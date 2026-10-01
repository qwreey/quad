--!nocheck
-- Q152 follow-up (scratch): what remains after a public close, how long, what heals it.
local E = require("./env")
local function setup()
	local q = E.newBase()
	local BK, inst = q.Bookkeeping, E.mock.Instance.new("Frame")
	local s, L = {}, {}
	local b = BK.getBlocker(inst)
	b:On()
	for i = 1, 4 do
		s[i] = q.Source(-1); BK.setOffsetSource(inst, i, s[i])
		L[i] = q.Source(2); BK.setLength(inst, i, L[i])
	end
	BK.setLength(inst, 1, 5) -- constant replaces State at 1 while batching
	b:Off()
	return q, BK, inst, s, L, b
end
local function vals(s) local v = {} for i = 1, #s do v[i] = s[i]:Get() end return table.concat(v, ",") end
do
	local q, BK, inst, s = setup()
	print("after :Off()            sources", vals(s), " pull getOffsetAt(2..4) =", BK.getOffsetAt(inst, 2), BK.getOffsetAt(inst, 3), BK.getOffsetAt(inst, 4))
	print("  bk cursors: offsetSetUpTo", BK.getBookkeeping(inst).offsetSetUpTo, "N", BK.getBookkeeping(inst).N)
end
do
	local q, BK, inst, s, L = setup()
	L[4]:Set(3) -- unrelated LATER position's State length changes
	print("after L[4]:Set(3)       sources", vals(s), " (true 0,5,7,9)")
end
do
	local q, BK, inst, s, L = setup()
	L[2]:Set(2) -- same value
	print("after L[2]:Set(same)    sources", vals(s))
end
do
	local q, BK, inst, s = setup()
	BK.setLength(inst, 4, 2) -- re-register LAST position same value
	print("after setLength(4,same) sources", vals(s))
end
do
	local q, BK, inst, s = setup()
	local b = BK.getBlocker(inst)
	b:On(); b:Off() -- a second empty open/close does not heal
	print("after empty On/Off      sources", vals(s))
end
