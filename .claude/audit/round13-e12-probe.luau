--!nocheck
-- round13 E12 probe — time ops × Debounce/Throttle × Gate × Blocker boundaries (not a spec).
-- Run from repo root: luau .claude/audit/round13-e12-probe.luau
local mock = require("../../quad-base/test/mock")
local q = mock.newQuad()
local Source, Debounce, Throttle, Blocker, Ref, Effect = q.Source, q.Debounce, q.Throttle, q.Blocker, q.Ref, q.Effect
local adv = mock.advanceTime
local function T(name, f)
	mock.resetTimers()
	local ok, err = pcall(f)
	print(`--- {name}: {ok and "ok" or ("ERR " .. tostring(err))}`)
end
local function obs(st, extra)
	local rec = { seen = {} }
	rec.o = st:Observer(function(s)
		if rec.installed then
			rec.seen[#rec.seen + 1] = `{tostring(s:Get())}@{mock.now()}`
			if extra then extra(s) end
		end
	end):Subscribe()
	rec.installed = true
	return rec
end
local function S(rec) return "[" .. table.concat(rec.seen, ",") .. "]" end
local P = mock.pendingTimers or function() return "?" end

-- ── (1) Time = 0 / -0 / 1e-9 / math.huge ─────────────────────────
for _, cfg in { {"Debounce", Debounce, {}}, {"Debounce L", Debounce, {Leading=true}}, {"Debounce L noT", Debounce, {Leading=true, Trailing=false}},
	{"Throttle", Throttle, {}}, {"Throttle noL", Throttle, {Leading=false}}, {"Throttle noT", Throttle, {Trailing=false}} } do
	for _, t in { 0, -0, 1e-9 } do
		T(`A1 {cfg[1]} Time={t} burst then advance(0)`, function()
			local o = table.clone(cfg[3]); o.Time = t
			local s = Source(0)
			local g = s:Apply(cfg[2](o))
			local r = obs(g)
			s:Set(1); s:Set(2)
			local before = S(r)
			adv(0)
			local mid = S(r)
			adv(1e-9)
			print(`  sync={before} after adv0={mid} after 1e-9={S(r)} pending={P()}`)
		end)
	end
end

T("A2 Debounce Time=0 bounded feedback: observer Sets upstream until 50 — all within one advance(0)?", function()
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 0 }))
	local r = obs(g, function(st) local v = st:Get(); if v < 50 then s:Set(v + 1) end end)
	s:Set(1)
	adv(0)
	print(`  fires={#r.seen} last={r.seen[#r.seen]} clock={mock.now()} pending={P()}`)
end)

T("A3 Debounce Time=0 unbounded feedback — mock advance(0) never returns (guard at 10000)", function()
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 0 }))
	local n = 0
	local r = obs(g, function(st) n += 1; if n >= 10000 then error("GUARD: 10000 fires in one advance(0)") end; s:Set(st:Get() + 1) end)
	s:Set(1)
	local ok, err = pcall(adv, 0)
	print(`  ok={ok} n={n} err={tostring(err):sub(1,80)} clock={mock.now()}`)
end)

T("A3b same feedback with Time=0.1 — advance(1) runs ~10 steps (time-bounded)", function()
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 0.1 }))
	local n = 0
	obs(g, function(st) n += 1; s:Set(st:Get() + 1) end)
	s:Set(1)
	adv(1)
	print(`  n={n} clock={mock.now()} pending={P()}`)
end)

T("A3c feedback, NO gate (sync observer Sets upstream) — baseline", function()
	local s = Source(0)
	local n = 0
	local ok, err = pcall(function()
		obs(s, function(st) n += 1; if n >= 10000 then error("GUARD") end; s:Set(st:Get() + 1) end)
		s:Set(1)
	end)
	print(`  ok={ok} n={n} err={tostring(err):sub(1,120)}`)
end)

T("A4 Time=math.huge Debounce: signal withheld forever? Flush? Cancel? pending", function()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Debounce({ Time = math.huge, MaxTime = math.huge, Handle = h }))
	local r = obs(g)
	s:Set(1)
	adv(1e300)
	print(`  after adv 1e300: {S(r)} pending={P()}`)
	h:Unwrap():Flush()
	print(`  after Flush: {S(r)} pending={P()}`)
	s:Set(2)
	h:Unwrap():Cancel()
	print(`  after Set+Cancel: {S(r)} pending={P()}`)
	local ok, e = pcall(adv, math.huge)
	print(`  adv(math.huge) ok={ok} {tostring(e)} {S(r)} clock={mock.now()}`)
end)

T("A4b Throttle Time=math.huge: leading passes once, then ?", function()
	local s = Source(0)
	local g = s:Apply(Throttle({ Time = math.huge }))
	local r = obs(g)
	s:Set(1); s:Set(2)
	adv(1e300)
	print(`  {S(r)} pending={P()}`)
end)

T("A5 Time State flips 0 -> NaN -> 0.5; state after throw", function()
	local tS = Source(0)
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = tS }))
	local r = obs(g)
	s:Set(1)
	tS:Set(0/0)
	local ok, e = pcall(function() s:Set(2) end)
	print(`  Set with NaN ok={ok} {tostring(e):sub(1,90)}`)
	adv(0)
	print(`  after adv(0): {S(r)} pending={P()}`)
	tS:Set(0.5)
	s:Set(3)
	adv(0.5)
	print(`  after fix: {S(r)} pending={P()}`)
end)

T("A5b first-ever read throws (idle, Leading=false) — withheld merged? next valid signal", function()
	local tS = Source(-1)
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Debounce({ Time = tS, Handle = h }))
	local r = obs(g)
	local ok = pcall(function() s:Set(1) end)
	print(`  throw={not ok} withheld nonempty={next(g._withheld) ~= nil} pending={P()}`)
	h:Unwrap():Flush()
	print(`  Flush with _time nil: {S(r)} pending={P()}`)
end)

T("A5c first-ever read throws with Throttle(Leading) — the throwing signal later?", function()
	local tS = Source(-1)
	local s = Source(0)
	local g = s:Apply(Throttle({ Time = tS }))
	local r = obs(g)
	pcall(function() s:Set(1) end)
	tS:Set(1)
	s:Set(2)
	print(`  sync after fix: {S(r)}`)
	adv(1)
	print(`  +1: {S(r)} pending={P()}`)
end)

-- ── (2) re-entrancy in timer callbacks, throws ───────────────────
T("B1 Throttle default: observer throws during trailing flush — state after, next leading?", function()
	local s = Source(0)
	local g = s:Apply(Throttle({ Time = 1 }))
	local boom = false
	local r = obs(g, function() if boom then boom = false; error("OBS BOOM") end end)
	s:Set(1) -- leading pass
	s:Set(2) -- withheld
	boom = true
	local ok, e = pcall(adv, 1)
	print(`  adv ok={ok} {tostring(e):sub(1,60)} seen={S(r)} clock={mock.now()} pending={P()}`)
	adv(5)
	s:Set(3) -- idle for 5s: leading should pass immediately
	print(`  after 5s idle Set(3) sync seen={S(r)} pending={P()}`)
	adv(1)
	print(`  +1: {S(r)} pending={P()}`)
end)

T("B1b same throw with another gate's timer due in the same advance — mock aborts rest of advance", function()
	local s, s2 = Source(0), Source(0)
	local g = s:Apply(Debounce({ Time = 1 }))
	local g2 = s2:Apply(Debounce({ Time = 2 }))
	local r = obs(g, function() error("OBS BOOM") end)
	local r2 = obs(g2)
	s:Set(1); s2:Set(1)
	local ok = pcall(adv, 5)
	print(`  ok={ok} clock={mock.now()} (target 5) g2 seen={S(r2)} pending={P()}`)
	adv(0)
	print(`  after adv(0): g2 seen={S(r2)} clock={mock.now()}`)
end)

T("B1c Debounce: observer throws in trailing flush — Blocker On, no window: next signal starts window?", function()
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 1, MaxTime = 3 }))
	local boom = true
	local r = obs(g, function() if boom then boom = false; error("x") end end)
	s:Set(1)
	pcall(adv, 1)
	print(`  after throw: seen={S(r)} pending={P()}`)
	s:Set(2)
	adv(1)
	print(`  next: {S(r)} pending={P()}`)
	adv(10)
	print(`  settle: {S(r)} pending={P()}`)
end)

T("B1d Debounce Leading=true: observer throws in trailing flush — next burst's leading edge?", function()
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 1, Leading = true }))
	local boom = false
	local r = obs(g, function() if boom then boom = false; error("x") end end)
	s:Set(1) -- leading
	s:Set(2) -- withheld
	boom = true
	pcall(adv, 1)
	adv(10)
	print(`  after throw + 10s idle: seen={S(r)} pending={P()}`)
	s:Set(3)
	print(`  new burst Set(3) sync: {S(r)} (leading expected 3@11)`)
	adv(1)
	print(`  +1: {S(r)} pending={P()}`)
end)

T("B1e Throttle Trailing=false: throw in leading pass", function()
	local s = Source(0)
	local g = s:Apply(Throttle({ Time = 1, Trailing = false }))
	local boom = true
	local r = obs(g, function() if boom then boom = false; error("x") end end)
	local ok = pcall(function() s:Set(1) end)
	print(`  throw={not ok} pending={P()}`)
	s:Set(2)
	print(`  Set(2) sync: {S(r)} pending={P()}`)
end)

T("B2 in trailing-flush observer: handle:Flush()", function()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Throttle({ Time = 1, Handle = h }))
	local once = false
	local r = obs(g, function(st) if st:Get() == 2 and not once then once = true; h:Unwrap():Flush() end end)
	s:Set(1); s:Set(2)
	adv(1)
	print(`  {S(r)} pending={P()}`)
	s:Set(3)
	print(`  Set(3) sync {S(r)}`)
	adv(3)
	print(`  {S(r)} pending={P()}`)
end)

T("B3 in trailing-flush observer: upstream Set then handle:Flush()", function()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Debounce({ Time = 1, Handle = h }))
	local once = false
	local r = obs(g, function(st) if st:Get() == 1 and not once then once = true; s:Set(9); h:Unwrap():Flush() end end)
	s:Set(1)
	adv(1)
	print(`  after: {S(r)} pending={P()}`)
	adv(5)
	print(`  settle: {S(r)} pending={P()}`)
end)

T("B4 in trailing-flush observer: upstream Set then handle:Cancel()", function()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Throttle({ Time = 1, Handle = h }))
	local once = false
	local r = obs(g, function(st) if st:Get() == 2 and not once then once = true; s:Set(9); h:Unwrap():Cancel() end end)
	s:Set(1); s:Set(2)
	adv(1)
	print(`  after: {S(r)} pending={P()} blocking?`)
	s:Set(10)
	print(`  Set(10) sync (leading expected): {S(r)}`)
	adv(5)
	print(`  settle {S(r)} pending={P()}`)
end)

T("B5 in cap-flush observer: Cancel / Set", function()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Debounce({ Time = 1, MaxTime = 2, Handle = h }))
	local mode = 0
	local r = obs(g, function(st) if mode == 1 then mode = 2; s:Set(100); h:Unwrap():Cancel() end end)
	mode = 1
	for i = 1, 30 do s:Set(i); adv(0.25) end
	print(`  {S(r)} pending={P()}`)
	adv(5)
	print(`  settle {S(r)} pending={P()}`)
end)

T("B6 handle:Flush() from inside observer during LEADING pass (Throttle)", function()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Throttle({ Time = 1, Handle = h }))
	local once = false
	local r = obs(g, function() if not once then once = true; h:Unwrap():Flush(); h:Unwrap():Cancel() end end)
	s:Set(1)
	print(`  sync {S(r)} pending={P()}`)
	s:Set(2)
	print(`  Set(2) sync {S(r)} (leading?)`)
	adv(3)
	print(`  settle {S(r)} pending={P()}`)
end)

T("B7 Flush throws (observer error) — state after", function()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Debounce({ Time = 1, Handle = h }))
	local boom = true
	local r = obs(g, function() if boom then boom = false; error("x") end end)
	s:Set(1)
	local ok = pcall(function() h:Unwrap():Flush() end)
	print(`  Flush threw={not ok} pending={P()}`)
	adv(1)
	print(`  +1 {S(r)} pending={P()}`)
	s:Set(2); adv(1)
	print(`  next {S(r)} pending={P()}`)
end)

T("B8 yield inside observer during timer commit (engine-like thread), then Set/Cancel while suspended", function()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Throttle({ Time = 1, Handle = h }))
	local park = false
	local r = obs(g, function() if park then park = false; coroutine.yield() end end)
	s:Set(1); s:Set(2)
	park = true
	local co = coroutine.create(function() adv(1) end)
	print(`  resume1`, coroutine.resume(co))
	print(`  suspended: {coroutine.status(co)} seen={S(r)} pending={P()}`)
	s:Set(3) -- window nil, Blocker On
	print(`  Set(3) while suspended: seen={S(r)} pending={P()}`)
	print(`  resume2`, coroutine.resume(co))
	adv(5)
	print(`  settle {S(r)} pending={P()}`)
end)

-- ── (3) composition ─────────────────────────────────────────────
T("C1 Debounce -> Blocker(On): expiry pushed behind blocker; Off later", function()
	local s = Source(0)
	local bl = Blocker()
	local g = s:Apply(Debounce({ Time = 1 })):Apply(bl)
	local r = obs(g)
	bl:On()
	s:Set(1); adv(1)
	print(`  expired under blocker: {S(r)} pending={P()}`)
	adv(1)
	print(`  +1 (debounce reopened window idles): pending={P()}`)
	bl:Off()
	print(`  Off: {S(r)}`)
end)

T("C1b Debounce -> Blocker(On); Blocker:OffWithoutEmit drops expiry", function()
	local s = Source(0)
	local bl = Blocker()
	local g = s:Apply(Debounce({ Time = 1 })):Apply(bl)
	local r = obs(g)
	bl:On()
	s:Set(1); adv(2)
	bl:OffWithoutEmit()
	print(`  {S(r)} get={g:Get()}`)
	s:Set(2); adv(1)
	print(`  next {S(r)}`)
end)

T("C2 Blocker(On) -> Debounce: timers never start until Off", function()
	local s = Source(0)
	local bl = Blocker()
	local g = s:Apply(bl):Apply(Debounce({ Time = 1 }))
	local r = obs(g)
	bl:On()
	s:Set(1); adv(5)
	print(`  pending={P()} seen={S(r)}`)
	bl:Off()
	print(`  Off: pending={P()} seen={S(r)}`)
	adv(1)
	print(`  +1 {S(r)}`)
end)

T("C3 Gate(hold) inside Debounce and Debounce inside Gate", function()
	local s = Source(0)
	local rel
	local g = s:Gate(function(emit) rel = emit; return function() end end):Apply(Debounce({ Time = 1 }))
	local r = obs(g)
	s:Set(1); adv(2)
	print(`  held: {S(r)}`)
	rel(); print(`  released sync: {S(r)} pending={P()}`)
	adv(1); print(`  +1 {S(r)}`)
	local rel2
	local s2 = Source(0)
	local g2 = s2:Apply(Debounce({ Time = 1 })):Gate(function(emit) rel2 = emit; return function() end end)
	local r2 = obs(g2)
	s2:Set(1); adv(1)
	print(`  debounce expired into hold: {S(r2)} pending={P()}`)
	print(`  rel2()={rel2()} {S(r2)}`)
end)

T("C4 Debounce gate unreferenced while timer pending & downstream Blocker closed — GC", function()
	local s = Source(0)
	local bl = Blocker()
	local wk = setmetatable({}, { __mode = "v" })
	do
		local d = s:Apply(Debounce({ Time = 1 }))
		local b2 = d:Apply(bl)
		wk.d, wk.b2 = d, b2
		bl:On()
		s:Set(1)
	end
	collectgarbage(); collectgarbage()
	print(`  pending timer, collected? d={wk.d == nil} b2={wk.b2 == nil} pending={P()}`)
	adv(1)
	collectgarbage(); collectgarbage()
	print(`  after expiry: d={wk.d == nil} b2={wk.b2 == nil} pending={P()}`)
	adv(1)
	collectgarbage(); collectgarbage()
	print(`  after 2xTime: d={wk.d == nil} b2={wk.b2 == nil} pending={P()}`)
	bl:Off()
	print(`  bl:Off() no crash`)
end)

T("C5 Effect cleanup calls factory:Cancel() — rerun path", function()
	local s = Source(0)
	local f = Debounce({ Time = 1 })
	local g = s:Apply(f)
	local r = obs(g)
	local dep = Source(0)
	local e = Effect(function(use)
		return function() f:Cancel() end
	end, dep):Subscribe()
	s:Set(1)
	dep:Set(1) -- rerun -> cleanup -> Cancel
	adv(2)
	print(`  {S(r)} pending={P()}`)
end)

-- ── (4) docs: Flush no-op leaves running window; Cancel leaves Get latest ─
T("D1 Flush with nothing withheld inside Throttle window (after leading) — window untouched?", function()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Throttle({ Time = 1, Handle = h }))
	local r = obs(g)
	s:Set(1)
	adv(0.5)
	h:Unwrap():Flush()
	s:Set(2)
	print(`  Set(2)@0.5 after no-op Flush: {S(r)} (withheld expected)`)
	adv(0.5)
	print(`  @1: {S(r)}`)
end)

T("D2 Cancel then :Get() latest; Throttle Cancel mid-window then signal is leading?", function()
	local s = Source(0)
	local h = Ref(nil)
	local g = s:Apply(Throttle({ Time = 1, Handle = h }))
	local r = obs(g)
	s:Set(1); s:Set(2)
	h:Unwrap():Cancel()
	print(`  get={g:Get()} pending={P()}`)
	s:Set(3)
	print(`  Set(3) right after Cancel: {S(r)} (Cancel → idle → leading passes)`)
end)

-- ── (5) self-cancel of running timer? instrument ops ──────────────
T("E1 instrument: does any quad path clearTimeout the currently running timer?", function()
	local running = nil
	local real_set, real_clear = q.Backend.setTimeout, q.Backend.clearTimeout
	local selfClears = 0
	q.Backend.setTimeout = function(fn, d)
		local tok
		tok = real_set(function() local prev = running; running = tok; fn(); running = prev end, d)
		return tok
	end
	q.Backend.clearTimeout = function(t) if t == running then selfClears += 1 end; real_clear(t) end
	for _, mk in { function() return Debounce({ Time = 1, MaxTime = 1 }) end, function() return Debounce({ Time = 1, MaxTime = 1.5, Leading = true }) end,
		function() return Throttle({ Time = 1 }) end, function() return Debounce({ Time = 0, MaxTime = 0 }) end } do
		local s = Source(0)
		local h = Ref(nil)
		local f = mk()
		local g = s:Apply(f)
		local k = 0
		obs(g, function() k += 1; if k % 3 == 0 then s:Set(1000 + k) elseif k % 5 == 0 then f:Flush() elseif k % 7 == 0 then f:Cancel() end end)
		for i = 1, 60 do s:Set(i); adv(0.3) end
		adv(10)
	end
	q.Backend.setTimeout, q.Backend.clearTimeout = real_set, real_clear
	print(`  self clears = {selfClears}`)
end)

T("C5b Effect cleanup Cancel — baseline without Cancel to compare", function()
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 1 }))
	local r = obs(g)
	s:Set(1); adv(2)
	print(`  {S(r)}`)
end)

T("A5d Time read throws inside s:Set — do sibling subscribers of s still hear the signal? (20 trials, hash order)", function()
	local heard, missed = 0, 0
	for i = 1, 20 do
		local tS = Source(-1)
		local s = Source(0)
		local sib = {}
		for k = 1, 3 do sib[k] = obs(s) end
		local g = s:Apply(Debounce({ Time = tS }))
		for k = 4, 6 do sib[k] = obs(s) end
		pcall(function() s:Set(1) end)
		for k = 1, 6 do if #sib[k].seen == 1 then heard += 1 else missed += 1 end end
	end
	print(`  sibling observers heard={heard} missed={missed}`)
end)

T("B1f Throttle baseline (no throw): after idle, Set passes leading", function()
	local s = Source(0)
	local g = s:Apply(Throttle({ Time = 1 }))
	local r = obs(g)
	s:Set(1); s:Set(2); adv(1); adv(5); s:Set(3)
	print(`  {S(r)}`)
end)

T("D3 MaxTime doc claim: 0.1s signals, Time=0.3, MaxTime=1 → pass intervals 1.0~1.1", function()
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 0.3, MaxTime = 1 }))
	local times = {}
	g:Observer(function() times[#times + 1] = mock.now() end):Subscribe()
	times = {}
	for i = 1, 60 do s:Set(i); adv(0.1) end
	local iv = {}
	for i = 2, #times do iv[#iv + 1] = string.format("%.2f", times[i] - times[i - 1]) end
	print(`  passes={#times} intervals={table.concat(iv, ",")}`)
end)

T("D4 MaxTime=0 with Time=1 (accepted) and chained Debounce(0)->Debounce(0) in one advance(0)", function()
	local s = Source(0)
	local g = s:Apply(Debounce({ Time = 1, MaxTime = 0 }))
	local r = obs(g)
	s:Set(1); s:Set(2)
	adv(0)
	print(`  MaxTime=0: {S(r)} pending={P()}`)
	local s2 = Source(0)
	local g2 = s2:Apply(Debounce({ Time = 0 })):Apply(Debounce({ Time = 0 })):Apply(Throttle({ Time = 0 }))
	local r2 = obs(g2)
	s2:Set(1); s2:Set(2)
	adv(0)
	print(`  chain of three 0-gates: {S(r2)} pending={P()}`)
end)
