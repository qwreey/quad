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
local BAD1 = NewN "Frame" { Visible = 5 }
local BAD2 = NewN "TextLabel" { Text = 42 }
return { BAD1, BAD2 }
