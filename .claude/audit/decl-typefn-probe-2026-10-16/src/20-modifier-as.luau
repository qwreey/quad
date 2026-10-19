--!strict
-- [2026-10-19 Studio copy of harness/compare/modfull/use.luau — same lines; requires rewritten to the Studio tree (probe.project.json). CLI results: that file.]
-- [2026-10-19 M3] Modifier<C> with As*/ModifierInto/Overridden/shorthand setters (Lib2), reproducing the kit's Modifier forms
-- (grep of quad-roblox-devui / quad-roblox-material: `D.Modifier.<C>():Name(..)` module-level, setter chains, stored base modifier
-- re-chained, `Modifier: <C>Modifier?` props spliced as `props.Modifier or q.None`, `Modifier: IntoGuiObject?` +
-- `props.Modifier:AsGuiObject():AsTextButton()`, `D.Modifier.GuiObject():Size(..):AutomaticSize(..)` returned from a helper).
local L = require("./Lib2")
type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>
local Elem = (nil :: any) :: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> L.Modifier<CM<K>>
local None = (nil :: any) :: L.None

local Frame = Elem "Frame"
local TextButton = Elem "TextButton"
local TextLabel = Elem "TextLabel"
local UIListLayout = Elem "UIListLayout"
local FrameModifier = Modifier "Frame" -- @h(m3-factory) at='FrameModifier ='
local TextButtonModifier = Modifier "TextButton"
local TextLabelModifier = Modifier "TextLabel"
local TextBoxModifier = Modifier "TextBox"
local GuiObjectModifier = Modifier "GuiObject"

-- kit form 1: module-level named base modifiers
local windowName = FrameModifier():Name("Window") -- @h(m3-value) at='windowName =' OK
local buttonName = TextButtonModifier():Name("Button") -- OK
local fieldName = TextBoxModifier():Name("Field") -- OK
-- kit form 2: setter chains (methods the kits actually call)
local tabs = FrameModifier():Size(UDim2.new(1, 0, 0, 48)):AnchorPoint(Vector2.new(0.5, 1)):Position(UDim2.new(0.5, 0, 1, -16)) -- OK
local base = FrameModifier():BackgroundTransparency(1):BorderSizePixel(0):LayoutOrder(2):AutomaticSize(Enum.AutomaticSize.Y):ClipsDescendants(true):ZIndex(2) -- OK
local tip = TextLabelModifier():AutomaticSize(Enum.AutomaticSize.XY):BorderSizePixel(0):TextWrapped(true):FontFace(Font.new("x")):TextSize(14):LineHeight(1.2):TextXAlignment(Enum.TextXAlignment.Left) -- OK
local btn = TextButtonModifier():AutoButtonColor(false):Text("x"):Position(UDim2.fromOffset(16, 16)) -- OK
local m = FrameModifier():Visible(true) -- @c(m3-dot) at='FrameModifier():' ins='Bor'
local gAs = GuiObjectModifier():Size(UDim2.new()) -- @c(m3-as) at='GuiObjectModifier():' ins='As'
-- kit form 3: stored base modifier re-chained later
local sized = base:Size(UDim2.new(1, 0, 0, 10)) -- OK
-- kit form 4: component props typed Modifier<C>? spliced into the element
type ButtonProps = { read Modifier: L.Modifier<TextButton>?, read Text: string }
local function Button(props: ButtonProps) return TextButton { buttonName, props.Modifier or None, Text = props.Text } end -- OK
local b1 = Button({ Text = "a", Modifier = TextButtonModifier():LayoutOrder(1) }) -- OK
local b2 = Button({ Text = "a", Modifier = FrameModifier():LayoutOrder(1) }) -- NEG Frame modifier for a TextButton prop
type TextProps = { read Modifier: L.Modifier<TextLabel>? }
local function Text(props: TextProps) return TextLabel { props.Modifier or None } end -- OK
local t1 = Text({ Modifier = TextLabelModifier():LayoutOrder(2) }) -- OK
-- kit form 5: ModifierInto<GuiObject>? + AsGuiObject():AsTextButton()/AsFrame()
type CardProps = { read Modifier: L.ModifierInto<GuiObject>? }
local function Card(props: CardProps) return TextButton { if props.Modifier then props.Modifier:AsGuiObject():AsTextButton() else None } end -- OK
local function CardF(props: CardProps) return Frame { if props.Modifier then props.Modifier:AsGuiObject():AsFrame() else None } end -- OK
local function surfaceSize() return GuiObjectModifier():Size(UDim2.fromOffset(240, 0)):AutomaticSize(Enum.AutomaticSize.Y) end
local k1 = Card({ Modifier = surfaceSize() }) -- OK
local k2 = CardF({ Modifier = surfaceSize() }) -- OK
local k3 = Card({ Modifier = FrameModifier() }) -- NEG Frame modifier has no AsGuiObject
local custom = { AsGuiObject = function(self: any) return GuiObjectModifier() end }
local k4 = Card({ Modifier = custom }) -- OK custom Into implementation
local function CardBad(props: CardProps) return Frame { if props.Modifier then props.Modifier:AsGuiObject():AsTextButton() else None } end -- NEG TextButton modifier into Frame
-- As family
local d1 = GuiObjectModifier():AsTextButton():Text("x") -- OK down-cast keeps TextButton setters
local d2: L.Modifier<TextButton> = GuiObjectModifier():AsTextButton() -- OK same structure as the alias
local d3 = FrameModifier():AsFrame() -- OK identity
local d4 = FrameModifier():AsTextButton() -- NEG leaf has no down-cast to a sibling
local d5 = TextButtonModifier():AsGuiObject() -- NEG no checked up-cast
local d6 = GuiObjectModifier():AsFrame():Text("x") -- NEG Frame has no Text
local d7: L.Modifier<TextButton> = FrameModifier():As() -- OK unchecked As (type only)
local d8 = FrameModifier():As("TextButton") :: L.Modifier<TextButton> -- OK unchecked As(name)
local d9 = GuiObjectModifier():AsGuiButton():AsTextButton():Text("x") -- OK two-step down-cast
local d10 = FrameModifier():As<<L.Modifier<TextButton>>>():Text("x") -- OK explicit instantiation of the unchecked As
-- Overridden (method form stays on the value type; Raw.Modifier.Overridden is base and out of this probe)
local o1 = FrameModifier():Overridden(TextButtonModifier()) -- @h(m3-overridden) at='o1 =' OK
-- shorthand setters (GuiObject chain only)
local s1 = FrameModifier():UICorner(8):UIPaddingOffset(12):UIPadding(UDim.new(0, 4)):UIScale(2) -- OK
local s2 = FrameModifier():UICorner(UDim.new(0, 4)) -- OK
local s3 = FrameModifier():UICorner("x") -- NEG wrong shorthand value
local s4 = Modifier "UIListLayout" ():UICorner(8) -- NEG not a GuiObject
local s5 = Frame { UICorner = 8, UIPaddingOffset = 12 } -- OK props shorthand
local s6 = UIListLayout { UICorner = 8 } -- NEG props shorthand outside GuiObject
local s7 = FrameModifier():UICorner(None) -- OK None destroys the managed child
-- element placement
local p1 = Frame { windowName, tabs, base, m, GuiObjectModifier() } -- OK own + ancestor tags
local p2 = TextButton { FrameModifier() } -- NEG sibling class
local p3 = UIListLayout { GuiObjectModifier() } -- NEG unrelated class
-- value errors
local v1 = FrameModifier():Size(5) -- NEG
local v2 = FrameModifier():Text("x") -- NEG not a Frame setter
local v3 = TextLabelModifier():TextSize("big") -- NEG
local v4 = FrameModifier():AbsoluteSize(Vector2.zero) -- NEG ReadOnly
return { windowName, buttonName, fieldName, tabs, base, tip, btn, m, gAs, sized, b1, b2, t1, k1, k2, k3, k4, CardBad, d1, d2, d3, d4, d5,
	d6, d7, d8, d9, d10, o1, s1, s2, s3, s4, s5, s6, s7, p1, p2, p3, v1, v2, v3, v4 }
