--!strict
-- [2026-10-19 M3 follow-up] which part of the kit body is too complex in sync (policy full, no Into involved)? One-line markers.
local L = require("../../../src/Lib3")
type P = L.PolicyFull
type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>
type Mod<C> = L.ModP<C, P>
local Elem = (nil :: any) :: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>
local Modifier = (nil :: any) :: <K>(name: K & keyof<L.ModClassMap>) -> (...any) -> Mod<CM<K>>
local None = (nil :: any) :: L.None
local TextButton = Elem "TextButton"
local GuiObjectModifier = Modifier "GuiObject"
local cond = (nil :: any) :: boolean
local function a(m: Mod<GuiObject>) return TextButton { m:AsTextButton() } end -- OK direct-spelled param, no union
local function b(m: Mod<GuiObject>?) return TextButton { if m then m:AsTextButton() else None } end -- OK direct-spelled optional + if/else None
local function c(m: Mod<CM<"GuiObject">>) return TextButton { m:AsTextButton() } end -- OK index-spelled param
local function d(m: Mod<CM<"GuiObject">>?) return TextButton { if m then m:AsTextButton() else None } end -- OK index-spelled optional + if/else
local e = TextButton { if cond then GuiObjectModifier():AsTextButton() else None } -- OK factory value + if/else
local f = TextButton { GuiObjectModifier():AsTextButton() } -- OK factory value
local function g(m: Mod<GuiObject>) local x = m:AsTextButton() return x end -- OK no element
local function h(m: Mod<GuiObject>) return TextButton { (m:AsTextButton()) :: any } end -- OK cast to any
local function i(m: Mod<GuiObject>) local x: Mod<TextButton> = m:AsTextButton() return x end -- OK direct-spelled leaf annotation
local function j(m: Mod<GuiObject>?) return TextButton { m and m:AsTextButton() or None } end -- OK and/or form
local function k(m: { read Modifier: Mod<GuiObject>? }) return TextButton { if m.Modifier then m.Modifier:AsTextButton() else None } end -- OK props-table read
local function l(m: Mod<GuiObject>) return TextButton { m } end -- OK GuiObject modifier placed directly
return { a, b, c, d, e, f, g, h, i, j, k, l }
