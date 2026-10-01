--!nocheck
-- Q152 scratch bench: many small owners in the drive shape (blocker created per owner).
local E = require("./env")
local function best(f)
	local b = math.huge
	for _ = 1, 5 do
		collectgarbage("collect")
		local t0 = os.clock(); f(); b = math.min(b, os.clock() - t0)
	end
	return b * 1000
end
local q = E.newBase()
local BK = q.Bookkeeping
for _, K in { 2000, 10000 } do
	local insts = {}
	for k = 1, K do insts[k] = E.mock.Instance.new("Frame") end
	local kb0 = collectgarbage("count")
	local keep = {}
	local t = best(function()
		keep = {}
		for k = 1, K do
			local inst = E.mock.Instance.new("Frame")
			keep[k] = inst
			local b = BK.getBlocker(inst)
			b:On()
			BK.setOffsetSource(inst, 1, q.None); BK.setLength(inst, 1, 1)
			BK.setOffsetSource(inst, 2, q.None); BK.setLength(inst, 2, 1)
			b:OffWithoutEmit()
			local bk = BK.getBookkeeping(inst)
			if not bk.recomputeBlocker.Blocking then BK._recompute(inst, bk) end
		end
	end)
	collectgarbage("collect")
	local kb = collectgarbage("count") - kb0
	print(string.format("K=%6d owners  drive-shape %8.2f ms  (%.3f us/owner)  live heap Δ %.0f KB (%.1f B/owner)", K, t, t * 1000 / K, kb, kb * 1024 / K))
	-- repeated close on an existing owner (no new blocker): Off vs OffWithoutEmit+_recompute
	local inst = keep[1]
	local b = BK.getBlocker(inst)
	local t2 = best(function() for _ = 1, 10000 do b:On(); b:OffWithoutEmit(); local bk = BK.getBookkeeping(inst); if not bk.recomputeBlocker.Blocking then BK._recompute(inst, bk) end end end)
	local t3 = best(function() for _ = 1, 10000 do b:On(); b:Off() end end)
	print(string.format("   10k reclose on one owner: OffWithoutEmit+_recompute %.2f ms   :Off() %.2f ms", t2, t3))
end
