-- 빌더 체인
local base = D.Modifier.GuiObject()
	:Size(UDim2.fromOffset(160, 40))
	:BackgroundColor3(Color3.fromRGB(60, 130, 255))
	:Visible(true)

-- 테이블 형태(+ 병합 — 뒤 인자가 이긴다)
local boxed = D.Modifier.Frame({ BackgroundTransparency = 0.5 }, { Visible = false })

-- 숫자 키 자리에 놓으면 그 자리에서 필드가 펼쳐진다
local card = D.Frame({ boxed, D.Modifier.Frame():ZIndex(2) })
