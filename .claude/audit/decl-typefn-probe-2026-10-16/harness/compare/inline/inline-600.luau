--!strict
local L = require("../../../src/Lib")
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel }
local NewN = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> index<ClassMap, K>
type SM<K> = { read __quadSpread: K }
local SpreadC = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> SM<K>
local s0 = SpreadC "Frame" { Visible = true }
local e0 = NewN "Frame" { s0, Visible = true }
local s1 = SpreadC "TextLabel" { Text = "a" }
local e1 = NewN "TextLabel" { s1, Text = "a" }
local s2 = SpreadC "TextButton" { AutoButtonColor = false }
local e2 = NewN "TextButton" { s2, AutoButtonColor = false }
local s3 = SpreadC "ImageLabel" { Image = "" }
local e3 = NewN "ImageLabel" { s3, Image = "" }
local s4 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e4 = NewN "UICorner" { s4, CornerRadius = UDim.new(0, 4) }
local s5 = SpreadC "Frame" { Visible = true }
local e5 = NewN "Frame" { s5, Visible = true }
local s6 = SpreadC "TextLabel" { Text = "a" }
local e6 = NewN "TextLabel" { s6, Text = "a" }
local s7 = SpreadC "TextButton" { AutoButtonColor = false }
local e7 = NewN "TextButton" { s7, AutoButtonColor = false }
local s8 = SpreadC "ImageLabel" { Image = "" }
local e8 = NewN "ImageLabel" { s8, Image = "" }
local s9 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e9 = NewN "UICorner" { s9, CornerRadius = UDim.new(0, 4) }
local s10 = SpreadC "Frame" { Visible = true }
local e10 = NewN "Frame" { s10, Visible = true }
local s11 = SpreadC "TextLabel" { Text = "a" }
local e11 = NewN "TextLabel" { s11, Text = "a" }
local s12 = SpreadC "TextButton" { AutoButtonColor = false }
local e12 = NewN "TextButton" { s12, AutoButtonColor = false }
local s13 = SpreadC "ImageLabel" { Image = "" }
local e13 = NewN "ImageLabel" { s13, Image = "" }
local s14 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e14 = NewN "UICorner" { s14, CornerRadius = UDim.new(0, 4) }
local s15 = SpreadC "Frame" { Visible = true }
local e15 = NewN "Frame" { s15, Visible = true }
local s16 = SpreadC "TextLabel" { Text = "a" }
local e16 = NewN "TextLabel" { s16, Text = "a" }
local s17 = SpreadC "TextButton" { AutoButtonColor = false }
local e17 = NewN "TextButton" { s17, AutoButtonColor = false }
local s18 = SpreadC "ImageLabel" { Image = "" }
local e18 = NewN "ImageLabel" { s18, Image = "" }
local s19 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e19 = NewN "UICorner" { s19, CornerRadius = UDim.new(0, 4) }
local s20 = SpreadC "Frame" { Visible = true }
local e20 = NewN "Frame" { s20, Visible = true }
local s21 = SpreadC "TextLabel" { Text = "a" }
local e21 = NewN "TextLabel" { s21, Text = "a" }
local s22 = SpreadC "TextButton" { AutoButtonColor = false }
local e22 = NewN "TextButton" { s22, AutoButtonColor = false }
local s23 = SpreadC "ImageLabel" { Image = "" }
local e23 = NewN "ImageLabel" { s23, Image = "" }
local s24 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e24 = NewN "UICorner" { s24, CornerRadius = UDim.new(0, 4) }
local s25 = SpreadC "Frame" { Visible = true }
local e25 = NewN "Frame" { s25, Visible = true }
local s26 = SpreadC "TextLabel" { Text = "a" }
local e26 = NewN "TextLabel" { s26, Text = "a" }
local s27 = SpreadC "TextButton" { AutoButtonColor = false }
local e27 = NewN "TextButton" { s27, AutoButtonColor = false }
local s28 = SpreadC "ImageLabel" { Image = "" }
local e28 = NewN "ImageLabel" { s28, Image = "" }
local s29 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e29 = NewN "UICorner" { s29, CornerRadius = UDim.new(0, 4) }
local s30 = SpreadC "Frame" { Visible = true }
local e30 = NewN "Frame" { s30, Visible = true }
local s31 = SpreadC "TextLabel" { Text = "a" }
local e31 = NewN "TextLabel" { s31, Text = "a" }
local s32 = SpreadC "TextButton" { AutoButtonColor = false }
local e32 = NewN "TextButton" { s32, AutoButtonColor = false }
local s33 = SpreadC "ImageLabel" { Image = "" }
local e33 = NewN "ImageLabel" { s33, Image = "" }
local s34 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e34 = NewN "UICorner" { s34, CornerRadius = UDim.new(0, 4) }
local s35 = SpreadC "Frame" { Visible = true }
local e35 = NewN "Frame" { s35, Visible = true }
local s36 = SpreadC "TextLabel" { Text = "a" }
local e36 = NewN "TextLabel" { s36, Text = "a" }
local s37 = SpreadC "TextButton" { AutoButtonColor = false }
local e37 = NewN "TextButton" { s37, AutoButtonColor = false }
local s38 = SpreadC "ImageLabel" { Image = "" }
local e38 = NewN "ImageLabel" { s38, Image = "" }
local s39 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e39 = NewN "UICorner" { s39, CornerRadius = UDim.new(0, 4) }
local s40 = SpreadC "Frame" { Visible = true }
local e40 = NewN "Frame" { s40, Visible = true }
local s41 = SpreadC "TextLabel" { Text = "a" }
local e41 = NewN "TextLabel" { s41, Text = "a" }
local s42 = SpreadC "TextButton" { AutoButtonColor = false }
local e42 = NewN "TextButton" { s42, AutoButtonColor = false }
local s43 = SpreadC "ImageLabel" { Image = "" }
local e43 = NewN "ImageLabel" { s43, Image = "" }
local s44 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e44 = NewN "UICorner" { s44, CornerRadius = UDim.new(0, 4) }
local s45 = SpreadC "Frame" { Visible = true }
local e45 = NewN "Frame" { s45, Visible = true }
local s46 = SpreadC "TextLabel" { Text = "a" }
local e46 = NewN "TextLabel" { s46, Text = "a" }
local s47 = SpreadC "TextButton" { AutoButtonColor = false }
local e47 = NewN "TextButton" { s47, AutoButtonColor = false }
local s48 = SpreadC "ImageLabel" { Image = "" }
local e48 = NewN "ImageLabel" { s48, Image = "" }
local s49 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e49 = NewN "UICorner" { s49, CornerRadius = UDim.new(0, 4) }
local s50 = SpreadC "Frame" { Visible = true }
local e50 = NewN "Frame" { s50, Visible = true }
local s51 = SpreadC "TextLabel" { Text = "a" }
local e51 = NewN "TextLabel" { s51, Text = "a" }
local s52 = SpreadC "TextButton" { AutoButtonColor = false }
local e52 = NewN "TextButton" { s52, AutoButtonColor = false }
local s53 = SpreadC "ImageLabel" { Image = "" }
local e53 = NewN "ImageLabel" { s53, Image = "" }
local s54 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e54 = NewN "UICorner" { s54, CornerRadius = UDim.new(0, 4) }
local s55 = SpreadC "Frame" { Visible = true }
local e55 = NewN "Frame" { s55, Visible = true }
local s56 = SpreadC "TextLabel" { Text = "a" }
local e56 = NewN "TextLabel" { s56, Text = "a" }
local s57 = SpreadC "TextButton" { AutoButtonColor = false }
local e57 = NewN "TextButton" { s57, AutoButtonColor = false }
local s58 = SpreadC "ImageLabel" { Image = "" }
local e58 = NewN "ImageLabel" { s58, Image = "" }
local s59 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e59 = NewN "UICorner" { s59, CornerRadius = UDim.new(0, 4) }
local s60 = SpreadC "Frame" { Visible = true }
local e60 = NewN "Frame" { s60, Visible = true }
local s61 = SpreadC "TextLabel" { Text = "a" }
local e61 = NewN "TextLabel" { s61, Text = "a" }
local s62 = SpreadC "TextButton" { AutoButtonColor = false }
local e62 = NewN "TextButton" { s62, AutoButtonColor = false }
local s63 = SpreadC "ImageLabel" { Image = "" }
local e63 = NewN "ImageLabel" { s63, Image = "" }
local s64 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e64 = NewN "UICorner" { s64, CornerRadius = UDim.new(0, 4) }
local s65 = SpreadC "Frame" { Visible = true }
local e65 = NewN "Frame" { s65, Visible = true }
local s66 = SpreadC "TextLabel" { Text = "a" }
local e66 = NewN "TextLabel" { s66, Text = "a" }
local s67 = SpreadC "TextButton" { AutoButtonColor = false }
local e67 = NewN "TextButton" { s67, AutoButtonColor = false }
local s68 = SpreadC "ImageLabel" { Image = "" }
local e68 = NewN "ImageLabel" { s68, Image = "" }
local s69 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e69 = NewN "UICorner" { s69, CornerRadius = UDim.new(0, 4) }
local s70 = SpreadC "Frame" { Visible = true }
local e70 = NewN "Frame" { s70, Visible = true }
local s71 = SpreadC "TextLabel" { Text = "a" }
local e71 = NewN "TextLabel" { s71, Text = "a" }
local s72 = SpreadC "TextButton" { AutoButtonColor = false }
local e72 = NewN "TextButton" { s72, AutoButtonColor = false }
local s73 = SpreadC "ImageLabel" { Image = "" }
local e73 = NewN "ImageLabel" { s73, Image = "" }
local s74 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e74 = NewN "UICorner" { s74, CornerRadius = UDim.new(0, 4) }
local s75 = SpreadC "Frame" { Visible = true }
local e75 = NewN "Frame" { s75, Visible = true }
local s76 = SpreadC "TextLabel" { Text = "a" }
local e76 = NewN "TextLabel" { s76, Text = "a" }
local s77 = SpreadC "TextButton" { AutoButtonColor = false }
local e77 = NewN "TextButton" { s77, AutoButtonColor = false }
local s78 = SpreadC "ImageLabel" { Image = "" }
local e78 = NewN "ImageLabel" { s78, Image = "" }
local s79 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e79 = NewN "UICorner" { s79, CornerRadius = UDim.new(0, 4) }
local s80 = SpreadC "Frame" { Visible = true }
local e80 = NewN "Frame" { s80, Visible = true }
local s81 = SpreadC "TextLabel" { Text = "a" }
local e81 = NewN "TextLabel" { s81, Text = "a" }
local s82 = SpreadC "TextButton" { AutoButtonColor = false }
local e82 = NewN "TextButton" { s82, AutoButtonColor = false }
local s83 = SpreadC "ImageLabel" { Image = "" }
local e83 = NewN "ImageLabel" { s83, Image = "" }
local s84 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e84 = NewN "UICorner" { s84, CornerRadius = UDim.new(0, 4) }
local s85 = SpreadC "Frame" { Visible = true }
local e85 = NewN "Frame" { s85, Visible = true }
local s86 = SpreadC "TextLabel" { Text = "a" }
local e86 = NewN "TextLabel" { s86, Text = "a" }
local s87 = SpreadC "TextButton" { AutoButtonColor = false }
local e87 = NewN "TextButton" { s87, AutoButtonColor = false }
local s88 = SpreadC "ImageLabel" { Image = "" }
local e88 = NewN "ImageLabel" { s88, Image = "" }
local s89 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e89 = NewN "UICorner" { s89, CornerRadius = UDim.new(0, 4) }
local s90 = SpreadC "Frame" { Visible = true }
local e90 = NewN "Frame" { s90, Visible = true }
local s91 = SpreadC "TextLabel" { Text = "a" }
local e91 = NewN "TextLabel" { s91, Text = "a" }
local s92 = SpreadC "TextButton" { AutoButtonColor = false }
local e92 = NewN "TextButton" { s92, AutoButtonColor = false }
local s93 = SpreadC "ImageLabel" { Image = "" }
local e93 = NewN "ImageLabel" { s93, Image = "" }
local s94 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e94 = NewN "UICorner" { s94, CornerRadius = UDim.new(0, 4) }
local s95 = SpreadC "Frame" { Visible = true }
local e95 = NewN "Frame" { s95, Visible = true }
local s96 = SpreadC "TextLabel" { Text = "a" }
local e96 = NewN "TextLabel" { s96, Text = "a" }
local s97 = SpreadC "TextButton" { AutoButtonColor = false }
local e97 = NewN "TextButton" { s97, AutoButtonColor = false }
local s98 = SpreadC "ImageLabel" { Image = "" }
local e98 = NewN "ImageLabel" { s98, Image = "" }
local s99 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e99 = NewN "UICorner" { s99, CornerRadius = UDim.new(0, 4) }
local s100 = SpreadC "Frame" { Visible = true }
local e100 = NewN "Frame" { s100, Visible = true }
local s101 = SpreadC "TextLabel" { Text = "a" }
local e101 = NewN "TextLabel" { s101, Text = "a" }
local s102 = SpreadC "TextButton" { AutoButtonColor = false }
local e102 = NewN "TextButton" { s102, AutoButtonColor = false }
local s103 = SpreadC "ImageLabel" { Image = "" }
local e103 = NewN "ImageLabel" { s103, Image = "" }
local s104 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e104 = NewN "UICorner" { s104, CornerRadius = UDim.new(0, 4) }
local s105 = SpreadC "Frame" { Visible = true }
local e105 = NewN "Frame" { s105, Visible = true }
local s106 = SpreadC "TextLabel" { Text = "a" }
local e106 = NewN "TextLabel" { s106, Text = "a" }
local s107 = SpreadC "TextButton" { AutoButtonColor = false }
local e107 = NewN "TextButton" { s107, AutoButtonColor = false }
local s108 = SpreadC "ImageLabel" { Image = "" }
local e108 = NewN "ImageLabel" { s108, Image = "" }
local s109 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e109 = NewN "UICorner" { s109, CornerRadius = UDim.new(0, 4) }
local s110 = SpreadC "Frame" { Visible = true }
local e110 = NewN "Frame" { s110, Visible = true }
local s111 = SpreadC "TextLabel" { Text = "a" }
local e111 = NewN "TextLabel" { s111, Text = "a" }
local s112 = SpreadC "TextButton" { AutoButtonColor = false }
local e112 = NewN "TextButton" { s112, AutoButtonColor = false }
local s113 = SpreadC "ImageLabel" { Image = "" }
local e113 = NewN "ImageLabel" { s113, Image = "" }
local s114 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e114 = NewN "UICorner" { s114, CornerRadius = UDim.new(0, 4) }
local s115 = SpreadC "Frame" { Visible = true }
local e115 = NewN "Frame" { s115, Visible = true }
local s116 = SpreadC "TextLabel" { Text = "a" }
local e116 = NewN "TextLabel" { s116, Text = "a" }
local s117 = SpreadC "TextButton" { AutoButtonColor = false }
local e117 = NewN "TextButton" { s117, AutoButtonColor = false }
local s118 = SpreadC "ImageLabel" { Image = "" }
local e118 = NewN "ImageLabel" { s118, Image = "" }
local s119 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e119 = NewN "UICorner" { s119, CornerRadius = UDim.new(0, 4) }
local s120 = SpreadC "Frame" { Visible = true }
local e120 = NewN "Frame" { s120, Visible = true }
local s121 = SpreadC "TextLabel" { Text = "a" }
local e121 = NewN "TextLabel" { s121, Text = "a" }
local s122 = SpreadC "TextButton" { AutoButtonColor = false }
local e122 = NewN "TextButton" { s122, AutoButtonColor = false }
local s123 = SpreadC "ImageLabel" { Image = "" }
local e123 = NewN "ImageLabel" { s123, Image = "" }
local s124 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e124 = NewN "UICorner" { s124, CornerRadius = UDim.new(0, 4) }
local s125 = SpreadC "Frame" { Visible = true }
local e125 = NewN "Frame" { s125, Visible = true }
local s126 = SpreadC "TextLabel" { Text = "a" }
local e126 = NewN "TextLabel" { s126, Text = "a" }
local s127 = SpreadC "TextButton" { AutoButtonColor = false }
local e127 = NewN "TextButton" { s127, AutoButtonColor = false }
local s128 = SpreadC "ImageLabel" { Image = "" }
local e128 = NewN "ImageLabel" { s128, Image = "" }
local s129 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e129 = NewN "UICorner" { s129, CornerRadius = UDim.new(0, 4) }
local s130 = SpreadC "Frame" { Visible = true }
local e130 = NewN "Frame" { s130, Visible = true }
local s131 = SpreadC "TextLabel" { Text = "a" }
local e131 = NewN "TextLabel" { s131, Text = "a" }
local s132 = SpreadC "TextButton" { AutoButtonColor = false }
local e132 = NewN "TextButton" { s132, AutoButtonColor = false }
local s133 = SpreadC "ImageLabel" { Image = "" }
local e133 = NewN "ImageLabel" { s133, Image = "" }
local s134 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e134 = NewN "UICorner" { s134, CornerRadius = UDim.new(0, 4) }
local s135 = SpreadC "Frame" { Visible = true }
local e135 = NewN "Frame" { s135, Visible = true }
local s136 = SpreadC "TextLabel" { Text = "a" }
local e136 = NewN "TextLabel" { s136, Text = "a" }
local s137 = SpreadC "TextButton" { AutoButtonColor = false }
local e137 = NewN "TextButton" { s137, AutoButtonColor = false }
local s138 = SpreadC "ImageLabel" { Image = "" }
local e138 = NewN "ImageLabel" { s138, Image = "" }
local s139 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e139 = NewN "UICorner" { s139, CornerRadius = UDim.new(0, 4) }
local s140 = SpreadC "Frame" { Visible = true }
local e140 = NewN "Frame" { s140, Visible = true }
local s141 = SpreadC "TextLabel" { Text = "a" }
local e141 = NewN "TextLabel" { s141, Text = "a" }
local s142 = SpreadC "TextButton" { AutoButtonColor = false }
local e142 = NewN "TextButton" { s142, AutoButtonColor = false }
local s143 = SpreadC "ImageLabel" { Image = "" }
local e143 = NewN "ImageLabel" { s143, Image = "" }
local s144 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e144 = NewN "UICorner" { s144, CornerRadius = UDim.new(0, 4) }
local s145 = SpreadC "Frame" { Visible = true }
local e145 = NewN "Frame" { s145, Visible = true }
local s146 = SpreadC "TextLabel" { Text = "a" }
local e146 = NewN "TextLabel" { s146, Text = "a" }
local s147 = SpreadC "TextButton" { AutoButtonColor = false }
local e147 = NewN "TextButton" { s147, AutoButtonColor = false }
local s148 = SpreadC "ImageLabel" { Image = "" }
local e148 = NewN "ImageLabel" { s148, Image = "" }
local s149 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e149 = NewN "UICorner" { s149, CornerRadius = UDim.new(0, 4) }
local s150 = SpreadC "Frame" { Visible = true }
local e150 = NewN "Frame" { s150, Visible = true }
local s151 = SpreadC "TextLabel" { Text = "a" }
local e151 = NewN "TextLabel" { s151, Text = "a" }
local s152 = SpreadC "TextButton" { AutoButtonColor = false }
local e152 = NewN "TextButton" { s152, AutoButtonColor = false }
local s153 = SpreadC "ImageLabel" { Image = "" }
local e153 = NewN "ImageLabel" { s153, Image = "" }
local s154 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e154 = NewN "UICorner" { s154, CornerRadius = UDim.new(0, 4) }
local s155 = SpreadC "Frame" { Visible = true }
local e155 = NewN "Frame" { s155, Visible = true }
local s156 = SpreadC "TextLabel" { Text = "a" }
local e156 = NewN "TextLabel" { s156, Text = "a" }
local s157 = SpreadC "TextButton" { AutoButtonColor = false }
local e157 = NewN "TextButton" { s157, AutoButtonColor = false }
local s158 = SpreadC "ImageLabel" { Image = "" }
local e158 = NewN "ImageLabel" { s158, Image = "" }
local s159 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e159 = NewN "UICorner" { s159, CornerRadius = UDim.new(0, 4) }
local s160 = SpreadC "Frame" { Visible = true }
local e160 = NewN "Frame" { s160, Visible = true }
local s161 = SpreadC "TextLabel" { Text = "a" }
local e161 = NewN "TextLabel" { s161, Text = "a" }
local s162 = SpreadC "TextButton" { AutoButtonColor = false }
local e162 = NewN "TextButton" { s162, AutoButtonColor = false }
local s163 = SpreadC "ImageLabel" { Image = "" }
local e163 = NewN "ImageLabel" { s163, Image = "" }
local s164 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e164 = NewN "UICorner" { s164, CornerRadius = UDim.new(0, 4) }
local s165 = SpreadC "Frame" { Visible = true }
local e165 = NewN "Frame" { s165, Visible = true }
local s166 = SpreadC "TextLabel" { Text = "a" }
local e166 = NewN "TextLabel" { s166, Text = "a" }
local s167 = SpreadC "TextButton" { AutoButtonColor = false }
local e167 = NewN "TextButton" { s167, AutoButtonColor = false }
local s168 = SpreadC "ImageLabel" { Image = "" }
local e168 = NewN "ImageLabel" { s168, Image = "" }
local s169 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e169 = NewN "UICorner" { s169, CornerRadius = UDim.new(0, 4) }
local s170 = SpreadC "Frame" { Visible = true }
local e170 = NewN "Frame" { s170, Visible = true }
local s171 = SpreadC "TextLabel" { Text = "a" }
local e171 = NewN "TextLabel" { s171, Text = "a" }
local s172 = SpreadC "TextButton" { AutoButtonColor = false }
local e172 = NewN "TextButton" { s172, AutoButtonColor = false }
local s173 = SpreadC "ImageLabel" { Image = "" }
local e173 = NewN "ImageLabel" { s173, Image = "" }
local s174 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e174 = NewN "UICorner" { s174, CornerRadius = UDim.new(0, 4) }
local s175 = SpreadC "Frame" { Visible = true }
local e175 = NewN "Frame" { s175, Visible = true }
local s176 = SpreadC "TextLabel" { Text = "a" }
local e176 = NewN "TextLabel" { s176, Text = "a" }
local s177 = SpreadC "TextButton" { AutoButtonColor = false }
local e177 = NewN "TextButton" { s177, AutoButtonColor = false }
local s178 = SpreadC "ImageLabel" { Image = "" }
local e178 = NewN "ImageLabel" { s178, Image = "" }
local s179 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e179 = NewN "UICorner" { s179, CornerRadius = UDim.new(0, 4) }
local s180 = SpreadC "Frame" { Visible = true }
local e180 = NewN "Frame" { s180, Visible = true }
local s181 = SpreadC "TextLabel" { Text = "a" }
local e181 = NewN "TextLabel" { s181, Text = "a" }
local s182 = SpreadC "TextButton" { AutoButtonColor = false }
local e182 = NewN "TextButton" { s182, AutoButtonColor = false }
local s183 = SpreadC "ImageLabel" { Image = "" }
local e183 = NewN "ImageLabel" { s183, Image = "" }
local s184 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e184 = NewN "UICorner" { s184, CornerRadius = UDim.new(0, 4) }
local s185 = SpreadC "Frame" { Visible = true }
local e185 = NewN "Frame" { s185, Visible = true }
local s186 = SpreadC "TextLabel" { Text = "a" }
local e186 = NewN "TextLabel" { s186, Text = "a" }
local s187 = SpreadC "TextButton" { AutoButtonColor = false }
local e187 = NewN "TextButton" { s187, AutoButtonColor = false }
local s188 = SpreadC "ImageLabel" { Image = "" }
local e188 = NewN "ImageLabel" { s188, Image = "" }
local s189 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e189 = NewN "UICorner" { s189, CornerRadius = UDim.new(0, 4) }
local s190 = SpreadC "Frame" { Visible = true }
local e190 = NewN "Frame" { s190, Visible = true }
local s191 = SpreadC "TextLabel" { Text = "a" }
local e191 = NewN "TextLabel" { s191, Text = "a" }
local s192 = SpreadC "TextButton" { AutoButtonColor = false }
local e192 = NewN "TextButton" { s192, AutoButtonColor = false }
local s193 = SpreadC "ImageLabel" { Image = "" }
local e193 = NewN "ImageLabel" { s193, Image = "" }
local s194 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e194 = NewN "UICorner" { s194, CornerRadius = UDim.new(0, 4) }
local s195 = SpreadC "Frame" { Visible = true }
local e195 = NewN "Frame" { s195, Visible = true }
local s196 = SpreadC "TextLabel" { Text = "a" }
local e196 = NewN "TextLabel" { s196, Text = "a" }
local s197 = SpreadC "TextButton" { AutoButtonColor = false }
local e197 = NewN "TextButton" { s197, AutoButtonColor = false }
local s198 = SpreadC "ImageLabel" { Image = "" }
local e198 = NewN "ImageLabel" { s198, Image = "" }
local s199 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e199 = NewN "UICorner" { s199, CornerRadius = UDim.new(0, 4) }
local s200 = SpreadC "Frame" { Visible = true }
local e200 = NewN "Frame" { s200, Visible = true }
local s201 = SpreadC "TextLabel" { Text = "a" }
local e201 = NewN "TextLabel" { s201, Text = "a" }
local s202 = SpreadC "TextButton" { AutoButtonColor = false }
local e202 = NewN "TextButton" { s202, AutoButtonColor = false }
local s203 = SpreadC "ImageLabel" { Image = "" }
local e203 = NewN "ImageLabel" { s203, Image = "" }
local s204 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e204 = NewN "UICorner" { s204, CornerRadius = UDim.new(0, 4) }
local s205 = SpreadC "Frame" { Visible = true }
local e205 = NewN "Frame" { s205, Visible = true }
local s206 = SpreadC "TextLabel" { Text = "a" }
local e206 = NewN "TextLabel" { s206, Text = "a" }
local s207 = SpreadC "TextButton" { AutoButtonColor = false }
local e207 = NewN "TextButton" { s207, AutoButtonColor = false }
local s208 = SpreadC "ImageLabel" { Image = "" }
local e208 = NewN "ImageLabel" { s208, Image = "" }
local s209 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e209 = NewN "UICorner" { s209, CornerRadius = UDim.new(0, 4) }
local s210 = SpreadC "Frame" { Visible = true }
local e210 = NewN "Frame" { s210, Visible = true }
local s211 = SpreadC "TextLabel" { Text = "a" }
local e211 = NewN "TextLabel" { s211, Text = "a" }
local s212 = SpreadC "TextButton" { AutoButtonColor = false }
local e212 = NewN "TextButton" { s212, AutoButtonColor = false }
local s213 = SpreadC "ImageLabel" { Image = "" }
local e213 = NewN "ImageLabel" { s213, Image = "" }
local s214 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e214 = NewN "UICorner" { s214, CornerRadius = UDim.new(0, 4) }
local s215 = SpreadC "Frame" { Visible = true }
local e215 = NewN "Frame" { s215, Visible = true }
local s216 = SpreadC "TextLabel" { Text = "a" }
local e216 = NewN "TextLabel" { s216, Text = "a" }
local s217 = SpreadC "TextButton" { AutoButtonColor = false }
local e217 = NewN "TextButton" { s217, AutoButtonColor = false }
local s218 = SpreadC "ImageLabel" { Image = "" }
local e218 = NewN "ImageLabel" { s218, Image = "" }
local s219 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e219 = NewN "UICorner" { s219, CornerRadius = UDim.new(0, 4) }
local s220 = SpreadC "Frame" { Visible = true }
local e220 = NewN "Frame" { s220, Visible = true }
local s221 = SpreadC "TextLabel" { Text = "a" }
local e221 = NewN "TextLabel" { s221, Text = "a" }
local s222 = SpreadC "TextButton" { AutoButtonColor = false }
local e222 = NewN "TextButton" { s222, AutoButtonColor = false }
local s223 = SpreadC "ImageLabel" { Image = "" }
local e223 = NewN "ImageLabel" { s223, Image = "" }
local s224 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e224 = NewN "UICorner" { s224, CornerRadius = UDim.new(0, 4) }
local s225 = SpreadC "Frame" { Visible = true }
local e225 = NewN "Frame" { s225, Visible = true }
local s226 = SpreadC "TextLabel" { Text = "a" }
local e226 = NewN "TextLabel" { s226, Text = "a" }
local s227 = SpreadC "TextButton" { AutoButtonColor = false }
local e227 = NewN "TextButton" { s227, AutoButtonColor = false }
local s228 = SpreadC "ImageLabel" { Image = "" }
local e228 = NewN "ImageLabel" { s228, Image = "" }
local s229 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e229 = NewN "UICorner" { s229, CornerRadius = UDim.new(0, 4) }
local s230 = SpreadC "Frame" { Visible = true }
local e230 = NewN "Frame" { s230, Visible = true }
local s231 = SpreadC "TextLabel" { Text = "a" }
local e231 = NewN "TextLabel" { s231, Text = "a" }
local s232 = SpreadC "TextButton" { AutoButtonColor = false }
local e232 = NewN "TextButton" { s232, AutoButtonColor = false }
local s233 = SpreadC "ImageLabel" { Image = "" }
local e233 = NewN "ImageLabel" { s233, Image = "" }
local s234 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e234 = NewN "UICorner" { s234, CornerRadius = UDim.new(0, 4) }
local s235 = SpreadC "Frame" { Visible = true }
local e235 = NewN "Frame" { s235, Visible = true }
local s236 = SpreadC "TextLabel" { Text = "a" }
local e236 = NewN "TextLabel" { s236, Text = "a" }
local s237 = SpreadC "TextButton" { AutoButtonColor = false }
local e237 = NewN "TextButton" { s237, AutoButtonColor = false }
local s238 = SpreadC "ImageLabel" { Image = "" }
local e238 = NewN "ImageLabel" { s238, Image = "" }
local s239 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e239 = NewN "UICorner" { s239, CornerRadius = UDim.new(0, 4) }
local s240 = SpreadC "Frame" { Visible = true }
local e240 = NewN "Frame" { s240, Visible = true }
local s241 = SpreadC "TextLabel" { Text = "a" }
local e241 = NewN "TextLabel" { s241, Text = "a" }
local s242 = SpreadC "TextButton" { AutoButtonColor = false }
local e242 = NewN "TextButton" { s242, AutoButtonColor = false }
local s243 = SpreadC "ImageLabel" { Image = "" }
local e243 = NewN "ImageLabel" { s243, Image = "" }
local s244 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e244 = NewN "UICorner" { s244, CornerRadius = UDim.new(0, 4) }
local s245 = SpreadC "Frame" { Visible = true }
local e245 = NewN "Frame" { s245, Visible = true }
local s246 = SpreadC "TextLabel" { Text = "a" }
local e246 = NewN "TextLabel" { s246, Text = "a" }
local s247 = SpreadC "TextButton" { AutoButtonColor = false }
local e247 = NewN "TextButton" { s247, AutoButtonColor = false }
local s248 = SpreadC "ImageLabel" { Image = "" }
local e248 = NewN "ImageLabel" { s248, Image = "" }
local s249 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e249 = NewN "UICorner" { s249, CornerRadius = UDim.new(0, 4) }
local s250 = SpreadC "Frame" { Visible = true }
local e250 = NewN "Frame" { s250, Visible = true }
local s251 = SpreadC "TextLabel" { Text = "a" }
local e251 = NewN "TextLabel" { s251, Text = "a" }
local s252 = SpreadC "TextButton" { AutoButtonColor = false }
local e252 = NewN "TextButton" { s252, AutoButtonColor = false }
local s253 = SpreadC "ImageLabel" { Image = "" }
local e253 = NewN "ImageLabel" { s253, Image = "" }
local s254 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e254 = NewN "UICorner" { s254, CornerRadius = UDim.new(0, 4) }
local s255 = SpreadC "Frame" { Visible = true }
local e255 = NewN "Frame" { s255, Visible = true }
local s256 = SpreadC "TextLabel" { Text = "a" }
local e256 = NewN "TextLabel" { s256, Text = "a" }
local s257 = SpreadC "TextButton" { AutoButtonColor = false }
local e257 = NewN "TextButton" { s257, AutoButtonColor = false }
local s258 = SpreadC "ImageLabel" { Image = "" }
local e258 = NewN "ImageLabel" { s258, Image = "" }
local s259 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e259 = NewN "UICorner" { s259, CornerRadius = UDim.new(0, 4) }
local s260 = SpreadC "Frame" { Visible = true }
local e260 = NewN "Frame" { s260, Visible = true }
local s261 = SpreadC "TextLabel" { Text = "a" }
local e261 = NewN "TextLabel" { s261, Text = "a" }
local s262 = SpreadC "TextButton" { AutoButtonColor = false }
local e262 = NewN "TextButton" { s262, AutoButtonColor = false }
local s263 = SpreadC "ImageLabel" { Image = "" }
local e263 = NewN "ImageLabel" { s263, Image = "" }
local s264 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e264 = NewN "UICorner" { s264, CornerRadius = UDim.new(0, 4) }
local s265 = SpreadC "Frame" { Visible = true }
local e265 = NewN "Frame" { s265, Visible = true }
local s266 = SpreadC "TextLabel" { Text = "a" }
local e266 = NewN "TextLabel" { s266, Text = "a" }
local s267 = SpreadC "TextButton" { AutoButtonColor = false }
local e267 = NewN "TextButton" { s267, AutoButtonColor = false }
local s268 = SpreadC "ImageLabel" { Image = "" }
local e268 = NewN "ImageLabel" { s268, Image = "" }
local s269 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e269 = NewN "UICorner" { s269, CornerRadius = UDim.new(0, 4) }
local s270 = SpreadC "Frame" { Visible = true }
local e270 = NewN "Frame" { s270, Visible = true }
local s271 = SpreadC "TextLabel" { Text = "a" }
local e271 = NewN "TextLabel" { s271, Text = "a" }
local s272 = SpreadC "TextButton" { AutoButtonColor = false }
local e272 = NewN "TextButton" { s272, AutoButtonColor = false }
local s273 = SpreadC "ImageLabel" { Image = "" }
local e273 = NewN "ImageLabel" { s273, Image = "" }
local s274 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e274 = NewN "UICorner" { s274, CornerRadius = UDim.new(0, 4) }
local s275 = SpreadC "Frame" { Visible = true }
local e275 = NewN "Frame" { s275, Visible = true }
local s276 = SpreadC "TextLabel" { Text = "a" }
local e276 = NewN "TextLabel" { s276, Text = "a" }
local s277 = SpreadC "TextButton" { AutoButtonColor = false }
local e277 = NewN "TextButton" { s277, AutoButtonColor = false }
local s278 = SpreadC "ImageLabel" { Image = "" }
local e278 = NewN "ImageLabel" { s278, Image = "" }
local s279 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e279 = NewN "UICorner" { s279, CornerRadius = UDim.new(0, 4) }
local s280 = SpreadC "Frame" { Visible = true }
local e280 = NewN "Frame" { s280, Visible = true }
local s281 = SpreadC "TextLabel" { Text = "a" }
local e281 = NewN "TextLabel" { s281, Text = "a" }
local s282 = SpreadC "TextButton" { AutoButtonColor = false }
local e282 = NewN "TextButton" { s282, AutoButtonColor = false }
local s283 = SpreadC "ImageLabel" { Image = "" }
local e283 = NewN "ImageLabel" { s283, Image = "" }
local s284 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e284 = NewN "UICorner" { s284, CornerRadius = UDim.new(0, 4) }
local s285 = SpreadC "Frame" { Visible = true }
local e285 = NewN "Frame" { s285, Visible = true }
local s286 = SpreadC "TextLabel" { Text = "a" }
local e286 = NewN "TextLabel" { s286, Text = "a" }
local s287 = SpreadC "TextButton" { AutoButtonColor = false }
local e287 = NewN "TextButton" { s287, AutoButtonColor = false }
local s288 = SpreadC "ImageLabel" { Image = "" }
local e288 = NewN "ImageLabel" { s288, Image = "" }
local s289 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e289 = NewN "UICorner" { s289, CornerRadius = UDim.new(0, 4) }
local s290 = SpreadC "Frame" { Visible = true }
local e290 = NewN "Frame" { s290, Visible = true }
local s291 = SpreadC "TextLabel" { Text = "a" }
local e291 = NewN "TextLabel" { s291, Text = "a" }
local s292 = SpreadC "TextButton" { AutoButtonColor = false }
local e292 = NewN "TextButton" { s292, AutoButtonColor = false }
local s293 = SpreadC "ImageLabel" { Image = "" }
local e293 = NewN "ImageLabel" { s293, Image = "" }
local s294 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e294 = NewN "UICorner" { s294, CornerRadius = UDim.new(0, 4) }
local s295 = SpreadC "Frame" { Visible = true }
local e295 = NewN "Frame" { s295, Visible = true }
local s296 = SpreadC "TextLabel" { Text = "a" }
local e296 = NewN "TextLabel" { s296, Text = "a" }
local s297 = SpreadC "TextButton" { AutoButtonColor = false }
local e297 = NewN "TextButton" { s297, AutoButtonColor = false }
local s298 = SpreadC "ImageLabel" { Image = "" }
local e298 = NewN "ImageLabel" { s298, Image = "" }
local s299 = SpreadC "UICorner" { CornerRadius = UDim.new(0, 4) }
local e299 = NewN "UICorner" { s299, CornerRadius = UDim.new(0, 4) }
local BAD1 = NewN "Frame" { Visible = 5 }
local BAD2 = NewN "TextLabel" { Text = 42 }
return { BAD1, BAD2 }
