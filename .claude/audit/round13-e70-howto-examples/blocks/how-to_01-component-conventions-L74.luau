local function MaterialButton(props: { read Text: string?, read Modifier: RobloxModule.TextButtonModifier?, read Ref: q.Ref<TextButton?>? }): TextButton
    return D.TextButton {
        props.Modifier or None, -- ⭐ 숫자 키 자리에서만 의미가 있는 관용구
        props.Ref or None,

        Text = props.Text or "",
    }
end
