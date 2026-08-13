--!strict
-- 06에서 Box<A>까지 제네릭이었던 것을 Box(비제네릭, number 고정)로 낮춰서
-- "재귀적 self 타입이 없는 상태에서 U만 제네릭"인 경우를 04와 대조.

type Box = { value: number }

local function Compute<U>(self: Box, fn: (self: Box) -> U): U
	return fn(self)
end

local box: Box = { value = 10 }

local doubled = Compute(box, function(s) return s.value * 2 end)

print("07 done")
