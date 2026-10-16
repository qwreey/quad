--!strict
-- [2026-10-16] q = Quad & Ext where Ext carries type-function-typed members (user question: does q stay sound?)
local QT = require("../../../../../../quad-types/src")
local L = require("../../../src/Lib")
type CreatableMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel }
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel, GuiObject: GuiObject, GuiButton: GuiButton, GuiBase2d: GuiBase2d, GuiLabel: GuiLabel, Instance: Instance }
export type SpreadAcc<K, C> = { read __quadSpread: K, Add: (self: SpreadAcc<K, C>, props: L.Props<C>) -> SpreadAcc<K, C> }
export type Ext = {
	Elem: <K>(name: K & keyof<CreatableMap>) -> (L.Props<index<CreatableMap, K>>) -> index<CreatableMap, K>,
	Spread: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> SpreadAcc<K, index<ClassMap, K>>,
	Modifier: <K>(name: K & keyof<ClassMap>) -> (...any) -> L.Modifier<index<ClassMap, K>>,
	Mapper: <K>(name: K & keyof<CreatableMap>) -> (key: string | L.MapperRootKey) -> (L.MapperProps<index<CreatableMap, K>>) -> L.MapperDescriptor,
	OnEvent: <K>(name: K & keyof<L.EventMap>) -> (fn: index<L.EventMap, K>) -> L.EventDesc<K>,
}
export type Q = QT.Quad & Ext
return {}
