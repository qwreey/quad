--!nocheck
-- p-slot-bundle interaction probe (scratch): cases where two of Q74/Q76/Q111/Q112/Q113/Q114 meet.
-- Run from <copy>/quad-base: luau test/probe.bundle.interact.luau
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function short(e) local s = tostring(e); local id = string.match(s, "Quad%d%d%d%d"); return id or (string.gsub(s, "^.-:%d+: ", "")):sub(1, 60) end
local function kids(p) local t = {} for _, c in p:GetChildren() do table.insert(t, c.Name .. (if mock.isDestroyed(c) then "(dead)" else "")) end return table.concat(t, ",") end
local function case(name, fn) local ok, e = pcall(fn); if not ok then print(name, "!! " .. short(e)) end end

-- I1: Q74 (owner chain) x state-driven ancestor change. Observer in inner's attach window drives the
-- ANCESTOR wrapper's State (not a public CRUD — assertNotMounting is not on this path).
for _, mode in { "nil", "cycle-outer", "self", "otherleaf" } do
	case("I1/" .. mode, function()
		local parent = Instance.new("Folder")
		local inner = Slot()
		local st = q.Source(inner)
		local outer = Slot({ F("head"), st })
		dispatch.drive(parent, { outer })
		local fired, rok, rerr = false, nil, nil
		inner.Length:Observer(function()
			if inner.Length:Get() > 0 and not fired then
				fired = true
				rok, rerr = pcall(function()
					if mode == "nil" then st:Set(nil)
					elseif mode == "cycle-outer" then st:Set(outer)
					elseif mode == "self" then st:Set(st)
					else st:Set(F("other")) end
				end)
			end
		end):Subscribe()
		local f = F("leaf"); local sub = Slot({ f })
		local aok, aerr = pcall(function() inner:Add(sub) end)
		print("I1/" .. mode, "fired", fired, "set", if rok then "ok" elseif rok == nil then "-" else short(rerr),
			"add", if aok then "ok" else short(aerr),
			"| inner.d", inner._destroyed, "sub.d/m", sub._destroyed, sub._mounted, "leafDead", mock.isDestroyed(f), "leafParent", if f.Parent == parent then "host" elseif f.Parent then f.Parent.Name else "nil",
			"| outerLen", outer.Length:Get(), "kids", kids(parent), "outer.mat", outer._materializing)
		-- recovery probe
		local ok2, e2 = pcall(function() outer:Add(F("after")) end)
		print("   after-add", if ok2 then "ok" else short(e2), "outerLen", outer.Length:Get(), "kids", kids(parent))
	end)
end

-- I2: Q76 (KeyGone first) x Q111 B/Q112 (State seat): the same State element moves from a gone key to a new key in one :Set.
for _, v in { "leaf", "nil", "slot" } do
	case("I2/" .. v, function()
		local parent = Instance.new("Folder")
		local val = if v == "leaf" then F("x") elseif v == "slot" then Slot({ F("x") }) else nil
		local S1 = q.Source(val)
		local data = q.Source({ { id = "a", st = S1 } })
		local s = Slot()
		local log = {}
		s:List(data, function(ctx)
			if ctx.Item == q.KeyGone then table.insert(log, "gone"); return nil end
			table.insert(log, ctx.Item.id); return ctx.Item.st
		end, function(it) return it.id end)
		dispatch.drive(parent, { s })
		local ok, e = pcall(function() data:Set({ { id = "b", st = S1 } }) end)
		print("I2/" .. v, "set", if ok then "ok" else short(e), "log", table.concat(log, " "), "len", s.Length:Get(), "kids", kids(parent))
		local ok2, e2 = pcall(function() S1:Set(F("y")) end)
		print("   S1:Set(y)", if ok2 then "ok" else short(e2), "len", s.Length:Get(), "kids", kids(parent))
	end)
end

-- I2c: two keys swap their State elements in one :Set (keys stay; items change -> updateFn returns the other State)
case("I2c", function()
	local parent = Instance.new("Folder")
	local S1, S2 = q.Source(F("x1")), q.Source(F("x2"))
	local data = q.Source({ { id = "a", st = S1 }, { id = "b", st = S2 } })
	local s = Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		return ctx.Item.st
	end, function(it) return it.id end)
	dispatch.drive(parent, { s })
	local ok, e = pcall(function() data:Set({ { id = "a", st = S2 }, { id = "b", st = S1 } }) end)
	print("I2c", "set", if ok then "ok" else short(e), "len", s.Length:Get(), "kids", kids(parent))
end)

-- I3: identity wrapper re-nests its old Slot value into the new value (X -> Slot{X}); Q76 order x Q111 A DFS
for _, own in { true, false } do
	case("I3/own=" .. tostring(own), function()
		local parent = Instance.new("Folder")
		local X = Slot({ F("x") })
		local st = q.Source(X)
		local outer = Slot({ st })
		dispatch.drive(parent, { outer })
		local ok, e = pcall(function() st:Set(Slot({ X })) end)
		print("I3", "set", if ok then "ok" else short(e), "X.d", X._destroyed, "len", outer.Length:Get(), "kids", kids(parent))
	end)
end

-- I4: :List, new key's updateFn returns the gone key's (still-referenced) element — Q76 observable (destroyed first)
case("I4", function()
	local parent = Instance.new("Folder")
	local cache = {}
	local data = q.Source({ "a" })
	local s = Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Item == "b" then return cache.a end
		local f = F(ctx.Item); cache[ctx.Item] = f; return f
	end)
	dispatch.drive(parent, { s })
	local ok, e = pcall(function() data:Set({ "b" }) end)
	print("I4", "set", if ok then "ok" else short(e), "len", s.Length:Get(), "kids", kids(parent))
end)

-- I5: Q113 x Q76: identity :List of States, one Set both removes a key and introduces a cyclic State
case("I5", function()
	local parent = Instance.new("Folder")
	local A = q.Source(F("a"))
	local C = q.Source(nil)
	local data = q.Source({ A, F("b") })
	local s = Slot()
	s:List(data)
	dispatch.drive(parent, { s })
	C:Set(C) -- make C cyclic before it is listed
	local ok, e = pcall(function() data:Set({ C }) end)
	print("I5", "set", if ok then "ok" else short(e), "len", s.Length:Get(), "kids", kids(parent), "blocking", q.Bookkeeping and "?" or "?")
	local ok2, e2 = pcall(function() data:Set({ F("c") }) end)
	print("   recover", if ok2 then "ok" else short(e2), "len", s.Length:Get(), "kids", kids(parent))
end)

-- I6: Q111 A (Set-time cycle) on a :Single(st) (user identity single) inside an attach window (Q74)
case("I6", function()
	local parent = Instance.new("Folder")
	local inner = Slot()
	local st = q.Source(F("z"))
	local mid = Slot()
	mid:Single(st)
	local outer = Slot({ mid, inner })
	dispatch.drive(parent, { outer })
	local fired, rok, rerr = false, nil, nil
	inner.Length:Observer(function()
		if inner.Length:Get() > 0 and not fired then
			fired = true
			rok, rerr = pcall(function() st:Set(outer) end)
		end
	end):Subscribe()
	local aok, aerr = pcall(function() inner:Add(Slot({ F("leaf") })) end)
	print("I6", "set", if rok then "ok" else short(rerr), "add", if aok then "ok" else short(aerr), "len", outer.Length:Get(), "kids", kids(parent))
	local ok2, e2 = pcall(function() st:Set(F("w")) end)
	print("   recover", if ok2 then "ok" else short(e2), "len", outer.Length:Get(), "kids", kids(parent))
end)
