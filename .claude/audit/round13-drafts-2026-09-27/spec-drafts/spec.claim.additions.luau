-- ── round13 Q154 (a) 초안 — E73 변이 공백(Claim 1패스 게이트·drive 순서). 대상 파일 끝의 `print("=== ALL PASS ===")` 바로
-- 앞에 넣는다. 대상 파일의 지역 이름 `q`, `M`, `makeTemplate`를 쓴다.

print()
print("=== 17. 1패스 게이트 — 소수 배열 키는 Quad0031로 아무것도 claim하기 전에 거부, 디스크립터 아닌 테이블은 Quad0034, 빈 클래스 이름은 Quad0026, 문자 키의 디스크립터는 VM 비교 에러가 아니라 Quad0076 ===")
-- 계약: docs/reference/roblox/04-claim-mapper.md 에러 표(Quad0031·Quad0034)와 "위 표의 `Claim: …` 에러는 **아무것도 claim하기 전에**",
-- `q.newMapperClass(className)`(Quad0026 — docs/reference/errors/06-module-backend.md), docs/reference/errors/02-dispatch-bookkeeping.md
-- Quad0076(문자 키의 quad 값 꼬리). 변이: E73 CL07(`i % 1 ~= 0` 제거 → 루트 claim 뒤 drive에서 Quad0085), CL15(디스크립터 게이트 삭제),
-- CL16(`or className == ""` 제거), CL06(`type(i) == "number" and ` 제거 → `attempt to compare string < number`).
do
	local root = makeTemplate()
	local ok, err = pcall(function()
		q.Claim(root, M.Frame(M.Root)({ [1.5] = M.TextLabel("Title")({}) }))
	end)
	assert(not ok and string.find(tostring(err), "Quad0031", 1, true) ~= nil, "fractional array key: " .. tostring(err))
	assert(q.Backend.isClaimed(root) == false, "pass-1 failure leaves the root unclaimed")

	local ok2, err2 = pcall(function()
		q.Claim(makeTemplate(), { _props = {} } :: any)
	end)
	assert(not ok2 and string.find(tostring(err2), "Quad0034", 1, true) ~= nil, "plain table as descriptor: " .. tostring(err2))

	local ok3, err3 = pcall(function()
		return q.newMapperClass("")
	end)
	assert(not ok3 and string.find(tostring(err3), "Quad0026", 1, true) ~= nil, "empty className: " .. tostring(err3))

	local ok4, err4 = pcall(function()
		q.Claim(makeTemplate(), M.Frame(M.Root)({ Foo = M.TextLabel("Title")({}) }))
	end)
	assert(not ok4 and string.find(tostring(err4), "Quad0076", 1, true) ~= nil, "descriptor under a string key: " .. tostring(err4))
	print("PASS")
end

print()
print("=== 18. drive는 안쪽부터 바깥으로 — 매핑 자식의 OnRendered가 루트 것보다 먼저 분다 ===")
-- 계약: docs/reference/roblox/04-claim-mapper.md 동작 3("**안쪽부터 바깥으로** props를 처리"), 같은 문서 "루트부터 claim하고 아래에서
-- 위로 적용"; .claude/base/claim-plan.md §4. 변이: E73 CL17(plan 삽입을 앞쪽으로 → top-down drive).
do
	local root = makeTemplate()
	local order = {}
	q.Claim(root, M.Frame(M.Root)({
		q.OnRendered(function()
			table.insert(order, "root")
		end),
		M.TextLabel("Title")({
			q.OnRendered(function()
				table.insert(order, "child")
			end),
		}),
	}))
	assert(order[1] == "child" and order[2] == "root", "bottom-up drive order: " .. table.concat(order, ","))
	print("PASS")
end
