--[[
	quad-roblox M5 단위 ① 계약 — `QuadRoblox` 프로바이더 진입점
	(`quad:UseProvider(QuadRoblox)`, 1슬롯 fn identity 락 — `H-305` (d′)로
	옛 `_initializedBy` 문자열 가드 대체) + LifetimeHandle 실구현
	(nativeClaim eager·미claim bind 거부 `H-290`) + EngineOps M5 몫
	(native* 여섯, isInst/onDestroying/nativeFindChild).
	정본: `.claude/base/module-lifecycle-plan.md`의 UseProvider 서술,
	`lifecycle-pattern.md` (0)/(1), `architecture.md` EngineOps 줄,
	round14 brief §1 단위 ① + `H-305` 회신.

	⚠️ quad 사본 혼입 주의: 이 spec의 quad-base는 **dev-dep 사본**
	(`../luau_packages/quad_base`, round14 Q3 (a)) 하나뿐이다. mock에서는
	quad를 만들지 않는 헬퍼(`Instance`/`assertBlamesUser`)만 빌린다 —
	`mock.newQuad`/`addSpecLeaf`는 mock 자신의 `../src`(원본 사본)로 quad를
	만들어 브랜드가 갈리므로 여기서 쓰면 안 된다.

	실기기 몫(진짜 Instance의 typeof·userdata 고정·Destroy 동기 전환)은
	Studio MCP 스모크가 따로 본다 — 여기 mock instance는 구조적 대역이다.
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance

local SPEC_FILE = "spec.robloxfactory.luau"

print("=== 1. 진입점 — UseProvider identity 락: 같은 fn no-op·다른 identity error (H-305 d′) ===")
do
	local q = Quad.New():UseProvider(QuadRoblox)
	assert(type((q :: any).D) == "table", "extension merge lands D on the module")
	local before = (q :: any).bindLifetime
	local again = (q :: any):UseProvider(QuadRoblox)
	assert(again == q and (q :: any).bindLifetime == before, "same provider fn again is a no-op (functions untouched)")

	-- 다른 identity의 프로바이더(다른 백엔드든, 같은 백엔드의 다른 사본이든 —
	-- 옛 `_initializedBy` 문자열은 후자를 묵인했다, 사용자 진단)는 error
	local foreignProvider = function(_quad: any)
		return {}
	end
	local ok, err = pcall(function()
		(q :: any):UseProvider(foreignProvider)
	end)
	assert(not ok, "a second, different-identity provider must be rejected")
	assert(string.find(tostring(err), "already has a provider", 1, true) ~= nil, "message states the one-slot contract: " .. tostring(err))
	mock.assertBlamesUser(err, SPEC_FILE, "foreign provider")

	-- `H-294` (a): mock도 백엔드다 — 양방향 점유가 전부 시끄럽게 거부된다
	-- (q :: any — 교집합 타입을 mock의 any 파라미터로 흘리면 새 솔버가
	-- 클로저 추론 중 전개 한도를 넘는다: "too complex", 실측)
	local okMockOver = pcall(function()
		mock.installLifetime(q :: any)
	end)
	assert(not okMockOver, "mock must not silently overwrite the roblox backend")
	local mocked = Quad.New()
	mock.installLifetime(mocked)
	mock.installLifetime(mocked) -- 같은 identity 재설치 — no-op이어야 함
	local okRobloxOver, err2 = pcall(function()
		(mocked :: any):UseProvider(QuadRoblox)
	end)
	assert(not okRobloxOver, "roblox must not silently take over mock-bound handles")
	assert(string.find(tostring(err2), "already has a provider", 1, true) ~= nil, "one-slot contract both ways: " .. tostring(err2))
	print("PASS")
end

-- [단위 ⑤ `H-25` 반영] native*/isInst 등 op 필드는 이제 `Quad` 공개 타입에
-- 있다(H-80 규약) — 여기 any는 mock instance를 넘기는 단언들 편의.
local q: any = Quad.New():UseProvider(QuadRoblox)

print()
print("=== 2. nativeClaim — 1회 셋업, 이중 claim은 셋업 유무만으로 error ===")
do
	local inst = Instance.new("Folder")
	q.nativeClaim(inst)
	local ok, err = pcall(function()
		q.nativeClaim(inst)
	end)
	assert(not ok, "double claim must error (claim-plan §7-10)")
	assert(string.find(tostring(err), "already claimed", 1, true) ~= nil, "message: " .. tostring(err))
	mock.assertBlamesUser(err, SPEC_FILE, "double claim")
	inst:Destroy()
	print("PASS")
end

print()
print("=== 3. bindLifetime — 미claim inst는 error(H-290), claim 후 정상 경로 ===")
do
	local unclaimed = Instance.new("Folder")
	local ok, err = pcall(function()
		q.bindLifetime(unclaimed, {})
	end)
	assert(not ok, "binding to an unclaimed inst must error")
	assert(string.find(tostring(err), "not claimed", 1, true) ~= nil, "message: " .. tostring(err))
	mock.assertBlamesUser(err, SPEC_FILE, "unclaimed bind")

	local inst = Instance.new("Folder")
	q.nativeClaim(inst)
	local value = {}
	assert(q.canBound(value) == true and q.canExecute(value) == false, "unbound: may bind, may not execute")
	q.bindLifetime(inst, value)
	assert(q.canBound(value) == false and q.canExecute(value) == true, "bound: may not bind again, may execute")

	local ok2 = pcall(function()
		q.bindLifetime(inst, value)
	end)
	assert(not ok2, "double binding must error")

	inst:Destroy()
	assert(q.canExecute(value) == false, "after Destroy the value may not execute (gcconn.Connected)")
	assert(q.canBound(value) == true, "after Destroy the value may be bound again")
	local inst2 = Instance.new("Folder")
	q.nativeClaim(inst2)
	q.bindLifetime(inst2, value) -- 죽은 바인딩의 값 재사용 허용(lifecycle-pattern (3))
	assert(q.canExecute(value) == true, "rebound to a new claimed inst")
	inst2:Destroy()
	print("PASS")
end

print()
print("=== 4. unbindLifetime — O(1) 개별 해제, 같은 inst 다른 값 무영향, no-op 관대 ===")
do
	local inst = Instance.new("Folder")
	q.nativeClaim(inst)
	local a, b = {}, {}
	q.bindLifetime(inst, a)
	q.bindLifetime(inst, b)
	q.unbindLifetime(b)
	assert(q.canExecute(b) == false and q.canExecute(a) == true, "only the unbound value is released")
	q.bindLifetime(inst, b) -- unbind 후 재바인드 통과
	assert(q.canExecute(b) == true, "rebind after unbind")
	q.unbindLifetime({ never = "bound" }) -- 안 걸린 값에 불러도 안전한 no-op
	inst:Destroy()
	print("PASS")
end

print()
print("=== 5. EngineOps — native* 여섯 + 판정/훅/조회 셋 (mock instance 구조 대역) ===")
do
	local target = Instance.new("Frame")
	local a, b = Instance.new("Frame"), Instance.new("Frame")
	a.Name, b.Name = "A", "B"

	q.nativeInsert(target, 0, { a, b })
	assert(a.Parent == target and b.Parent == target, "nativeInsert parents the elements")

	q.nativeExtract(target, 0, { a })
	assert(a.Parent == nil, "nativeExtract detaches but keeps alive")
	local c = Instance.new("Frame")
	c.Name = "C"
	q.nativeExtract(target, 0, { b }, { c })
	assert(b.Parent == nil and c.Parent == target, "nativeExtract with replacement inserts newElements")

	local destroyed = false
	c.Destroying:Connect(function()
		destroyed = true
	end)
	q.nativeRemove(target, 0, { c }, { a })
	assert(destroyed and a.Parent == target, "nativeRemove destroys and inserts the replacement")

	-- Roblox 백엔드의 순서 이동은 의도된 no-op 덮어쓰기(ROADMAP M5 배너)
	q.nativeMove(target, 0, { a }, 1)
	q.nativeSwap(target, 0, { a }, 1, { b })
	assert(a.Parent == target and b.Parent == nil, "nativeMove/nativeSwap change nothing physical")

	assert(q.nativeFindChild(target, "A") == a, "nativeFindChild finds a direct child by key")
	assert(q.nativeFindChild(target, "nope") == nil, "nativeFindChild misses cleanly")

	local fired = 0
	q.onDestroying(target, function()
		fired += 1
	end)
	q.nativeDispose(target)
	assert(fired == 1, "onDestroying fires exactly once via nativeDispose(Destroy)")

	-- mock instance는 typeof상 table — 진짜 Instance의 true 판정은 Studio 스모크 몫
	assert(q.isInst(target) == false, "isInst is a real-engine typeof check (false on mocks)")
	print("PASS")
end

print()
print("=== 6. M5 스코프 밖 op은 설치되지 않음(Q4 (a)) — M10·백로그 몫 그대로 ===")
do
	for _, name in { "addTag", "removeTag", "setAttribute", "setTimeout", "clearTimeout" } do
		assert((q :: any)[name] == nil, name .. " must stay uninstalled in M5")
	end
	print("PASS")
end

print()
print("=== 7. 반응형 통합 — Observer가 roblox 생명주기로 게이팅됨 ===")
do
	local inst = Instance.new("Folder")
	q.nativeClaim(inst)
	local src = q.Source(1)
	local seen: { number } = {}
	local observer = src:Observer(function(state: any)
		table.insert(seen, state:Get() :: number)
	end)
	q.bindLifetime(inst, observer)
	src:Set(2)
	assert(#seen == 2 and seen[1] == 1 and seen[2] == 2, "install fire + one re-emission")
	inst:Destroy()
	src:Set(3)
	assert(#seen == 2, "after Destroy the observer is gated (canExecute via roblox gcconn)")
	print("PASS")
end

print()
print("=== 8. 탐사자 보강(🟡-5) — Effect 배선·훅 가드·재바인드 캐치업이 roblox 전사본 경유로 ===")
do
	-- (a) isEffect 분기: _bindDestroying이 EngineOps.onDestroying과 실배선돼
	--     leaf 사망 시 cleanup이 정확히 1회 소진되는가
	local inst = Instance.new("Folder")
	q.nativeClaim(inst)
	local src = q.Source(1)
	local cleanups = 0
	local eff = q.Effect(function(_self: any)
		local _ = src:Get()
		return function()
			cleanups += 1
		end
	end, src)
	q.bindLifetime(inst, eff)
	inst:Destroy() -- mock Destroying은 동기 발화 — 실기기는 지연 배달(`H-291`)
	assert(cleanups == 1, "leaf death consumes the cleanup exactly once (onDestroying wiring)")

	-- (b) _assertBindable 훅 경로: fn 실행 중(_running) bind 시도는 커밋 전에 거부되고
	--     반쯤 묶인 핸들이 남지 않는다(`H-183`/`H-184`)
	local inst2 = Instance.new("Folder")
	q.nativeClaim(inst2)
	local src2 = q.Source(1)
	local sawGuard = false
	local obs2 = src2:Observer(function(_state: any, self: any)
		local ok = pcall(function()
			q.bindLifetime(inst2, self)
		end)
		if not ok then
			sawGuard = true
		end
	end)
	assert(sawGuard, "binding from inside fn is rejected by the pre-commit hook guard")
	assert(q.canExecute(obs2) == false, "the rejected bind left no half-bound state")
	q.bindLifetime(inst2, obs2) -- 정상 문맥에서는 그대로 묶인다
	assert(q.canExecute(obs2) == true, "clean bind after the rejected attempt")

	-- (c) 재바인드 캐치업: 묶이기 전 홀드된 emit이 bind 시 1회만 따라잡힌다(`H-159`)
	local inst3 = Instance.new("Folder")
	q.nativeClaim(inst3)
	local src3 = q.Source(1)
	local seen = 0
	local obs3 = src3:Observer(function()
		seen += 1
	end)
	assert(seen == 1, "install fire at creation")
	src3:Set(2)
	assert(seen == 1, "unbound emit is held, not delivered")
	q.bindLifetime(inst3, obs3)
	assert(seen == 2, "bind catches up the held change exactly once")
	src3:Set(3)
	assert(seen == 3, "bound emits flow normally")
	inst3:Destroy()
	print("PASS")
end

print()
print("=== ALL PASS ===")
