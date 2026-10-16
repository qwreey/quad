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
local s25 = FrameS { Visible = true }
local e25 = Frame { s25, Visible = true }
local s26 = TextLabelS { Text = "a" }
local e26 = TextLabel { s26, Text = "a" }
local s27 = TextButtonS { AutoButtonColor = false }
local e27 = TextButton { s27, AutoButtonColor = false }
local s28 = ImageLabelS { Image = "" }
local e28 = ImageLabel { s28, Image = "" }
local s29 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e29 = UICorner { s29, CornerRadius = UDim.new(0, 4) }
local s30 = FrameS { Visible = true }
local e30 = Frame { s30, Visible = true }
local s31 = TextLabelS { Text = "a" }
local e31 = TextLabel { s31, Text = "a" }
local s32 = TextButtonS { AutoButtonColor = false }
local e32 = TextButton { s32, AutoButtonColor = false }
local s33 = ImageLabelS { Image = "" }
local e33 = ImageLabel { s33, Image = "" }
local s34 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e34 = UICorner { s34, CornerRadius = UDim.new(0, 4) }
local s35 = FrameS { Visible = true }
local e35 = Frame { s35, Visible = true }
local s36 = TextLabelS { Text = "a" }
local e36 = TextLabel { s36, Text = "a" }
local s37 = TextButtonS { AutoButtonColor = false }
local e37 = TextButton { s37, AutoButtonColor = false }
local s38 = ImageLabelS { Image = "" }
local e38 = ImageLabel { s38, Image = "" }
local s39 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e39 = UICorner { s39, CornerRadius = UDim.new(0, 4) }
local s40 = FrameS { Visible = true }
local e40 = Frame { s40, Visible = true }
local s41 = TextLabelS { Text = "a" }
local e41 = TextLabel { s41, Text = "a" }
local s42 = TextButtonS { AutoButtonColor = false }
local e42 = TextButton { s42, AutoButtonColor = false }
local s43 = ImageLabelS { Image = "" }
local e43 = ImageLabel { s43, Image = "" }
local s44 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e44 = UICorner { s44, CornerRadius = UDim.new(0, 4) }
local s45 = FrameS { Visible = true }
local e45 = Frame { s45, Visible = true }
local s46 = TextLabelS { Text = "a" }
local e46 = TextLabel { s46, Text = "a" }
local s47 = TextButtonS { AutoButtonColor = false }
local e47 = TextButton { s47, AutoButtonColor = false }
local s48 = ImageLabelS { Image = "" }
local e48 = ImageLabel { s48, Image = "" }
local s49 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e49 = UICorner { s49, CornerRadius = UDim.new(0, 4) }
local s50 = FrameS { Visible = true }
local e50 = Frame { s50, Visible = true }
local s51 = TextLabelS { Text = "a" }
local e51 = TextLabel { s51, Text = "a" }
local s52 = TextButtonS { AutoButtonColor = false }
local e52 = TextButton { s52, AutoButtonColor = false }
local s53 = ImageLabelS { Image = "" }
local e53 = ImageLabel { s53, Image = "" }
local s54 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e54 = UICorner { s54, CornerRadius = UDim.new(0, 4) }
local s55 = FrameS { Visible = true }
local e55 = Frame { s55, Visible = true }
local s56 = TextLabelS { Text = "a" }
local e56 = TextLabel { s56, Text = "a" }
local s57 = TextButtonS { AutoButtonColor = false }
local e57 = TextButton { s57, AutoButtonColor = false }
local s58 = ImageLabelS { Image = "" }
local e58 = ImageLabel { s58, Image = "" }
local s59 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e59 = UICorner { s59, CornerRadius = UDim.new(0, 4) }
local s60 = FrameS { Visible = true }
local e60 = Frame { s60, Visible = true }
local s61 = TextLabelS { Text = "a" }
local e61 = TextLabel { s61, Text = "a" }
local s62 = TextButtonS { AutoButtonColor = false }
local e62 = TextButton { s62, AutoButtonColor = false }
local s63 = ImageLabelS { Image = "" }
local e63 = ImageLabel { s63, Image = "" }
local s64 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e64 = UICorner { s64, CornerRadius = UDim.new(0, 4) }
local s65 = FrameS { Visible = true }
local e65 = Frame { s65, Visible = true }
local s66 = TextLabelS { Text = "a" }
local e66 = TextLabel { s66, Text = "a" }
local s67 = TextButtonS { AutoButtonColor = false }
local e67 = TextButton { s67, AutoButtonColor = false }
local s68 = ImageLabelS { Image = "" }
local e68 = ImageLabel { s68, Image = "" }
local s69 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e69 = UICorner { s69, CornerRadius = UDim.new(0, 4) }
local s70 = FrameS { Visible = true }
local e70 = Frame { s70, Visible = true }
local s71 = TextLabelS { Text = "a" }
local e71 = TextLabel { s71, Text = "a" }
local s72 = TextButtonS { AutoButtonColor = false }
local e72 = TextButton { s72, AutoButtonColor = false }
local s73 = ImageLabelS { Image = "" }
local e73 = ImageLabel { s73, Image = "" }
local s74 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e74 = UICorner { s74, CornerRadius = UDim.new(0, 4) }
local BAD1 = Frame { Visible = 5 }
local BAD2 = TextLabel { Text = 42 }
return { BAD1, BAD2 }
