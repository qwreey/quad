--!strict
-- 순수 sanity check: 재귀 없는 평범한 제네릭 함수도 콜백 파라미터 무주석 추론이 되는가?
local function Map<T, U>(arr: {T}, fn: (T) -> U): {U}
    return {} :: any
end

local arr: {number} = {1,2,3}
local result = Map(arr, function(a) return tostring(a) end) -- a 무주석

local ok: string = result[1]
local wrong: number = result[1]
