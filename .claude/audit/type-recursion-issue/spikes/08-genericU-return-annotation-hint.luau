--!strict
-- luau-analyze가 06/07에서 "Consider annotating the return with number"라고
-- 직접 제안함. 그 제안대로 콜백의 리턴 타입만(파라미터는 여전히 무주석)
-- 명시하면 self 파라미터까지 같이 풀리는지 확인.

type Box = { value: number }

local function Compute<U>(self: Box, fn: (self: Box) -> U): U
	return fn(self)
end

local box: Box = { value = 10 }

local doubled = Compute(box, function(s): number return s.value * 2 end)

print("08 done")
