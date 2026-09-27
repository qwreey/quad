--!nocheck
-- E65 Bookkeeping differential fuzzer: q.Bookkeeping (setLength/setOffsetSource/setEmpty/getOffsetAt/getBlocker/_recompute)
-- vs a naive prefix-sum model. usage (repo root):
--   luau .claude/audit/round13-e65-internal-ds-fuzz/fuzz-bk.luau -a <seeds> <start> [mutant]
-- Model rules (dispatch-core-plan "Length/Offset" L1547~, "저장 위치" L1774~, "배치 등록" L2599~; Bookkeeping.luau):
--  B1 offset(i) = sum_{j<i} len(j) (physical owner: base 0, Bookkeeping.luau:170)
--  B2 getOffsetAt(i): positions 1..i-1 must have a length; else Quad0022 if i > N+1, Quad0229 otherwise (L196-203)
--  B3 setOffsetSource(i, None) stores only; (i, Source) = getOffsetAt(i) THEN store THEN Set (H-392, L383-398); other -> Quad0025
--  B4 setLength writes lengthList[i], N = max(N, i), then recompute unless batch blocker on or owner frozen (L348-366, L319-330)
--  B5 recompute j=1..N: source nil -> Quad0023; non-None source := offset(j); length nil -> Quad0024 (L238-299)
--  B6 a raise inside recompute leaves recomputeBlocker on = owner frozen for good (documented UB family, L157-161, L271-273)
--  B7 batch: getBlocker(o):On() defers; close = OffWithoutEmit + _recompute unless frozen (Dispatch/init.luau:535-541)
--  B8 validation: nil owner Quad0020, bad position Quad0019, bad constant length Quad0021 (checked before any write)
--  B9 a State length re-runs recompute on :Set (observer), replaced registration stops (unbindLifetime)
--  B10 offsetCache[1..offsetCacheValidUpTo] always equals the true prefix sums ("두 필드" 절)
local E = require("./env")
local RNG = require("./rng")
local args = { ... }
local SEEDS, START, MUT = tonumber(args[1]) or 100, tonumber(args[2]) or 1, args[3]
-- mutants: offBy1 (offset includes own length), noFreeze (raise does not freeze), nilSkip (nil source skipped silently),
--          rangeMsg (always Quad0022), batchEager (batch does not defer)
local stats = { seeds = 0, ops = 0, diffs = 0, errs = {}, frozen = 0, batches = 0, stateSets = 0, skipped = 0, cacheChecks = 0 }
local samples = {}
local function bump(k) stats.errs[k] = (stats.errs[k] or 0) + 1 end

local function runSeed(seed)
	local rng = RNG.new(seed)
	local q = E.newBase()
	local BK = q.Bookkeeping
	local None = q.None
	local diffsBefore = stats.diffs
	local function diff(msg)
		stats.diffs += 1
		if #samples < 10 then table.insert(samples, `seed {seed}: {msg}`) end
	end
	local NO = rng:NextInteger(1, 2)
	local owners = {}
	for o = 1, NO do
		owners[o] = {
			inst = E.mock.Instance.new("Frame"),
			lens = {}, srcs = {}, N = 0, frozen = false, batch = false,
			pool = {}, val = {}, elems = {},
		}
		for k = 1, rng:NextInteger(2, 5) do
			owners[o].pool[k] = q.Source(-1); owners[o].val[k] = -1
		end
	end
	local lstates, lv = {}, {}
	for k = 1, rng:NextInteger(1, 3) do
		lv[k] = rng:NextInteger(0, 4); lstates[k] = q.Source(lv[k])
	end
	local function lenval(L) return if L.c ~= nil then L.c else lv[L.s] end
	-- model offset; returns (value) or (nil, errId)
	local function mOffset(O, at)
		local sum = 0
		for j = 1, at - 1 do
			local L = O.lens[j]
			if L == nil then
				if MUT == "rangeMsg" then return nil, "Quad0022" end
				return nil, if at > O.N + 1 then "Quad0022" else "Quad0229"
			end
			sum += lenval(L)
		end
		if MUT == "offBy1" and O.lens[at] then sum += lenval(O.lens[at]) end
		return sum
	end
	local function mRecompute(O)
		if O.frozen or (O.batch and MUT ~= "batchEager") then return nil end
		for j = 1, O.N do
			local s = O.srcs[j]
			if s == nil then
				if MUT ~= "nilSkip" then
					if MUT ~= "noFreeze" then O.frozen = true end
					return "Quad0023"
				end
			elseif s ~= "None" then
				O.val[s] = (mOffset(O, j))
			end
			if O.lens[j] == nil then
				if MUT ~= "noFreeze" then O.frozen = true end
				return "Quad0024"
			end
		end
		return nil
	end
	local function badPos()
		local r = rng:NextInteger(1, 5)
		return ({ 0, -1, 1.5, "x", nil })[r]
	end
	local clean = seed % 2 == 0 -- half the seeds never create holes, so owners stay unfrozen and every offset is compared
	local function pickPos(O)
		if clean or rng:NextNumber() < 0.85 then return rng:NextInteger(1, O.N + 1) end
		return rng:NextInteger(1, O.N + 3)
	end
	local function call(fn, ...)
		local ok, err = pcall(fn, ...)
		if ok then return nil end
		local id = E.id(err)
		bump(id)
		return id
	end
	local function checkErr(what, got, exp)
		if MUT == "v" then print(`  op {what} got={tostring(got)} exp={tostring(exp)}`) end
		if got ~= exp then diff(`{what}: err {tostring(got)} expected {tostring(exp)}`) end
	end

	local function opSetOffsetSource(O, i, sKind)
		-- sKind: "None" | k (pool idx) | "bad"
		local src = if sKind == "None" then None elseif sKind == "bad" then { 1 } else O.pool[sKind]
		local got = call(BK.setOffsetSource, O.inst, i, src)
		local exp
		if type(i) ~= "number" or i % 1 ~= 0 or i <= 0 then exp = "Quad0019"
		elseif sKind == "bad" then exp = "Quad0025"
		elseif sKind == "None" then O.srcs[i] = "None"
		else
			local off, e = mOffset(O, i)
			if e then exp = e else O.srcs[i] = sKind; O.val[sKind] = off end
		end
		checkErr(`setOffsetSource({tostring(i)},{tostring(sKind)})`, got, exp)
		return got == nil
	end
	local function opSetLength(O, i, lKind, lval)
		-- lKind: "c" constant lval | "s" state index lval | "bad" lval raw
		local len = if lKind == "s" then lstates[lval] else lval
		local elem = nil
		if type(i) == "number" and i >= 1 and i % 1 == 0 and rng:NextNumber() < 0.5 then
			O.elems[i] = O.elems[i] or { pos = i }
			elem = O.elems[i]
		end
		local got = call(BK.setLength, O.inst, i, len, nil, elem)
		local exp
		if type(i) ~= "number" or i % 1 ~= 0 or i <= 0 then exp = "Quad0019"
		elseif lKind == "bad" then exp = "Quad0021"
		else
			O.lens[i] = if lKind == "s" then { s = lval } else { c = lval }
			O.N = math.max(O.N, i)
			exp = mRecompute(O)
		end
		checkErr(`setLength({tostring(i)},{lKind}{tostring(lval)})`, got, exp)
	end

	local nops = rng:NextInteger(15, 50)
	for _ = 1, nops do
		stats.ops += 1
		local o = rng:NextInteger(1, NO)
		local O = owners[o]
		local r = rng:NextNumber()
		if r < 0.40 then
			-- the handler contract pair: offset source first, then length (H-39)
			local i = pickPos(O)
			local sKind = if rng:NextNumber() < 0.35 then "None" else rng:NextInteger(1, #O.pool)
			if not opSetOffsetSource(O, i, sKind) then
				-- a handler whose offset registration raised stops there
			elseif rng:NextNumber() < 0.7 then
				opSetLength(O, i, "c", rng:NextInteger(0, 5))
			else
				opSetLength(O, i, "s", rng:NextInteger(1, #lstates))
			end
		elseif r < 0.47 then
			local i = if rng:NextNumber() < 0.1 then badPos() else pickPos(O)
			local r2 = rng:NextNumber()
			opSetOffsetSource(O, i, if r2 < 0.1 then "bad" elseif r2 < 0.4 then "None" else rng:NextInteger(1, #O.pool))
		elseif r < 0.53 then
			local i = if rng:NextNumber() < 0.1 then badPos() else pickPos(O)
			if type(i) == "number" and O.srcs[i] == nil and (clean or rng:NextNumber() < 0.8) then i = if O.N > 0 then rng:NextInteger(1, O.N) else 1 end
			local r2 = rng:NextNumber()
			if r2 < 0.1 then opSetLength(O, i, "bad", ({ -1, 1.5, "3", 0 / 0 })[rng:NextInteger(1, 4)])
			elseif r2 < 0.6 then opSetLength(O, i, "c", rng:NextInteger(0, 5))
			else opSetLength(O, i, "s", rng:NextInteger(1, #lstates)) end
		elseif r < 0.58 then
			local i = if rng:NextNumber() < 0.1 then badPos() else pickPos(O)
			local got = call(BK.setEmpty, O.inst, i)
			local exp
			if type(i) ~= "number" or i % 1 ~= 0 or i <= 0 then exp = "Quad0019"
			else
				O.srcs[i] = "None"; O.lens[i] = { c = 0 }; O.N = math.max(O.N, i)
				exp = mRecompute(O)
			end
			checkErr(`setEmpty({tostring(i)})`, got, exp)
		elseif r < 0.75 then
			local i = if rng:NextNumber() < 0.05 then badPos() else pickPos(O)
			local ok, res = pcall(BK.getOffsetAt, O.inst, i)
			local got = if ok then nil else E.id(res)
			if got then bump(got) end
			local exp, expV
			if type(i) ~= "number" or i % 1 ~= 0 or i <= 0 then exp = "Quad0019" else
				expV, exp = mOffset(O, i)
			end
			checkErr(`getOffsetAt({tostring(i)})`, got, exp)
			if ok and exp == nil and res ~= expV and O.frozen then stats.frozenStale = (stats.frozenStale or 0) + 1
			elseif ok and exp == nil and res ~= expV then diff(`getOffsetAt({i}) = {res} expected {expV}`) end
		elseif r < 0.88 then
			-- a length State changes: every live registration's observer re-runs recompute (B9)
			local k = rng:NextInteger(1, #lstates)
			local nv = rng:NextInteger(0, 6)
			local affected, predicted = {}, false
			for _, OO in owners do
				for _, L in OO.lens do if L.s == k then affected[OO] = true end end
			end
			-- predict: skip if any affected owner would raise (observer order across owners is unspecified)
			local oldv = lv[k]
			lv[k] = nv
			for OO in affected do
				if not OO.frozen and not OO.batch then
					for j = 1, OO.N do if OO.srcs[j] == nil or OO.lens[j] == nil then predicted = true end end
				end
			end
			if predicted then
				lv[k] = oldv; stats.skipped += 1
			else
				stats.stateSets += 1
				if MUT == "v" then print(`  [state{k} {oldv}->{nv}]`) end
				local got = call(function() lstates[k]:Set(nv) end)
				checkErr(`lengthState{k}:Set({nv})`, got, nil)
				for OO in affected do mRecompute(OO) end -- Source:Set re-emits even on an equal value (H-68)
			end
		elseif r < 0.95 then
			-- batch toggle (B7)
			if not O.batch then
				BK.getBlocker(O.inst):On(); O.batch = true; stats.batches += 1
			else
				BK.getBlocker(O.inst):OffWithoutEmit(); O.batch = false
				local bk = BK.getBookkeeping(O.inst)
				local got = nil
				if not bk.recomputeBlocker.Blocking then got = call(BK._recompute, O.inst, bk) end
				checkErr("batch close", got, mRecompute(O))
			end
		else
			-- nil owner gate (B8)
			local fns = { "setLength", "setOffsetSource", "setEmpty", "getOffsetAt", "getBlocker", "getBookkeeping" }
			local fn = fns[rng:NextInteger(1, #fns)]
			checkErr(`{fn}(nil)`, call(BK[fn], nil, 1, 0), "Quad0020")
		end
		-- invariants after every op
		for oo, OO in owners do
			local bk = BK.getBookkeeping(OO.inst)
			if OO.frozen then
				-- frozen owner (B6, UB family): only N/frozen are compared; offsets/cache staleness is counted, not diffed
				for j = 1, bk.offsetCacheValidUpTo do
					if bk.offsetCache[j] ~= mOffset(OO, j) then stats.frozenStale = (stats.frozenStale or 0) + 1 break end
				end
			end
			if (bk.N or 0) ~= OO.N then diff(`owner{oo} N real {tostring(bk.N)} model {OO.N}`) end
			if bk.recomputeBlocker.Blocking ~= OO.frozen then diff(`owner{oo} frozen real {tostring(bk.recomputeBlocker.Blocking)} model {tostring(OO.frozen)}`) end
			if OO.frozen then continue end
			for k, s in OO.pool do
				if s:Get() ~= OO.val[k] then diff(`owner{oo} src{k} real {s:Get()} model {OO.val[k]}`) end
			end
			for j = 1, bk.offsetCacheValidUpTo do
				stats.cacheChecks += 1
				local v = mOffset(OO, j)
				if MUT == "offBy1" then v = nil end
				if MUT ~= "offBy1" and bk.offsetCache[j] ~= v then diff(`owner{oo} offsetCache[{j}] real {tostring(bk.offsetCache[j])} true {tostring(v)} (validUpTo {bk.offsetCacheValidUpTo})`) end
			end
		end
	end
	for _, OO in owners do if OO.frozen then stats.frozen += 1 end end
	return stats.diffs > diffsBefore
end

local t0 = os.clock()
local badSeeds = 0
for s = START, START + SEEDS - 1 do
	if runSeed(s) then badSeeds += 1 end
	stats.seeds += 1
end
print(`bookkeeping mutant={MUT or "-"} seeds={stats.seeds} diffSeeds={badSeeds} ops={stats.ops} diffs={stats.diffs} stateSets={stats.stateSets} skipped={stats.skipped} batches={stats.batches} frozenOwnersAtEnd={stats.frozen} cacheChecks={stats.cacheChecks} frozenStaleObs={stats.frozenStale or 0} time={string.format("%.2f", os.clock() - t0)}s`)
local es = {}
for k, v in stats.errs do table.insert(es, `{k}={v}`) end
table.sort(es)
print("errors: " .. table.concat(es, " "))
for _, s in samples do print("  " .. s) end
