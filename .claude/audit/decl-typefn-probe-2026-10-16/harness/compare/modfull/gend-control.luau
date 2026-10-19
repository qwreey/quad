--!strict
-- [2026-10-19 M3] control: the same Into / sibling-prop cases against TODAY's generated Declaration (vsc only — sync collapses the module).
local DM = require("../../../../../../quad-roblox/src/Declaration")
local D: DM.Declaration = nil :: any
local function A(m: DM.IntoGuiObject?) end
local function An(m: DM.IntoGuiObject) end
local function T(p: { read Modifier: DM.IntoGuiObject? }) end
A(D.Modifier.GuiObject()) -- OK optional param
An(D.Modifier.GuiObject()) -- OK
T({ Modifier = D.Modifier.GuiObject() }) -- OK
A(D.Modifier.Frame()) -- NEG
type ButtonProps = { read Modifier: DM.TextButtonModifier?, read Text: string }
local function Button(props: ButtonProps) end
Button({ Text = "a", Modifier = D.Modifier.Frame():LayoutOrder(1) }) -- NEG Frame modifier for a TextButton prop
local function Bp(m: DM.TextButtonModifier?) end
Bp(D.Modifier.Frame()) -- NEG as param
local bx: DM.TextButtonModifier = D.Modifier.Frame() -- NEG plain assignment
local tbOk: DM.TextButtonModifier = D.Modifier.GuiObject():AsTextButton() -- OK
local d7: DM.TextButtonModifier = D.Modifier.Frame():As() -- OK unchecked As (type only) — generic T from the annotation?
local d8 = D.Modifier.Frame():As("TextButton") :: DM.TextButtonModifier -- OK unchecked As(name) + cast
local d9 = D.Modifier.Frame():As<<DM.TextButtonModifier>>() -- OK explicit instantiation
