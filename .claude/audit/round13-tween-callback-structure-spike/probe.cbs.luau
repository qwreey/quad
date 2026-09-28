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

-- ── 2. Q91 probes ─────────────────────────────────────────────────────────────────────────────
local function cascade(label, props, reverseDelivery)
	local s = q.Source(0)
	local decl = {}
	for _, p in props do decl[p] = s end
	local f = D.Frame(decl)
	local step, completes, starts, cancels = 0, 0, 0, 0
	local function mk(v)
		return q.Tween({ Value = v, Time = 1,
			Started = function() starts += 1 end,
			Cancelled = function() cancels += 1 end,
			Completed = function() completes += 1; if step < 3 then step += 1; s:Set(mk(100 + step)) end end })
	end
	local n0 = #mock.tweenLog
	s:Set(mk(10))
	local rounds = 0
	local perRound = {}
	while rounds < 8 do
		rounds += 1
		local batch = {}
		for i = n0 + 1, #mock.tweenLog do local e = mock.tweenLog[i]; if e.tween.PlaybackState == "Playing" then table.insert(batch, e) end end
		if #batch == 0 then break end
		-- same frame: the engine flipped every batch tween and wrote its target, notices come one by one
		for _, e in batch do e.tween.PlaybackState = "Completed"; for pk, pv in e.props do (e.inst :: any)[pk] = pv end end
		if reverseDelivery then for i = #batch, 1, -1 do batch[i].tween.Completed:Fire("Completed") end
		else for _, e in batch do e.tween.Completed:Fire("Completed") end end
		table.insert(perRound, tostring(orphans(n0)))
	end
	local vals = {}
	local target = if props[1] == "UIPaddingOffset" then named(f, "_quad_padding") else f
	local shown = if props[1] == "UIPaddingOffset" then { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } else props
	for _, p in shown do table.insert(vals, fmt((target :: any)[p])) end
	print(("  %s%s: steps %d, Started %d, Completed %d, Cancelled %d, tweens created %d, rounds %d, orphans after each round [%s], s=%s final=%s %s"):format(
		label, reverseDelivery and " (reverse)" or "", step, starts, completes, cancels, #mock.tweenLog - n0, rounds - 1, table.concat(perRound, ","), fmt(s:Get()), table.concat(vals, "/"), P(n0)))
	-- follow-up: a later plain Tween write — one tween per prop expected, nothing left from the cascade
	s:Set(q.Tween({ Value = 500, Time = 1 }))
	print("    after Set(500): " .. P(n0))
	s:Set(nil :: any)
	print("    after Set(nil): " .. P(n0))
end
sec("2a Q91 cascade UIPaddingOffset 10->101->102->103", function()
	cascade("UIPaddingOffset", { "UIPaddingOffset" }, false)
	cascade("UIPaddingOffset", { "UIPaddingOffset" }, true)
end)
sec("2b Q91 T5 one Source on two props (Size + BackgroundTransparency)", function()
	cascade("Size+BgT", { "Size", "BackgroundTransparency" }, false)
	cascade("Size+BgT", { "Size", "BackgroundTransparency" }, true)
end)
local function t6(name, mkB)
	table.clear(order)
	local s = q.Source(0)
	local f = D.Frame({ Size = s })
	local n0 = #mock.tweenLog
	s:Set(T("A", 10, { onC = once(function() s:Set(T("C", 77)) end) }))
	flip(n0) -- A reached its target, notice pending (window)
	table.clear(order)
	local ok, err = pcall(function() s:Set(mkB()) end)
	local line = ("  %-22s ok=%s order=%s s=%s Size=%s %s"):format(name, tostring(ok), ord(), fmt(s:Get()), fmt(f.Size), P(n0))
	deliver(n0)
	print(line .. " | after late notices order=" .. ord())
	if not ok then print("    err", first(err)) end
	pcall(function() s:Set(q.Tween({ Value = 500, Time = 1 })) end)
	print("    follow-up Set(500): " .. P(n0))
end
sec("2c Q91 T6 single prop, window replacement, A.Completed chains C=77", function()
	t6("engine B", function() return T("B", 20) end)
	t6("zero-time B", function() return T("B", 20, { Time = 0 }) end)
	t6("plain B", function() return 20 end)
	t6("engine B Finish", function() return T("B", 20, { Override = "Finish" }) end)
end)

-- ── 3. H-589 re-entry ─────────────────────────────────────────────────────────────────────────
local function reentry(name, setup)
	table.clear(order)
	local s = q.Source(0)
	local f = D.Frame({ Size = s })
	local n0 = #mock.tweenLog
	local ok, err = pcall(setup, s)
	print(("  %-44s ok=%s order=%s s=%s Size=%s %s"):format(name, tostring(ok), ord(), fmt(s:Get()), fmt(f.Size), P(n0)))
	if not ok then print("    err", first(err)) end
	table.clear(order)
	local ok2 = pcall(function() s:Set(T("F", 500)) end)
	print(("    follow-up Set(F=500) ok=%s order=%s %s"):format(tostring(ok2), ord(), P(n0)))
end
sec("3 H-589 same-State re-entry from inside a callback", function()
	reentry("R1 engine Started(B) sets C", function(s)
		s:Set(T("A", 10))
		s:Set(T("B", 20, { onS = once(function() s:Set(T("C", 77)) end) }))
	end)
	reentry("R2 old Cancelled(A) sets C (engine B)", function(s)
		s:Set(T("A", 10, { onX = once(function() s:Set(T("C", 77)) end) }))
		s:Set(T("B", 20))
	end)
	reentry("R2z old Cancelled(A) sets C (zero-time B)", function(s)
		s:Set(T("A", 10, { onX = once(function() s:Set(T("C", 77)) end) }))
		s:Set(T("B", 20, { Time = 0 }))
	end)
	reentry("R2p old Cancelled(A) sets C (plain B)", function(s)
		s:Set(T("A", 10, { onX = once(function() s:Set(T("C", 77)) end) }))
		s:Set(20)
	end)
	reentry("R2c old Cancelled(A) sets C=zero-time", function(s)
		s:Set(T("A", 10, { onX = once(function() s:Set(T("C", 77, { Time = 0 })) end) }))
		s:Set(T("B", 20))
	end)
	reentry("R3 snap Started(B) sets C (prev plain)", function(s)
		s:Set(T("B", 20, { Time = 0, onS = once(function() s:Set(T("C", 77)) end) }))
	end)
	reentry("R3r snap Started(B) sets C (prev running A)", function(s)
		s:Set(T("A", 10))
		s:Set(T("B", 20, { Time = 0, onS = once(function() s:Set(T("C", 77)) end) }))
	end)
	reentry("R4 snap Completed(B) sets C (prev plain)", function(s)
		s:Set(T("B", 20, { Time = 0, onC = once(function() s:Set(T("C", 77)) end) }))
	end)
	reentry("R5 natural Completed(A) sets C", function(s)
		s:Set(T("A", 10, { onC = once(function() s:Set(T("C", 77)) end) }))
		lastTween():simulateCompleted()
	end)
end)
sec("3b first-write snap Started sets C (prev nil)", function()
	table.clear(order)
	local s
	s = q.Source(T("B", 20, { onS = once(function() s:Set(T("C", 77)) end) }))
	local n0 = #mock.tweenLog
	local f = D.Frame({ Size = s })
	print(("  first-write snap Started(B) sets C: order=%s s=%s Size=%s %s"):format(ord(), fmt(s:Get()), fmt(f.Size), P(n0)))
	table.clear(order)
	s:Set(T("F", 500))
	print(("    follow-up order=%s %s"):format(ord(), P(n0)))
end)

-- ── 4. Q146 throwing callbacks ────────────────────────────────────────────────────────────────
local function thrower(name, prep, trigger)
	for _, tail in { "next", "teardown" } do
		table.clear(order)
		local s = q.Source(0)
		local f = D.Frame({ Size = s })
		local n0 = #mock.tweenLog
		prep(s, n0)
		table.clear(order)
		local ok, err = pcall(trigger, s, n0)
		local after = ("ok=%s err=%s order=%s Size=%s %s"):format(tostring(ok), ok and "-" or first(err):sub(-12), ord(), fmt(f.Size), P(n0))
		table.clear(order)
		local ok2, err2
		if tail == "next" then
			ok2, err2 = pcall(function() s:Set(T("N", 300)) end)
		else
			ok2, err2 = pcall(function() q.Dispatch.retractFrom(f, "Size", 1) end)
		end
		if tail == "next" then print(("  %-38s %s"):format(name, after)) end
		print(("    %-8s ok=%s order=%s Size=%s %s"):format(tail, tostring(ok2), ord(), fmt(f.Size), P(n0)) .. (ok2 and "" or (" err=" .. first(err2))))
	end
end
sec("4 Q146 callbacks that throw (then: next value / teardown)", function()
	thrower("T1 new Started(B) throws (engine B)", function(s) s:Set(T("A", 10)) end,
		function(s) s:Set(T("B", 20, { onS = function() error("S") end })) end)
	thrower("T2 old Cancelled(A) throws", function(s) s:Set(T("A", 10, { onX = function() error("X") end })) end,
		function(s) s:Set(T("B", 20)) end)
	thrower("T3 old window Completed(A) throws", function(s, n0) s:Set(T("A", 10, { onC = function() error("C") end })); flip(n0) end,
		function(s) s:Set(T("B", 20)) end)
	thrower("T4 zero-time snap Started(B) throws", function(s) s:Set(T("A", 10)) end,
		function(s) s:Set(T("B", 20, { Time = 0, onS = function() error("S") end })) end)
	thrower("T5 zero-time snap Completed(B) throws", function(s) s:Set(T("A", 10)) end,
		function(s) s:Set(T("B", 20, { Time = 0, onC = function() error("C") end })) end)
	thrower("T6 natural Completed(A) throws", function(s) s:Set(T("A", 10, { onC = function() error("C") end })) end,
		function(s) lastTween():simulateCompleted() end)
end)
sec("4b Q146 teardown callbacks that throw (then: re-drive the same index)", function()
	for _, win in { false, true } do
		table.clear(order)
		local s = q.Source(0)
		local f = D.Frame({ Size = s })
		local n0 = #mock.tweenLog
		s:Set(T("A", 10, { onX = function() error("X") end, onC = function() error("C") end }))
		if win then flip(n0) end
		table.clear(order)
		local ok, err = pcall(function() q.Dispatch.retractFrom(f, "Size", 1) end)
		print(("  teardown %s A throws: ok=%s err=%s order=%s %s"):format(win and "window" or "running", tostring(ok), ok and "-" or first(err):sub(-12), ord(), P(n0)))
		table.clear(order)
		local ok2, err2 = pcall(function() q.Dispatch.process(f, "Size", T("N", 300), 1) end)
		print(("    re-drive process(N) ok=%s order=%s Size=%s %s%s"):format(tostring(ok2), ord(), fmt(f.Size), P(n0), ok2 and "" or (" err=" .. first(err2))))
	end
end)

-- ── 5. observed order table ───────────────────────────────────────────────────────────────────
local function row(name, fn)
	table.clear(order)
	local s = q.Source(0)
	local f = D.Frame({ Size = s })
	local n0 = #mock.tweenLog
	local ok, err = pcall(fn, s, f, n0)
	print(("  %-40s %s%s"):format(name, ord(), ok and "" or (" !! " .. first(err))))
end
sec("5 order table (the transition only; late notices delivered)", function()
	row("first-write snap (Tween on fresh)", function(s) local s2 = q.Source(T("A", 10)); D.Frame({ Size = s2 }) end)
	row("replace running A by engine B (+finish)", function(s, f, n0) s:Set(T("A", 10)); table.clear(order); s:Set(T("B", 20)); lastTween():simulateCompleted() end)
	row("replace running A by zero-time B", function(s, f, n0) s:Set(T("A", 10)); table.clear(order); s:Set(T("B", 20, { Time = 0 })) end)
	row("replace running A by plain", function(s, f, n0) s:Set(T("A", 10)); table.clear(order); s:Set(20) end)
	row("replace window A by engine B", function(s, f, n0) s:Set(T("A", 10)); flip(n0); table.clear(order); s:Set(T("B", 20)); deliver(n0) end)
	row("replace window A by zero-time B", function(s, f, n0) s:Set(T("A", 10)); flip(n0); table.clear(order); s:Set(T("B", 20, { Time = 0 })); deliver(n0) end)
	row("replace window A by plain", function(s, f, n0) s:Set(T("A", 10)); flip(n0); table.clear(order); s:Set(20); deliver(n0) end)
	row("replace snapped {Value} by engine B", function(s, f, n0) s:Set(T("A", 10, { Time = 0 })); table.clear(order); s:Set(T("B", 20)) end)
	row("natural finish A", function(s, f, n0) s:Set(T("A", 10)); table.clear(order); lastTween():simulateCompleted() end)
	row("teardown running A", function(s, f, n0) s:Set(T("A", 10)); table.clear(order); q.Dispatch.retractFrom(f, "Size", 1) end)
	row("teardown window A", function(s, f, n0) s:Set(T("A", 10)); flip(n0); table.clear(order); q.Dispatch.retractFrom(f, "Size", 1); deliver(n0) end)
	row("Set(None) window A (handler switch)", function(s, f, n0) s:Set(T("A", 10)); flip(n0); table.clear(order); s:Set(None); deliver(n0) end)
end)

-- ── 6. Q99 teardown window with a chaining Completed ──────────────────────────────────────────
sec("6 Q99 teardown window, A.Completed chains C=77", function()
	local function td(name, mkTeardown, isPad)
		table.clear(order)
		local s = q.Source(0)
		local f = D.Frame(if isPad then { UIPaddingOffset = s } else { Size = s })
		local n0 = #mock.tweenLog
		s:Set(T("A", 10, { onC = once(function() s:Set(T("C", 77)) end) }))
		flip(n0)
		table.clear(order)
		local ok, err = pcall(mkTeardown, s, f)
		deliver(n0)
		print(("  %-28s ok=%s order=%s s=%s kids=%s %s"):format(name, tostring(ok), ord(), fmt(s:Get()), kids(f), P(n0)) .. (ok and "" or (" err=" .. first(err))))
		if not isPad then
			pcall(function() q.Dispatch.process(f, "Size", q.Tween({ Value = 500, Time = 1 }), 1) end)
			print("    follow-up process(500): " .. P(n0))
		end
	end
	td("retractFrom(Size)", function(s, f) q.Dispatch.retractFrom(f, "Size", 1) end)
	td("s:Set(None)", function(s) s:Set(None) end)
	td("UIPaddingOffset s:Set(nil)", function(s) s:Set(nil :: any) end, true)
end)

-- ── 4c. Q146 residue: after a throw, is the slot's dedup target honest? (re-declare the OLD target 10) ──
sec("4c Q146 after a throw, re-declare the old target (Tween Value=10) — does it play?", function()
	local function chk(name, prep, trigger, redeclare)
		table.clear(order)
		local s = q.Source(0)
		local f = D.Frame({ Size = s })
		local n0 = #mock.tweenLog
		prep(s, n0)
		local ok = pcall(trigger, s, f)
		local before = #mock.tweenLog
		table.clear(order)
		local ok2, err2 = pcall(redeclare, s, f)
		print(("  %-40s throw=%s redeclare ok=%s new engine tweens=%d Size=%s %s%s"):format(name, tostring(not ok), tostring(ok2), #mock.tweenLog - before, fmt(f.Size), P(n0), ok2 and "" or (" err=" .. first(err2))))
	end
	chk("old Cancelled(A) throws on replace", function(s) s:Set(T("A", 10, { onX = function() error("X") end })) end,
		function(s) s:Set(T("B", 20)) end, function(s) s:Set(T("A2", 10)) end)
	chk("teardown Cancelled(A) throws, re-drive A2", function(s) s:Set(T("A", 10, { onX = function() error("X") end })) end,
		function(s, f) q.Dispatch.retractFrom(f, "Size", 1) end, function(s, f) q.Dispatch.process(f, "Size", T("A2", 10), 1) end)
end)

-- ── 5b. what the old value's settle callback SEES on the property (moved after the write) ──────
sec("5b property value read inside A's Cancelled/Completed on replacement", function()
	local function see(name, win, mkB)
		local s = q.Source(0)
		local f = D.Frame({ Size = s })
		local n0 = #mock.tweenLog
		local seen = "-"
		s:Set(q.Tween({ Value = 10, Time = 1, Cancelled = function() seen = "X sees " .. fmt(f.Size) end, Completed = function() seen = "C sees " .. fmt(f.Size) end }))
		if win then flip(n0); f.Size = 10 end -- window: the engine already wrote the target
		s:Set(mkB())
		print(("  %-32s %s (after: Size=%s)"):format(name, seen, fmt(f.Size)))
	end
	see("running A -> engine B", false, function() return q.Tween({ Value = 20, Time = 1 }) end)
	see("running A -> engine B Finish", false, function() return q.Tween({ Value = 20, Time = 1, Override = "Finish" }) end)
	see("running A -> zero-time B", false, function() return q.Tween({ Value = 20, Time = 0 }) end)
	see("running A -> plain 20", false, function() return 20 end)
	see("window A -> plain 20", true, function() return 20 end)
end)
