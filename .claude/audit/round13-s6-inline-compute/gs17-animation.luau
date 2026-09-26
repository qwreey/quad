--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local count = q.Source(0)
local flash = q.Source(false)

local label = D.TextLabel({
	TextColor3 = count:Compute(function(c)
		local n = c:Get()
		local isMilestone = n > 0 and n % 10 == 0
		return q.Tween({
			Value = if isMilestone then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 255, 255),
			Time = if isMilestone then 0.6 else 0.2,
			Started = if isMilestone then function() flash:Set(true) end else nil,
			Completed = if isMilestone then function() flash:Set(false) end else nil,
			Cancelled = if isMilestone then function() flash:Set(false) end else nil,
		})
	end),
})
print(label)
