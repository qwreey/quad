type ButtonProps = {
    read Text: string | QuadTypes.StateMarker<string>,
    read OnClick: () -> (),
    read Modifier: RobloxModule.TextButtonModifier?,
    read Ref: q.Ref<TextButton?>?,
}

local function CustomButton(props: ButtonProps): TextButton
    -- [1] TextButton 전용으로 태그된 기본 스타일
    local baseStyle = D.Modifier.TextButton {
        Size = UDim2.fromOffset(140, 40),
        BackgroundColor3 = Color3.fromRGB(0, 140, 240),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
    }

    return D.TextButton {
        -- [2] 불변식 2 — 뒤에 온 props.Modifier가 baseStyle을 필드 단위로 덮는다
        baseStyle,
        props.Modifier or None,
        props.Ref or None,

        -- [3] 불변식 1 — 문자 키는 어떤 Modifier도 덮지 못한다
        Text = props.Text,
        MouseButton1Click = props.OnClick,   -- 마우스 좌클릭만 받는 엔진 이벤트 — 게임패드·터치까지 받으려면 시작하기의 Activated
        UICorner = 8,
    }
end
