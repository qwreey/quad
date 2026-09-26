--!strict
local q = require("./s10-config")
local QT = require("../../../quad-types/src")
local D = q.Declaration
type None = QT.None
local _w1 = q.Attr({ A = q.Source(1 :: number | None) }) -- W1 group Attr State<number|None> (doc core/09 287 example)
local _w2 = q.NumberAttr("N", q.Source(1 :: number | None)) -- W2 NumberAttr State<number|None>
local _w3 = D.Frame { NextSelectionUp = q.Source(nil :: GuiObject | None) } -- W3 object ref State<GuiObject|None> (wrong init on purpose)
local _w4 = D.Frame { UICorner = q.Source(8 :: number | None) } -- W4 shorthand State<number|None>
local _w5 = D.Frame { BackgroundTransparency = q.Source(0 :: number | None) } -- W5 number prop State<number|None>
local _w6 = D.TextButton { Activated = q.Source(q.None :: (() -> ()) | None) } -- W6 event State<cb|None>
local _w7 = D.Frame { q.Source(q.None :: Instance | None) } -- W7 numeric State<Instance|None>
local _w8 = q.Slot<<Instance>>():Single(q.Source(q.None :: Instance | None)) -- W8 :Single State<Instance|None>
local _w9 = q.Slot<<Instance>>():Add(q.Source(q.None :: Instance | None)) -- W9 Slot:Add State<Instance|None>
local _w10 = D.Frame { q.Source(nil :: QT.Tag?) } -- W10 numeric State<Tag?>
