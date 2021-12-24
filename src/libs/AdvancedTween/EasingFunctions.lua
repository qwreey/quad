local EasingFunctions = {}

local function reverse(Index)
	return 1 - Index
end

local Linear = {} do
	Linear.Run = function(Index)
		return Index
	end
end
EasingFunctions["Linear"] = Linear

local Circle = {} do
	Circle.Run = function(Index)
		return 1-((1-Index)^2)
	end
end
EasingFunctions["Circle"] = Circle

local Exp2 = {} do
	local MinIndex = -4
	local MaxIndex = 2
	local GetIndex = function(Index)
		return Index * (MaxIndex - MinIndex) + MinIndex
	end

	local Min = math.exp(MinIndex)
	local Max = math.exp(MaxIndex) - Min

	Exp2.Reverse = true
	Exp2.Run = function(Index)
		-- Index ; max = 1 min = 0
		return (math.exp(GetIndex(Index)) - Min) / Max
	end
end
EasingFunctions["Exp2"] = Exp2

local Exp4 = {} do
	local MinIndex = -4
	local MaxIndex = 4
	local GetIndex = function(Index)
		return Index * (MaxIndex - MinIndex) + MinIndex
	end

	local Min = math.exp(MinIndex)
	local Max = math.exp(MaxIndex) - Min

	Exp4.Reverse = true
	Exp4.Run = function(Index)
		-- Index ; max = 1 min = 0
		return (math.exp(GetIndex(Index)) - Min) / Max
	end
end
EasingFunctions["Exp4"] = Exp4

local Exp2Max4 = {} do
	local MinIndex = -2
	local MaxIndex = 4
	local GetIndex = function(Index)
		return Index * (MaxIndex - MinIndex) + MinIndex
	end

	local Min = math.exp(MinIndex)
	local Max = math.exp(MaxIndex) - Min

	Exp2Max4.Reverse = true
	Exp2Max4.Run = function(Index)
		-- Index ; max = 1 min = 0
		return (math.exp(GetIndex(Index)) - Min) / Max
	end
end
EasingFunctions["Exp2Max4"] = Exp2Max4

return EasingFunctions
