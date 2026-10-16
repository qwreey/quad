--!strict
local L = require("../../../src/Lib")
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel }
local NewN = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> index<ClassMap, K>
type SM<K> = { read __quadSpread: K }
local SpreadC = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> SM<K>
local Frame = NewN "Frame"
local FrameS = SpreadC "Frame"
local TextLabel = NewN "TextLabel"
local TextLabelS = SpreadC "TextLabel"
local TextButton = NewN "TextButton"
local TextButtonS = SpreadC "TextButton"
local ImageLabel = NewN "ImageLabel"
local ImageLabelS = SpreadC "ImageLabel"
local UICorner = NewN "UICorner"
local UICornerS = SpreadC "UICorner"
local s0 = FrameS { Visible = true }
local e0 = Frame { s0, Visible = true }
local s1 = TextLabelS { Text = "a" }
local e1 = TextLabel { s1, Text = "a" }
local s2 = TextButtonS { AutoButtonColor = false }
local e2 = TextButton { s2, AutoButtonColor = false }
local s3 = ImageLabelS { Image = "" }
local e3 = ImageLabel { s3, Image = "" }
local s4 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e4 = UICorner { s4, CornerRadius = UDim.new(0, 4) }
local s5 = FrameS { Visible = true }
local e5 = Frame { s5, Visible = true }
local s6 = TextLabelS { Text = "a" }
local e6 = TextLabel { s6, Text = "a" }
local s7 = TextButtonS { AutoButtonColor = false }
local e7 = TextButton { s7, AutoButtonColor = false }
local s8 = ImageLabelS { Image = "" }
local e8 = ImageLabel { s8, Image = "" }
local s9 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e9 = UICorner { s9, CornerRadius = UDim.new(0, 4) }
local s10 = FrameS { Visible = true }
local e10 = Frame { s10, Visible = true }
local s11 = TextLabelS { Text = "a" }
local e11 = TextLabel { s11, Text = "a" }
local s12 = TextButtonS { AutoButtonColor = false }
local e12 = TextButton { s12, AutoButtonColor = false }
local s13 = ImageLabelS { Image = "" }
local e13 = ImageLabel { s13, Image = "" }
local s14 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e14 = UICorner { s14, CornerRadius = UDim.new(0, 4) }
local s15 = FrameS { Visible = true }
local e15 = Frame { s15, Visible = true }
local s16 = TextLabelS { Text = "a" }
local e16 = TextLabel { s16, Text = "a" }
local s17 = TextButtonS { AutoButtonColor = false }
local e17 = TextButton { s17, AutoButtonColor = false }
local s18 = ImageLabelS { Image = "" }
local e18 = ImageLabel { s18, Image = "" }
local s19 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e19 = UICorner { s19, CornerRadius = UDim.new(0, 4) }
local s20 = FrameS { Visible = true }
local e20 = Frame { s20, Visible = true }
local s21 = TextLabelS { Text = "a" }
local e21 = TextLabel { s21, Text = "a" }
local s22 = TextButtonS { AutoButtonColor = false }
local e22 = TextButton { s22, AutoButtonColor = false }
local s23 = ImageLabelS { Image = "" }
local e23 = ImageLabel { s23, Image = "" }
local s24 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e24 = UICorner { s24, CornerRadius = UDim.new(0, 4) }
local BAD1 = Frame { Visible = 5 }
local BAD2 = TextLabel { Text = 42 }
return { BAD1, BAD2 }
