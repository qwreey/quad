local N, PASSES, RUNS = 1000, 2000, 5
local items, prevs, uds = table.create(N), table.create(N), table.create(N)
for i = 1, N do items[i] = { id = i }; prevs[i] = if i % 3 == 0 then nil else {}; uds[i] = if i % 2 == 0 then i else nil end
local offset = {}
local sink = 0

local function fnPos(item, index, off, prev, ud)
	if item.id == index and off then sink += 1 end
	return prev, ud
end
local function fnCtx(ctx)
	if ctx.item.id == ctx.index and ctx.offset then sink += 1 end
	return ctx.prev, ctx.userdata
end

local variants = {}
variants[1] = { "positional", function()
	for _ = 1, PASSES do for i = 1, N do fnPos(items[i], i, offset, prevs[i], uds[i]) end end
end }
variants[2] = { "fresh table", function()
	for _ = 1, PASSES do for i = 1, N do
		fnCtx({ item = items[i], index = i, offset = offset, prev = prevs[i], userdata = uds[i] })
	end end
end }
variants[3] = { "reuse overwrite", function()
	local ctx = { item = false, index = 0, offset = false, prev = false, userdata = false }
	for _ = 1, PASSES do for i = 1, N do
		ctx.item = items[i]; ctx.index = i; ctx.offset = offset; ctx.prev = prevs[i]; ctx.userdata = uds[i]
		fnCtx(ctx)
	end end
end }
variants[4] = { "reuse + clear/call", function()
	local ctx = {}
	for _ = 1, PASSES do for i = 1, N do
		ctx.item = items[i]; ctx.index = i; ctx.offset = offset; ctx.prev = prevs[i]; ctx.userdata = uds[i]
		fnCtx(ctx); table.clear(ctx)
	end end
end }
variants[5] = { "reuse + clear/pass", function()
	local ctx = {}
	for _ = 1, PASSES do for i = 1, N do
		ctx.item = items[i]; ctx.index = i; ctx.offset = offset; ctx.prev = prevs[i]; ctx.userdata = uds[i]
		fnCtx(ctx)
	end table.clear(ctx) end
end }

local out = {}
for _, v in variants do
	collectgarbage("collect")
	local ts = {}
	for r = 1, RUNS do local t0 = os.clock(); v[2](); ts[r] = os.clock() - t0 end
	table.sort(ts)
	local med = ts[math.ceil(RUNS / 2)]
	table.insert(out, string.format("%-20s %7.1f ms  (%5.1f ns/call)", v[1], med * 1000, med * 1e9 / (N * PASSES)))
end
print(table.concat(out, "\n"))
