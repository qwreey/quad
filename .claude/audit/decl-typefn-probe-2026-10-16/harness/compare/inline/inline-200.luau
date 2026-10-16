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
local BAD1 = NewN "Frame" { Visible = 5 }
local BAD2 = NewN "TextLabel" { Text = 42 }
return { BAD1, BAD2 }
