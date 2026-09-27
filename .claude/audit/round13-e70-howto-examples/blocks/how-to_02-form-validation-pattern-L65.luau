-- 부르는 쪽 — 원천을 만들고, 그 위에 판정을 얹는다
local agreed = q.Source(false)

-- 약관에 동의해야만 제출할 수 있다(지금은 동의 여부 그대로지만, 폼이 커지면 조건이 여기에 늘어난다)
local canSubmit: q.State<boolean> = agreed:Compute(function(c)
    return c:Get()
end)

local submitColor: q.State<Color3> = canSubmit:Compute(function(enabled)
    return if enabled:Get()
        then Color3.fromRGB(0, 170, 255)
        else Color3.fromRGB(80, 80, 90)
end)

local panel = D.Frame {
    D.UIListLayout { Padding = UDim.new(0, 8) },

    Checkbox { Label = "약관에 동의합니다", Value = agreed },

    D.TextButton {
        Text = "가입하기",
        Interactable = canSubmit, -- false면 눌리지 않는다
        BackgroundColor3 = submitColor,
    },
}
