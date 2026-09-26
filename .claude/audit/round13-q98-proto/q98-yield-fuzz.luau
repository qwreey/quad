-- P-Q98 yield fuzzer (P-Q93 fuzzer + per-generation start/complete counts):
-- dupSeq = a node's fn STARTS in generation g after a run of g already COMPLETED (the Q98 symptom);
-- dupAny = any second start in the same generation (Q93 overlap + Q98 + thrown-fn retries).
-- random Compute DAG, some fns yield; random coroutines read, resume, Set.
-- Metrics: overlap = same node's fn parked twice in the SAME generation (the Q93 symptom);
-- e184 = Quad0184 raised to a reader; stuck = after all coroutines drain + a fresh Set on every
-- source, some node still raises; wrong = final value differs from reference.
local MAIN = coroutine.running()
local mock = require("./mock")
local q = mock.newQuad()
local Source = q.Source
local stuckNoSet, nested184 = 0, 0
local noStamp, thrownStamp, orphan = 0, 0, 0
threw = {}
local dupSeq, dupAny = 0, 0
local overlap, e184, other, stuck, wrong, runsTotal = 0, 0, 0, 0, 0, 0
local FINAL = false
local function run(seed)
	FINAL = false
	threw = {}
	math.randomseed(seed)
	local R = math.random
	local nodes, ref = {}, {}
	local parked = {} -- node idx -> { [gen] = count }
	local started, completed = {}, {}
	local yieldy = {}
	local srcs = {}
	for i = 1, R(1, 3) do nodes[i] = Source(R(0, 9)); srcs[#srcs + 1] = i; ref[i] = function() return nodes[i]:Get() end end
	local refv = {}
	local function refval(i)
		return refv[i]
	end
	local defs = {}
	for i = #nodes + 1, #nodes + R(2, 6) do
		local a, b = R(1, i - 1), R(1, i - 1)
		yieldy[i] = R() < 0.6
		defs[i] = { a, b }
		local idx = i
		nodes[i] = nodes[a]:Compute(function(h, _prev, h2)
			local g = nodes[idx]._computing -- the generation this run stamped
			threw[idx] = threw[idx] or {}
			threw[idx][g] = true -- cleared below if the reads return
			started[idx] = started[idx] or {}; completed[idx] = completed[idx] or {}
			started[idx][g] = (started[idx][g] or 0) + 1
			if started[idx][g] > 1 then dupAny += 1 end
			if (completed[idx][g] or 0) > 0 then dupSeq += 1 end
			local x, y = h:Get(), h2:Get()
			threw[idx][g] = nil
			runsTotal += 1
			parked[idx] = parked[idx] or {}
			if yieldy[idx] and not FINAL and coroutine.running() ~= MAIN and R() < 0.7 then
				parked[idx][g] = (parked[idx][g] or 0) + 1
				if parked[idx][g] > 1 then overlap += 1 end
				coroutine.yield()
				parked[idx][g] -= 1
			end
			completed[idx][g] = (completed[idx][g] or 0) + 1
			return x + y
		end, nodes[b])
	end
	local cos = {}
	local function tryRead(i)
		local ok, e = pcall(function() return nodes[i]:Get() end)
		if not ok then
			if tostring(e):find("Quad0184") then e184 += 1 else other += 1; if other <= 2 then print("other", e) end end
		end
	end
	for _ = 1, R(10, 40) do
		local k = R(1, 4)
		if k == 1 then
			local i = R(1, #nodes)
			local co = coroutine.create(function() tryRead(i) end)
			coroutine.resume(co)
			if coroutine.status(co) == "suspended" then cos[#cos + 1] = co end
		elseif k == 2 and #cos > 0 then
			local j = R(1, #cos)
			local co = cos[j]
			coroutine.resume(co)
			if coroutine.status(co) ~= "suspended" then table.remove(cos, j) end
		elseif k == 3 then
			nodes[srcs[R(1, #srcs)]]:Set(R(0, 9))
		else
			local i = R(1, #nodes)
			tryRead(i) -- main-thread reader (never parks)
		local co = coroutine.create(function() tryRead(i) end) -- plus a coroutine reader reader in a coroutine that may park
			coroutine.resume(co)
			if coroutine.status(co) == "suspended" then cos[#cos + 1] = co end
		end
	end
	-- drain
	local guard = 0
	while #cos > 0 and guard < 1000 do
		guard += 1
		local co = table.remove(cos, 1)
		coroutine.resume(co)
		if coroutine.status(co) == "suspended" then cos[#cos + 1] = co end
	end
	FINAL = true
	for i = 1, #nodes do
		local ok = pcall(function() return nodes[i]:Get() end)
		if not ok then stuckNoSet += 1; local st = nodes[i]._computing; if st == -1 then noStamp += 1 elseif threw[i] and threw[i][st] then thrownStamp += 1 else orphan += 1 end end
	end
	-- fresh generation everywhere, then read from main (not yieldable → no parking)
	for _, s in srcs do nodes[s]:Set(nodes[s]:Get() + 100) end
	for i = 1, #nodes do
		local want
		if defs[i] then want = refv[defs[i][1]] + refv[defs[i][2]] else want = nodes[i]:Get() end
		refv[i] = want
		local ok, v = pcall(function() return nodes[i]:Get() end)
		if not ok then stuck += 1 elseif v ~= want then wrong += 1 end
	end
end
local N = tonumber((... :: any)) or 3000
local crash = 0
for seed = 1, N do
	local ok, e = pcall(run, seed)
	if not ok then crash += 1; if crash <= 3 then print("crash", seed, e) end end
end
print(`stuckNoSet(after drain, same gen) {stuckNoSet} = thrownStamp {thrownStamp} + orphan {orphan} + downstreamOfStuck(noStamp) {noStamp}`)
print(`dupSeq {dupSeq} dupAny {dupAny}`)
print(`seeds {N} overlap {overlap} e184 {e184} otherErr {other} stuck {stuck} wrong {wrong} fnRuns {runsTotal} crash {crash}`)
