-- Templates.luau — 정적인 것만. 자식의 `Name`이 나중에 Claim이 찾을 열쇠다
local ItemTemplate = D.Frame {
    Name = "ItemCard",
    Size = UDim2.fromOffset(240, 64),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    BorderSizePixel = 0,
    UICorner = UDim.new(0, 8),

    D.TextLabel { Name = "ItemName", Text = "-", TextSize = 14 },
    D.TextButton { Name = "ActionButton", Text = "사용" },
}
