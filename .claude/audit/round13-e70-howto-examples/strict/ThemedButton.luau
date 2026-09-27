--!strict
-- E70 strict (generated) — how-to_05-theme-and-dynamic-styling-L180
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_05-theme-and-dynamic-styling-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- 클래스별 Modifier 타입(`FrameModifier`/`IntoTextButton` 등)은 quad_roblox 패키지 루트가 내보낸다
local RobloxModule = require("../../../../quad-roblox/src")
-- ==== doc block how-to/05-theme-and-dynamic-styling.md:180 ====
-- ThemedButton.luau
local Styles = require("./Styles")

local function ThemedButton(props: {
    read Text: string?,
    read OnClick: () -> (),
    read Modifier: RobloxModule.IntoTextButton?,
})
    -- 호출자 오버라이드가 있으면 기본 스타일 위에 얹는다(뒤가 이긴다)
    local effective = if props.Modifier
        then q.Modifier.Overridden(Styles.Button, props.Modifier:AsTextButton())
        else Styles.Button

    return D.TextButton {
        effective,
        Text = props.Text or "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = 14,
        Activated = function()
            props.OnClick()
        end,
    }
end

return ThemedButton
