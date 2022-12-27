local EasingFunctions = {}

local Exp2 = {} do
	local MinIndex = -4
	local MaxIndex = 2
	local GetIndex = function(Index)
		return Index * (MaxIndex - MinIndex) + MinIndex
	end

	local exp = math.exp
	local Min = exp(MinIndex)
	local Max = exp(MaxIndex) - Min

	Exp2.Reverse = true
	Exp2.Run = function(Index)
		-- Index ; max = 1 min = 0
		return (exp(GetIndex(Index)) - Min) / Max
	end
end
EasingFunctions["Exp2"] = Exp2

local Exp4 = {} do
	local MinIndex = -4
	local MaxIndex = 4
	local GetIndex = function(Index)
		return Index * (MaxIndex - MinIndex) + MinIndex
	end

	local exp = math.exp
	local Min = exp(MinIndex)
	local Max = exp(MaxIndex) - Min

	Exp4.Reverse = true
	Exp4.Run = function(Index)
		-- Index ; max = 1 min = 0
		return (exp(GetIndex(Index)) - Min) / Max
	end
end
EasingFunctions["Exp4"] = Exp4

local Linear = {} do
	Linear.Reverse = false
	Linear.Run = function(Index)
		return Index
	end
end
EasingFunctions["Linear"] = Linear

local Expo = {} do
	Expo.Reverse = false
	Expo.Run = function(Index)
		if Index == 1 then return 1 end
		if Index == 0 then return 0 end
		return 1 - 2^(-10 * Index)
	end
end
EasingFunctions["Expo"] = Expo

local Quint = {} do
	Quint.Reverse = false
	Quint.Run = function(Index)
		if Index == 1 then return 1 end
		if Index == 0 then return 0 end
		return 1 - ((1 - Index)^5)
	end
end
EasingFunctions["Quint"] = Quint

local Quart = {} do
	Quart.Reverse = false
	Quart.Run = function(Index)
		if Index == 1 then return 1 end
		if Index == 0 then return 0 end
		return 1 - ((1 - Index)^4)
	end
end
EasingFunctions["Quart"] = Quart

local Cubic = {} do
	Cubic.Reverse = false
	Cubic.Run = function(Index)
		if Index == 1 then return 1 end
		if Index == 0 then return 0 end
		return 1 - ((1 - Index)^3)
	end
end
EasingFunctions["Cubic"] = Cubic

local Quad = {} do
	Quad.Reverse = false
	Quad.Run = function(Index)
		if Index == 1 then return 1 end
		if Index == 0 then return 0 end
		return 1 - ((1 - Index)^2)
	end
end
EasingFunctions["Quad"] = Quad

local Sin = {} do
	local pi2 = math.pi/2
	local sin = math.sin
	Sin.Reverse = false
	Sin.Run = function(Index)
		if Index == 1 then return 1 end
		if Index == 0 then return 0 end
		return sin(Index * pi2);
	end
end
EasingFunctions["Sin"] = Sin

local Circle = {} do
	local sqrt = math.sqrt
	Circle.Run = function(Index)
		if Index == 1 then return 1 end
		if Index == 0 then return 0 end
		return sqrt(1-(1-Index)^2)
	end
end
EasingFunctions["Circle"] = Circle

local Back = {} do
	local c1 = 1.70158
	local c3 = 2.70158
	Back.Reverse = false
	Back.Run = function(Index)
		if Index == 1 then return 1 end
		if Index == 0 then return 0 end
		return 1 + c3 * (Index-1)^3 + c1 * (Index-1)^2
	end
end
EasingFunctions["Back"] = Back

local Elastic = {} do
	local sin = math.sin
	local pi = math.pi
	Elastic.Reverse = false
	Elastic.Run = function(Index)
		if Index == 1 then return 1 end
		if Index == 0 then return 0 end
		return (2^(-10*Index))*(sin((Index*10-0.75)*(2*pi/3)))+1
	end
end
EasingFunctions["Elastic"] = Elastic

local Bounce = {} do
	local n1 = 7.5625
	local d1 = 2.75
	Bounce.Reverse = false
	Bounce.Run = function(Index)
		if Index > 0.995 then return 1 end
		if Index < 0.005 then return 0 end
		if Index < 1 / d1 then
			return n1 * Index^2
		elseif Index < 2 / d1 then
			return n1 * (Index - 1.5/d1)^2 + 0.75
		elseif Index < 2.5 / d1 then
			return n1 * (Index - 2.25/d1)^2 + 0.9375
		else
			return n1 * (Index - 2.625/d1)^2 + 0.984375
		end
	end
end
EasingFunctions["Bounce"] = Bounce

return EasingFunctions
