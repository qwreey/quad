--!strict
-- E15 (e) — how-to 05 §2~§4 (Theme/Styles/ThemedButton/SettingsCard) in one file + §1 Context bag.
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration
local RobloxModule = require("../../quad-roblox/src")

export type ColorPalette = { Background: Color3, Surface: Color3, TextPrimary: Color3, TextMuted: Color3, Accent: Color3, Border: Color3 }
local LIGHT: ColorPalette = { Background = Color3.fromRGB(248, 249, 250), Surface = Color3.fromRGB(255, 255, 255), TextPrimary = Color3.fromRGB(33, 37, 41), TextMuted = Color3.fromRGB(108, 117, 125), Accent = Color3.fromRGB(13, 110, 253), Border = Color3.fromRGB(222, 226, 230) }
local DARK: ColorPalette = { Background = Color3.fromRGB(18, 18, 18), Surface = Color3.fromRGB(30, 30, 30), TextPrimary = Color3.fromRGB(240, 240, 240), TextMuted = Color3.fromRGB(160, 160, 160), Accent = Color3.fromRGB(66, 153, 225), Border = Color3.fromRGB(45, 45, 45) }
local isDark = q.Source(true)
local palette = isDark:Compute(function(dark)
    return if dark:Get() then DARK else LIGHT
end)
local function token(key: string)
    return palette
        :Apply(q.Operator.Indexed<<Color3>>(key))
        :Apply(q.Animate({ Time = 0.25, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out }))
end
local Theme = {
    IsDark = isDark,
    Toggle = function() isDark:Set(not isDark:Get()) end,
    Tokens = { Background = token("Background"), Surface = token("Surface"), TextPrimary = token("TextPrimary"), TextMuted = token("TextMuted"), Accent = token("Accent"), Border = token("Border") },
}
local ThemeProvider = q.Context.Provider<<typeof(Theme)>>("Theme")
local ctx = q.Context():Set(ThemeProvider, Theme)

local Styles = {
    Button = D.Modifier.TextButton()
        :Size(UDim2.new(0, 120, 0, 40))
        :BackgroundColor3(Theme.Tokens.Accent)
        :BorderSizePixel(0),
}
local function ThemedButton(props: { read Text: string?, read OnClick: () -> (), read Modifier: RobloxModule.IntoTextButton? })
    local effective = if props.Modifier then q.Modifier.Overridden(Styles.Button, props.Modifier:AsTextButton()) else Styles.Button
    return D.TextButton {
        effective,
        Text = props.Text or "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextSize = 14,
        Activated = function() props.OnClick() end,
    }
end
local function SettingsCard(props: { read Ctx: q.Context })
    local theme = props.Ctx:Get(ThemeProvider)
    return D.Frame {
        Size = UDim2.new(0, 360, 0, 240),
        BackgroundColor3 = theme.Tokens.Surface,
        UICorner = UDim.new(0, 12),
        D.TextLabel { TextColor3 = theme.Tokens.TextPrimary, Text = "화면 설정" },
        ThemedButton { Text = "테마 전환", OnClick = theme.Toggle, Modifier = D.Modifier.TextButton():Position(UDim2.new(0, 20, 1, -60)):Size(UDim2.new(0, 140, 0, 38)) },
    }
end
local blocker = q.Blocker()
local gatedDark: q.State<boolean> = isDark:Apply(blocker)
local card = SettingsCard { Ctx = ctx }
local _o = D.Frame { card, gatedDark:Observer(function(t) print(t:Get()) end) }
