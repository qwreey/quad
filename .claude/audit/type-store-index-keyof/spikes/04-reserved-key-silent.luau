--!strict
type Source<T> = { Value: T, Get: (self: Source<T>) -> T, Set: (self: Source<T>, v: T) -> Source<T> }
type Store<T> = {
	__store: T,
	Peek: <Self, K>(self: Self, key: K & keyof<index<Self, "__store">>)
	       -> Source<index<index<Self, "__store">, K>>,
} & T

-- 사용자 키 이름이 예약 이름과 겹칠 때
local clash = (nil :: any) :: Store<{ Peek: number, __store: boolean }>
local g1: Source<number> = clash:Peek("Peek")   -- 메소드로 부를 수 있나 / 무엇이 나오나
local g2: number = clash.Peek                   -- 필드로 읽으면
local g3: string = clash.Peek                   -- 음성 대조군
local g4 = clash:Peek("__store")                -- 팬텀 이름을 키로
