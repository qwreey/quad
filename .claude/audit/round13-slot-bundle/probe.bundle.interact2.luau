--!nocheck
-- p-slot-bundle interaction probe 2 (scratch)
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function short(e) local s = tostring(e); local id = string.match(s, "Quad%d%d%d%d"); return id or (string.gsub(s, "^.-:%d+: ", "")):sub(1, 60) end
local function kids(p) local t = {} for _, c in p:GetChildren() do table.insert(t, c.Name .. (if mock.isDestroyed(c) then "(dead)" else "")) end return table.concat(t, ",") end
local function case(name, fn) local ok, e = pcall(fn); if not ok then print(name, "!! " .. short(e)) end end
local ident = function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Item end

-- I5: Q113 x Q76 — a :Single(st) whose State value turns cyclic while a key is gone
case("I5", function()
	local parent = Instance.new("Folder")
	local C = q.Source(F("a"))
	local s = Slot()
	s:Single(C)
	dispatch.drive(parent, { s })
	local ok, e = pcall(function() C:Set(C) end)
	print("I5", "set", if ok then "ok" else short(e), "len", s.Length:Get(), "kids", kids(parent))
	local ok2, e2 = pcall(function() C:Set(F("c")) end)
	print("   recover", if ok2 then "ok" else short(e2), "len", s.Length:Get(), "kids", kids(parent))
end)

-- I7: a throw escaping a runtime Add's attach window (materialize of a :List whose updateFn throws).
-- base: only the direct parent keeps _materializing (Quad0167 "stays unusable"); Q74 raises the whole chain.
for _, depth in { 1, 3 } do
	case("I7/depth" .. depth, function()
		local parent = Instance.new("Folder")
		local inner = Slot()
		local chain = { inner }
		local top = inner
		for d = 1, depth do top = Slot({ top }); table.insert(chain, top) end
		dispatch.drive(parent, { top })
		local bad = Slot()
		bad:List(q.Source({ 1 }), function(ctx) if ctx.Item == q.KeyGone then return nil end error("boom") end)
		local ok, e = pcall(function() inner:Add(bad) end)
		local mats = {}
		for i, sl in chain do mats[i] = tostring(sl._materializing) end
		local okT, eT = pcall(function() top:Add(F("after")) end)
		local okI, eI = pcall(function() inner:Add(F("after2")) end)
		print("I7/depth" .. depth, "add", if ok then "ok" else short(e), "mat(inner..top)", table.concat(mats, ","), "| top:Add", if okT then "ok" else short(eT), "inner:Add", if okI then "ok" else short(eI), "kids", kids(parent))
	end)
end

-- I8: same, but the throw is a Q113-rejected cyclic State element inside the attached subtree (mount-time Quad0070)
case("I8", function()
	local parent = Instance.new("Folder")
	local inner = Slot()
	local outer = Slot({ inner })
	dispatch.drive(parent, { outer })
	local C = q.Source(nil); C:Set(C)
	local sub = Slot({ C })
	local ok, e = pcall(function() inner:Add(sub) end)
	local okT, eT = pcall(function() outer:Add(F("after")) end)
	print("I8", "add", if ok then "ok" else short(e), "mat", tostring(inner._materializing), tostring(outer._materializing), "| outer:Add", if okT then "ok" else short(eT), "kids", kids(parent))
end)

-- I9: Q111 unmounted-then-mount residual (P-Q111 residual 1) with Q74: the drive-time Quad0173 leaves _materializing on
case("I9", function()
	local parent = Instance.new("Folder")
	local inner = Slot()
	local st = q.Source(nil)
	local outer = Slot({ st })
	local ok0, e0 = pcall(function() inner:Add(outer) end)
	st:Set(inner)
	local ok, e = pcall(function() dispatch.drive(parent, { outer }) end)
	local ok2, e2 = pcall(function() outer:Add(F("x")) end)
	print("I9", "pre", if ok0 then "ok" else short(e0), "drive", if ok then "ok" else short(e), "mat", tostring(inner._materializing), tostring(outer._materializing), "after", if ok2 then "ok" else short(e2))
end)
