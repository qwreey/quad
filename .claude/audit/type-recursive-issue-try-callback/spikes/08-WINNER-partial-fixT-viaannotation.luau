--!strict
-- T만 먼저 명시 주석으로 고정한 중간 변수를 거치면, U는 여전히 제네릭이어도 콜백 파라미터가 추론되는가?
local function Compute<T, U>(self: {value: T}, fn: ({value: T}) -> U): {value: U}
    return { value = fn(self) } :: any
end

local self1: {value: number} = { value = 1 }

-- T=number로 고정된 중간 함수 변수(여전히 U는 제네릭)
local computeForNumber: <U>(self: {value: number}, fn: ({value: number}) -> U) -> {value: U} = Compute
local r = computeForNumber(self1, function(a) return tostring(a.value) end)
local ok: string = r.value
