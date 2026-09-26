--!nocheck
-- E19 perf side-branch: bookkeeping work per single manual op vs N (mounted, flat leaves).
-- Counters come from the scratch-copy hooks (HOOKS.txt): getOffsetAt calls / its walk iterations,
-- reindex iterations (reindexFrom + reindexRange), bookkeeping array splice iterations, recompute calls / iterations.
local mock = require("./mock")
local Instance = mock.Instance
local function F(n) local f = Instance.new("Frame"); f.Name = n or "f"; return f end
local OPS = {
	{ "Add@1", function(s, n) s:Add(F(), 1) end },
	{ "Add@end", function(s, n) s:Add(F()) end },
	{ "Remove@1", function(s, n) s:Remove(1) end },
	{ "Remove@mid", function(s, n) s:Remove(n // 2) end },
	{ "Replace@mid", function(s, n) s:Replace(n // 2, F()) end },
	{ "Extract@1", function(s, n) s:Extract(1) end },
	{ "Extract@mid+new", function(s, n) s:Extract(n // 2, F()) end },
	{ "Splice@1 rm1 +1", function(s, n) s:Splice(1, 1, F()) end },
	{ "Splice@mid rm5 +5", function(s, n) local t = {}; for i = 1, 5 do t[i] = F() end; s:Splice(n // 2, 5, table.unpack(t)) end },
	{ "Splice@1 +100", function(s, n) local t = {}; for i = 1, 100 do t[i] = F() end; s:Splice(1, 0, table.unpack(t)) end },
	{ "Move 1->n", function(s, n) s:Move(1, n) end },
	{ "Move n->1", function(s, n) s:Move(n, 1) end },
	{ "Move mid->mid+1", function(s, n) s:Move(n // 2, n // 2 + 1) end },
	{ "Swap 1,n", function(s, n) s:Swap(1, n) end },
	{ "Swap mid,mid+1", function(s, n) s:Swap(n // 2, n // 2 + 1) end },
	{ "ExtractAll", function(s, n) s:ExtractAll() end },
	{ "Clear", function(s, n) s:Clear() end },
}
local VARIANTS = { "flat", "nested-sibling" }
print("variant | op | N | getOffsetAt calls | getOffsetAt iters | reindex iters | bk-array splice iters | recompute calls | recompute iters | ms")
for _, variant in VARIANTS do
	for _, N in { 10, 100, 1000, 4000 } do
		for _, op in OPS do
			local q = mock.newQuad()
			q._pc = { reindexCalls = 0, reindexIters = 0, spliceArr = 0, getOffsetAt = 0, getOffsetIters = 0, recompute = 0, recomputeIters = 0 }
			local host = Instance.new("Folder")
			local kids = {}
			for i = 1, N do kids[i] = F("k" .. i) end
			local s = q.Slot(kids)
			local props
			if variant == "flat" then props = { s }
			else
				-- the op runs on `s`, which sits BEFORE a sibling Slot of N leaves in a parent Slot
				local sib = {}
				for i = 1, N do sib[i] = F("s" .. i) end
				local parent = q.Slot({ s, q.Slot(sib) })
				props = { parent }
			end
			q.Dispatch.drive(host, props)
			for k in q._pc do q._pc[k] = 0 end
			local t0 = os.clock()
			op[2](s, N)
			local ms = (os.clock() - t0) * 1000
			local pc = q._pc
			print(`{variant} | {op[1]} | {N} | {pc.getOffsetAt} | {pc.getOffsetIters} | {pc.reindexIters} | {pc.spliceArr} | {pc.recompute} | {pc.recomputeIters} | {string.format("%.2f", ms)}`)
		end
	end
end
