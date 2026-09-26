local card = q.Modifier {
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
}
local wide = q.Modifier(card, { Size = UDim2.fromScale(1, 0.4) }) -- card를 깔고 Size를 얹는다
local panel = D.Frame { wide }
