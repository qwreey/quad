--!strict
-- [2026-10-16] round13 Q87/Q127 under class-first curry: per-class read map (no cross-class `any` conflicts), Instance props read as `T?`.
local L = require("../../src/Lib")
local QT = require("../../../../../quad-types/src")
type ClassMap = { Frame: Frame, ScrollingFrame: ScrollingFrame, UIGradient: UIGradient, UIStroke: UIStroke, TextLabel: TextLabel, BillboardGui: BillboardGui }
type CM<K> = index<ClassMap, K>
local Out = (nil :: any) :: <C0>(class: C0 & keyof<ClassMap>) -> <K>(name: K & keyof<L.ReadMap<CM<C0>>>) -> (src: QT.Source<index<L.ReadMap<CM<C0>>, K>>) -> L.ChangeDesc<K>
local OnChange = (nil :: any) :: <C0>(class: C0 & keyof<ClassMap>) -> <K>(name: K & keyof<L.ReadMap<CM<C0>>>) -> (fn: (index<L.ReadMap<CM<C0>>, K>) -> ()) -> L.ChangeDesc<K>
local function src<T>(v: T): QT.Source<T> return nil :: any end

-- Q87 conflict names, now per class
local p1 = Out "ScrollingFrame" "CanvasSize" (src(UDim2.new()))
local p2 = Out "UIGradient" "Color" (src(ColorSequence.new(Color3.new())))
local p3 = Out "UIGradient" "Transparency" (src(NumberSequence.new(0)))
local p4 = Out "UIStroke" "Transparency" (src(0.5))
local n1 = Out "ScrollingFrame" "CanvasSize" (src(Vector2.zero)) -- should error
local n2 = Out "UIGradient" "Transparency" (src(0.5)) -- should error (NumberSequence)
local n3 = Out "Frame" "Text" (src("x")) -- should error (not a Frame prop)
-- Q127 object references read as nilable
local q1 = Out "Frame" "NextSelectionUp" (src(nil :: GuiObject?))
local q2 = Out "BillboardGui" "Adornee" (src(nil :: Instance?))
local q3 = OnChange "Frame" "NextSelectionUp" (function(v)
	local g: GuiObject = v -- should error: v is GuiObject?
end)
local q4 = OnChange "Frame" "Size" (function(v)
	local u: UDim2 = v -- fine: non-Instance stays non-nil
end)
return { p1, p2, p3, p4, n1, n2, n3, q1, q2, q3, q4 }
