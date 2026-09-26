--!nocheck
-- Run from a variant copy root (cp -rL quad-base <dir>/; patch <dir>/quad-base/src/Effect.luau with a .diff here; place this file in <dir>/audit/). Probe for P-Q109/Q110, 2026-09-27.
-- P-Q110 probe — run from a variant dir: `luau audit/q110.luau`
local mock = require("../quad-base/test/mock")
local Instance = mock.Instance
local q = mock.newQuad()
local function E(f, ...) local ok, err = pcall(f, ...) if ok then return "ok" end local s = tostring(err) return (s:match("Quad%d+[^\n]*") or s:sub(1, 100)) end

print("== 1. install fn Sets its own dep once (unbound)")
do
	local src = q.Source(0)
	local runs, cl, seen = 0, {}, {}
	local eff = q.Effect(function()
		runs += 1
		table.insert(seen, src:Get())
		if src:Get() == 0 then src:Set(1) end
		return function(d) table.insert(cl, tostring(d)) end
	end, src)
	print(string.format("   before bind: runs=%d seen=[%s] cleanups=[%s] rerunRequired=%s hasCleanup=%s", runs, table.concat(seen, ","), table.concat(cl, ","), tostring(eff._rerunRequired), tostring(eff._cleanup ~= nil)))
	eff:Subscribe()
	print(string.format("   after Subscribe: runs=%d seen=[%s] cleanups=[%s]", runs, table.concat(seen, ","), table.concat(cl, ",")))
	src:Set(5)
	print(string.format("   after Set(5): runs=%d seen=[%s] cleanups=[%s]", runs, table.concat(seen, ","), table.concat(cl, ",")))
	eff:Unsubscribe()
	print(string.format("   after Unsubscribe: cleanups=[%s]", table.concat(cl, ",")))
end

print("== 1b. same, bound by drive (leaf) instead of Subscribe, then host Destroy")
do
	local src = q.Source(0)
	local runs, cl, seen = 0, {}, {}
	local eff = q.Effect(function()
		runs += 1
		table.insert(seen, src:Get())
		if src:Get() == 0 then src:Set(1) end
		return function(d) table.insert(cl, tostring(d)) end
	end, src)
	local before = runs
	local h = Instance.new("Frame"); q.Dispatch.drive(h, { eff })
	print(string.format("   before bind runs=%d; after bind runs=%d seen=[%s] cleanups=[%s]", before, runs, table.concat(seen, ","), table.concat(cl, ",")))
	h:Destroy()
	print(string.format("   after Destroy cleanups=[%s]", table.concat(cl, ",")))
end

print("== 2. install fn calls self:Rerun() once (unbound)")
do
	local runs, cl = 0, {}
	local eff = q.Effect(function(self) runs += 1; if runs == 1 then self:Rerun() end; return function(d) table.insert(cl, tostring(d)) end end)
	print(string.format("   before bind: runs=%d cleanups=[%s] rerunRequired=%s", runs, table.concat(cl, ","), tostring(eff._rerunRequired)))
	eff:Subscribe()
	print(string.format("   after Subscribe: runs=%d cleanups=[%s]", runs, table.concat(cl, ",")))
	eff:Unsubscribe()
end
do -- control
	local runs = 0
	local eff = q.Effect(function() runs += 1 end)
	eff:Rerun()
	print(string.format("   control (Rerun outside fn, unbound): runs=%d rerunRequired=%s", runs, tostring(eff._rerunRequired)))
end

print("== 3. subscribed Effect: fn Sets its dep → runs once more (doc sentence)")
do
	local src = q.Source(0)
	local runs, seen, cl = 0, {}, {}
	local eff = q.Effect(function()
		runs += 1; table.insert(seen, src:Get())
		if src:Get() == 10 then src:Set(11) end
		return function(d) table.insert(cl, tostring(d)) end
	end, src)
	eff:Subscribe()
	runs = 0; table.clear(seen); table.clear(cl)
	src:Set(10)
	print(string.format("   Set(10) → runs=%d seen=[%s] cleanups=[%s]", runs, table.concat(seen, ","), table.concat(cl, ",")))
	eff:Unsubscribe()
end

print("== 4. unconditional self:Rerun() in fn (bounded at 50000 by the probe)")
do
	local runs = 0
	local eff = q.Effect(function(self) runs += 1; if runs < 50000 then self:Rerun() end end)
	print("   install (unbound) runs:", runs)
	local r0 = runs
	eff:Subscribe()
	print("   after Subscribe runs:", runs - r0)
	local r1 = runs
	eff:Rerun()
	print("   subscribed Rerun() runs:", runs - r1)
	eff:Unsubscribe()
end

print("== 5. install fn Sets its dep; a Blocker'd dep; Ref dep Set in install fn")
do
	local r = q.Ref()
	local seen = {}
	local eff = q.Effect(function() table.insert(seen, tostring(r.Value)); if r.Value == nil then r:Set("x") end end, r)
	print("   before bind seen [" .. table.concat(seen, ",") .. "]")
	q.Dispatch.drive(Instance.new("Frame"), { eff })
	print("   after bind seen [" .. table.concat(seen, ",") .. "]")
end

print("== 6. install fn Sets dep, then Effect is never bound (GC / Unsubscribe path)")
do
	local src = q.Source(0)
	local cl = {}
	local eff = q.Effect(function() if src:Get() == 0 then src:Set(1) end; return function(d) table.insert(cl, tostring(d)) end end, src)
	print("   unbound: cleanups [" .. table.concat(cl, ",") .. "] Unsubscribe→", E(function() eff:Unsubscribe() end))
	eff:WeakSubscribe(); eff:WeakUnsubscribe()
	print("   after WeakSubscribe/WeakUnsubscribe: cleanups [" .. table.concat(cl, ",") .. "]")
end
