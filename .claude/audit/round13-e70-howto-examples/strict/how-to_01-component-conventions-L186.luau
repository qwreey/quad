--!strict
-- E70 strict (generated) — how-to_01-component-conventions-L186
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
-- ==== doc block how-to/01-component-conventions.md:186 ====
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
