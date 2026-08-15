--!strict
-- quad 실제 State/Compute 모양(typeof 패턴) + T 고정 중간변수 트릭을 실제 계약(중첩 self 호출 포함)으로 검증
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

local test: State<number> = (nil :: any) :: State<number>

-- T=number로 고정한 중간 변수 (콜백 파라미터 무주석 시도)
local computeForNumber: <U>(self: State<number>, func: (State<number>) -> U) -> State<U> = Compute
local d1 = computeForNumber(test, function(a) return a:Get() > 0 end) -- a 무주석, boolean 반환 기대
local ok1: boolean = d1:Get()
local wrong1: number = d1:Get()

-- 중첩: 콜백 안에서 a를 또 Compute(quad :Apply factory 패턴과 동형) -- 안쪽도 T=number로 고정한 중간변수를 통해서만 무주석 가능한지 확인
local nested = computeForNumber(test, function(a)
    local innerComputeForNumber: <U2>(self: State<number>, func: (State<number>) -> U2) -> State<U2> = Compute
    local inner = innerComputeForNumber(a, function(a1) return a1:Get() > 0 end) -- a1도 무주석 시도
    local innerOk: boolean = inner:Get()
    return "y"
end)
local ok2: string = nested:Get()

-- 존재하지 않는 메소드 호출 -- 반드시 에러
local sound = computeForNumber(test, function(a)
    a:NoSuchMethod()
    return 1
end)
