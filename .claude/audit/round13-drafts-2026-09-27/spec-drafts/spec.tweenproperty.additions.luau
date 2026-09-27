-- ── round13 Q154 (a) 초안 — E69/E73 변이 공백. 대상 파일 끝의 `print("=== ALL PASS ===")` 바로 앞에 넣는다.
-- 대상 파일의 지역 이름 `q`, `Tween`, `log`, `mock`를 쓴다.

print()
print("=== 12. Info 없는 Time = 0이라도 Reverses나 RepeatCount가 있으면 스냅이 아니라 평소대로 엔진 트윈 ===")
-- 계약: docs/reference/roblox/06-tween-animate.md 옵션 절("`Info` 없이 `Time = 0`이고 `DelayTime`/`RepeatCount`/`Reverses`도 없으면
-- … 스냅 … 그 셋 중 하나라도 있으면 평소대로 엔진 트윈"). 변이: E69 PR10(`Handlers/Property.luau`의 `and v.Reverses ~= true` 제거).
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = src }) :: any
	src:Set(Tween({ Value = 5, Time = 0, Reverses = true }))
	assert(#log == 1, "Time = 0 + Reverses creates an engine tween: " .. #log)
	assert(f.Size == 0, "no snap (the mock does not interpolate): " .. tostring(f.Size))
	mock.resetTweenLog()
	src:Set(Tween({ Value = 6, Time = 0, RepeatCount = 2 }))
	assert(#log == 1, "Time = 0 + RepeatCount creates an engine tween: " .. #log)
	print("PASS")
end
