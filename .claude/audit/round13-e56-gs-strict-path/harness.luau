--!nocheck
-- [E27 copy] 원본: ../round13-s10-snippet-recheck/harness.luau. 변경: TextLabel/TextButton에 TextScaled 추가(GS 02~04 스니펫이 씀),
-- 캡처용 print 헬퍼 H.capture 추가. 나머지 동일.
-- S10 shared mock harness (borrowed from round13-e15-probe-setup.luau / quad-roblox spec.component).
-- require this from a runner placed in the SAME directory via `require("./harness")`.
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local installProperty = require("../../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../../quad-roblox/src/Handlers/Event")
local installShorthand = require("../../../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../../../quad-roblox/src/EngineOps")
local mock = require("../../../quad-base/test/mock")
local EG = require("./engine-globals")

local W = { Write = "" }
local function props(...)
	local t = {}
	for _, n in { ... } do table.insert(t, { Name = n, Permits = W }) end
	return t
end
local COMMON = { "Name", "Size", "Visible", "Position", "LayoutOrder", "ZIndex", "BackgroundTransparency", "BackgroundColor3", "BorderSizePixel", "AnchorPoint", "Interactable", "ClipsDescendants", "Rotation", "Active", "Draggable" }
local function with(...)
	local t = table.clone(COMMON)
	for _, n in { ... } do table.insert(t, n) end
	return props(table.unpack(t))
end
local REFLECTED = {
	Frame = with(),
	ScreenGui = props("Name", "ResetOnSpawn", "Enabled", "IgnoreGuiInset", "DisplayOrder"),
	TextButton = with("TextScaled", "Text", "TextSize", "TextColor3", "FontFace", "Font", "TextXAlignment", "TextYAlignment", "TextWrapped", "AutoButtonColor", "TextTransparency"),
	TextLabel = with("TextScaled", "Text", "TextSize", "TextColor3", "FontFace", "Font", "TextXAlignment", "TextYAlignment", "TextWrapped", "TextTransparency", "RichText"),
	TextBox = with("Text", "PlaceholderText", "TextSize", "TextColor3", "ClearTextOnFocus", "MultiLine"),
	ScrollingFrame = with("CanvasSize", "CanvasPosition", "AbsoluteWindowSize", "ScrollBarThickness", "AutomaticCanvasSize", "ScrollingDirection"),
	ImageLabel = with("Image", "ImageColor3", "ImageTransparency", "ScaleType"),
	ImageButton = with("Image", "ImageColor3", "ImageTransparency", "ScaleType"),
	UIListLayout = props("Name", "Padding", "FillDirection", "HorizontalAlignment", "VerticalAlignment", "SortOrder"),
	UIGridLayout = props("Name", "CellSize", "CellPadding", "SortOrder"),
	UICorner = props("Name", "CornerRadius"),
	UIPadding = props("Name", "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight"),
	UIStroke = props("Name", "Color", "Thickness", "Transparency"),
	Frame_Viewport = with(),
	ViewportFrame = with(),
}
mock.declareEvents("TextButton", { "Activated", "MouseButton1Click", "MouseButton1Down", "MouseEnter", "MouseLeave", "InputBegan", "InputEnded" })
mock.declareEvents("TextBox", { "FocusLost", "Focused" })
mock.declareEvents("Frame", { "MouseEnter", "MouseLeave", "InputBegan", "InputEnded" })
mock.declareEvents("ScrollingFrame", { "MouseEnter" })
local gameShim = mock.gameShim(REFLECTED)

-- virtual `task` scheduler (spec.timers idiom)
local queue = {}
local clock = 0
local taskShim = {
	delay = function(delay, fn, ...)
		local args = table.pack(...)
		local th = coroutine.create(function() fn(table.unpack(args, 1, args.n)) end)
		queue[#queue + 1] = { at = clock + delay, thread = th, seq = #queue + 1 }
		return th
	end,
	spawn = function(fn, ...)
		local args = table.pack(...)
		local th = coroutine.create(function() fn(table.unpack(args, 1, args.n)) end)
		coroutine.resume(th)
		return th
	end,
	wait = function(t) return t or 0 end,
	cancel = function(th)
		if coroutine.status(th) ~= "dead" then coroutine.close(th) end
		for i, t in queue do if t.thread == th then table.remove(queue, i) break end end
	end,
}
local function runTask(dt)
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
local q = Quad:UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = EG.Enum
;(getfenv(installEvent)).game = gameShim
;(getfenv(installEngineOps)).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
;(getfenv(installShorthand)).UDim = EG.UDim

-- E27: capture helper — returns (printFn, log) ; printFn joins args with tab like print and records
local function capture()
	local log = {}
	local function p(...)
		local n = select("#", ...)
		local parts = {}
		for i = 1, n do parts[i] = tostring((select(i, ...))) end
		local line = table.concat(parts, "\t")
		table.insert(log, line)
		print(line)
	end
	return p, log
end

local function first(err) return (tostring(err):gsub("\n.*", "")) end

return {
	Quad = Quad,
	q = q,
	D = q.Declaration,
	None = q.None,
	Modifier = q.Modifier,
	gameShim = gameShim,
	game = gameShim,
	runTask = runTask,
	task = taskShim,
	first = first,
	capture = capture,
	mock = mock,
	CollectionService = gameShim:GetService("CollectionService"),
	EG = EG,
}
