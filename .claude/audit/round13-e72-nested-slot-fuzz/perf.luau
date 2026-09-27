--!nocheck
-- E72 perf: nesting depth / width shape of Slot-as-ownerKey bookkeeping (mock CLI, ordered oracle native ops).
-- usage: mise exec -- luau .claude/audit/round13-e72-nested-slot-fuzz/perf.luau
local E = require("./env")
local I = E.mock.Instance
local function now() return os.clock() end
local function leaf() return I.new("Frame") end

-- chain of D manual Slots, each level = { k leaves..., child }; deepest holds `deepN` leaves
local function build(q, D, k, deepN)
	local levels = {}
	local child = nil
	for d = D, 1, -1 do
		local items = {}
		local n = if d == D then deepN else k
		for _ = 1, n do table.insert(items, leaf()) end
		if child then table.insert(items, child) end
		child = q.Slot(items)
		levels[d] = child
	end
	return levels
end
local function counters(q, slots)
	local c = { L = 0, O = 0, keep = {} }
	for _, s in ipairs(slots) do
		local a = s.Length:Observer(function() c.L += 1 end); a:Subscribe()
		local b = s.Offset:Observer(function() c.O += 1 end); b:Subscribe()
		table.insert(c.keep, a); table.insert(c.keep, b)
	end
	c.L, c.O = 0, 0
	return c
end
local function run(D, k, deepN, W)
	W = W or 1
	local q, env = E.newBase()
	local host = I.new("Frame")
	local front = q.Slot({ leaf() })
	local chains, all = {}, {}
	for w = 1, W do
		chains[w] = build(q, D, k, deepN)
		for _, s in ipairs(chains[w]) do table.insert(all, s) end
	end
	local props = { front }
	for w = 1, W do table.insert(props, chains[w][1]) end
	local t0 = now()
	local ok, err = pcall(q.Dispatch.drive, host, props)
	local tMount = now() - t0
	if not ok then return { err = E.id(err) .. " " .. tostring(err):sub(1, 120) } end
	local c = counters(q, all)
	local r = { mount = tMount }
	-- p1: front insert shifts every nested Offset
	t0 = now(); front:Add(leaf(), 1); r.front = now() - t0; r.frontL, r.frontO = c.L, c.O; c.L, c.O = 0, 0
	-- p2: deepest (first chain) front insert: Length climbs D levels
	local deepest = chains[1][D]
	t0 = now(); local ok2, e2 = pcall(function() deepest:Add(leaf(), 1) end); r.deep = now() - t0
	if not ok2 then r.err = "deepAdd " .. E.id(e2) .. " " .. tostring(e2):sub(1, 100) return r end
	r.deepL, r.deepO = c.L, c.O; c.L, c.O = 0, 0
	-- p3: extract level-2 subtree of chain 1 and put it back
	if D >= 2 then
		t0 = now(); local sub = chains[1][1]:Extract(k + 1); chains[1][1]:Add(sub); r.reAdd = now() - t0
		r.reL, r.reO = c.L, c.O
	end
	-- sanity: oracle order = expected flatten
	local exp = {}
	local function fl(s) for i = 1, #s._elements do local e = s:Get(i); if E.Quad and q.isSlot(e) then fl(e) else table.insert(exp, e) end end end
	for _, p in ipairs(props) do fl(p) end
	local got = env.P(host)
	local same = #exp == #got
	for i = 1, #exp do if exp[i] ~= got[i] then same = false end end
	r.orderOk = same and #env.viol == 0
	r.len = chains[1][1].Length:Get()
	return r
end
local function us(x) return string.format("%.0f", x * 1e6) end
print("# depth sweep (k=2 leaves per level, deepest 2 leaves, W=1)")
print("D | mount us | frontAdd us (L,O notifs) | deepAdd us (L,O) | extract+reAdd lvl2 us (L,O) | orderOk")
for _, D in ipairs({ 2, 4, 6, 8, 16, 32, 64, 128 }) do
	local best
	for _ = 1, 3 do
		local r = run(D, 2, 2)
		if r.err then print(D, "ERR", r.err) break end
		if not best or r.front < best.front then best = r end
	end
	if best then
		print(`{D} | {us(best.mount)} | {us(best.front)} ({best.frontL},{best.frontO}) | {us(best.deep)} ({best.deepL},{best.deepO}) | {us(best.reAdd or 0)} ({best.reL or 0},{best.reO or 0}) | {tostring(best.orderOk)}`)
	end
end
print("# deepest-leaf count sweep (D=8, k=2): deepAdd = recompute of the deepest Slot from position 1 + D-level climb")
for _, N in ipairs({ 100, 200, 400, 800, 1600, 3200 }) do
	local r = run(8, 2, N)
	print(`N={N} | mount {us(r.mount)} us | deepAdd {us(r.deep)} us ({r.deepL},{r.deepO}) | frontAdd {us(r.front)} us | orderOk {tostring(r.orderOk)}`)
end
print("# width sweep (W chains of D=6, k=2): frontAdd shifts W*D Offsets")
for _, W in ipairs({ 1, 4, 16, 64, 256 }) do
	local r = run(6, 2, 2, W)
	print(`W={W} slots={W * 6} | mount {us(r.mount)} us | frontAdd {us(r.front)} us ({r.frontL},{r.frontO}) | deepAdd(chain1) {us(r.deep)} us ({r.deepL},{r.deepO}) | orderOk {tostring(r.orderOk)}`)
end
print("# stack limit probe (k=1, deepest 1): does mount / deepest Add survive?")
for _, D in ipairs({ 100, 150, 200, 300, 400, 800 }) do
	local r = run(D, 1, 1)
	if r.err then print(`D={D} ERR {r.err}`) else print(`D={D} ok mount {us(r.mount)} us deepAdd {us(r.deep)} us len {r.len} orderOk {tostring(r.orderOk)}`) end
end
