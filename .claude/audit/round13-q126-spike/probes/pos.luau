--!strict
-- Q126 spike — POSITIVE rows: every line must type-check after the change (runtime already accepts all).
local q = require("./config")
local QT = require("../quad-types/src")
local D = q.Declaration
type None = QT.None

-- object-reference properties (engine accepts nil)
local _p1 = D.Frame { NextSelectionUp = q.Source(nil :: GuiObject?) } -- P1 State<GuiObject?>
local _p2 = D.Frame { NextSelectionUp = q.Source<<(GuiObject | None)?>>(nil) } -- P2 State<(GuiObject|None)?>
local _p3 = D.Frame { NextSelectionUp = q.Source<<GuiObject | None>>(q.None) } -- P3 State<GuiObject|None>
local _p4 = D.BillboardGui { Adornee = q.Source(nil :: BasePart?) } -- P4 covariant: State<BasePart?> into Instance slot
local _p5 = D.ViewportFrame { CurrentCamera = q.Source(nil :: Camera?) } -- P5 Camera
local sel = q.Source(0)
local target: q.State<GuiObject?> = sel:Compute(function(s: q.StateData<number>): GuiObject?
	if s:Get() > 0 then return nil end
	return nil
end)
local _p6 = D.Frame { NextSelectionUp = target } -- P6 Compute State<GuiObject?>
local _p7 = D.Frame { NextSelectionUp = q.Source(nil :: Frame?) } -- P7 covariant: State<Frame?> into GuiObject
-- events (State's nil/None = disconnect)
local _e1 = D.TextButton { Activated = q.Source(nil :: ((InputObject, number) -> ())?) } -- P8 State<cb?>
local _e2 = D.TextButton { Activated = q.Source<<((InputObject, number) -> ()) | None>>(q.None) } -- P9 State<cb|None>
local on = q.Source(true)
local cb: q.State<((InputObject, number) -> ())?> = on:Compute(function(s: q.StateData<boolean>): ((InputObject, number) -> ())?
	if s:Get() then return function(_i: InputObject, _n: number) end end
	return nil
end)
local _e3 = D.TextButton { Activated = cb } -- P10 Compute State<cb?>
local _e4 = D.TextButton { Activated = q.Source(function() end) } -- P11 control: plain State<cb> still ok
-- shorthand (State's nil/None = destroy the managed child)
local _s1 = D.Frame { UICorner = q.Source(nil :: number?) } -- P12 UICorner State<number?>
local _s2 = D.Frame { UICorner = q.Source<<UDim | None>>(UDim.new(0, 4)) } -- P13 UICorner State<UDim|None>
local _s3 = D.Frame { UIPadding = q.Source(nil :: UDim?) } -- P14 UIPadding State<UDim?>
local _s4 = D.Frame { UIScale = q.Source(nil :: number?), UIPaddingOffset = q.Source(nil :: number?) } -- P15
local _s5 = D.Frame { UICorner = q.Source(8) } -- P16 control: State<number>
-- typed Attr sugar (State's nil/None = delete)
local _a1 = q.NumberAttr("N", q.Source(nil :: number?)) -- P17
local _a2 = q.BooleanAttr("B", q.Source<<boolean | None>>(true)) -- P18 idiom (i)
local _a3 = q.StringAttr("S", q.Source<<(string | None)?>>(nil)) -- P19
local _a4 = D.Frame { q.NumberAttr("N", q.Source(1)) } -- P20 control
-- Slot element input positions (State's nil/None = element comes down, not destroyed)
local sl = q.Slot<<Instance>>()
local _sl1 = sl:Add(q.Source(nil :: Instance?)) -- P21 Add State<Instance?>
local _sl2 = sl:Add(q.Source<<Instance | None>>(q.None)) -- P22 Add State<Instance|None>
local _sl3 = sl:Add(q.Source(nil :: Frame?)) -- P23 covariant
sl:Replace(1, q.Source(nil :: Instance?)) -- P24 Replace
local _sl4 = q.Slot<<Instance>>({ q.Source(nil :: Instance?) }) -- P25 constructor initial
local _sl5 = sl:IndexOf(q.Source(nil :: Instance?)) -- P26 IndexOf
local _sl6 = sl:Add(q.Source(D.Frame {} :: Instance)) -- P27 control
-- Modifier setters (object refs + shorthand)
local _m1 = D.Modifier.Frame():NextSelectionUp(q.Source(nil :: GuiObject?)) -- P28
local _m2 = D.Modifier.Frame():UICorner(q.Source(nil :: number?)) -- P29
local _m3 = D.Modifier.Frame():UICorner(q.Source<<(number | UDim | None)?>>(nil)) -- P30
local _m4 = D.Modifier.Frame():NextSelectionUp(q.None):NextSelectionUp(nil) -- P31 literal None/nil still ok
local _m5 = D.Modifier.Frame():NextSelectionUp(function(old) return old end) -- P32 transform fn
local _m6 = D.Modifier.GuiObject():SelectionImageObject(q.Source(nil :: ImageLabel?)) -- P33 covariant
-- Set(None) idiom (i): declare the State wide, Attr sugar accepts it now
local active = q.Source<<boolean | None>>(true)
local _a5 = D.Frame { q.BooleanAttr("Active", active) } -- P34
active:Set(false) -- P35
active:Set(q.None) -- P36
