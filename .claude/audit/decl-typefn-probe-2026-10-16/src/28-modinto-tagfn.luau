--!strict
-- [2026-10-19 Studio copy of harness/compare/modinto/iso-tagfn.luau — line 2 replaced by this note so line numbers match; require points at ./Lib3. CLI results: that file.]
-- (`ToGui(m)` instead of the method `m:AsGuiObject()`), so the call site never compares Modifier copies. One-line markers.
local L = require("./Lib3")
type P = L.PolicyFull
type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>
type Mod<C> = L.ModP<C, P>
type IntoTag = { read __quadModifier: "GuiObject" | "GuiBase2d" | "GuiBase" | "Instance" }
local Elem = (nil :: any) :: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> Mod<CM<K>>
local ToGui = (nil :: any) :: (m: IntoTag) -> Mod<GuiObject>
local None = (nil :: any) :: L.None
local Frame = Elem "Frame"
local TextButton = Elem "TextButton"
local GuiObjectModifier = Modifier "GuiObject"
local InstanceModifier = Modifier "Instance"
local FrameModifier = Modifier "Frame"
type CardProps = { read Modifier: IntoTag?, read LayoutOrder: number? }
local function Card(props: CardProps) return TextButton { if props.Modifier then ToGui(props.Modifier):AsTextButton() else None } end -- OK
local function CardF(props: CardProps) return Frame { if props.Modifier then ToGui(props.Modifier):AsFrame() else None } end -- OK
local function CardS(props: CardProps) return TextButton { if props.Modifier then ToGui(props.Modifier):AsTextButton():AutoButtonColor(false):Text("x") else None, LayoutOrder = props.LayoutOrder } end -- OK
local function CardBad(props: CardProps) return Frame { if props.Modifier then ToGui(props.Modifier):AsTextButton() else None } end -- NEG
local function CardBad2(props: CardProps) return Frame { if props.Modifier then ToGui(props.Modifier):AsFrame():Text("x") else None } end -- NEG
local k1 = Card({ Modifier = GuiObjectModifier():Size(UDim2.new()) }) -- OK
local k2 = Card({ Modifier = InstanceModifier() }) -- OK ancestor
local n1 = Card({ Modifier = FrameModifier() }) -- NEG
local n2 = Card({ Modifier = Modifier "ScreenGui" () }) -- NEG
return { Card, CardF, CardS, CardBad, CardBad2, k1, k2, n1, n2 }
