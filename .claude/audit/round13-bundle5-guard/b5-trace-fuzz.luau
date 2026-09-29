-- bundle5 guard — DEFINED-PATH trace fuzzer (differential: run in before/after trees, diff output).
-- Random Compute DAG over Sources, Blocker/Debounce gate nodes, Observers/Effects that read
-- nodes, fns that sometimes THROW, sometimes return a Modifier, sometimes pcall-read THEMSELVES
-- (a real cycle → Quad0184, swallowed) — all on the main thread, NO yield.
--
-- Determinism: object-keyed tables (`_subs`, EpochMap, withheld sets) iterate in address order and
-- ASLR is on (setarch -R is not permitted here), so subscriber order varies run to run. The trace is
-- therefore canonicalised per op step: the lines of one step are SORTED, and the read-error codes
-- (`boomN` = the fn's own raise to the first reader, Quad0184 = the stamp to later readers, a
-- Quad0185 that reached a reader through a downstream fn) fold into ERR — which reader gets which
-- is documented as unspecified. What stays exact: every fn run (node, inputs, `previous`), every
-- successful value, success-vs-error of every read, and per-step run counts per node (raw codes
-- are tallied in the summary line). Consumers only pcall-read (no emitDown abort), and the
-- cycle read is SELF only (a downstream cycle read makes the final state depend on who reads first).
-- Noise check: run the SAME tree twice; the output must be identical.
-- Mode "ub" (positive control): fns also Set their own upstream once and re-read themselves.
local args = { ... }
local N = tonumber(args[1]) or 2000
local MODE = args[2] or "defined"
DUMP = tonumber(args[3]) -- debug: print the canonical trace of this seed
local mock = require("./mock")
local Brand = require("../src/Brand")
local q = mock.newQuad()
local Source = q.Source
local MOD = {}
Brand.ModifierBrand:Register(MOD)

-- All read errors fold into ERR (which consumer receives boomN / Quad0184 / a Quad0185 that
-- propagated through a downstream fn depends on subscriber order — noise-checked). Raw codes
-- are only tallied. Anything that is not one of those three is kept verbatim (would be news).
local rawCodes = {}
local function code(e): string
	local s = tostring(e)
	local c = if s:match("boom%d+") then "boom" else s:match("(Quad%d+)")
	if c == nil then return "other:" .. (s:match("[^:]+$") or s):sub(1, 30) end
	rawCodes[c] = (rawCodes[c] or 0) + 1
	if c == "boom" or c == "Quad0184" or c == "Quad0185" then return "ERR" end
	return c
end

local function fnv(str: string, h: number): number
	for i = 1, #str do
		h = bit32.bxor(h, string.byte(str, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

local totals = { runs = 0, fires = 0, steps = 0, thrown = 0, e185 = 0, reads = 0 }

local function run(seed: number): (number, number)
	mock.resetTimers()
	math.randomseed(seed)
	local R = math.random
	local bucket = {}
	local runsThisStep = {}
	local h = 2166136261
	local nsteps = 0
	local function T(s: string) bucket[#bucket + 1] = s end
	local function step(label: string)
		table.sort(bucket)
		local rc = {}
		for k, v in runsThisStep do rc[#rc + 1] = `{k}:{v}` end
		table.sort(rc)
		local chunk = label .. "\n" .. table.concat(bucket, "\n") .. "\nR " .. table.concat(rc, ",")
		if DUMP == seed then print(chunk) end
		h = fnv(chunk, h)
		for _, l in bucket do
			if l:find(" ERR", 1, true) then totals.thrown += 1 end
		end
		bucket = {}
		runsThisStep = {}
		nsteps += 1
	end
	local nodes = {}
	local blockers = {}
	local srcs = {}
	for i = 1, R(1, 3) do
		nodes[i] = Source(R(0, 9)); srcs[#srcs + 1] = i
	end
	local nNodes = #nodes + R(2, 7)
	for i = #nodes + 1, nNodes do
		local roll = R()
		local a = R(1, i - 1)
		if roll < 0.15 then
			local bl = q.Blocker()
			blockers[#blockers + 1] = bl
			nodes[i] = nodes[a]:Apply(bl); if DUMP == seed then print(`G {i} = blk({a})`) end
		elseif roll < 0.22 then
			nodes[i] = nodes[a]:Apply(q.Debounce({ Time = R(1, 3) })); if DUMP == seed then print(`G {i} = deb({a})`) end
		else
			local b = R(1, i - 1)
			local throwMod = R(2, 7)
			local modMod = R(5, 11)
			local throws = R() < 0.3
			local mods = R() < 0.15
			local cyc = R() < 0.25
			local ub = MODE == "ub" and R() < 0.3
			local idx = i
			local ubLeft = 1
			nodes[i] = nodes[a]:Compute(function(hh, prev, h2)
				local v = hh:Get()
				local w = if h2 ~= nil then h2:Get() else 0
				if type(v) ~= "number" then v = 0 end
				if type(w) ~= "number" then w = 0 end
				local x = v + w + idx
				totals.runs += 1
				runsThisStep[idx] = (runsThisStep[idx] or 0) + 1
				T(`run {idx} x={x} prev={tostring(prev)}`)
				if cyc then
					local ok, e = pcall(function() return nodes[idx]:Get() end)
					T(`cyc {idx} {ok and tostring(e) or code(e)}`)
				end
				if ub and ubLeft > 0 and #srcs > 0 then
					ubLeft -= 1
					local s = nodes[srcs[1]]
					pcall(function() s:Set(s:Get() + 1) end)
					local ok, e = pcall(function() return nodes[idx]:Get() end)
					T(`ubread {idx} {ok and tostring(e) or code(e)}`)
				end
				if throws and x % throwMod == 0 then error(`boom{idx}`) end
				if mods and x % modMod == 0 then return MOD end
				return x
			end, nodes[b]); if DUMP == seed then print(`G {i} = cmp({a},{b}) throws={throws} mods={mods} cyc={cyc}`) end
		end
	end
	step("build")
	for _ = 1, R(0, 3) do
		local j = R(1, #nodes)
		local o = nodes[j]:Observer(function(st, _, from)
			totals.fires += 1
			local ok, e = pcall(function() return st:Get() end)
			T(`obs {j} {from ~= nil} {ok and tostring(e) or code(e)}`)
		end)
		o:Subscribe()
		step("obs")
	end
	for _ = 1, R(0, 2) do
		local j = R(1, #nodes)
		local eff = q.Effect(function()
			totals.fires += 1
			local ok2, e2 = pcall(function() return nodes[j]:Get() end)
			T(`eff {j} {ok2 and tostring(e2) or code(e2)}`)
		end, nodes[j])
		q.Backend.bindLifetime(mock.Instance.new("Frame"), eff)
		step("eff")
	end
	for _ = 1, R(10, 40) do
		local roll = R()
		if roll < 0.4 and #srcs > 0 then
			local s = srcs[R(1, #srcs)]
			local val = R(0, 20)
			local ok, e = pcall(function() nodes[s]:Set(val) end)
			T(`set {s} {ok and "ok" or code(e)}`)
			step("set")
		elseif roll < 0.75 then
			local j = R(1, #nodes)
			totals.reads += 1
			local ok, e = pcall(function() return nodes[j]:Get() end)
			T(`get {j} {ok and tostring(e) or code(e)}`)
			step("get")
		elseif roll < 0.88 and #blockers > 0 then
			local bl = blockers[R(1, #blockers)]
			local on = R() < 0.5
			local ok, e = pcall(function() if on then bl:On() else bl:Off() end end)
			T(`blk {on} {ok and "ok" or code(e)}`)
			step("blk")
		else
			local dt = R(1, 3)
			local ok, e = pcall(function() mock.advanceTime(dt) end)
			T(`time {ok and "ok" or code(e)}`)
			step("time")
		end
	end
	for j = 1, #nodes do
		local ok, e = pcall(function() return nodes[j]:Get() end)
		T(`fin {j} {ok and tostring(e) or code(e)}`)
		step("fin")
	end
	totals.steps += nsteps
	return h, nsteps
end

local crash = 0
local lines = {}
for seed = 1, N do
	local ok, hsh, n = pcall(run, seed)
	if not ok then crash += 1; lines[#lines + 1] = `{seed} CRASH {tostring(hsh):sub(1, 80)}` else lines[#lines + 1] = `{seed} {hsh} {n}` end
end
print(table.concat(lines, "\n"))
print(`mode {MODE} seeds {N} fnRuns {totals.runs} consumerFires {totals.fires} steps {totals.steps} reads {totals.reads} errLines {totals.thrown} crash {crash}`)
local rc = {}
for k, v in rawCodes do rc[#rc + 1] = `{k}={v}` end
table.sort(rc)
print("raw error codes (order-dependent split, tally only): " .. table.concat(rc, " "))
