--!strict
-- [보존] 사용자가 2026-08-25에 직접 돌린 탐색 원본(루트 `test.luau`).
-- `const` -> `local`만 고쳤고 나머지는 그대로다. 주석의 기대 진단이 곧 판정.

local function test2<K>(k: K & ("A" | "B"), v: number): K
    return nil :: any
end

local t: "B" = test2("B", 1)
-- TypeError: Expected this to be '"A"', but got '"B"'
local t: "A" = test2("B", 1) -- 에러 발생

local function test3<K>(k: K & ("A" | "B")): index<{ A: number }, K>
    return nil :: any
end

-- number
local a = test3("A")
-- TypeError: Expected this to be 'string', but got 'number'Luau1000
local a: string = test3("A")

local function test4<S, K>(s: S, k: K & ("A" | "B")): index<S, K>
    return nil :: any
end

-- boolean
local b = test4({ A = true}, "A")


-- now we should test index<Self...>
local function getter<Self, K>(self: Self, key: K & (keyof<index<Self, "__realtype">>)): index<index<Self, "__realtype">, K>
    return nil :: any
end

local me = {
    __realtype = {
        name = true
    },
    getter = getter
}
-- name 이 자동완성됩니다. 게다가
me:getter("name")
local t = me:getter("name") -- boolean
-- 음성 대조해보면. 이렇습니다
local t: string = me:getter("name")

-- __call 에 대해서 시도해보죠
local mock = (nil :: any) :: setmetatable<{
    __realtype: {
        name: boolean,
    }
}, {
    __call: typeof(getter),
}>
-- mock() -- self 를 받지 못하네요. __call 은 타입에 인자만 남아야하나봅니다.

type Store<T> = setmetatable<{
}, {
    __call: <K>(K & keyof<T>) -> index<T, K>
}>
local sinst = (nil :: any) :: Store<{
    a: boolean,
    b: number,
}>
-- TypeError: Argument count mismatch. Function expects 1 argument, but 1 is specifiedLuau1008
-- 이해가 안가지만, 아마 어디선가 문제를 일으키나보네요
local b = sinst("a")

-- 완전히 실패합니다. 이전에 확인한것과 같게, T는 넘어갈 수 없다는 논리
local function getter2<Self, K>(key: K & (keyof<Self>)): index<Self, K>
    return nil :: any
end
type Store2<T> = setmetatable<{
}, {
    __call: typeof(getter2<<T>>)
}>
local sinst2 = (nil::any)::Store2<{
    a: boolean, b: number
}>
sinst2()

-- 따라서 이것이 최선일 수 있어요
type Store3<T> = {
    Set: <K>(key: K & keyof<T>, value: index<T, K>) -> Store3<T>,
    Peek: <K>(key: K & keyof<T>) -> index<T, K>,
}
local sinst3 = (nil::any)::Store3<{
    test: boolean
}>
-- 에러가 남. 다만, set 의 시그니처 보기로는 뭘 넣어야할지 바로 감이 안 잡힘.
sinst3.Set("test", 1) -- test 가 자동완성됩니다
-- Set 에 있어서는, 값이 뭔지 알기 힘들기에 직접 인덱스를 허용해야함.


type Store4<T> = {
    Peek: <K>(self: any, key: K & keyof<T>) -> index<T, K>,
} & T
local sinst4 = (nil :: any) :: Store4<{
    test: boolean
}>
-- TypeError: Property 'any' does not exist on type '{ test: boolean }'Luau1038
-- T 가 들어간 것이 self: any 자리에 들어가니, 에러가 납니다
sinst4:Peek("test")


type Store5<T> = {
    Peek: <Inner, K>(self: Store5<Inner>, key: K & keyof<Inner>) -> index<Inner, K>,
} & T
-- peek 의 인자가 에러타입이 됨
local sinst5 = (nil :: any) :: Store5<{
    test: boolean
}>


type Store6<T> = {
    __realtype: T,
    Peek: <Self, K>(self: Self, key: K & keyof<index<Self, "__realtype">>) -> index<index<Self, "__realtype">, K>,
} & T
-- peek 의 인자가 에러타입이 됨
local sinst6 = (nil :: any) :: Store6<{
    test: boolean
}>
-- TypeError: Expected this to be 'number', but got 'boolean'Luau1000
local aaa: number = sinst6:Peek("test")
sinst6:Peek("bbb") -- TypeError: Property '"bbb"' does not exist on type '{ test: boolean }'

-- 이것으로 남는 결론: K& 를 걸고 유니온 스트링을 걸면, K 가 싱글톤으로써, string 으로 뭉개지지 않고 전해진다.
-- K & (...) 상태에서 bbb 를 넣을 순 있음. 그치만 잘 에러가 남. 보면 그대로 index 함수로 잘 싱글톤으로 들어간다는게 이상하게 보이는 부분.

local function singletonTest1<T>(input: T): T
    return input
end
local singletonTest1v = singletonTest1("bbb") -- string

local function singletonTest2<T>(input: T & string): T
    return input
end
local singletonTest2v = singletonTest2("bbb") -- unknown

local function singletonTest2<T>(input: T & ""): T
    return input
end
local singletonTest2v = singletonTest2("bbb") -- "bbb"
-- TypeError: Expected this to be '"" & "bbb"', but got '"bbb"'; 
-- the 2nd component of the intersection is `""`, and `"bbb"` is not a subtype of `""`
-- **여기서 얻는점: 타입 후보 중에서 싱글톤이 있으면, 싱글톤으로 들어간다. 아마도
-- 이것은 싱글톤 중에서 메치를 해야하니, 있는 그대로 string 으로 뭉개지 않고 bbb 로 넘기는듯
-- 싱글톤으로 넘기는 조건이 있다는것이다

local function singletonTest3<T>(input: T | "" | string): T
    return input
end
local singletonTest3v = singletonTest3("bbb") -- "bbb", 에러도 없다.
local singletonTest4v: "a" = singletonTest3("bbb") -- TypeError: Expected this to be '"a"', but got '"bbb"'
-- 확실하다.
