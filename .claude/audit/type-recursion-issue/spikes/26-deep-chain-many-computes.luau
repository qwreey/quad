--!strict
-- 깊은 체이닝 스트레스 테스트: Compute를 10번 이상 연쇄, 타입도 계속
-- 바꿔가며(number -> string -> number -> boolean -> ... ) 무주석 람다로
-- 전부 연결. 얕은 체인(19)에서만 통과하고 깊어지면 솔버가 포기하는지 확인.

export type StateData<T> = {
	Get: (self: StateData<T>) -> T,
}
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}

local function fakeState<T>(v: T): State<T>
	return (nil :: any) :: State<T>
end

local s0: State<number> = fakeState(0)

local s1 = s0:Compute(function(x) return tostring(x:Get()) end)          -- number -> string
local s2 = s1:Compute(function(x) return #x:Get() end)                   -- string -> number
local s3 = s2:Compute(function(x) return x:Get() > 0 end)                -- number -> boolean
local s4 = s3:Compute(function(x) return if x:Get() then 1 else 0 end)   -- boolean -> number
local s5 = s4:Compute(function(x) return x:Get() * 2.5 end)              -- number -> number
local s6 = s5:Compute(function(x) return tostring(x:Get()) end)          -- number -> string
local s7 = s6:Compute(function(x) return x:Get() .. "!" end)             -- string -> string
local s8 = s7:Compute(function(x) return #x:Get() end)                   -- string -> number
local s9 = s8:Compute(function(x) return x:Get() % 3 end)                -- number -> number
local s10 = s9:Compute(function(x) return x:Get() == 0 end)              -- number -> boolean
local s11 = s10:Compute(function(x) return not x:Get() end)              -- boolean -> boolean
local s12 = s11:Compute(function(x) return x:Get() end)                  -- boolean -> boolean (passthrough)

-- 최종 타입이 정확히 boolean으로 좁혀졌는지 실사용 검증(에러 없이 대입되면 통과)
local finalCheck: boolean = s12:Get()

print("26 done", finalCheck)
