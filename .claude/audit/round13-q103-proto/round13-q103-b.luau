--!strict
-- P-Q103 variant B probe: idioms under the unchanged Field<T> (no nil arm). `-- E:` expect error, `-- OK:` expect none.
local q = require("./round13-e14-types-settings")
local D = q.Declaration
local None = q.None

local function _B()
	local base = D.Modifier.Frame { BackgroundTransparency = 0.5, LayoutOrder = 1 }
	local maybe: number? = nil
	local _b1 = base:LayoutOrder(q.None) -- OK:B1 q.None literal
	local _b2 = base:LayoutOrder(None) -- OK:B2 None local
	local _b3 = base:LayoutOrder(nil :: any) -- OK:B3 nil :: any
	local _b4 = base:LayoutOrder(maybe :: any) -- OK:B4 optional cast any
	local _b5 = base:LayoutOrder(if maybe == nil then q.None else maybe) -- OK:B5 if-expr to None
	local _b6 = base:LayoutOrder(maybe or q.None) -- OK:B6 or None
	local _b7 = base:LayoutOrder(function(_old) return nil end) -- OK:B7 transform returning nil
	local _b8 = base:Size(nil) -- E:B8 bare nil (baseline error, T12)
	local _b9 = base:Style(nil) -- E:B9 FieldP bare nil (non-interpolable)
	local _b10 = D.Modifier.Frame({ LayoutOrder = maybe }) -- ?:B10 constructor table form optional
	return _b1, _b2, _b3, _b4, _b5, _b6, _b7, _b8, _b9, _b10
end
return _B
