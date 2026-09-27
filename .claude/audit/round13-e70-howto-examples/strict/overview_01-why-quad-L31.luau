--!strict
-- E70 strict (generated) — overview_01-why-quad-L31
local H: any = nil -- [E70] mock 보강 식이 strict에서 any로 읽히게
-- ==== page prologue (DEFAULT) ====
-- [E70 기본 프롤로그 — GS 01 설정 모듈 관용구]
local q = require("./Quad")
local D = q.Declaration
-- ==== doc block overview/01-why-quad.md:31 ====
local isHovered = q.Source(false)
local CommonButtonModifier = D.Modifier.Frame { BorderSizePixel = 0 }

D.Frame {
    Size = UDim2.new(0, 200, 0, 50),                  -- 문자 키: 프로퍼티
    BackgroundColor3 = isHovered:Compute(function(h)  -- 문자 키: 반응형 바인딩(편집기 타입 검사까지 보려면 지역 변수로 빼세요 — how-to 02 §4)
        return if h:Get() then Color3.fromRGB(80, 120, 240) else Color3.fromRGB(50, 50, 60)
    end),
    MouseEnter = function() isHovered:Set(true) end,  -- 문자 키: 이벤트(self는 안 온다)
    CommonButtonModifier,                             -- 숫자 키: 재사용 스타일
    D.TextLabel { Text = "클릭하세요" },                -- 숫자 키: 자식
}
