--!nocheck
-- round13 P-TWEEN bundle probe (scratch). Runs against any tree (base / bundle); header adapted from
-- ../round13-e2b-probe.luau. Copy to <scratch>/quad-roblox/test/ and run `luau test/probe.bundle.luau`.
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local installShorthand = require("../src/Handlers/InstanceShorthand")
local mock = require("../../quad-base/test/mock")

local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Position", Permits = W }, { Name = "Parent", Permits = W }, { Name = "BackgroundTransparency", Permits = W }, { Name = "BackgroundColor3", Permits = W }, { Name = "Rotation", Permits = W } },
	UIPadding = { { Name = "Name", Permits = W }, { Name = "PaddingLeft", Permits = W }, { Name = "PaddingRight", Permits = W }, { Name = "PaddingTop", Permits = W }, { Name = "PaddingBottom", Permits = W } },
	UICorner = { { Name = "Name", Permits = W }, { Name = "CornerRadius", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q = Quad.New():UseProvider(QuadRoblox)
local penv = getfenv(installProperty)
penv.game = gameShim
penv.TweenInfo = mock.tweenInfoShim
penv.Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent)).game = gameShim
;(getfenv(require("../src/EngineOps"))).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local D = q.Declaration
local function first(err) return (tostring(err):gsub("\n.*", "")) end
-- value-type stand-ins with a `typeof` seam (engine typeof answers "UDim"/"UDim2"/"Vector2"/"Color3")
local UDIM_MT = { __eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end, __tostring = function(a) return ("UDim(%s,%s)"):format(a.Scale, a.Offset) end }
UDim = { new = function(s, o) return setmetatable({ Scale = s, Offset = o }, UDIM_MT) end }
local UDIM2_MT = { __eq = function(a, b) return a.X == b.X and a.Y == b.Y end, __tostring = function(a) return ("UDim2(%s,%s)"):format(tostring(a.X), tostring(a.Y)) end }
local function UDim2(xs, xo, ys, yo) return setmetatable({ X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }, UDIM2_MT) end
local V2_MT = { __eq = function(a, b) return a.X == b.X and a.Y == b.Y end, __tostring = function(a) return ("V2(%s,%s)"):format(a.X, a.Y) end }
local function V2(x, y) return setmetatable({ X = x, Y = y }, V2_MT) end
local C3_MT = { __eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end, __tostring = function(a) return ("C3(%s,%s,%s)"):format(a.R, a.G, a.B) end }
local function C3(r, g, b) return setmetatable({ R = r, G = g, B = b }, C3_MT) end
local realTypeof = typeof
penv.typeof = function(v)
	local mt = getmetatable(v)
	if mt == UDIM_MT then return "UDim" elseif mt == UDIM2_MT then return "UDim2" elseif mt == V2_MT then return "Vector2" elseif mt == C3_MT then return "Color3" end
	return realTypeof(v)
end
;(getfenv(installShorthand)).UDim = UDim
local function f32(x) return (string.unpack("f", string.pack("f", x))) end
local function sec(name, fn)
	print("=== " .. name .. " ===")
	local ok, err = pcall(fn)
	if not ok then print("  !! section error:", first(err)) end
end
local log = mock.tweenLog
local function lastTween() return log[#log].tween end
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
	for i = n0 + 1, #log do local e = log[i]; if e.tween.PlaybackState == "Playing" then for _, v in e.props do table.insert(t, tostring(v)) end end end
	return table.concat(t, ",")
end
local function row(name, n0, extra)
	print(("  %-44s order=%-22s playing=[%s]%s"):format(name, table.concat(order, ","), playing(n0), extra or ""))
end
-- fresh Frame with Size bound to a Source, first write (snap) already done, order cleared
local function fresh(v0)
	local s = q.Source(v0 or 0)
	local f = D.Frame({ Size = s })
	table.clear(order)
	return s, f, #log
end
local function settle(t, f, k) t.PlaybackState = "Completed"; if f then f[k or "Size"] = t.PropertyTable[k or "Size"] end end

sec("ORDER (4) — observed callback order per path", function()
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); row("N0 engine start (after snap)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); table.clear(order); settle(a, f); a.Completed:Fire("Completed"); row("N1 natural finish", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); table.clear(order); s:Set(tw("B", 20)); row("R1 replace running (engine B)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); table.clear(order); s:Set(tw("B", 20, { Time = 0 })); row("R2 replace running (zero-time B)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); table.clear(order); s:Set(20); row("R3 replace running (plain 20)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); table.clear(order); s:Set(tw("B", 20)); a.Completed:Fire("Completed"); row("W1 window replace (engine B), late notice", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10, { onC = function() s:Set(tw("C", 77)) end })); local a = lastTween(); settle(a, f); table.clear(order); s:Set(tw("B", 20)); row("W2 window replace, A.Completed chains C", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); table.clear(order); s:Set(tw("B", 20, { Time = 0 })); row("W3 window replace (zero-time B)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); table.clear(order); s:Set(20); row("W4 window replace (plain 20)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); table.clear(order); s:Set(tw("B", 10)); a.Completed:Fire("Completed"); row("W5 window + same target (engine wrote it)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10, { Reverses = true })); local a = lastTween(); a.PlaybackState = "Completed"; f.Size = 0; table.clear(order); s:Set(tw("B", 10, { Reverses = true })); a.Completed:Fire("Completed"); row("W6 window + same target, Reverses (rest=start)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); table.clear(order); q.Dispatch.retractFrom(f, "Size", 1); row("T1 teardown running", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); table.clear(order); q.Dispatch.retractFrom(f, "Size", 1); a.Completed:Fire("Completed"); row("T2 teardown in window (+late notice)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10, { onC = function() s:Set(tw("C", 77)) end })); local a = lastTween(); settle(a, f); table.clear(order); q.Dispatch.retractFrom(f, "Size", 1); row("T3 teardown in window, A.Completed chains C", n0, " s=" .. tostring(s:Get())) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); a.Completed:Fire("Completed"); table.clear(order); q.Dispatch.retractFrom(f, "Size", 1); row("T4 teardown after natural finish", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); table.clear(order); s:Set(q.None); row("T5 None (handler switch) running", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); f:Destroy(); table.clear(order); q.Dispatch.retractFrom(f, "Size", 1); row("T6 corpse retractFrom running (Q82)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); f:Destroy(); table.clear(order); q.Dispatch.retractFrom(f, "Size", 1); row("T7 corpse retractFrom window (Q82)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); f:Destroy(); table.clear(order); settle(a); a.Completed:Fire("Completed"); row("T8 Destroy then natural finish (Q71)", n0) end
	do table.clear(order); local n0 = #log; local s = q.Source(tw("A", 10)); local f = D.Frame({ Size = s }); row("S1 first-set snap", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); table.clear(order); s:Set(tw("B", 10)); row("S2 dedup, running same target", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); a.Completed:Fire("Completed"); table.clear(order); s:Set(tw("B", 10)); row("S3 dedup, finished at target", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); a.Completed:Fire("Completed"); f.Size = 40; table.clear(order); s:Set(tw("B", 10)); row("S4 finished + outside write, same target (Q81)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10, { Reverses = true })); local a = lastTween(); a.PlaybackState = "Completed"; a.Completed:Fire("Completed"); f.Size = 0; table.clear(order); s:Set(tw("B", 10, { Reverses = true })); row("S5 Reverses pulse again (Q81)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10, { Time = 0 })); table.clear(order); f.Size = 40; s:Set(tw("B", 10)); row("S6 snapped record + outside write (Q81)", n0) end
	do local s, f, n0 = fresh(); s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); a.Completed:Fire("Completed"); table.clear(order); s:Set(tw("B", 10, { Dedup = false })); row("S7 Dedup=false, finished at target", n0) end
end)

sec("I1 Q81 x Q92 — padding: outside write on ONE side, same target again", function()
	local s = q.Source(UDim.new(0, 0))
	local f = D.Frame({ UIPadding = s })
	local c = { S = 0, C = 0 }
	local function mk(o) return q.Tween({ Value = UDim.new(0, o), Time = 1, Started = function() c.S += 1 end, Completed = function() c.C += 1 end }) end
	local n0 = #log
	s:Set(mk(8))
	for i = n0 + 1, #log do local e = log[i]; e.tween.PlaybackState = "Completed"; for p, v in e.props do e.inst[p] = v end; e.tween.Completed:Fire("Completed") end
	local pad = f:FindFirstChild("_quad_padding") or f:GetChildren()[1]
	print("  after finish: S", c.S, "C", c.C)
	-- outside write on PaddingRight only (not the first chain)
	pad.PaddingRight = UDim.new(0, 3)
	local n1 = #log
	s:Set(mk(8))
	local props = {}
	for i = n1 + 1, #log do for p in log[i].props do table.insert(props, p) end end
	print("  right-only outside write → new tweens", #log - n1, "[" .. table.concat(props, ",") .. "] S", c.S)
	pad.PaddingLeft = UDim.new(0, 3)
	local n2 = #log
	s:Set(mk(8))
	props = {}
	for i = n2 + 1, #log do for p in log[i].props do table.insert(props, p) end end
	print("  left(first chain) outside write → new tweens", #log - n2, "[" .. table.concat(props, ",") .. "] S", c.S)
end)

sec("I2 Q97 — engine-quantized read-back (retractor record + Q81 same-target)", function()
	local cases = {
		{ "number 0.1 (float32)", "BackgroundTransparency", 0, 0.1, f32(0.1) },
		{ "number 0.5 (exact)", "BackgroundTransparency", 0, 0.5, f32(0.5) },
		{ "Rotation 33.3 (float32)", "Rotation", 0, 33.3, f32(33.3) },
		{ "UDim2 scale .3 f32 / offset 10.6→10", "Size", UDim2(0, 0, 0, 0), UDim2(0.3, 10.6, 0.1, 5), UDim2(f32(0.3), 10, f32(0.1), 5) },
		{ "Vector2 (.1,.7) f32", "Position", V2(0, 0), V2(0.1, 0.7), V2(f32(0.1), f32(0.7)) },
		{ "Color3 (.1,.2,.3) f32", "BackgroundColor3", C3(0, 0, 0), C3(0.1, 0.2, 0.3), C3(f32(0.1), f32(0.2), f32(0.3)) },
		{ "UDim2 genuinely different (off by 1)", "Size", UDim2(0, 0, 0, 0), UDim2(0.3, 10, 0.1, 5), UDim2(f32(0.3), 11, f32(0.1), 5) },
	}
	for _, cs in cases do
		local name, k, v0, target, stored = cs[1], cs[2], cs[3], cs[4], cs[5]
		-- (a) retractor: finish, engine leaves `stored`, teardown, re-declare same target
		local f = D.Frame({ [k] = v0 })
		local n0 = #log
		q.Dispatch.drive(f, { [k] = q.Tween({ Value = target, Time = 1 }) })
		local t = lastTween(); t.PlaybackState = "Completed"; f[k] = stored; t.Completed:Fire("Completed")
		q.Dispatch.retractFrom(f, k, 1)
		q.Dispatch.drive(f, { [k] = q.Tween({ Value = target, Time = 1 }) })
		local afterTeardown = #log - n0
		-- (b) Q81 dedup: finish with `stored`, same target again (no teardown)
		local s = q.Source(v0)
		local g = D.Frame({ [k] = s })
		local n1 = #log
		s:Set(q.Tween({ Value = target, Time = 1 }))
		local t2 = lastTween(); t2.PlaybackState = "Completed"; g[k] = stored; t2.Completed:Fire("Completed")
		s:Set(q.Tween({ Value = target, Time = 1 }))
		print(("  %-38s teardown+redeclare tweens=%d  dedup-after-finish tweens=%d"):format(name, afterTeardown, #log - n1))
	end
end)

sec("I3 clamping property (CanvasPosition-like): engine never holds the target", function()
	local s = q.Source(0)
	local f = D.Frame({ Size = s })
	local n = { S = 0, C = 0 }
	local function mk() return q.Tween({ Value = 1000, Time = 1, Started = function() n.S += 1 end, Completed = function() n.C += 1 end }) end
	local n0 = #log
	for _ = 1, 3 do
		s:Set(mk())
		local t = lastTween()
		if t.PlaybackState == "Playing" then t.PlaybackState = "Completed"; f.Size = 300; t.Completed:Fire("Completed") end -- clamped
	end
	print("  3x same target 1000 (engine clamps to 300): tweens", #log - n0, "Started", n.S, "Completed", n.C)
end)

sec("I4 Q81 x engine-side cancel (another TweenService tween on the same property)", function()
	local s, f, n0 = fresh()
	s:Set(tw("A", 10))
	local a = lastTween()
	a.PlaybackState = "Cancelled"; a.Completed:Fire("Cancelled") -- outside cancel; notice arrives
	f.Size = 4
	table.clear(order)
	s:Set(tw("B", 10))
	row("same target after outside cancel", n0, " A.cancels=" .. a.cancels)
end)

sec("I5 Q91 nested x Q81 — A.Completed chains the incoming B's target", function()
	local s, f, n0 = fresh()
	s:Set(tw("A", 10, { onC = function() s:Set(tw("C", 20)) end }))
	local a = lastTween(); settle(a, f); table.clear(order)
	s:Set(tw("B", 20))
	row("inner same target as B (B not yet played)", n0)
end)

sec("I6 Q99c x Q81 — teardown in window, then same target re-declared", function()
	local s, f, n0 = fresh()
	s:Set(tw("A", 10)); local a = lastTween(); settle(a, f); table.clear(order)
	q.Dispatch.retractFrom(f, "Size", 1)
	q.Dispatch.drive(f, { Size = tw("B", 10) })
	a.Completed:Fire("Completed")
	row("window teardown → same target", n0, " tweens=" .. (#log - n0))
end)
