--!strict
-- [2026-10-16] accumulating Spread: the marker gains `:Add(props)` (Modifier-like value) — placement / completion / cost
local L = require("../../src/Lib")
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel, GuiObject: GuiObject, GuiButton: GuiButton, GuiBase2d: GuiBase2d }
local NewN = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> index<ClassMap, K>
type SpreadAcc<K, C> = { read __quadSpread: K, Add: (self: SpreadAcc<K, C>, props: L.Props<C>) -> SpreadAcc<K, C> }
local SpreadA = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> SpreadAcc<K, index<ClassMap, K>>
local Frame = NewN "Frame"
local TextButton = NewN "TextButton"
local GuiSpread = SpreadA "GuiObject"
local FrameSpread = SpreadA "Frame"
local s = GuiSpread { BackgroundTransparency = 0.5 }
s:Add { Visible = true } -- @c(add-Back) at='s:Add { ' ins='Back'
local chained = FrameSpread {}:Add { Visible = true }:Add { Style = Enum.FrameStyle.Custom } -- @h(acc-hover) at='chained ='
local okF = Frame { s, chained }
local okB = TextButton { s }
local bad1 = s:Add { Visible = 5 } -- should error
local bad2 = s:Add { Text = "x" } -- should error: not a GuiObject prop
local bad3 = TextButton { chained } -- should error: Frame spread into TextButton
return { s, chained, okF, okB, bad1, bad2, bad3 }
