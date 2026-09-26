--!nocheck
-- round13 E20 probe B — Deferred Destroying (spec.effect 11 queue shim) x re-arm by Subscribe/WeakSubscribe
-- (H-574 guarded only the rebind path). Run from repo root.
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local q = mock.newQuad()
local B = q.Backend
local orig = B.onDestroying
local queue = {}
B.onDestroying = function(inst, fn)
	return orig(inst, function() table.insert(queue, fn) end)
end
local function flush() local qq = queue; queue = {}; for _, f in qq do f() end end

for _, how in { "Subscribe", "WeakSubscribe", "rebind", "unbind+Subscribe" } do
	local dep = q.Source(0)
	local runs, cl = 0, {}
	local eff = q.Effect(function()
		runs += 1
		return function(d) table.insert(cl, tostring(d)) end
	end, dep)
	local host = Instance.new("Frame")
	q.Dispatch.drive(host, { eff })
	host:Destroy() -- gcconn cut now, Destroying queued
	local host2
	if how == "Subscribe" then eff:Subscribe()
	elseif how == "WeakSubscribe" then eff:WeakSubscribe()
	elseif how == "rebind" then host2 = Instance.new("Frame"); q.Dispatch.drive(host2, { eff })
	else B.unbindLifetime(eff); eff:Subscribe() end
	local r0 = runs
	dep:Set(1)
	local beforeFlush = runs - r0
	flush()
	local r1 = runs
	dep:Set(2)
	dep:Set(3)
	print(string.format("%-18s set-before-flush fn+%d | after stale callback: Sub=%s dying=%s exe=%s cl=[%s] | 2 more Sets fn+%d",
		how, beforeFlush, tostring(eff.Subscribed), tostring(eff._dying), tostring(B.canExecute(eff)), table.concat(cl, ","), runs - r1))
	if how == "Subscribe" or how == "unbind+Subscribe" then
		local ok, e = pcall(eff.Unsubscribe, eff)
		print("    then Unsubscribe:", ok, e and tostring(e):match("Quad%d+"), "cl=", table.concat(cl, ","))
	end
end

-- Observer control: no Destroying connection, so no stale callback path
do
	local dep = q.Source(0)
	local runs = 0
	local o = dep:Observer(function() runs += 1 end)
	local host = Instance.new("Frame")
	q.Dispatch.drive(host, { o })
	host:Destroy()
	o:Subscribe()
	flush()
	local r = runs
	dep:Set(5)
	print("Observer control: Subscribe in window then flush → Set fn+" .. (runs - r))
end
B.onDestroying = orig
