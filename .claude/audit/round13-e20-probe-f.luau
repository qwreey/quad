--!nocheck
-- round13 E20 probe F — quad-roblox install idiom (e15 harness): doc examples core/05 + GS 08, lifetime subset on the real
-- quad-roblox hold ops, and the Deferred window x Subscribe re-arm. Run from repo root.
local H = require("./round13-e15-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local B = q.Backend
local function E(f, ...)
	local ok, err = pcall(f, ...)
	if ok then return "ok" end
	local s = tostring(err)
	return (s:match("Quad%d+[^\n]*") or s:sub(1, 100))
end

print("== core/05 Observer example")
do
	local hp = q.Source(100)
	local log = {}
	local observer = hp:Observer(function(target, self, emitFrom) table.insert(log, target:Get()) end)
	print("  ", #log, "(doc 1)")
	hp:Set(80); print("  ", #log, "(doc 1)")
	observer:Subscribe(); print("  ", #log, "(doc 2) last=", log[#log], "(doc 80)")
	hp:Set(60); print("  ", #log, "(doc 3)")
end
print("== core/05 Effect example")
do
	local hp = q.Source(100)
	local out = {}
	local effect = q.Effect(function(self)
		local value = hp:Get()
		table.insert(out, "hp:" .. value)
		return function() table.insert(out, "정리:" .. value) end
	end, hp)
	effect:Subscribe(); hp:Set(80); effect:Unsubscribe()
	print("  ", table.concat(out, " "), "(doc: hp:100 | 정리:100 hp:80 | 정리:80)")
end
print("== core/05 numeric-key example (TextLabel) + Destroy")
do
	local hp = q.Source(100)
	local out = {}
	local label = D.TextLabel {
		Text = hp:Compute(function(self) return `HP {self:Get()}` end),
		hp:Observer(function(target) table.insert(out, "obs" .. target:Get()) end),
		q.Effect(function() table.insert(out, "eff" .. hp:Get()) end, hp),
	}
	hp:Set(90)
	label:Destroy()
	hp:Set(80)
	print("  ", table.concat(out, " "), "Text=", label.Text)
end
print("== GS 08 block 3: State<Observer?> seat, Set(nil) stops it")
do
	local count = q.Source(0)
	local out = {}
	local logger = q.Source(count:Observer(function(t) table.insert(out, t:Get()) end))
	local card = D.Frame { logger }
	count:Set(1); count:Set(2)
	logger:Set(nil)
	count:Set(3)
	print("  ", table.concat(out, ","), "(doc: prints until Set(nil))")
end
print("== roblox lifetime subset: Effect bound via D, host Destroy, rebind to new host, Subscribe after destroy")
do
	local dep = q.Source(0)
	local cl, runs = {}, 0
	local eff = q.Effect(function() runs += 1; return function(d) table.insert(cl, tostring(d)) end end, dep)
	local f = D.Frame { eff }
	print("   bound: Sub", eff.Subscribed, "exe", B.canExecute(eff), "Subscribe→", E(function() eff:Subscribe() end), "bind other→", E(function() D.Frame { eff } end))
	f:Destroy()
	print("   destroyed: cl", table.concat(cl, ","), "exe", B.canExecute(eff), "_dying", eff._dying)
	local f2 = D.Frame { eff }
	print("   rebind new host: runs", runs, "exe", B.canExecute(eff))
	f2:Destroy()
	print("   Subscribe after 2nd destroy→", E(function() eff:Subscribe() end), "runs", runs, "cl", table.concat(cl, ","))
	dep:Set(1)
	print("   Set → runs", runs)
	eff:Unsubscribe()
	print("   Unsubscribe → cl", table.concat(cl, ","))
	print("   bindLifetime(1-arg primitive on corpse f2):", E(function() B.bindLifetime(f2, function() end) end))
end
print("== roblox + Deferred shim: Subscribe inside the window, then the queued Destroying arrives")
do
	local orig = B.onDestroying
	local queue = {}
	B.onDestroying = function(inst, fn) return orig(inst, function() table.insert(queue, fn) end) end
	local dep = q.Source(0)
	local cl, runs = {}, 0
	local eff = q.Effect(function() runs += 1; return function(d) table.insert(cl, tostring(d)) end end, dep)
	local f = D.Frame { eff }
	f:Destroy()
	eff:Subscribe()
	dep:Set(1)
	local qq = queue; queue = {}; for _, fn in qq do fn() end
	local r = runs
	dep:Set(2); dep:Set(3)
	print("   after stale callback: Sub", eff.Subscribed, "_dying", eff._dying, "cl", table.concat(cl, ","), "Sets→fn+", runs - r)
	B.onDestroying = orig
end
