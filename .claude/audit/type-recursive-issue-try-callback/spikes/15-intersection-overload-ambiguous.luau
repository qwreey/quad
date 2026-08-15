--!strict
-- 재귀 아닌 타입에서 오버로드(교차타입)로 콘크리트 분기를 하나 추가하면 그 분기 매칭 시 추론이 되는가?
local ComputeGeneric: (<U>(self: {value: number}, fn: ({value: number}) -> U) -> {value: U})
    & ((self: {value: number}, fn: ({value: number}) -> string) -> {value: string})
    = (nil :: any)

local self1: {value: number} = { value = 1 }
local r = ComputeGeneric(self1, function(a) return tostring(a.value) end)
