local function Modal(props: {
    read Open: q.Source<boolean>,
    read Title: string,
    read OnConfirm: () -> (),
    read OnCancel: () -> (),
    read Children: q.Slot<Instance>?,
}): Frame
    return D.Frame {
        Size = UDim2.fromOffset(360, 220),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),

        Visible = props.Open,

        D.TextLabel {
            Text = props.Title,
            Size = UDim2.new(1, 0, 0, 40),
        },

        props.Children or None, -- ⭐ 숫자 키 자리, or None으로 nil-hole 방지(실전 레시피 01)

        D.TextButton {
            Text = "확인",
            Position = UDim2.new(0, 20, 1, -48),
            Size = UDim2.fromOffset(140, 36),
            Activated = function()
                props.Open:Set(false)
                props.OnConfirm()
            end,
        },
        D.TextButton {
            Text = "취소",
            Position = UDim2.new(1, -160, 1, -48),
            Size = UDim2.fromOffset(140, 36),
            Activated = function()
                props.Open:Set(false)
                props.OnCancel()
            end,
        },
    }
end
