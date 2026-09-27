-- 기본 스타일 그대로
local btn1 = CustomButton { Text = "확인", OnClick = function() print("기본 버튼") end }

-- 크기와 색상만 위험 버튼으로 커스텀
local btn2 = CustomButton {
    Text = "삭제",
    OnClick = function() print("삭제 버튼") end,
    Modifier = D.Modifier.TextButton {
        BackgroundColor3 = Color3.fromRGB(240, 60, 60),
        Size = UDim2.fromOffset(100, 36),
    },
}
