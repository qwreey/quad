--!nocheck
-- round13 Q91/Q92 prototype probe (scratch). To rerun: cp -rL quad-base quad-roblox quad-types quad-error to a scratch dir, apply the two diffs in this folder, copy this file to <scratch>/quad-roblox/test/probe.q91teardown.luau and run `luau test/probe.q91teardown.luau` from <scratch>/quad-roblox. Header lines 1-45 are copied from ../round13-e2b-probe.luau.
-- Moved from quad-roblox/test/probe.e2b.luau; to rerun copy back there after ./scripts/relink.sh and run `luau quad-roblox/test/probe.e2b.luau`.
-- round13 E2-2 probe (scratch) — InstanceShorthand / Modifier+StoreBind / Event
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local installShorthand = require("../src/Handlers/InstanceShorthand")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance

local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Visible", Permits = W }, { Name = "Parent", Permits = W }, { Name = "BackgroundTransparency", Permits = W } },
	TextButton = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W }, { Name = "Visible", Permits = W }, { Name = "Size", Permits = W } },
	UICorner = { { Name = "Name", Permits = W }, { Name = "CornerRadius", Permits = W } },
	UIPadding = { { Name = "Name", Permits = W }, { Name = "PaddingLeft", Permits = W }, { Name = "PaddingRight", Permits = W }, { Name = "PaddingTop", Permits = W }, { Name = "PaddingBottom", Permits = W } },
	UIScale = { { Name = "Name", Permits = W }, { Name = "Scale", Permits = W } },
}
mock.declareEvents("TextButton", { "Activated", "MouseEnter" })
mock.declareEvents("Frame", { "Changed", "MouseEnter" })
local gameShim = mock.gameShim(REFLECTED)
local q = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent)).game = gameShim
;(getfenv(require("../src/EngineOps"))).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
q.errorNamespace.setFuncLevel(require("../luau_packages/quad_types").ERROR_LEVEL_SURFACE, q.Backend.isInst)
local D = q.Declaration
local function first(err) return (tostring(err):gsub("\n.*", "")) end
local UDIM_MT = { __eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end,
	__tostring = function(a) return ("UDim(%s,%s)"):format(a.Scale, a.Offset) end }
UDim = { new = function(s, o) return setmetatable({ Scale = s, Offset = o }, UDIM_MT) end }
;(getfenv(installShorthand)).UDim = UDim
local function sec(name, fn)
	print("=== " .. name .. " ===")
	local ok, err = pcall(fn)
	if not ok then print("  !! section error:", first(err)) end
end
local function kids(f) local t = {} for _, c in f:GetChildren() do table.insert(t, c.ClassName .. ":" .. c.Name) end return table.concat(t, ",") end
local function nsubs(s) collectgarbage("collect"); collectgarbage("collect"); local n = 0 for _ in s._subs do n += 1 end return n end
local function named(f, n) for _, c in f:GetChildren() do if c.Name == n then return c end end end
local function playingAfter(n0) local t = {} for i = n0 + 1, #mock.tweenLog do local e = mock.tweenLog[i]; if e.tween.PlaybackState == "Playing" then for p, v in e.props do table.insert(t, p .. "=" .. tostring(v)) end end end return table.concat(t, ",") end
sec("R1 retractFrom(Size) in window, A.Completed chains C", function()
	local s = q.Source(0); local f = D.Frame({ Size = s }); local n0 = #mock.tweenLog; local done = false
	s:Set(q.Tween({ Value = 10, Time = 1, Completed = function() if not done then done = true; s:Set(q.Tween({ Value = 77, Time = 1 })) end end }))
	mock.tweenLog[#mock.tweenLog].tween.PlaybackState = "Completed"
	local ok, err = pcall(function() q.Dispatch.retractFrom(f, "Size", 1) end)
	print("  ok", ok, ok and "" or first(err), "playing", playingAfter(n0))
end)
sec("R2 UIPaddingOffset Set(nil) in window (managed child destroy), chain", function()
	local s = q.Source(0); local f = D.Frame({ UIPaddingOffset = s }); local n0 = #mock.tweenLog; local done = false
	s:Set(q.Tween({ Value = 10, Time = 1, Completed = function() if not done then done = true; s:Set(q.Tween({ Value = 77, Time = 1 })) end end }))
	for i = n0 + 1, #mock.tweenLog do mock.tweenLog[i].tween.PlaybackState = "Completed" end
	local ok, err = pcall(function() s:Set(nil) end)
	print("  ok", ok, ok and "" or first(err), "kids", kids(f), "playing", playingAfter(n0))
end)
