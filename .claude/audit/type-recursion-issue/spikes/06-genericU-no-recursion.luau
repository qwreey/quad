--!strict
-- State 재귀 자체를 완전히 없애고, self가 그냥 평범한 제네릭 A인
-- 순수 HOF에서도 "로컬 제네릭 U + 콜백 인자 무주석"이 깨지는지 확인.
-- State/Get 개념을 전혀 안 쓰고 가장 순수한 형태로 축소.

type Box<A> = { value: A }

local function Compute<A, U>(self: Box<A>, fn: (self: Box<A>) -> U): U
	return fn(self)
end

local box: Box<number> = { value = 10 }

-- s의 타입이 Box<number>로 바로 주석 없이 추론되어야 하는데,
-- Compute 자체가 로컬 제네릭 U를 갖고 있어서 안 되는지 확인
local doubled = Compute(box, function(s) return s.value * 2 end)

print("06 done")
