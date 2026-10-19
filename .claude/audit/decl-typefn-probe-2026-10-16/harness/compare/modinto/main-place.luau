--!strict
-- [2026-10-19 main] placement-only prop: full `Modifier<GuiObject>?`, no As, placed straight into TextButton/Frame; plus Into<leaf> helper (Bold). Policy full. One-line markers.
local L = require("../../../src/Lib3")
type P = L.PolicyFull
type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>
type Mod<C> = L.ModP<C, P>
type Into<C> = L.IntoP<C, P>
local Elem = (nil :: any) :: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> Mod<CM<K>>
local None = (nil :: any) :: L.None
local Frame = Elem "Frame"
local TextButton = Elem "TextButton"
local TextLabel = Elem "TextLabel"
local GuiObjectModifier = Modifier "GuiObject"
local FrameModifier = Modifier "Frame"
local TextLabelModifier = Modifier "TextLabel"
local TextButtonModifier = Modifier "TextButton"
type CardProps = { read Modifier: Mod<GuiObject>?, read LayoutOrder: number? }
local function Card(props: CardProps) return TextButton { props.Modifier or None, LayoutOrder = props.LayoutOrder, Text = "x" } end -- OK
local function CardF(props: CardProps) return Frame { if props.Modifier then props.Modifier else None, LayoutOrder = props.LayoutOrder } end -- OK
local function CardTL(props: CardProps) return TextLabel { props.Modifier or None } end -- OK
local k1 = Card({ Modifier = GuiObjectModifier():Size(UDim2.new()):Visible(true) }) -- OK
local k2 = CardF({ Modifier = GuiObjectModifier():LayoutOrder(2), LayoutOrder = 1 }) -- OK
local n1 = Card({ Modifier = FrameModifier() }) -- NEG
local n2 = Card({ Modifier = Modifier "ScreenGui" () }) -- NEG
local n3 = Card({ Modifier = GuiObjectModifier():Text("x") }) -- NEG
local n4 = Frame { FrameModifier(), TextLabelModifier() } -- NEG
local function Bold(m: Into<TextLabel>) return m:AsTextLabel():TextSize(20) end
local b1 = TextLabel { Bold(TextLabelModifier()) } -- OK
local b2 = TextLabel { Bold(GuiObjectModifier():Visible(true)) } -- OK
local b3 = TextLabel { Bold(TextButtonModifier()) } -- NEG
local b4 = Frame { Bold(TextLabelModifier()) } -- NEG
local function BoldBtn(m: Into<TextButton>) return m:AsTextButton():AutoButtonColor(false) end
local c1 = TextButton { BoldBtn(GuiObjectModifier()) } -- OK
local c2 = TextButton { BoldBtn(TextButtonModifier():Text("y")) } -- OK
local c3 = TextButton { BoldBtn(FrameModifier()) } -- NEG
return { Card, CardF, CardTL, k1, k2, n1, n2, n3, n4, Bold, b1, b2, b3, b4, BoldBtn, c1, c2, c3 }
