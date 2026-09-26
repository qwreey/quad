local runs = 0
local function InitCounter(_module)
	runs += 1
end

local m = Quad.New()
m:RunInit(InitCounter)
m:RunInit(InitCounter) -- no-op
print(runs) --> 1
