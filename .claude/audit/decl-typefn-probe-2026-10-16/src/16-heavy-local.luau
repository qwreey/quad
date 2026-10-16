--!strict
-- [2026-10-16] the full D amount (31 ctors + 47 Modifiers) hoisted INSIDE one file, not exported — contrast with 11/12 (exported: Studio silent, CLI too complex)
-- [2026-10-16] q.Declaration rebuilt from type functions, same scope as the generated D (31 ctors, 47 Modifiers, 31 Mappers).
-- Question (plan 4절 2번): can the library ship a ready-made D this way without the Studio collapse the generated D shows?
local L = require("./Lib")
type CreatableMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel }
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, GuiBase: GuiBase, GuiBase2d: GuiBase2d, GuiButton: GuiButton, GuiLabel: GuiLabel, GuiObject: GuiObject, ImageButton: ImageButton, ImageLabel: ImageLabel, Instance: Instance, LayerCollector: LayerCollector, Model: Model, PVInstance: PVInstance, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, SurfaceGuiBase: SurfaceGuiBase, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UIBase: UIBase, UIComponent: UIComponent, UIConstraint: UIConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIGridStyleLayout: UIGridStyleLayout, UILayout: UILayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel, WorldRoot: WorldRoot }
local Elem = (nil :: any) :: <K>(name: K & keyof<CreatableMap>) -> (L.Props<index<CreatableMap, K>>) -> index<CreatableMap, K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (...any) -> L.Modifier<index<ClassMap, K>>
local Mapper = (nil :: any) :: <K>(name: K & keyof<CreatableMap>) -> (key: string | L.MapperRootKey) -> (L.MapperProps<index<CreatableMap, K>>) -> L.MapperDescriptor
local BillboardGui = Elem "BillboardGui"
local Camera = Elem "Camera"
local CanvasGroup = Elem "CanvasGroup"
local Folder = Elem "Folder"
local Frame = Elem "Frame"
local ImageButton = Elem "ImageButton"
local ImageLabel = Elem "ImageLabel"
local ScreenGui = Elem "ScreenGui"
local ScrollingFrame = Elem "ScrollingFrame"
local SurfaceGui = Elem "SurfaceGui"
local TextBox = Elem "TextBox"
local TextButton = Elem "TextButton"
local TextLabel = Elem "TextLabel"
local UIAspectRatioConstraint = Elem "UIAspectRatioConstraint"
local UICorner = Elem "UICorner"
local UIDragDetector = Elem "UIDragDetector"
local UIFlexItem = Elem "UIFlexItem"
local UIGradient = Elem "UIGradient"
local UIGridLayout = Elem "UIGridLayout"
local UIListLayout = Elem "UIListLayout"
local UIPadding = Elem "UIPadding"
local UIPageLayout = Elem "UIPageLayout"
local UIScale = Elem "UIScale"
local UIShadow = Elem "UIShadow"
local UISizeConstraint = Elem "UISizeConstraint"
local UIStroke = Elem "UIStroke"
local UITableLayout = Elem "UITableLayout"
local UITextSizeConstraint = Elem "UITextSizeConstraint"
local VideoFrame = Elem "VideoFrame"
local ViewportFrame = Elem "ViewportFrame"
local WorldModel = Elem "WorldModel"
local BillboardGuiModifier = Modifier "BillboardGui"
local CameraModifier = Modifier "Camera"
local CanvasGroupModifier = Modifier "CanvasGroup"
local FolderModifier = Modifier "Folder"
local FrameModifier = Modifier "Frame"
local GuiBaseModifier = Modifier "GuiBase"
local GuiBase2dModifier = Modifier "GuiBase2d"
local GuiButtonModifier = Modifier "GuiButton"
local GuiLabelModifier = Modifier "GuiLabel"
local GuiObjectModifier = Modifier "GuiObject"
local ImageButtonModifier = Modifier "ImageButton"
local ImageLabelModifier = Modifier "ImageLabel"
local InstanceModifier = Modifier "Instance"
local LayerCollectorModifier = Modifier "LayerCollector"
local ModelModifier = Modifier "Model"
local PVInstanceModifier = Modifier "PVInstance"
local ScreenGuiModifier = Modifier "ScreenGui"
local ScrollingFrameModifier = Modifier "ScrollingFrame"
local SurfaceGuiModifier = Modifier "SurfaceGui"
local SurfaceGuiBaseModifier = Modifier "SurfaceGuiBase"
local TextBoxModifier = Modifier "TextBox"
local TextButtonModifier = Modifier "TextButton"
local TextLabelModifier = Modifier "TextLabel"
local UIAspectRatioConstraintModifier = Modifier "UIAspectRatioConstraint"
local UIBaseModifier = Modifier "UIBase"
local UIComponentModifier = Modifier "UIComponent"
local UIConstraintModifier = Modifier "UIConstraint"
local UICornerModifier = Modifier "UICorner"
local UIDragDetectorModifier = Modifier "UIDragDetector"
local UIFlexItemModifier = Modifier "UIFlexItem"
local UIGradientModifier = Modifier "UIGradient"
local UIGridLayoutModifier = Modifier "UIGridLayout"
local UIGridStyleLayoutModifier = Modifier "UIGridStyleLayout"
local UILayoutModifier = Modifier "UILayout"
local UIListLayoutModifier = Modifier "UIListLayout"
local UIPaddingModifier = Modifier "UIPadding"
local UIPageLayoutModifier = Modifier "UIPageLayout"
local UIScaleModifier = Modifier "UIScale"
local UIShadowModifier = Modifier "UIShadow"
local UISizeConstraintModifier = Modifier "UISizeConstraint"
local UIStrokeModifier = Modifier "UIStroke"
local UITableLayoutModifier = Modifier "UITableLayout"
local UITextSizeConstraintModifier = Modifier "UITextSizeConstraint"
local VideoFrameModifier = Modifier "VideoFrame"
local ViewportFrameModifier = Modifier "ViewportFrame"
local WorldModelModifier = Modifier "WorldModel"
local WorldRootModifier = Modifier "WorldRoot"
local e0 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t0" }, UICorner { CornerRadius = UDim.new(0, 0) } }
local e1 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t1" }, UICorner { CornerRadius = UDim.new(0, 1) } }
local e2 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t2" }, UICorner { CornerRadius = UDim.new(0, 2) } }
local e3 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t3" }, UICorner { CornerRadius = UDim.new(0, 3) } }
local e4 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t4" }, UICorner { CornerRadius = UDim.new(0, 4) } }
local e5 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t5" }, UICorner { CornerRadius = UDim.new(0, 5) } }
local e6 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t6" }, UICorner { CornerRadius = UDim.new(0, 6) } }
local e7 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t7" }, UICorner { CornerRadius = UDim.new(0, 7) } }
local e8 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t8" }, UICorner { CornerRadius = UDim.new(0, 8) } }
local e9 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t9" }, UICorner { CornerRadius = UDim.new(0, 9) } }
local e10 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t10" }, UICorner { CornerRadius = UDim.new(0, 10) } }
local e11 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t11" }, UICorner { CornerRadius = UDim.new(0, 11) } }
local e12 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t12" }, UICorner { CornerRadius = UDim.new(0, 12) } }
local e13 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t13" }, UICorner { CornerRadius = UDim.new(0, 13) } }
local e14 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t14" }, UICorner { CornerRadius = UDim.new(0, 14) } }
local e15 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t15" }, UICorner { CornerRadius = UDim.new(0, 15) } }
local e16 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t16" }, UICorner { CornerRadius = UDim.new(0, 16) } }
local e17 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t17" }, UICorner { CornerRadius = UDim.new(0, 17) } }
local e18 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t18" }, UICorner { CornerRadius = UDim.new(0, 18) } }
local e19 = Frame { GuiObjectModifier():Visible(true), TextLabel { Text = "t19" }, UICorner { CornerRadius = UDim.new(0, 19) } }
local BAD = TextLabel { Text = 42 }
return { e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, e13, e14, e15, e16, e17, e18, e19, BAD }
