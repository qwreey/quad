--!nocheck
-- round13 E20 probe C — transitions inside an upstream Set wave. Run from repo root.
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local q = mock.newQuad()
local B = q.Backend
local function E(f, ...)
	local ok, err = pcall(f, ...)
	if ok then return "ok" end
	local s = tostring(err)
	return (s:match("Quad%d+[^\n]*") or s:sub(1, 120))
end

print("== C1 fn unsubscribes a sibling mid-wave: does the sibling still get this wave? (200 trials, varied creation order)")
do
	local got, missed = 0, 0
	for t = 1, 200 do
		local src = q.Source(0)
		local sib
		local sibRuns = 0
		local pad = {}
		for i = 1, t % 7 do pad[i] = src:Observer(function() end):Subscribe() end
		local a = src:Observer(function(_, _, from) if from ~= nil and sib.Subscribed then sib:Unsubscribe() end end):Subscribe()
		sib = src:Observer(function(_, _, from) if from ~= nil then sibRuns += 1 end end):Subscribe()
		src:Set(1)
		if sibRuns == 1 then got += 1 else missed += 1 end
		a:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
		if sib.Subscribed then sib:Unsubscribe() end
	end
	print("   sibling fired before being unsubscribed:", got, " held (not fired):", missed)
end

print("== C2 fn subscribes a sibling that holds an OLDER change: runs in this wave")
do
	local counts = {}
	for t = 1, 200 do
		local src = q.Source(0)
		local sib
		local sibRuns = 0
		local pad = {}
		for i = 1, t % 7 do pad[i] = src:Observer(function() end):Subscribe() end
		sib = src:Observer(function() sibRuns += 1 end) -- not subscribed
		src:Set(1) -- held change (older)
		local a = src:Observer(function(_, _, from) if from ~= nil and not sib.Subscribed then sib:Subscribe() end end):Subscribe()
		sibRuns = 0
		src:Set(2)
		counts[sibRuns] = (counts[sibRuns] or 0) + 1
		a:Unsubscribe(); sib:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
	end
	for k, v in counts do print("   sibling ran", k, "times in one wave:", v, "trials") end
end

print("== C2e same for Effect sibling (held change, subscribed mid-wave)")
do
	local counts = {}
	for t = 1, 200 do
		local src = q.Source(0)
		local sibRuns = 0
		local pad = {}
		for i = 1, t % 7 do pad[i] = src:Observer(function() end):Subscribe() end
		local sib = q.Effect(function() sibRuns += 1 end, src)
		src:Set(1)
		local a = src:Observer(function(_, _, from) if from ~= nil and not sib.Subscribed then sib:Subscribe() end end):Subscribe()
		sibRuns = 0
		src:Set(2)
		counts[sibRuns] = (counts[sibRuns] or 0) + 1
		a:Unsubscribe(); sib:Unsubscribe(); for _, p in pad do p:Unsubscribe() end
	end
	for k, v in counts do print("   effect sibling ran", k, "times in one wave:", v, "trials") end
end

print("== C3 Observer self-Set recursion depth (nested waves) vs Effect (flat _pending loop)")
for _, N in { 100, 1000, 5000, 20000, 100000 } do
	local src = q.Source(0)
	local maxDepth, depth = 0, 0
	local o = src:Observer(function(t)
		depth += 1
		if depth > maxDepth then maxDepth = depth end
		if t:Get() < N then t:Set(t:Get() + 1) end
		depth -= 1
	end)
	local r = E(function() o:Subscribe() end)
	local src2 = q.Source(0)
	local eff = q.Effect(function() if src2:Get() < N then src2:Set(src2:Get() + 1) end end, src2)
	local r2 = E(function() eff:Subscribe(); src2:Set(1) end)
	print(string.format("   N=%d Observer: %s maxDepth=%d final=%d | Effect: %s final=%d", N, r, maxDepth, src:Get(), r2, src2:Get()))
end

print("== C4 Effect Rerun() from inside its own fn: loops without depth")
do
	local runs = 0
	local eff
	eff = q.Effect(function(self) runs += 1; if runs < 50000 then self:Rerun() end end)
	print("   install runs (unbound, force):", runs)
	runs = 0
	eff:Subscribe()
	eff:Rerun()
	print("   subscribed Rerun loop runs:", runs)
end

print("== C5 Effect A's fn calls B:Subscribe/Unsubscribe/Rerun while B is up the stack (B running)")
do
	local src = q.Source(0)
	local A, Bh
	local out = {}
	Bh = q.Effect(function()
		if src:Get() == 1 then src:Set(2) end -- nested: A runs while B is running
		return function(d) table.insert(out, "Bcl:" .. tostring(d)) end
	end, src)
	A = q.Effect(function()
		if src:Get() == 2 then
			table.insert(out, "A→B:Subscribe " .. E(function() Bh:Subscribe() end))
			table.insert(out, "A→B:Rerun " .. E(function() Bh:Rerun() end))
			table.insert(out, "A→B:WeakUnsubscribe " .. E(function() Bh:WeakUnsubscribe() end))
		end
	end, src)
	A:Subscribe(); Bh:WeakSubscribe()
	src:Set(1)
	print("  ", table.concat(out, " | "))
	print("   B after: Sub=", Bh.Subscribed, "running=", Bh._running)
end

print("== C6 Observer fn destroys its own host mid-wave; siblings bound to the same host / descendant")
do
	for t = 1, 3 do
		local src = q.Source(0)
		local host = Instance.new("Frame")
		local child = Instance.new("Frame"); child.Parent = host
		local log = {}
		local killer = src:Observer(function(_, _, from) if from then table.insert(log, "killer"); host:Destroy() end end)
		local sib = src:Observer(function(_, _, from) if from then table.insert(log, "sib(exe=" .. tostring(B.canExecute(nil)) .. ")") end end)
		local desc = src:Observer(function(_, _, from) if from then table.insert(log, "desc") end end)
		local effRuns = 0
		local eff = q.Effect(function() effRuns += 1 end, src)
		if t == 1 then B.bindLifetime(host, killer); B.bindLifetime(host, sib); B.bindLifetime(child, desc); B.bindLifetime(host, eff)
		elseif t == 2 then B.bindLifetime(host, sib); B.bindLifetime(child, desc); B.bindLifetime(host, eff); B.bindLifetime(host, killer)
		else B.bindLifetime(child, desc); B.bindLifetime(host, eff); B.bindLifetime(host, sib); B.bindLifetime(host, killer) end
		effRuns = 0
		src:Set(1)
		print("   order", t, table.concat(log, ","), "effRuns", effRuns)
	end
end

print("== C7 q.dispose(host) from inside an Effect fn bound to that host")
do
	local src = q.Source(0)
	local host = Instance.new("Frame")
	local cl = {}
	local runs = 0
	local eff = q.Effect(function()
		runs += 1
		if src:Get() == 1 then q.dispose(host) end
		return function(d) table.insert(cl, tostring(d)) end
	end, src)
	B.bindLifetime(host, eff)
	src:Set(1)
	src:Set(2)
	print("   runs", runs, "cleanups", table.concat(cl, ","), "dying", eff._dying, "running", eff._running)
end
