--!nocheck
-- E50 teardown fuzzer: random component tree x teardown path x callback action -> event log vs reference model.
-- usage: luau fuzz.luau -a <firstSeed> <count> [verbose] [iso|raw]
local H = require("./harness")
local mockM = require("../../../quad-base/test/mock")
local q, D = H.q, H.D
local CS = H.CollectionService
local args = { ... }
local FIRST = tonumber(args[1]) or 1
local COUNT = tonumber(args[2]) or 100
local VERBOSE = args[3] == "v"
local ISO = args[4] ~= "raw" -- default: engine-like handler isolation (Roblox runs each handler separately)
local DEFERRED = args[4] == "deferred" -- Destroying handlers delivered after the Destroy call returns (Roblox default SignalBehavior)
local deferredQ = {}
local handlerErrs = {}
if DEFERRED then
	local orig = q.Backend.onDestroying
	q.Backend.onDestroying = function(inst, fn)
		return orig(inst, function(...) table.insert(deferredQ, fn) end)
	end
end
local function flushDeferred()
	while #deferredQ > 0 do
		local fn = table.remove(deferredQ, 1)
		local ok, e = pcall(fn)
		if not ok then table.insert(handlerErrs, H.first(e)) end
	end
end
local MUT = args[5] -- mutation for detection-power check: noDestroying | claimedAlways | removeIsExtract
if MUT == "noDestroying" then q.Backend.onDestroying = function() return { Disconnect = function() end, Connected = true } end end
if MUT == "claimedAlways" then q.Backend.isClaimed = function() return true end end
if MUT == "removeIsExtract" then q.Backend.nativeRemove = q.Backend.nativeExtract end

-- engine-like: each Destroying/event handler isolated (mock Fire has no pcall — mock limit)
do
	local probe = mockM.Instance.new("Frame")
	local SignalMT = getmetatable(probe.Destroying)
	local origFire = SignalMT.Fire
	if ISO then
		SignalMT.Fire = function(self, ...)
			local snapshot = table.clone(self.connections)
			for i = #snapshot, 1, -1 do
				local conn = snapshot[i]
				if conn.Connected then
					local ok, e = pcall(conn.fn, ...)
					if not ok then table.insert(handlerErrs, H.first(e)) end
				end
			end
		end
	end
	probe:Destroy()
end

local rmTags = {}
local origRm = CS.RemoveTag
CS.RemoveTag = function(self, inst, name) rmTags[name] = (rmTags[name] or 0) + 1 return origRm(self, inst, name) end

local rs = 1
local function nextF()
	rs = (rs * 1103515245 + 12345) % 2147483648
	return rs / 2147483648
end
local function R(n) return math.floor(nextF() * n) + 1 end
local function P(p) return nextF() < p end

local totals = { seeds = 0, diffs = 0, nodes = 0, paths = {}, actions = {}, waveCrossFires = 0, waveSameFires = 0, waveAliveFires = 0, depFnOnDyingHost = 0, opErrs = {}, cbErrs = {} }
local function bump(t, k) t[k] = (t[k] or 0) + 1 end

local function runSeed(seed)
	rs = seed * 7919 + 17; for _ = 1, 5 do nextF() end
	table.clear(rmTags)
	table.clear(handlerErrs)
	mockM.resetTweenLog()
	local phase = "build"
	local pulse = q.Source(0)
	local nodes = {}
	local ev = {} -- wave order log
	local diffs = {}
	local currentActor = nil -- node id whose callback is running
	local cbErrs = {}

	local function newNode(depth, parent)
		local n = { id = #nodes + 1, depth = depth, parent = parent, children = {}, c = {
			effT = 0, effF = 0, depT = 0, depF = 0, depFnAfterDeath = 0, od = 0,
			obsPost = 0, obsWave = 0, debPost = 0, started = 0, completed = 0, cancelled = 0,
		} }
		nodes[n.id] = n
		return n
	end

	local function doAction(n)
		local a = n.action
		if a == "none" then return end
		local prev = currentActor
		currentActor = n.id
		if a == "read" then
			local o = nodes[R(#nodes)]
			local _ = o.ref and o.ref.Value
		elseif a == "set" then
			pulse:Set(pulse:Get() + 1)
		elseif a == "crud" then
			if n.slot then
				local ok, e = pcall(function()
					if n.slot.Length:Get() > 0 and P(0.5) then n.slot:Remove(1) else n.slot:Add(D.Frame { Name = "late" }) end
				end)
				if not ok then table.insert(cbErrs, H.first(e)) end
			end
		elseif a == "throw" then
			currentActor = prev
			error("boom" .. n.id)
		end
		currentActor = prev
	end

	-- build bottom-up
	local function build(depth, parent)
		local n = newNode(depth, parent)
		local nk = depth < 4 and R(4) or 0
		if depth == 1 then nk = math.max(nk, 1) end
		if depth >= 2 and P(0.45) then nk = 0 end
		n.action = ({ "none", "none", "read", "set", "crud", "throw" })[R(6)]
		bump(totals.actions, n.action)
		for _ = 1, nk do
			local ch = build(depth + 1, n)
			ch.mode = ({ "static", "slot", "list", "seat" })[R(4)]
			table.insert(n.children, ch)
		end
		local props = { Name = "n" .. n.id }
		local a = {}
		if P(0.6) then n.eff = true; table.insert(a, q.Effect(function()
			return function(d)
				if d then n.c.effT += 1 else n.c.effF += 1 end
				table.insert(ev, "C" .. n.id)
				doAction(n)
			end
		end)) end
		if P(0.4) then n.dep = true; table.insert(a, q.Effect(function()
			pulse:Get()
			if n.depDied then n.c.depFnAfterDeath += 1
			elseif phase == "wave" and n.inst and mockM.isDestroyed(n.inst) then totals.depFnOnDyingHost += 1 end
			return function(d) if d then n.c.depT += 1; n.depDied = true else n.c.depF += 1 end end
		end, pulse)) end
		if P(0.5) then n.od = true; table.insert(a, q.OnDestroyed(function()
			n.c.od += 1
			table.insert(ev, "D" .. n.id)
			doAction(n)
		end)) end
		if P(0.5) then n.obs = true; table.insert(a, pulse:Observer(function()
			if phase == "post" then n.c.obsPost += 1
			elseif phase == "wave" then
				n.c.obsWave += 1
				if mockM.isDestroyed(n.inst) then
					if currentActor == n.id then totals.waveSameFires += 1 else totals.waveCrossFires += 1; if VERBOSE then print("  crossfire host n" .. n.id .. " by n" .. tostring(currentActor)) end end
				else totals.waveAliveFires += 1 end
			end
		end)) end
		if P(0.3) then n.deb = true; table.insert(a, pulse:Apply(q.Debounce({ Time = 1 })):Observer(function()
			if phase == "post" then n.c.debPost += 1 end
		end)) end
		if P(0.5) then n.tag = true; table.insert(a, q.Tag("N" .. n.id)) end
		if P(0.5) then n.attr = true; table.insert(a, q.Attr({ ["A" .. n.id] = n.id })) end
		if P(0.5) then n.ref = q.Ref(nil); table.insert(a, n.ref) end
		if P(0.4) then n.sizeSrc = q.Source(1); props.Size = n.sizeSrc end
		-- children placement
		local slotEls, listKeys = {}, {}
		for _, ch in n.children do
			if ch.mode == "static" then table.insert(a, ch.inst)
			elseif ch.mode == "slot" then table.insert(slotEls, ch.inst); ch.holder = n
			elseif ch.mode == "list" then table.insert(listKeys, ch.id); ch.holder = n
			elseif ch.mode == "seat" then ch.seat = q.Source(ch.inst); table.insert(a, ch.seat) end
		end
		if #slotEls > 0 or P(0.2) then
			n.slot = q.Slot(slotEls)
			table.insert(a, n.slot)
		end
		if #listKeys > 0 then
			n.owns = P(0.5)
			n.listData = q.Source(listKeys)
			local byKey = {}
			for _, ch in n.children do if ch.mode == "list" then byKey[ch.id] = ch.inst end end
			n.list = q.Slot():List(n.listData, function(ctx)
				if ctx.Item == q.KeyGone then return nil end
				if ctx.Prev then return ctx.Prev end
				return byKey[ctx.Item]
			end, function(it) return it end, { OwnsElements = n.owns })
			table.insert(a, n.list)
		end
		-- shuffle numeric attachments
		for i = #a, 2, -1 do local j = R(i); a[i], a[j] = a[j], a[i] end
		for i, v in a do props[i] = v end
		n.inst = D.Frame(props)
		return n
	end

	local root = build(1, nil)
	root.mode = "root"
	totals.nodes += #nodes
	-- start tweens
	for _, n in nodes do
		if n.sizeSrc then
			n.sizeSrc:Set(q.Tween({ Value = 5, Time = 1,
				Started = function() n.c.started += 1 end,
				Completed = function() n.c.completed += 1 end,
				Cancelled = function() n.c.cancelled += 1 end }))
			n.tween = mockM.tweenLog[#mockM.tweenLog].tween
		end
	end
	-- pending debounce timers
	pulse:Set(pulse:Get() + 1)
	H.runTask(0.5)

	local function subtree(n, out)
		out = out or {}
		table.insert(out, n)
		for _, ch in n.children do if not ch.cut then subtree(ch, out) end end
		return out
	end

	-- choose teardown ops (1..3 sequential ops on still-attached nodes)
	local dead, detached = {}, {}
	local attachedSet = {}
	for _, n in nodes do attachedSet[n] = true end
	local function mark(set, list) for _, x in list do set[x] = true end end
	local function unattach(list) for _, x in list do attachedSet[x] = nil end end
	local pathsDone = {}
	local T, path
	local phase2 = false
	phase = "wave"
	for _opi = 1, R(3) do
		local cands = {}
		for _, n in nodes do if attachedSet[n] and not dead[n] then table.insert(cands, n) end end
		if #cands == 0 then break end
		T = cands[R(#cands)]
		if T.mode == "root" then path = P(0.5) and "Destroy" or "dispose"
		elseif T.mode == "static" then path = "disposeHeld"
		elseif T.mode == "slot" then path = ({ "Remove", "Clear", "Extract" })[R(3)]
		elseif T.mode == "list" then path = T.holder.owns and "KeyGoneOwned" or "KeyGoneUnowned"
		elseif T.mode == "seat" then path = "SeatNil" end
		local opOk, opErr
		local sub = subtree(T)
		if path == "Destroy" then mark(dead, sub); unattach(sub)
			opOk, opErr = pcall(function() T.inst:Destroy() end)
		elseif path == "dispose" then mark(dead, sub); unattach(sub)
			opOk, opErr = pcall(function() q.dispose(T.inst) end)
		elseif path == "disposeHeld" then
			opOk, opErr = pcall(function() q.dispose(T.inst) end)
			if opOk then table.insert(diffs, "disposeHeld: expected Quad0179, succeeded"); mark(dead, sub); unattach(sub) end
			if not opOk and not tostring(opErr):find("Quad0179") then table.insert(diffs, "disposeHeld: wrong error " .. H.first(opErr)) end
			opOk = true
		elseif path == "Remove" then mark(dead, sub); unattach(sub)
			opOk, opErr = pcall(function() T.holder.slot:Remove(T.holder.slot:IndexOf(T.inst)) end)
		elseif path == "Clear" then
			for _, ch in T.holder.children do if ch.mode == "slot" and attachedSet[ch] then local s2 = subtree(ch); mark(dead, s2); unattach(s2) end end
			opOk, opErr = pcall(function() T.holder.slot:Clear() end)
		elseif path == "Extract" then mark(detached, sub); unattach(sub)
			opOk, opErr = pcall(function() T.holder.slot:Extract(T.holder.slot:IndexOf(T.inst)) end)
		elseif path == "KeyGoneOwned" or path == "KeyGoneUnowned" then
			if path == "KeyGoneOwned" then mark(dead, sub) else mark(detached, sub) end
			unattach(sub)
			local keys = {}
			for _, k in T.holder.listData:Get() do if k ~= T.id then table.insert(keys, k) end end
			opOk, opErr = pcall(function() T.holder.listData:Set(keys) end)
		elseif path == "SeatNil" then mark(detached, sub); unattach(sub)
			opOk, opErr = pcall(function() T.seat:Set(nil) end)
		end
		if path == "Clear" then for _, ch in T.holder.children do if ch.mode == "slot" then ch.cut = true end end
		elseif path ~= "disposeHeld" and T.mode ~= "root" then T.cut = true end
		bump(totals.paths, path)
		table.insert(pathsDone, path .. ":n" .. T.id)
		if not opOk then table.insert(diffs, "op " .. path .. " threw: " .. H.first(opErr)) end
		flushDeferred()
		-- dispose a detached subtree (half the time)
		if (path == "Extract" or path == "KeyGoneUnowned" or path == "SeatNil") and P(0.5) then
			phase2 = true
			local ok, e = pcall(function() q.dispose(T.inst) end)
			if not ok then table.insert(diffs, "phase2 dispose threw: " .. H.first(e)) end
			flushDeferred()
			for _, x in sub do dead[x] = true; detached[x] = nil end
		end
	end
	path = table.concat(pathsDone, ",")
	for _, n in nodes do if dead[n] then n.dead = true end end
	-- post
	phase = "post"
	for _, n in nodes do if n.tween then n.tween:simulateCompleted() end end
	pulse:Set(pulse:Get() + 1)
	H.runTask(10)

	-- model check
	for _, n in nodes do
		local c = n.c
		local isDead = dead[n] == true
		local function chk(cond, what) if not cond then table.insert(diffs, ("n%d(%s,%s,d%d) %s"):format(n.id, n.mode, isDead and "dead" or (detached[n] and "detached" or "alive"), n.depth, what)) end end
		if n.eff then chk(c.effT == (isDead and 1 or 0), "effect cleanup dying=true count " .. c.effT); chk(c.effF == 0, "effect cleanup dying=false count " .. c.effF) end
		if n.od then chk(c.od == (isDead and 1 or 0), "OnDestroyed count " .. c.od) end
		if n.dep then chk(c.depT == (isDead and 1 or 0), "dep effect dying=true count " .. c.depT); chk(c.depFnAfterDeath == 0, "dep effect fn ran after death " .. c.depFnAfterDeath)
			if not isDead then chk(c.depF >= 1, "alive dep effect did not rerun in post (depF=" .. c.depF .. ")") end end
		if n.obs then chk(c.obsPost == (isDead and 0 or 1), "observer post fires " .. c.obsPost) end
		if n.deb and isDead then chk(c.debPost == 0, "debounce observer fired after death " .. c.debPost) end
		if n.sizeSrc then chk(c.started == 1, "tween Started " .. c.started); chk(c.cancelled == 0, "tween Cancelled " .. c.cancelled)
			chk(c.completed == (isDead and 0 or 1), "tween Completed " .. c.completed) end
		if n.tag then chk((rmTags["N" .. n.id] or 0) == 0, "RemoveTag calls " .. tostring(rmTags["N" .. n.id])) end
		if n.attr then chk(n.inst:GetAttribute("A" .. n.id) == n.id, "attr value " .. tostring(n.inst:GetAttribute("A" .. n.id))) end
		if n.ref then chk(n.ref.Value == n.inst, "ref.Value changed") end
		if isDead then chk(mockM.isDestroyed(n.inst), "instance not destroyed") else chk(not mockM.isDestroyed(n.inst), "instance destroyed") end
	end
	totals.seeds += 1
	if #diffs > 0 then
		totals.diffs += 1
		print(("SEED %d ops=%s phase2=%s nodes=%d DIFFS:"):format(seed, path, tostring(phase2), #nodes))
		for i, d in diffs do if i <= 8 then print("   " .. d) end end
	elseif VERBOSE then
		print(("seed %d ok path=%s nodes=%d ev=%s"):format(seed, path, #nodes, table.concat(ev, " ")))
	end
	-- clean up survivors
	pcall(function() root.inst:Destroy() end)
	for _, n in nodes do pcall(function() if not mockM.isDestroyed(n.inst) then n.inst:Destroy() end end) end
end

for s = FIRST, FIRST + COUNT - 1 do
	local ok, e = pcall(runSeed, s)
	if not ok then totals.diffs += 1; print("SEED " .. s .. " HARNESS ERROR " .. tostring(e)) end
end
print(("== seeds=%d diffSeeds=%d nodes=%d iso=%s deferredDestroying=%s"):format(totals.seeds, totals.diffs, totals.nodes, tostring(ISO), tostring(DEFERRED)))
local function dump(name, t) local ks = {} for k, v in t do table.insert(ks, k .. "=" .. v) end table.sort(ks) print(name .. ": " .. table.concat(ks, ", ")) end
dump("paths", totals.paths); dump("actions", totals.actions)
print("wave observer fires on hosts whose Destroy already started: sameHost=" .. totals.waveSameFires .. " crossHost=" .. totals.waveCrossFires .. "; on hosts not yet destroying=" .. totals.waveAliveFires)
print("dep Effect fn reruns on a host whose Destroy started, before its dying cleanup: " .. totals.depFnOnDyingHost)
dump("callback errors", totals.cbErrs)
