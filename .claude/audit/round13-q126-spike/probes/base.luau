--!strict
-- Q126 spike — engine-agnostic rows (quad-types only: AttrSugar, SlotElement, Source:Set).
-- Checked by luau-analyze AND luau-lsp --platform=standard (no Roblox defs).
local q = require("../quad-base/src")
local QT = require("../quad-types/src")
type None = QT.None
type El = { read name: string }
type Sub = { read name: string, read extra: number }
type Other = { read other: boolean }

local _a1 = q.NumberAttr("N", q.Source(nil :: number?)) -- P1 Attr sugar State<number?>
local _a2 = q.BooleanAttr("B", q.Source<<boolean | None>>(true)) -- P2 Attr sugar State<boolean|None> (idiom i)
local _a3 = q.StringAttr("S", q.Source<<(string | None)?>>(nil)) -- P3
local _a4 = q.NumberAttr("N", q.None) -- P4 control literal None
local sl = q.Slot<<El>>()
local _s1 = sl:Add(q.Source(nil :: El?)) -- P5 Slot:Add State<El?>
local _s2 = sl:Add(q.Source<<El | None>>(q.None)) -- P6 Slot:Add State<El|None>
local _s3 = sl:Add(q.Source(nil :: Sub?)) -- P7 covariant subtype
local _s4 = q.Slot<<El>>({ q.Source(nil :: El?) }) -- P8 initial
local _s5 = sl:Add(q.Slot<<Sub>>()) -- P9 control Slot-in-Slot
local active = q.Source<<boolean | None>>(true)
active:Set(q.None) -- P10 idiom (i) Set
local _a5 = q.BooleanAttr("Active", active) -- P11 idiom (i) into sugar

local _n1 = q.NumberAttr("N", q.Source(nil :: string?)) -- N1 wrong type
local _n2 = q.StringAttr("S", nil) -- N2 literal nil
local _n3 = sl:Add(q.Source(nil :: Other?)) -- N3 wrong element type
local _n4 = sl:Add(nil) -- N4 literal nil (runtime Quad0239)
local _n5 = sl:Add(q.None) -- N5 literal None (runtime Quad0239)
local plain = q.Source(true)
plain:Set(q.None) -- N6 Set(None) on a narrow State
local _n7 = q.Source(1):Set("x") -- N7 wrong type
