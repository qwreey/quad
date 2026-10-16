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
local s150 = FrameS { Visible = true }
local e150 = Frame { s150, Visible = true }
local s151 = TextLabelS { Text = "a" }
local e151 = TextLabel { s151, Text = "a" }
local s152 = TextButtonS { AutoButtonColor = false }
local e152 = TextButton { s152, AutoButtonColor = false }
local s153 = ImageLabelS { Image = "" }
local e153 = ImageLabel { s153, Image = "" }
local s154 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e154 = UICorner { s154, CornerRadius = UDim.new(0, 4) }
local s155 = FrameS { Visible = true }
local e155 = Frame { s155, Visible = true }
local s156 = TextLabelS { Text = "a" }
local e156 = TextLabel { s156, Text = "a" }
local s157 = TextButtonS { AutoButtonColor = false }
local e157 = TextButton { s157, AutoButtonColor = false }
local s158 = ImageLabelS { Image = "" }
local e158 = ImageLabel { s158, Image = "" }
local s159 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e159 = UICorner { s159, CornerRadius = UDim.new(0, 4) }
local s160 = FrameS { Visible = true }
local e160 = Frame { s160, Visible = true }
local s161 = TextLabelS { Text = "a" }
local e161 = TextLabel { s161, Text = "a" }
local s162 = TextButtonS { AutoButtonColor = false }
local e162 = TextButton { s162, AutoButtonColor = false }
local s163 = ImageLabelS { Image = "" }
local e163 = ImageLabel { s163, Image = "" }
local s164 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e164 = UICorner { s164, CornerRadius = UDim.new(0, 4) }
local s165 = FrameS { Visible = true }
local e165 = Frame { s165, Visible = true }
local s166 = TextLabelS { Text = "a" }
local e166 = TextLabel { s166, Text = "a" }
local s167 = TextButtonS { AutoButtonColor = false }
local e167 = TextButton { s167, AutoButtonColor = false }
local s168 = ImageLabelS { Image = "" }
local e168 = ImageLabel { s168, Image = "" }
local s169 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e169 = UICorner { s169, CornerRadius = UDim.new(0, 4) }
local s170 = FrameS { Visible = true }
local e170 = Frame { s170, Visible = true }
local s171 = TextLabelS { Text = "a" }
local e171 = TextLabel { s171, Text = "a" }
local s172 = TextButtonS { AutoButtonColor = false }
local e172 = TextButton { s172, AutoButtonColor = false }
local s173 = ImageLabelS { Image = "" }
local e173 = ImageLabel { s173, Image = "" }
local s174 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e174 = UICorner { s174, CornerRadius = UDim.new(0, 4) }
local s175 = FrameS { Visible = true }
local e175 = Frame { s175, Visible = true }
local s176 = TextLabelS { Text = "a" }
local e176 = TextLabel { s176, Text = "a" }
local s177 = TextButtonS { AutoButtonColor = false }
local e177 = TextButton { s177, AutoButtonColor = false }
local s178 = ImageLabelS { Image = "" }
local e178 = ImageLabel { s178, Image = "" }
local s179 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e179 = UICorner { s179, CornerRadius = UDim.new(0, 4) }
local s180 = FrameS { Visible = true }
local e180 = Frame { s180, Visible = true }
local s181 = TextLabelS { Text = "a" }
local e181 = TextLabel { s181, Text = "a" }
local s182 = TextButtonS { AutoButtonColor = false }
local e182 = TextButton { s182, AutoButtonColor = false }
local s183 = ImageLabelS { Image = "" }
local e183 = ImageLabel { s183, Image = "" }
local s184 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e184 = UICorner { s184, CornerRadius = UDim.new(0, 4) }
local s185 = FrameS { Visible = true }
local e185 = Frame { s185, Visible = true }
local s186 = TextLabelS { Text = "a" }
local e186 = TextLabel { s186, Text = "a" }
local s187 = TextButtonS { AutoButtonColor = false }
local e187 = TextButton { s187, AutoButtonColor = false }
local s188 = ImageLabelS { Image = "" }
local e188 = ImageLabel { s188, Image = "" }
local s189 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e189 = UICorner { s189, CornerRadius = UDim.new(0, 4) }
local s190 = FrameS { Visible = true }
local e190 = Frame { s190, Visible = true }
local s191 = TextLabelS { Text = "a" }
local e191 = TextLabel { s191, Text = "a" }
local s192 = TextButtonS { AutoButtonColor = false }
local e192 = TextButton { s192, AutoButtonColor = false }
local s193 = ImageLabelS { Image = "" }
local e193 = ImageLabel { s193, Image = "" }
local s194 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e194 = UICorner { s194, CornerRadius = UDim.new(0, 4) }
local s195 = FrameS { Visible = true }
local e195 = Frame { s195, Visible = true }
local s196 = TextLabelS { Text = "a" }
local e196 = TextLabel { s196, Text = "a" }
local s197 = TextButtonS { AutoButtonColor = false }
local e197 = TextButton { s197, AutoButtonColor = false }
local s198 = ImageLabelS { Image = "" }
local e198 = ImageLabel { s198, Image = "" }
local s199 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e199 = UICorner { s199, CornerRadius = UDim.new(0, 4) }
local s200 = FrameS { Visible = true }
local e200 = Frame { s200, Visible = true }
local s201 = TextLabelS { Text = "a" }
local e201 = TextLabel { s201, Text = "a" }
local s202 = TextButtonS { AutoButtonColor = false }
local e202 = TextButton { s202, AutoButtonColor = false }
local s203 = ImageLabelS { Image = "" }
local e203 = ImageLabel { s203, Image = "" }
local s204 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e204 = UICorner { s204, CornerRadius = UDim.new(0, 4) }
local s205 = FrameS { Visible = true }
local e205 = Frame { s205, Visible = true }
local s206 = TextLabelS { Text = "a" }
local e206 = TextLabel { s206, Text = "a" }
local s207 = TextButtonS { AutoButtonColor = false }
local e207 = TextButton { s207, AutoButtonColor = false }
local s208 = ImageLabelS { Image = "" }
local e208 = ImageLabel { s208, Image = "" }
local s209 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e209 = UICorner { s209, CornerRadius = UDim.new(0, 4) }
local s210 = FrameS { Visible = true }
local e210 = Frame { s210, Visible = true }
local s211 = TextLabelS { Text = "a" }
local e211 = TextLabel { s211, Text = "a" }
local s212 = TextButtonS { AutoButtonColor = false }
local e212 = TextButton { s212, AutoButtonColor = false }
local s213 = ImageLabelS { Image = "" }
local e213 = ImageLabel { s213, Image = "" }
local s214 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e214 = UICorner { s214, CornerRadius = UDim.new(0, 4) }
local s215 = FrameS { Visible = true }
local e215 = Frame { s215, Visible = true }
local s216 = TextLabelS { Text = "a" }
local e216 = TextLabel { s216, Text = "a" }
local s217 = TextButtonS { AutoButtonColor = false }
local e217 = TextButton { s217, AutoButtonColor = false }
local s218 = ImageLabelS { Image = "" }
local e218 = ImageLabel { s218, Image = "" }
local s219 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e219 = UICorner { s219, CornerRadius = UDim.new(0, 4) }
local s220 = FrameS { Visible = true }
local e220 = Frame { s220, Visible = true }
local s221 = TextLabelS { Text = "a" }
local e221 = TextLabel { s221, Text = "a" }
local s222 = TextButtonS { AutoButtonColor = false }
local e222 = TextButton { s222, AutoButtonColor = false }
local s223 = ImageLabelS { Image = "" }
local e223 = ImageLabel { s223, Image = "" }
local s224 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e224 = UICorner { s224, CornerRadius = UDim.new(0, 4) }
local s225 = FrameS { Visible = true }
local e225 = Frame { s225, Visible = true }
local s226 = TextLabelS { Text = "a" }
local e226 = TextLabel { s226, Text = "a" }
local s227 = TextButtonS { AutoButtonColor = false }
local e227 = TextButton { s227, AutoButtonColor = false }
local s228 = ImageLabelS { Image = "" }
local e228 = ImageLabel { s228, Image = "" }
local s229 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e229 = UICorner { s229, CornerRadius = UDim.new(0, 4) }
local s230 = FrameS { Visible = true }
local e230 = Frame { s230, Visible = true }
local s231 = TextLabelS { Text = "a" }
local e231 = TextLabel { s231, Text = "a" }
local s232 = TextButtonS { AutoButtonColor = false }
local e232 = TextButton { s232, AutoButtonColor = false }
local s233 = ImageLabelS { Image = "" }
local e233 = ImageLabel { s233, Image = "" }
local s234 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e234 = UICorner { s234, CornerRadius = UDim.new(0, 4) }
local s235 = FrameS { Visible = true }
local e235 = Frame { s235, Visible = true }
local s236 = TextLabelS { Text = "a" }
local e236 = TextLabel { s236, Text = "a" }
local s237 = TextButtonS { AutoButtonColor = false }
local e237 = TextButton { s237, AutoButtonColor = false }
local s238 = ImageLabelS { Image = "" }
local e238 = ImageLabel { s238, Image = "" }
local s239 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e239 = UICorner { s239, CornerRadius = UDim.new(0, 4) }
local s240 = FrameS { Visible = true }
local e240 = Frame { s240, Visible = true }
local s241 = TextLabelS { Text = "a" }
local e241 = TextLabel { s241, Text = "a" }
local s242 = TextButtonS { AutoButtonColor = false }
local e242 = TextButton { s242, AutoButtonColor = false }
local s243 = ImageLabelS { Image = "" }
local e243 = ImageLabel { s243, Image = "" }
local s244 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e244 = UICorner { s244, CornerRadius = UDim.new(0, 4) }
local s245 = FrameS { Visible = true }
local e245 = Frame { s245, Visible = true }
local s246 = TextLabelS { Text = "a" }
local e246 = TextLabel { s246, Text = "a" }
local s247 = TextButtonS { AutoButtonColor = false }
local e247 = TextButton { s247, AutoButtonColor = false }
local s248 = ImageLabelS { Image = "" }
local e248 = ImageLabel { s248, Image = "" }
local s249 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e249 = UICorner { s249, CornerRadius = UDim.new(0, 4) }
local s250 = FrameS { Visible = true }
local e250 = Frame { s250, Visible = true }
local s251 = TextLabelS { Text = "a" }
local e251 = TextLabel { s251, Text = "a" }
local s252 = TextButtonS { AutoButtonColor = false }
local e252 = TextButton { s252, AutoButtonColor = false }
local s253 = ImageLabelS { Image = "" }
local e253 = ImageLabel { s253, Image = "" }
local s254 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e254 = UICorner { s254, CornerRadius = UDim.new(0, 4) }
local s255 = FrameS { Visible = true }
local e255 = Frame { s255, Visible = true }
local s256 = TextLabelS { Text = "a" }
local e256 = TextLabel { s256, Text = "a" }
local s257 = TextButtonS { AutoButtonColor = false }
local e257 = TextButton { s257, AutoButtonColor = false }
local s258 = ImageLabelS { Image = "" }
local e258 = ImageLabel { s258, Image = "" }
local s259 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e259 = UICorner { s259, CornerRadius = UDim.new(0, 4) }
local s260 = FrameS { Visible = true }
local e260 = Frame { s260, Visible = true }
local s261 = TextLabelS { Text = "a" }
local e261 = TextLabel { s261, Text = "a" }
local s262 = TextButtonS { AutoButtonColor = false }
local e262 = TextButton { s262, AutoButtonColor = false }
local s263 = ImageLabelS { Image = "" }
local e263 = ImageLabel { s263, Image = "" }
local s264 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e264 = UICorner { s264, CornerRadius = UDim.new(0, 4) }
local s265 = FrameS { Visible = true }
local e265 = Frame { s265, Visible = true }
local s266 = TextLabelS { Text = "a" }
local e266 = TextLabel { s266, Text = "a" }
local s267 = TextButtonS { AutoButtonColor = false }
local e267 = TextButton { s267, AutoButtonColor = false }
local s268 = ImageLabelS { Image = "" }
local e268 = ImageLabel { s268, Image = "" }
local s269 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e269 = UICorner { s269, CornerRadius = UDim.new(0, 4) }
local s270 = FrameS { Visible = true }
local e270 = Frame { s270, Visible = true }
local s271 = TextLabelS { Text = "a" }
local e271 = TextLabel { s271, Text = "a" }
local s272 = TextButtonS { AutoButtonColor = false }
local e272 = TextButton { s272, AutoButtonColor = false }
local s273 = ImageLabelS { Image = "" }
local e273 = ImageLabel { s273, Image = "" }
local s274 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e274 = UICorner { s274, CornerRadius = UDim.new(0, 4) }
local s275 = FrameS { Visible = true }
local e275 = Frame { s275, Visible = true }
local s276 = TextLabelS { Text = "a" }
local e276 = TextLabel { s276, Text = "a" }
local s277 = TextButtonS { AutoButtonColor = false }
local e277 = TextButton { s277, AutoButtonColor = false }
local s278 = ImageLabelS { Image = "" }
local e278 = ImageLabel { s278, Image = "" }
local s279 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e279 = UICorner { s279, CornerRadius = UDim.new(0, 4) }
local s280 = FrameS { Visible = true }
local e280 = Frame { s280, Visible = true }
local s281 = TextLabelS { Text = "a" }
local e281 = TextLabel { s281, Text = "a" }
local s282 = TextButtonS { AutoButtonColor = false }
local e282 = TextButton { s282, AutoButtonColor = false }
local s283 = ImageLabelS { Image = "" }
local e283 = ImageLabel { s283, Image = "" }
local s284 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e284 = UICorner { s284, CornerRadius = UDim.new(0, 4) }
local s285 = FrameS { Visible = true }
local e285 = Frame { s285, Visible = true }
local s286 = TextLabelS { Text = "a" }
local e286 = TextLabel { s286, Text = "a" }
local s287 = TextButtonS { AutoButtonColor = false }
local e287 = TextButton { s287, AutoButtonColor = false }
local s288 = ImageLabelS { Image = "" }
local e288 = ImageLabel { s288, Image = "" }
local s289 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e289 = UICorner { s289, CornerRadius = UDim.new(0, 4) }
local s290 = FrameS { Visible = true }
local e290 = Frame { s290, Visible = true }
local s291 = TextLabelS { Text = "a" }
local e291 = TextLabel { s291, Text = "a" }
local s292 = TextButtonS { AutoButtonColor = false }
local e292 = TextButton { s292, AutoButtonColor = false }
local s293 = ImageLabelS { Image = "" }
local e293 = ImageLabel { s293, Image = "" }
local s294 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e294 = UICorner { s294, CornerRadius = UDim.new(0, 4) }
local s295 = FrameS { Visible = true }
local e295 = Frame { s295, Visible = true }
local s296 = TextLabelS { Text = "a" }
local e296 = TextLabel { s296, Text = "a" }
local s297 = TextButtonS { AutoButtonColor = false }
local e297 = TextButton { s297, AutoButtonColor = false }
local s298 = ImageLabelS { Image = "" }
local e298 = ImageLabel { s298, Image = "" }
local s299 = UICornerS { CornerRadius = UDim.new(0, 4) }
local e299 = UICorner { s299, CornerRadius = UDim.new(0, 4) }
local BAD1 = Frame { Visible = 5 }
local BAD2 = TextLabel { Text = 42 }
return { BAD1, BAD2 }
