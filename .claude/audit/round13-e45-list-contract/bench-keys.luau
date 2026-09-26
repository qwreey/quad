--!nocheck
-- E45 3(f): 1000-item :List, keyFn cost by key type (mount / same-keys recycle / reversed recycle); median of 5
local E = require("./env")
local mk = E.mk
local N = 1000
local function med(t) table.sort(t) return t[math.ceil(#t / 2)] end
local kinds = {
	{ "index(default)", nil, function(i) return { n = i } end },
	{ "number", function(it) return it.n end, function(i) return { n = i } end },
	{ "string", function(it) return it.s end, function(i) return { n = i, s = "id" .. i } end },
	{ "table", function(it) return it end, function(i) return { n = i } end },
	{ "Instance", function(it) return it.inst end, function(i) return { n = i, inst = mk("k" .. i) } end },
}
for _, k in kinds do
	local tm, tr, tv, tkey = {}, {}, {}, {}
	for rep = 1, 5 do
		local q = E.newQ()
		local items = table.create(N)
		for i = 1, N do items[i] = k[3](i) end
		local rev = table.create(N)
		for i = 1, N do rev[i] = items[N - i + 1] end
		local data = q.Source(items)
		local s = q.Slot()
		s:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or mk("e") end, k[2])
		local p = E.I.new("Folder")
		local t0 = os.clock(); q.Dispatch.drive(p, { s }); tm[rep] = os.clock() - t0
		local copy = table.clone(items)
		t0 = os.clock(); data:Set(copy); tr[rep] = os.clock() - t0
		t0 = os.clock(); data:Set(rev); tv[rep] = os.clock() - t0
		-- keyFn alone
		local f = k[2] or function(_, i) return i end
		t0 = os.clock(); local seen = {} for i, it in ipairs(items) do seen[f(it, i)] = true end tkey[rep] = os.clock() - t0
		assert(s.Length:Get() == N)
	end
	print(string.format("B | %-15s | mount %.2f ms | recycle same %.2f ms | recycle reversed %.2f ms | keyFn+hash only %.3f ms", k[1], med(tm) * 1e3, med(tr) * 1e3, med(tv) * 1e3, med(tkey) * 1e3))
end
