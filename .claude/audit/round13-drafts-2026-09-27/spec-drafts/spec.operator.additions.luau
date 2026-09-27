-- ── round13 Q154 (a) 초안 — E69 변이 공백. 대상 파일 끝의 `print("=== ALL PASS ===")` 바로 앞에 넣는다.
-- 대상 파일의 지역 이름 `Source`, `Operator`를 쓴다.

print()
print("=== 8. 경계값 — Clamp(lo, lo)는 허용(lo > hi만 에러), Shr는 논리 시프트(bit32.rshift — 최상위 비트가 부호로 번지지 않음) ===")
-- 계약: docs/reference/sugar/02-operator.md `q.Operator.Clamp(lo, hi)`("읽는 시점에 `lo > hi`이면 … Quad0124"),
-- 연산자 표 `Shr` = `bit32.rshift`. 변이: E69 OP03(`>` → `>=`), OP05(`rshift` → `arshift`).
do
	local s = Source(5)
	local ok, v = pcall(function()
		return s:Apply(Operator.Clamp(3, 3)):Get()
	end)
	assert(ok and v == 3, "Clamp(3, 3) clamps to 3: " .. tostring(v))
	local h = Source(0x80000000)
	local shifted = h:Apply(Operator.Shr(4)):Get()
	assert(shifted == 0x08000000, "logical right shift of a high-bit value: " .. tostring(shifted))
	print("PASS")
end
