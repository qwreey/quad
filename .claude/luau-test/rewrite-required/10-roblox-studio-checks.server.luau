--[[
	⚠️ [2026-08-14 다섯 번째 세션] 재작성 필요 — 아래 A 섹션 코드는 **폐기된
	모델**을 검증한다: 별도 predicate `canBound`(→ `canExecute`로 통합 폐기),
	`bindLifetime`이 `value.Subscribed = true`를 세팅하는 것(→ `.Subscribed`는
	전역 `:Subscribe()` 전용이라 `bindLifetime`과 무관), 2-인자
	`canExecute(inst, value)`/`unbindLifetime(inst, value)`(→ 둘 다 `value`
	단독 1-인자). 새 모델은 `base/lifecycle-pattern.md`의
	"`bindLifetime`/`canExecute`/`unbindLifetime` — 확정" 절, 역전 경위는
	`archive/canexecute-inst-arg-reversed.md`.
	**단 A 섹션이 검증하려던 것 중 "ClassName 신호 미발화 / Destroy 시
	Connected 즉시 전환"은 새 모델에서도 그대로 유효하다** — 오히려 더
	중요해졌음(`canExecute`가 `value` 쪽에 복사된 gcconn의 `.Connected`를
	직접 읽는 게 leaf 경로 생존 판정의 전부). 그 두 가정은 이미 부분 실측됨:
	`audit/gcconn-trick-verification.md`. B/C 섹션은 이 변경과 무관하게 그대로
	유효하다. (재작성은 별도 작업 — Studio 전용이라 이 환경에서 검증도 못 함.)

	검증 대상 (Roblox Studio 전용 — 순수 luau CLI로는 안 됨, 실제 Instance/
	Connection/CollectionService/Attribute가 필요함):

	A) bindLifetime/unbindLifetime/canExecute의 gcconn 트릭 — Observer/
	   Effect 값의 이중 바인딩을 canBound로 막는지까지 포함해서 검증
	   (2026-08-09 세션에 unbindLifetime 추가 + canBound 이름 확정 +
	   gchold를 배열이 아니라 value를 키로 쓰는 테이블로 바꾼 것까지 반영
	   — 이전 버전의 이 스크립트는 array 기반 gchold였음, 이번에 정정).
	B) Attribute가 Instance 참조 타입을 실제로 지원하는가(ObjectValue
	   없이 Ref 용도로 쓸 수 있다는 CLAUDE.md 서술의 실측).
	C) CollectionService 태그 + GetTagged 왕복이 quad-debug가 기대하는
	   대로 동작하는가(태그 추가/제거, GetTagged로 조회).

	배경: .claude/base/lifecycle-pattern.md "bindLifetime/canExecute/
	unbindLifetime — 확정" 절 + "실측 필요(M0/M2)" 캐비엇,
	.claude/base/bind-system-plan.md "이중 바인딩 금지" 절(canBound),
	CLAUDE.md 2026-08-06 세션의 Attribute Instance 참조 지원 언급,
	.claude/research/debug-tooling-plan.md의 CollectionService 노출 방식.

	실행 방법:
	1. Roblox Studio에서 아무 place나 열고(빈 baseplate로 충분),
	   ServerScriptService에 이 파일 내용을 그대로 붙여넣은 Script를
	   하나 만든다.
	2. Play(F5) 또는 Run(F8) — Output 창에서 결과를 확인.
	3. 확인 끝나면 이 Script는 지워도 됨(Studio 안에 실제로 만든 Script
	   얘기 — 이 원본 파일 자체는 `.claude/luau-test/`에 참고용으로
	   남겨둠).

	주의: HUMAN_TODO.md 1번(Studio 별도 계정) 확인 후 실행할 것 —
	SAFETY.md 준수.
]]

print("========================================")
print("A) bindLifetime/unbindLifetime/canExecute/canBound gcconn 트릭")
print("========================================")

do
	local relate = {} -- 이 스파이크 전용 아주 단순한 strong map (inst -> {gcconn, gchold})

	-- Observer/Effect를 흉내낸 최소 값 — .Subscribed 필드가 canExecute/canBound가
	-- 공유하는 그 필드(base/bind-system-plan.md "이중 바인딩 금지" 절 참고)
	local function fakeObserver()
		return { isObserverSpike = true, Subscribed = false }
	end
	local function isObserverLike(v)
		return type(v) == "table" and v.isObserverSpike == true
	end

	-- canBound(handle) — "아직 어느 경로로도 안 묶였으면 true"
	local function canBound(value)
		return not (isObserverLike(value) and value.Subscribed)
	end

	local function bindLifetime(inst: Instance, value: any)
		local isOE = isObserverLike(value)
		if isOE and not canBound(value) then
			error("Observer/Effect가 이미 다른 경로로 바인딩됨")
		end

		local entry = relate[inst]
		if not entry then
			local gchold = {} -- value 자신을 키로 씀(배열 아님) — unbindLifetime을 O(1)로
			local gcconn = inst:GetPropertyChangedSignal("ClassName"):Connect(function()
				-- 이 콜백은 정상적으로는 절대 발화하면 안 됨 — 발화하면 그 자체가
				-- "ClassName이 신호를 절대 안 쏜다"는 가정이 틀렸다는 증거이므로 경고.
				warn("[예상 밖] ClassName Changed가 실제로 발화함! gcconn 트릭의 전제가 깨짐:", inst:GetFullName())
				local _ = gchold
			end)
			entry = { gcconn = gcconn, gchold = gchold }
			relate[inst] = entry
		end
		entry.gchold[value] = true -- 강참조 생성, inst 죽으면 gcconn 클로저와 함께 GC
		if isOE then
			value.Subscribed = true -- canExecute/canBound가 보는 필드 그대로 재사용
		end
	end

	local function unbindLifetime(inst: Instance, value: any)
		local entry = relate[inst]
		if entry then
			entry.gchold[value] = nil -- inst는 안 건드림, 이 value 하나만 조기 해제(O(1))
		end
		if isObserverLike(value) then
			value.Subscribed = false
		end
	end

	local function canExecute(inst: Instance, value: any): boolean
		if isObserverLike(value) and not value.Subscribed then
			return false
		end
		local entry = relate[inst]
		return entry ~= nil and entry.gcconn.Connected
	end

	local target = Instance.new("Folder")
	target.Name = "QuadLifetimeSpikeTarget"
	target.Parent = workspace

	local obs1 = fakeObserver()
	bindLifetime(target, obs1)
	print("bindLifetime 직후 canExecute(target, obs1) =", canExecute(target, obs1), "(true여야 함)")

	print()
	print("-- A-1) canBound 이중 바인딩 게이트: 같은 obs1을 또 bindLifetime하면 error가 나야 함 --")
	local ok, err = pcall(function()
		bindLifetime(target, obs1)
	end)
	print("두 번째 bindLifetime(obs1) 성공?", ok, "(false여야 함)", not ok and tostring(err) or "")

	print()
	print("-- A-2) unbindLifetime: 특정 값 하나만 조기 해제, inst 전체엔 영향 없어야 함 --")
	local obs2 = fakeObserver()
	bindLifetime(target, obs2)
	print("obs2 bindLifetime 직후 canExecute =", canExecute(target, obs2), "(true)")
	unbindLifetime(target, obs2)
	print("obs2 unbindLifetime 이후 canExecute =", canExecute(target, obs2), "(false여야 함, .Subscribed가 다시 false)")
	print("obs1(같은 inst, 안 건드림)은 여전히 canExecute =", canExecute(target, obs1), "(true여야 함 — obs2 해제가 obs1에 영향 없어야 함)")
	print("unbindLifetime 이후 같은 obs2를 다시 bindLifetime 가능한가(canBound가 재바인딩 허용하는지)?")
	local ok2 = pcall(function()
		bindLifetime(target, obs2)
	end)
	print("재-bindLifetime(obs2) 성공?", ok2, "(true여야 함 — unbindLifetime이 canBound를 다시 통과시켜야 함)")

	print()
	print("-- A-3) Destroy 시 canExecute가 false로 바뀌는가(gcconn.Connected 확인) --")
	target:Destroy()
	print(
		"Destroy 후 canExecute(target, obs1) =",
		canExecute(target, obs1),
		"(false여야 함 — Connection.Connected가 Destroy로 즉시 끊기는지 확인)"
	)

	-- 5초 정도 대기하며 위 warn이 늦게라도 튀어나오는지 관찰(비동기 우려 대비)
	task.delay(5, function()
		print("[A] 5초 대기 종료 — 그 사이 warn이 안 떴다면 gcconn 트릭 전제가 안전함")
	end)
end

print()
print("========================================")
print("B) Attribute의 Instance 참조 타입 지원 여부")
print("========================================")

do
	local target = Instance.new("Folder")
	target.Name = "QuadAttributeRefSpikeTarget"
	target.Parent = workspace

	local holder = Instance.new("Folder")
	holder.Name = "QuadAttributeRefSpikeHolder"
	holder.Parent = workspace

	local ok, err = pcall(function()
		holder:SetAttribute("RefToTarget", target)
	end)
	print("SetAttribute(Instance) 성공?", ok, err and tostring(err) or "")

	if ok then
		local readBack = holder:GetAttribute("RefToTarget")
		print("GetAttribute 결과가 원본과 같은 Instance인가?", readBack == target)
	end

	-- 대상이 Destroy되면 Attribute는 어떻게 되는가(참고 확인 — nil로 풀리는지,
	-- 아니면 죽은 참조를 계속 들고 있는지는 Ref 설계에 영향을 줄 수 있음)
	target:Destroy()
	task.wait()
	local afterDestroy = holder:GetAttribute("RefToTarget")
	print("target Destroy 후 GetAttribute =", afterDestroy, "(nil로 풀리는지, 죽은 참조 그대로인지 확인)")

	holder:Destroy()
end

print()
print("========================================")
print("C) CollectionService 태그 + GetTagged 왕복")
print("========================================")

do
	local CollectionService = game:GetService("CollectionService")
	local TAG = "QuadDebugSpikeTag"

	local a = Instance.new("Folder")
	a.Name = "TaggedA"
	a.Parent = workspace
	local b = Instance.new("Folder")
	b.Name = "TaggedB"
	b.Parent = workspace

	CollectionService:AddTag(a, TAG)
	CollectionService:AddTag(b, TAG)

	local tagged = CollectionService:GetTagged(TAG)
	print("GetTagged 결과 개수 =", #tagged, "(2여야 함)")

	CollectionService:RemoveTag(a, TAG)
	local taggedAfterRemove = CollectionService:GetTagged(TAG)
	print("RemoveTag 이후 GetTagged 개수 =", #taggedAfterRemove, "(1이어야 함)")

	a:Destroy()
	b:Destroy()
end

print()
print("모든 섹션 실행 완료 — Output 로그를 그대로 복사해서 공유해주면 됨")
