--[[
	검증 대상: base 디스패치 드라이버가 명시적으로 강제하는
	"배열 파트(children/Ref) 먼저, 해시 파트(프로퍼티/이벤트) 나중" 두 패스 순회 계약.

	배경: .claude/base/bind-system-plan.md "props 순회 순서" 절, ROADMAP.md M0 4번째 항목.
	사용자가 이미 Luau REPL로 `for i,v in {a=1, 2, b=3} do ... end`가
	`1, 2` 다음 `a, 1` `b, 3` 순서로 나오는 걸 확인했었지만(우연한 관찰),
	base는 이 우연한 동작에 기대지 않고 배열 파트(1..#t)를 먼저, 그 다음
	별도로 해시 파트만 골라내는 두 패스를 "명시적으로" 강제하기로 확정함
	— 이 스크립트는 그 강제 버전이 실제로 계약대로 동작하는지 확인.

	실행: `luau 01-two-pass-array-hash-order.luau` (Roblox 필요 없음, 순수 CLI)
	기대 결과: "array pass"가 항상 "hash pass"보다 먼저 전부 출력되고,
	array pass 안에서는 index 순서(1,2,3...)가 정확히 지켜져야 함.
]]

local function isArrayKey(k)
	return type(k) == "number" and k == math.floor(k) and k >= 1
end

-- Dispatch.drive(inst, flattened)의 최소 스파이크 버전
local function drive(inst, flattened)
	-- pass 1: 배열 파트, index 순서 보장
	local n = #flattened
	for i = 1, n do
		local v = flattened[i]
		print(string.format("[array pass] inst=%s i=%d v=%s", tostring(inst), i, tostring(v)))
	end

	-- pass 2: 해시 파트, 배열 인덱스(1..#t)는 건너뜀
	-- 주의: pairs()/제네릭 for는 배열 파트도 다시 순회하므로 반드시 걸러내야 함
	for k, v in flattened do
		if not (isArrayKey(k) and k <= n) then
			print(string.format("[hash pass] inst=%s k=%s v=%s", tostring(inst), tostring(k), tostring(v)))
		end
	end
end

local children = { "Ref1", "Child2", "Child3" }
local props = {
	children[1],
	children[2],
	children[3],
	Name = "TestFrame",
	BackgroundTransparency = 0,
	Event_Activated = "handler",
}

print("=== two-pass order 검증 ===")
drive("FakeInstance", props)

--[[
	추가로 확인할 것 (실행 후 눈으로 확인):
	1. array pass 3개가 hash pass보다 먼저, 그리고 i=1,2,3 순서로 나오는가?
	2. hash pass에 array 항목(children)이 중복으로 안 섞여 나오는가?
	3. 테이블 리터럴에서 해시 키를 적는 소스 텍스트 순서를 바꿔도(Name/
	   BackgroundTransparency/Event_Activated 순서를 바꿔서 재실행)
	   array pass 결과가 그대로인지 확인해볼 것 — 순서가 소스 텍스트가
	   아니라 오직 "배열/해시 파트 분리"에만 의존한다는 걸 재확인하는 목적.
]]
