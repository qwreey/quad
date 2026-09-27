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
