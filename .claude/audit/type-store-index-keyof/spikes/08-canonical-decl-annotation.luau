--!strict
export type StateData<T> = { Get: (self: StateData<T>) -> T }
export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>) -> U) -> State<U>,
}
export type Source<T> = State<T> & { Value: T, Set: (self: Source<T>, v: T) -> Source<T> }
type Rec = { hp: number, name: string? }
type Store<T> = {
	__store: T,
	Of: <Self, K>(self: Self, key: K & keyof<index<Self, "__store">>)
	     -> Source<index<index<Self, "__store">, K>>,
} & T
local store = (nil :: any) :: Store<Rec>

-- (A) 반환값 무주석 추론 — 먹히는가?
local hp = store:Of("hp")
local a1: number = hp:Get()     -- 통과해야 함
local a2: string = hp:Get()     -- 음성 대조군: 걸려야 함
local a3 = hp:NoSuchMethod()    -- 음성 대조군: 걸려야 함
hp:Set(5)
hp:Set("5")                     -- 음성 대조군: 걸려야 함

-- (B) name 은 string? 인가
local nm = store:Of("name")
local b1: string? = nm:Get()
local b2: number = nm:Get()     -- 음성 대조군

-- (C) Compute 콜백 파라미터 무주석 (문제 A)
local c1 = hp:Compute(function(s) return s:Get() * 2 end)

-- (D) 콜백 파라미터에 주석을 달면
local d1 = hp:Compute(function(s: StateData<number>) return s:Get() * 2 end)
