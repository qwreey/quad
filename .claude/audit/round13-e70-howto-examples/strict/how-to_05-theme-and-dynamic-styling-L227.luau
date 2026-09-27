--!strict
-- E70 strict (generated) — how-to_05-theme-and-dynamic-styling-L227
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_05-theme-and-dynamic-styling-L11) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
-- 클래스별 Modifier 타입(`FrameModifier`/`IntoTextButton` 등)은 quad_roblox 패키지 루트가 내보낸다
local RobloxModule = require("../../../../quad-roblox/src")
-- ==== doc block how-to/05-theme-and-dynamic-styling.md:227 ====
-- SettingsCard.luau
local Theme = require("./Theme")
local ThemedButton = require("./ThemedButton")

local function SettingsCard()
    return D.Frame {
        Size = UDim2.new(0, 360, 0, 240),
        Position = UDim2.new(0.5, -180, 0.5, -120),
        BackgroundColor3 = Theme.Tokens.Surface,
        BorderSizePixel = 0,

        UICorner = UDim.new(0, 12), -- 숏핸드: 관리 자식 UICorner를 만들어 붙인다

        D.TextLabel {
            Size = UDim2.new(1, -40, 0, 30),
            Position = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            FontFace = Font.fromEnum(Enum.Font.GothamBold),
            TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.Tokens.TextPrimary,
            Text = "화면 설정",
        },

        D.TextLabel {
            Size = UDim2.new(1, -40, 0, 20),
            Position = UDim2.new(0, 20, 0, 55),
            BackgroundTransparency = 1,
            FontFace = Font.fromEnum(Enum.Font.Gotham),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.Tokens.TextMuted,
            Text = "테마와 표시 옵션을 바꿉니다.",
        },

        ThemedButton {
            Text = "테마 전환",
            OnClick = Theme.Toggle,
            Modifier = D.Modifier.TextButton()
                :Position(UDim2.new(0, 20, 1, -60))
                :Size(UDim2.new(0, 140, 0, 38)),
        },
    }
end
