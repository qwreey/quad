-- Theme.luau
export type ColorPalette = {
    Background: Color3,
    Surface: Color3,
    TextPrimary: Color3,
    TextMuted: Color3,
    Accent: Color3,
    Border: Color3,
}

local LIGHT: ColorPalette = {
    Background = Color3.fromRGB(248, 249, 250),
    Surface = Color3.fromRGB(255, 255, 255),
    TextPrimary = Color3.fromRGB(33, 37, 41),
    TextMuted = Color3.fromRGB(108, 117, 125),
    Accent = Color3.fromRGB(13, 110, 253),
    Border = Color3.fromRGB(222, 226, 230),
}

local DARK: ColorPalette = {
    Background = Color3.fromRGB(18, 18, 18),
    Surface = Color3.fromRGB(30, 30, 30),
    TextPrimary = Color3.fromRGB(240, 240, 240),
    TextMuted = Color3.fromRGB(160, 160, 160),
    Accent = Color3.fromRGB(66, 153, 225),
    Border = Color3.fromRGB(45, 45, 45),
}

local isDark = q.Source(true)

-- 지금 쓸 팔레트를 고르는 것은 한 번이면 된다
local palette = isDark:Compute(function(dark)
    return if dark:Get() then DARK else LIGHT
end)

-- 토큰 하나 = "팔레트에서 키 하나를 읽는 State"에 애니메이션을 얹은 것
local function token(key: string)
    return palette
        :Apply(q.Operator.Indexed<<Color3>>(key))
        :Apply(q.Animate({
            Time = 0.25,
            Style = Enum.EasingStyle.Quad,
            Direction = Enum.EasingDirection.Out,
        }))
end

return {
    IsDark = isDark,
    Toggle = function()
        isDark:Set(not isDark:Get())
    end,
    Tokens = {
        Background = token("Background"),
        Surface = token("Surface"),
        TextPrimary = token("TextPrimary"),
        TextMuted = token("TextMuted"),
        Accent = token("Accent"),
        Border = token("Border"),
    },
}
