-- ── round13 Q154 (a) 초안 — E69 변이 공백. 대상 파일 끝의 `print("=== ALL PASS ===")` 바로 앞에 넣는다.

print()
print("=== 8. 이름 리스트가 64단계보다 깊게 중첩되면 Quad0201 ===")
-- 계약: docs/reference/errors/05-tag-attr.md Quad0201("이름 리스트가 64단계보다 깊게 중첩됐을 때").
-- 변이: E69 TG08(깊이 한도 64 → 640).
do
	local q = newQuad()
	local t: any = "x"
	for _ = 1, 70 do
		t = { t }
	end
	local ok, err = pcall(function()
		q.Tag(t)
	end)
	assert(not ok and string.find(tostring(err), "Quad0201", 1, true) ~= nil, "depth gate: " .. tostring(err))
	print("PASS")
end
