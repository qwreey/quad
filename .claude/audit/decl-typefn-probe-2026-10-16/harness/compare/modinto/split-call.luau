--!strict
-- [2026-10-19 M3 follow-up] split of use-full-hand.luau: call sites only (Card declared by type, no body). One-line markers.
local L = require("../../../src/Lib3")
type P = L.PolicyFull
type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>
type Mod<C> = L.ModP<C, P>
type IntoG = { AsGuiObject: (self: any) -> Mod<GuiObject> }
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
local Card = (nil :: any) :: (props: CardProps) -> TextButton
local CardF = (nil :: any) :: (props: CardProps) -> Frame
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
return {}
