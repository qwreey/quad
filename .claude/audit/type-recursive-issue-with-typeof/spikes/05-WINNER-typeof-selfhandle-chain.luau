--!strict
-- 순수 typeof(no setmetatable) + self-handle 콜백 파라미터(quad 실제 계약) + 타입 변경 체이닝
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

local test = (nil :: any) :: State<number>

-- 타입이 바뀌는 체이닝: number -> boolean -> string -> number
local d1 = test:Compute(function(a0: State<number>): boolean return true end)
local d2 = d1:Compute(function(a0: State<boolean>): string return "x" end)
local d3 = d2:Compute(function(a0: State<string>): number return 1 end)

local ok1: boolean = d1:Get()
local ok2: string = d2:Get()
local ok3: number = d3:Get()
local wrong1: string = d1:Get()
local wrong2: number = d2:Get()
local wrong3: boolean = d3:Get()

-- 콜백 안에서 재귀 self 호출(중첩) -- 진짜 quad 패턴(예: Effect가 받은 state에 대해 또 Compute)
local nested = test:Compute(function(a0: State<number>): string
    local innerState = a0:Compute(function(a1: State<number>): boolean return a1:Get() > 0 end)
    local innerVal: boolean = innerState:Get()
    return "y"
end)

-- 존재하지 않는 메소드 -- 반드시 에러 (건전성)
local sound = test:Compute(function(a0: State<number>): number
    a0:NoSuchMethod()
    return 1
end)
