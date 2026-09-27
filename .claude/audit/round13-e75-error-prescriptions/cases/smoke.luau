--!nocheck
local H = require("../harness")
local R = require("../runner")
local q, D = H.q, H.D
R.case({ id = "Quad0145",
	trigger = function()
		local s = q.Slot()
		s:List({ "a", "a" }, function(ctx) return D.TextLabel({ Text = ctx.Item }) end, function(x) return x end)
		D.Frame({ s })
	end,
	fix = function()
		local s = q.Slot()
		s:List({ { id = 1, t = "a" }, { id = 2, t = "a" } }, function(ctx) return D.TextLabel({ Text = ctx.Item.t }) end, function(x) return x.id end)
		local f = D.Frame({ s })
		local n = #f:GetChildren()
		return n == 2, "children=" .. n
	end })
R.done()
