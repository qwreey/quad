--!nocheck
-- xorshift-free LCG over doubles (deterministic per seed, independent of math.random)
return function(seed)
	local s = (seed * 2654435761) % 4294967296
	local function nextU() s = (s * 1664525 + 1013904223) % 4294967296; return s end
	local R = {}
	function R.int(a, b) return a + nextU() % (b - a + 1) end
	function R.pick(t) return t[R.int(1, #t)] end
	function R.chance(p) return nextU() / 4294967296 < p end
	return R
end
