local QuadTypes = require("@game/ReplicatedStorage/roblox_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.KeyGone`·`QuadTypes.SlotItem<T>`)

local width = q.Source(200)
local topbar = q.Source(60)

-- v1: myStore "width,topbar":With(function(w, tb) ... end)
local size = width:Compute(function(
	self: q.StateData<number>,
	_prev: UDim2?,
	tb: q.StateData<number>
): UDim2
	return UDim2.fromOffset(self:Get(), tb:Get())
end, topbar)

local frame = D.Frame { Size = size }
