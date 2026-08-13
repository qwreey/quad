--[[
	*** [2026-08-13 감사] B/C 섹션은 폐기·변경된 설계를 검증 중 — 돌리기 전에
	*** 아래대로 먼저 고칠 것. A 섹션은 그대로 유효(단 `kTagMap`은 이제 없음,
	*** 클로저가 `v`를 직접 캡처하므로 `tagNameMap` 하나만 남음 — 참조 카운트
	*** 로직 자체는 안 바뀌어서 A의 검증 내용은 그대로 성립).
	***
	***  B) `rawNew`+`owners` 수동 레지스트리는 2026-08-13 하루 안에 두 번
	***     뒤집혀 완전히 사라짐. 지금 설계는 그룹이 **공개 `AttributeKey(name)`**
	***     으로 항상 인덱스 1에 `Dispatch.process`만 부르고(retractFrom은
	***     부르지 않음 — 부르면 점유 체크가 무력화됨), 철거는 반환 클로저가
	***     자기가 등록한 이름 전부에 대해 수행. 소유권 충돌은 별도 레지스트리가
	***     아니라 **`Dispatch.process`의 인덱스 점유 체크**가 잡음.
	***     → B는 "그룹 A가 점유한 이름을 그룹 B가 잡으면 error가 나는가"를
	***       인덱스 점유 모델로 다시 써야 함(`base/attribute-plan.md`
	***       "이름 소유권"/"메커니즘" 절).
	***
	***  C) `claimOwner`가 "같은 owner면 no-op(false)"이던 3분기가 감사에서
	***     버그로 판정돼 둘로 쪼개짐 — nested(`rawAdd`)는 **엄격**(같은 owner
	***     재클레임도 error, `Slot{a,a}`를 막기 위함), top-level만
	***     `claimOwnerAt(element, inst, k)`으로 **위치까지** 봐서 spurious
	***     재발행만 false. `destroySlotTree`/`rawRemove`의 `releaseOwner`
	***     호출도 새로 추가됨.
	***     → C는 이 두 함수를 각각 검증하도록 다시 써야 함
	***       (`base/slot-plan.md` "요소 소유권 — `elementOwner`" 절).

	검증 대상: "retract는 항상 불림" 전면 정정(2026-08-12 열한 번째 세션) 이후
	새로 생긴 세 가지 소유권/참조카운트 추적 로직이 실제로 짜인 대로 동작하는지 —
	전부 여러 위치/여러 사이클에 걸쳐 상태가 정확히 갱신되는지가 핵심이라
	손으로 추론만으로는 놓치기 쉬운 클래스(이 프로젝트가 이미 같은 클래스에서
	실제 버그를 두 번 냄: `retractUnder`의 and/or 삼항 falsy 버그, Slot
	`recompute`의 off-by-one). 셋 다 Roblox 엔진/GC 타이밍과 무관한 순수 Luau
	테이블 로직이지만, 03/04/11번 스파이크가 커버하는 것과는 다른 새 알고리즘
	모양(여러 위치가 하나의 이름/자리를 공유하는 참조 카운트, 캐싱된 키 객체의
	사이클 간 재사용, "같은 owner면 무시/다른 owner면 error" 3분기)이라 별도로
	실측이 필요하다고 판단해 신규 작성함.

	A) Tag 참조 카운트 — `base/tag-plan.md` "메커니즘 — TagHandler" 절의
	   `kTagMap`/`tagNameMap`. 서로 다른 두 위치가 같은 이름을 겹쳐 가질 때
	   (`Frame { Tag("a"), Tag("a","b") }`류) 한쪽이 이름을 잃어도 다른 쪽이
	   아직 쥐고 있으면 실제 `RemoveTag`가 안 불려야 함(웹 className 합집합
	   시맨틱).

	B) Attribute 소유권 — `base/attribute-plan.md` "이름 소유권" 절의 `rawNew`+
	   `owners` 레지스트리. 직접 리터럴 쓰기와 그룹 위임이 같은 이름을 동시에
	   관리하려 하면 즉시 error. 그룹의 "남아있는 이름"은 캐싱된 같은 키 객체를
	   여러 사이클에 걸쳐 재사용해야 함(매번 새 키를 만들면 owners 레지스트리가
	   자기 자신과 충돌하는 오탐이 남).

	C) Slot 요소 소유권 — `base/slot-plan.md` "요소 소유권 — `elementOwner`" 절의
	   `claimOwner`/`releaseOwner`. 같은 element가 이미 다른 곳에 마운트돼
	   있으면 error, 같은 owner가 다시 클레임하면 조용한 no-op(재귀 재emit
	   대응), 해제 후 다른 곳에 새로 붙는 건 정상 허용. top-level(Dispatch)과
	   nested(`Add`) 경로가 **같은** 레지스트리를 공유해야 서로의 마운트를 잡음.

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

print("=== A. Tag kTagMap/tagNameMap — 참조 카운트 ===")

do
	local kTagMap = makeRegistry() -- (inst,k) -> Tag(흉내: {names={...}})
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

	local function TagRetract(inst, k, newv)
		local oldv = kTagMap:get(inst, k)
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
		kTagMap:set(inst, k, v)
	end

	-- Frame { Tag("a"), Tag("a", "b") } — 두 위치(k=1, k=2)가 "a"를 겹쳐 가짐
	local tagPos1 = makeTag("a")
	local tagPos2 = makeTag("a", "b")
	TagRetract("Frame1", 1, tagPos1)
	TagProcess("Frame1", 1, tagPos1)
	TagRetract("Frame1", 2, tagPos2)
	TagProcess("Frame1", 2, tagPos2)

	-- Frame{Tag("a"), Tag("a","b")} 마운트 직후: "a"는 두 위치가 겹쳐 가지므로
	-- AddTag("a")는 첫 홀더가 생길 때 한 번만 실제로 불려야 함(로그 = {a, b})
	allPass = report("초기 마운트: AddTag 로그", #addLog == 2 and addLog[1] == "a" and addLog[2] == "b", "{a,b}", table.concat(addLog, ",")) and allPass

	-- 위치1이 "a"를 잃음(Tag()로 교체, 빈 값) — 위치2가 아직 "a"를 쥐고 있으므로
	-- 실제 RemoveTag("a")는 안 불려야 함
	local emptyTag = makeTag()
	TagRetract("Frame1", 1, emptyTag)
	TagProcess("Frame1", 1, emptyTag)

	allPass = report("위치1이 a를 잃어도 위치2가 쥐고 있어 RemoveTag 안 불림", #removeLog == 0, "0", #removeLog) and allPass

	-- 위치2도 "a"를 잃음 — 이제 진짜로 RemoveTag("a")가 불려야 함(b는 그대로 유지)
	local tagPos2b = makeTag("b")
	TagRetract("Frame1", 2, tagPos2b)
	TagProcess("Frame1", 2, tagPos2b)

	allPass = report("마지막 홀더도 a를 잃으면 RemoveTag(a) 실제로 불림", #removeLog == 1 and removeLog[1] == "a", "{a}", table.concat(removeLog, ",")) and allPass
end

-- ===== B. Attribute 소유권 — rawNew 전용 키 + owners 레지스트리 =====

print()
print("=== B. Attribute owners 레지스트리 — 소유권 충돌 + 캐시 재사용 ===")

do
	local owners = makeRegistry() -- (inst,name) -> keyObject
	local function rawNew(name)
		return { __name = name } -- identity가 의미있는 새 키 객체
	end

	local function AttributeKeyProcess(inst, k, v)
		local name = k.__name
		local map = owners:get(inst, "map") or {}
		local current = map[name]
		if current ~= nil and current ~= k then
			error(string.format('attribute "%s"는 이미 다른 AttributeKey가 관리 중', name))
		end
		if v == nil then
			map[name] = nil
		else
			map[name] = k
		end
		owners:set(inst, "map", map)
	end

	local directKey = rawNew("Enabled") -- 직접 리터럴 쓰기 흉내(공개 캐시 대신 여기선 그냥 키 하나)
	AttributeKeyProcess("Frame1", directKey, true)

	local ok1 = pcall(function()
		local groupKey = rawNew("Enabled") -- 그룹이 rawNew로 만든 별개 키 객체(이름은 같음)
		AttributeKeyProcess("Frame1", groupKey, false)
	end)
	allPass = report("직접 쓰기 + 그룹이 같은 이름을 동시에 관리 -> error", ok1 == false, false, ok1) and allPass

	-- 그룹 자신의 diff 사이클 — 같은 이름이 여러 사이클에 걸쳐 살아남으면
	-- 캐싱된 같은 키 객체를 재사용해야 함(안 그러면 owners가 자기 자신과 충돌)
	local groupCache = {} -- {[name] = keyObject} — attribute-plan.md의 "이름 -> 그 이름 전용 키" 맵
	local function groupCycle(names)
		for _, name in names do
			local key = groupCache[name] or rawNew(name)
			groupCache[name] = key
			AttributeKeyProcess("Frame2", key, true) -- 실제로는 Dispatch.retractUnder+process 페어, 여기선 process만 흉내
		end
	end

	groupCycle({ "Health", "Mana" })
	local firstHealthKey = groupCache["Health"]
	groupCycle({ "Health", "Mana" }) -- 2번째 사이클, 같은 이름들 살아남음

	local ok2 = groupCache["Health"] == firstHealthKey
	allPass = report("남아있는 이름은 사이클 간 같은 키 객체 재사용(재생성 아님)", ok2, true, ok2) and allPass

	local ok3, err3 = pcall(function()
		-- 캐시를 무시하고 매번 새 키를 만들면(버그 시뮬레이션) 자기 자신과도 충돌해야 정상
		local staleKey = rawNew("Health")
		AttributeKeyProcess("Frame2", staleKey, true)
	end)
	allPass = report("캐시 우회하고 새 키로 같은 이름 쓰면 자기 자신과도 충돌(캐시 재사용이 왜 필수인지 반증)", ok3 == false, false, ok3) and allPass
end

-- ===== C. Slot elementOwner — claimOwner/releaseOwner =====

print()
print("=== C. Slot elementOwner — 다중 마운트 금지 + 같은 owner는 no-op ===")

do
	local elementOwner = makeRegistry()
	local OWNER = "__owner"

	local function claimOwner(element, ownerKey)
		local current = elementOwner:get(element, OWNER)
		if current == ownerKey then
			return false -- 이미 같은 owner — no-op
		end
		if current ~= nil then
			error("이 요소는 이미 다른 곳에 마운트돼 있음 — 다중 마운트 금지")
		end
		elementOwner:set(element, OWNER, ownerKey)
		return true
	end

	local function releaseOwner(element, ownerKey)
		if elementOwner:get(element, OWNER) == ownerKey then
			elementOwner:set(element, OWNER, nil)
		end
	end

	local slotA = { __name = "slotA" }
	local frame1 = { __name = "Frame1" }
	local frame2 = { __name = "Frame2" }
	local outerSlot = { __name = "outerSlot" }

	local claimed1 = claimOwner(slotA, frame1) -- top-level Dispatch 마운트
	allPass = report("최초 클레임은 true(실제로 붙음)", claimed1 == true, true, claimed1) and allPass

	local claimed2 = claimOwner(slotA, frame1) -- 같은 owner가 재emit(재귀 재계산 등)
	allPass = report("같은 owner 재클레임은 false(no-op, 재파괴/재생성 없음)", claimed2 == false, false, claimed2) and allPass

	local ok4 = pcall(function()
		claimOwner(slotA, outerSlot) -- nested Add가 같은 slotA를 다른 곳에 붙이려 함
	end)
	allPass = report("top-level이 이미 소유 중인데 nested Add가 같은 element를 또 클레임 -> error", ok4 == false, false, ok4) and allPass

	releaseOwner(slotA, frame1) -- top-level에서 정상 해제(retract)
	local claimed3 = claimOwner(slotA, outerSlot) -- 해제 후엔 다른 곳에 정상적으로 다시 붙을 수 있음
	allPass = report("release 이후엔 다른 owner가 정상 클레임 가능", claimed3 == true, true, claimed3) and allPass

	local ok5 = pcall(function()
		claimOwner(slotA, frame2) -- outerSlot이 아직 쥐고 있는데 frame2가 가로채려 함
	end)
	allPass = report("release 안 된 상태에서 제3자가 가로채려 하면 -> error", ok5 == false, false, ok5) and allPass
end

print()
print(allPass and "=== 전체 PASS ===" or "=== 하나 이상 FAIL — 위 로그에서 어느 케이스인지 확인할 것 ===")

--[[
	확인 포인트:
	1. A: "위치1이 a를 잃어도 위치2가 쥐고 있어 RemoveTag 안 불림" — 이게 FAIL이면
	   웹 className류 합집합 시맨틱이 실제로 안 되는 것이므로 tag-plan.md의
	   `kTagMap`/`tagNameMap` 알고리즘 자체를 재검토해야 함(최우선 보고).
	2. B: "캐시 우회하고 새 키로 같은 이름 쓰면 자기 자신과도 충돌" 케이스가
	   FAIL(즉 에러가 안 남)이면 오히려 좋은 신호가 아니라, attribute-plan.md가
	   "캐시가 그룹 값 교체를 넘어 영속돼야 한다"고 요구하는 이유 자체가
	   이 스파이크에서 재현이 안 된 것 — 이 경우 이 검증 케이스 설계를
	   재검토할 것(알고리즘이 아니라 테스트 설계 문제일 수 있음).
	3. C: 세 가지 분기(같은 owner=no-op, 다른 owner=error, release 후 재클레임=
	   정상)가 전부 정확히 갈리는가 — 이 셋 중 하나라도 안 갈리면 Slot의
	   "재귀 재emit마다 서브트리가 파괴됐다 재생성되는" 파괴적 버그
	   (slot-plan.md 참고)로 직결되므로 FAIL이면 최우선 보고.
]]
