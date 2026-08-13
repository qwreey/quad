--[[
	검증 대상: `Slot:Splice(index, removeCount, ...newElements)`
	(`base/slot-plan.md` "확정" CRUD 표 + "`Splice` 신설" 절, 2026-08-12
	열다섯 번째 세션 신규) — 한 구간을 제거하고 동시에 새 요소를 그 자리에
	삽입하는 shift+recompute 1회짜리 연산이, 문서 자신이 명시한 불변식
	("`Splice`의 결과는 항상 `Extract` 반복 + `Add` 반복으로도 재현 가능해야
	함")을 실제로 만족하는지.

	왜 이게 필요한가: 이 프로젝트는 인덱스 시프트 계산에서 이미 한 번 실제
	버그를 냈음(`Dispatch.recompute`의 offset이 자기 자신을 포함해 누적되던
	off-by-one, 2026-08-11 여섯 번째 세션, `base/bind-system-plan.md` 참고) —
	Splice는 제거 구간과 삽입 구간이 서로 다른 길이일 때 뒤 요소들이 얼마나
	밀리는지를 한 번에 계산해야 해서 같은 클래스의 off-by-one 위험이 있음.
	Roblox 엔진/GC 타이밍과 무관한 순수 인덱스 산술이라 `luau` CLI로 바로
	검증 가능.

	방법: `rawSplice`를 흉내낸 구현과, 그와 독립적으로 "제거 구간을 하나씩
	`Extract`, 그 자리에 하나씩 `Add`"를 반복하는 훨씬 단순하고 명백히 옳은
	참조 구현(reference impl) 둘을 각 케이스에 나란히 돌려 최종 배열과 반환된
	제거분이 완전히 일치하는지 비교 — 손으로 기대값을 미리 계산해두지 않아도
	두 구현이 divergence하면 그 자체가 버그 신호.

	실행: `luau 20-slot-splice-index-arithmetic.luau`
]]

-- ===== 참조 구현: Extract 반복 + Add 반복(단순하고 명백히 옳음) =====

local function referenceSplice(arr, index, removeCount, newElements)
	local out = table.clone(arr)
	local removed = {}
	-- removeCount개를 index 위치에서 하나씩 Extract(뒤 요소가 당겨짐)
	for _ = 1, removeCount do
		table.insert(removed, table.remove(out, index))
	end
	-- newElements를 index 위치부터 하나씩 Add(뒤 요소가 밀림)
	for i, el in newElements do
		table.insert(out, index + i - 1, el)
	end
	return out, removed
end

-- ===== 실측 대상: shift 1회 + recompute 1회로 묶은 구현 =====
-- base/slot-plan.md가 "새 능력 추가 아님, 순수 최적화"라고 명시한 대로,
-- table.move 기반 단일 시프트로 같은 결과를 내야 함.

local function rawSplice(arr, index, removeCount, newElements)
	local n = #arr
	local removed = {}
	for i = 0, removeCount - 1 do
		removed[i + 1] = arr[index + i]
	end

	local newCount = #newElements
	local delta = newCount - removeCount -- 양수면 뒤가 더 밀림, 음수면 당겨짐

	if delta > 0 then
		-- 뒤 요소들을 delta칸 뒤로 미리 밀어 공간 확보(뒤에서부터 복사해야 겹침 안 깨짐)
		for i = n, index + removeCount, -1 do
			arr[i + delta] = arr[i]
		end
	elseif delta < 0 then
		-- 뒤 요소들을 -delta칸 앞으로 당김(앞에서부터 복사)
		for i = index + removeCount, n do
			arr[i + delta] = arr[i]
		end
		for i = n + delta + 1, n do
			arr[i] = nil
		end
	end

	for i, el in newElements do
		arr[index + i - 1] = el
	end

	return arr, removed
end

-- ===== 케이스들 — 경계값 위주(off-by-one이 실제로 숨을 만한 자리) =====

local cases = {
	{ name = "제거=삽입 길이 같음(제자리 교체)", arr = { "a", "b", "c", "d" }, index = 2, removeCount = 2, newElements = { "X", "Y" } },
	{ name = "삽입 > 제거(뒤가 밀림)", arr = { "a", "b", "c", "d" }, index = 2, removeCount = 1, newElements = { "X", "Y", "Z" } },
	{ name = "제거 > 삽입(뒤가 당겨짐)", arr = { "a", "b", "c", "d", "e" }, index = 2, removeCount = 3, newElements = { "X" } },
	{ name = "removeCount=0(순수 삽입, Add와 동치여야 함)", arr = { "a", "b", "c" }, index = 2, removeCount = 0, newElements = { "X", "Y" } },
	{ name = "newElements 없음(순수 제거, Extract 반복과 동치여야 함)", arr = { "a", "b", "c", "d" }, index = 2, removeCount = 2, newElements = {} },
	{ name = "맨 앞(index=1)", arr = { "a", "b", "c" }, index = 1, removeCount = 1, newElements = { "X", "Y" } },
	{ name = "맨 끝까지 제거(index+removeCount-1 == #arr)", arr = { "a", "b", "c", "d" }, index = 3, removeCount = 2, newElements = { "X" } },
	{ name = "끝에 순수 추가(index = #arr+1, removeCount=0)", arr = { "a", "b", "c" }, index = 4, removeCount = 0, newElements = { "X", "Y" } },
	{ name = "전체 교체(index=1, removeCount=#arr)", arr = { "a", "b", "c" }, index = 1, removeCount = 3, newElements = { "X", "Y", "Z", "W" } },
	{ name = "단일 원소 배열에서 단일 교체", arr = { "a" }, index = 1, removeCount = 1, newElements = { "X" } },
	{ name = "삽입 개수가 제거보다 훨씬 큼(delta 큰 양수)", arr = { "a", "b", "c" }, index = 2, removeCount = 1, newElements = { "X", "Y", "Z", "W", "V" } },
}

local function arraysEqual(a, b)
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

local allPass = true

for _, case in cases do
	local refArr, refRemoved = referenceSplice(case.arr, case.index, case.removeCount, case.newElements)
	local rawArr = table.clone(case.arr)
	local _, rawRemoved = rawSplice(rawArr, case.index, case.removeCount, case.newElements)

	local finalOk = arraysEqual(refArr, rawArr)
	local removedOk = arraysEqual(refRemoved, rawRemoved)
	local pass = finalOk and removedOk

	allPass = allPass and pass

	print(string.format("  [%s] %s", pass and "PASS" or "FAIL", case.name))
	if not pass then
		print("      reference 최종:", table.concat(refArr, ","), " / raw 최종:", table.concat(rawArr, ","))
		print("      reference 제거분:", table.concat(refRemoved, ","), " / raw 제거분:", table.concat(rawRemoved, ","))
	end
end

print()
print(allPass and "=== 전체 PASS ===" or "=== 하나 이상 FAIL — off-by-one 등 shift 계산 버그 가능성, 최우선 보고 ===")

--[[
	확인 포인트:
	1. 모든 케이스가 PASS인가 — 특히 "delta 큰 양수"/"전체 교체"/"맨 끝까지
	   제거" 세 케이스는 시프트 방향(뒤에서부터 vs 앞에서부터 복사)을 잘못
	   고르면 데이터가 겹쳐써지는 클래식 버그가 나는 자리라 우선 확인할 것.
	2. 이 파일의 `rawSplice`는 문서(`slot-plan.md`)가 서술한 알고리즘을
	   이 스파이크 작성자가 재구현한 것 — 실제 M6 구현이 이거랑 정확히
	   같은 모양일 필요는 없지만, "제거+삽입을 시프트 1회로 묶어도
	   Extract반복+Add반복과 결과가 항상 같다"는 불변식 자체가 성립하는지
	   확인하는 게 이 스파이크의 목적. FAIL이 나면 `rawSplice`가 아니라
	   불변식 자체(또는 이 스파이크의 케이스 설계)를 의심해볼 것.
	3. 이 스파이크는 논리적 정합성만 다룸 — 실제 Slot 구현이 여기에 더해
	   다뤄야 하는 것(요소 타입 검증, 이미 마운트된 element 거부, 물리
	   detach/reattach 타이밍)은 범위 밖, `slot-plan.md` 본문 참고.
]]
