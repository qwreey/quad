--!strict
-- E70 strict (generated) — how-to_05-theme-and-dynamic-styling-L166
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_05-theme-and-dynamic-styling-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- 클래스별 Modifier 타입(`FrameModifier`/`IntoTextButton` 등)은 quad_roblox 패키지 루트가 내보낸다
local RobloxModule = require("../../../../quad-roblox/src")
-- ==== doc block how-to/05-theme-and-dynamic-styling.md:166 ====
-- Styles.luau
local Theme = require("./Theme")

return {
    Button = D.Modifier.TextButton()
        :Size(UDim2.new(0, 120, 0, 40))
        :BackgroundColor3(Theme.Tokens.Accent)
        :BorderSizePixel(0),
}
