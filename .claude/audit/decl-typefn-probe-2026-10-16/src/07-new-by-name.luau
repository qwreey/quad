--!strict
-- [2026-10-16] Can the class come from the NAME alone? `New("Frame")` with K & keyof<ClassMap>, C = index<ClassMap, K>.
-- Studio(2026-10-16, studio-analysis, 4-class map): diagnostics identical to CLI vsc. If this works the surface needs no duplicated `<<Frame>>("Frame")`.
local L = require("./Lib")
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel }
local NewN = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> index<ClassMap, K>
local Frame = NewN("Frame") -- @h(byname-ctor) at='Frame = '
local TextLabel = NewN("TextLabel")
local Typo = NewN("Fraem") -- should error
local ok1 = Frame({ BackgroundColor3 = Color3.new(1, 1, 1) }) -- @c(byname-Back) at='Frame({ ' ins='Back'
local ok2 = TextLabel({ Text = "hi" }) -- @h(byname-ok2) at='ok2'
local bad1 = Frame({ Visible = 5 }) -- should error
local bad2 = TextLabel({ Text = 42 }) -- should error
local bad3 = Frame({ Text = "x" }) -- should error (not a Frame prop)
local inline = NewN("Frame")({ Visible = 5 }) -- should error (inline use)
local nm = NewN("Frame") -- @c(byname-name) at='NewN("' ins='Te'
return { Frame, TextLabel, Typo, ok1, ok2, bad1, bad2, bad3, inline, nm }
