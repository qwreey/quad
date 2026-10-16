--!strict
local Ui = require("./Ui")
local m0 = Ui.GuiObjectModifier():BackgroundTransparency(0.1)
local e0 = Ui.Frame { m0, Size = UDim2.new(), Ui.TextLabel { Text = "t0" }, Ui.UICorner { CornerRadius = UDim.new(0, 0) } }
local m1 = Ui.GuiObjectModifier():BackgroundTransparency(0.2)
local e1 = Ui.Frame { m1, Size = UDim2.new(), Ui.TextLabel { Text = "t1" }, Ui.UICorner { CornerRadius = UDim.new(0, 1) } }
local m2 = Ui.GuiObjectModifier():BackgroundTransparency(0.3)
local e2 = Ui.Frame { m2, Size = UDim2.new(), Ui.TextLabel { Text = "t2" }, Ui.UICorner { CornerRadius = UDim.new(0, 2) } }
local m3 = Ui.GuiObjectModifier():BackgroundTransparency(0.4)
local e3 = Ui.Frame { m3, Size = UDim2.new(), Ui.TextLabel { Text = "t3" }, Ui.UICorner { CornerRadius = UDim.new(0, 3) } }
local m4 = Ui.GuiObjectModifier():BackgroundTransparency(0.5)
local e4 = Ui.Frame { m4, Size = UDim2.new(), Ui.TextLabel { Text = "t4" }, Ui.UICorner { CornerRadius = UDim.new(0, 4) } }
local m5 = Ui.GuiObjectModifier():BackgroundTransparency(0.6)
local e5 = Ui.Frame { m5, Size = UDim2.new(), Ui.TextLabel { Text = "t5" }, Ui.UICorner { CornerRadius = UDim.new(0, 5) } }
local m6 = Ui.GuiObjectModifier():BackgroundTransparency(0.7)
local e6 = Ui.Frame { m6, Size = UDim2.new(), Ui.TextLabel { Text = "t6" }, Ui.UICorner { CornerRadius = UDim.new(0, 6) } }
local m7 = Ui.GuiObjectModifier():BackgroundTransparency(0.8)
local e7 = Ui.Frame { m7, Size = UDim2.new(), Ui.TextLabel { Text = "t7" }, Ui.UICorner { CornerRadius = UDim.new(0, 7) } }
local m8 = Ui.GuiObjectModifier():BackgroundTransparency(0.9)
local e8 = Ui.Frame { m8, Size = UDim2.new(), Ui.TextLabel { Text = "t8" }, Ui.UICorner { CornerRadius = UDim.new(0, 8) } }
local m9 = Ui.GuiObjectModifier():BackgroundTransparency(0.1)
local e9 = Ui.Frame { m9, Size = UDim2.new(), Ui.TextLabel { Text = "t9" }, Ui.UICorner { CornerRadius = UDim.new(0, 9) } }
local m10 = Ui.GuiObjectModifier():BackgroundTransparency(0.2)
local e10 = Ui.Frame { m10, Size = UDim2.new(), Ui.TextLabel { Text = "t10" }, Ui.UICorner { CornerRadius = UDim.new(0, 10) } }
local m11 = Ui.GuiObjectModifier():BackgroundTransparency(0.3)
local e11 = Ui.Frame { m11, Size = UDim2.new(), Ui.TextLabel { Text = "t11" }, Ui.UICorner { CornerRadius = UDim.new(0, 11) } }
local m12 = Ui.GuiObjectModifier():BackgroundTransparency(0.4)
local e12 = Ui.Frame { m12, Size = UDim2.new(), Ui.TextLabel { Text = "t12" }, Ui.UICorner { CornerRadius = UDim.new(0, 12) } }
local m13 = Ui.GuiObjectModifier():BackgroundTransparency(0.5)
local e13 = Ui.Frame { m13, Size = UDim2.new(), Ui.TextLabel { Text = "t13" }, Ui.UICorner { CornerRadius = UDim.new(0, 13) } }
local m14 = Ui.GuiObjectModifier():BackgroundTransparency(0.6)
local e14 = Ui.Frame { m14, Size = UDim2.new(), Ui.TextLabel { Text = "t14" }, Ui.UICorner { CornerRadius = UDim.new(0, 14) } }
local m15 = Ui.GuiObjectModifier():BackgroundTransparency(0.7)
local e15 = Ui.Frame { m15, Size = UDim2.new(), Ui.TextLabel { Text = "t15" }, Ui.UICorner { CornerRadius = UDim.new(0, 15) } }
local m16 = Ui.GuiObjectModifier():BackgroundTransparency(0.8)
local e16 = Ui.Frame { m16, Size = UDim2.new(), Ui.TextLabel { Text = "t16" }, Ui.UICorner { CornerRadius = UDim.new(0, 16) } }
local m17 = Ui.GuiObjectModifier():BackgroundTransparency(0.9)
local e17 = Ui.Frame { m17, Size = UDim2.new(), Ui.TextLabel { Text = "t17" }, Ui.UICorner { CornerRadius = UDim.new(0, 17) } }
local m18 = Ui.GuiObjectModifier():BackgroundTransparency(0.1)
local e18 = Ui.Frame { m18, Size = UDim2.new(), Ui.TextLabel { Text = "t18" }, Ui.UICorner { CornerRadius = UDim.new(0, 18) } }
local m19 = Ui.GuiObjectModifier():BackgroundTransparency(0.2)
local e19 = Ui.Frame { m19, Size = UDim2.new(), Ui.TextLabel { Text = "t19" }, Ui.UICorner { CornerRadius = UDim.new(0, 19) } }
local BAD = Ui.TextLabel { Text = 42 }
return { e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16, e17, e18, e19, BAD }
