--!strict
type Source<T> = { Value: T, Set: (self: Source<T>, v: T) -> Source<T> }

-- 예약 키를 팬텀 하나로 줄인다. Peek/Set/Names 는 전부 탑레벨.
type Store<T> = { __store: T } & T

local function peek<Self, K>(s: Self, key: K & keyof<index<Self, "__store">>)
	: index<index<index<Self, "__store">, K>, "Value">
	return nil :: any
end
local function names<Self>(s: Self): { keyof<index<Self, "__store">> }
	return nil :: any
end

local store = (nil :: any) :: Store<{ hp: Source<number>, name: Source<string> }>

local f: Source<number> = store.hp            -- 직접 접근
local g: Source<string> = store.hp            -- 음성 대조군

local a: number = peek(store, "hp")
local b: string = peek(store, "hp")           -- 음성 대조군
local c: string = peek(store, "name")
local d = peek(store, "nope")                 -- 음성 대조군
local n: { "hp" | "name" } = names(store)

-- 사용자가 Peek / Set / Names 를 키로 써도 되는가
local free = (nil :: any) :: Store<{ Peek: Source<number>, Set: Source<boolean>, Names: Source<string> }>
local p: number = peek(free, "Peek")
local q: boolean = peek(free, "Set")
local w: string = peek(free, "Names")
local z: number = peek(free, "Set")           -- 음성 대조군
