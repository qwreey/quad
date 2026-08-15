--!strict

type function MakeState(ty: type): type
	local result = types.newtable()
	local U = types.generic("U")
	result:setproperty(types.singleton("Get"), types.newfunction({ head = { result } }, { head = { ty } }))
	result:setproperty(types.singleton("Compute"), types.newfunction(
		{ head = { result, types.newfunction({ head = { result } }, { head = { U } }) } },
		{ head = { MakeState(U) } },
		{ U }
	))
	return result
end

type S = MakeState<number>
local s: S = nil :: any
local r = s:Compute(function(a0) return "hi" end)
local checkGet: string = r:Get()
