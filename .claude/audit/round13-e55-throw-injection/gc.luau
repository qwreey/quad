--!nocheck
-- E55 axis (d): GC residue after throws, each case beside a no-throw control.
-- usage: luau gc.luau
local H = require("./harness")
local mockM = require("../../../quad-base/test/mock")
local q, D = H.q, H.D

local function gc() for _ = 1, 6 do collectgarbage("collect") end end

local cases = {}
local function case(name, fn)
	table.insert(cases, { name = name, fn = fn })
end

-- each fn(throw) returns the objects to watch (host instance, handles)
case("Observer fn threw, host destroyed", function(throw)
	local a = q.Source(1)
	local o = a:Observer(function(s) if throw and s:Get() == 2 then error("x") end end)
	local h = D.Frame({ o })
	pcall(function() a:Set(2) end)
	h:Destroy()
	return { host = h, handle = o }
end)
case("Effect fn threw, host destroyed", function(throw)
	local b = q.Source(1)
	local e = q.Effect(function() if throw and b:Get() == 2 then error("e") end end, b)
	local h = D.Frame({ e })
	pcall(function() b:Set(2) end)
	h:Destroy()
	return { host = h, handle = e }
end)
case("Effect fn threw, strong-subscribed, dropped", function(throw)
	local b = q.Source(1)
	local e = q.Effect(function() if throw and b:Get() == 2 then error("e") end end, b):Subscribe()
	pcall(function() b:Set(2) end)
	if not throw then e:Unsubscribe() end
	return { handle = e }
end)
case(":List updateFn threw (gate stuck), host destroyed", function(throw)
	local items = q.Source({ 1 })
	local sl = q.Slot():List(items, function(ctx)
		if throw and ctx.Item == 2 then error("u") end
		if ctx.Item == q.KeyGone then return nil end
		return ctx.Prev or D.Frame({})
	end)
	local h = D.Frame({ sl })
	pcall(function() items:Set({ 1, 2 }) end)
	h:Destroy()
	return { host = h, slot = sl }
end)
case("Declaration threw in OnRendered (half-built, Ref kept by caller then dropped)", function(throw)
	local r = q.Ref(nil)
	pcall(function() return D.Frame({ r, q.OnRendered(function() if throw then error("r") end end) }) end)
	local inst = r.Value
	if inst then inst:Destroy() end -- the documented recovery: dispose the orphan (sugar/05:39)
	return { host = inst, ref = r }
end)
case("Declaration threw in OnRendered, half-built NOT destroyed, no refs", function(throw)
	local weakInst = setmetatable({}, { __mode = "v" })
	pcall(function()
		return D.Frame({ q.OnCreated(function(inst) weakInst[1] = inst end), q.OnRendered(function() if throw then error("r") end end) })
	end)
	return { host = weakInst[1] }
end)
case("Declaration threw in PreRef (pre-pass), not destroyed", function(throw)
	local weakInst = setmetatable({}, { __mode = "v" })
	pcall(function()
		local pr = q.PreRef(nil)
		pr:Callback(function(v) if v then weakInst[1] = v; if throw then error("p") end end end)
		return D.Frame({ pr })
	end)
	return { host = weakInst[1] }
end)
case("Declaration threw in property (plain Compute), not destroyed", function(throw)
	local weakInst = setmetatable({}, { __mode = "v" })
	pcall(function()
		return D.Frame({ q.OnCreated(function(inst) weakInst[1] = inst end), q.Slot({ D.Frame({}) }),
			ZIndex = q.Source(1):Compute(function() if throw then error("c") end return 2 end) })
	end)
	return { host = weakInst[1] }
end)
case("nested-Slot attach: first-cycle updateFn threw during S1:Add(listSlot), root destroyed", function(throw)
	local S1 = q.Slot()
	local root = D.Frame({ S1 })
	local lst = q.Slot():List({ 1, 2 }, function(ctx)
		if throw and ctx.Item == 2 then error("fc") end
		if ctx.Item == q.KeyGone then return nil end
		return ctx.Prev or D.Frame({})
	end)
	pcall(function() S1:Add(lst) end)
	root:Destroy()
	return { host = root, slot = lst, parent = S1 }
end)
case("Offset subscriber threw (recompute window), host destroyed", function(throw)
	local s1, s2 = q.Slot(), q.Slot()
	local h = D.Frame({ s1, s2, s2.Offset:Observer(function(st) if throw and st:Get() == 1 then error("off") end end) })
	pcall(function() s1:Add(D.Frame({})) end)
	h:Destroy()
	return { host = h, slot = s2 }
end)
case("Offset subscriber threw, host NOT destroyed, all refs dropped", function(throw)
	local s1, s2 = q.Slot(), q.Slot()
	local h = D.Frame({ s1, s2, s2.Offset:Observer(function(st) if throw and st:Get() == 1 then error("off") end end) })
	pcall(function() s1:Add(D.Frame({})) end)
	return { host = h, slot = s2 }
end)
case("Tween Started threw (engine path), host destroyed", function(throw)
	local st = q.Source(0)
	local h = D.Frame({ BackgroundTransparency = st })
	pcall(function() st:Set(q.Tween({ Value = 0.5, Time = 1, Started = function() if throw then error("ts") end end, Completed = function() end })) end)
	h:Destroy()
	mockM.resetTweenLog() -- the mock log holds `inst` strongly (spec observation aid) — not engine behaviour
	return { host = h }
end)
case("Cleanup threw on destroy", function(throw)
	local e = q.Effect(function() return function() if throw then error("cl") end end end)
	local h = D.Frame({ e })
	h:Destroy()
	return { host = h, handle = e }
end)
case("attach-window: first-cycle updateFn threw while Add-ing into a mounted Slot", function(throw)
	local S1 = q.Slot()
	local root = D.Frame({ S1 })
	local lst = q.Slot():List({ 1, 2 }, function(ctx)
		if throw and ctx.Item == 2 then error("fc") end
		if ctx.Item == q.KeyGone then return nil end
		return ctx.Prev or D.Frame({})
	end)
	pcall(function() S1:Add(D.Frame({ lst })) end)
	root:Destroy()
	return { host = root, slot = lst, parent = S1 }
end)

-- probe mock handler isolation: engine-like
do
	local probe = mockM.Instance.new("Frame")
	local SignalMT = getmetatable(probe.Destroying)
	SignalMT.Fire = function(self, ...)
		local snapshot = table.clone(self.connections)
		for i = #snapshot, 1, -1 do
			local conn = snapshot[i]
			if conn.Connected then pcall(conn.fn, ...) end
		end
	end
	probe:Destroy()
end

for _, c in cases do
	local res = {}
	for _, throw in { false, true } do
		local weak = setmetatable({}, { __mode = "v" })
		local ok, got = pcall(c.fn, throw)
		if not ok then res[throw] = "crash: " .. H.first(got); continue end
		for k, v in got do weak[k] = v end
		got = nil
		gc()
		local alive = {}
		for k in weak do table.insert(alive, k) end
		table.sort(alive)
		res[throw] = #alive == 0 and "all collected" or ("ALIVE: " .. table.concat(alive, ","))
	end
	print(("%-78s control: %-22s throw: %s"):format(c.name, res[false], res[true]))
end
