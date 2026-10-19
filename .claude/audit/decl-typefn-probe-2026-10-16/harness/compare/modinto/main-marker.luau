--!strict
-- [2026-10-19 main] placement-only prop as a MARKER (tag of C and its ancestors, no methods), placed straight into TextButton/Frame, no As. Policy full. One-line markers.
local L = require("../../../src/Lib3")
type P = L.PolicyFull
type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>
type Mod<C> = L.ModP<C, P>
type GuiMarker = { read __quadModifier: "GuiObject" | "GuiBase2d" | "GuiBase" | "Instance" }
local Elem = (nil :: any) :: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> Mod<CM<K>>
local None = (nil :: any) :: L.None
local Frame = Elem "Frame"
local TextButton = Elem "TextButton"
local UIListLayout = Elem "UIListLayout"
local GuiObjectModifier = Modifier "GuiObject"
local InstanceModifier = Modifier "Instance"
local FrameModifier = Modifier "Frame"
type CardProps = { read Modifier: GuiMarker?, read LayoutOrder: number? }
local function Card(props: CardProps) return TextButton { props.Modifier or None, LayoutOrder = props.LayoutOrder, Text = "x" } end -- OK
local function CardF(props: CardProps) return Frame { if props.Modifier then props.Modifier else None, LayoutOrder = props.LayoutOrder } end -- OK
local function CardBad(props: CardProps) return UIListLayout { props.Modifier or None } end -- NEG
local k1 = Card({ Modifier = GuiObjectModifier():Size(UDim2.new()):Visible(true) }) -- OK
local k2 = CardF({ Modifier = GuiObjectModifier():LayoutOrder(2), LayoutOrder = 1 }) -- OK
local k3 = Card({ Modifier = InstanceModifier():Name("n") }) -- OK
local n1 = Card({ Modifier = FrameModifier() }) -- NEG
local n2 = Card({ Modifier = Modifier "ScreenGui" () }) -- NEG
local n3 = Card({ Modifier = GuiObjectModifier():Text("x") }) -- NEG
local n4 = Card({ Modifier = 5 }) -- NEG
return { Card, CardF, CardBad, k1, k2, k3, n1, n2, n3, n4 }
