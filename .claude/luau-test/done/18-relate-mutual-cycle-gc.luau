--[[
	검증 대상: `base/relate-plan.md` "위험한 패턴 — 서로 다른 두 `Relate`의
	상호 강참조 순환" 절의 핵심 주장 — Luau에 ephemeron 테이블이 없어서
	(https://luau.org/compatibility/ "Lua 5.2" 섹션), 서로 다른 두 weak-key
	테이블이 서로의 키를 상대방의 강한 값으로 제공하는 순환을 만들면 GC가
	절대 못 푼다는 것. 지금까지 이 주장은 **공식 문서 인용으로만** 뒷받침돼
	있었고, 실제 Luau로 재현해본 적은 없었음(2026-08-12 열세/열네 번째
	세션, `Slot`의 `kSlotMap`/`slotOwner`가 이 패턴에 걸려있었다가 한쪽을
	`SetWeak`로 낮춰 수정된 실제 사례).

	이 스파이크는 두 부분:
	1. **위험한 패턴 재현(음성 대조군)** — 두 테이블 다 상대방 키를 강하게
	   들면 실제로 안 죽는지.
	2. **수정된 패턴 확인(양성 대조군)** — `relate-plan.md`가 처방한 대로
	   한쪽을 weak-value로 낮추면 실제로 죽는지.

	배경: `base/relate-plan.md` "위험한 패턴" 절, `base/slot-plan.md` "Slot과
	Store 바인드의 관계" 절(`kSlotMap`/`slotOwner` 실사례).

	실행: `luau 18-relate-mutual-cycle-gc.luau` (순수 luau CLI, Roblox 불필요
	— `collectgarbage()`를 직접 씀, `07`과 같은 이유).
]]

local function newStrongKeyWeakTable()
	return setmetatable({}, { __mode = "k" }) -- 키만 weak, 값은 기본(strong)
end

print("=== 1. 위험한 패턴 재현 — 상호 강참조 순환은 GC가 안 풀어야 함 ===")
do
	local relateA = newStrongKeyWeakTable() -- inst(weak key) -> value(strong 값)
	local relateB = newStrongKeyWeakTable() -- value(weak key) -> inst(strong 값)

	local canary
	do
		local inst = {}
		local value = {}
		relateA[inst] = value
		relateB[value] = inst
		-- canary 자신은 inst/value를 약하게만 참조 — 관찰 전용, 생존에 관여 안 함
		canary = setmetatable({ inst, value }, { __mode = "v" })
		-- 이 do-블록을 벗어나면 inst/value에 대한 강한 로컬 참조는 사라짐 —
		-- 남은 건 relateA/relateB 안의 상호 참조뿐
	end

	collectgarbage()
	collectgarbage()

	local instAlive = canary[1] ~= nil
	local valueAlive = canary[2] ~= nil
	print("inst 살아있음?", instAlive, "(기대: true — 상호 순환 때문에 안 풀림, ephemeron 없음)")
	print("value 살아있음?", valueAlive, "(기대: true — 같은 이유)")
	if not instAlive and not valueAlive then
		warn("[예상 밖] 상호 순환인데도 GC됨 — Luau가 이 케이스를 실제로 처리한다는 뜻, relate-plan.md의 '위험한 패턴' 경고 자체를 재검토해야 함")
	end
end

print()
print("=== 2. 수정된 패턴 — relate-plan.md 처방대로 한쪽을 weak-value로 낮추면 풀려야 함 ===")
do
	local relateA = newStrongKeyWeakTable() -- inst(weak key) -> value(strong 값), 그대로 둠
	local relateBWeak = setmetatable({}, { __mode = "kv" }) -- value(weak key) -> inst(이번엔 값도 weak)

	local canary
	do
		local inst = {}
		local value = {}
		relateA[inst] = value
		relateBWeak[value] = inst
		canary = setmetatable({ inst, value }, { __mode = "v" })
	end

	collectgarbage()
	collectgarbage()

	local instAlive = canary[1] ~= nil
	local valueAlive = canary[2] ~= nil
	print("inst 살아있음?", instAlive, "(기대: false — 이번엔 GC됨)")
	print("value 살아있음?", valueAlive, "(기대: false — 같은 이유)")
	if instAlive or valueAlive then
		warn("[예상 밖] weak-value로 낮췄는데도 안 죽음 — relate-plan.md의 처방(SetWeak로 낮추기)이 실제로는 안 통한다는 뜻, 최우선으로 재검토")
	end
end

--[[
	확인 포인트:
	1번 섹션은 true/true, 2번 섹션은 false/false가 나와야 relate-plan.md의
	주장(위험한 패턴 존재 + 처방 효과 있음) 둘 다 실측 확인된 것. 어느 한쪽이
	라도 기대와 다르면(특히 warn이 뜨면) `base/relate-plan.md` "위험한 패턴"
	절과 `base/slot-plan.md`의 `kSlotMap`/`slotOwner`/`elementOwner` 설계
	전체를 재검토해야 함 — 이 사례 하나가 Slot GC 설계의 유일한 근거였음.
]]
