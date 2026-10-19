--!strict
-- [2026-10-19 Studio copy of harness/compare/modfull/into-ident.luau — same lines; requires rewritten to the Studio tree (probe.project.json). CLI results: that file.]
-- [2026-10-19 M3] is the ModifierInto failure an identity problem? Same GuiObject Modifier reached two ways, passed two ways.
local L = require("./Lib2")
type CM<K> = index<L.ModClassMap, K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> L.Modifier<CM<K>>
local GMdirect = (nil :: any) :: () -> L.Modifier<GuiObject>
local GMindex = Modifier "GuiObject"
type IntoTF = L.ModifierInto<GuiObject>
type IntoHand = { AsGuiObject: (self: any) -> L.Modifier<GuiObject> }
local function A(m: IntoTF?) end
local function An(m: IntoTF) end
local function B(m: IntoHand?) end
local function T(p: { read Modifier: IntoTF? }) end
A(GMdirect()) -- OK direct alias -> TF Into? (param)
A(GMindex()) -- OK index alias -> TF Into? (param)
An(GMindex()) -- OK index alias -> TF Into (param, non-optional)
B(GMindex()) -- OK index alias -> hand Into? (param)
T({ Modifier = GMindex() }) -- OK index alias -> TF Into? (table literal field)
local x1: L.Modifier<GuiObject> = GMindex() -- OK index vs direct alias, plain assignment
local x2: L.Modifier<GuiObject> = GMdirect() -- OK same alias, plain assignment
local x3: L.ModifierAs0<GuiObject> = (nil :: any) :: L.ModifierAs0<GuiObject> -- OK
T({ Modifier = GMdirect() }) -- OK direct alias -> TF Into? (table literal field)
An(GMdirect()) -- OK direct alias -> TF Into (param, non-optional)
local GMhoist: () -> L.Modifier<GuiObject> = Modifier "GuiObject" -- OK hoist with a direct-alias annotation
T({ Modifier = GMhoist() }) -- OK
local y1: L.ModifierAs1<GuiObject> = (nil :: any) :: L.ModifierAs1<index<L.ModClassMap, "GuiObject">> -- OK As1 cross-spelling
local y0: L.ModifierAs0<GuiObject> = (nil :: any) :: L.ModifierAs0<index<L.ModClassMap, "GuiObject">> -- OK As0 cross-spelling
local yf: L.Modifier<Frame> = (nil :: any) :: L.Modifier<index<L.ModClassMap, "Frame">> -- OK leaf cross-spelling
A(Modifier "Frame" ()) -- NEG Frame has no AsGuiObject
T({ Modifier = Modifier "Frame" () }) -- NEG
