--!nocheck
local vals = {0, -0, 1.5, -1.5, -1, 2^31, 2^32, 2^32+5, 2^53, 2^53+2, -2^53, 2^63, 2^63+2^11, -2^63, -2^63-4096, 2^64, 1e300, -1e300, 0/0, math.huge, -math.huge, 4294967295.9, -4294967296.5}
for _, v in vals do
	local ok, r = pcall(bit32.band, v, 0xFFFFFFFF)
	local ok2, r2 = pcall(bit32.bnot, v)
	print(string.format("%-22s band=%s bnot=%s", tostring(v), tostring(r), tostring(r2)))
end
for _, d in {0, 1, 31, 32, 33, 64, -1, -31, -32, -33, 1.5, -1.5, 0/0, math.huge, -math.huge, 2^31, 2^32, 2^31+1, -2^31, -2^31-1, 1e10, 2^63} do
	local ok, r = pcall(bit32.lshift, 0x80000001, d)
	local ok2, r2 = pcall(bit32.rshift, 0x80000001, d)
	print(string.format("shift %-12s l=%s r=%s", tostring(d), tostring(r), tostring(r2)))
end
print(math.min(0/0, 1), math.min(1, 0/0), math.max(0/0,1), math.max(1,0/0))
print(pcall(math.clamp, 0/0, 0, 1), pcall(math.clamp, 5, 0, 0), pcall(math.clamp, -0, 0, 1), 1/math.clamp(-0,0,1), 1/math.clamp(-0, -0, 0))
print(pcall(math.clamp, math.huge, 0, 1), pcall(math.clamp, 5, -math.huge, math.huge))
print(1/math.min(0,-0), 1/math.min(-0,0), 1/math.max(0,-0), 1/math.max(-0,0))
