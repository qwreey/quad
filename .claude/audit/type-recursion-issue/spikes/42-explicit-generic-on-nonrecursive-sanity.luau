--!strict
-- <<...>>가 일반적인(재귀 아닌) 제네릭 함수에는 진짜 작동하는지 sanity
-- check -- 이게 되면 문법/배선 자체는 살아있고, 문제 B는 정말 재귀
-- 케이스에만 있는 별개의 버그라는 뜻.

local function identity<T>(v: T): T
	return v
end

local x = identity<<string>>(5 :: any) -- 명시적으로 string이라고 우김(5는 any로 캐스트해서 통과시킴)
local wrong: number = x -- 진짜 explicit 타입이 먹혔으면(x: string) 여기서 에러여야 함

print("42 done", wrong)
