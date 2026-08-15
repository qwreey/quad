--!strict

export type Source<T> = {
	Get: (self: Source<T>) -> T,
	Set: (self: Source<T>, value: T) -> (),
}

type function WrapStore(ty: type): type
	local result = types.newtable()
	result:setproperty(types.singleton("Get"), types.newfunction({ head = { result } }, { head = { ty } }))
	result:setproperty(types.singleton("Set"), types.newfunction({ head = { result, ty } }, { head = {} }))
	return result
end

type function ProcessStoreType(ty: type): type
	local props = ty:properties() :: { [type]: { read: type?, write: type? } }
	local result = types.newtable()
	for i, v in props do
		local fieldType = v.read or v.write
		if fieldType then
			result:setproperty(i, WrapStore(fieldType))
		end
	end
	return result
end

type Input = { ty: string, count: number }
type Processed = ProcessStoreType<Input>

local processed: Processed = nil :: any

local checkTy: string = processed.ty:Get()
local checkCount: number = processed.count:Get()

-- negative controls
local wrongTy: number = processed.ty:Get()
processed.ty:Set(123)          -- should error, ty is Source<string>, expects string
processed.count:Set("nope")    -- should error, count is Source<number>
processed.ty:NoSuchMethod()    -- should error
