--!strict
--[[
	Small derivations shared by widgets (internal helpers, but stable for the other kit files). Each call mints one
	Compute node — call once per widget, not per frame.

		Util.px(state)        State<number>  -> State<UDim>   (offset only)
		Util.pxX(state)       State<Vector2> -> State<UDim>   (.X as offset)
		Util.pxY(state)       State<Vector2> -> State<UDim>   (.Y as offset)
		Util.offset2(state)   State<Vector2> -> State<UDim2>  (fromOffset)
]]

local Quad = require("./Quad")

type State<T> = Quad.State<T>

local Util = {}

function Util.px(s: State<number>): State<UDim>
	local out: State<UDim> = s:Compute(function(self)
		return UDim.new(0, self:Get())
	end)
	return out
end

function Util.pxX(s: State<Vector2>): State<UDim>
	local out: State<UDim> = s:Compute(function(self)
		return UDim.new(0, self:Get().X)
	end)
	return out
end

function Util.pxY(s: State<Vector2>): State<UDim>
	local out: State<UDim> = s:Compute(function(self)
		return UDim.new(0, self:Get().Y)
	end)
	return out
end

function Util.offset2(s: State<Vector2>): State<UDim2>
	local out: State<UDim2> = s:Compute(function(self)
		local v = self:Get()
		return UDim2.fromOffset(v.X, v.Y)
	end)
	return out
end

return Util
