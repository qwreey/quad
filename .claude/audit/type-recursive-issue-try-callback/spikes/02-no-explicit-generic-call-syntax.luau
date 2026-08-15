--!strict
-- Luau에 함수 호출부에서 제네릭 타입 인자를 명시하는 문법이 있는지 확인
-- (TS의 `f<number>(x)`류 -- 있다면 T를 호출부에서 못박아 콜백 파라미터를
--  추론시킬 실마리가 될 수 있었음).
--
-- 결론: 둘 다 SyntaxError. Luau는 함수 호출에 대한 명시적 제네릭 인자
-- 문법 자체가 없음(타입 별칭 인스턴스화 `Array<number>`와는 다른 문법).
local function Map<T, U>(arr: {T}, fn: (T) -> U): {U}
    return {} :: any
end
local arr: {number} = {1, 2, 3}

-- 시도 1: `::<...>` 형태 -- SyntaxError
local result1 = Map::<number, string>(arr, function(a) return tostring(a) end)

-- 시도 2: `<...>` 바로 붙이는 형태(제네릭 함수 호출 관용구가 있다면 이 모양일 것) -- SyntaxError
local result2 = Map<number, string>(arr, function(a) return tostring(a) end)
