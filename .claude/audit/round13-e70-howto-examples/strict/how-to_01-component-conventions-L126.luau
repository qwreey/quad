--!strict
-- E70 strict (generated) — how-to_01-component-conventions-L126
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (how-to_01-component-conventions-L14) ====
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("./Quad")
local D = q.Declaration
local None = q.None

-- 값이 아니라 '타입 이름'을 가져오는 모듈
local QuadTypes = require("../../../../quad-roblox/luau_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.StateMarker<T>` 등)
-- 클래스별 Modifier·요소 타입(`TextButtonModifier`/`IntoTextButton`/`FrameElem` 등)은 quad_roblox 패키지 루트가 내보낸다
local RobloxModule = require("../../../../quad-roblox/src")
-- ==== doc block how-to/01-component-conventions.md:126 ====
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
