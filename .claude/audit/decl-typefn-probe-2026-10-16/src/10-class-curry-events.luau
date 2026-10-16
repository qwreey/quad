--!strict
-- [2026-10-16] class-first curry for OnEvent / OnChange: `OnEvent "Frame" "MouseEnter" (function(x, y) … end)`.
-- G = generic second call (K & keyof<Events<C>>, index<>), O = overloaded second call (intersection, one per name — picked by the literal).
local L = require("./Lib")
type ClassMap = { BillboardGui: BillboardGui, Camera: Camera, CanvasGroup: CanvasGroup, Folder: Folder, Frame: Frame, ImageButton: ImageButton, ImageLabel: ImageLabel, ScreenGui: ScreenGui, ScrollingFrame: ScrollingFrame, SurfaceGui: SurfaceGui, TextBox: TextBox, TextButton: TextButton, TextLabel: TextLabel, UIAspectRatioConstraint: UIAspectRatioConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout, UITextSizeConstraint: UITextSizeConstraint, VideoFrame: VideoFrame, ViewportFrame: ViewportFrame, WorldModel: WorldModel, GuiObject: GuiObject, GuiButton: GuiButton }
type CM<K> = index<ClassMap, K>
local OnEventG = (nil :: any) :: <C0>(class: C0 & keyof<ClassMap>) -> <K>(name: K & keyof<L.Events<CM<C0>>>) -> (fn: index<L.Events<CM<C0>>, K>) -> L.EventDesc<K>
local OnEventO = (nil :: any) :: <C0>(class: C0 & keyof<ClassMap>) -> L.EventOverloads<CM<C0>>
local OnChangeG = (nil :: any) :: <C0>(class: C0 & keyof<ClassMap>) -> <K>(name: K & keyof<L.PropMap<CM<C0>>>) -> (fn: (index<L.PropMap<CM<C0>>, K>) -> ()) -> L.ChangeDesc<K>
local OnChangeO = (nil :: any) :: <C0>(class: C0 & keyof<ClassMap>) -> L.ChangeOverloads<CM<C0>>

local FrameEventG = OnEventG "Frame"
local FrameEventO = OnEventO "Frame"
local ButtonEventO = OnEventO "TextButton"
local FrameChangeG = OnChangeG "Frame"
local FrameChangeO = OnChangeO "Frame"

-- (a) contextual typing reaches the unannotated callback: body misuse must be caught AT THE BODY LINE
local g1 = FrameEventG "MouseEnter" (function(x, y) -- @h(g-x) at='x, y'
	local s: string = x -- should error (x: number)
end)
local o1 = FrameEventO "MouseEnter" (function(x, y) -- @h(o-x) at='x, y'
	local s: string = x -- should error (x: number)
end)
local o2 = ButtonEventO "Activated" (function(input, count)
	local _ = input.UserInputType -- @c(o-input) at='input.' ins='User'
end)
local c1 = FrameChangeG "Visible" (function(v) -- @h(cg-v) at='v)'
	local s: string = v -- should error (v: boolean)
end)
local c2 = FrameChangeO "Visible" (function(v) -- @h(co-v) at='v)'
	local s: string = v -- should error (v: boolean)
end)
-- (b) name completion inside the second call's quotes
local nG = FrameEventG "MouseLeave" (function() end) -- @c(g-name) at='FrameEventG "' ins='Mouse'
local nO = FrameEventO "MouseLeave" (function() end) -- @c(o-name) at='FrameEventO "' ins='Mouse'
-- (c) wrong names for the class
local bG = FrameEventG "Activated" (function() end) -- should error: not a Frame event
local bO = FrameEventO "Activated" (function() end) -- should error
local bC = FrameChangeO "Text" (function(v) end) -- should error: not a Frame prop
-- (d) inline, no hoist
local inl = OnEventO "Frame" "MouseMoved" (function(x, y) local s: string = y end) -- should error at body
return { g1, o1, o2, c1, c2, nG, nO, bG, bO, bC, inl }
