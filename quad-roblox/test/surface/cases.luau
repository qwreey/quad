--!strict
--[[
	3.4.0 typed surface — the gate fixture `scripts/surface-gate.py` analyzes (not a spec: never run).
	Every NEG-marked line must get a diagnostic on that line and no other line may get one; OK-marked lines
	document the positives. The built-in surface (`Surface.BuiltinSurface`) and `q.ForClasses` are typed here before
	any runtime exists (`.claude/research/release-3.4.0-plan.md` 단위 2).
]]

local QuadTypes = require("../../luau_packages/quad_types")
local Surface = require("../../src/Surface")
local q = (nil :: any) :: Surface.BuiltinSurface & {
	ForClasses: Surface.ForClasses,
	Source: <T>(v: T) -> QuadTypes.Source<T>,
	None: QuadTypes.None,
}

local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local TextButton = q.Elem "TextButton"
local ScrollingFrame = q.Elem "ScrollingFrame"
local FrameModifier = q.Modifier "Frame"
local GuiModifier = q.Modifier "GuiObject"
local LabelModifier = q.Modifier "TextLabel"
local FrameSpread = q.Spread "Frame"
local GuiSpread = q.Spread "GuiObject"
local ButtonSpread = q.Spread "TextButton"

-- elements
local f1 = Frame { Size = UDim2.fromOffset(10, 10), Visible = true, TextLabel { Text = "x" } } -- OK
local f2 = Frame { Visible = 5 } -- NEG wrong value
local f3 = Frame { Text = "x" } -- NEG not a Frame member
local f4 = Frame { AbsoluteSize = Vector2.zero } -- NEG read-only
local f5 = Frame { Parent = f1 } -- NEG Parent is not a prop
local f6 = Frame { UICorner = 8, UIPadding = UDim.new(0, 4) } -- OK shorthand
local f7 = Frame { Transparency = 0.5 } -- OK legacy member injected
local l1 = TextLabel { FontSize = Enum.FontSize.Size14, TextWrap = true } -- OK legacy members injected
local e0 = q.Elem "GuiObject" -- NEG abstract class is not creatable
local e1 = q.Elem "Fraem" -- NEG unknown class name

-- Modifier
local m1 = FrameModifier():BackgroundTransparency(0.5):Size(UDim2.new()) -- OK
local m2 = FrameModifier():Visible(5) -- NEG setter value
local g1 = GuiModifier():AsFrame():BackgroundTransparency(0.1) -- OK checked down-cast
local f8 = Frame { m1, g1, GuiModifier() } -- OK same class and ancestors
local f9 = Frame { LabelModifier() } -- NEG sibling-class Modifier

-- Spread
local s1 = FrameSpread { Visible = true, LayoutOrder = 1 }
s1:Append(GuiSpread { ZIndex = 2 }) -- OK ancestor Spread
s1:Append(ButtonSpread {}) -- NEG sibling Spread into :Append
local r1 = s1:Append(GuiSpread {}) -- NEG :Append returns nothing
local s2 = FrameSpread { Visible = "x" } -- NEG Spread value
local f10 = Frame { s1, GuiSpread { Active = true } } -- OK
local l2 = TextLabel { ButtonSpread {} } -- NEG sibling Spread on an element

-- descriptors
local FrameOnEvent = q.OnEvent "Frame"
local f11 = Frame {
	FrameOnEvent "MouseEnter" (function(x, y) local _n: number = x + y end), -- OK callback typed from the class
	q.OnChange "Frame" "AbsoluteSize" (function(v) local _w: number = v.X end), -- OK read surface keeps ReadOnly
}
local d1 = FrameOnEvent "MouseEnterr" (function() end) -- NEG event name
local d2 = q.OnChange "Frame" "Visible" (function(v) local _s: string = v end) -- NEG callback type
local canvas = q.Source(UDim2.new())
local sf1 = ScrollingFrame { q.Out "ScrollingFrame" "CanvasSize" (canvas) } -- OK
local d3 = q.Out "ScrollingFrame" "CanvasSize" (q.Source(5)) -- NEG Out source type

-- Mapper
local mp = q.Mapper "Frame" ("Card") { Visible = true } -- OK
local mp2 = q.Mapper "Frame" ("Card") { Visible = 1 } -- NEG mapper prop value

-- component input positions
type CardProps = { Modifier: Surface.ModifierInto<Frame>?, FieldSpread: Surface.SpreadInto<TextBox>? }
local function Card(props: CardProps)
	return Frame { props.Modifier or q.None, TextLabel {} }
end
local c1 = Card { Modifier = GuiModifier() } -- OK ancestor Modifier into ModifierInto<Frame>
local c2 = Card { Modifier = LabelModifier() } -- NEG sibling Modifier into ModifierInto<Frame>
local c3 = Card { FieldSpread = GuiSpread {} } -- OK
local c4 = Card { FieldSpread = ButtonSpread {} } -- NEG sibling Spread into SpreadInto<TextBox>

-- maps
local pm: index<Surface.PropertyMap<Frame>, "Size"> = UDim2.new() -- OK
local pm2: index<Surface.PropertyMap<Frame>, "Size"> = 5 -- NEG

-- the escape: the user's own class map
type World = { Part: Part, BasePart: BasePart, Beam: Beam }
local W = q.ForClasses<<World>>()
local Part = W.Elem "Part"
local p1 = Part { Anchored = true, Size = Vector3.one, Position = Vector3.zero, Shape = Enum.PartType.Ball } -- OK
local p2 = Part { Anchored = 5 } -- NEG
local p3 = Part { AssemblyMass = 1 } -- NEG read-only
local bp = W.Modifier "BasePart" ()
local bs = W.Spread "BasePart" { CanCollide = false }
local p4 = Part { bp, bs, W.OnEvent "Part" "Touched" (function(hit) local _p: BasePart = hit end) } -- OK
local p5 = W.Elem "Frame" -- NEG not in the user map
local p6 = Frame { bs } -- NEG a BasePart Spread on a Frame

return {}
