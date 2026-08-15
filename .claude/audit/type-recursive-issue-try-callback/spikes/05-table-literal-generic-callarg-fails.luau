--!strict
-- 제네릭 함수 호출의 "인자"로 테이블 리터럴을 넘기면(그 안에 콜백을 담아서) 컨텍스트 추론이 살아나는가?
local function Foo<T, U>(arr: {T}, handlers: { fn: (T) -> U }): {U}
    return {} :: any
end
local arr: {number} = {1,2,3}
local result = Foo(arr, { fn = function(a) return tostring(a) end })
local ok: {string} = result
