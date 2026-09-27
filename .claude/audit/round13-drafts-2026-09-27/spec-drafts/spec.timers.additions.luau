-- ── round13 Q154 (a) 초안 — E73 변이 공백. 대상 파일 끝의 `print("=== ALL PASS ===")`(또는 `ALL PASS`) 바로 앞에 넣는다.
-- 대상 파일의 지역 이름 `q`를 쓴다.

print()
print("=== 4. setTimeout — NaN delay도 Quad0216(음수와 같은 게이트) ===")
-- 계약: docs/reference/errors/07-roblox.md Quad0216("`delay`가 숫자가 아니거나, NaN이거나, 음수일 때").
-- 변이: E73 EO12(`or delay ~= delay` 제거).
do
	local ok, err = pcall(function()
		return q.Backend.setTimeout(function() end, 0 / 0)
	end)
	assert(not ok and string.find(tostring(err), "Quad0216", 1, true) ~= nil, "NaN delay: " .. tostring(err))
	print("PASS")
end
