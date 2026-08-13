--[[
	검증 대상: "retract는 항상 불림" 전면 정정(2026-08-12 열한 번째 세션) 이후
	새로 생긴 세 가지 소유권/참조카운트 추적 로직이 실제로 짜인 대로 동작하는지 —
	전부 여러 위치/여러 사이클에 걸쳐 상태가 정확히 갱신되는지가 핵심이라
	손으로 추론만으로는 놓치기 쉬운 클래스(이 프로젝트가 이미 같은 클래스에서
	실제 버그를 두 번 냄: `retractUnder`의 and/or 삼항 falsy 버그, Slot
	`recompute`의 off-by-one). 셋 다 Roblox 엔진/GC 타이밍과 무관한 순수 Luau
	테이블 로직이지만, 03/04/11번 스파이크가 커버하는 것과는 다른 새 알고리즘
	모양(여러 위치가 하나의 이름/자리를 공유하는 참조 카운트, 캐싱된 키 객체의
	사이클 간 재사용, "같은 owner면 무시/다른 owner면 error" 분기)이라 별도로
	실측이 필요하다고 판단해 신규 작성함.

	[2026-08-13 재작성] B/C 섹션은 원래 폐기된 설계(`rawNew`+`owners` 수동
	레지스트리, "같은 owner면 no-op" 3분기 `claimOwner`)를 검증하고 있어서
	현재 base 설계에 맞춰 다시 씀. A 섹션은 그대로 유효 — 단 `kTagMap`은
	2026-08-13 다섯 번째 세션에 Handler 계약이 클로저 반환으로 바뀌며
	삭제됐고, 클로저가 `v`(이 위치의 Tag)를 직접 캡처하므로 이제
	`tagNameMap`(이름 -> 홀더 Tag set) 하나만 남음 — 참조 카운트 로직
	자체는 안 바뀌어서 A의 검증 내용/기댓값은 그대로 성립.

	A) Tag 참조 카운트 — `base/tag-plan.md` "메커니즘 — TagHandler" 절의
	   `tagNameMap`. 서로 다른 두 위치가 같은 이름을 겹쳐 가질 때
	   (`Frame { Tag("a"), Tag("a","b") }`류) 한쪽이 이름을 잃어도 다른 쪽이
	   아직 쥐고 있으면 실제 `RemoveTag`가 안 불려야 함(웹 className 합집합
	   시맨틱).

	B) Attribute 이름 소유권 — `base/attribute-plan.md` "이름 소유권"/
	   "메커니즘" 절의 최종(세 번째) 설계: 그룹이 이름마다 공개
	   `AttributeKey(name)`(이름별 weak 캐시)으로 항상 인덱스 1에
	   `Dispatch.process(inst, key, source, 1)`만 부르고(`retractFrom`
	   선행 호출 금지 — 부르면 점유 체크가 무력화됨), 철거는 반환 클로저가
	   자기가 등록한 이름 전부에 대해 수행. 소유권 충돌 감지는 별도
	   레지스트리가 아니라 **`Dispatch.process` 자신의 인덱스 점유 체크**가
	   대신함 — 이 스파이크는 그 점유 체크 로직 자체를 흉내 내어 검증.

	   **[중요 캐비엇]** `research/dispatch-redispatch-diff-plan.md` 5절이
	   지적하듯, 앞으로 도입될 "하강 diff" 재디스패치 모델(`Dispatch.process`가
	   핸들러를 먼저 비교해 같으면 재사용)에서는 그룹 A/그룹 B가 둘 다
	   `StoreBind`로 보여 "같은 핸들러"로 판정되므로 **이 점유 체크 하나만으로는
	   그룹↔그룹 충돌을 못 잡는다**는 게 이미 확인돼 있음(`.claude/question.md`
	   0-Z, 최우선 미결 항목 — "이전 결정인 이름별 claimant `Relate`를 다시
	   가져오는 방향"으로 사용자가 기울었으나 심층 분석은 다음 세션으로 이관).
	   즉 아래 B 섹션이 검증하는 건 **현재 확정된 모델**(점유 체크가 충돌을
	   잡음, 그룹↔직접 쓰기 케이스는 이 모델에서도 계속 유효)이고, 0-Z가
	   결정되면(특히 그룹↔그룹 케이스) 이 섹션도 다시 손봐야 함.

	C) Slot 요소 소유권 — `base/slot-plan.md` "요소 소유권 — `elementOwner`"
	   절의 `claimOwner`(nested `rawAdd` 전용, 엄격 — 같은 owner 재클레임도
	   error)와 `claimOwnerAt`(top-level `SlotHandler` 전용 — `(inst,k)`까지
	   봐서 정확히 같은 자리의 spurious 재발행만 `false`, 그 외 중복은 전부
	   error) 두 함수로 쪼개진 최종 설계. 원래 하나의 `claimOwner`가 "같은
	   owner면 no-op(false)"이라는 3분기를 양쪽에 공유했던 게 감사에서 버그로
	   판정됨(`Frame { slot, slot }`에서 top-level이 `k=2`를 조용히 no-op
	   처리하고도 파괴적 클로저를 반환해 이중 파괴로 이어짐, `local a=Slot{};
	   Slot{a,a}`에서 nested가 반환값을 안 봐서 이중 클레임을 그냥 통과시킴) —
	   아래 C 섹션은 두 함수를 각각 검증.

	실행: `luau 19-ownership-refcount-relate-patterns.luau`
]]

-- ===== 공용: Relate 흉내(이 스파이크는 순수 로직 검증이 목적이라 weak-key는
-- 07/18번이 이미 따로 다룸 — 여기선 plain 테이블로 단순화) =====

local function makeRegistry()
	local t = {}
	return {
		get = function(_, a, b)
			local sub = t[a]
			return sub and sub[b]
		end,
		set = function(_, a, b, v)
			t[a] = t[a] or {}
			t[a][b] = v
		end,
	}
end

local function report(name, ok, expected, actual)
	local pass = ok
	print(string.format("  [%s] %s%s", pass and "PASS" or "FAIL", name, pass and "" or string.format(" (expected=%s actual=%s)", tostring(expected), tostring(actual))))
	return pass
end

local allPass = true

-- ===== A. Tag 참조 카운트 — 여러 위치가 같은 이름을 겹쳐 가짐 =====

print("=== A. Tag tagNameMap — 참조 카운트 ===")

do
	-- [2026-08-13 재작성 시 확인] 옛 `kTagMap`(위치별 마지막 Tag를 별도
	-- 저장하던 맵)은 실제 base 설계에선 없음 — 2026-08-13 다섯 번째 세션에
	-- `process`가 자기 retract 클로저를 반환하는 계약으로 바뀌며, "이
	-- (inst,k) 자리에 지금 뭐가 있었나"는 클로저가 `v`를 upvalue로 직접
	-- 캡처해서 알므로 별도 저장소가 불필요해짐(`tag-plan.md` "메커니즘" 절).
	-- `tagNameMap`(이름 -> 그 이름을 걸고 있는 현재 홀더 집합)만 남음 — 이건
	-- 여러 위치를 가로지르는 누적 상태라 여전히 필요.
	--
	-- 아래 TagRetract/TagProcess는 실제 base 코드의 함수 분리 방식(하나의
	-- process가 반환하는 클로저)과는 다르게 두 개의 독립 함수로 남아있음 —
	-- 이건 원래 스파이크 작성자가 검증 편의를 위해 고른 형태고, 이 세션의
	-- 재작성 범위(B/C만)에 포함되지 않아 그대로 유지함. 참조 카운트 로직
	-- 자체(홀더 집합 갱신 + `Contains` 힌트로 실제 RemoveTag만 skip)는
	-- 실제 base 설계와 동등함.
	local tagNameMap = makeRegistry() -- (inst,name) -> {[Tag]=true}
	local removeLog = {}
	local addLog = {}

	local function names(tagList)
		local out = {}
		for _, n in tagList do
			out[n] = true
		end
		return out
	end

	local function makeTag(...)
		return { __names = names({ ... }) }
	end
	local function tagNames(tag)
		local out = {}
		for n in tag.__names do
			table.insert(out, n)
		end
		return out
	end
	local function tagContains(tag, name)
		return tag.__names[name] == true
	end

	-- kTagMap 대체: 이 스파이크 안에서만 쓰는 "이 위치가 직전에 걸었던 Tag"
	-- 로컬 기억 — 실제 base에선 process가 반환하는 클로저의 upvalue가 이
	-- 역할을 함(위 주석 참고). 여기선 TagRetract/TagProcess가 분리돼 있어
	-- 호출부가 직접 넘겨줌.
	local function TagRetract(inst, k, oldv, newv)
		if not oldv then
			return
		end
		local newvIsTag = newv ~= nil and newv.__names ~= nil
		for _, name in tagNames(oldv) do
			local holders = tagNameMap:get(inst, name) or {}
			holders[oldv] = nil
			tagNameMap:set(inst, name, holders)
			if next(holders) == nil and not (newvIsTag and tagContains(newv, name)) then
				table.insert(removeLog, name)
			end
		end
	end

	local function TagProcess(inst, k, v)
		for _, name in tagNames(v) do
			local holders = tagNameMap:get(inst, name) or {}
			if next(holders) == nil then
				table.insert(addLog, name)
			end
			holders[v] = true
			tagNameMap:set(inst, name, holders)
		end
	end

	-- Frame { Tag("a"), Tag("a", "b") } — 두 위치(k=1, k=2)가 "a"를 겹쳐 가짐
	local tagPos1 = makeTag("a")
	local tagPos2 = makeTag("a", "b")
	TagRetract("Frame1", 1, nil, tagPos1)
	TagProcess("Frame1", 1, tagPos1)
	TagRetract("Frame1", 2, nil, tagPos2)
	TagProcess("Frame1", 2, tagPos2)

	-- Frame{Tag("a"), Tag("a","b")} 마운트 직후: "a"는 두 위치가 겹쳐 가지므로
	-- AddTag("a")는 첫 홀더가 생길 때 한 번만 실제로 불려야 함(로그 = {a, b})
	allPass = report("초기 마운트: AddTag 로그", #addLog == 2 and addLog[1] == "a" and addLog[2] == "b", "{a,b}", table.concat(addLog, ",")) and allPass

	-- 위치1이 "a"를 잃음(Tag()로 교체, 빈 값) — 위치2가 아직 "a"를 쥐고 있으므로
	-- 실제 RemoveTag("a")는 안 불려야 함
	local emptyTag = makeTag()
	TagRetract("Frame1", 1, tagPos1, emptyTag)
	TagProcess("Frame1", 1, emptyTag)

	allPass = report("위치1이 a를 잃어도 위치2가 쥐고 있어 RemoveTag 안 불림", #removeLog == 0, "0", #removeLog) and allPass

	-- 위치2도 "a"를 잃음 — 이제 진짜로 RemoveTag("a")가 불려야 함(b는 그대로 유지)
	local tagPos2b = makeTag("b")
	TagRetract("Frame1", 2, tagPos2, tagPos2b)
	TagProcess("Frame1", 2, tagPos2b)

	allPass = report("마지막 홀더도 a를 잃으면 RemoveTag(a) 실제로 불림", #removeLog == 1 and removeLog[1] == "a", "{a}", table.concat(removeLog, ",")) and allPass
end

-- ===== B. Attribute 이름 소유권 — Dispatch 인덱스 점유 체크로 판정 =====

print()
print("=== B. Attribute — Dispatch.process 점유 체크가 이름 소유권 충돌을 잡는가 ===")

do
	-- Dispatch.process/retractFrom을 아주 얇게 흉내냄 — (inst,key) 자리별로
	-- 인덱스별 점유자(occupant)를 기록. 실제 Dispatch는 핸들러 매치/재귀도
	-- 하지만 여기선 "인덱스 1이 이미 점유돼 있으면 error"라는 핵심 계약만
	-- 재현하면 충분(attribute-plan.md "메커니즘" 절이 의존하는 게 정확히 이것).
	local occupant = makeRegistry() -- (inst,key) -> claimant(임의의 identity)

	local function DispatchProcess(inst, key, claimant, index)
		assert(index == 1, "이 스파이크는 인덱스 1 직접 위임 케이스만 다룸")
		local current = occupant:get(inst, key)
		if current ~= nil and current ~= claimant then
			error(string.format('attribute key "%s"는 이미 다른 claimant가 점유 중', tostring(key.__name)))
		end
		occupant:set(inst, key, claimant)
	end

	local function DispatchRetractFrom(inst, key, claimant, index)
		assert(index == 1)
		if occupant:get(inst, key) == claimant then
			occupant:set(inst, key, nil)
		end
	end

	-- AttributeKey(name) 이름별 weak 캐시 흉내 — 실제로는 GC weak지만 여기선
	-- 순수 로직만 보므로 strong 캐시로 충분(동등성 보장이 핵심)
	local keyCache = {}
	local function AttributeKey(name)
		local k = keyCache[name]
		if not k then
			k = { __name = name }
			keyCache[name] = k
		end
		return k
	end

	-- 직접 리터럴 쓰기: [AttributeKey "Enabled"] = true, claimant는 이 자리
	-- 자체(Modifier 필드 identity 대신 편의상 문자열로 대체)
	local directClaimant = "directWrite"
	DispatchProcess("Frame1", AttributeKey("Enabled"), directClaimant, 1)

	-- 그룹이 rawNew 대신 공개 캐시로 같은 이름을 잡으려 하면 -> 점유 체크가 error
	local groupClaimant = "group1"
	local ok1 = pcall(function()
		DispatchProcess("Frame1", AttributeKey("Enabled"), groupClaimant, 1)
	end)
	allPass = report("직접 쓰기가 점유한 이름을 그룹이 잡으려 하면 -> error", ok1 == false, false, ok1) and allPass

	-- 그룹 자신의 재귀 diff 사이클 — AttributeGroupHandler.process/retractor 흉내.
	-- process: 새 이름 집합 전부 인덱스 1로 위임. 반환 클로저: 자기가 등록한
	-- 이름 전부 retractFrom(공개 캐시라 매번 같은 키 객체 재사용, 별도
	-- 레지스트리 불필요 — attribute-plan.md "메커니즘" 절 그대로).
	local function AttributeGroupProcess(inst, groupClaimant, names)
		local registered = {}
		for _, name in names do
			DispatchProcess(inst, AttributeKey(name), groupClaimant, 1)
			table.insert(registered, name)
		end
		return function()
			for _, name in registered do
				DispatchRetractFrom(inst, AttributeKey(name), groupClaimant, 1)
			end
		end
	end

	local retractGroup = AttributeGroupProcess("Frame2", "groupA", { "Health", "Mana" })
	local firstHealthKey = AttributeKey("Health") -- 캐시된 같은 객체인지 재확인용

	-- 2번째 사이클: 옛 클로저가 먼저 걷어내고(하강 diff 이전 모델의 관용구대로
	-- retract-then-process), 새 process가 같은 이름들을 다시 등록 — 캐시된
	-- 같은 키 객체를 재사용해야 자기 자신과 충돌하지 않음
	retractGroup()
	retractGroup = AttributeGroupProcess("Frame2", "groupA", { "Health", "Mana" })

	local ok2 = AttributeKey("Health") == firstHealthKey
	allPass = report("이름 캐시는 사이클 간 같은 키 객체 재사용(공개 AttributeKey 캐시)", ok2, true, ok2) and allPass

	-- 같은 그룹이 "Health"를 잃었다가(2번째 사이클에서 Mana만 남김) 다시
	-- 포함하는 경우 -> 자기 자신과 충돌하면 안 됨(자기가 걷어낸 자리를
	-- 자기가 다시 잡는 것이므로) — 0-Z 이전, 현재 모델에서 정상 통과해야 함
	retractGroup()
	retractGroup = AttributeGroupProcess("Frame2", "groupA", { "Mana" }) -- Health를 놓음
	local ok3 = pcall(function()
		retractGroup()
		retractGroup = AttributeGroupProcess("Frame2", "groupA", { "Health", "Mana" }) -- Health를 다시 포함
	end)
	allPass = report("같은 그룹이 이름을 놓았다 다시 포함해도 자기 자신과 안 충돌", ok3 == true, true, ok3) and allPass

	-- 음성 대조군: 두 개의 서로 다른 그룹이 같은 이름을 동시에 관리하려 하면
	-- (retractFrom 없이 process만 먼저 부르는 순서로) 반드시 점유 error가
	-- 나야 함 — 이게 "체크포인트/owners 레지스트리 없이 점유 체크 하나로
	-- 충돌을 잡는다"는 이 설계의 핵심 주장 그 자체
	local groupBClaimant = "groupB"
	local ok4 = pcall(function()
		DispatchProcess("Frame2", AttributeKey("Mana"), groupBClaimant, 1) -- groupA가 아직 Mana를 쥔 채
	end)
	allPass = report("[핵심] 그룹A가 점유 중인 이름을 그룹B가 잡으려 하면 -> error(점유 체크가 충돌을 잡음)", ok4 == false, false, ok4) and allPass

	-- 음성 대조군 2: 점유 체크를 흉내내지 않고(=폐기된 옛 모델처럼 아무
	-- 체크 없이 그냥 덮어쓰면) 위 케이스가 조용히 통과해버림을 직접 보여줌 —
	-- "이 스파이크가 실제로 뭔가를 검증하고 있다"는 반증
	do
		local naiveOccupant = {}
		local function naiveProcess(key, claimant)
			naiveOccupant[key] = claimant -- 점유 체크 없이 무조건 덮어씀(구 last-write-wins)
		end
		local key = "Mana"
		naiveProcess(key, "groupA")
		naiveProcess(key, "groupB") -- 아무 에러도 안 남 — 이게 바로 이 문서가 고쳤다고 주장하는 버그
		allPass = report("(음성 대조군) 점유 체크 없는 naive 모델은 같은 상황에서 조용히 통과함(버그 재현)", naiveOccupant[key] == "groupB", "groupB", naiveOccupant[key]) and allPass
	end
end

-- ===== C. Slot elementOwner — claimOwner(nested, 엄격) / claimOwnerAt(top-level) =====

print()
print("=== C. Slot elementOwner — claimOwner(엄격) vs claimOwnerAt(spurious 재발행 허용) ===")

do
	local elementOwner = makeRegistry() -- element -> {OWNER=ownerKey, OWNER_POS=k}
	local OWNER = "__owner"
	local OWNER_POS = "__ownerPos"

	-- nested(rawAdd) 전용 — 엄격: 이미 누가 갖고 있으면 같은 owner여도 error
	local function claimOwner(element, ownerKey)
		if elementOwner:get(element, OWNER) ~= nil then
			error("이 요소는 이미 마운트돼 있음 — 다중 마운트 금지")
		end
		elementOwner:set(element, OWNER, ownerKey)
	end

	-- top-level(SlotHandler) 전용 — 정확히 같은 (inst,k) 자리의 spurious
	-- 재발행만 false(no-op), 그 외 중복은 전부 error. 반환값 = 새로 클레임했는가.
	local function claimOwnerAt(element, inst, k)
		local current = elementOwner:get(element, OWNER)
		if current == inst and elementOwner:get(element, OWNER_POS) == k then
			return false -- 정확히 이 자리가 이미 들고 있음 — 재확인만
		end
		if current ~= nil then
			error("이 요소는 이미 다른 곳에 마운트돼 있음 — 다중 마운트 금지")
		end
		elementOwner:set(element, OWNER, inst)
		elementOwner:set(element, OWNER_POS, k)
		return true
	end

	local function releaseOwner(element, ownerKey)
		local current = elementOwner:get(element, OWNER)
		if current ~= ownerKey then
			error("releaseOwner: 이 element는 이 ownerKey가 소유하고 있지 않음 — 호출측 소유권 추적이 깨졌음")
		end
		elementOwner:set(element, OWNER, nil)
		elementOwner:set(element, OWNER_POS, nil)
	end

	-- --- C-1. nested claimOwner: 같은 owner 재클레임도 error(Slot{a,a} 방지) ---

	do
		local a = { __name = "elementA" }
		local outerSlot = { __name = "outerSlot" }

		claimOwner(a, outerSlot) -- rawAdd(outerSlot, a) — 최초 클레임, 정상

		local ok1 = pcall(function()
			claimOwner(a, outerSlot) -- 같은 outerSlot이 같은 a를 또 rawAdd(Slot{a,a} 시뮬레이션)
		end)
		allPass = report("C-1: nested Slot{a,a} — 같은 owner 재클레임도 -> error", ok1 == false, false, ok1) and allPass

		-- 음성 대조군: 옛 3분기(같은 owner면 조용히 false)였다면 위 케이스가
		-- 통과해버려 outerSlot._elements = {a, a}가 조용히 만들어짐
		local function oldClaimOwner3way(element, ownerKey, registry)
			local current = registry[element]
			if current == ownerKey then
				return false -- 옛 설계: no-op 취급, error 없음
			end
			if current ~= nil then
				error("다른 곳에 마운트됨")
			end
			registry[element] = ownerKey
			return true
		end
		local oldRegistry = {}
		local claimed1 = oldClaimOwner3way(a, outerSlot, oldRegistry)
		local claimed2 = oldClaimOwner3way(a, outerSlot, oldRegistry) -- rawAdd가 반환값을 안 보므로 그냥 통과
		allPass = report("(음성 대조군) 옛 3분기 claimOwner였다면 Slot{a,a}가 에러 없이 통과함(claimed2=false, no error)", claimed1 == true and claimed2 == false, "true,false", tostring(claimed1) .. "," .. tostring(claimed2)) and allPass

		releaseOwner(a, outerSlot)
	end

	-- --- C-2. 서로 다른 Slot에 같은 element -> error ---

	do
		local b = { __name = "elementB" }
		local slot1 = { __name = "slot1" }
		local slot2 = { __name = "slot2" }

		claimOwner(b, slot1)
		local ok2 = pcall(function()
			claimOwner(b, slot2)
		end)
		allPass = report("C-2: 서로 다른 nested Slot에 같은 element -> error", ok2 == false, false, ok2) and allPass

		releaseOwner(b, slot1)
	end

	-- --- C-3. top-level claimOwnerAt: 같은 (inst,k) 자리에서 같은 slot 재발행은 no-op ---

	do
		local slotA = { __name = "slotA" }
		local frame1 = { __name = "Frame1" }

		local claimed1 = claimOwnerAt(slotA, frame1, 1) -- 최초 마운트
		allPass = report("C-3a: 최초 클레임은 true(실제로 붙음)", claimed1 == true, true, claimed1) and allPass

		local claimed2 = claimOwnerAt(slotA, frame1, 1) -- 같은 (inst,k)에서 store 재발행
		allPass = report("C-3b: 같은 (inst,k) 재발행은 false(no-op, 재파괴/재생성 없음)", claimed2 == false, false, claimed2) and allPass

		releaseOwner(slotA, frame1)
	end

	-- --- C-4. top-level Frame{slot, slot}: 같은 inst, 다른 k -> error ---

	do
		local slotB = { __name = "slotB" }
		local frame2 = { __name = "Frame2" }

		claimOwnerAt(slotB, frame2, 1) -- k=1에 마운트

		local ok3 = pcall(function()
			claimOwnerAt(slotB, frame2, 2) -- 같은 inst, 다른 위치(k=2)에 같은 slotB
		end)
		allPass = report("C-4: [핵심] top-level Frame{slot,slot}(같은 inst, 다른 k) -> error", ok3 == false, false, ok3) and allPass

		-- 음성 대조군: owner만 보고 위치(k)를 안 보는 옛 claimOwner였다면
		-- current==inst라 조용히 false를 반환해 버림 -> 이후 파괴적 클로저가
		-- 두 자리 모두에서 반환되어 이중 파괴로 이어지는 게 실제 발견된 버그
		local function oldClaimOwnerNoPos(element, inst, registry)
			local current = registry[element]
			if current == inst then
				return false -- 위치를 안 봐서 k=2도 그냥 no-op 취급 — 버그
			end
			if current ~= nil then
				error("다른 곳에 마운트됨")
			end
			registry[element] = inst
			return true
		end
		local oldRegistry = {}
		local oc1 = oldClaimOwnerNoPos(slotB, frame2, oldRegistry)
		local oc2 = oldClaimOwnerNoPos(slotB, frame2, oldRegistry) -- k=2에서도 에러 없이 false — 버그 재현
		allPass = report("(음성 대조군) 위치를 안 보는 옛 claimOwner였다면 Frame{slot,slot}이 에러 없이 통과함", oc1 == true and oc2 == false, "true,false", tostring(oc1) .. "," .. tostring(oc2)) and allPass

		releaseOwner(slotB, frame2)
	end

	-- --- C-5. release 후 재클레임은 정상 통과 ---

	do
		local slotC = { __name = "slotC" }
		local frame3 = { __name = "Frame3" }
		local frame4 = { __name = "Frame4" }

		claimOwnerAt(slotC, frame3, 1)
		releaseOwner(slotC, frame3)
		local claimed = claimOwnerAt(slotC, frame4, 1) -- 해제 후 완전히 다른 곳에 재마운트
		allPass = report("C-5: release 이후엔 다른 owner가 정상 클레임 가능", claimed == true, true, claimed) and allPass

		releaseOwner(slotC, frame4)
	end

	-- --- C-6. 불일치 release -> error ---

	do
		local slotD = { __name = "slotD" }
		local frame5 = { __name = "Frame5" }
		local frame6 = { __name = "Frame6" }

		claimOwnerAt(slotD, frame5, 1)
		local ok4 = pcall(function()
			releaseOwner(slotD, frame6) -- frame5가 쥐고 있는데 frame6이 release 시도
		end)
		allPass = report("C-6: 불일치 release -> error(호출측 소유권 추적 붕괴 즉시 감지)", ok4 == false, false, ok4) and allPass

		releaseOwner(slotD, frame5) -- 정리
	end
end

print()
print(allPass and "=== 전체 PASS ===" or "=== 하나 이상 FAIL — 위 로그에서 어느 케이스인지 확인할 것 ===")

--[[
	확인 포인트:
	1. A: "위치1이 a를 잃어도 위치2가 쥐고 있어 RemoveTag 안 불림" — 이게 FAIL이면
	   웹 className류 합집합 시맨틱이 실제로 안 되는 것이므로 tag-plan.md의
	   `tagNameMap` 알고리즘 자체를 재검토해야 함(최우선 보고).
	2. B: "[핵심] 그룹A가 점유 중인 이름을 그룹B가 잡으려 하면 -> error" 케이스가
	   FAIL이면, `Dispatch.process`의 인덱스 점유 체크만으로 그룹↔그룹 이름
	   충돌을 잡는다는 attribute-plan.md의 현재 모델 자체가 성립 안 하는 것 —
	   단, 이건 재디스패치 "하강 diff" 모델 도입 후에는 어차피 다시 뚫리는
	   케이스로 이미 알려져 있음(`.claude/question.md` 0-Z) — 그 결정이 나면
	   이 섹션 전체를 그 결정에 맞춰 다시 써야 함.
	3. C: C-1(nested 재클레임 error)/C-4(top-level 다른 위치 error)가 이
	   스파이크의 핵심 — 둘 다 "옛 3분기/위치 미검사 설계였다면 조용히
	   통과했을 것"을 음성 대조군으로 같이 보여줌. 이 중 하나라도 FAIL이면
	   Slot의 "재귀 재emit마다 서브트리가 파괴됐다 재생성되는" 또는 "이중
	   파괴" 버그로 직결되므로 최우선 보고.
]]
