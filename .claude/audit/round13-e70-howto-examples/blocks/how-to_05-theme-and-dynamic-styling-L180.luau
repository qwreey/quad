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
