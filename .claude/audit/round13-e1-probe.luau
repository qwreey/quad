--!nocheck
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch

-- ── physical-order simulating backend ──
local phys = setmetatable({}, { __mode = "k" })
local violations = {}
local function P(t) local l = phys[t]; if not l then l = {}; phys[t] = l end; return l end
local function nm(e) return e and e.Name or "nil" end
local function viol(msg) table.insert(violations, msg) end
local function checkBlock(t, off, els, op)
	local l = P(t)
	for k, e in ipairs(els) do
		if l[off + k] ~= e then
			viol(`{op}: expected {nm(e)} at phys[{off + k}] got {nm(l[off + k])}`)
			return false
		end
	end
	return true
end
local known = {}
local function removeBlock(t, off, els, op)
	local l = P(t)
	local first = els[1] and table.find(l, els[1])
	if first and first - 1 ~= off then
		local contiguous = true
		for k, e in ipairs(els) do if l[first + k - 1] ~= e then contiguous = false end end
		if contiguous and op == "extract" then
			table.insert(known, `K1 stale offset {op}: passed {off}, actual {first - 1} ({nm(els[1])})`)
			for _ = 1, #els do table.remove(l, first) end
			return
		end
	end
	if not checkBlock(t, off, els, op) then
		for _, e in ipairs(els) do local i = table.find(l, e); if i then table.remove(l, i) end end
		return
	end
	for _ = 1, #els do table.remove(l, off + 1) end
end
local function insertBlock(t, off, els, op)
	local l = P(t)
	if off < 0 or off > #l then viol(`{op}: offset {off} out of [0,{#l}]`); off = math.clamp(off, 0, #l) end
	for k, e in ipairs(els) do table.insert(l, off + k, e) end
end
local B = q.Backend
B.nativeInsert = function(t, off, els) insertBlock(t, off, els, "insert"); for _, e in els do e.Parent = t end end
B.nativeExtract = function(t, off, els, new)
	removeBlock(t, off, els, "extract"); for _, e in els do e.Parent = nil end
	if new then insertBlock(t, off, new, "extract/new"); for _, e in new do e.Parent = t end end
end
B.nativeRemove = function(t, off, els, new)
	removeBlock(t, off, els, "remove"); for _, e in els do e:Destroy() end
	if new then insertBlock(t, off, new, "remove/new"); for _, e in new do e.Parent = t end end
end
B.nativeMove = function(t, fo, els, to)
	removeBlock(t, fo, els, "move"); insertBlock(t, to, els, "move/to")
end
B.nativeSwap = function(t, oa, ea, ob, eb)
	-- a before b
	local okA = checkBlock(t, oa, ea, "swapA"); local okB = checkBlock(t, ob, eb, "swapB")
	local l = P(t)
	if not (okA and okB) then return end
	local before = table.move(l, 1, oa, 1, {})
	local mid = table.move(l, oa + #ea + 1, ob, 1, {})
	local after = table.move(l, ob + #eb + 1, #l, 1, {})
	local out = {}
	for _, x in before do table.insert(out, x) end
	for _, x in eb do table.insert(out, x) end
	for _, x in mid do table.insert(out, x) end
	for _, x in ea do table.insert(out, x) end
	for _, x in after do table.insert(out, x) end
	phys[t] = out
end
local function dropEverywhere(e) for _, l in pairs(phys) do local i = table.find(l, e); if i then table.remove(l, i) end end end
B.nativeDispose = function(e) dropEverywhere(e); e:Destroy() end

-- leaf handler for string items: a Frame named by the string
q.Dispatch.addHandler({
	name = "ProbeLeaf",
	isHandlable = function(_i, k, v) return type(k) == "number" and type(v) == "string" end,
	priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
	process = function(inst, k, v, _index)
		local f = Instance.new("Frame"); f.Name = v
		q.Bookkeeping.setOffsetSource(inst, k, q.None)
		B.nativeInsert(inst, q.Bookkeeping.getOffsetAt(inst, k), { f })
		q.Bookkeeping.setLength(inst, k, 1)
		return q.Void
	end,
})

-- expected flatten
local function leaves(s, out)
	out = out or {}
	for _, e in ipairs(s._elements) do
		if q.isSlot(e) then leaves(e, out) else table.insert(out, e) end
	end
	return out
end
local function names(list) local o = {}; for i, e in ipairs(list) do o[i] = nm(e) end; return table.concat(o, ",") end

local H = { q = q, mock = mock, Instance = Instance, Slot = Slot, dispatch = dispatch, phys = phys, P = P, known = known, violations = violations, leaves = leaves, names = names, nm = nm }
-- ===== round13 E1 targeted repros (run: copy to quad-base/test/, ./scripts/relink.sh, luau quad-base/test/<file>) =====
do -- from probe.e1.t.luau
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function show(label, parent) print(label, names(H.P(parent)), "viol:", table.concat(H.violations, "; "), "known:", table.concat(H.known, "; ")); table.clear(H.violations); table.clear(H.known) end

print("== T1 minimal K1: List KeyGone Detach of a wrapper after an insert in the same cycle ==")
do
	local parent = Instance.new("Folder")
	local frames = {}
	local st = q.Source(F("k2st"))
	local data = q.Source({ { id = 1 }, { id = 2 } })
	local root = Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return q.Detach, ctx.UserData end
		local id = ctx.Item.id
		if id == 2 then return st, id end
		frames[id] = frames[id] or F("k" .. id)
		return frames[id], id
	end, function(it) return it.id end)
	dispatch.drive(parent, { "L", root, "T" })
	show("before", parent)
	data:Set({ { id = 3 }, { id = 1 } })
	show("after ", parent)
end

print("== T1b same with a plain user Slot element, OwnsElements=false, nil on KeyGone ==")
do
	local parent = Instance.new("Folder")
	local frames = {}
	local sub = Slot({ F("s1"), F("s2") })
	local data = q.Source({ { id = 1 }, { id = 2 } })
	local root = Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil, ctx.UserData end
		local id = ctx.Item.id
		if id == 2 then return sub, id end
		frames[id] = frames[id] or F("k" .. id)
		return frames[id], id
	end, function(it) return it.id end, { OwnsElements = false })
	dispatch.drive(parent, { "L", root, "T" })
	show("before", parent)
	data:Set({ { id = 3 }, { id = 1 } })
	show("after ", parent)
end

print("== T2 updateFn mutates ctx.Prev row Slot while an earlier row was inserted this cycle ==")
do
	local parent = Instance.new("Folder")
	local rows = {}
	local data = q.Source({ { id = 1, n = 1 } })
	local root = Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		local it = ctx.Item
		local row = ctx.Prev
		if row == nil then
			row = Slot()
			rows[it.id] = row
		end
		while #row._elements < it.n do row:Add(F(`r{it.id}_{#row._elements + 1}`)) end
		return row
	end, function(it) return it.id end)
	local ok, err = pcall(dispatch.drive, parent, { "L", root, "T" })
	print("drive ok", ok, err)
	show("before", parent)
	local ok2, err2 = pcall(function() data:Set({ { id = 0, n = 2 }, { id = 1, n = 2 } }) end)
	print("set ok", ok2, err2)
	show("after ", parent)
	print("row1 Offset", rows[1].Offset:Get(), "Length root", root.Length:Get())
end
end
do -- from probe.e1.t3.luau
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function try(label, fn) local ok, e = pcall(fn); print(label, ok, if ok then "" else tostring(e):sub(1, 220)) return ok end

print("== T6 grandparent CRUD from an Observer fired inside a runtime Add's attach window ==")
do
	local parent = Instance.new("Folder")
	local inner = Slot()
	local outer = Slot({ inner })
	dispatch.drive(parent, { outer })
	local fired = false
	inner.Length:Observer(function()
		if inner.Length:Get() > 0 and not fired then
			fired = true
			try("  observer: outer:Remove(1)", function() outer:Remove(1) end)
		end
	end):Subscribe()
	local f = F("leaf")
	local sub = Slot({ f })
	try("inner:Add(sub)", function() inner:Add(sub) end)
	print("inner destroyed", inner._destroyed, "sub destroyed", sub._destroyed, "sub _mounted", sub._mounted)
	print("f destroyed", mock.isDestroyed(f), "f.Parent == parent", f.Parent == parent, "#children", #parent:GetChildren())
	print("outer Length", outer.Length:Get(), "#outer._elements", #outer._elements)
end

print("== T6b same, direct parent (control — Q52 guard) ==")
do
	local parent = Instance.new("Folder")
	local inner = Slot()
	local outer = Slot({ inner })
	dispatch.drive(parent, { outer })
	local fired = false
	inner.Length:Observer(function()
		if inner.Length:Get() > 0 and not fired then
			fired = true
			try("  observer: inner:Clear()", function() inner:Clear() end)
		end
	end):Subscribe()
	local sub = Slot({ F("leaf") })
	try("inner:Add(sub)", function() inner:Add(sub) end)
end

print("== T6c grandparent CRUD from the recompute of a plain-leaf Add (no attach window) ==")
do
	local parent = Instance.new("Folder")
	local inner = Slot()
	local outer = Slot({ inner, Slot({ F("sib") }) })
	dispatch.drive(parent, { outer })
	local fired = false
	inner.Length:Observer(function()
		if inner.Length:Get() > 0 and not fired then
			fired = true
			try("  observer: outer:Remove(1)", function() outer:Remove(1) end)
		end
	end):Subscribe()
	local f = F("leaf")
	try("inner:Add(f)", function() inner:Add(f) end)
	print("f destroyed", mock.isDestroyed(f), "f.Parent", f.Parent, "outer Length", outer.Length:Get(), "#children", #parent:GetChildren())
end
end
do -- from probe.e1.t5.luau
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function leaves(s, out) out = out or {}; for _, e in ipairs(s._elements) do if q.isSlot(e) then leaves(e, out) else table.insert(out, e) end end; return out end

local parent = Instance.new("Folder")
local S1 = Slot()
local S22 = Slot()
local R2 = Slot({ S22, F("f58") })
dispatch.drive(parent, { F and "x" == "y" or S1, R2 })
local S14 = Slot()
local S12 = Slot({ S14, F("f36") })
local fired = false
S22.Offset:Observer(function()
	if not fired and S22.Offset:Get() > 0 then
		fired = true
		print("  observer fires: S12 mounted?", S12._mounted, "S14 mounted?", S14._mounted, "S1 materializing", S1._materializing)
		local bk1 = q.Bookkeeping.getBookkeeping(S1)
		print("  S1 recomputeBlocker", bk1.recomputeBlocker.Blocking, "S1 batch", q.Bookkeeping.getBlocker(S1).Blocking, "S12 batch", q.Bookkeeping.getBlocker(S12).Blocking, "S12 rb", q.Bookkeeping.getBookkeeping(S12).recomputeBlocker.Blocking)
		print("  S1 bk.N", bk1.N, "lengthList[1] is S12.Length", bk1.lengthList[1] == S12.Length, "lengthList[1]", tostring(bk1.lengthList[1]))
		S14:Add(F("new"))
		print("  after inner add: S12.Length", S12.Length:Get(), "S1.Length", S1.Length:Get())
	end
end):Subscribe()
S1:Add(S12, 1)
print("fired", fired)
print("S1.Length", S1.Length:Get(), "leaves", #leaves(S1), "S12.Length", S12.Length:Get(), "S14.Length", S14.Length:Get())
print("R2.Offset", R2.Offset:Get(), "expected", #leaves(S1))
local names = {}
for _, c in parent:GetChildren() do table.insert(names, c.Name) end
print("children", table.concat(names, ","))
-- does a later unrelated CRUD heal it?
S14:Add(F("new2"))
print("after heal attempt: S1.Length", S1.Length:Get(), "leaves", #leaves(S1), "R2.Offset", R2.Offset:Get())
end
do -- from probe.e1.t6.luau
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function leaves(s, out) out = out or {}; for _, e in ipairs(s._elements) do if q.isSlot(e) then leaves(e, out) else table.insert(out, e) end end; return out end

print("== T7 top-level: State<Slot> set at runtime, sibling Offset observer CRUDs a child of the new Slot ==")
do
	local parent = Instance.new("Folder")
	local child = Slot()
	local R = Slot({ child, F("r") })
	local R2 = Slot({ F("z") })
	local holder = q.Source(nil)
	dispatch.drive(parent, { holder, R2 })
	local fired = false
	R2.Offset:Observer(function()
		if not fired and R2.Offset:Get() > 0 then fired = true; child:Add(F("new")) end
	end):Subscribe()
	holder:Set(R)
	print("fired", fired, "R.Length", R.Length:Get(), "leaves", #leaves(R), "R2.Offset", R2.Offset:Get(), "(expected", #leaves(R), ")")
end

print("== T8 no Slot-in-Slot: user Observer on sibling Offset Adds to the Slot just mounted (top-level) ==")
do
	local parent = Instance.new("Folder")
	local R = Slot({ F("r") })
	local R2 = Slot({ F("z") })
	local holder = q.Source(nil)
	dispatch.drive(parent, { holder, R2 })
	local fired = false
	R2.Offset:Observer(function()
		if not fired and R2.Offset:Get() > 0 then fired = true; local ok, e = pcall(function() R:Add(F("new")) end); print("  R:Add", ok, e and tostring(e):sub(1, 90)) end
	end):Subscribe()
	holder:Set(R)
	print("fired", fired, "R.Length", R.Length:Get(), "leaves", #leaves(R), "R2.Offset", R2.Offset:Get(), "(expected", #leaves(R), ")")
end
end
