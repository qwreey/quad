-- round13 E3 fuzzer (core propagation + Blocker/Debounce/Throttle + Effect). Copy to quad-base/test/ and run with luau. ALLOW_INSTALL=true reproduces the install-window loss (P2 family).
-- E1-2 variant: ALLOW_INSTALL=true, plus install-stale counters (pureCore = no Debounce/Throttle on the path)
-- core propagation fuzzer: values never gated, no lost notification after all blockers Off
local mock = require("./mock")
local q = mock.newQuad()
local Source, Blocker = q.Source, q.Blocker

INSTALLING = false
ALLOW_INSTALL = true
INSTALL_STALE = {}
local function run(seed, verbose)
	math.randomseed(seed)
	mock.resetTimers()
	BUDGET = 25
	local R = math.random
	local nodes = {} -- { obj, kind, deps, idx }
	local sources = {}
	local blockers = {}
	for i = 1, R(1, 3) do blockers[i] = Blocker() end
	local nS = R(2, 4)
	for i = 1, nS do
		local s = Source(R(0, 9))
		nodes[#nodes + 1] = { obj = s, kind = "S" }
		sources[#sources + 1] = #nodes
	end
	local nD = R(3, 9)
	for _ = 1, nD do
		local k = R(1, 6)
		local a = R(1, #nodes)
		if k == 1 then
			local b = R(1, #nodes)
			local c = nodes[a].obj:Compute(function(h, _, hb) return h:Get() + hb:Get() end, nodes[b].obj)
			nodes[#nodes + 1] = { obj = c, kind = "C", deps = { a, b } }
		elseif k == 2 then
			local b = R(1, #nodes)
			nodes[#nodes + 1] = { obj = nodes[a].obj:Depend(nodes[b].obj), kind = "D", deps = { a, b } }
		elseif k == 3 then
			local bl = blockers[R(1, #blockers)]
			nodes[#nodes + 1] = { obj = nodes[a].obj:Apply(bl), kind = "G", deps = { a } }
		elseif k == 4 then
			nodes[#nodes + 1] = { obj = nodes[a].obj:Compute(function(h) return h:Get() * 2 end), kind = "M", deps = { a } }
		elseif k == 5 then
			local t = ({ 0, 0.5, 1 })[R(1, 3)]
			local f = if R() < 0.5 then q.Debounce({ Time = t, Leading = R() < 0.5, MaxTime = if R() < 0.3 then 2 else nil }) else q.Throttle({ Time = t, Leading = R() < 0.5 })
			nodes[#nodes + 1] = { obj = nodes[a].obj:Apply(f), kind = "T", deps = { a }, f = f }
		else
			local mid = nodes[a].obj:Apply(blockers[R(1, #blockers)])
			local t = ({ 0, 0.5, 1 })[R(1, 3)]
			nodes[#nodes + 1] = { obj = mid:Apply(q.Debounce({ Time = t })), kind = "BT", deps = { a }, keep = mid }
		end
	end
	local sval = {}
	for _, si in sources do sval[si] = nodes[si].obj:Get() end
	local function ref(i)
		local n = nodes[i]
		if n.kind == "S" then return n.obj:Get() end
		if n.kind == "C" then return ref(n.deps[1]) + ref(n.deps[2]) end
		if n.kind == "M" then return ref(n.deps[1]) * 2 end
		return ref(n.deps[1])
	end
	-- observers: some reentrant — Set a source with smaller-or-equal "level"? to avoid loops, only set a source
	-- that this observer's node does NOT depend on (transitively), once per fire with depth limit
	local function dependsOn(i, si)
		if i == si then return true end
		local n = nodes[i]
		if n.deps then for _, d in n.deps do if dependsOn(d, si) then return true end end end
		return false
	end
	local function hasTimer(i)
		local n = nodes[i]
		if n.kind == "T" or n.kind == "BT" then return true end
		if n.deps then for _, d in n.deps do if hasTimer(d) then return true end end end
		return false
	end
	local obs = {}
	local depth = 0
	local log = {}
	for i = 1, #nodes do
		if R() < 0.6 then
			local target
			if R() < 0.4 then
				local cand = {}
				for _, si in sources do if not dependsOn(i, si) then cand[#cand + 1] = si end end
				if #cand > 0 then target = cand[R(1, #cand)] end
			end
			local rec = { node = i, last = nil, fires = 0 }
			INSTALLING = true
			local o = nodes[i].obj:Observer(function(st)
				rec.last = st:Get()
				rec.fires += 1
				if target and depth < 3 and (ALLOW_INSTALL or not INSTALLING) and BUDGET > 0 then
					BUDGET -= 1
					depth += 1
					nodes[target].obj:Set(rec.last % 7)
					depth -= 1
				end
			end)
			INSTALLING = false
			if rec.last ~= nodes[i].obj:Get() then INSTALL_STALE[#INSTALL_STALE + 1] = `node {i} kind {nodes[i].kind} T{hasTimer(i) and 1 or 0} seed-stale after install: saw {rec.last} now {nodes[i].obj:Get()}` end
			o:WeakSubscribe()
			rec.o = o
			obs[#obs + 1] = rec
		end
	end
	for i = 1, #nodes do
		if R() < 0.5 then
			local target
			if R() < 0.4 then
				local cand = {}
				for _, si in sources do if not dependsOn(i, si) then cand[#cand + 1] = si end end
				if #cand > 0 then target = cand[R(1, #cand)] end
			end
			local inCleanup = R() < 0.5
			local rec = { node = i, last = nil, fires = 0, effect = true }
			local extra = nodes[R(1, #nodes)].obj
			local e = q.Effect(function()
				rec.last = nodes[i].obj:Get()
				local _ = extra:Get()
				if target and not inCleanup and BUDGET > 0 then BUDGET -= 1; nodes[target].obj:Set(rec.last % 5) end
				return function()
					if target and inCleanup and BUDGET > 0 then BUDGET -= 1; nodes[target].obj:Set(R(0, 4)) end
				end
			end, nodes[i].obj)
			e:WeakSubscribe()
			rec.o = e
			obs[#obs + 1] = rec
		end
	end
	local steps = R(5, 40)
	for step = 1, steps do
		local op = R(1, 12)
		if op <= 5 then
			local si = sources[R(1, #sources)]
			nodes[si].obj:Set(R(0, 9))
			log[#log + 1] = `set{si}`
		elseif op <= 7 then
			local b = blockers[R(1, #blockers)]
			b:On()
			log[#log + 1] = "on"
		elseif op <= 9 then
			local b = blockers[R(1, #blockers)]
			b:Off()
			log[#log + 1] = "off"
		elseif op >= 11 then
			mock.advanceTime(({ 0, 0.3, 0.5, 1, 2 })[R(1, 5)])
			log[#log + 1] = "adv"
		else
			local i = R(1, #nodes)
			local got = nodes[i].obj:Get()
			if got ~= ref(i) then return false, `step {step} value node {i} got {got} want {ref(i)}` end
		end
		-- value invariant always
		for i = 1, #nodes do
			local got = nodes[i].obj:Get()
			if got ~= ref(i) then return false, `step {step} value node {i} ({nodes[i].kind}) got {got} want {ref(i)}` end
		end
	end
	for _, b in blockers do b:Off() end
	mock.advanceTime(50)
	for _, b in blockers do b:Off() end
	mock.advanceTime(50)
	for _, rec in obs do
		local cur = nodes[rec.node].obj:Get()
		if rec.last ~= cur then
			return false, `lost notification{rec.effect and " (EFFECT)" or ""}: node {rec.node} ({nodes[rec.node].kind}) observer last {rec.last} now {cur}; log {table.concat(log, " ")}`
		end
	end
	return true
end

local fails = 0
local staleTotal, staleSeeds = 0, 0
local pureStale = 0
for seed = 1, tonumber((... :: any)) or 20000 do
	INSTALL_STALE = {}
	local ok, ok2, msg = pcall(run, seed)
	if #INSTALL_STALE > 0 then staleTotal += #INSTALL_STALE; staleSeeds += 1 end
	for _, m in INSTALL_STALE do if string.find(m, "T0", 1, true) then pureStale += 1; if pureStale <= 3 then print("  pure-core stale seed", seed, m) end end end
	if ok and not ok2 then print("  install-stale:", table.concat(INSTALL_STALE, "; ")) end
	if not ok then
		fails += 1
		if fails <= 5 then print("seed", seed, "ERR", ok2) end
	elseif not ok2 then
		fails += 1
		if fails <= 8 then print("seed", seed, msg) end
	end
end
print("pureCoreInstallStale", pureStale, "installStaleSeeds", staleSeeds, "installStaleTotal", staleTotal, "fails", fails, "seeds", tonumber((... :: any)) or 20000)
