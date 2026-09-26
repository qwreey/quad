--!nocheck
--[[
	SCRATCH spec draft (p-q76b) — NOT a repo spec. Two groups:
	  Q76 (A1+A1b adopted): KeyGone runs before this cycle's updateFn calls, gone keys from the back
	      (descending current position; keys with no mounted element last), and the observable
	      consequences (old elements already destroyed when a new item's updateFn runs; state left by a throw).
	  Q74 (owner-chain `_materializing` adopted): an Observer fired in a runtime Add's attach window
	      must not CRUD a grandparent/ancestor Slot (`Quad0167`), and no ghost child is left.
	Each case runs under pcall and prints PASS/FAIL, so one run gives a per-case table.
	Run from <copy>/quad-base: luau test/spec.q76b.draft.luau
]]
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch

local results = {}
local function case(name, fn)
	local ok, err = pcall(fn)
	table.insert(results, { name, ok, err })
	print((if ok then "PASS " else "FAIL ") .. name .. (if ok then "" else ("\n     " .. tostring(err))))
end
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function mkList(initial, log, opts)
	local data = q.Source(initial)
	local s = Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then
			table.insert(log, "gone:" .. tostring(ctx.UserData))
			return nil, ctx.UserData
		end
		local it = ctx.Item
		if log.hook then log.hook(it) end
		table.insert(log, it.id)
		if it.render == false then return nil, it.id end
		if ctx.Prev then return ctx.Prev, it.id end
		local f = F(tostring(it.id)); return f, it.id
	end, function(it) return it.id end, opts)
	return data, s
end
local function ids(...) local t = {} for i, v in { ... } do t[i] = { id = v } end return t end

-- ── Q76 ────────────────────────────────────────────────────────────────
case("Q76-1 KeyGone before this cycle's updateFn calls, gone keys from the back", function()
	local log = {}
	local data, s = mkList(ids("a", "b", "c", "d"), log)
	dispatch.drive(Instance.new("Folder"), { s })
	table.clear(log)
	data:Set(ids("x", "b", "y", "d"))
	local got = table.concat(log, " ")
	assert(got == "gone:c gone:a x b y d", "call order: " .. got)
end)

case("Q76-2 many gone keys (integer keys): strictly descending by position", function()
	local log = {}
	local init = {}
	for i = 1, 20 do init[i] = { id = i } end
	local data, s = mkList(init, log)
	dispatch.drive(Instance.new("Folder"), { s })
	table.clear(log)
	data:Set({ { id = 5 }, { id = 15 } })
	local gone = {}
	for _, e in log do local k = string.match(e, "^gone:(%d+)$"); if k then table.insert(gone, tonumber(k)) end end
	assert(#gone == 18, "18 gone")
	for i = 2, #gone do assert(gone[i - 1] > gone[i], "not descending: " .. table.concat(gone, ",")) end
	assert(string.sub(log[1], 1, 5) == "gone:" and log[#log] == 15, "gone first, then items: " .. table.concat(log, " "))
end)

case("Q76-3 a gone key with no mounted element (rendered nil) comes after the mounted ones", function()
	local log = {}
	local data, s = mkList({ { id = 1, render = false }, { id = 2 }, { id = 3 } }, log)
	dispatch.drive(Instance.new("Folder"), { s })
	table.clear(log)
	data:Set({})
	assert(table.concat(log, " ") == "gone:3 gone:2 gone:1", "order: " .. table.concat(log, " "))
end)

case("Q76-4 a new item's updateFn sees the gone elements already destroyed", function()
	local log = {}
	local parent = Instance.new("Folder")
	local data, s = mkList(ids("a", "b"), log)
	dispatch.drive(parent, { s })
	local a = parent:GetChildren()[1]
	local seen
	log.hook = function(it)
		if it.id == "x" and seen == nil then seen = { kids = #parent:GetChildren(), aDead = mock.isDestroyed(a) or a.Name ~= "a" and mock.isDestroyed(a) } end
	end
	-- find a/b by name (GetChildren order is not the contract)
	local byName = {}
	for _, c in parent:GetChildren() do byName[c.Name] = c end
	data:Set(ids("x", "y"))
	assert(seen ~= nil, "x updateFn ran")
	assert(seen.kids == 0, "children when x's updateFn ran: " .. seen.kids .. " (base: 2)")
	local _ = seen.aDead
	assert(mock.isDestroyed(byName.a) and mock.isDestroyed(byName.b), "old destroyed at the end")
end)

case("Q76-5 state left by a throw in a NEW item's updateFn: old elements already gone; next :Set recovers", function()
	local log = {}
	local parent = Instance.new("Folder")
	local data, s = mkList(ids("a", "b"), log)
	dispatch.drive(parent, { s })
	local byName = {}
	for _, c in parent:GetChildren() do byName[c.Name] = c end
	log.hook = function(it) if it.id == "boom" then error("user throw") end end
	local ok = pcall(function() data:Set(ids("x", "boom")) end)
	assert(not ok, "throws")
	log.hook = nil
	assert(mock.isDestroyed(byName.a) and mock.isDestroyed(byName.b), "old destroyed before the throw (base: still alive)")
	-- Length is NOT asserted: a throw leaves the batch gate On and Length stops emitting (core/06 UB, both versions)
	assert(#s._elements == 1 and #parent:GetChildren() == 1, "only x mounted (base: a,b,x)")
	data:Set(ids("x", "z"))
	local names = {}
	for _, c in parent:GetChildren() do table.insert(names, c.Name) end
	table.sort(names)
	assert(table.concat(names, ",") == "x,z" and #s._elements == 2, "recovered: " .. table.concat(names, ","))
end)

case("Q76-6 Detach on KeyGone + OwnsElements=false: same final state, gone first", function()
	local log = {}
	local parent = Instance.new("Folder")
	local data = q.Source(ids("a", "b", "c"))
	local s = Slot()
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then table.insert(log, "gone:" .. ctx.UserData); return q.Detach, ctx.UserData end
		table.insert(log, ctx.Item.id)
		return ctx.Prev or F(ctx.Item.id), ctx.Item.id
	end, function(it) return it.id end, { OwnsElements = false })
	dispatch.drive(parent, { s })
	table.clear(log)
	data:Set(ids("n", "b"))
	assert(table.concat(log, " ") == "gone:c gone:a n b", "order: " .. table.concat(log, " "))
	assert(s.Length:Get() == 2 and #parent:GetChildren() == 2, "final")
end)

-- ── Q74 ────────────────────────────────────────────────────────────────
case("Q74-1 grandparent Remove from an Observer inside a runtime Add's attach window is refused (Quad0167), no ghost", function()
	local parent = Instance.new("Folder")
	local inner = Slot()
	local outer = Slot({ inner })
	dispatch.drive(parent, { outer })
	local fired, rok, rerr = false, nil, nil
	inner.Length:Observer(function()
		if inner.Length:Get() > 0 and not fired then
			fired = true
			rok, rerr = pcall(function() outer:Remove(1) end)
		end
	end):Subscribe()
	local f = F("leaf")
	local sub = Slot({ f })
	pcall(function() inner:Add(sub) end)
	assert(fired, "observer fired")
	assert(rok == false and string.find(tostring(rerr), "Quad0167", 1, true), "grandparent Remove must raise Quad0167 (base: passes)")
	assert(not (mock.isDestroyed(f) and f.Parent == parent), "no destroyed leaf left parented (ghost child)")
	assert(not (sub._destroyed and sub._mounted), "no destroyed Slot left _mounted")
	assert(outer.Length:Get() == 1 and #parent:GetChildren() == 1, "outer keeps inner+leaf")
end)

case("Q74-2 depth-4 ancestor Clear from the same window is refused", function()
	local parent = Instance.new("Folder")
	local s4 = Slot()
	local s3 = Slot({ s4 }); local s2 = Slot({ s3 }); local s1 = Slot({ s2 })
	dispatch.drive(parent, { s1 })
	local fired, rok, rerr = false, nil, nil
	s4.Length:Observer(function()
		if s4.Length:Get() > 0 and not fired then
			fired = true
			rok, rerr = pcall(function() s1:Clear() end)
		end
	end):Subscribe()
	pcall(function() s4:Add(Slot({ F("deep") })) end)
	assert(fired and rok == false and string.find(tostring(rerr), "Quad0167", 1, true), "ancestor Clear must raise Quad0167")
	assert(s1.Length:Get() == 1, "tree intact")
end)

case("Q74-3 control (both): direct parent Clear is refused; sibling Add from the window passes", function()
	local parent = Instance.new("Folder")
	local inner = Slot()
	local sib = Slot()
	local outer = Slot({ inner, sib })
	dispatch.drive(parent, { outer })
	local fired, cok, cerr, sok = false, nil, nil, nil
	inner.Length:Observer(function()
		if inner.Length:Get() > 0 and not fired then
			fired = true
			cok, cerr = pcall(function() inner:Clear() end)
			sok = pcall(function() sib:Add(F("s")) end)
		end
	end):Subscribe()
	pcall(function() inner:Add(Slot({ F("leaf") })) end)
	assert(cok == false and string.find(tostring(cerr), "Quad0167", 1, true), "direct parent refused")
	assert(sok == true, "sibling Add passes")
	assert(outer.Length:Get() == 2, "Length 2")
end)

local pass = 0
for _, r in results do if r[2] then pass += 1 end end
print(`summary {pass}/{#results}`)
