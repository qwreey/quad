--!strict
-- FixedCompute<T> 별칭으로 필드를 감싸면 콜론 호출에서 파라미터가 자동으로 풀리는가?
type FixedComputeOf<T> = <U>(self: Box<T>, fn: (Box<T>) -> U) -> Box<U>
type Box<T> = {
    value: T,
    Compute: FixedComputeOf<T>,
}
local self1: Box<number> = (nil :: any) :: Box<number>
local r = self1:Compute(function(a) return tostring(a.value) end)
local ok: string = r.value
local wrong: number = r.value
