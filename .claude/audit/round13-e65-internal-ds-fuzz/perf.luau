--!nocheck
-- E65 performance shape (CLI luau 0.734, mock backend; os.clock, best of 3). usage (repo root):
--   luau .claude/audit/round13-e65-internal-ds-fuzz/perf.luau
local E = require("./env")
local SRC = "../../../quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src/"
local EpochMap = require(SRC .. "EpochMap")
local Relate = require(SRC .. "Relate")
local function best(f)
	local b = math.huge
	for _ = 1, 3 do
		collectgarbage("collect")
		local t0 = os.clock(); f(); b = math.min(b, os.clock() - t0)
	end
	return b * 1000
end
local function setup(N, withSrc, batched)
	local q = E.newBase()
	local BK, inst = q.Bookkeeping, E.mock.Instance.new("Frame")
	local srcs = {}
	local b = BK.getBlocker(inst)
	if batched then b:On() end
	for i = 1, N do
		local s = if withSrc then q.Source(0) else q.None
		srcs[i] = s
		BK.setOffsetSource(inst, i, s); BK.setLength(inst, i, 1)
	end
	if batched then b:OffWithoutEmit(); BK._recompute(inst, BK.getBookkeeping(inst)) end
	return q, BK, inst, srcs
end
print("-- registration: batched (drive-like, one recompute at close) vs unbatched (recompute per setLength)")
for _, N in { 1000, 2000, 4000, 8000 } do
	local tb = best(function() setup(N, true, true) end)
	local tu = if N <= 4000 then best(function() setup(N, true, false) end) else nil
	print(string.format("  N=%5d batched %8.2f ms   unbatched %s", N, tb, if tu then string.format("%9.2f ms", tu) else "(skipped)"))
end
print("-- one constant length change at position 1 (recompute over N; Sources vs None)")
for _, N in { 1000, 2000, 4000, 8000, 16000 } do
	local _, BK, inst = setup(N, true, true)
	local k = 0
	local ts = best(function() for _ = 1, 10 do k += 1; BK.setLength(inst, 1, k % 3) end end) / 10
	local _, BK2, inst2 = setup(N, false, true)
	local tn = best(function() for _ = 1, 10 do k += 1; BK2.setLength(inst2, 1, k % 3) end end) / 10
	local tg = best(function() for _ = 1, 10 do k += 1; BK2.setLength(inst2, 1, k % 3); BK2.getOffsetAt(inst2, N) end end) / 10
	print(string.format("  N=%5d  Sources %7.3f ms/change   None %7.3f ms/change   None+getOffsetAt(N) %7.3f ms", N, ts, tn, tg))
end
print("-- change at the LAST position (cursor lowered to N: should be ~flat)")
for _, N in { 1000, 4000, 16000 } do
	local _, BK, inst = setup(N, true, true)
	local k = 0
	local t = best(function() for _ = 1, 100 do k += 1; BK.setLength(inst, N, k % 3) end end) / 100
	print(string.format("  N=%5d  %7.4f ms/change", N, t))
end
print("-- Relate: M SetStrong+GetStrong over M/10 insts")
for _, M in { 1e4, 1e5, 4e5 } do
	local r = Relate()
	local insts = {}
	for i = 1, M / 10 do insts[i] = {} end
	local t = best(function()
		for i = 1, M do local inst = insts[(i % #insts) + 1]; r:SetStrong(inst, i % 7, i); r:GetStrong(inst, i % 7) end
	end)
	print(string.format("  M=%7d  %8.2f ms  (%.3f us/pair)", M, t, t * 1000 / M))
end
print("-- EpochMap: Update(set of k) and Refresh over a map of k keys")
for _, K in { 1e3, 1e4, 1e5 } do
	local q = E.newBase()
	local set = {}
	for _ = 1, K do set[q.Source(0)] = true end
	local m = EpochMap()
	m:Sync(set)
	local tu = best(function() m:Update(set) end)
	local tr = best(function() m:Refresh() end)
	print(string.format("  K=%6d  Update %7.2f ms  Refresh %7.2f ms", K, tu, tr))
end
