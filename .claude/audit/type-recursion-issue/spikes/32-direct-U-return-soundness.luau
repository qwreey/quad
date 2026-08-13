--!strict
type Box = { value: number }
local function Compute<U>(self: Box, fn: (self: Box) -> U): U
	return fn(self)
end
local box: Box = { value = 10 }
local doubled = Compute(box, function(s) return s.value * 2 end)
local wrong: string = doubled -- doubled는 number여야 함, 진짜 타입체크되면 여기서 에러
print("32 done", wrong)
