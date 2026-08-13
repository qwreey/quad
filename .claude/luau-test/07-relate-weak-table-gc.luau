--[[
	검증 대상: .claude/base/relate-plan.md가 확정한 Relate의 실제 구조
	({ [inst(weak)]: { StrongMap?, WeakMap? } })가 Luau의 진짜 weak-table
	GC 동작과 맞아떨어지는지 — lazy 서브테이블 생성, WeakMap 공유
	메타테이블, 그리고 무엇보다 "inst가 죽으면 중첩된 것까지 전부
	같이 GC되는가"라는 .claude/base/bind-system-plan.md "왜 GC-안전한가"
	절의 핵심 주장 자체.

	배경: .claude/base/relate-plan.md "M2 착수 시 실측 확인" 캐비엇.

	중요한 제약: Roblox의 실제 게임 스크립트 환경에는 collectgarbage()가
	명시적으로 노출되지 않음 — 그래서 이 스크립트 자체(collectgarbage()를
	직접 호출)는 Roblox Studio가 아니라 순수 luau CLI에서 돌려야 함
	(standalone Luau 인터프리터는 collectgarbage를 허용). Roblox 쪽은
	VM/GC 구현 자체가 같은 Luau이므로 여기서 확인된 동작이 그대로
	적용된다고 가정할 수 있지만, "그대로 적용된다"는 가정 자체는 이
	스크립트로 검증 불가능한 항목으로 남음(참고만 할 것).

	**[2026-08-13 갱신]** "그래서 Studio에서는 GC 타이밍 검증 자체가
	불가능하다"는 예전 결론은 정정됨 — `collectgarbage()` API가 없을
	뿐, weak-value 테이블에 canary를 넣고 할당 압력을 걸며 기다리는
	간접 기법으로 Studio에서도 GC 완료를 관찰 가능함이 실측 확인됨
	(`gc-trigger-helper.server.luau`, `audit/gcconn-trick-verification.md`
	참고). `10`처럼 Studio 스파이크에서 GC 완료를 기다려야 하면 그
	헬퍼를 쓸 것 — 이 파일(`07`)은 여전히 순수 luau CLI 전용으로 남김
	(더 정확한 `collectgarbage()` 직접 호출을 쓸 수 있어 굳이 간접
	기법으로 바꿀 이유 없음).

	실행: `luau 07-relate-weak-table-gc.luau`
]]

local sharedWeakValueMeta = { __mode = "v" }

local function Relate()
	local outer = setmetatable({}, { __mode = "k" }) -- inst는 항상 weak
	local relate = {}

	local function subtable(inst)
		local t = outer[inst]
		if not t then
			t = {}
			outer[inst] = t
		end
		return t
	end

	function relate.SetStrong(_, inst, key, value)
		local t = subtable(inst)
		t.StrongMap = t.StrongMap or {}
		t.StrongMap[key] = value
	end
	function relate.GetStrong(_, inst, key)
		local t = outer[inst]
		if not t or not t.StrongMap then
			return nil
		end
		return t.StrongMap[key]
	end
	function relate.SetWeak(_, inst, key, value)
		local t = subtable(inst)
		if not t.WeakMap then
			t.WeakMap = setmetatable({}, sharedWeakValueMeta)
		end
		t.WeakMap[key] = value
	end
	-- [2026-08-13 여섯 번째 세션 추가] 테스트 전용 — outer는 __mode="k"라
	-- 죽은 키의 엔트리는 GC 후 pairs 순회에서 사라짐. 즉 "weak table 내부
	-- 엔트리 개수를 셀 방법이 없다"던 이 파일의 옛 결론은 틀렸음.
	function relate._countEntries()
		local n = 0
		for _ in pairs(outer) do
			n += 1
		end
		return n
	end

	function relate.GetWeak(_, inst, key)
		local t = outer[inst]
		if not t or not t.WeakMap then
			return nil
		end
		return t.WeakMap[key]
	end

	-- 디버깅 전용 — 실제 Relate API엔 없음, 이 스파이크에서 관찰용으로만
	function relate._debugHasSubtable(_, inst)
		return outer[inst] ~= nil
	end

	return relate
end

print("=== 1. lazy 생성 확인 ===")
local relate1 = Relate()
local instA = {} -- 실제로는 Roblox Instance지만, 순수 luau CLI엔 없으므로 plain table로 대체
print("Set 호출 전 subtable 존재?", relate1:_debugHasSubtable(instA), "(false여야 함)")
relate1:SetStrong(instA, "k1", "v1")
print("SetStrong 호출 후 subtable 존재?", relate1:_debugHasSubtable(instA), "(true여야 함)")
print("GetStrong(instA, k1) =", relate1:GetStrong(instA, "k1"))
print("GetWeak(instA, 아무거나) — WeakMap 아직 안 만들어졌어도 nil로 안전하게 반환?", relate1:GetWeak(instA, "nope"))

print()
print("=== 2. inst가 스코프를 벗어나면 그 안의 StrongMap도 같이 사라지는가(간접 확인) ===")
local relate2 = Relate()
do
	local instB = {}
	relate2:SetStrong(instB, "tween", "FAKE_TWEEN_INSTANCE")
	print("instB 살아있을 때 GetStrong =", relate2:GetStrong(instB, "tween"))
	-- instB에 대한 유일한 강참조는 이 do-블록의 로컬 변수뿐 — 블록을 벗어나면 사라짐
end
collectgarbage() -- 표준 luau CLI에서 지원(Roblox에선 사용 불가 — 위 주석 참고)
collectgarbage()
print("(instB 참조를 잃었으므로 같은 값으로 재조회는 애초에 불가능 — 아래 3번이 실질 확인)")

print()
print("=== 3. weak key가 실제로 GC되는지 카운팅으로 확인 ===")
local relate3 = Relate()
local keepAlive = {} -- 이 배열에 담긴 것만 살아남음
for i = 1, 100 do
	local inst = {}
	relate3:SetStrong(inst, "data", "payload" .. i)
	if i <= 10 then
		keepAlive[i] = inst -- 앞 10개만 강하게 붙잡아둠
	end
	-- 나머지 90개는 루프 변수 스코프를 벗어나는 즉시 참조를 잃음
end
collectgarbage()
collectgarbage()

local aliveCount = 0
for i = 1, 10 do
	if relate3:GetStrong(keepAlive[i], "data") ~= nil then
		aliveCount += 1
	end
end
print("강하게 붙잡아둔 10개 중 살아있는 것:", aliveCount, "(10이어야 함)")
print("relate3의 살아있는 엔트리 총 개수:", relate3._countEntries(), "(10이어야 함 — 죽은 90개가 실제로 걷혔는지)")

print()
print("=== 4. 핵심 주장 직접 검증 — inst가 죽으면 *중첩된 서브테이블 안의 값*까지 같이 GC되는가 ===")
--[[
	이게 `base/bind-system-plan.md` "왜 GC-안전한가"와 `base/relate-plan.md`
	전체가 기대고 있는 바로 그 주장. 3번은 "바깥 키 엔트리가 걷히는가"까지만
	보는데, 실제로 중요한 건 그 안에 StrongMap으로 담아둔 **payload(gcconn,
	실행 중인 Tween, mounted Slot 등)까지 연쇄적으로 풀리는가**임.

	기법: payload를 weak-value canary 레지스트리에도 같이 등록해두고, inst
	참조만 끊은 뒤 GC. canary 엔트리가 사라졌으면 = payload가 실제로
	수거됨 = 연쇄 GC 확인.
]]
local relate4 = Relate()
local canary = setmetatable({}, { __mode = "v" }) -- payload를 약하게만 참조

do
	local liveInsts = {}
	for i = 1, 50 do
		local inst = {}
		local payload = { tag = "payload" .. i } -- StrongMap에 담길 실제 자원 흉내
		relate4:SetStrong(inst, "gchold", payload)
		canary[i] = payload
		if i <= 5 then
			liveInsts[i] = inst -- 앞 5개만 계속 살림
		end
	end
	collectgarbage()
	collectgarbage()

	local canaryAlive = 0
	for _ in pairs(canary) do
		canaryAlive += 1
	end
	print("inst 5개만 살린 상태에서 살아남은 payload 수:", canaryAlive, "(5여야 함 — 45개는 연쇄 GC돼야)")
	print("relate4의 살아있는 엔트리 총 개수:", relate4._countEntries(), "(5여야 함)")
	print("살아있는 inst로 payload 재조회 가능?", relate4:GetStrong(liveInsts[1], "gchold") ~= nil, "(true여야 함)")
end

-- liveInsts까지 스코프를 벗어난 뒤 다시 확인
collectgarbage()
collectgarbage()
local canaryAlive2 = 0
for _ in pairs(canary) do
	canaryAlive2 += 1
end
print("모든 inst 참조를 놓은 뒤 살아남은 payload 수:", canaryAlive2, "(0이어야 함 — 전부 연쇄 GC)")
print("relate4의 살아있는 엔트리 총 개수:", relate4._countEntries(), "(0이어야 함)")

print()
print('=== 참고: collectgarbage("count") 메모리 변화(대략적 신호일 뿐) ===')
print(collectgarbage("count"), "KB")

--[[
	확인 포인트:
	1. 1번 섹션 — SetStrong 호출 전엔 subtable이 안 만들어져 있다가, 호출
	   순간에만 생기는가(lazy 생성 실측).
	2. 3번 섹션 — collectgarbage()가 실제로 동작하고(에러 안 나고),
	   강하게 붙잡아둔 10개는 살아있는가(당연히 그래야 함 — sanity check).
	3. **[2026-08-13 여섯 번째 세션 정정·보강] "죽은 것이 실제로 GC됐는지
	   직접 카운트할 방법이 없다"던 옛 결론은 틀렸음.** outer 테이블이
	   `__mode = "k"`이므로 GC 후 죽은 키의 엔트리는 `pairs` 순회에서
	   그냥 사라짐 — 그래서 `relate._countEntries()`로 살아있는 엔트리
	   수를 직접 셀 수 있고, payload 쪽은 weak-value canary 레지스트리로
	   같이 세면 됨. 3번(엔트리 카운트)과 4번(연쇄 GC) 섹션이 그 방식.
	4. **4번 섹션이 이 파일의 진짜 핵심** — `base/bind-system-plan.md`
	   "왜 GC-안전한가"와 `base/relate-plan.md` 전체가 기대고 있는
	   "inst가 죽으면 그 안에 StrongMap으로 매달아둔 자원(gcconn/Tween/
	   mounted Slot 등)까지 연쇄적으로 풀린다"는 주장을 직접 확인함.
	   여기서 살아남은 payload 수가 기대치보다 크면 **GC-native 아키텍처
	   전체의 전제가 흔들리는 것**이므로 최우선으로 파고들 것.
]]
