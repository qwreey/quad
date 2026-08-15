--!strict
-- test4/5는 콜백이 raw T를 받는 잘못된 계약이었음(quad 실제 계약은 fn(self)가
-- lazy State 핸들 자체를 받음, base/typing-limits.md 참고).
-- self: Box<ImplT>를 그대로 콜백에 넘기도록 정정 + 콜백 안에서 self 메소드를
-- 다시 호출할 수 있는지(=self가 진짜 Box<T>로 타이핑되는지)까지 검증.

local computeImpl = (nil :: any) :: <ImplT>() -> (
    <U>(self: Box<ImplT>, f: (Box<ImplT>) -> U) -> Box<U>
)
local getImpl = (nil :: any) :: <ImplT>() -> (
    (self: Box<ImplT>) -> ImplT
)
local boxImpl = (nil :: any) :: <ImplT>() -> {
    Compute: typeof(computeImpl<<ImplT>>()),
    Get: typeof(getImpl<<ImplT>>()),
}

type Box<T> = setmetatable<{
    inner: T,
}, { __index: typeof(boxImpl<<T>>()) }>

local test = (nil :: any) :: Box<number>

-- CHECK1: 무주석 콜백 파라미터 -- self가 진짜 Box<number>로 추론되는가?
local r1 = test:Compute(function(a0)
    return a0:Get() + 1   -- a0가 Box<number>가 아니면 :Get()에서 에러남
end)

-- CHECK2: 콜백 안에서 a0:Compute(...) 재귀 호출(진짜 self 메소드 접근 가능?)
local r1b = test:Compute(function(a0)
    local inner = a0:Compute(function(a1) return true end)
    return 1
end)

-- CHECK3: 무주석 LHS, 다운스트림 오용 -- 반드시 에러
local r2 = test:Compute(function(a0): number
    return a0:Get() + 1
end)
local wrong2: string = r2:Get()

-- CHECK4: 명시 LHS 오타입 -- 반드시 에러
local wrong3: Box<boolean> = test:Compute(function(a0): number
    return a0:Get() + 1
end)

-- CHECK5: 존재하지 않는 메소드 -- 반드시 에러 (self 타입이 any로 새지 않았는지 확인)
local r3 = test:Compute(function(a0)
    a0:NoSuchMethod()
    return 1
end)
