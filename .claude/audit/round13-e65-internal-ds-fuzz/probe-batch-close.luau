--!nocheck
-- A handler author opens getBlocker(owner) (public) around several registrations: how can the batch be closed
-- through the PUBLIC surface? (drive closes with OffWithoutEmit + the internal `_recompute`, Dispatch/init.luau:535-541)
local E = require("./env")
for _, how in { "Off", "OffWithoutEmit", "Off+setLength(1,same)" } do
	local q = E.newBase()
	local BK, inst = q.Bookkeeping, E.mock.Instance.new("Frame")
	local s = {}
	local b = BK.getBlocker(inst)
	b:On()
	for i = 1, 4 do s[i] = q.Source(-1); BK.setOffsetSource(inst, i, s[i]); BK.setLength(inst, i, 2) end
	-- change an earlier length while batching: later sources were Set at registration with the OLD prefix
	BK.setLength(inst, 1, 5)
	if how == "Off" then b:Off() elseif how == "OffWithoutEmit" then b:OffWithoutEmit() else b:Off(); BK.setLength(inst, 1, 5) end
	local v = {}
	for i = 1, 4 do table.insert(v, s[i]:Get()) end
	print(string.format("  close by %-22s sources %s   (true 0,5,7,9)  recomputeBlocker=%s", how, table.concat(v, ","), tostring(BK.getBookkeeping(inst).recomputeBlocker.Blocking)))
end
