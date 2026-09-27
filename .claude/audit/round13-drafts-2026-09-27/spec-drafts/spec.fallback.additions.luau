-- ── round13 Q154 (a) 초안 — E73 변이 공백. 대상 파일 끝의 `print("=== ALL PASS ===")` 바로 앞에 넣는다.
-- 대상 파일의 지역 이름 `Traceback`을 쓴다.

print()
print("=== 5. Traceback의 trace는 던진 자리에서 시작한다 — 첫 줄이 Fallback.luau(에러 핸들러 자신)가 아니다 ===")
-- 계약: docs/reference/sugar/05-fallback-traceback.md `q.Traceback`("`xpcall` 핸들러 안에서, 즉 **던진 자리에서** 트레이스백을 뜹니다").
-- 변이: E73 FB05(`debug.traceback(nil, 2)` → `1`).
do
	local tr: string? = nil
	Traceback(function(): any
		error("boom")
	end, function(_e: any, t: string): any
		tr = t
		return nil
	end)()
	assert(type(tr) == "string", "trace delivered")
	local first = string.match(tr :: string, "^[^\n]*") or ""
	assert(string.find(first, "Fallback", 1, true) == nil, "trace's first frame is the throw site, not the handler: " .. first)
	print("PASS")
end
