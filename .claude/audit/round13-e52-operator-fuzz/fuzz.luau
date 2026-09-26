--!nocheck
-- E52 differential fuzzer: q.Operator vs model.luau.  Run from repo root after ./scripts/relink.sh:
--   luau .claude/audit/round13-e52-operator-fuzz/fuzz.luau -a <seeds> [start] [verbose] [mutant]
local q = require("../../../quad-base/src")
local M = require("./model")
local newRng = require("./rng")
local Op = q.Operator
local None = q.None
local SEEDS = tonumber((select(1, ...))) or 1000
local START = tonumber((select(2, ...))) or 1
local VERBOSE = (select(3, ...)) == "v"
local MUT = select(4, ...)
if MUT == "sumfirst" then local f = M.FOLD.Sum; M.FOLD.Sum = function(a, b) return f(b, a) end end -- (no-op for numbers, sanity that it stays 0)
if MUT == "noneisnil" then local e = M.eval; M.eval = function(op, a, n, tv) if tv == None then tv = nil end return e(op, a, n, tv) end end
if MUT == "floorbits" then M.u32 = function(x) if x ~= x or math.abs(x) == math.huge or math.abs(x) >= 2^63 then return 0 end return math.floor(x) % 2^32 end end
if MUT == "skipnil" then local r = M.eval; M.eval = function(op, a, n, tv) local b = {} for i = 1, n do local x = a[i]; if not (x.k == "state" and x.cur == nil) then b[#b+1] = x end end return r(op, b, #b, tv) end end
if MUT == "clampswap" then local r = M.eval; M.eval = function(op, a, n, tv) if op == "Clamp" then local lo = if a[1].k=="state" then a[1].cur else a[1].v; local hi = if a[2].k=="state" then a[2].cur else a[2].v; if type(lo)=="number" and type(hi)=="number" and lo > hi then return true, math.clamp(tv, hi, lo) end end return r(op, a, n, tv) end end

local OPS = { "Not", "Sum", "Product", "Min", "Max", "Clamp", "Band", "Bor", "Bxor", "Bnot", "Shl", "Shr", "Alternative", "Indexed" }
local NUMS = { 0, -0, 1, -1, 2, 3, 7, 12, 100, -100, 0.5, 1.5, -1.5, 2.75, -3.25, 31, 32, 33, -31, -32, 64,
	2 ^ 31, 2 ^ 31 - 1, -2 ^ 31, 2 ^ 32 - 1, 2 ^ 32, 2 ^ 32 + 5, 2 ^ 53, 2 ^ 53 + 2, -2 ^ 53, 2 ^ 63, -2 ^ 63, 2 ^ 63 + 2 ^ 11, 1e300, -1e300,
	0 / 0, math.huge, -math.huge, 1e-300, 4294967295.9 }
local KEYS = { "a", "b", "Primary", 1, 2, 0.5, true, "__quadNone", "missing" }
local function tbl(R)
	local t = {}
	if R.chance(0.7) then t.a = R.pick(NUMS) end
	if R.chance(0.5) then t.b = { a = 1, b = "x" } end
	if R.chance(0.4) then t[1] = "one" end
	if R.chance(0.3) then t.Primary = "red" end
	return t
end
local function anyVal(R, numBias)
	local r = R.int(1, 100)
	if r <= numBias then return R.pick(NUMS) end
	if r <= numBias + 6 then return nil end
	if r <= numBias + 11 then return None end
	if r <= numBias + 15 then return R.pick({ "5", "0x10", "abc", "" }) end
	if r <= numBias + 20 then return R.chance(0.5) end
	return tbl(R)
end

local stats = { cases = 0, reads = 0, diffs = 0, und = {}, errs = {}, ops = {}, factoryErr = 0 }
local diffsShown = 0
local function errId(e)
	local s = tostring(e)
	return s:match("Quad%d%d%d%d") or ("RAW:" .. s:gsub("^.-:%d+: ", ""):sub(1, 80))
end
local function report(seed, what, exp, got, ctx)
	stats.diffs += 1
	if diffsShown < 30 then
		diffsShown += 1
		print(`DIFF seed={seed} {what}: expected {exp} got {got} | {ctx}`)
	end
end
local function show(v)
	if v == None then return "None" end
	if type(v) == "table" then return "tbl" end
	if type(v) == "string" then return '"' .. v .. '"' end
	return tostring(v)
end

-- model node graph: node = { kind="src", val } | { kind="op", op, args, n, target, stuck } | { kind="wrap", target, stuck }
local function modelGet(node)
	if node.kind == "src" then return true, node.val end
	if node.stuck then return false, "Quad0184" end
	local ok, tv = modelGet(node.target)
	local rok, r
	if not ok then rok, r = false, tv
	elseif node.kind == "wrap" then rok, r = true, tv
	else
		for i = 1, node.n do local a = node.args[i]; if a and a.k == "state" then a.cur = a.src.val end end
		if node.op == "Alternative" and node.args[1].k == "state" then node.args[1].cur = node.args[1].src.val end
		rok, r = M.eval(node.op, node.args, node.n, tv)
		for tag in M.undecided(node.op, node.args, node.n, tv) do stats.und[tag] = (stats.und[tag] or 0) + 1 end
	end
	-- laziness: Clamp reads bounds BEFORE its target -> a bound error means the target was never read
	if node.kind == "op" and node.op == "Clamp" and ok then
		-- already evaluated target above; the real impl reads bounds first. If bounds fail, the target (a derived
		-- node) was not evaluated -> its stuck state must not change. Re-evaluate order precisely:
	end
	if not rok then node.stuck = true end
	return rok, r
end
-- precise Clamp laziness: evaluate bounds before target
local function modelGetPrecise(node)
	if node.kind == "op" and node.op == "Clamp" and not node.stuck then
		for i = 1, 2 do local a = node.args[i]; if a.k == "state" then a.cur = a.src.val end end
		local ok1 = (node.args[1].k ~= "state") or (type(node.args[1].cur) == "number")
		local ok2 = (node.args[2].k ~= "state") or (type(node.args[2].cur) == "number")
		local lo = if node.args[1].k == "state" then node.args[1].cur else node.args[1].v
		local hi = if node.args[2].k == "state" then node.args[2].cur else node.args[2].v
		if not (ok1 and ok2) or lo ~= lo or hi ~= hi or lo > hi then
			node.stuck = true
			return M.eval("Clamp", node.args, node.n, 0)
		end
	end
	if node.kind ~= "src" and not node.stuck and node.target.kind ~= "src" then
		-- recurse with precise semantics for the target
		local ok, tv = modelGetPrecise(node.target)
		if not ok then node.stuck = true; return false, tv end
		local saved = node.target
		node.target = { kind = "src", val = tv }
		local a, b = modelGet(node)
		node.target = saved
		return a, b
	end
	return modelGet(node)
end
-- stuck clears when any transitive source is Set: we keep per-node source sets
local function deps(node, acc)
	acc = acc or {}
	if node.kind == "src" then acc[node] = true return acc end
	deps(node.target, acc)
	if node.args then for i = 1, #node.args do local a = node.args[i]; if a and a.k == "state" then acc[a.src] = true end end end
	return acc
end

local function runSeed(seed)
	local R = newRng(seed)
	local srcs = {} -- model src nodes paired with real Sources
	local function newSrc(v)
		local m = { kind = "src", val = v }
		m.real = q.Source(v)
		srcs[#srcs + 1] = m
		return m
	end
	local nodes = {}
	local nTargets = R.int(1, 3)
	local op = R.pick(OPS)
	stats.ops[op] = (stats.ops[op] or 0) + 1
	-- args
	local n = if op == "Clamp" then (if R.chance(0.9) then 2 else R.int(0, 3)) elseif (op == "Shl" or op == "Shr") then (if R.chance(0.9) then 1 else R.int(0, 2)) elseif (op == "Indexed" or op == "Alternative") then (if R.chance(0.95) then 1 else 0) else R.int(0, 4)
	local args, realArgs = {}, {}
	local isNum = not (op == "Not" or op == "Indexed" or op == "Alternative")
	for i = 1, n do
		local r = R.int(1, 100)
		if op == "Indexed" then
			if r <= 85 then args[i] = { k = "lit", v = R.pick(KEYS) } elseif r <= 92 then args[i] = { k = "nil" } else args[i] = { k = "state", src = newSrc("a") } end
		elseif r <= 45 then args[i] = { k = "lit", v = if isNum then (if R.chance(0.9) then R.pick(NUMS) else anyVal(R, 0)) else anyVal(R, 50) }
			if args[i].v == nil then args[i] = { k = "nil" } end
		elseif r <= 95 then args[i] = { k = "state", src = newSrc(anyVal(R, if isNum then 80 else 50)) }
		else args[i] = { k = "nil" } end
		realArgs[i] = if args[i].k == "state" then args[i].src.real elseif args[i].k == "lit" then args[i].v else nil
	end
	-- factory
	local factory
	local fexp = M.factory(op, args, n)
	if op == "Not" or op == "Bnot" then factory = Op[op]
	else
		local ok, f = pcall(Op[op], table.unpack(realArgs, 1, n))
		stats.cases += 1
		local got = if ok then nil else errId(f)
		if got ~= fexp then report(seed, "factory " .. op, tostring(fexp), tostring(got), `n={n}`) end
		if not ok then stats.factoryErr += 1 return end
		factory = f
	end
	-- targets (factory reuse across targets; sometimes same target twice)
	for t = 1, nTargets do
		local base
		if t > 1 and R.chance(0.25) then base = nodes[#nodes].target else
			base = newSrc(anyVal(R, if isNum then 75 else 40))
			if op == "Indexed" and R.chance(0.6) then base.val = tbl(R); base.real:Set(base.val) end
			if R.chance(0.3) then -- derived target (Compute / Depend place)
				local w = { kind = "wrap", target = base }
				w.real = if R.chance(0.5) then base.real:Compute(function(h) return h:Get() end) else base.real:Depend()
				base = w
			end
		end
		local node = { kind = "op", op = op, args = args, n = if op == "Indexed" or op == "Alternative" then 1 else n, target = base }
		if op == "Not" or op == "Bnot" then node.n = 0; node.args = {} end
		if op == "Clamp" then node.n = 2; node.args = { args[1], args[2] } elseif op == "Shl" or op == "Shr" then node.n = 1; node.args = { args[1] } end
		local ok, res = pcall(function() return base.real:Apply(factory) end)
		stats.cases += 1
		if not ok then report(seed, "apply " .. op, "ok", errId(res), "") return end
		node.real = res
		if R.chance(0.2) then -- consumer place: user :Compute over the operator result
			local w = { kind = "wrap", target = node }
			w.real = node.real:Compute(function(h) return h:Get() end)
			node = w
		end
		nodes[#nodes + 1] = node
	end
	local function check(step)
		for idx, node in nodes do
			local eok, ev = modelGetPrecise(node)
			local gok, gv = pcall(function() return node.real:Get() end)
			stats.reads += 1
			local ctx = `op={op} step={step} node={idx}`
			if eok ~= gok then report(seed, "okness", if eok then "value " .. show(ev) else ev, if gok then "value " .. show(gv) else errId(gv), ctx)
			elseif not eok then
				local id = errId(gv)
				stats.errs[id] = (stats.errs[id] or 0) + 1
				if id ~= ev then report(seed, "errid", ev, id, ctx) end
			elseif not M.same(ev, gv) then report(seed, "value", show(ev), show(gv), ctx) end
		end
	end
	check(0)
	if R.chance(0.3) then check(0) end -- same-generation re-read (0184 after a throw)
	for step = 1, R.int(1, 6) do
		if #srcs == 0 then break end
		local s = R.pick(srcs)
		local v = anyVal(R, if isNum then 75 else 40)
		if op == "Indexed" and R.chance(0.5) then v = tbl(R) end
		s.val = v
		s.real:Set(v)
		for _, node in nodes do
			local function clear(nd) if nd.kind ~= "src" then if deps(nd)[s] then nd.stuck = false end clear(nd.target) end end
			clear(node)
		end
		check(step)
		if R.chance(0.2) then check(step) end
	end
end

for seed = START, START + SEEDS - 1 do
	local ok, e = pcall(runSeed, seed)
	if not ok then report(seed, "harness", "", tostring(e), "") end
end
local ops = {} for k, v in stats.ops do ops[#ops + 1] = k .. "=" .. v end table.sort(ops)
local und = {} for k, v in stats.und do und[#und + 1] = k .. "=" .. v end table.sort(und)
local errs = {} for k, v in stats.errs do errs[#errs + 1] = k .. "=" .. v end table.sort(errs)
print(`seeds {START}..{START + SEEDS - 1}: cases={stats.cases} reads={stats.reads} factoryErr={stats.factoryErr} DIFFS={stats.diffs}`)
print("ops: " .. table.concat(ops, " "))
print("undecided cells hit: " .. table.concat(und, " "))
print("read errors: " .. table.concat(errs, " "))
