--!strict
-- [2026-10-16] Claim/Mapper axis by name: `Mapper "Frame"` -> (key) -> (props) -> MapperDescriptor.
-- Props reuse Build with MapperPolicy (Child adds MapperDescriptor). Compare with generated `D.Mapper.Frame(key)(props)`.
local L = require("./Lib")
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel }
local NewN = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> index<ClassMap, K>
local MapperN = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (key: string | L.MapperRootKey) -> (L.MapperProps<index<ClassMap, K>>) -> L.MapperDescriptor
local Root = (nil :: any) :: L.MapperRootKey
local Claim = (nil :: any) :: <T>(inst: T, desc: L.MapperDescriptor) -> T

local MFrame = MapperN "Frame"
local MLabel = MapperN "TextLabel"
local Frame = NewN "Frame"

local template = (nil :: any) :: Frame
local ok = Claim(template, MFrame(Root)({
	BackgroundTransparency = 0.25,
	MLabel "Title" { Text = "hi" },
	MFrame "List" {
		MLabel "Inner" { TextSize = 18 },
	},
	Frame { Visible = true }, -- a new child inside a claimed tree is still fine
}))
local hoverOk = ok -- @h(mapper-claim) at='ok -- @h'
local inl = MapperN "TextLabel" "Sub" { Text = "inline" } -- @c(mapper-inline-Te) at='"Sub" { ' ins='Te'
local bad1 = MFrame "X" { Visible = 5 } -- @c(mapper-Back) at='MFrame "X" { ' ins='Back' (should error)
local bad2 = MLabel "X" { Text = 42 } -- should error
local bad3 = Frame { MLabel "X" {} } -- should error: mapper descriptor in a NEW element
local bad4 = MapperN "Fraem" -- should error
local bad5 = MFrame(5) -- should error: key must be string | Root
return { ok, hoverOk, inl, bad1, bad2, bad3, bad4, bad5 }
