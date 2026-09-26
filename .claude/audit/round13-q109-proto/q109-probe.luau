--!nocheck
-- Run from a variant copy root (cp -rL quad-base <dir>/; patch <dir>/quad-base/src/Effect.luau with a .diff here; place this file in <dir>/audit/). Probe for P-Q109/Q110, 2026-09-27.
-- P-Q109 probe — run from a variant dir: `luau audit/q109.luau` (require path ../quad-base/test/mock)
local mock = require("../quad-base/test/mock")
local Instance = mock.Instance
local q = mock.newQuad()
local function hist(counts) local ks = {} for k in counts do table.insert(ks, k) end table.sort(ks) local o = {} for _, k in ks do table.insert(o, k .. "x" .. counts[k]) end return table.concat(o, " ") end

-- 1. E20 C2e shape: Effect sibling held an OLDER change, WeakSubscribed/Subscribed mid-wave by a sibling Observer
local function c2(kind, depKind, revive)
	local counts = {}
	for t = 1, 200 do
		local src = q.Source(0)
		local dep = if depKind == "Source" then src else src:Compute(function(s) return s:Get() end)
		local runs, pad = 0, {}
		for i = 1, t % 7 do pad[i] = src:Observer(function() end):Subscribe() end
		local sib
		if kind == "Observer" then sib = dep:Observer(function() runs += 1 end)
		else sib = q.Effect(function() runs += 1; dep:Get() end, dep) end
		if revive == "drive" then local h = Instance.new("Frame"); q.Dispatch.drive(h, { sib }); h:Destroy() end
		src:Set(1) -- held (older)
		local a = src:Observer(function(_, _, from)
			if from ~= nil and src:Get() == 2 then
				if revive == "drive" then q.Dispatch.drive(Instance.new("Frame"), { sib })
				elseif not sib.Subscribed then sib:Subscribe() end
			end
		end):Subscribe()
		runs = 0
		src:Set(2)
		counts[runs] = (counts[runs] or 0) + 1
		a:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
		if sib.Subscribed and revive ~= "drive" then sib:Unsubscribe() end
	end
	print(string.format("   %-8s dep=%-7s revive=%-9s runs-per-wave: %s", kind, depKind, revive, hist(counts)))
end
print("== 1. revive mid-wave (200 trials): runs in the wave of Set(2)")
for _, kind in { "Effect", "Observer" } do
	for _, depKind in { "Source", "Compute" } do
		for _, revive in { "Subscribe", "drive" } do c2(kind, depKind, revive) end
	end
end

-- 2. missed case: after the replay, the SAME wave changes the value again (another sibling Sets 3)
print("== 2. replay, then a later sibling in the same wave Sets 3 (200 trials): values the Effect saw")
do
	local seenHist = {}
	for t = 1, 200 do
		local src = q.Source(0)
		local seen = {}
		local pad = {}
		for i = 1, t % 7 do pad[i] = src:Observer(function() end):Subscribe() end
		local sib = q.Effect(function() table.insert(seen, src:Get()) end, src)
		src:Set(1)
		local a = src:Observer(function(_, _, from) if from ~= nil and src:Get() == 2 and not sib.Subscribed then sib:Subscribe() end end):Subscribe()
		local b = src:Observer(function(_, _, from) if from ~= nil and src:Get() == 2 and sib.Subscribed then src:Set(3) end end):Subscribe()
		table.clear(seen)
		src:Set(2)
		local key = table.concat(seen, ",") .. " final=" .. src:Get()
		seenHist[key] = (seenHist[key] or 0) + 1
		a:Unsubscribe(); b:Unsubscribe(); sib:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
	end
	for k, v in seenHist do print("   seen [" .. k .. "]:", v) end
end

-- 3. H-151 gate contract: withheld emit released after the catch-up must re-run
print("== 3. H-151 contract — Effect(fn, gated) held, Subscribe while Blocker on, then Off")
do
	local src = q.Source(0)
	local b = q.Blocker()
	local g = src:Apply(b)
	local seen = {}
	local eff = q.Effect(function() table.insert(seen, g:Get()) end, g)
	b:On(); src:Set(1)
	table.clear(seen)
	eff:Subscribe()
	local afterSub = table.concat(seen, ",")
	b:Off()
	print("   runs at Subscribe [" .. afterSub .. "]  total after Off [" .. table.concat(seen, ",") .. "]  (contract: Off re-runs)")
	eff:Unsubscribe()
end
do -- same with a Source sibling dep AND a gated dep (mixed)
	local src = q.Source(0)
	local b = q.Blocker()
	local g = src:Apply(b)
	local u = q.Source(0)
	local seen = {}
	local eff = q.Effect(function() table.insert(seen, g:Get() .. "/" .. u:Get()) end, g, u)
	b:On(); src:Set(1); u:Set(1)
	table.clear(seen)
	eff:Subscribe()
	local afterSub = table.concat(seen, ",")
	b:Off()
	print("   mixed: runs at Subscribe [" .. afterSub .. "]  total after Off [" .. table.concat(seen, ",") .. "]")
	eff:Unsubscribe()
end
do -- rebind (portal) while gated
	local src = q.Source(0)
	local b = q.Blocker()
	local g = src:Apply(b)
	local seen = {}
	local eff = q.Effect(function() table.insert(seen, g:Get()) end, g)
	local h1 = Instance.new("Frame"); q.Dispatch.drive(h1, { eff }); h1:Destroy()
	b:On(); src:Set(1)
	table.clear(seen)
	q.Dispatch.drive(Instance.new("Frame"), { eff })
	local afterSub = table.concat(seen, ",")
	b:Off()
	print("   rebind: runs at bind [" .. afterSub .. "]  total after Off [" .. table.concat(seen, ",") .. "]")
end

-- 4. H-159: Ref Set before bind still caught by the bind replay
print("== 4. H-159 — Ref dep Set before bind")
do
	local r = q.Ref()
	local seen = {}
	local eff = q.Effect(function() table.insert(seen, tostring(r.Value)) end, r)
	r:Set("button")
	q.Dispatch.drive(Instance.new("Frame"), { eff })
	print("   seen [" .. table.concat(seen, ",") .. "]")
end

-- 5. out-of-wave revive: held change, Subscribe later (not mid-wave), then an ordinary Set
print("== 5. ordinary revive then ordinary Set (no wave overlap)")
do
	local src = q.Source(0)
	local seen = {}
	local eff = q.Effect(function() table.insert(seen, src:Get()) end, src)
	src:Set(1)
	eff:Subscribe()
	src:Set(2)
	src:Set(2) -- same value: Source Set with equal value?
	print("   seen [" .. table.concat(seen, ",") .. "]")
	eff:Unsubscribe()
end
