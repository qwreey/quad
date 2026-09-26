local function doublePlugin(_self)
	return {
		Double = function(_selfArg, v: number)
			return v * 2
		end,
	}
end

local m = Quad.New():AddPlugin(doublePlugin)
print(m:Double(21)) --> 42
