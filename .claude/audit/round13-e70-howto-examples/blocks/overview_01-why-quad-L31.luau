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
