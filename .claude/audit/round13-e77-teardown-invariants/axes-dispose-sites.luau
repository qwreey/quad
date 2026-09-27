--!nocheck
-- E77 axes: q.dispose(root) called from inside each user-callback site that the fuzzer does not use as a
-- teardown trigger. Per site: does the root die, did its Effect get exactly one cleanup(true), did OnDestroyed run
-- once, any raised error (with/without Quad id), any callback after teardown, GC residue of the tree.
local H = require("./harness")
local q, D, mock = H.q, H.D, H.mock
local pulse = q.Source(0)
local function fullgc() for _ = 1, 6 do collectgarbage("collect") end end
local SITES = {}
local function site(name, f) table.insert(SITES, { name = name, f = f }) end
-- each site builder returns (root, trigger) ; `kill()` disposes root
site("updateFn(churn)", function(kill)
	local data = q.Source({ 1 })
	local root = D.Frame({ q.Slot():List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end if ctx.Item == 2 then kill() end return ctx.Prev or D.Frame({}) end) })
	return root, function() data:Set({ 1, 2 }) end
end)
site("keyFn(churn)", function(kill)
	local data = q.Source({ 1 })
	local root = D.Frame({ q.Slot():List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or D.Frame({}) end, function(it) if it == 2 then kill() end return it end) })
	return root, function() data:Set({ 1, 2 }) end
end)
site("Ref.Callback", function(kill)
	local r = q.Ref(nil)
	local root = D.Frame({ r })
	r:Callback(function(v) if v == "go" then kill() end end)
	return root, function() r:Set("go") end
end)
site("Tween.Started", function(kill)
	local s = q.Source(1)
	local root = D.Frame({ Size = s:Compute(function(x) local v = x:Get(); return q.Tween({ Value = v, Time = 1, Started = function() if v == 2 then kill() end end }) end) })
	return root, function() s:Set(2) end
end)
site("Tween.Cancelled", function(kill)
	local s = q.Source(1)
	local root = D.Frame({ Size = s:Compute(function(x) local v = x:Get(); return q.Tween({ Value = v, Time = 1, Cancelled = function() if v == 2 then kill() end end }) end) })
	return root, function() s:Set(2); s:Set(3) end
end)
site("Effect fn", function(kill)
	local go = q.Source(false)
	local root = D.Frame({ q.Effect(function() if go:Get() then kill() end end, go) })
	return root, function() go:Set(true) end
end)
site("Observer(own host)", function(kill)
	local go = q.Source(false)
	local root = D.Frame({ go:Observer(function(s) if s:Get() then kill() end end) })
	return root, function() go:Set(true) end
end)
site("Throttle Observer(timer)", function(kill)
	local go = q.Source(0)
	local root = D.Frame({ go:Apply(q.Throttle({ Time = 1, Leading = false })):Observer(function(s) if s:Get() == 1 then kill() end end) })
	return root, function() go:Set(1); H.runTask(1.5) end
end)
site("q.Out write-back", function(kill)
	local src = q.Source("a")
	local box
	local root = D.Frame({ D.TextBox({ Text = src, q.Out("Text", src) }), src:Observer(function(s) if s:Get() == "close" then kill() end end) })
	return root, function() root:GetChildren()[1].Text = "close" end
end)
site("Slot.Offset Observer", function(kill)
	local front = q.Slot()
	local back = q.Slot({ D.Frame({}) })
	local root = D.Frame({ front, back, back.Offset:Observer(function(s) if s:Get() == 1 then kill() end end) })
	return root, function() front:Add(D.Frame({})) end
end)
site("OnCreated(child being built)", function(kill)
	local s = q.Slot()
	local root = D.Frame({ s })
	return root, function() s:Add(D.Frame({ q.OnCreated(function() kill() end) })) end
end)
site("Context value Observer", function(kill)
	local P = q.Context.Provider("X"); local v = q.Source(0); local bag = q.Context():Set(P, v)
	local root = D.Frame({ bag:Get(P):Observer(function(s) if s:Get() == 1 then kill() end end) })
	return root, function() v:Set(1) end
end)
for _, S in SITES do
	local log = { cl = {}, od = 0, post = 0 }
	local phase = "run"
	local root
	local function kill() q.dispose(root) end
	local tracker = setmetatable({}, { __mode = "k" })
	local errs = {}
	local ok, e = pcall(function()
		local r, trig = S.f(kill)
		root = r
		q.Dispatch.drive(root, {}) -- no-op (keeps positions)
		local ef = q.Effect(function() pulse:Get(); if phase == "post" then log.post += 1 end return function(d) table.insert(log.cl, tostring(d)) end end, pulse)
		local od = q.OnDestroyed(function() log.od += 1 end)
		local holder = q.Slot({ D.Frame({ ef, od, pulse:Observer(function() if phase == "post" then log.post += 1 end end) }) })
		-- attach the probe child through a Slot declared up front is impossible post-hoc; use a fresh wrapper instead
		root.Parent = nil
		tracker[root] = "root"; tracker[ef] = "effect"
		local wrapperKids = holder
		local w = D.Frame({ wrapperKids })
		w.Parent = root -- plain parenting: root's Destroy takes w down with it
		tracker[w] = "probeChild"
		trig()
	end)
	if not ok then table.insert(errs, H.first(e)) end
	local destroyed = root and mock.isDestroyed(root)
	if root and not destroyed then pcall(q.dispose, root) end
	phase = "post"
	pcall(function() pulse:Set(pulse:Get() + 1); H.runTask(5) end)
	mock.resetTweenLog()
	root = nil
	fullgc()
	local surv = {}
	for _, k in tracker do table.insert(surv, k) end
	print(string.format("%-28s destroyedByKill=%-5s cleanup=[%s] od=%d post=%d errs=[%s] gcSurvivors=[%s]", S.name, tostring(destroyed), table.concat(log.cl, ","), log.od, log.post, table.concat(errs, " | "), table.concat(surv, ",")))
end
