local function ModalDialog(props: { read Title: string, read Children: q.Slot<Instance>? }): Frame
    return D.Frame {
        Size = UDim2.fromOffset(400, 300),
        BackgroundColor3 = Color3.fromRGB(25, 25, 30),

        -- 헤더 타이틀
        D.TextLabel {
            Text = props.Title,
            Size = UDim2.new(1, 0, 0, 40),
        },

        -- 전달받은 Slot을 컨텐츠 영역의 한 자리로 놓는다
        D.Frame {
            Position = UDim2.fromOffset(0, 40),
            Size = UDim2.new(1, 0, 1, -40),
            BackgroundTransparency = 1,

            props.Children or None,
        },
    }
end
