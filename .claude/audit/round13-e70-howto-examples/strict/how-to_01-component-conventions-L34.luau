--!strict
-- E70 strict (generated) — how-to_01-component-conventions-L34
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
-- ==== doc block how-to/01-component-conventions.md:34 ====
local isHovered = q.Source(false)
local CommonButtonModifier = D.Modifier.Frame {
    BorderSizePixel = 0,
}

D.Frame {
    -- [1] 문자 키: 프로퍼티 바인딩 (정적 값 또는 반응형 State/Tween)
    Size = UDim2.new(0, 200, 0, 50),
    BackgroundColor3 = isHovered:Compute(function(h)  -- 편집기 타입 검사까지 보려면 지역 변수로 빼세요(02 §4)
        return if h:Get() then Color3.fromRGB(80, 120, 240) else Color3.fromRGB(50, 50, 60)
    end),

    -- [2] 문자 키: 이벤트 리스너 (엔진이 주는 인자만 받는다 — self는 안 온다)
    MouseEnter = function() isHovered:Set(true) end,
    MouseLeave = function() isHovered:Set(false) end,

    -- [3] 숫자 키: 재사용 가능한 스타일 (Modifier)
    CommonButtonModifier,

    -- [4] 숫자 키: 자식 요소
    D.TextLabel {
        Text = "클릭하세요",
    },
}
