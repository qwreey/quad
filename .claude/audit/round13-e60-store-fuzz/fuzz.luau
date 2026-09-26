--!nocheck
-- E60 differential fuzzer: q.Store bag algebra vs a reference model built from docs/reference/core/04-store.md.
-- usage (repo root): luau .claude/audit/round13-e60-store-fuzz/fuzz.luau -a <seeds> <start> [v] [mutant]
-- One install: quad-base/test/mock.luau -> quad-base/src + quad-base/luau_packages/quad_types (typing-limits 8.34).
local mock = require("../../../quad-base/test/mock")
local RNG = require("./rng")
local args = { ... }
local SEEDS = tonumber(args[1]) or 200
local START = tonumber(args[2]) or 1
local VERBOSE = args[3] == "v"
local MUT = args[4] -- model mutant (detection-power check): "iter", "of", "tostr", "ctor"

local function idOf(err)
	return string.match(tostring(err), "Quad%d%d%d%d") or ("RAW:" .. (tostring(err):gsub("\n.*", "")))
end

-- key pool: { key, expectedErrorOrNil }   (core/04:52-53, 101, 111, 156-160)
local KEYS = {
	{ "hp" }, { "mp" }, { "nm" }, { "Get" }, { "_x" }, { "a b" }, { "é" }, { "Set" },
	{ "", "Quad0193" }, { 1, "Quad0193" }, { true, "Quad0193" }, { 2.5, "Quad0193" },
	{ "Of", "Quad0194" }, { "Names", "Quad0194" }, { "__x", "Quad0194" }, { "__reservedCheck", "Quad0194" },
	{ "__index", "Quad0194" }, { "__tostring", "Quad0194" },
}
local GOODKEYS = { "hp", "mp", "nm", "Get", "_x", "a b", "é", "Set" }
local READKEYS = { "hp", "mp", "nm", "Get", "_x", "a b", "é", "Set", "zz", "Of", "Names", "__index", "__tostring", "__x" }
local IMPL_MEMBERS = { Of = true, Names = true, __index = true, __tostring = true }

local stats = { seeds = 0, ops = 0, diffs = 0, ctorOk = 0, ctorErr = 0, multiBad = 0, ofNew = 0, ofOld = 0, ofRaw = 0,
	attrDrives = 0, attrChecks = 0, internalReads = 0, sets = 0, assigns = 0, iters = 0, tostrs = 0 }
local multiBadDist = {}
local samples = {}
local function diff(seed, step, what)
	stats.diffs += 1
	if #samples < 30 then table.insert(samples, `seed {seed} step {step}: {what}`) end
end

local function runSeed(seed)
	local rng = RNG.new(seed)
	local q = mock.newQuad()
	local Source, Store = q.Source, q.Store
	local srcVal = {} -- model: Source -> value (keys = every Source we created or Of made)
	local pool = {}
	local function newSrc()
		local v = rng:NextInteger(0, 99)
		local s = Source(v)
		srcVal[s] = v
		table.insert(pool, s)
		return s
	end
	for _ = 1, 3 do newSrc() end
	local stores = {} -- { obj, fields = {name -> value}, defaults = tbl? }
	local attrs = {} -- { inst, snap = {name -> value} }

	local function pickValue()
		local r = rng:NextInteger(1, 20)
		if r <= 8 then return pool[rng:NextInteger(1, #pool)], nil
		elseif r <= 11 then return newSrc(), nil
		elseif r == 12 then return 5, "Quad0198"
		elseif r == 13 then return Store(), "Quad0198"
		elseif r == 14 then return pool[1]:Compute(function(h) return h:Get() end), "Quad0198"
		elseif r == 15 then return q.Tag("t"), "Quad0198"
		elseif r == 16 then return q.AttrKey("k"), "Quad0198"
		elseif r == 17 then return {}, "Quad0198"
		elseif r == 18 then return q.Ref(), "Quad0198"
		elseif r == 19 then local s = Source(Store()); srcVal[s] = s:Get(); table.insert(pool, s); return s, nil -- Source holding a Store
		else return "str", "Quad0198" end
	end

	local function ctor(step)
		local r = rng:NextInteger(1, 30)
		local defaults, expect -- expect: nil = ok, table = set of ids
		if r == 1 then defaults, expect = 7, { Quad0195 = true }
		elseif r == 2 then defaults, expect = "x", { Quad0195 = true }
		elseif r == 3 then defaults, expect = pool[1], { Quad0196 = true }
		elseif r == 4 then defaults, expect = Store(), { Quad0196 = true }
		elseif r == 5 then defaults, expect = q.AttrKey("z"), { Quad0197 = true }
		elseif r == 6 then defaults, expect = q.Tag("a"), { Quad0196 = true }
		elseif r == 7 then defaults = nil
		else
			defaults = {}
			local n = rng:NextInteger(0, 5)
			local bad = {}
			local nbad = 0
			for _ = 1, n do
				local k
				if rng:NextInteger(1, 4) == 1 then k = KEYS[rng:NextInteger(1, #KEYS)] else k = { GOODKEYS[rng:NextInteger(1, #GOODKEYS)] } end
				local v, vErr = pickValue()
				if rng:NextInteger(1, 3) ~= 1 then v, vErr = pool[rng:NextInteger(1, #pool)], nil end
				if defaults[k[1]] == nil then
					defaults[k[1]] = v
					local e = k[2] or vErr
					if e then bad[e] = true; nbad += 1 end
				end
			end
			if rng:NextInteger(1, 10) == 1 then table.freeze(defaults) end
			if nbad > 0 then expect = bad end
			if nbad > 1 then stats.multiBad += 1 end
		end
		if MUT == "ctor" and expect == nil and type(defaults) == "table" and next(defaults) ~= nil then expect = { Quad0198 = true } end
		local ok, res = pcall(Store, defaults)
		if expect then
			stats.ctorErr += 1
			if ok then diff(seed, step, "ctor expected error, got ok")
			elseif not expect[idOf(res)] then diff(seed, step, `ctor got {idOf(res)}`)
			else
				local k = 0
				for _ in expect do k += 1 end
				if k > 1 then multiBadDist[idOf(res)] = (multiBadDist[idOf(res)] or 0) + 1 end
			end
			return
		end
		stats.ctorOk += 1
		if not ok then diff(seed, step, `ctor expected ok, got {idOf(res)}`) return end
		if res == defaults then diff(seed, step, "store == defaults (doc 42 says the passed table becomes the store)") end
		local fields = {}
		if defaults then for k, v in defaults do fields[k] = v end end
		table.insert(stores, { obj = res, fields = fields, defaults = if type(defaults) == "table" and not table.isfrozen(defaults) then defaults else nil })
	end

	local function checkAll(step)
		for _, s in pool do
			if s:Get() ~= srcVal[s] then diff(seed, step, `Source value {tostring(s:Get())} vs model {tostring(srcVal[s])}`) end
		end
		for _, a in attrs do
			local got = mock.getAttributes(a.inst)
			local want = {}
			for name, v in a.snap do
				local w = if q.isSource(v) then srcVal[v] else v
				want[name] = w
			end
			stats.attrChecks += 1
			for k, v in want do if got[k] ~= v then diff(seed, step, `attr {k}={tostring(got[k])} want {tostring(v)}`) end end
			for k, v in got do if want[k] == nil then diff(seed, step, `attr extra {k}={tostring(v)}`) end end
		end
	end

	local nops = rng:NextInteger(20, 60)
	ctor(0)
	for step = 1, nops do
		stats.ops += 1
		if #stores == 0 then ctor(step) continue end
		local st = stores[rng:NextInteger(1, #stores)]
		local store, fields = st.obj, st.fields
		local op = rng:NextInteger(1, 13)
		if op == 1 then
			ctor(step)
		elseif op == 2 or op == 3 then -- :Of
			local k = if rng:NextInteger(1, 4) == 1 then KEYS[rng:NextInteger(1, #KEYS)] else { GOODKEYS[rng:NextInteger(1, #GOODKEYS)] }
			local ok, res = pcall(store.Of, store, k[1])
			if k[2] then
				if ok then diff(seed, step, `Of({tostring(k[1])}) expected {k[2]}, ok`)
				elseif idOf(res) ~= k[2] then diff(seed, step, `Of({tostring(k[1])}) got {idOf(res)} want {k[2]}`) end
			elseif not ok then diff(seed, step, `Of({k[1]}) threw {idOf(res)}`)
			else
				local old = fields[k[1]]
				if old ~= nil then
					if q.isSource(old) then stats.ofOld += 1 else stats.ofRaw += 1 end
					local want = old
					if MUT == "of" then want = nil end
					if res ~= want then diff(seed, step, `Of({k[1]}) returned a different object than the field`) end
				else
					stats.ofNew += 1
					if not q.isSource(res) or res:Get() ~= nil then diff(seed, step, `Of({k[1]}) new is not an empty Source`) end
					if rawget(store, k[1]) ~= res then diff(seed, step, `Of({k[1]}) new not stored`) end
					fields[k[1]] = res
					srcVal[res] = nil
					table.insert(pool, res)
				end
			end
		elseif op == 4 then -- dot read
			local k = READKEYS[rng:NextInteger(1, #READKEYS)]
			local got = store[k]
			if fields[k] ~= nil then
				if got ~= fields[k] then diff(seed, step, `read {k}: not the field object`) end
			elseif IMPL_MEMBERS[k] then
				stats.internalReads += 1
				if got == nil then diff(seed, step, `read {k}: expected internal member`) end
			elseif got ~= nil then diff(seed, step, `read {k}: expected nil, got {typeof(got)}`) end
		elseif op == 5 then -- direct assignment (not blocked, results not guaranteed — core/04:156)
			stats.assigns += 1
			local k = GOODKEYS[rng:NextInteger(1, #GOODKEYS)]
			local r = rng:NextInteger(1, 4)
			local v = if r == 1 then nil elseif r == 2 then rng:NextInteger(0, 9) else pool[rng:NextInteger(1, #pool)]
			store[k] = v
			fields[k] = v
		elseif op == 6 then -- Names
			local names = store:Names()
			local seen = {}
			for _, n in names do
				if seen[n] then diff(seed, step, `Names dup {n}`) end
				seen[n] = true
				if fields[n] == nil then diff(seed, step, `Names extra {tostring(n)}`) end
			end
			for n in fields do if not seen[n] then diff(seed, step, `Names missing {tostring(n)}`) end end
		elseif op == 7 then -- generalized iteration / pairs
			stats.iters += 1
			local got = {}
			local useP = rng:NextInteger(1, 2) == 1
			if useP then for k, v in pairs(store) do got[k] = v end else for k, v in store do got[k] = v end end
			if MUT == "iter" then got.__phantom = true end
			for k, v in fields do if got[k] ~= v then diff(seed, step, `iter missing/other {tostring(k)}`) end end
			for k in got do if fields[k] == nil then diff(seed, step, `iter extra {tostring(k)}`) end end
		elseif op == 8 then -- tostring
			stats.tostrs += 1
			local names = {}
			for n in fields do table.insert(names, tostring(n)) end
			table.sort(names)
			local want = `Store\{{table.concat(names, ", ")}}`
			if MUT == "tostr" then want = `Store\{{table.concat(names, ",")}}` end
			local ok, got = pcall(tostring, store)
			if not ok then diff(seed, step, `tostring threw {idOf(got)}`)
			elseif got ~= want then diff(seed, step, `tostring {got} vs {want}`) end
		elseif op == 9 or op == 10 then -- Source:Set
			stats.sets += 1
			local s = pool[rng:NextInteger(1, #pool)]
			local v = rng:NextInteger(0, 99)
			s:Set(v)
			srcVal[s] = v
		elseif op == 11 then -- q.Attr(store) + drive (snapshot of Names at construction)
			local okv = true
			for n, v in fields do
				if type(n) ~= "string" or n == "" then okv = false end
				if not q.isSource(v) and type(v) ~= "number" then okv = false end
				if q.isSource(v) and type(srcVal[v]) == "table" then okv = false end -- Source<Store> -> table attr: engine rejects
			end
			if okv then
				local snap = {}
				for n, v in fields do snap[n] = v end
				local inst = mock.Instance.new("Frame")
				local ok, e = pcall(function() q.Dispatch.drive(inst, { q.Attr(store) }) end)
				if not ok then diff(seed, step, `Attr(store) drive threw {idOf(e)}`)
				else stats.attrDrives += 1; table.insert(attrs, { inst = inst, snap = snap }) end
			end
		elseif op == 12 then -- mutate the defaults table after construction: store must not follow
			if st.defaults then st.defaults.late = pool[1]; st.defaults = nil end
		elseif op == 13 then -- same Source under a second name / second store via :Of-free path is direct assign; share via new ctor
			local s = pool[rng:NextInteger(1, #pool)]
			local ok, res = pcall(Store, { hp = s, mp = s })
			if not ok then diff(seed, step, `shared ctor threw {idOf(res)}`)
			else
				if res.hp ~= res.mp or res.hp ~= s then diff(seed, step, "shared Source identity") end
				table.insert(stores, { obj = res, fields = { hp = s, mp = s } })
			end
		end
		checkAll(step)
	end
	stats.seeds += 1
end

for seed = START, START + SEEDS - 1 do
	local ok, e = pcall(runSeed, seed)
	if not ok then diff(seed, -1, "harness crash " .. tostring(e)) end
end
local t = {}
for k, v in stats do table.insert(t, k .. "=" .. v) end
table.sort(t)
print(table.concat(t, " "))
local d = {}
for k, v in multiBadDist do table.insert(d, k .. ":" .. v) end
table.sort(d)
print("multi-bad ctor first-error distribution: " .. table.concat(d, " "))
for _, s in samples do print("  " .. s) end
