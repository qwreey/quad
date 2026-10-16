--!strict
-- [2026-10-16] q.Declaration rebuilt from type functions, same scope as the generated D (31 ctors, 47 Modifiers, 31 Mappers).
-- Question (plan 4절 2번): can the library ship a ready-made D this way without the Studio collapse the generated D shows?
local L = require("../../../src/Lib")
type CreatableMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel }
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, GuiBase: GuiBase, GuiBase2d: GuiBase2d, GuiButton: GuiButton, GuiLabel: GuiLabel, GuiObject: GuiObject, ImageButton: ImageButton, ImageLabel: ImageLabel, Instance: Instance, LayerCollector: LayerCollector, Model: Model, PVInstance: PVInstance, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, SurfaceGuiBase: SurfaceGuiBase, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UIBase: UIBase, UIComponent: UIComponent, UIConstraint: UIConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIGridStyleLayout: UIGridStyleLayout, UILayout: UILayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel, WorldRoot: WorldRoot }
local Elem = (nil :: any) :: <K>(name: K & keyof<CreatableMap>) -> (L.Props<index<CreatableMap, K>>) -> index<CreatableMap, K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (...any) -> L.Modifier<index<ClassMap, K>>
local Mapper = (nil :: any) :: <K>(name: K & keyof<CreatableMap>) -> (key: string | L.MapperRootKey) -> (L.MapperProps<index<CreatableMap, K>>) -> L.MapperDescriptor
local D = {

	Modifier = {
		BillboardGui = Modifier "BillboardGui",
		Camera = Modifier "Camera",
		CanvasGroup = Modifier "CanvasGroup",
		Folder = Modifier "Folder",
		Frame = Modifier "Frame",
		GuiBase = Modifier "GuiBase",
		GuiBase2d = Modifier "GuiBase2d",
		GuiButton = Modifier "GuiButton",
		GuiLabel = Modifier "GuiLabel",
		GuiObject = Modifier "GuiObject",
		ImageButton = Modifier "ImageButton",
		ImageLabel = Modifier "ImageLabel",
		Instance = Modifier "Instance",
		LayerCollector = Modifier "LayerCollector",
		Model = Modifier "Model",
		PVInstance = Modifier "PVInstance",
		ScreenGui = Modifier "ScreenGui",
		ScrollingFrame = Modifier "ScrollingFrame",
		SurfaceGui = Modifier "SurfaceGui",
		SurfaceGuiBase = Modifier "SurfaceGuiBase",
		TextBox = Modifier "TextBox",
		TextButton = Modifier "TextButton",
		TextLabel = Modifier "TextLabel",
		UIAspectRatioConstraint = Modifier "UIAspectRatioConstraint",
		UIBase = Modifier "UIBase",
		UIComponent = Modifier "UIComponent",
		UIConstraint = Modifier "UIConstraint",
		UICorner = Modifier "UICorner",
		UIDragDetector = Modifier "UIDragDetector",
		UIFlexItem = Modifier "UIFlexItem",
		UIGradient = Modifier "UIGradient",
		UIGridLayout = Modifier "UIGridLayout",
		UIGridStyleLayout = Modifier "UIGridStyleLayout",
		UILayout = Modifier "UILayout",
		UIListLayout = Modifier "UIListLayout",
		UIPadding = Modifier "UIPadding",
		UIPageLayout = Modifier "UIPageLayout",
		UIScale = Modifier "UIScale",
		UIShadow = Modifier "UIShadow",
		UISizeConstraint = Modifier "UISizeConstraint",
		UIStroke = Modifier "UIStroke",
		UITableLayout = Modifier "UITableLayout",
		UITextSizeConstraint = Modifier "UITextSizeConstraint",
		VideoFrame = Modifier "VideoFrame",
		ViewportFrame = Modifier "ViewportFrame",
		WorldModel = Modifier "WorldModel",
		WorldRoot = Modifier "WorldRoot",
	},
}
return D
