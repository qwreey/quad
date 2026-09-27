--!nocheck
-- deterministic PRNG (CLI luau has no Roblox `Random`): 32-bit xorshift, Random-like surface
local R = {}
R.__index = R
function R.new(seed)
	local s = bit32.bxor(seed * 2654435761 % 4294967296, 0x9E3779B9)
	if s == 0 then s = 1 end
	return setmetatable({ s = s }, R)
end
function R:u32()
	local x = self.s
	x = bit32.bxor(x, bit32.lshift(x, 13))
	x = bit32.bxor(x, bit32.rshift(x, 17))
	x = bit32.bxor(x, bit32.lshift(x, 5))
	self.s = x
	return x
end
function R:NextNumber() return self:u32() / 4294967296 end
function R:NextInteger(a, b) return a + (self:u32() % (b - a + 1)) end
return R
