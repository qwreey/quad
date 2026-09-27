-- ✅ 숫자 키 자리에 그대로
local function CustomInput(props: { InputRef: q.Ref<TextBox?>? })
    return D.TextBox {
        props.InputRef or q.None,
        PlaceholderText = "...",
    }
end
