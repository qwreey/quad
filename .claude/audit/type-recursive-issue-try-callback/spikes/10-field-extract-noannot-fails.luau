--!strict
-- 필드 추출을 손으로 재주석하지 않고 그냥 뽑아서 두 단계로 호출하면?
type Box<T> = {
    value: T,
    Compute: <U>(self: Box<T>, fn: (Box<T>) -> U) -> Box<U>,
}
local self1: Box<number> = (nil :: any) :: Box<number>

local extractedCompute = self1.Compute  -- 재주석 없이 그대로 추출
local r = extractedCompute(self1, function(a) return tostring(a.value) end)
local ok: string = r.value
local wrong: number = r.value
