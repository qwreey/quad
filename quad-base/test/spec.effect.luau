--[[
	Effect 계약 — `.claude/base/effect-plan.md` "확정 구조" / "의사코드 — 생성자" / `_bindDestroying` /
	`_unbindDestroying` / `_consumeCleanup` / `rawRerun`+`Rerun` / "`EffectHandle:Subscribe()`" /
	"`Effect(fn, ...deps)`". `H-70`/`H-107`/`H-144`/`H-147`/`H-150`/`H-151`/`H-159`/`H-160`.
]]

local Quad = require("../src")
local mock = require("./mock")
local QuadTypes = require("../roblox_packages/quad_types")

type EffectHandle = QuadTypes.EffectHandle

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
	quad.bindLifetime(inst, e)
	assert(runs == 2 and (e :: any)._rerunRequired == false, "bind replays the hold exactly once (not per change)")
	s:Set(3)
	assert(runs == 3, "State dep fires")
	r:Set(3)
	assert(runs == 4, "Ref dep fires")
	quad.unbindLifetime(e)
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
	quad.bindLifetime(inst, e2)
	assert(table.concat(log, ",") == "run", "bound: no replay (nothing held)")
	inst:Destroy()
	assert(table.concat(log, ",") == "run,clean", "Destroying consumed the cleanup")
	assert((e2 :: any)._destroyConn == nil, "connection dropped")
	quad.unbindLifetime(e2) -- 죽은 뒤에도 안전(no-op)
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
	quad.bindLifetime(a, e)
	quad.unbindLifetime(e)
	quad.bindLifetime(b, e)
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
	assert(#caught == 4, "all four entry points refuse inside fn, got " .. table.concat(caught, ","))
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
	assert(quad.canExecute(e) == false, "unbound")
	s:Set(2) -- held
	assert(e:WeakSubscribe() == e and e.Subscribed == true and quad.canExecute(e) == true, "weak primitive")
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
		quad.bindLifetime(Instance.new("Frame"), Effect(function() end, s):Subscribe())
	end)
	assert(not ok and string.find(tostring(err), "already subscribed", 1, true) ~= nil, "bindLifetime shares the gate: " .. tostring(err))
	print("PASS")
end

print()
print("=== 8. error — fn이 던지면 그 Effect는 죽는다(_running 남음), 이후 재진입 전부 차단 ===")
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
		e:Unsubscribe()
	end), "entry points are blocked on a dead handle")
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
print("=== ALL PASS ===")
