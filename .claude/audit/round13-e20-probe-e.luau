--!nocheck
-- round13 E20 probe E — Effect cleanup contract per consumption site (rerun / Unsubscribe / host Destroy / seat swap):
-- throw, yield, Rerun inside, new Effect inside, non-function return. Run from repo root.
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local q = mock.newQuad()
local B = q.Backend
local function E(f, ...)
	local ok, err = pcall(f, ...)
	if ok then return "ok" end
	local s = tostring(err)
	return (s:match("Quad%d+[^\n]*") or s:match("[^/]*$"):sub(1, 90))
end

-- site builders: return (eff, trigger(), ctx)
local function mk(behaviour)
	local c = { runs = 0, log = {} }
	c.dep = q.Source(0)
	c.eff = q.Effect(function(self)
		c.runs += 1
		return function(dying)
			table.insert(c.log, "cl:" .. tostring(dying))
			behaviour(c, self, dying)
		end
	end, c.dep)
	return c
end

local sites = {
	rerun = function(c) c.eff:Subscribe(); return function() c.dep:Set(1) end end,
	unsubscribe = function(c) c.eff:Subscribe(); return function() c.eff:Unsubscribe() end end,
	destroy = function(c) c.host = Instance.new("Frame"); q.Dispatch.drive(c.host, { c.eff }); return function() c.host:Destroy() end end,
	swap = function(c)
		c.host = Instance.new("Frame"); c.seat = q.Source(c.eff)
		q.Dispatch.drive(c.host, { c.seat })
		return function() c.seat:Set(q.None) end
	end,
}
local behaviours = {
	throw = function(c) error("cleanup boom") end,
	rerunSelf = function(c, self) table.insert(c.log, "Rerun→" .. E(function() self:Rerun() end)) end,
	setDep = function(c) c.dep:Set(c.dep:Get() + 10) end,
	subscribeSelf = function(c, self) table.insert(c.log, "Subscribe→" .. E(function() self:Subscribe() end)) end,
	unsubscribeSelf = function(c, self) table.insert(c.log, "Unsubscribe→" .. E(function() self:Unsubscribe() end)) end,
	newEffectOnHost = function(c, self, dying)
		if c.host then
			local inner = q.Effect(function() table.insert(c.log, "innerFn") return function(d) table.insert(c.log, "innerCl:" .. tostring(d)) end end)
			table.insert(c.log, "bindInnerToHost→" .. E(function() q.Dispatch.drive(c.host, { inner }) end))
			c.inner = inner
		end
	end,
}
for _, bname in { "throw", "rerunSelf", "setDep", "subscribeSelf", "unsubscribeSelf", "newEffectOnHost" } do
	for _, sname in { "rerun", "unsubscribe", "destroy", "swap" } do
		local c = mk(behaviours[bname])
		local trig = sites[sname](c)
		c.runs = 0
		local r = E(trig)
		local after = `runs+{c.runs} run={tostring(c.eff._running)} clRun={tostring(c.eff._cleanupRunning)} Sub={tostring(c.eff.Subscribed)} exe={tostring(B.canExecute(c.eff))}`
		local extra = ""
		if sname == "destroy" then
			extra = ` hostDestroyedFully(parentNil/gcconnCut)={tostring(not B.canExecute(c.eff))}`
		end
		-- afterwards: does a dep change run fn? can it be re-armed?
		local r0 = c.runs
		pcall(function() c.dep:Set(c.dep:Get() + 1) end)
		local later = c.runs - r0
		local rearm = E(function() if c.eff.Subscribed then c.eff:Unsubscribe() end c.eff:Subscribe() end)
		if c.inner then
			extra ..= ` innerExe={tostring(B.canExecute(c.inner))}`
		end
		print(string.format("%-16s %-12s trig=%s | %s%s | log=[%s] | nextSet fn+%d | rearm=%s", bname, sname, r, after, extra, table.concat(c.log, " "), later, rearm))
	end
end

print("== mock Destroy aborted by a throwing Destroying handler: state of host / siblings")
do
	local host = Instance.new("Frame")
	local child = Instance.new("Frame"); child.Parent = host
	local dep = q.Source(0)
	local sibRuns = 0
	local sib = dep:Observer(function(_, _, f) if f then sibRuns += 1 end end)
	local eff = q.Effect(function() return function() error("x") end end, dep)
	q.Dispatch.drive(host, { eff, sib })
	print("   Destroy:", E(function() host:Destroy() end), "child parent:", child.Parent ~= nil, "sib exe:", B.canExecute(sib))
	dep:Set(1)
	print("   sibling observer on 'destroyed' host fired:", sibRuns)
end

print("== cleanup that yields (UB) — which entry points are blocked while suspended")
do
	local dep = q.Source(0)
	local co
	local eff = q.Effect(function()
		return function() co = coroutine.running(); coroutine.yield() end
	end, dep):Subscribe()
	local th = coroutine.create(function() dep:Set(1) end)
	coroutine.resume(th)
	print("   suspended in cleanup: clRun", eff._cleanupRunning, "running", eff._running)
	print("   Rerun:", E(function() eff:Rerun() end), "Set:", E(function() dep:Set(2) end), "Unsubscribe:", E(function() eff:Unsubscribe() end), "Sub", eff.Subscribed)
	coroutine.resume(th)
	print("   after resume: clRun", eff._cleanupRunning, "running", eff._running, "Sub", eff.Subscribed, "rerunRequired", eff._rerunRequired)
end
