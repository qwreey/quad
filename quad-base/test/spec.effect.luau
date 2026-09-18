--[[
	Effect 계약 — `.claude/base/effect-plan.md` "확정 구조" / "의사코드 — 생성자" / `_bindDestroying` /
	`_unbindDestroying` / `_consumeCleanup` / `rawRerun`+`Rerun` / "`Effect:Subscribe()`" /
	"`Effect(fn, ...deps)`". `H-70`/`H-107`/`H-144`/`H-147`/`H-150`/`H-151`/`H-159`/`H-160`/`H-182`/`H-184`.
]]

local Quad = require("../src")
local mock = require("./mock")
local QuadTypes = require("../luau_packages/quad_types")

type Effect = QuadTypes.Effect

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

local quad = Quad.New()
mock.installLifetime(quad)
local Source, Ref, Effect = quad.Source, quad.Ref, quad.Effect
local Instance = mock.Instance

print("=== 1. 생성 — deps 검증(H-70), 설치 즉시 1회(force), _deps 강한 주인, 브랜드 ===")
do
	local s = Source(1)
	local r = Ref(1)
	local runs = 0
	local e = Effect(function(self)
		runs += 1
		assert(quad.isEffect(self), "fn receives the handle")
	end, s, r, s) -- duplicate dep is ignored
	assert(runs == 1, "installed once on creation, before any binding (force)")
	assert((e :: any).__quadEffect == true, "EffectMarker field readable (H-300, 2026-09-07 마커 전면화)")
	assert(quad.isEffect(e) and not quad.isObserver(e), "brand")
	local depCount = 0
	for _ in pairs((e :: any)._deps) do
		depCount += 1
	end
	assert(depCount == 2, "duplicate dep collapsed; one entry per dep")
	local bads: { { value: any, message: string } } = {
		{ value = nil, message = "is nil" },
		{ value = {}, message = "not a State/Source/Ref" },
		{ value = 5, message = "not a State/Source/Ref" },
	}
	for _, bad in bads do
		local ok, err = pcall(function()
			Effect(function() end, s, bad.value)
		end)
		assert(not ok and string.find(tostring(err), bad.message, 1, true) ~= nil, "dep #2 " .. bad.message .. ": " .. tostring(err))
		assert(string.find(tostring(err), "spec.effect.luau", 1, true) ~= nil, "level 2")
	end
	assert(not pcall(function()
		Effect(5 :: any)
	end), "fn must be a function")
	print("PASS")
end

print()
print("=== 2. 발화 — 안 묶이면 홀드(H-159), 묶이면 dep 변경마다 1회; Ref dep도 같은 경로 ===")
do
	local s, r = Source(1), Ref(1)
	local runs = 0
	local e = Effect(function()
		runs += 1
	end, s, r)
	s:Set(2)
	r:Set(2)
	assert(runs == 1 and (e :: any)._rerunRequired == true, "unbound: changes held, not run")
	local inst = Instance.new("Frame")
	quad.Backend.bindLifetime(inst, e)
	assert(runs == 2 and (e :: any)._rerunRequired == false, "bind replays the hold exactly once (not per change)")
	s:Set(3)
	assert(runs == 3, "State dep fires")
	r:Set(3)
	assert(runs == 4, "Ref dep fires")
	quad.Backend.unbindLifetime(e)
	s:Set(4)
	assert(runs == 4, "unbound again: silent (held)")
	print("PASS")
end

print()
print("=== 3. 다이아몬드 — 공통 상류가 한 번 바뀌면 fn은 한 번 (H-107: 클로저를 나눠도 dedup은 _epochs) ===")
do
	local a = Source(1)
	local b = a:Compute(function(x): number
		return x:Get() + 1
	end)
	local c = a:Compute(function(x): number
		return x:Get() + 2
	end)
	local runs = 0
	local e = Effect(function()
		runs += 1
	end, b, c):Subscribe()
	runs = 0
	a:Set(5)
	assert(runs == 1, "one Set → one run, got " .. runs)
	e:Unsubscribe()
	print("PASS")
end

print()
print("=== 4. cleanup — fn의 반환이 cleanup, 다음 fn 전에 1회, Unsubscribe가 소진, 파괴가 소진 ===")
do
	local s = Source(1)
	local log: { string } = {}
	local e = Effect(function()
		table.insert(log, "run")
		return function()
			table.insert(log, "clean")
		end
	end, s):Subscribe()
	s:Set(2)
	assert(table.concat(log, ",") == "run,clean,run", "cleanup runs right before the next fn")
	e:Unsubscribe()
	assert(table.concat(log, ",") == "run,clean,run,clean", "Unsubscribe consumes the cleanup exactly once")
	assert((e :: any)._rerunRequired == true, "consumed = must reinstall next time")
	-- 재구독 → 꼬리가 1회 재실행(H-144)
	e:Subscribe()
	assert(table.concat(log, ",") == "run,clean,run,clean,run", "resubscribe replays once")
	e:Unsubscribe()
	-- leaf 파괴 → Destroying 콜백이 cleanup 소진
	log = {}
	local inst = Instance.new("Frame")
	local e2 = Effect(function()
		table.insert(log, "run")
		return function()
			table.insert(log, "clean")
		end
	end, s)
	quad.Backend.bindLifetime(inst, e2)
	assert(table.concat(log, ",") == "run", "bound: no replay (nothing held)")
	inst:Destroy()
	assert(table.concat(log, ",") == "run,clean", "Destroying consumed the cleanup")
	assert((e2 :: any)._destroyConn == nil, "connection dropped")
	quad.Backend.unbindLifetime(e2) -- 죽은 뒤에도 안전(no-op)
	print("PASS")
end

print()
print("=== 5. cleanup 없는 fn — 바인드/재마운트마다 재실행되지 않는다 (_rerunRequired 판정, H-58 회귀 방지) ===")
do
	local s = Source(1)
	local runs = 0
	local e = Effect(function()
		runs += 1
	end, s)
	local a, b = Instance.new("Frame"), Instance.new("Frame")
	quad.Backend.bindLifetime(a, e)
	quad.Backend.unbindLifetime(e)
	quad.Backend.bindLifetime(b, e)
	assert(runs == 1, "no held change → no re-run on (re)bind, got " .. runs)
	print("PASS")
end

print()
print("=== 6. 재진입 — fn 안의 dep:Set은 지연 재실행(_pending); fn/cleanup은 자기 구독을 못 바꾼다 (H-147) ===")
do
	local s = Source(0)
	local runs = 0
	local e: any
	e = Effect(function()
		runs += 1
		if s:Get() == 0 then
			s:Set(1) -- re-entrant change during fn
		end
	end, s):Subscribe()
	assert(runs == 2 and s:Get() == 1, "deferred re-run happened once after fn returned");
	(e :: any):Unsubscribe()

	local caught: { string } = {}
	local e2: any
	e2 = Effect(function(self)
		for _, name in { "Subscribe", "WeakSubscribe", "Unsubscribe", "WeakUnsubscribe" } do
			local ok = pcall(function()
				(self :: any)[name](self)
			end)
			if not ok then
				table.insert(caught, name)
			end
		end
		return function()
			local ok = pcall(function()
				e2:Subscribe()
			end)
			if not ok then
				table.insert(caught, "cleanup:Subscribe")
			end
		end
	end, s)
	-- round11 Q63 (b): only the SUBSCRIBE entries are gated on `isRunning`; `Unsubscribe` here is refused by
	-- its own strictness gate (never strongly subscribed), and `WeakUnsubscribe` is lenient — passes silently
	assert(table.concat(caught, ",") == "Subscribe,WeakSubscribe,Unsubscribe", "subscribe entries refuse inside fn, releasing is not gated; got " .. table.concat(caught, ","))
	e2:Subscribe()
	e2:Unsubscribe() -- runs the cleanup → its Subscribe attempt must error too
	assert(caught[#caught] == "cleanup:Subscribe", "entry points refuse inside cleanup too")
	print("PASS")
end

print()
print("=== 7. 네 진입점 — 게이트·관대/엄격·강한 킵 뒤 꼬리, canExecute 연동 ===")
do
	local s = Source(1)
	local runs = 0
	local e = Effect(function()
		runs += 1
	end, s)
	assert(quad.Backend.canExecute(e) == false, "unbound")
	s:Set(2) -- held
	assert(e:WeakSubscribe() == e and e.Subscribed == true and quad.Backend.canExecute(e) == true, "weak primitive")
	assert(runs == 2, "tail replayed the hold")
	assert(not pcall(function()
		e:Subscribe()
	end), "already subscribed")
	e:WeakUnsubscribe()
	assert((e :: any).Subscribed == false, "lenient release")
	e:WeakUnsubscribe() -- silent
	e:Subscribe()
	assert(not pcall(function()
		e:WeakUnsubscribe()
	end), "strong keep present → error")
	e:Unsubscribe()
	assert(not pcall(function()
		e:Unsubscribe()
	end), "strict")
	local ok, err = pcall(function()
		quad.Backend.bindLifetime(Instance.new("Frame"), Effect(function() end, s):Subscribe())
	end)
	assert(not ok and string.find(tostring(err), "already subscribed", 1, true) ~= nil, "bindLifetime shares the gate: " .. tostring(err))
	print("PASS")
end

print()
print("=== 8. error — fn이 던지면 그 Effect는 죽는다(_running 남음), 재실행·(재)구독은 차단; round11 Q63 (b): 해제(Unsubscribe/WeakUnsubscribe)는 통과해 강한 킵이 풀린다 ===")
do
	local s = Source(1)
	local e = Effect(function()
		if s:Get() == 2 then
			error("boom")
		end
	end, s):Subscribe()
	local ok = pcall(function()
		s:Set(2)
	end)
	assert(not ok, "the error propagated out of Set (no pcall inside quad)")
	assert((e :: any)._running == true, "dead: _running stays set")
	s:Set(1) -- 발화는 _pending으로만 기록되고 fn은 안 돈다
	assert(not pcall(function()
		e:Subscribe()
	end), "(re)subscribing is blocked on a dead handle")
	e:Unsubscribe() -- used to be refused too → the strong keep held the dead handle forever
	assert(e.Subscribed == false, "released")
	local ok2 = pcall(function() e:Unsubscribe() end)
	assert(not ok2, "second Unsubscribe: the strictness gate still applies")
	-- fn이 자기를 해제하고 cleanup을 돌려주는 모양: Unsubscribe는 fn을 안 부르고, 돌려준 cleanup은 rawRerun 꼬리가 즉시 소진(Q68 (b))
	local cleaned = 0
	local s2 = Source(0)
	local e2: any
	e2 = Effect(function()
		if s2:Get() == 1 then e2:Unsubscribe() end -- not on the install run (e2 is not assigned yet there)
		return function() cleaned += 1 end
	end, s2):Subscribe()
	s2:Set(1) -- rerun: old cleanup consumed (1), fn unsubscribes itself, its NEW cleanup is consumed at once (2)
	assert(e2.Subscribed == false and cleaned == 2 and (e2 :: any)._cleanup == nil, "self-unsubscribe inside fn: released, returned cleanup consumed at once: " .. cleaned)
	print("PASS")
end

print()
print("=== 9. GC — Effect가 강한 주인: 핸들을 놓으면 Ref 콜백·내부 Observer도 같이 사라진다 ===")
do
	local s, r = Source(1), Ref(1)
	local weak = setmetatable({}, { __mode = "v" }) :: { any }
	local function make()
		weak[1] = Effect(function() end, s, r)
	end
	make()
	collectgarbage()
	collectgarbage()
	assert(weak[1] == nil, "an unowned Effect is collectable")
	assert(next(r.WeakCallbacks) == nil, "its Ref callback went with it")
	assert(next((s :: any)._subs) == nil, "and its internal Observer left the State's subscriber set")
	-- 강한 구독은 살려둔다
	local calls = 0
	local function makeStrong()
		Effect(function()
			calls += 1
		end, s):Subscribe()
	end
	makeStrong()
	collectgarbage()
	collectgarbage()
	calls = 0
	s:Set(9)
	assert(calls == 1, "strongly subscribed Effect survives with no references")
	print("PASS")
end

print()
print("=== 10. H-182 — Destroy 파동 안 cleanup 소진 뒤의 dep 변경은 홀드(_dying); H-184 — 거부된 bind는 아무것도 커밋 안 함 ===")
do
	-- H-182 재현(리뷰 실측 모양): parent의 Destroying(A cleanup)이 먼저, child의
	-- Destroying(B cleanup)이 그 파동 후반에 dep을 Set — gcconn은 파동 끝에 끊기므로
	-- canExecute만으론 A가 죽는 중임을 못 본다.
	local count = Source(0)
	local parent = Instance.new("Frame")
	local child = Instance.new("Frame")
	child.Parent = parent
	local runsA = 0
	local cleansA = 0
	local A: any = Effect(function()
		runsA += 1
		return function()
			cleansA += 1
		end
	end, count)
	quad.Backend.bindLifetime(parent, A)
	local B = Effect(function()
		return function()
			count:Set(-1) -- fires A's internal observer mid-wave, after A's Destroying ran
		end
	end)
	quad.Backend.bindLifetime(child, B)
	assert(runsA == 1 and cleansA == 0, "setup: one install run")
	parent:Destroy()
	assert(cleansA == 1, "A's cleanup ran exactly once in the wave")
	assert(runsA == 1, "the mid-wave dep change did NOT re-run fn on the dying leaf (_dying holds)")
	assert(A._cleanup == nil, "no cleanup was stored that nothing would consume")
	assert(A._rerunRequired == true, "the change was held, not dropped")
	-- 재무장: 재바인드가 _dying을 내리고 홀드를 1회 재생
	local fresh = Instance.new("Frame")
	quad.Backend.bindLifetime(fresh, A)
	assert(runsA == 2, "rebinding replays the held change once")
	assert(A._dying == false, "rebind re-armed the handle")
	fresh:Destroy()
	-- Subscribe 경로도 재무장한다
	assert(A._dying == true, "its own Destroying raised the flag again")
	A:Subscribe()
	assert(A._dying == false and runsA == 3, "Subscribe re-arms and replays the hold")
	A:Unsubscribe()
	-- H-184: fn 안의 bindLifetime은 커밋 전에 거부된다 — 반쯤 묶인 핸들이 없다
	local inst2 = Instance.new("Frame")
	local bindErr: any = nil
	local C: any = Effect(function(self)
		local ok, err = pcall(function()
			quad.Backend.bindLifetime(inst2, self)
		end)
		if not ok then
			bindErr = tostring(err)
		end
	end)
	assert(bindErr ~= nil and string.find(bindErr, "inside its own fn or cleanup", 1, true) ~= nil, "bind inside fn refused: " .. tostring(bindErr))
	assert(quad.Backend.canBound(C), "nothing was committed — not half-bound")
	quad.Backend.bindLifetime(inst2, C)
	assert(quad.Backend.canExecute(C), "binds cleanly afterwards")
	print("PASS")
end

print()
print()
print("=== 4순회 H-384 — fn 안에서 자기 자신을 drive로 바인드하려는 오용(H-147 (A)) — blame은 사용자의 Effect 생성 줄 (fn은 생성 시 즉시 돈다; drive → process → bindLifetime → _assertBindable, 최외곽) ===")
do
	local inner = mock.Instance.new("Frame")
	local ok, err = pcall(function()
		Effect(function(self)
			quad.Dispatch.drive(inner, { self })
		end)
	end)
	assert(not ok and string.find(tostring(err), "cannot bind an Effect from inside its own fn", 1, true) ~= nil, "guard fires: " .. tostring(err))
	mock.assertBlamesUser(err, "spec.effect.luau", "drive-depth _assertBindable blames the user, not Effect.luau")
	print("PASS")
end

print()
print("=== 공개 표면 (18) 2026-09-15 — fn이 함수도 nil도 아닌 값을 돌려주면 그 자리에서 던진다(사용자 줄 blame) ===")
do
	-- 생성 시점: fn은 생성자에서 즉시 돈다 → 생성 줄 blame
	local okNum, errNum = pcall(function()
		Effect((function()
			return 42
		end :: any))
	end)
	assert(not okNum and string.find(tostring(errNum), "Effect: fn must return a cleanup function or nothing (got number)", 1, true) ~= nil, "install-time non-function return: " .. tostring(errNum))
	mock.assertBlamesUser(errNum, "spec.effect.luau", "install-time return check blames the user")
	-- 전파 시점: 첫 실행은 정상, 연결 객체를 돌려주는 회차에서 :Set 줄 blame
	local s = Source(1)
	local e = Effect((function(): any
		if s:Get() == 2 then
			return { Disconnect = function() end }
		end
		return nil
	end :: any), s):Subscribe()
	local okSet, errSet = pcall(function()
		s:Set(2)
	end)
	assert(not okSet and string.find(tostring(errSet), "(got table)", 1, true) ~= nil, "emit-time non-function return: " .. tostring(errSet))
	mock.assertBlamesUser(errSet, "spec.effect.luau", "emit-time return check blames the user")
	assert((e :: any)._running == true, "the Effect dies exactly as when fn throws")
	print("PASS")
end

print()
print("=== round10 Q51 (a) (2026-09-17) — cleanup 안의 dep Set은 뒤따르는 fn이 소비한다: 사이클 하나(cl fn), 옛 순서의 cl fn cl fn이 아니다 ===")
do
	local a = Source(1)
	local log = {}
	local once = true
	local e = Effect(function()
		table.insert(log, "fn" .. tostring(a:Get()))
		return function()
			table.insert(log, "cl")
			if once then
				once = false
				a:Set(99) -- inside the cleanup: the fn that follows reads 99
			end
		end
	end, a):Subscribe()
	assert(table.concat(log, " ") == "fn1", "install")
	a:Set(2) -- cleanup runs (Sets 99), then fn reads 99 — no extra cycle
	assert(table.concat(log, " ") == "fn1 cl fn99", "one cycle, fn saw the cleanup's Set: " .. table.concat(log, " "))
	-- a Set DURING fn still queues one more run (that is what `_pending` is for)
	local inFn = true
	local log2 = {}
	local b = Source(1)
	local e2 = Effect(function()
		table.insert(log2, "fn" .. tostring(b:Get()))
		if inFn then
			inFn = false
			b:Set(5)
		end
	end, b):Subscribe()
	assert(table.concat(log2, " ") == "fn1 fn5", "a Set inside fn re-runs once: " .. table.concat(log2, " "))
	e:Unsubscribe(); e2:Unsubscribe()
	print("PASS")
end

print()
print("=== round10 Q57 (2026-09-17, 사용자 제안) — cleanup(dying): 잎 사망 소진만 true, 재실행 직전·Unsubscribe·자리 교체는 false; () -> () cleanup은 그대로 ===")
do
	local seen = {}
	local function mk(tag: string)
		return function()
			return function(dying: boolean)
				table.insert(seen, tag .. ":" .. tostring(dying))
			end
		end
	end
	-- (1) rerun before fn
	local a = Source(1)
	local e1 = Effect(mk("rerun"), a):Subscribe()
	a:Set(2)
	-- (2) Unsubscribe
	e1:Unsubscribe()
	-- (3) value-swap retract at a numeric-key seat (inst alive)
	local inst = Instance.new("Frame")
	local seat = Source(Effect(mk("swap")) :: any)
	quad.Dispatch.drive(inst, { seat })
	seat:Set(nil)
	-- (4) leaf death
	local inst2 = Instance.new("Frame")
	quad.Dispatch.drive(inst2, { Effect(mk("death")) })
	inst2:Destroy()
	assert(table.concat(seen, " ") == "rerun:false rerun:false swap:false death:true", "dying per site: " .. table.concat(seen, " "))
	-- an arity-0 cleanup still works
	local plain = 0
	local inst3 = Instance.new("Frame")
	quad.Dispatch.drive(inst3, { Effect(function() return function() plain += 1 end end) })
	inst3:Destroy()
	assert(plain == 1, "() -> () cleanup unchanged")
	print("PASS")
end

print()
print("=== 11. round11 H-574 (2026-09-17, Deferred 실측) — 호스트가 죽은 뒤 같은 청크에서 다른 인스턴스에 다시 묶인 핸들은 옛 Destroying 콜백(지연 배달)에 죽지 않는다 ===")
do
	-- Roblox default SignalBehavior.Deferred: `Destroying` handlers run at the next resume point while
	-- Destroy cuts gcconn synchronously. Model it by queueing what quad's onDestroying registers.
	local origOnDestroying = quad.Backend.onDestroying
	local queue = {}
	quad.Backend.onDestroying = function(inst: any, fn: () -> ()): any
		return origOnDestroying(inst, function()
			table.insert(queue, fn)
		end)
	end
	local function flush()
		local q = queue
		queue = {}
		for _, fn in q do
			fn()
		end
	end
	local dep = Source(0)
	local runs, cleanups = 0, {}
	local eff = Effect(function()
		runs += 1
		return function(dying: boolean)
			table.insert(cleanups, dying)
		end
	end, dep)
	local host1 = Instance.new("Frame")
	quad.Dispatch.drive(host1, { eff })
	host1:Destroy() -- gcconn cut now; the Destroying callback is queued
	local host2 = Instance.new("Frame")
	quad.Dispatch.drive(host2, { eff }) -- rebind inside the same chunk (a row cache re-using its hook handle)
	flush() -- the OLD callback arrives now — it must not touch the new binding
	dep:Set(1)
	assert(runs == 2, "fn still runs on the new host (was held forever): " .. runs)
	assert(#cleanups == 1 and cleanups[1] == false, "only the rerun cleanup so far, dying=false: " .. #cleanups)
	host2:Destroy()
	flush()
	assert(#cleanups == 2 and cleanups[2] == true, "the real death runs the cleanup once with dying=true: " .. #cleanups)
	dep:Set(2)
	assert(runs == 2, "dead after the real death")
	quad.Backend.onDestroying = origOnDestroying
	print("PASS")
end

print()
print()
print("=== 12. round11 Q68 (b) (2026-09-18) — fn이 yield하는 사이 leaf가 죽으면(_dying) fn이 돌려준 cleanup을 저장하지 않고 즉시 dying=true로 소진(전엔 죽은 핸들에 남는 영구 누수); 자리 철거로 실행 자격을 잃은 경우도 같다 ===")
do
	-- (1) yield + host death
	local s = Source(0)
	local host = Instance.new("Frame")
	local cleaned, dyingArg = 0, nil
	local e = Effect(function()
		if s:Get() == 1 then
			coroutine.yield() -- the "network round trip" — UB by contract, but the most common shape
		end
		return function(d: boolean) cleaned += 1; dyingArg = d end
	end, s)
	quad.Backend.bindLifetime(host, e)
	local co = coroutine.create(function() s:Set(1) end)
	assert(coroutine.resume(co) and coroutine.status(co) == "suspended", "fn is parked mid-run")
	assert(cleaned == 1 and dyingArg == false, "the install cleanup was consumed before fn ran (rerun)")
	host:Destroy() -- Destroying → _dying, _consumeCleanup on an empty slot (no-op)
	assert(cleaned == 1, "nothing to consume yet")
	assert(coroutine.resume(co), "fn resumes and returns its cleanup")
	assert(cleaned == 2 and dyingArg == true and (e :: any)._cleanup == nil, "consumed at once with dying = true, not stored: cleaned=" .. cleaned)
	assert(not quad.Backend.canExecute(e), "dead handle")
	-- (2) yield + position retract (unbind, host alive): consumed with dying = false
	local s2 = Source(0)
	local host2 = Instance.new("Frame")
	local cleaned2, dying2 = 0, nil
	local e2 = Effect(function()
		if s2:Get() == 1 then coroutine.yield() end
		return function(d: boolean) cleaned2 += 1; dying2 = d end
	end, s2)
	quad.Backend.bindLifetime(host2, e2)
	local co2 = coroutine.create(function() s2:Set(1) end)
	coroutine.resume(co2)
	quad.Backend.unbindLifetime(e2) -- the position retracts while fn is parked
	assert(quad.Backend.canBound(e2), "unbound")
	coroutine.resume(co2)
	assert(cleaned2 == 2 and dying2 == false and (e2 :: any)._cleanup == nil, "consumed at once (dying = false), not stored: " .. cleaned2)
	-- (3) code-review: fn Sets a dep (→ _pending), unsubscribes itself, returns NOTHING — the loop must not run
	-- fn again on the dead handle (it used to, and died in the second Unsubscribe with _running stuck)
	local a, b = Source(0), Source(0)
	local runs3 = 0
	local e3: any
	e3 = Effect(function()
		runs3 += 1
		if a:Get() == 1 then
			b:Set(b:Get() + 1) -- re-entrant request while running
			e3:Unsubscribe()
			return
		end
		return function() end
	end, a, b):Subscribe()
	a:Set(1) -- used to throw "not subscribed strongly" out of this line
	assert(runs3 == 2 and e3.Subscribed == false and (e3 :: any)._running == false, "fn ran once for the Set, handle released, not stuck: runs=" .. runs3)
	-- (4) code-review: the CLEANUP unsubscribes the handle — fn must not run after it, and the nested
	-- consume must not throw nor lower `_cleanupRunning` for the outer cleanup's tail
	local d = Source(0)
	local runs4, subInCleanup = 0, nil
	local e4: any
	e4 = Effect(function()
		runs4 += 1
		return function()
			e4:Unsubscribe()
			subInCleanup = pcall(function() e4:Subscribe() end) -- still inside a cleanup → gated
		end
	end, d):Subscribe()
	d:Set(1) -- used to throw from inside _consumeCleanup, leaving _running AND _cleanupRunning stuck
	assert(runs4 == 1 and e4.Subscribed == false and (e4 :: any)._running == false and (e4 :: any)._cleanupRunning == false, "cleanup released the handle; fn did not run again; flags clean")
	assert(subInCleanup == false, "Subscribe inside the rest of the cleanup is still gated (save/restore)")
	print("PASS")
end

print("=== ALL PASS ===")
