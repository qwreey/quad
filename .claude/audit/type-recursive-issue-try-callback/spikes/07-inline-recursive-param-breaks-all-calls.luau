--!strict
-- 인라인 선언(구 leaky 방식)에서는 콜백 파라미터가 무주석으로도 추론되는가? (반환타입 leak과 별개 질문)
type State<T> = {
    Get: (self: State<T>) -> T,
    Compute: <U>(self: State<T>, fn: (State<T>) -> U) -> State<U>,
}
local test: State<number> = (nil :: any) :: State<number>
local r = test:Compute(function(a) return tostring(a:Get()) end)
local ok: string = r:Get()
local wrong: number = r:Get()
