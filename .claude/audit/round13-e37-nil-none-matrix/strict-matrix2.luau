--!strict
local q = require("./s10-config")
local QT = require("../../../quad-types/src")
local D = q.Declaration
type None = QT.None

local s1 = q.Source(1)
local c: q.State<string?> = s1:Compute(function(h: q.StateData<number>): string? if h:Get() > 1 then return nil end return "x" end)
local _p6 = D.TextLabel { Text = c } -- U1 Compute State<string?> into Text
local _m1 = D.Modifier.Frame():BackgroundTransparency(q.None) -- U2 typed Modifier None
local _m2 = D.Modifier.Frame():BackgroundTransparency(nil) -- U3 typed Modifier nil
local _m3 = D.Modifier.Frame():BackgroundTransparency(q.Source(nil :: number?)) -- U4 typed Modifier State<number?>
local _m4 = D.Modifier.Frame():NextSelectionUp(q.Source(nil :: GuiObject?)) -- U5 typed Modifier object-ref State<GuiObject?>
local _t2 = q.Tag(q.None) -- U6 Tag(None)
local _t3 = q.Tag("A", q.None) -- U7 Tag("A", None)
local _b1 = q.BooleanAttr("B", q.Source(nil :: boolean?)) -- U8 BooleanAttr State<boolean?>
local _k1 = D.Frame { [q.AttrKey("K")] = q.Source(nil :: number?) } -- U9 AttrKey State<number?>
local alt = q.Source(nil :: string?):Apply(q.Operator.Alternative("d"))
local _p7 = D.TextLabel { Text = alt } -- U10 Alternative result into Text
local idx = q.Source({ A = "x" }):Apply(q.Operator.Indexed<<string?>>("B"))
local _p8 = D.TextLabel { Text = idx } -- U11 Indexed<<string?>> into Text
local _sl = q.Slot<<Instance>>():Add(q.Source(D.Frame {} :: Instance)) -- U12 Slot:Add(State<Instance>) control
local _ev = D.TextButton { Activated = q.Source(function() end) } -- U13 event State<cb> control
