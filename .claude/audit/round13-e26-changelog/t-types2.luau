--!strict
-- E26 isolation probe: migrations flagged in t-types.luau
local q = require("./t-settings")
local D = q.Declaration
type Row = { id: string, label: string }

local function _parent()
	local _a = q.OnChange("Parent", function(p) if p then print(p.Name) end end) -- ?P3a standalone unannotated (CHANGELOG "주석을 빼고(추론됨)")
	local _b = D.Frame { q.OnChange("Parent", function(p) if p then print(p.Name) end end) } -- ?P3b inside D.Frame
	local _c = D.Frame { q.OnChange("Parent", function(p) print(p) end) } -- ?P3c unannotated, no field access
	local _d = D.Frame { q.OnChange("Size", function(s) print(s.X) end) } -- ?P3d non-nil prop, unannotated field access (control)
	local _e = D.Frame { AncestryChanged = function(child, parent) if parent then print(parent.Name) end end } -- ?P3e event unannotated
end

local function _cleanup()
	local src = q.Source(0)
	local _a = q.Effect(function() return function() end end, src) -- ?F4a inline literal
	local _b = q.Effect(function()
		local function cleanup() print("x") end
		return cleanup
	end, src) -- ?F4b named local function (inferred () -> ())
	local _c = q.Effect(function()
		local conn = { Disconnect = function(_self: any) end }
		return function() conn:Disconnect() end
	end, src) -- ?F4c CHANGELOG's own advice shape
	local function makeCleanup(): () -> () return function() end end
	local _d = q.Effect(function() return makeCleanup() end, src) -- ?F4d helper typed () -> ()
	local _e = q.OnDestroyed(function() end) -- control
end

local function _upd(rows: q.State<{ Row }>)
	local s = q.Slot()
	s:List(rows, function(ctx)
		if ctx.Item == q.KeyGone then
			return nil, ctx.UserData
		end
		if ctx.Prev then
			return ctx.Prev, ctx.UserData
		end
		return D.TextLabel { Text = ctx.Item.label }, ctx.UserData
	end, function(item) return item.id end) -- ?U3a docs form
	local cur = q.Source({ id = "x", label = "X" } :: Row?)
	local s2 = q.Slot()
	s2:Single(cur, function(ctx)
		if ctx.Item == q.KeyGone then
			return nil, ctx.UserData
		end
		return D.TextLabel { Text = ctx.Item.label }, ctx.UserData
	end) -- ?U5a docs form for Single
end
