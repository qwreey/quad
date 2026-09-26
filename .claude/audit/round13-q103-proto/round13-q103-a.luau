--!strict
-- P-Q103 variant A extra: nil arm must not widen the non-nil value check.
local q = require("./round13-e14-types-settings")
local D = q.Declaration
local function _A()
	local base = D.Modifier.Frame { LayoutOrder = 1 }
	local s: string? = nil
	local st: q.State<number?> = q.Source(nil :: number?)
	local _a1 = base:LayoutOrder(s) -- E:A1 string? into number setter
	local _a2 = base:LayoutOrder(st) -- ?:A2 State<number?> (nil inside State — outside this question)
	local _a3 = base:Style(nil) -- OK:A3 FieldP nil
	local _a4 = base:LayoutOrder(nil):Visible(true) -- OK:A4 chain continues after nil
	return _a1, _a2, _a3, _a4
end
return _A
