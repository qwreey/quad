--[[
	검증 대상: 배열 슬롯을 "소진"시킬 때 nil로 지울지 None 센티널로 지울지는
	그 배열의 성격(순서가 중요한가, 슬롯 재사용이 필요한가)에 따라 갈린다는,
	2026-08-09 열한 번째 세션에 재정정된 최종 결론.

	**[중요, 2026-08-09 커밋 f198fd9 반영]** 이 파일의 이전 버전은
	"Ref 콜백/대기자 배열도 None으로 소진해야 한다"고 잘못 적어뒀었음 —
	사용자가 직접 찾아낸 버그: None으로 소진하면 그 슬롯이 영원히
	non-nil로 남아있어서, `:Wait()`/`:Callback()`가 반복 호출될 때마다
	배열이 끝없이 길어지는(예전 소진 슬롯을 재사용 못 하는) 진짜 버그였음.
	.claude/base/bind-system-plan.md "왜 None이 아니라 nil인가" 절(2026-08-09
	열한 번째 세션, 최종 정정)이 최신 소스 — 결론은 두 패턴이 서로 다른
	문제를 풀고 있었다는 것:

	- **순서가 중요한 배열(PreRef pre-pass 소진 슬롯, Length/Offset의
	  sourceList)**: 계속 `None` — 구멍이 생기면 해시 파트로 밀려
	  index 순회 순서가 깨지므로, "채워짐"을 유지해야 함.
	- **순서가 안 중요하고 슬롯 재사용이 필요한 배열(Ref 콜백/대기자
	  리스트)**: `nil` + "빈 슬롯을 선형 탐색해 재사용"하는 등록 함수
	  (`table.insert`는 안 씀 — 구멍 있는 테이블에서 `#t`가 미정의
	  동작이라서). 순서 자체는 문제 안 됨 — 일반화 `for`는 구멍이 있어도
	  모든 non-nil 엔트리를 빠짐없이 방문하기 때문.

	이 스크립트는 두 패턴을 나란히 재현해서 각각이 실제로 옳은 선택인지,
	그리고 "None을 잘못 썼을 때 실제로 배열이 끝없이 자라는" 버그 자체도
	수치로 보여줌.

	실행: `luau 02-none-sentinel-vs-nil-holes.luau`
]]

local None = setmetatable({}, { __tostring = function()
	return "<None>"
end })

-- ===============================================================
-- Part A. 순서가 중요한 배열 — None이 맞는 경우 (PreRef pre-pass, sourceList)
-- ===============================================================

print("=== A. 순서가 중요한 배열: None으로 소진해야 순서/#t가 안 깨짐 ===")

local N = 50

local function buildList(n)
	local t = {}
	for i = 1, n do
		t[i] = "item" .. i
	end
	return t
end

print("-- A-1) BAD: nil로 지우면 순서/#t가 불안정해짐 --")
local bad = buildList(N)
for i = 2, N, 2 do
	bad[i] = nil
end
print("bad #t =", #bad, "(Lua 명세상 정의되지 않은 동작 — 실제 값 확인용)")
local badOrder = {}
for i, v in bad do
	table.insert(badOrder, tostring(i) .. "=" .. tostring(v))
end
print("bad 순회 순서(구멍이 생겨 흐트러질 수 있음):", table.concat(badOrder, ", "))

print()
print("-- A-2) GOOD: None으로 지우면 #t/순서가 항상 보존됨(PreRef pre-pass에 필요한 성질) --")
local good = buildList(N)
for i = 2, N, 2 do
	good[i] = None
end
print("good #t =", #good, "(항상 N — 구멍이 없으니까)")
local goodOrder = {}
for i = 1, #good do
	local v = good[i]
	goodOrder[#goodOrder + 1] = tostring(i) .. "=" .. (v == None and "None" or tostring(v))
end
print("good 순회 순서(1..#t로 직접, 항상 안정적):", table.concat(goodOrder, ", "))

-- ===============================================================
-- Part B. 순서가 안 중요하고 슬롯 재사용이 필요한 배열 — nil이 맞는 경우
-- (Ref 콜백/대기자 리스트가 실제로 이 카테고리, 2026-08-09 최종 정정)
-- ===============================================================

print()
print("=== B. Ref 콜백/대기자 리스트: None을 쓰면 무한 성장 버그, nil+재사용이 맞음 ===")

-- 등록: table.insert 대신 "빈(nil) 슬롯을 선형 탐색해 재사용"
local function registerNil(list, value)
	for i = 1, #list + 1 do
		if list[i] == nil then
			list[i] = value
			return i
		end
	end
end

-- 소진: 그 인덱스를 nil로 되돌림(재사용 가능하게)
local function consumeNil(list, i)
	list[i] = nil
end

-- 대조군: 예전에 잘못 썼던 None 기반 버전(table.insert로만 추가, 소진은 None)
local function registerNoneBad(list, value)
	table.insert(list, value)
	return #list
end
local function consumeNoneBad(list, i)
	list[i] = None
end

print("-- B-1) nil + 슬롯 재사용: 동시 대기자 수만큼만 배열 크기가 유지되는가 --")
do
	local waiters = {}
	local maxSizeSeen = 0
	-- "등록 -> 곧바로 소진"을 여러 번 반복(:Wait() 호출 후 fire되는 흔한 패턴 흉내)
	for cycle = 1, 1000 do
		local idx = registerNil(waiters, "waiter" .. cycle)
		maxSizeSeen = math.max(maxSizeSeen, #waiters)
		consumeNil(waiters, idx)
	end
	print("1000번 등록/소진 반복 후 배열 길이 =", #waiters, "(0이어야 함 — 전부 소진됨)")
	print("과정 중 관측된 최대 배열 크기 =", maxSizeSeen, "(작게 유지돼야 함, 이상적으론 1)")
end

print()
print("-- B-2) None + table.insert(예전 버그): 같은 패턴을 반복하면 배열이 끝없이 자람 --")
do
	local waiters = {}
	for cycle = 1, 1000 do
		local idx = registerNoneBad(waiters, "waiter" .. cycle)
		consumeNoneBad(waiters, idx)
	end
	print("1000번 등록/소진 반복 후 배열 길이 =", #waiters, "(1000이어야 함 — 이게 바로 그 버그)")
	local noneCount = 0
	for _, v in waiters do
		if v == None then
			noneCount += 1
		end
	end
	print("그 중 None으로 채워진(죽은) 슬롯 개수 =", noneCount, "(전부 죽은 슬롯인데 자리만 차지)")
end

print()
print("-- B-3) nil 소진이 순서를 안 깨는가(대기자는 순서 안 중요하지만, 그래도 확인) --")
do
	local waiters = {}
	registerNil(waiters, "keep-me-1")
	local idx2 = registerNil(waiters, "temp-2")
	registerNil(waiters, "keep-me-3")
	consumeNil(waiters, idx2) -- 중간 슬롯 소진 -> 구멍 생김
	local visited = {}
	for i, v in waiters do
		table.insert(visited, tostring(i) .. "=" .. tostring(v))
	end
	print("구멍 있는 상태에서 순회(전부 방문되기만 하면 충분, 순서 무관):", table.concat(visited, ", "))
	-- 이제 새 등록이 빈 슬롯(구멍)을 재사용하는지 확인
	local reusedIdx = registerNil(waiters, "reused")
	print("새 등록이 빈 슬롯(index=" .. idx2 .. ")을 재사용했는가?", reusedIdx == idx2)
end

--[[
	확인 포인트:
	1. Part A — good(None) 쪽은 #t/순서가 항상 N으로 안정적인가(PreRef
	   pre-pass가 요구하는 성질 재확인).
	2. Part B-1 — nil+재사용 방식은 반복해도 배열이 안 커지는가(0 또는
	   작은 값 유지)?
	3. Part B-2 — None+table.insert 방식은 실제로 1000까지 자라는가 —
	   이게 바로 사용자가 찾아낸 "무한 성장" 버그의 정량적 재현. 이 결과가
	   기대와 다르면(예: 실제로는 안 자란다면) bind-system-plan.md의 정정
	   근거 자체를 재검토해야 하니 반드시 알려줄 것.
	4. Part B-3 — 새 등록이 소진된 빈 슬롯(index=idx2)을 실제로 재사용하는가
	   — 이게 "table.insert 대신 선형 탐색 재사용 등록 함수"가 실제로
	   의도대로 동작하는지의 핵심 확인.
]]
