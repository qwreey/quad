--!strict
-- Q126 spike — idiom (i) spellings a GS reader can write with only the setup module (no QuadTypes require)
local q = require("./config")
local D = q.Declaration
local active = q.Source<<boolean | typeof(q.None)>>(true) -- P1 typeof(q.None) spelling
active:Set(false) -- P2
active:Set(q.None) -- P3
local _card = D.Frame { q.BooleanAttr("Active", active) } -- P4 into typed sugar
local _card2 = D.Frame { q.Attr({ Active = active }) } -- P5 into group Attr
local hp: q.Source<number | typeof(q.None)> = q.Source<<number | typeof(q.None)>>(100) -- P6 annotated
local _l = D.TextLabel { Text = hp:Compute(function(h: q.StateData<number | typeof(q.None)>): string
	local v = h:Get()
	return if v == q.None then "-" else tostring(v)
end) } -- P7 reading it back needs a None branch
