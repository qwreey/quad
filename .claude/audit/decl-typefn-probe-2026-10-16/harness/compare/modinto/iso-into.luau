--!strict
-- [2026-10-19 M3 follow-up] which step of `into:AsGuiObject():AsTextButton()` is too complex in sync (policy full, gen-D-shaped hand Into)? One-line markers.
local L = require("../../../src/Lib3")
type P = L.PolicyFull
type CM<K> = index<L.ModClassMap, K>
type EM<K> = index<L.CreatableMap, K>
type Mod<C> = L.ModP<C, P>
type IntoG = { AsGuiObject: (self: any) -> Mod<GuiObject> }
local Elem = (nil :: any) :: <K>(name: K & keyof<L.CreatableMap>) -> (L.Props<EM<K>>) -> EM<K>
local None = (nil :: any) :: L.None
local TextButton = Elem "TextButton"
local function h1(m: IntoG) local x = m:AsGuiObject() return x end -- OK call only
local function h2(m: IntoG) local x = m.AsGuiObject(m) return x end -- OK dot call
local function h3(m: IntoG) local x = m:AsGuiObject():AsTextButton() return x end -- OK second hop
local function h4(m: IntoG) return TextButton { m:AsGuiObject():AsTextButton() } end -- OK into element
local function h5(m: IntoG) local g = m:AsGuiObject() return TextButton { g:AsTextButton() } end -- OK split
local function h6(m: IntoG) local g: Mod<GuiObject> = m:AsGuiObject() return g end -- OK same-spelled annotation
local function h7(m: Mod<GuiObject>) return TextButton { m:AsGuiObject():AsTextButton() } end -- OK identity then down-cast, no Into
local function h8(m: Mod<GuiObject>) return TextButton { m:AsGuiObject():AsGuiObject():AsTextButton() } end -- OK three hops, no Into
local function h9(m: IntoG?) return TextButton { if m then m:AsGuiObject():AsTextButton() else None } end -- OK kit form (optional + if/else)
local function h10(m: IntoG?) local x = if m then m:AsGuiObject():AsTextButton() else None return TextButton { x } end -- OK kit form hoisted to a local
local function h11(m: IntoG) return TextButton { m:AsGuiObject():AsTextButton() :: Mod<TextButton> } end -- OK cast to the same-spelled leaf alias
local function h12(m: IntoG) return TextButton { (m:AsGuiObject()):AsTextButton() } end -- OK parenthesised first call
return { h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12 }
