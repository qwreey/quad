-- ── round13 Q154 (a) 초안 — E73 변이 공백. 대상 파일 끝의 `print("=== ALL PASS ===")` 바로 앞에 넣는다.
-- 대상 파일의 지역 이름 `q`(any)를 쓴다.

print()
print("=== 6. 생성 DefineSubtype 간선 — GuiObject Modifier에서 직계 하위 클래스로의 검사형 캐스트가 전부 통한다 ===")
-- 계약: docs/reference/roblox/03-d-modifier.md 캐스트 예(`D.Modifier.GuiObject():AsTextLabel()`·`:AsFrame()`) — 조상 방향 검사형
-- `:As<Class>()`는 생성 간선(`Modifier.DefineSubtype`)으로 성립한다. 변이: E73 DC02(`DefineSubtype("GuiObject", "ScrollingFrame")` 삭제 →
-- Quad0056). ⚠️ 생성 간선 전체(43개)의 대조는 생성기 `check` 층이 맞는 자리일 수 있다 — 여기선 GuiObject의 직계 여덟만 본다.
do
	local D = q.Declaration
	for _, sub in { "CanvasGroup", "Frame", "GuiButton", "GuiLabel", "ScrollingFrame", "TextBox", "VideoFrame", "ViewportFrame" } do
		local ok, err = pcall(function()
			local base = D.Modifier.GuiObject()
			return base["As" .. sub](base)
		end)
		assert(ok, "GuiObject():As" .. sub .. "() must be a checked cast along a generated edge: " .. tostring(err))
	end
	print("PASS")
end
