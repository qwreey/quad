--[[
	Observer 계약 — `.claude/base/source-state-plan.md` "전파 루프 — 확정 의사코드"(`_receive`/`_catchUp`/
	생성자 순서) / "`state:Observer(fn)`" 절(등록 즉시 1회, `fn(targetState, self, emitFrom?)`, `nil` 계약),
	`.claude/base/lifecycle-pattern.md` "(2) 전역 경로"(네 진입점) / "(4) 실제 호출부"(`canExecute` 게이팅).
]]

local Quad = require("../src")
local mock = require("./mock")
local QuadTypes = require("../roblox_packages/quad_types")

type Observer = QuadTypes.Observer

-- strict 모드에서 `collectgarbage`는 선언 안 된 전역 — 표준 luau CLI엔 있다(Roblox엔 없음)
local collectgarbage = (_G :: any).collectgarbage :: () -> ()

local quad = Quad.New()
mock.installLifetime(quad)
local Source = quad.Source
local Instance = mock.Instance

print("=== 1. 생성 — 등록 즉시 1회(emitFrom = nil), _state 강참조, 브랜드, 순서(fn → _subs) ===")
do
	local s = Source(1)
	local calls: { any } = {}
	local o = s:Observer(function(target, self, from)
		table.insert(calls, { target = target, self = self, from = from })
	end)
	assert(#calls == 1 and calls[1].target == s and calls[1].self == o and calls[1].from == nil, "install fire: (state, observer, nil)")
	assert(quad.isObserver(o) and not quad.isState(o) and not quad.isEpoch(o), "brand")
	assert((o :: any)._state == s, "observer holds its State strongly")
	assert((s :: any)._subs[o] == true, "joined the subscriber set after the install fire")
	assert((o :: any)._rerunRequired == false, "install fire lowered the hold flag")
	-- 설치 발화가 자기 State를 Set해도 플래그가 서지 않는다(순서 계약)
	local s2 = Source(0)
	local o2 = s2:Observer(function(target, _, from)
		if from == nil and target:Get() == 0 then
			(target :: any):Set(1)
		end
	end)
	assert((o2 :: any)._rerunRequired == false, "fn → _subs order: the install fire's own Set did not raise the flag")
	print("PASS")
end

print()
print("=== 2. _receive — canExecute 게이팅: 안 묶이면 홀드, 묶이면 fn(state, self, from) ===")
do
	local s = Source(1)
	local calls: { { from: any } } = {} -- `table.insert(t, nil)`은 길이를 안 늘리므로 래퍼로 기록
	local o = s:Observer(function(_, _, from)
		table.insert(calls, { from = from })
	end)
	s:Set(2)
	assert(#calls == 1, "unbound observer does not fire")
	assert((o :: any)._rerunRequired == true, "…the change is held (H-159)")
	local inst = Instance.new("Frame")
	quad.bindLifetime(inst, o)
	assert(#calls == 2 and calls[2].from == nil, "bind replays the held change once, with no source (H-164)")
	assert((o :: any)._rerunRequired == false, "flag lowered")
	s:Set(3)
	assert(#calls == 3 and calls[3].from == s, "bound: fires with the source epoch")
	inst:Destroy()
	s:Set(4)
	assert(#calls == 3 and (o :: any)._rerunRequired == true, "dead inst: held again, not fired")
	print("PASS")
end

print()
print("=== 3. 무인자 state:Observer() — 항상 관측 유틸(호출 즉시 Get) ===")
do
	local runs = 0
	local s = Source(1)
	local d = s:Compute(function(x): number
		runs += 1
		return x:Get()
	end)
	local o = d:Observer()
	assert(runs == 1, "install fire observed (computed) once")
	o:Subscribe()
	s:Set(2)
	assert(runs == 2, "each change re-observes")
	o:Unsubscribe()
	print("PASS")
end

print()
print("=== 4. WeakSubscribe(프리미티브) — .Subscribed=true, 약한 등록, 캐치업; canExecute true ===")
do
	local s = Source(1)
	local calls = 0
	local o = s:Observer(function()
		calls += 1
	end)
	s:Set(2) -- held
	assert(o:WeakSubscribe() == o, "returns self")
	assert(o.Subscribed == true and quad.canExecute(o) == true, "flag + gate")
	assert(calls == 2, "WeakSubscribe replayed the held change once")
	s:Set(3)
	assert(calls == 3, "fires while weakly subscribed")
	local ok, err = pcall(function()
		o:WeakSubscribe()
	end)
	assert(not ok and string.find(tostring(err), "already subscribed", 1, true) ~= nil, "double subscribe: " .. tostring(err))
	assert(string.find(tostring(err), "spec.observer.luau", 1, true) ~= nil, "level 2")
	local ok2, err2 = pcall(function()
		quad.bindLifetime(Instance.new("Frame"), o)
	end)
	assert(not ok2 and string.find(tostring(err2), "already subscribed", 1, true) ~= nil, "bindLifetime shares the gate: " .. tostring(err2))
	print("PASS")
end

print()
print("=== 5. WeakUnsubscribe — 관대(H-133), 단 강한 킵이 있으면 error ===")
do
	local s = Source(1)
	local o = s:Observer(function() end)
	o:WeakUnsubscribe() -- never subscribed: silent
	o:WeakSubscribe():WeakUnsubscribe()
	assert((o :: any).Subscribed == false and quad.canExecute(o) == false, "released")
	o:WeakUnsubscribe() -- already released: silent
	o:Subscribe()
	local ok, err = pcall(function()
		o:WeakUnsubscribe()
	end)
	assert(not ok and string.find(tostring(err), "use :Unsubscribe()", 1, true) ~= nil, "strong keep present: " .. tostring(err))
	assert(o.Subscribed == true, "…and nothing was changed")
	o:Unsubscribe()
	print("PASS")
end

print()
print("=== 6. Subscribe/Unsubscribe — 인라인 게이트(H-149), 강한 킵, 엄격 해제 ===")
do
	local s = Source(1)
	local calls = 0
	local o = s:Observer(function()
		calls += 1
	end)
	s:Set(2)
	assert(o:Subscribe() == o and calls == 2, "Subscribe replays the held change once")
	local ok, err = pcall(function()
		o:Subscribe()
	end)
	assert(not ok and string.find(tostring(err), "spec.observer.luau", 1, true) ~= nil, "double subscribe points at the caller: " .. tostring(err))
	local w = s:Observer(function() end):WeakSubscribe()
	local ok2, err2 = pcall(function()
		w:Unsubscribe()
	end)
	assert(not ok2 and string.find(tostring(err2), "use :WeakUnsubscribe()", 1, true) ~= nil, "strict: weakly subscribed → error: " .. tostring(err2))
	assert(w.Subscribed == true, "…untouched")
	assert(o:Unsubscribe() == o and o.Subscribed == false and quad.canExecute(o) == false, "released both tables")
	local ok3 = pcall(function()
		o:Unsubscribe()
	end)
	assert(not ok3, "second Unsubscribe errors (strict)")
	s:Set(3)
	assert(calls == 2, "released observer is silent")
	print("PASS")
end

print()
print("=== 7. GC — 강한 구독은 참조를 안 들어도 산다, 약한 구독은 놓으면 수거 ===")
do
	local s = Source(1)
	local strongCalls, weakCalls = 0, 0
	local function make()
		s:Observer(function()
			strongCalls += 1
		end):Subscribe()
		s:Observer(function()
			weakCalls += 1
		end):WeakSubscribe()
	end
	make()
	collectgarbage()
	collectgarbage()
	strongCalls, weakCalls = 0, 0
	s:Set(2)
	assert(strongCalls == 1, "strongly subscribed observer survives with no references")
	assert(weakCalls == 0, "weakly subscribed observer was collected")
	print("PASS")
end

print()
print("=== 8. 파동 중 새 구독자 — 스냅샷 계약(다음 파동부터) + 인스턴스별 레지스트리 ===")
do
	local s = Source(1)
	local late: any = nil
	local lateCalls = 0
	s:Observer(function(_, _, from)
		if from ~= nil and late == nil then
			late = s:Observer(function(_, _, f)
				if f ~= nil then
					lateCalls += 1
				end
			end):Subscribe()
		end
	end):Subscribe()
	s:Set(2)
	assert(late ~= nil and lateCalls == 0, "subscriber added mid-wave is not visited in that wave")
	s:Set(3)
	assert(lateCalls == 1, "…but from the next wave")
	local other = Quad.New()
	mock.installLifetime(other)
	local oo = other.Source(0):Observer(function() end)
	assert(getmetatable(oo :: any) ~= getmetatable(late :: any), "each quad instance has its own Observer impl (H-174)")
	print("PASS")
end

print()
print("=== ALL PASS ===")
