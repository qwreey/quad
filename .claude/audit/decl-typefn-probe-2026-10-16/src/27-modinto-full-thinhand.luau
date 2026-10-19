--!strict
-- [2026-10-19 Studio copy of harness/compare/modinto/use-full-thinhand.luau — line 2 replaced by this note so line numbers match; require points at ./Lib3. CLI results: that file.]
local L = require("./Lib3")
type P = L.PolicyFull
type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>
type Mod<C> = L.ModP<C, P>
type IntoG = { read __quadModifier: "GuiObject" | "GuiBase2d" | "GuiBase" | "Instance", AsGuiObject: (self: any) -> Mod<GuiObject> }
local Elem = (nil :: any) :: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> Mod<CM<K>>
local None = (nil :: any) :: L.None
local Frame = Elem "Frame"
local TextButton = Elem "TextButton"
local FrameModifier = Modifier "Frame"
local TextButtonModifier = Modifier "TextButton"
local GuiObjectModifier = Modifier "GuiObject"
local GuiBase2dModifier = Modifier "GuiBase2d"
local InstanceModifier = Modifier "Instance"
local ScreenGuiModifier = Modifier "ScreenGui"
local buttonName = TextButtonModifier():Name("Button") -- OK
-- kit form (material Card.luau 81/214/237, List.luau 97/267/299)
type CardProps = { read Modifier: IntoG?, read LayoutOrder: number? }
local function Card(props: CardProps) return TextButton { if props.Modifier then props.Modifier:AsGuiObject():AsTextButton() else None } end -- OK
local function CardF(props: CardProps) return Frame { if props.Modifier then props.Modifier:AsGuiObject():AsFrame() else None } end -- OK
local function CardK(props: CardProps) return TextButton { buttonName, TextButtonModifier():Size(UDim2.new()), if props.Modifier then props.Modifier:AsGuiObject():AsTextButton() else None, BackgroundTransparency = 0, LayoutOrder = props.LayoutOrder } end -- OK kit-shaped element
local function CardS(props: CardProps) return TextButton { if props.Modifier then props.Modifier:AsGuiObject():AsTextButton():AutoButtonColor(false):Text("x") else None } end -- OK setters after the chain
local function CardFS(props: CardProps) return Frame { if props.Modifier then props.Modifier:AsGuiObject():AsFrame():ClipsDescendants(true) else None } end -- OK
local function surfaceSize() return GuiObjectModifier():Size(UDim2.fromOffset(240, 0)):AutomaticSize(Enum.AutomaticSize.Y) end
local k1 = Card({ Modifier = surfaceSize() }) -- OK GuiObject modifier (helper return)
local k2 = CardF({ Modifier = GuiObjectModifier() }) -- OK
local k3 = Card({ Modifier = GuiBase2dModifier() }) -- OK ancestor GuiBase2d modifier
local k4 = Card({ Modifier = InstanceModifier():Name("x") }) -- OK ancestor Instance modifier
local k5 = Card({ LayoutOrder = 1 }) -- OK no modifier
local n1 = Card({ Modifier = FrameModifier() }) -- NEG descendant Frame modifier into Into<GuiObject>
local n2 = Card({ Modifier = TextButtonModifier() }) -- NEG
local n3 = Card({ Modifier = ScreenGuiModifier() }) -- NEG sibling branch (LayerCollector)
local n4 = Card({ Modifier = Modifier "UIListLayout" () }) -- NEG unrelated class
local function CardBad(props: CardProps) return Frame { if props.Modifier then props.Modifier:AsGuiObject():AsTextButton() else None } end -- NEG TextButton modifier into Frame
local function CardBad2(props: CardProps) return TextButton { if props.Modifier then props.Modifier:AsGuiObject():AsTextButton():Size(5) else None } end -- NEG wrong setter value after the chain
local function CardBad3(props: CardProps) return Frame { if props.Modifier then props.Modifier:AsGuiObject():AsFrame():Text("x") else None } end -- NEG Frame has no Text
-- plain assignments to the Into / identity across spellings
local i1: IntoG = GuiObjectModifier() -- OK
local i2: IntoG = InstanceModifier() -- OK ancestor
local i3: IntoG = FrameModifier() -- NEG
local i4: Mod<GuiObject> = GuiObjectModifier() -- OK cross spelling (Lib2 into-ident x1 was too complex in sync)
local i5: Mod<TextButton> = GuiObjectModifier():AsTextButton() -- OK
-- leaf / out-of-list down-casts (다)
local l1 = FrameModifier():AsTextButton() -- NEG leaf has no down-cast
local l2 = TextButtonModifier():AsGuiObject() -- NEG no checked up-cast
local o1 = GuiObjectModifier():AsTextLabel():Text("x") -- OK list: TextLabel
local o2 = GuiObjectModifier():AsScrollingFrame():CanvasSize(UDim2.new()) -- OK list: ScrollingFrame
local o3 = GuiObjectModifier():AsViewportFrame() -- OK list: ViewportFrame
local o4 = GuiObjectModifier():AsGuiButton():AsTextButton() -- OK list: GuiButton second hop
local o5 = InstanceModifier():AsGuiObject():AsFrame() -- OK ancestor → GuiObject → Frame
local o6 = InstanceModifier():AsFrame() -- OK list: Instance → Frame direct
local o7 = GuiBase2dModifier():AsTextButton() -- OK list: GuiBase2d → TextButton direct
-- placement sanity
local p1 = Frame { GuiObjectModifier(), FrameModifier(), InstanceModifier() } -- OK own + ancestor tags
local p2 = TextButton { FrameModifier() } -- NEG sibling class
local d1 = TextButton { GuiObjectModifier():AsTextButton():Text("x") } -- OK
local d2 = Frame { GuiObjectModifier():AsTextButton() } -- NEG
-- custom Into implementation (no tag): thin forms reject it by construction — counted separately (SEMANTIC)
local custom = { AsGuiObject = function(self: any) return GuiObjectModifier() end }
local c1 = Card({ Modifier = custom }) -- SEMANTIC custom Into (tag required)
-- LSP probes
local hv = GuiObjectModifier():Size(UDim2.new()) -- @h(gm-value) at='hv =' -- @c(gm-dot) at='GuiObjectModifier():' ins='A' -- OK
local function Probe(props: CardProps) local x = props.Modifier and props.Modifier:AsGuiObject() return x end -- @c(into-dot) at='props.Modifier and props.Modifier:' ins='A' -- @h(into-prop) at='props: CardProps' -- OK
local function Probe2(props: CardProps) local y = props.Modifier and props.Modifier:AsGuiObject():AsTextButton() return y end -- @c(as-dot) at='props.Modifier:AsGuiObject():' ins='A' -- OK
return { buttonName, Card, CardF, CardK, CardS, CardFS, k1, k2, k3, k4, k5, n1, n2, n3, n4, CardBad, CardBad2, CardBad3, i1, i2, i3, i4, i5,
	l1, l2, o1, o2, o3, o4, o5, o6, o7, p1, p2, d1, d2, c1, hv, Probe, Probe2 }
