--!strict
-- 재사용 가능한 "monomorphize 헬퍼" 함수 하나로 T별 수동 어노테이션을 없앨 수 있는가?
local function Get<T>(self: State<T>): T
    return nil :: any
end
local function Compute<T, U>(self: State<T>, func: (State<T>) -> U): State<U>
    return nil :: any
end
type State<T> = {
    Get: typeof(Get),
    Compute: typeof(Compute),
}

-- 한 번만 작성되는 재사용 가능한 헬퍼 -- T는 이 함수 자신의 제네릭(호출 시점에 자동 추론)
local function MonomorphicCompute<T>(self: State<T>): (<U>(self: State<T>, func: (State<T>) -> U) -> State<U>)
    return (self :: any).Compute
end

local test: State<number> = (nil :: any) :: State<number>

-- 사용자 쪽 코드 -- T별 수동 주석 없이 헬퍼만 거쳐서 부르면?
local computeFor = MonomorphicCompute(test)
local d1 = computeFor(test, function(a) return a:Get() > 0 end) -- a 무주석
local ok1: boolean = d1:Get()
local wrong1: number = d1:Get()
