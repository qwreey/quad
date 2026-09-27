-- ── round13 Q154 (a) 초안 — E69 변이 공백. 대상 파일 끝의 `print("=== ALL PASS ===")` 바로 앞에 넣는다.
-- 대상 파일의 지역 이름 `Source`, `Debounce`를 쓴다.

print()
print("=== 14. Time에 준 State가 신호 시점에 음수면 그 :Set 줄에서 Quad0039(백엔드 타이머에 음수가 닿기 전) ===")
-- 계약: docs/reference/errors/01-core-reactive.md Quad0039("`Time`(또는 `MaxTime`)에 바인딩한 `State`가 … 음수/NaN일 때.
-- … **신호가 들어오는 시점**에 읽어 검사"), docs/reference/sugar/03-debounce-throttle.md. 변이: E69 DB01(`v < 0` → `v < -1` —
-- mock 타이머의 자체 검사로 죽었고, 실제 엔진 `task.delay`는 음수를 조용히 받는다).
do
	local T = Source(-0.5)
	local src = Source(0)
	local g = src:Apply(Debounce({ Time = T }))
	local o = g:Observer(function() end):Subscribe()
	local ok, err = pcall(function()
		src:Set(1)
	end)
	assert(not ok and string.find(tostring(err), "Quad0039", 1, true) ~= nil, "negative State Time: " .. tostring(err))
	o:Unsubscribe()
	print("PASS")
end
