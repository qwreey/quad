--!nocheck
-- round13 E15 (scratch) — shared harness for the integration-scenario probes.
-- Install idiom borrowed from round13-e14-probe / quad-roblox spec.tweenproperty + spec.timers.
-- Run a probe from repo root: `luau .claude/audit/round13-e15-probe-<x>.luau` (after ./scripts/relink.sh).
local Quad = require("../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../quad-roblox/src").QuadRoblox
local installProperty = require("../quad-roblox/src/Handlers/Property")
local installEvent = require("../quad-roblox/src/Handlers/Event")
local installShorthand = require("../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../quad-roblox/src/EngineOps")
local mock = require("../quad-base/test/mock")

local W = { Write = "" }
local function props(...)
	local t = {}
	for _, n in { ... } do table.insert(t, { Name = n, Permits = W }) end
	return t
end
local COMMON = { "Name", "Size", "Visible", "Position", "LayoutOrder", "ZIndex", "BackgroundTransparency", "BackgroundColor3", "BorderSizePixel", "AnchorPoint", "Interactable" }
local function with(...)
	local t = table.clone(COMMON)
	for _, n in { ... } do table.insert(t, n) end
	return props(table.unpack(t))
end
local REFLECTED = {
	Frame = with(),
	ScreenGui = props("Name", "ResetOnSpawn", "Enabled"),
	TextButton = with("Text", "TextSize", "TextColor3", "FontFace", "TextXAlignment"),
	TextLabel = with("Text", "TextSize", "TextColor3", "FontFace", "TextXAlignment"),
	TextBox = with("Text", "PlaceholderText", "TextSize", "TextColor3"),
	ScrollingFrame = with("CanvasSize", "CanvasPosition", "AbsoluteWindowSize", "ScrollBarThickness"),
	UIListLayout = props("Name", "Padding", "FillDirection"),
	UICorner = props("Name", "CornerRadius"),
}
mock.declareEvents("TextButton", { "Activated", "MouseButton1Click", "MouseEnter" })
mock.declareEvents("TextBox", { "FocusLost" })
mock.declareEvents("Frame", { "MouseEnter" })
local gameShim = mock.gameShim(REFLECTED)

-- virtual task scheduler (spec.timers idiom)
local queue = {}
local clock = 0
local taskShim = {
	delay = function(delay, fn, ...)
		local args = table.pack(...)
		local th = coroutine.create(function() fn(table.unpack(args, 1, args.n)) end)
		queue[#queue + 1] = { at = clock + delay, thread = th, seq = #queue + 1 }
		return th
	end,
	cancel = function(th)
		if coroutine.status(th) ~= "dead" then coroutine.close(th) end
		for i, t in queue do if t.thread == th then table.remove(queue, i) break end end
	end,
}
local function run(dt)
	local target = clock + dt
	while true do
		local best, bi = nil, 0
		for i, t in queue do
			if t.at <= target and (best == nil or t.at < best.at) then best, bi = t, i end
		end
		if best == nil then break end
		table.remove(queue, bi)
		clock = best.at
		if coroutine.status(best.thread) ~= "dead" then
			local ok, err = coroutine.resume(best.thread)
			if not ok then print("  [task error] " .. tostring(err):gsub("\n.*", "")) end
		end
	end
	clock = target
end

;(getfenv(installEngineOps)).task = taskShim
local q = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent)).game = gameShim
;(getfenv(installEngineOps)).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
q.errorNamespace.setFuncLevel(require("../quad-roblox/luau_packages/quad_types").ERROR_LEVEL_SURFACE, q.Backend.isInst)
local UDIM_MT = { __eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end }
local UDim = { new = function(s, o) return setmetatable({ Scale = s, Offset = o }, UDIM_MT) end }
;(getfenv(installShorthand)).UDim = UDim

local function first(err) return (tostring(err):gsub("\n.*", "")) end
local function try(label, fn)
	local ok, err = pcall(fn)
	print(label, ok and "OK" or ("ERR: " .. first(err)))
	return ok, err
end

-- weak tracker for leak counting
local tracked = setmetatable({}, { __mode = "k" })
local function track(tag, obj) if obj ~= nil then tracked[obj] = tag end return obj end
local function alive(prefix)
	for _ = 1, 4 do collectgarbage("collect") end
	local counts = {}
	for _, tag in tracked do
		if prefix == nil or string.sub(tag, 1, #prefix) == prefix then counts[tag] = (counts[tag] or 0) + 1 end
	end
	local out = {}
	for k, v in counts do table.insert(out, k .. "=" .. v) end
	table.sort(out)
	return table.concat(out, " ")
end

return {
	q = q, D = q.Declaration, mock = mock, run = run, now = function() return clock end,
	pending = function() return #queue end, task = taskShim, try = try, first = first, track = track, alive = alive, UDim = UDim,
	tweenLog = mock.tweenLog,
}
