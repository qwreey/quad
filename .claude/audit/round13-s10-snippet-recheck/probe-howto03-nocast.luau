--!strict
local q = require("./s10-config")

local viewportHeight = q.Source(400)

local scrollY = q.Source(0)
local gatedScrollY = scrollY:Apply(q.Throttle { Time = 0.1 })

local window = gatedScrollY:Compute(function(y, _previous, height)
	return y:Get() + height:Get()
end, viewportHeight)
print(window)
