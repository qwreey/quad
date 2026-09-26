--!nocheck
-- round13 E4-2 probe (scratch) — Q91 teardown window x variants. To rerun: cp -rL quad-base quad-roblox quad-types quad-error type-version-check to a scratch dir,
-- apply ../round13-q91-proto/Property.window-completed-after-record.diff, then ./Property.teardown-window-variants.diff (and ./Dispatch.defer-to-outermost.diff to BOTH quad-base/src and
-- quad-roblox/luau_packages/.pesde/qwreey+quad_base/*/quad_base/src — quad-roblox requires its own copy), optionally ../round13-q91-proto/InstanceShorthand.callbacks-once.diff;
-- copy this file and ../round13-q91-proto/probe.q91teardown.luau to <scratch>/quad-roblox/test/ and run ./run.sh <Q91_ON> <MODE> <Q82_GATE> from <scratch> (run.sh seds the switches).
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
local None = q.None
local order = {}
local function T(tag, extra)
	local t = { Started = function() table.insert(order, tag .. ":S") end,
		Completed = function() table.insert(order, tag .. ":C") end,
		Cancelled = function() table.insert(order, tag .. ":X") end }
	for k2, v2 in extra or {} do t[k2] = v2 end
	return t
end
-- A = the window tween; its Completed chains C (=77) once
local function chainA(s, tag)
	local done = false
	local cfg = T(tag or "A", { Value = 10, Time = 1 })
	local base = cfg.Completed
	cfg.Completed = function()
		base()
		if not done then done = true; s:Set(q.Tween(T("C", { Value = 77, Time = 1 }))) end
	end
	return q.Tween(cfg)
end
local function playingInfo(n0)
	local t = {}
	for i = n0 + 1, #mock.tweenLog do
		local e = mock.tweenLog[i]
		if e.tween.PlaybackState == "Playing" then
			for p, v in e.props do
				table.insert(t, (mock.isDestroyed(e.inst) and "dead." or "") .. e.inst.ClassName .. "." .. p .. "=" .. tostring(v))
			end
		end
	end
	return table.concat(t, ",")
end
local function cTweens(n0)
	local t = {}
	for i = n0 + 1, #mock.tweenLog do
		local e = mock.tweenLog[i]
		for _, v in e.props do
			if v == 77 or (type(v) == "table" and v.Offset == 77) then table.insert(t, e.tween) end
		end
	end
	return t
end
local function report(n0, extra)
	print("  order", table.concat(order, ","))
	print("  playing", playingInfo(n0), extra or "")
end
local function flip(n0) for i = n0 + 1, #mock.tweenLog do if mock.tweenLog[i].tween.PlaybackState == "Playing" then mock.tweenLog[i].tween.PlaybackState = "Completed" end end end
local function deliver(n0) for i = n0 + 1, #mock.tweenLog do local tw = mock.tweenLog[i].tween; if tw.PlaybackState == "Completed" then tw.Completed:Fire("Completed") end end end
-- after teardown: who cancels C? next write to the same (inst,k) through a fresh chain
local function followUp(inst, k, n0)
	local cs = cTweens(n0)
	local ok, err = pcall(function() q.Dispatch.process(inst, k, q.Tween({ Value = 500, Time = 1 }), 1) end)
	local c = {}
	for _, tw in cs do table.insert(c, tw.cancels) end
	print("  followUp write ok", ok, ok and "" or first(err), "C.cancels", table.concat(c, ","), "playing", playingInfo(n0))
end

sec("i  retractFrom(f,Size,1) in window", function()
	table.clear(order)
	local s = q.Source(0); local f = D.Frame({ Size = s }); local n0 = #mock.tweenLog
	s:Set(chainA(s)); flip(n0)
	local ok, err = pcall(function() q.Dispatch.retractFrom(f, "Size", 1) end)
	print("  ok", ok, ok and "" or first(err), "s=", tostring(s:Get()))
	deliver(n0)
	report(n0, "f.Size=" .. tostring(f.Size))
	followUp(f, "Size", n0)
end)
sec("ii-a s:Set(None) in window (Property->None at index 2)", function()
	table.clear(order)
	local s = q.Source(0); local f = D.Frame({ Size = s }); local n0 = #mock.tweenLog
	s:Set(chainA(s)); flip(n0)
	local ok, err = pcall(function() s:Set(None) end)
	print("  ok", ok, ok and "" or first(err), "s=", tostring(s:Get()) , "f.Size=", tostring(f.Size))
	deliver(n0)
	report(n0)
	followUp(f, "Size", n0)
end)
sec("ii-b Dispatch.process(f,Size,None,1) in window (StoreBind->None at index 1)", function()
	table.clear(order)
	local s = q.Source(0); local f = D.Frame({ Size = s }); local n0 = #mock.tweenLog
	s:Set(chainA(s)); flip(n0)
	local ok, err = pcall(function() q.Dispatch.process(f, "Size", None, 1) end)
	print("  ok", ok, ok and "" or first(err), "s=", tostring(s:Get()), "f.Size=", tostring(f.Size))
	deliver(n0)
	report(n0)
	followUp(f, "Size", n0)
end)
sec("iii-a UIPaddingOffset s:Set(nil) in window (4 tweens, managed child destroy)", function()
	table.clear(order)
	local s = q.Source(0); local f = D.Frame({ UIPaddingOffset = s }); local n0 = #mock.tweenLog
	s:Set(chainA(s)); flip(n0)
	local ok, err = pcall(function() s:Set(nil) end)
	local pad = named(f, "_quad_padding")
	print("  ok", ok, ok and "" or first(err), "s=", tostring(s:Get()), "kids", kids(f), pad and ("L=" .. tostring(pad.PaddingLeft) .. " R=" .. tostring(pad.PaddingRight)) or "")
	deliver(n0)
	report(n0)
	print("  kids after deliver", kids(f))
end)
sec("iii-b UICorner s:Set(nil) in window (1 tween, managed child destroy)", function()
	table.clear(order)
	local s = q.Source(0); local f = D.Frame({ UICorner = s }); local n0 = #mock.tweenLog
	s:Set(chainA(s)); flip(n0)
	local ok, err = pcall(function() s:Set(nil) end)
	print("  ok", ok, ok and "" or first(err), "s=", tostring(s:Get()), "kids", kids(f))
	deliver(n0)
	report(n0)
	print("  kids after deliver", kids(f))
end)
sec("iv-D parent Destroy, Deferred (flip, Destroy, then notice)", function()
	table.clear(order)
	local s = q.Source(0); local f = D.Frame({ Size = s, UICorner = s }); local n0 = #mock.tweenLog
	s:Set(chainA(s)); flip(n0)
	f:Destroy()
	deliver(n0)
	report(n0, "s=" .. tostring(s:Get()))
end)
sec("iv-I parent Destroy, Immediate (notice at finish, then Destroy)", function()
	table.clear(order)
	local s = q.Source(0); local f = D.Frame({ Size = s }); local n0 = #mock.tweenLog
	s:Set(chainA(s)); flip(n0); deliver(n0)
	f:Destroy()
	report(n0, "s=" .. tostring(s:Get()))
	local cs = cTweens(n0); for _, tw in cs do tw:simulateCompleted() end
	print("  after C finishes on corpse:", table.concat(order, ","))
end)
sec("Q82 Destroy then retractFrom (running / window)", function()
	table.clear(order)
	local s = q.Source(0); local f = D.Frame({ Size = s }); local n0 = #mock.tweenLog
	s:Set(q.Tween(T("a", { Value = 10, Time = 1 })))
	f:Destroy(); q.Dispatch.retractFrom(f, "Size", 1)
	local s2 = q.Source(0); local g = D.Frame({ Size = s2 }); local n1 = #mock.tweenLog
	s2:Set(q.Tween(T("w", { Value = 10, Time = 1 }))); flip(n1)
	g:Destroy(); q.Dispatch.retractFrom(g, "Size", 1)
	print("  order", table.concat(order, ","))
end)
sec("ii-c Dispatch.process(f,Size,Tween B,1) in window (StoreBind->Property at index 1: teardown then new tween)", function()
	table.clear(order)
	local s = q.Source(0); local f = D.Frame({ Size = s }); local n0 = #mock.tweenLog
	s:Set(chainA(s)); flip(n0)
	local ok, err = pcall(function() q.Dispatch.process(f, "Size", q.Tween(T("B", { Value = 55, Time = 1 })), 1) end)
	print("  ok", ok, ok and "" or first(err), "s=", tostring(s:Get()))
	deliver(n0)
	report(n0)
end)
sec("pp  ping-pong chain (every Completed re-Sets), retractFrom in window", function()
	table.clear(order)
	local s = q.Source(0); local f = D.Frame({ Size = s }); local n0 = #mock.tweenLog
	local flipflop = 10
	local cfg
	cfg = function() return q.Tween(T("P" .. flipflop, { Value = flipflop, Time = 1, Completed = function() table.insert(order, "P:C"); flipflop = if flipflop == 10 then 20 else 10; s:Set(cfg()) end })) end
	s:Set(cfg()); flip(n0)
	q.Dispatch.retractFrom(f, "Size", 1)
	deliver(n0)
	report(n0)
end)
sec("b3-exc  a thrown process leaves the depth raised; then case i", function()
	table.clear(order)
	pcall(function() q.Dispatch.process(D.Frame({}), "NoSuchKey__", 1, 1) end)
	local s = q.Source(0); local f = D.Frame({ Size = s }); local n0 = #mock.tweenLog
	s:Set(chainA(s)); flip(n0)
	q.Dispatch.retractFrom(f, "Size", 1)
	deliver(n0)
	report(n0)
end)
