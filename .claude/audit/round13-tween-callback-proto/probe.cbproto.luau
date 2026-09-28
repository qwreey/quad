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
-- ================= round13 tween-callback-structure spike probe (collect -> write -> call) =================
local None = q.None
local order = {}
local function rec(s) table.insert(order, s) end
local function ord() return table.concat(order, ",") end
local function fmt(v) if type(v) == "table" and v.Offset ~= nil then return tostring(v.Offset) end return tostring(v) end
local function playingList(n0)
	local t = {}
	for i = n0 + 1, #mock.tweenLog do
		local e = mock.tweenLog[i]
		if e.tween.PlaybackState == "Playing" then
			for p, v in e.props do table.insert(t, (mock.isDestroyed(e.inst) and "dead." or "") .. e.inst.ClassName .. "." .. p .. "=" .. fmt(v)) end
		end
	end
	table.sort(t)
	return t
end
-- orphans = playing tweens beyond ONE per (inst, prop), plus any playing on a destroyed instance
local function orphans(n0)
	local per, n = {}, 0
	for i = n0 + 1, #mock.tweenLog do
		local e = mock.tweenLog[i]
		if e.tween.PlaybackState == "Playing" then
			for p in e.props do
				if mock.isDestroyed(e.inst) then n += 1 else
					local key = tostring(e.inst) .. "." .. p
					per[key] = (per[key] or 0) + 1
				end
			end
		end
	end
	for _, c in per do if c > 1 then n += c - 1 end end
	return n
end
local function P(n0) return "playing=[" .. table.concat(playingList(n0), " ") .. "] orphans=" .. orphans(n0) end
-- T(tag, value, extra): a Tween whose callbacks log tag:S / tag:C / tag:X; extra.onS/onC/onX run after logging
local function T(tag, v, extra)
	extra = extra or {}
	local o = { Value = v, Time = 1,
		Started = function() rec(tag .. ":S"); if extra.onS then extra.onS() end end,
		Completed = function() rec(tag .. ":C"); if extra.onC then extra.onC() end end,
		Cancelled = function() rec(tag .. ":X"); if extra.onX then extra.onX() end end }
	for kk, vv in extra do if kk ~= "onS" and kk ~= "onC" and kk ~= "onX" then o[kk] = vv end end
	return q.Tween(o)
end
local function once(fn) local done = false; return function() if not done then done = true; fn() end end end
local function flip(n0) for i = n0 + 1, #mock.tweenLog do local tw = mock.tweenLog[i].tween; if tw.PlaybackState == "Playing" then tw.PlaybackState = "Completed" end end end
local function deliver(n0) for i = n0 + 1, #mock.tweenLog do local tw = mock.tweenLog[i].tween; if tw.PlaybackState == "Completed" then tw.Completed:Fire("Completed") end end end
local function lastTween() return mock.tweenLog[#mock.tweenLog].tween end


-- ================= PROTO probe (round13 tween-callback-structure §8-1: args + Mapped/Wrapped + shorthand representative) =========
local argLog = {}
local function A(tag) -- a callback set that logs (event, inst name, prop, value)
	local function mk(ev) return function(inst, prop, value) table.insert(argLog, ("%s:%s(%s,%s,%s)"):format(tag, ev, if inst then (inst.Name or inst.ClassName) else "nil", tostring(prop), fmt(value))) end end
	return { Started = mk("S"), Completed = mk("C"), Cancelled = mk("X") }
end
local function TA(tag, v, extra)
	local o = A(tag); o.Value = v; o.Time = 1
	for kk, vv in (extra or {}) do o[kk] = vv end
	return q.Tween(o)
end
local function args() local s = table.concat(argLog, " "); table.clear(argLog); return s end

sec("A. callback args at every Property fire site (Size on Frame 'F')", function()
	local s = q.Source(0)
	local f = D.Frame({ Name = "F", Size = s })
	local n0 = #mock.tweenLog
	local s2 = q.Source(TA("first", 5))
	D.Frame({ Name = "G", Size = s2 })
	print("  first-write snap:        " .. args())
	s:Set(TA("a", 10)); print("  engine start:            " .. args())
	s:Set(TA("b", 20)); print("  replace running:         " .. args())
	flip(n0); s:Set(TA("c", 30)); print("  replace window:          " .. args())
	s:Set(TA("z", 40, { Time = 0 })); print("  replace by zero-time:    " .. args())
	s:Set(TA("d", 50)); lastTween():simulateCompleted(); print("  natural finish:          " .. args())
	s:Set(TA("e", 60)); s:Set(70); print("  replace by plain:        " .. args())
	s:Set(TA("g", 80)); q.Dispatch.retractFrom(f, "Size", 1); print("  teardown running:        " .. args())
	q.Dispatch.process(f, "Size", TA("h", 90), 1); flip(n0); q.Dispatch.retractFrom(f, "Size", 1); deliver(n0); print("  teardown window (Q99 c): " .. args())
end)

sec("A2. Q82 (a) corpse retractFrom — no callback, engine tween still cancelled", function()
	for _, win in { false, true } do
		local f = D.Frame({ Name = "F", Size = 0 })
		local n0 = #mock.tweenLog
		q.Dispatch.process(f, "Size", TA("a", 10), 1)
		local tw = lastTween()
		if win then flip(n0) end
		args()
		f:Destroy()
		q.Dispatch.retractFrom(f, "Size", 1)
		print(("  %s: callbacks=[%s] cancels=%d state=%s"):format(win and "window " or "running", args(), tw.cancels, tostring(tw.PlaybackState)))
	end
end)

-- representative cascade through a shorthand key: the user callback chains the next value from Completed
local function padCascade(label, key, mkVal, order_)
	local s = q.Source(mkVal(0))
	local f = D.Frame({ Name = "P", [key] = s })
	local step, S, C, X = 0, 0, 0, 0
	local seen = {}
	local function mk(v)
		return q.Tween({ Value = mkVal(v), Time = 1,
			Started = function(inst, prop, value) S += 1; table.insert(seen, "S:" .. inst.Name .. "." .. prop .. "=" .. fmt(value)) end,
			Cancelled = function(inst, prop, value) X += 1; table.insert(seen, "X:" .. inst.Name .. "." .. prop .. "=" .. fmt(value)) end,
			Completed = function(inst, prop, value)
				C += 1; table.insert(seen, "C:" .. inst.Name .. "." .. prop .. "=" .. fmt(value))
				if step < 3 then step += 1; s:Set(mk(100 + step)) end
			end })
	end
	local n0 = #mock.tweenLog
	s:Set(mk(10))
	local rounds = 0
	while rounds < 8 do
		rounds += 1
		local batch = {}
		for i = n0 + 1, #mock.tweenLog do local e = mock.tweenLog[i]; if e.tween.PlaybackState == "Playing" then table.insert(batch, e) end end
		if #batch == 0 then break end
		for _, e in batch do e.tween.PlaybackState = "Completed"; for pk, pv in e.props do (e.inst :: any)[pk] = pv end end
		local seq = order_(batch)
		for _, e in seq do e.tween.Completed:Fire("Completed") end
	end
	local pad = named(f, "_quad_padding")
	local vals = {}
	for _, p in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do table.insert(vals, fmt((pad :: any)[p])) end
	print(("  %-30s steps %d S %d C %d X %d, created %d, final=%s %s"):format(label, step, S, C, X, #mock.tweenLog - n0, table.concat(vals, "/"), P(n0)))
	print("    seen: " .. table.concat(seen, " "))
end
local function fwd(b) return b end
local function rev(b) local r = {} for i = #b, 1, -1 do table.insert(r, b[i]) end return r end
local function repFirst(b) local r = { b[#b] } for i = 1, #b - 1 do table.insert(r, b[i]) end return r end -- batch order = PADDING_PROPS order, last = Bottom
local function repMid(b) local r = {} for _, i in { 2, 4, 1, 3 } do if b[i] then table.insert(r, b[i]) end end return r end
local function udim(v) return UDim.new(0, v) end
local function num(v) return v end
sec("B (2)(4). UIPaddingOffset 10->101->102->103 from the representative Completed, notice orders", function()
	padCascade("UIPaddingOffset fwd", "UIPaddingOffset", num, fwd)
	padCascade("UIPaddingOffset rev", "UIPaddingOffset", num, rev)
	padCascade("UIPaddingOffset rep-first", "UIPaddingOffset", num, repFirst)
	padCascade("UIPaddingOffset 2,4,1,3", "UIPaddingOffset", num, repMid)
	padCascade("UIPadding(identity) fwd", "UIPadding", udim, fwd)
	padCascade("UIPadding(identity) rev", "UIPadding", udim, rev)
	padCascade("UIPadding(identity) rep-first", "UIPadding", udim, repFirst)
end)

sec("C (3). four tweens running, representative callback re-emits synchronously", function()
	for _, which in { "engine", "zero-time", "plain" } do
		local s = q.Source(0)
		local f = D.Frame({ Name = "P", UIPaddingOffset = s })
		local n0 = #mock.tweenLog
		local seen = {}
		local fired = false
		s:Set(q.Tween({ Value = 10, Time = 1,
			Cancelled = function(inst, prop, value)
				table.insert(seen, "X:" .. inst.Name .. "." .. prop .. "=" .. fmt(value))
				if not fired then fired = true; s:Set(q.Tween({ Value = 77, Time = 1 })) end
			end }))
		local B = if which == "engine" then q.Tween({ Value = 20, Time = 1 }) elseif which == "zero-time" then q.Tween({ Value = 20, Time = 0 }) else 20
		s:Set(B)
		local pad = named(f, "_quad_padding")
		local vals = {}
		for _, p in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do table.insert(vals, fmt((pad :: any)[p])) end
		print(("  B=%-9s seen=[%s] s=%s final=%s %s"):format(which, table.concat(seen, " "), fmt(s:Get()), table.concat(vals, "/"), P(n0)))
	end
	-- window variant: A reached its target on all four (notices pending), B arrives, A.Completed (rep) re-emits
	local s = q.Source(0)
	local f = D.Frame({ Name = "P", UIPaddingOffset = s })
	local n0 = #mock.tweenLog
	local seen, fired = {}, false
	s:Set(q.Tween({ Value = 10, Time = 1, Completed = function(inst, prop, value)
		table.insert(seen, "C:" .. inst.Name .. "." .. prop .. "=" .. fmt(value))
		if not fired then fired = true; s:Set(q.Tween({ Value = 77, Time = 1 })) end
	end }))
	flip(n0)
	s:Set(q.Tween({ Value = 20, Time = 1 }))
	deliver(n0)
	local pad = named(f, "_quad_padding")
	local vals = {}
	for _, p in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do table.insert(vals, fmt((pad :: any)[p])) end
	print(("  window A, B=engine, rep Completed re-emits: seen=[%s] s=%s final=%s %s"):format(table.concat(seen, " "), fmt(s:Get()), table.concat(vals, "/"), P(n0)))
end)

sec("D (5). T5 — one Source on Size + BackgroundTransparency: two callbacks, each its own prop", function()
	local s = q.Source(0)
	local f = D.Frame({ Name = "F", Size = s, BackgroundTransparency = s })
	local n0 = #mock.tweenLog
	s:Set(TA("t", 10))
	print("  start:     " .. args())
	for i = n0 + 1, #mock.tweenLog do mock.tweenLog[i].tween:simulateCompleted() end
	print("  finish:    " .. args())
	s:Set(TA("u", 20, { Time = 0 }))
	print("  zero-time: " .. args())
	local _ = f
end)

sec("E. shorthand callback args, single-key UICorner/UIScale, replace + Set(nil) teardown", function()
	for _, spec in { { "UICorner", 8 }, { "UIScale", 1.5 }, { "UIPaddingOffset", 4 } } do
		local s = q.Source(0)
		local f = D.Frame({ Name = "H", [spec[1]] = s })
		local n0 = #mock.tweenLog
		s:Set(TA("a", spec[2]))
		local st = args()
		for i = n0 + 1, #mock.tweenLog do mock.tweenLog[i].tween:simulateCompleted() end
		local fin = args()
		s:Set(TA("b", spec[2] * 2))
		local rep = args()
		s:Set(nil :: any)
		print(("  %-16s start=[%s] finish=[%s] replace=[%s] Set(nil)=[%s] kids=%s %s"):format(spec[1], st, fin, rep, args(), kids(f), P(n0)))
	end
end)

sec("F. Mapped(fn, wrap) / Wrapped — one call, set semantics, validation", function()
	local base = TA("m", 3)
	local c0 = 0
	local w = base:Wrapped(function(cb) c0 += 1; return { Completed = cb.Completed } end)
	print(("  Wrapped: wrap calls %d, Started=%s Completed same=%s Cancelled=%s Value=%s frozen=%s"):format(c0, tostring(w.Started), tostring(w.Completed == base.Completed), tostring(w.Cancelled), fmt(w.Value), tostring(table.isfrozen(w))))
	local c1 = 0
	local m = base:Mapped(function(v) return v * 10 end, function(cb) c1 += 1; return cb:Map(function(f) return function(i, p, v) f(i, p, v) end end) end)
	print(("  Mapped(fn,wrap): wrap calls %d, Value=%s all three present=%s isTween=%s"):format(c1, fmt(m.Value), tostring(m.Started ~= nil and m.Completed ~= nil and m.Cancelled ~= nil), tostring(q.isTween(m))))
	local none = q.Tween({ Value = 1 }):Wrapped(function(cb) return cb:Map(function(f) return f end) end)
	print(("  no callbacks + Map: Started=%s Completed=%s"):format(tostring(none.Started), tostring(none.Completed)))
	local plain = base:Mapped(function(v) return v + 1 end)
	print(("  Mapped(fn) keeps callbacks as-is: %s"):format(tostring(plain.Completed == base.Completed)))
	for _, bad in {
		{ "wrap not fn", function() return base:Wrapped(5 :: any) end },
		{ "wrap returns nil", function() return base:Wrapped(function() return nil :: any end) end },
		{ "set value not fn", function() return base:Wrapped(function() return { Completed = 5 :: any } end) end },
		{ "Map g not fn", function() return base:Wrapped(function(cb) return cb:Map(5 :: any) end) end },
		{ "Mapped wrap not fn", function() return base:Mapped(function(v) return v end, "x" :: any) end },
	} do
		local ok, err = pcall(bad[2])
		print(("  %-20s ok=%s %s"):format(bad[1], tostring(ok), ok and "" or first(err)))
	end
end)

sec("G. GC — callbacks (and the shorthand's wrapped copy) do not pin a destroyed Instance (claimed ones are held by quad until Destroy)", function()
	local function gc(label, key, mkTween, destroy)
		local weak = setmetatable({}, { __mode = "k" })
		do
			local s = q.Source(0)
			local f = D.Frame({ Name = "P", [key] = s })
			s:Set(mkTween())
			weak[f] = true
			if destroy then f:Destroy() end
		end
		mock.resetTweenLog()
		for _ = 1, 6 do collectgarbage("collect") end
		local n = 0 for _ in weak do n += 1 end
		print(("  %-40s alive=%d"):format(label, n))
	end
	for _, key in { "Size", "UIPaddingOffset", "UICorner" } do
		for _, d in { false, true } do
			gc(key .. " no callbacks" .. (d and " +Destroy" or ""), key, function() return q.Tween({ Value = 10, Time = 1 }) end, d)
			gc(key .. " Completed cb" .. (d and " +Destroy" or ""), key, function() return q.Tween({ Value = 10, Time = 1, Completed = function() end }) end, d)
		end
	end
end)
