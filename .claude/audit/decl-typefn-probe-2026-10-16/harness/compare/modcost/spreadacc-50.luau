--!strict
-- [2026-10-16] accumulating Spread: the marker gains `:Add(props)` (Modifier-like value) — placement / completion / cost
local L = require("../../../src/Lib")
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel, GuiObject: GuiObject, GuiButton: GuiButton, GuiBase2d: GuiBase2d }
local NewN = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> index<ClassMap, K>
type SpreadAcc<K, C> = { read __quadSpread: K, Add: (self: SpreadAcc<K, C>, props: L.Props<C>) -> SpreadAcc<K, C> }
local SpreadA = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> SpreadAcc<K, index<ClassMap, K>>
local Frame = NewN "Frame"
local TextButton = NewN "TextButton"
local GuiSpread = SpreadA "GuiObject"
local FrameSpread = SpreadA "Frame"
local s0 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e0 = Frame { s0, Size = UDim2.new() }
local s1 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e1 = Frame { s1, Size = UDim2.new() }
local s2 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e2 = Frame { s2, Size = UDim2.new() }
local s3 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e3 = Frame { s3, Size = UDim2.new() }
local s4 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e4 = Frame { s4, Size = UDim2.new() }
local s5 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e5 = Frame { s5, Size = UDim2.new() }
local s6 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e6 = Frame { s6, Size = UDim2.new() }
local s7 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e7 = Frame { s7, Size = UDim2.new() }
local s8 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e8 = Frame { s8, Size = UDim2.new() }
local s9 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e9 = Frame { s9, Size = UDim2.new() }
local s10 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e10 = Frame { s10, Size = UDim2.new() }
local s11 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e11 = Frame { s11, Size = UDim2.new() }
local s12 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e12 = Frame { s12, Size = UDim2.new() }
local s13 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e13 = Frame { s13, Size = UDim2.new() }
local s14 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e14 = Frame { s14, Size = UDim2.new() }
local s15 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e15 = Frame { s15, Size = UDim2.new() }
local s16 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.8 }
local e16 = Frame { s16, Size = UDim2.new() }
local s17 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.9 }
local e17 = Frame { s17, Size = UDim2.new() }
local s18 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.1 }
local e18 = Frame { s18, Size = UDim2.new() }
local s19 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.2 }
local e19 = Frame { s19, Size = UDim2.new() }
local s20 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.3 }
local e20 = Frame { s20, Size = UDim2.new() }
local s21 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.4 }
local e21 = Frame { s21, Size = UDim2.new() }
local s22 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.5 }
local e22 = Frame { s22, Size = UDim2.new() }
local s23 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.6 }
local e23 = Frame { s23, Size = UDim2.new() }
local s24 = GuiSpread { Visible = true }:Add { BackgroundTransparency = 0.7 }
local e24 = Frame { s24, Size = UDim2.new() }
return {}
