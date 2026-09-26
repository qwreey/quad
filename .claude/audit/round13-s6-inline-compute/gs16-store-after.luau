--!strict
local Setup = require("./_setup")
local q = Setup.q
local D = q.Declaration

local settings = { Step = q.Source(1) }
local stepText = settings.Step:Compute(function(s)
	return `보폭: {s:Get()}`
end)

local stepButton = D.TextButton({
	Size = UDim2.fromOffset(120, 32),
	Text = stepText,
	Activated = function()
		settings.Step:Set(settings.Step:Get() % 5 + 1)
	end,
})
print(stepButton)
