--!strict
local L = require("../../../../src/Lib")
type ClassMap = { Frame: Frame, GuiObject: GuiObject, ImageLabel: ImageLabel, ScrollingFrame: ScrollingFrame, TextButton: TextButton, TextLabel: TextLabel, UICorner: UICorner, UIListLayout: UIListLayout, UIPadding: UIPadding }
local Elem = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> index<ClassMap, K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (...any) -> L.Modifier<index<ClassMap, K>>
local Frame = Elem "Frame"
local TextLabel = Elem "TextLabel"
local TextButton = Elem "TextButton"
local ImageLabel = Elem "ImageLabel"
local UICorner = Elem "UICorner"
local UIListLayout = Elem "UIListLayout"
local UIPadding = Elem "UIPadding"
local ScrollingFrame = Elem "ScrollingFrame"
local GuiObjectModifier = Modifier "GuiObject"
local FrameModifier = Modifier "Frame"
local TextButtonModifier = Modifier "TextButton"
local TextLabelModifier = Modifier "TextLabel"
local m0 = GuiObjectModifier():BackgroundTransparency(0.1)
local e0 = Frame { m0, Size = UDim2.new(), TextLabel { Text = "t0" }, UICorner { CornerRadius = UDim.new(0, 0) } }
local m1 = GuiObjectModifier():BackgroundTransparency(0.2)
local e1 = Frame { m1, Size = UDim2.new(), TextLabel { Text = "t1" }, UICorner { CornerRadius = UDim.new(0, 1) } }
local m2 = GuiObjectModifier():BackgroundTransparency(0.3)
local e2 = Frame { m2, Size = UDim2.new(), TextLabel { Text = "t2" }, UICorner { CornerRadius = UDim.new(0, 2) } }
local m3 = GuiObjectModifier():BackgroundTransparency(0.4)
local e3 = Frame { m3, Size = UDim2.new(), TextLabel { Text = "t3" }, UICorner { CornerRadius = UDim.new(0, 3) } }
local m4 = GuiObjectModifier():BackgroundTransparency(0.5)
local e4 = Frame { m4, Size = UDim2.new(), TextLabel { Text = "t4" }, UICorner { CornerRadius = UDim.new(0, 4) } }
local m5 = GuiObjectModifier():BackgroundTransparency(0.6)
local e5 = Frame { m5, Size = UDim2.new(), TextLabel { Text = "t5" }, UICorner { CornerRadius = UDim.new(0, 5) } }
local m6 = GuiObjectModifier():BackgroundTransparency(0.7)
local e6 = Frame { m6, Size = UDim2.new(), TextLabel { Text = "t6" }, UICorner { CornerRadius = UDim.new(0, 6) } }
local m7 = GuiObjectModifier():BackgroundTransparency(0.8)
local e7 = Frame { m7, Size = UDim2.new(), TextLabel { Text = "t7" }, UICorner { CornerRadius = UDim.new(0, 7) } }
local m8 = GuiObjectModifier():BackgroundTransparency(0.9)
local e8 = Frame { m8, Size = UDim2.new(), TextLabel { Text = "t8" }, UICorner { CornerRadius = UDim.new(0, 8) } }
local m9 = GuiObjectModifier():BackgroundTransparency(0.1)
local e9 = Frame { m9, Size = UDim2.new(), TextLabel { Text = "t9" }, UICorner { CornerRadius = UDim.new(0, 9) } }
local m10 = GuiObjectModifier():BackgroundTransparency(0.2)
local e10 = Frame { m10, Size = UDim2.new(), TextLabel { Text = "t10" }, UICorner { CornerRadius = UDim.new(0, 10) } }
local m11 = GuiObjectModifier():BackgroundTransparency(0.3)
local e11 = Frame { m11, Size = UDim2.new(), TextLabel { Text = "t11" }, UICorner { CornerRadius = UDim.new(0, 11) } }
local m12 = GuiObjectModifier():BackgroundTransparency(0.4)
local e12 = Frame { m12, Size = UDim2.new(), TextLabel { Text = "t12" }, UICorner { CornerRadius = UDim.new(0, 12) } }
local m13 = GuiObjectModifier():BackgroundTransparency(0.5)
local e13 = Frame { m13, Size = UDim2.new(), TextLabel { Text = "t13" }, UICorner { CornerRadius = UDim.new(0, 13) } }
local m14 = GuiObjectModifier():BackgroundTransparency(0.6)
local e14 = Frame { m14, Size = UDim2.new(), TextLabel { Text = "t14" }, UICorner { CornerRadius = UDim.new(0, 14) } }
local m15 = GuiObjectModifier():BackgroundTransparency(0.7)
local e15 = Frame { m15, Size = UDim2.new(), TextLabel { Text = "t15" }, UICorner { CornerRadius = UDim.new(0, 15) } }
local m16 = GuiObjectModifier():BackgroundTransparency(0.8)
local e16 = Frame { m16, Size = UDim2.new(), TextLabel { Text = "t16" }, UICorner { CornerRadius = UDim.new(0, 16) } }
local m17 = GuiObjectModifier():BackgroundTransparency(0.9)
local e17 = Frame { m17, Size = UDim2.new(), TextLabel { Text = "t17" }, UICorner { CornerRadius = UDim.new(0, 17) } }
local m18 = GuiObjectModifier():BackgroundTransparency(0.1)
local e18 = Frame { m18, Size = UDim2.new(), TextLabel { Text = "t18" }, UICorner { CornerRadius = UDim.new(0, 18) } }
local m19 = GuiObjectModifier():BackgroundTransparency(0.2)
local e19 = Frame { m19, Size = UDim2.new(), TextLabel { Text = "t19" }, UICorner { CornerRadius = UDim.new(0, 19) } }
local BAD = TextLabel { Text = 42 }
return { e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16, e17, e18, e19, BAD }
