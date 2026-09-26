--!nocheck
-- E51 separate axes (a)~(g). luau axes.luau
local H = require("./harness")
local mock, Instance = H.mock, H.Instance
local function newQ() local log = {} return H.newQ(log), log end
local function attrs(inst) local a = mock.getAttributes(inst) local t = {} for k, v in a do table.insert(t, k .. "=" .. tostring(v)) end table.sort(t) return table.concat(t, ",") end
local function tags(inst) return table.concat(mock.getTags(inst), ",") end
local function try(f) local ok, e = pcall(f) return ok and "ok" or H.idOf(e) end

print("== (a) one name dropped by two positions in one wave")
do
	local q, log = newQ()
	local inst = Instance.new("Frame")
	local s = q.Source(q.Tag("a", "b"))
	q.Dispatch.drive(inst, { s, s }) -- same Source at two positions
	print(" a1 drive:", table.concat(log, " | ")) table.clear(log)
	s:Set(q.Tag("b"))
	print(" a1 Set{b} (a leaves both):", table.concat(log, " | ")) table.clear(log)
	s:Set(nil)
	print(" a1 Set nil:", table.concat(log, " | "), "tags=", tags(inst)) table.clear(log)
	-- derived: two Computes of one Source
	local c = q.Source(1)
	local d1 = c:Compute(function(v) return if v:Get() == 1 then q.Tag("x") else q.Tag() end)
	local d2 = c:Compute(function(v) return if v:Get() == 1 then q.Tag("x", "y") else nil end)
	local i2 = Instance.new("Frame")
	q.Dispatch.drive(i2, { d1, d2 })
	print(" a2 drive:", table.concat(log, " | ")) table.clear(log)
	c:Set(2)
	print(" a2 wave (x leaves both):", table.concat(log, " | "), "tags=", tags(i2)) table.clear(log)
	-- Blocker-held wave
	local b = q.Blocker()
	local g = c:Apply(b)
	local e1 = g:Compute(function(v) return if v:Get() == 1 then q.Tag("z") else nil end)
	local e2 = g:Compute(function(v) return if v:Get() == 1 then q.Tag("z") else nil end)
	local ok = pcall(function()
		c:Set(1)
		local i3 = Instance.new("Frame")
		q.Dispatch.drive(i3, { e1, e2 }) table.clear(log)
		b:On() c:Set(2) b:Off()
		print(" a3 gated wave:", table.concat(log, " | "), "tags=", tags(i3)) table.clear(log)
	end)
	if not ok then print(" a3 skipped (Gate/Blocker surface)") end
end

print("== (b) Destroy: removeTag/setAttr on destroy?")
do
	local q, log = newQ()
	local inst = Instance.new("Frame")
	q.Dispatch.drive(inst, { q.Tag("a"), q.Attr({ X = 1 }), [q.AttrKey("Y")] = 2 }) table.clear(log)
	inst:Destroy()
	print(" b1 destroy calls:", #log, table.concat(log, " | "))
	-- child destroyed via parent's Slot removal
	local parent = Instance.new("Frame")
	local slot = q.Slot()
	q.Dispatch.drive(parent, { slot })
	local child = Instance.new("Frame")
	q.Dispatch.drive(child, { q.Tag("c") }) table.clear(log)
	slot:Add(child)
	print(" b2 Add calls:", table.concat(log, " | "))
	slot:Remove(1)
	print(" b2 Remove (dispose) calls:", #log, table.concat(log, " | "), "destroyed=", mock.isDestroyed(child))
end

print("== (c) Quad0002 rejection leaves the original owner untouched")
do
	local q, log = newQ()
	local inst = Instance.new("Frame")
	local A = q.Source(q.Attr({ X = 1 }))
	local B = q.Source(nil)
	local hk = q.Source(5)
	q.Dispatch.drive(inst, { A, B, [q.AttrKey("H")] = hk }) table.clear(log)
	print(" c1 B<-{X} :", try(function() B:Set(q.Attr({ X = 2 })) end), "attrs=", attrs(inst), "log=", table.concat(log, " | ")) table.clear(log)
	A:Set(q.Attr({ X = 3 })) print(" c1 owner A still writes:", table.concat(log, " | ")) table.clear(log)
	print(" c2 B<-{H} (hash owner):", try(function() B:Set(q.Attr({ H = 9 })) end), "attrs=", attrs(inst)) table.clear(log)
	hk:Set(6) print(" c2 hash owner still writes:", table.concat(log, " | ")) table.clear(log)
	-- after A releases X, can B (whose earlier attempts failed) take X?
	A:Set(nil)
	print(" c3 A released; B<-{X}:", try(function() B:Set(q.Attr({ X = 4 })) end), "attrs=", attrs(inst)) table.clear(log)
	-- partial: group whose pairs order delegates K before colliding on X
	local C = q.Source(nil)
	local i2 = Instance.new("Frame")
	local sK = q.Source(1)
	q.Dispatch.drive(i2, { q.Attr({ X = 1 }), C }) table.clear(log)
	local g = { X = 2 } for _, n in { "a", "b", "c", "d", "e", "f" } do g[n] = n == "a" and sK or 2 end
	print(" c4 partial group collide:", try(function() C:Set(q.Attr(g)) end), "writes=", table.concat(log, " | ")) table.clear(log)
	C:Set(nil)
	sK:Set(42)
	print(" c4 after C:Set(nil), inner sK:Set(42) writes:", table.concat(log, " | "), "(zombie subscription — H-684)") table.clear(log)
	print(" c4 another owner takes 'b':", try(function() q.Dispatch.drive(i2, { [3] = q.Attr({ b = 1 }) }) end))
end

print("== (d) AttrKey vs group — who was placed first")
do
	local q, log = newQ()
	local i1 = Instance.new("Frame")
	print(" d1 literal { [AttrKey X]=1, Attr{X=2} } :", try(function() q.Dispatch.drive(i1, { [q.AttrKey("X")] = 1, q.Attr({ X = 2 }) }) end), "attrs=", attrs(i1))
	local i2 = Instance.new("Frame")
	print(" d2 literal { Attr{X=2}, [AttrKey X]=1 } :", try(function() q.Dispatch.drive(i2, { q.Attr({ X = 2 }), [q.AttrKey("X")] = 1 }) end), "attrs=", attrs(i2))
	-- reactive: AttrKey owns first, group arrives later
	local i3 = Instance.new("Frame")
	local G = q.Source(nil)
	q.Dispatch.drive(i3, { G, [q.AttrKey("X")] = 1 })
	print(" d3 AttrKey first, then group:", try(function() G:Set(q.Attr({ X = 2 })) end), "attrs=", attrs(i3))
	-- reactive: group owns, AttrKey value State re-emits (AttrKey placed at drive after group) — AttrKey lost at drive
	local i4 = Instance.new("Frame")
	local G2 = q.Source(q.Attr({ X = 2 }))
	local hk = q.Source(nil)
	print(" d4 drive { State<Attr{X}>, [AttrKey X]=State(nil) }:", try(function() q.Dispatch.drive(i4, { G2, [q.AttrKey("X")] = hk }) end), "attrs=", attrs(i4))
	-- two separate drives on one instance: hash first, array later
	local i5 = Instance.new("Frame")
	q.Dispatch.drive(i5, { [q.AttrKey("X")] = 1 })
	print(" d5 second drive adds group:", try(function() q.Dispatch.drive(i5, { q.Attr({ X = 2 }) }) end), "attrs=", attrs(i5))
	-- Overridden / StringAttr vs group
	local i6 = Instance.new("Frame")
	print(" d6 { NumberAttr X, Attr{X} }:", try(function() q.Dispatch.drive(i6, { q.NumberAttr("X", 1), q.Attr({ X = 2 }) }) end), "attrs=", attrs(i6))
	local i7 = Instance.new("Frame")
	print(" d7 Overridden(Attr{X=1},Attr{X=2}) single:", try(function() q.Dispatch.drive(i7, { q.Attr.Overridden(q.Attr({ X = 1 }), q.Attr({ X = 2 })) }) end), "attrs=", attrs(i7))
	print(" d8 Merged overlap:", try(function() q.Attr.Merged(q.Attr({ X = 1 }), q.Attr({ X = 2 })) end))
	print(" d9 Tag.Merged overlap (brief premise 'rejection'):", try(function() return q.Tag.Merged(q.Tag("a"), q.Tag("a", "b")) end))
end

print("== (e) Tag/Attr name edge cases (quad gates; engine rules not modeled)")
do
	local q, log = newQ()
	for _, n in { "", " ", "a b", "RBXfoo", "RBX", string.rep("x", 101), "한글", "a\0b" } do
		local inst = Instance.new("Frame")
		local rt = try(function() q.Dispatch.drive(inst, { q.Tag(n) }) end)
		local i2 = Instance.new("Frame")
		local ra = try(function() q.Dispatch.drive(i2, { q.Attr({ [n] = 1 }) }) end)
		local i3 = Instance.new("Frame")
		local rk = try(function() q.Dispatch.drive(i3, { [q.AttrKey(n)] = 1 }) end)
		print(string.format(" name=%q(len %d): Tag %s / Attr %s / AttrKey %s", #n > 20 and (n:sub(1, 8) .. "…") or n, #n, rt, ra, rk))
	end
end

print("== (f) perf: 1000 tag names")
do
	local q, log = newQ()
	local names = {} for i = 1, 1000 do names[i] = "t" .. i end
	local half = {} for i = 1, 1000 do half[i] = "t" .. (i + 500) end
	local inst = Instance.new("Frame")
	local s = q.Source(q.Tag(names))
	local t0 = os.clock()
	q.Dispatch.drive(inst, { s, q.Tag(names) })
	local t1 = os.clock()
	s:Set(q.Tag(half)) -- 500 leave position 1 but position 2 still holds them → no removeTag; 500 new
	local t2 = os.clock()
	s:Set(nil)
	local t3 = os.clock()
	local calls = {} for _, l in log do table.insert(calls, (l:match("^(%a+)")) .. "(" .. #string.split(l, ",") .. ")") end
	print(string.format(" drive 2x1000 %.2fms; shift-by-500 %.2fms; retract %.2fms; engine calls: %s", (t1 - t0) * 1e3, (t2 - t1) * 1e3, (t3 - t2) * 1e3, table.concat(calls, " ")))
	print(" final tag count:", #mock.getTags(inst))
end

print("== (g) Slot: Tag-bearing element moved between slots / replaced")
do
	local q, log = newQ()
	local p = Instance.new("Frame")
	local s1, s2 = q.Slot(), q.Slot()
	q.Dispatch.drive(p, { s1, s2 })
	local el = Instance.new("Frame")
	local ts = q.Source(q.Tag("e"))
	q.Dispatch.drive(el, { ts, q.Tag("e", "f") }) table.clear(log)
	s1:Add(el)
	local x = s1:Extract(1)
	print(" g1 Extract returned el:", x == el, "calls:", table.concat(log, " | "), "tags=", tags(el))
	s2:Add(el)
	print(" g1 Add to s2 calls:", table.concat(log, " | "), "tags=", tags(el)) table.clear(log)
	ts:Set(nil)
	print(" g1 element's own State still counts (f,e held by pos2):", table.concat(log, " | "), "tags=", tags(el)) table.clear(log)
	local el2 = Instance.new("Frame")
	q.Dispatch.drive(el2, { q.Tag("e") }) table.clear(log)
	s2:Replace(1, el2)
	print(" g2 Replace calls:", table.concat(log, " | "), "old destroyed=", mock.isDestroyed(el), "old tags(mock corpse)=", tags(el))
end
