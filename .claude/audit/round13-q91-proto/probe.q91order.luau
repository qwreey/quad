--!nocheck
-- round13 Q91/Q92 prototype probe (scratch). To rerun: cp -rL quad-base quad-roblox quad-types quad-error to a scratch dir, apply the two diffs in this folder, copy this file to <scratch>/quad-roblox/test/probe.q91order.luau and run `luau test/probe.q91order.luau` from <scratch>/quad-roblox. Header lines 1-45 are copied from ../round13-e2b-probe.luau.
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
local order = {}
local function tw(tag, v, extra)
	local o = { Value = v, Time = 1,
		Started = function() table.insert(order, tag .. ":S") end,
		Completed = function() table.insert(order, tag .. ":C"); if extra and extra.onC then extra.onC() end end,
		Cancelled = function() table.insert(order, tag .. ":X") end }
	if extra then for kk, vv in extra do if kk ~= "onC" then o[kk] = vv end end end
	return q.Tween(o)
end
local function playing(n0)
	local t = {}
	for i = n0 + 1, #mock.tweenLog do local e = mock.tweenLog[i]; if e.tween.PlaybackState == "Playing" then for _, v in e.props do table.insert(t, tostring(v)) end end end
	return table.concat(t, ",")
end
local function case(name, mkB, chain)
	table.clear(order)
	local s = q.Source(0)
	local f = D.Frame({ Size = s })
	local n0 = #mock.tweenLog
	s:Set(tw("A", 10, chain and { onC = function() s:Set(tw("C", 77)) end } or nil))
	local a = mock.tweenLog[#mock.tweenLog].tween
	table.clear(order)
	a.PlaybackState = "Completed" -- window
	s:Set(mkB())
	print(("  %-34s order=%s  playing=[%s] A.cancels=%d Size=%s"):format(name, table.concat(order, ","), playing(n0), a.cancels, tostring(f.Size)))
	a.Completed:Fire("Completed")
	if #order > 0 then end
end
sec("ORDER", function()
	case("O1 engine B, no chain", function() return tw("B", 20) end, false)
	case("O2 engine B, A.Completed chains C", function() return tw("B", 20) end, true)
	case("O3 zero-time B, chain", function() return tw("B", 20, { Time = 0 }) end, true)
	case("O4 plain B, chain", function() return 20 end, true)
	case("O5 zero-time B, no chain", function() return tw("B", 20, { Time = 0 }) end, false)
	case("O6 engine B Finish, chain", function() return tw("B", 20, { Override = "Finish" }) end, true)
end)
sec("H-581 late notice", function()
	table.clear(order)
	local s = q.Source(0)
	local f = D.Frame({ Size = s })
	s:Set(tw("A", 10)); local a = mock.tweenLog[#mock.tweenLog].tween
	a.PlaybackState = "Completed"; s:Set(tw("B", 20))
	a.Completed:Fire("Completed")
	print("  order", table.concat(order, ","), "A.cancels", a.cancels)
end)
sec("teardown in window (retractor path, not deferred), chain", function()
	table.clear(order)
	local s = q.Source(0)
	local f = D.Frame({ Size = s })
	local n0 = #mock.tweenLog
	s:Set(tw("A", 10, { onC = function() s:Set(tw("C", 77)) end })); local a = mock.tweenLog[#mock.tweenLog].tween
	a.PlaybackState = "Completed"; table.clear(order)
	local ok, err = pcall(function() s:Set(nil) end)
	print("  Set(nil): ok", ok, ok and "" or first(err), "order", table.concat(order, ","), "playing", playing(n0))
end)
