--!strict
-- 2x2 매트릭스의 D칸: 재귀형 + T를 중간변수로 고정 + U만 제네릭
type Box<T> = {
    value: T,
    Compute: <U>(self: Box<T>, fn: (Box<T>) -> U) -> Box<U>,
}
local function ComputeImpl<T, U>(self: Box<T>, fn: (Box<T>) -> U): Box<U>
    return { value = fn(self) } :: any
end

local self1: Box<number> = (nil :: any) :: Box<number>

-- T=number로 고정한 중간 변수 (U만 여전히 제네릭), self1.Compute가 아니라 자유함수를 통해
local computeForNumber: <U>(self: Box<number>, fn: (Box<number>) -> U) -> Box<U> = ComputeImpl
local r = computeForNumber(self1, function(a) return tostring(a.value) end)
local ok: string = r.value
local wrong: number = r.value
