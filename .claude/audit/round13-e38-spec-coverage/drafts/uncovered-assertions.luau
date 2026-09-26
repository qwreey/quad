--!nocheck
--[[
	E38 draft (NOT a spec — no `spec.` prefix on purpose; the decision to promote any of these is the user's).
	Assertion-form of the probes in ../probes/ for the public paths that no spec executes today
	(luau --coverage: the lines named per block never ran under test.sh). Place next to mock.luau
	(quad-base/test/) to run. Every assert below passes at HEAD 886626ea.
]]
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function throwsId(id, f) local ok, e = pcall(f); assert(not ok and string.find(tostring(e), id, 1, true), id .. ": " .. tostring(e)) end

do -- effect:Rerun() — public method, zero direct spec calls (core/05 "effect:Rerun()")
	local log = {}
	local e = q.Effect(function() table.insert(log, "fn"); return function() table.insert(log, "cl") end end)
	e:Subscribe(); table.clear(log)
	assert(e:Rerun() == e and table.concat(log, " ") == "cl fn", "cleanup then fn, returns self")
	local n = 0
	local held = q.Effect(function() n += 1 end) -- constructor runs fn once (forced install)
	held:Rerun(); held:Rerun()
	assert(n == 1, "unsubscribed/unbound: held")
	held:Subscribe(); assert(n == 2, "replayed ONCE on Subscribe")
	local m = 0
	local self2; self2 = q.Effect(function(s) m += 1; if m == 2 then s:Rerun(); s:Rerun() end end)
	self2:Subscribe(); self2:Rerun(); assert(m == 3, "re-entrant requests coalesce into one deferred run")
end

do -- Slot:List reconcile errors (List.luau:95/117 never ran) — state stays usable
	local data = q.Source({ { id = 1 }, { id = 2 } })
	local s = Slot()
	s:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or F(tostring(ctx.Item.id)) end, function(it) return it.id end)
	local p = Instance.new("Folder"); dispatch.drive(p, { s })
	throwsId("Quad0145", function() data:Set({ { id = 1 }, { id = 1 } }) end)
	throwsId("Quad0142", function() data:Set(5) end)
	assert(s.Length:Get() == 2, "rejected cycles leave the list as it was")
	data:Set({ { id = 3 } }); assert(s.Length:Get() == 1 and #p:GetChildren() == 1, "next valid Set reconciles")
end

do -- held (Detach) element dies with its owner (core/06 q.Detach: "Slot이 파괴될 때 같이 파괴") — Tree.luau:203-206, List.luau:188-192
	local data = q.Source({ { id = "x" } })
	local s = Slot(); local fx
	s:List(data, function(ctx) if ctx.Item == q.KeyGone then return q.Detach end fx = ctx.Prev or F("x"); return fx end, function(it) return it.id end)
	local outer = Slot(); outer:Add(s)
	dispatch.drive(Instance.new("Folder"), { outer })
	data:Set({}); assert(not mock.isDestroyed(fx), "held")
	outer:Remove(1); assert(mock.isDestroyed(fx), "owner Slot destroyed → held element destroyed")
	local data2 = q.Source({ { id = "x" } })
	local s2 = Slot(); local fy
	s2:List(data2, function(ctx) if ctx.Item == q.KeyGone then return q.Detach end fy = ctx.Prev or F("y"); return fy end, function(it) return it.id end)
	local p2 = Instance.new("Folder"); dispatch.drive(p2, { s2 })
	data2:Set({}); p2:Destroy(); assert(mock.isDestroyed(fy), "physical parent destroyed → held element destroyed")
end

do -- detached key returns with a NEW element (List.luau:77-79): the held one is destroyed
	local show, data = q.Source(true), q.Source({ { id = "x" } })
	local s = Slot(); local made = {}
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone or not show:Get() then return q.Detach end
		local f = F("x" .. (#made + 1)); table.insert(made, f); return f
	end, function(it) return it.id end)
	dispatch.drive(Instance.new("Folder"), { s })
	show:Set(false); data:Set({ { id = "x" } })
	show:Set(true); data:Set({ { id = "x" } })
	assert(mock.isDestroyed(made[1]) and s.Length:Get() == 1, "held element replaced and destroyed")
end

do -- :List installed on an already-mounted empty Slot (List.luau:256-257)
	local s = Slot(); local outer = Slot(); outer:Add(F("before")); outer:Add(s); outer:Add(F("after"))
	dispatch.drive(Instance.new("Folder"), { outer })
	s:List({ 1, 2 }, function(ctx) return F("L" .. ctx.Item) end)
	assert(s.Length:Get() == 2 and s.Offset:Get() == 1 and outer.Length:Get() == 4, "activates at install")
end

do -- Debounce MaxTime cap is cleared when the window ends first (Debounce.luau:178-179)
	mock.resetTimers()
	local src = q.Source(0)
	local g = src:Apply(q.Debounce({ Time = 1, MaxTime = 5 }))
	local n = 0
	local o = g:Observer(function() n += 1 end); o:Subscribe(); n = 0
	src:Set(1); mock.advanceTime(1); assert(n == 1, "trailing pass")
	mock.advanceTime(1); mock.advanceTime(4)
	assert(n == 1 and mock.pendingTimers() == 0, "no cap fire after the window closed")
end

do -- public-surface error ids no spec throws today (all messages match docs/reference/errors)
	throwsId("Quad0045", function() q.Debounce() end)
	throwsId("Quad0012", function() q.Attr.Overridden(5) end)
	throwsId("Quad0190", function() q.Source(1):Observer(5) end)
	throwsId("Quad0180", function() q.dispose({}) end)
	throwsId("Quad0134", function() table.sort({ 1, 2, 3 }, function(a, b) q.Ref(nil):Wait(); return a < b end) end)
	local e = q.Effect(function() end); dispatch.drive(Instance.new("Frame"), { e })
	throwsId("Quad0231", function() e:Subscribe() end); throwsId("Quad0230", function() e:WeakSubscribe() end)
	local o = q.Source(1):Observer(function() end); dispatch.drive(Instance.new("Frame"), { o })
	throwsId("Quad0235", function() o:Subscribe() end); throwsId("Quad0234", function() o:WeakSubscribe() end)
	local w = q.Effect(function() end); w:WeakSubscribe(); throwsId("Quad0089", function() w:WeakSubscribe() end)
	local st = q.Store({ A = q.Source(1) }); st[""] = q.Source(2); throwsId("Quad0003", function() q.Attr(st) end)
	local dead = Slot(); q.dispose(dead); throwsId("Quad0140", function() dispatch.drive(Instance.new("Folder"), { dead }) end)
	local f = F("same"); local s2 = Slot(); s2:List({ 1, 2 }, function() return f end)
	throwsId("Quad0156", function() dispatch.drive(Instance.new("Folder"), { s2 }) end)
end
print("ALL PASS (draft)")
