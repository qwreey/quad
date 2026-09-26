--!nocheck
local H = require("./harness")
local q, D = H.q, H.D

local hp = q.Source(100)
local seen = {}

local label = D.TextLabel {
	Text = hp:Compute(function(self: q.StateData<number>)
		return `HP {self:Get()}`
	end),

	hp:Observer(function(target)
		table.insert(seen, target:Get())
	end),
	q.Effect(function()
		table.insert(seen, "effect:" .. tostring(hp:Get()))
	end, hp),
}

hp:Set(80)
print(table.concat(seen, ","))
print(label.Text)
