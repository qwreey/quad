--!strict
-- [2026-10-16] (a) does a class map reuse the global class type? (b) Spread two-arg vs curried: completion inside `{`.
local L = require("./Lib")
type ClassMap = { Frame: Frame, TextLabel: TextLabel, GuiObject: GuiObject }

type function sameAs(m: type, key: type, g: type)
	local v = m:readproperty(key)
	print(`[SAME] map[{key:value()}] == global: {tostring(v == g)}; rawequal: {tostring(rawequal(v, g))}`)
	return m
end
type _probe = sameAs<ClassMap, "Frame", Frame>

type SM<K> = { read __quadSpread: K }
local Spread2 = (nil :: any) :: <K>(name: K & keyof<ClassMap>, props: L.Props<index<ClassMap, K>>) -> SM<K>
local SpreadC = (nil :: any) :: <K>(name: K & keyof<ClassMap>) -> (L.Props<index<ClassMap, K>>) -> SM<K>

local a = Spread2("Frame", { BackgroundTransparency = 0.5 }) -- @c(two-arg-Back) at='"Frame", { ' ins='Back'
local b = SpreadC "Frame" { BackgroundTransparency = 0.5 } -- @c(curry-Back) at='"Frame" { ' ins='Back'
local aBad = Spread2("Frame", { Visible = 5 }) -- should error
local bBad = SpreadC "Frame" { Visible = 5 } -- should error
local g = SpreadC "GuiObject" { Visible = true } -- @h(curry-marker) at='g = '
local gBad = SpreadC "GuiObject" { Text = "x" } -- should error (not a GuiObject prop)
return { a, b, aBad, bBad, g, gBad }
