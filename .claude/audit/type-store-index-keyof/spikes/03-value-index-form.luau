--!strict
type Source<T> = { Value: T, Get: (self: Source<T>) -> T, Set: (self: Source<T>, v: T) -> Source<T> }

-- T 는 평범한 값 타입. __index/__newindex 가 Get/Set 을 대행하고,
-- Peek 이 Source<> 를 씌워 준다.
type Store<T> = {
	__store: T,     -- 팬텀. 사용은 UB.
	Peek: <Self, K>(self: Self, key: K & keyof<index<Self, "__store">>)
	       -> Source<index<index<Self, "__store">, K>>,
} & T

local store = (nil :: any) :: Store<{ hp: number, name: string }>

-- (1) __index → 값
local a: number = store.hp
local b: string = store.hp                 -- 음성 대조군

-- (2) __newindex → 대입
store.hp = 5
store.hp = "five"                          -- 음성 대조군

-- (3) Peek → Source<값>
local c: Source<number> = store:Peek("hp")
local d: Source<string> = store:Peek("hp") -- 음성 대조군
local e: Source<string> = store:Peek("name")
local f = store:Peek("nope")               -- 음성 대조군

-- (4) Peek 결과를 반응형으로 씀
store:Peek("hp"):Set(3)
store:Peek("hp"):Set("3")                  -- 음성 대조군

-- (5) 사용자가 Peek 을 자기 키로 쓰면
local clash = (nil :: any) :: Store<{ Peek: number }>
local g = clash:Peek("Peek")
