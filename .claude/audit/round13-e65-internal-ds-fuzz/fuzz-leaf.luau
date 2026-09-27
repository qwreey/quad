--!nocheck
-- E65 leaf differential fuzzer: EpochMap / Relate / ImplRegistry vs naive models.
-- usage (repo root): luau .claude/audit/round13-e65-internal-ds-fuzz/fuzz-leaf.luau -a <epoch|relate|impl> <seeds> <start> [mutant]
-- EpochMap model (state-epoch-plan §3 L158-253 / EpochMap.luau L1-24):
--   EM1 Update(e|set): for each e: changed |= (m[e] ~= e.Revision); m[e] = e.Revision (ALL written, "내부 최적화" writes w/o read)
--   EM2 Peek: same comparison, no write (H-72)       EM3 Refresh: Update over own keys
--   EM4 Sync: write only, no return                   EM5 TrackFrom(o): o's keys, LIVE revision, o untouched
--   EM6 keys weak: an epoch reachable only from maps disappears after collect
-- Relate model (relate-plan "API"/"실제 구조"): R1 Strong/Weak are independent per (inst,key); R2 Get never creates;
--   R3 nil inst -> Quad0138, nil key -> Quad0139 (inst checked first); R4 weak value dropped after collect; R5 inst weak
-- ImplRegistry model: I1 implsOf(m) returns one table per module forever; I2 stored raw (bypasses __index/__newindex)
local E = require("./env")
local RNG = require("./rng")
local SRC = "../../../quad-roblox/luau_packages/.pesde/qwreey+quad_base/3.2.0/quad_base/src/"
local EpochMap = require(SRC .. "EpochMap")
local Relate = require(SRC .. "Relate")
local ImplRegistry = require(SRC .. "ImplRegistry")
local args = { ... }
local MODE, SEEDS, START, MUT = args[1] or "epoch", tonumber(args[2]) or 100, tonumber(args[3]) or 1, args[4]
local stats = { seeds = 0, ops = 0, diffs = 0, errs = {}, gcDrops = 0 }
local samples = {}
local function bump(k) stats.errs[k] = (stats.errs[k] or 0) + 1 end
local function diff(seed, msg)
	stats.diffs += 1
	if #samples < 8 then table.insert(samples, `seed {seed}: {msg}`) end
end
local q = E.newBase()

-- ── EpochMap ───────────────────────────────────────────────
local function epochSeed(seed)
	local rng = RNG.new(seed)
	local pool = {}
	local NE = rng:NextInteger(2, 7)
	for i = 1, NE do pool[i] = q.Source(0) end
	local NM = rng:NextInteger(1, 3)
	local maps, models = {}, {}
	for i = 1, NM do maps[i] = EpochMap(); models[i] = setmetatable({}, { __mode = "k" }) end
	local function pickSet()
		local s = {}
		for _ = 1, rng:NextInteger(0, 4) do s[pool[rng:NextInteger(1, #pool)]] = true end
		return s
	end
	local function pickFrom()
		if rng:NextNumber() < 0.5 then return pool[rng:NextInteger(1, #pool)] end
		return pickSet()
	end
	local function mUpdate(m, from, write)
		local list = if E.Quad and from.Revision ~= nil then { from } else (function() local t = {} for e in from do table.insert(t, e) end return t end)()
		local changed = false
		for _, e in list do
			if m[e] ~= e.Revision then
				changed = true
				if MUT == "updEarly" and write then return true end
			end
			if write and not (MUT == "peekWrites" and false) then m[e] = e.Revision end
		end
		return changed
	end
	for _ = 1, rng:NextInteger(20, 60) do
		stats.ops += 1
		local r = rng:NextNumber()
		local mi = rng:NextInteger(1, NM)
		local map, model = maps[mi], models[mi]
		local got, exp, what
		if r < 0.25 then
			local from = pickFrom()
			got = map:Update(from); exp = mUpdate(model, from, true); what = "Update"
		elseif r < 0.4 then
			local from = pickFrom()
			got = map:Peek(from); exp = mUpdate(model, from, MUT == "peekWrites"); what = "Peek"
		elseif r < 0.5 then
			got = map:Refresh()
			local keys = {}
			for e in model do keys[e] = true end
			exp = mUpdate(model, keys, true); what = "Refresh"
		elseif r < 0.6 then
			local from = pickFrom()
			map:Sync(from); mUpdate(model, from, true); what = "Sync"
		elseif r < 0.7 then
			local oi = rng:NextInteger(1, NM)
			map:TrackFrom(maps[oi])
			local src = models[oi]
			local tmp = {}
			for e, rev in src do tmp[e] = if MUT == "trackCopies" then rev else e.Revision end
			for e, v in tmp do model[e] = v end
			what = "TrackFrom"
		elseif r < 0.95 then
			local e = pool[rng:NextInteger(1, #pool)]
			local c = rng:NextInteger(0, 3)
			for _ = 1, c do e:Set(rng:NextInteger(0, 1e6)) end
			what = "Set"
		else
			-- GC axis: drop one epoch from the pool; it must vanish from real maps
			local i = rng:NextInteger(1, #pool)
			if #pool > 1 then
				table.remove(pool, i)
				collectgarbage("collect")
				stats.gcDrops += 1
			end
			what = "gc"
		end
		if got ~= exp then diff(seed, `{what} returned {tostring(got)} expected {tostring(exp)}`) end
		-- full content comparison after every op
		for k = 1, NM do
			local real, mod = maps[k]._map, models[k]
			local n1, n2 = 0, 0
			for e, v in real do n1 += 1; if mod[e] ~= v then diff(seed, `map{k} content {what}: real {v} model {tostring(mod[e])}`) break end end
			for _ in mod do n2 += 1 end
			if n1 ~= n2 then diff(seed, `map{k} size {what}: real {n1} model {n2}`) end
		end
	end
end

-- ── Relate ─────────────────────────────────────────────────
local function relateSeed(seed)
	local rng = RNG.new(seed)
	local rel = Relate()
	local insts = {}
	for i = 1, rng:NextInteger(1, 4) do insts[i] = { name = "i" .. i } end
	insts[#insts + 1] = "strInst"; insts[#insts + 1] = 7; insts[#insts + 1] = print -- non-table outer keys
	local keys = { "a", "b", 1, 2, true, { tag = "k1" }, { tag = "k2" } }
	local vals = { 1, "x", false }
	local liveVals = {}
	for i = 1, 3 do liveVals[i] = { v = i } end
	local model = {} -- inst -> { S = {}, W = {} }
	local function mb(inst, create)
		local b = model[inst]
		if b == nil and create then b = { S = {}, W = {} }; model[inst] = b end
		return b
	end
	local function pick(t) return t[rng:NextInteger(1, #t)] end
	for _ = 1, rng:NextInteger(20, 60) do
		stats.ops += 1
		local r = rng:NextNumber()
		local inst = if rng:NextNumber() < 0.03 then nil else pick(insts)
		local key = if rng:NextNumber() < 0.03 then nil else pick(keys)
		local expErr = if inst == nil then "Quad0138" elseif key == nil then "Quad0139" else nil
		local value
		local vr = rng:NextNumber()
		if vr < 0.15 then value = nil elseif vr < 0.55 then value = pick(vals) else value = liveVals[rng:NextInteger(1, #liveVals)] end
		local kind = if r < 0.3 then "SetStrong" elseif r < 0.6 then "SetWeak" elseif r < 0.78 then "GetStrong" elseif r < 0.95 then "GetWeak" else "gc"
		if kind == "gc" then
			inst, key, value = nil, nil, nil -- the loop locals must not pin the dropped objects
			-- drop one live value table and one table inst; collect; model forgets weak refs to the dropped value
			local i = rng:NextInteger(1, #liveVals)
			local dead = liveVals[i]
			liveVals[i] = { v = rng:NextInteger(10, 99) }
			-- a value still held by any StrongMap (real and model alike) survives; only otherwise do weak refs clear
			local strongHeld = false
			for _, b in model do for _, v in b.S do if v == dead then strongHeld = true end end end
			if not strongHeld then
				for _, b in model do
					for k, v in b.W do if v == dead then b.W[k] = nil end end
				end
			end
			dead = nil
			if rng:NextNumber() < 0.5 and type(insts[1]) == "table" then
				local di = insts[1]
				insts[1] = { name = "fresh" }
				-- outer key weak: bucket must vanish unless its bucket content references it (it never does here)
				model[di] = nil
				di = nil
			end
			collectgarbage("collect")
			stats.gcDrops += 1
			-- compare bucket population on table insts
			local realN, modelN = 0, 0
			for k in rel.buckets do if type(k) == "table" then realN += 1 end end
			for k in model do if type(k) == "table" then modelN += 1 end end
			-- model may hold empty buckets for table insts that got only Gets? (Gets never create) -> equal expected
			if realN ~= modelN then diff(seed, `gc bucket count real {realN} model {modelN}`) end
		else
			local ok, res = pcall(rel[kind], rel, inst, key, value)
			local gotErr = if ok then nil else E.id(res)
			if gotErr then bump(gotErr) end
			if gotErr ~= expErr then diff(seed, `{kind} err {tostring(gotErr)} expected {tostring(expErr)}`)
			elseif ok then
				if kind == "SetStrong" or kind == "SetWeak" then
					local b = mb(inst, true)
					local tgt = if MUT == "sharedMap" then b.S else (if kind == "SetStrong" then b.S else b.W)
					if MUT == "setNilNoop" and value == nil then else tgt[key] = value end
				else
					local b = mb(inst, false)
					local exp
					if b then
						if kind == "GetStrong" then exp = b.S[key]
						else
							exp = if MUT == "sharedMap" then b.S[key] else b.W[key]
							if MUT == "weakFallback" and exp == nil then exp = b.S[key] end
						end
					end
					if res ~= exp then diff(seed, `{kind} got {tostring(res)} expected {tostring(exp)}`) end
				end
			end
			-- R2: reads never create a bucket
			if (kind == "GetStrong" or kind == "GetWeak") and inst ~= nil and model[inst] == nil and rel.buckets[inst] ~= nil then
				diff(seed, "Get created a bucket")
			end
		end
	end
end

-- ── ImplRegistry ───────────────────────────────────────────
local function implSeed(seed)
	local rng = RNG.new(seed)
	local mods, model = {}, {}
	for i = 1, rng:NextInteger(1, 5) do
		local m = {}
		local kind = rng:NextInteger(1, 3)
		if kind == 2 then setmetatable(m, { __index = function(_, k) if k == "_impl" then return { fake = true } end end }) end
		if kind == 3 then setmetatable(m, { __newindex = function() error("frozen-ish") end, __index = function() return nil end }) end
		mods[i] = m
	end
	for _ = 1, rng:NextInteger(10, 30) do
		stats.ops += 1
		local m = mods[rng:NextInteger(1, #mods)]
		local t = ImplRegistry.implsOf(m)
		if MUT == "freshEach" then model[m] = {} end
		if model[m] == nil then model[m] = t end
		if model[m] ~= t then diff(seed, "implsOf identity changed") end
		if t.fake then diff(seed, "implsOf returned __index result") end
		local k = "k" .. rng:NextInteger(1, 3)
		t[k] = (t[k] or 0) + 1
	end
	local seen = {}
	for _, t in model do
		if seen[t] then diff(seed, "two modules share one impl table") end
		seen[t] = true
	end
end

local run = if MODE == "epoch" then epochSeed elseif MODE == "relate" then relateSeed else implSeed
local t0 = os.clock()
for s = START, START + SEEDS - 1 do
	run(s)
	stats.seeds += 1
end
print(`mode={MODE} mutant={MUT or "-"} seeds={stats.seeds} ops={stats.ops} gcDrops={stats.gcDrops} diffs={stats.diffs} time={string.format("%.2f", os.clock() - t0)}s`)
local es = {}
for k, v in stats.errs do table.insert(es, `{k}={v}`) end
table.sort(es)
if #es > 0 then print("errors: " .. table.concat(es, " ")) end
for _, s in samples do print("  " .. s) end
