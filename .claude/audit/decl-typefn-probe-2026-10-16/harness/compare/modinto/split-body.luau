--!strict
-- [2026-10-19 M3 follow-up] split of use-full-hand.luau: kit bodies only (policy full, gen-D-shaped hand Into). One-line markers.
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
local function Card(props: CardProps) return TextButton { if props.Modifier then props.Modifier:AsGuiObject():AsTextButton() else None } end -- OK
local function CardF(props: CardProps) return Frame { if props.Modifier then props.Modifier:AsGuiObject():AsFrame() else None } end -- OK
local function CardK(props: CardProps) return TextButton { buttonName, TextButtonModifier():Size(UDim2.new()), if props.Modifier then props.Modifier:AsGuiObject():AsTextButton() else None, BackgroundTransparency = 0, LayoutOrder = props.LayoutOrder } end -- OK kit-shaped element
local function CardS(props: CardProps) return TextButton { if props.Modifier then props.Modifier:AsGuiObject():AsTextButton():AutoButtonColor(false):Text("x") else None } end -- OK setters after the chain
local function CardFS(props: CardProps) return Frame { if props.Modifier then props.Modifier:AsGuiObject():AsFrame():ClipsDescendants(true) else None } end -- OK
return {}
