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
local s75 = FrameS { Visible = true }
local e75 = Frame { s75, Visible = true }
local s76 = TextLabelS { Text = "a" }
local e76 = TextLabel { s76, Text = "a" }
local s77 = TextButtonS { AutoButtonColor = false }
local e77 = TextButton { s77, AutoButtonColor = false }
local s78 = ImageLabelS { Image = "" }
local e78 = ImageLabel { s78, Image = "" }
local s79 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e79 = UICorner { s79, CornerRadius = UDim.new(0, 4) }
local s80 = FrameS { Visible = true }
local e80 = Frame { s80, Visible = true }
local s81 = TextLabelS { Text = "a" }
local e81 = TextLabel { s81, Text = "a" }
local s82 = TextButtonS { AutoButtonColor = false }
local e82 = TextButton { s82, AutoButtonColor = false }
local s83 = ImageLabelS { Image = "" }
local e83 = ImageLabel { s83, Image = "" }
local s84 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e84 = UICorner { s84, CornerRadius = UDim.new(0, 4) }
local s85 = FrameS { Visible = true }
local e85 = Frame { s85, Visible = true }
local s86 = TextLabelS { Text = "a" }
local e86 = TextLabel { s86, Text = "a" }
local s87 = TextButtonS { AutoButtonColor = false }
local e87 = TextButton { s87, AutoButtonColor = false }
local s88 = ImageLabelS { Image = "" }
local e88 = ImageLabel { s88, Image = "" }
local s89 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e89 = UICorner { s89, CornerRadius = UDim.new(0, 4) }
local s90 = FrameS { Visible = true }
local e90 = Frame { s90, Visible = true }
local s91 = TextLabelS { Text = "a" }
local e91 = TextLabel { s91, Text = "a" }
local s92 = TextButtonS { AutoButtonColor = false }
local e92 = TextButton { s92, AutoButtonColor = false }
local s93 = ImageLabelS { Image = "" }
local e93 = ImageLabel { s93, Image = "" }
local s94 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e94 = UICorner { s94, CornerRadius = UDim.new(0, 4) }
local s95 = FrameS { Visible = true }
local e95 = Frame { s95, Visible = true }
local s96 = TextLabelS { Text = "a" }
local e96 = TextLabel { s96, Text = "a" }
local s97 = TextButtonS { AutoButtonColor = false }
local e97 = TextButton { s97, AutoButtonColor = false }
local s98 = ImageLabelS { Image = "" }
local e98 = ImageLabel { s98, Image = "" }
local s99 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e99 = UICorner { s99, CornerRadius = UDim.new(0, 4) }
local s100 = FrameS { Visible = true }
local e100 = Frame { s100, Visible = true }
local s101 = TextLabelS { Text = "a" }
local e101 = TextLabel { s101, Text = "a" }
local s102 = TextButtonS { AutoButtonColor = false }
local e102 = TextButton { s102, AutoButtonColor = false }
local s103 = ImageLabelS { Image = "" }
local e103 = ImageLabel { s103, Image = "" }
local s104 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e104 = UICorner { s104, CornerRadius = UDim.new(0, 4) }
local s105 = FrameS { Visible = true }
local e105 = Frame { s105, Visible = true }
local s106 = TextLabelS { Text = "a" }
local e106 = TextLabel { s106, Text = "a" }
local s107 = TextButtonS { AutoButtonColor = false }
local e107 = TextButton { s107, AutoButtonColor = false }
local s108 = ImageLabelS { Image = "" }
local e108 = ImageLabel { s108, Image = "" }
local s109 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e109 = UICorner { s109, CornerRadius = UDim.new(0, 4) }
local s110 = FrameS { Visible = true }
local e110 = Frame { s110, Visible = true }
local s111 = TextLabelS { Text = "a" }
local e111 = TextLabel { s111, Text = "a" }
local s112 = TextButtonS { AutoButtonColor = false }
local e112 = TextButton { s112, AutoButtonColor = false }
local s113 = ImageLabelS { Image = "" }
local e113 = ImageLabel { s113, Image = "" }
local s114 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e114 = UICorner { s114, CornerRadius = UDim.new(0, 4) }
local s115 = FrameS { Visible = true }
local e115 = Frame { s115, Visible = true }
local s116 = TextLabelS { Text = "a" }
local e116 = TextLabel { s116, Text = "a" }
local s117 = TextButtonS { AutoButtonColor = false }
local e117 = TextButton { s117, AutoButtonColor = false }
local s118 = ImageLabelS { Image = "" }
local e118 = ImageLabel { s118, Image = "" }
local s119 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e119 = UICorner { s119, CornerRadius = UDim.new(0, 4) }
local s120 = FrameS { Visible = true }
local e120 = Frame { s120, Visible = true }
local s121 = TextLabelS { Text = "a" }
local e121 = TextLabel { s121, Text = "a" }
local s122 = TextButtonS { AutoButtonColor = false }
local e122 = TextButton { s122, AutoButtonColor = false }
local s123 = ImageLabelS { Image = "" }
local e123 = ImageLabel { s123, Image = "" }
local s124 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e124 = UICorner { s124, CornerRadius = UDim.new(0, 4) }
local s125 = FrameS { Visible = true }
local e125 = Frame { s125, Visible = true }
local s126 = TextLabelS { Text = "a" }
local e126 = TextLabel { s126, Text = "a" }
local s127 = TextButtonS { AutoButtonColor = false }
local e127 = TextButton { s127, AutoButtonColor = false }
local s128 = ImageLabelS { Image = "" }
local e128 = ImageLabel { s128, Image = "" }
local s129 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e129 = UICorner { s129, CornerRadius = UDim.new(0, 4) }
local s130 = FrameS { Visible = true }
local e130 = Frame { s130, Visible = true }
local s131 = TextLabelS { Text = "a" }
local e131 = TextLabel { s131, Text = "a" }
local s132 = TextButtonS { AutoButtonColor = false }
local e132 = TextButton { s132, AutoButtonColor = false }
local s133 = ImageLabelS { Image = "" }
local e133 = ImageLabel { s133, Image = "" }
local s134 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e134 = UICorner { s134, CornerRadius = UDim.new(0, 4) }
local s135 = FrameS { Visible = true }
local e135 = Frame { s135, Visible = true }
local s136 = TextLabelS { Text = "a" }
local e136 = TextLabel { s136, Text = "a" }
local s137 = TextButtonS { AutoButtonColor = false }
local e137 = TextButton { s137, AutoButtonColor = false }
local s138 = ImageLabelS { Image = "" }
local e138 = ImageLabel { s138, Image = "" }
local s139 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e139 = UICorner { s139, CornerRadius = UDim.new(0, 4) }
local s140 = FrameS { Visible = true }
local e140 = Frame { s140, Visible = true }
local s141 = TextLabelS { Text = "a" }
local e141 = TextLabel { s141, Text = "a" }
local s142 = TextButtonS { AutoButtonColor = false }
local e142 = TextButton { s142, AutoButtonColor = false }
local s143 = ImageLabelS { Image = "" }
local e143 = ImageLabel { s143, Image = "" }
local s144 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e144 = UICorner { s144, CornerRadius = UDim.new(0, 4) }
local s145 = FrameS { Visible = true }
local e145 = Frame { s145, Visible = true }
local s146 = TextLabelS { Text = "a" }
local e146 = TextLabel { s146, Text = "a" }
local s147 = TextButtonS { AutoButtonColor = false }
local e147 = TextButton { s147, AutoButtonColor = false }
local s148 = ImageLabelS { Image = "" }
local e148 = ImageLabel { s148, Image = "" }
local s149 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e149 = UICorner { s149, CornerRadius = UDim.new(0, 4) }
local BAD1 = Frame { Visible = 5 }
local BAD2 = TextLabel { Text = 42 }
return { BAD1, BAD2 }
