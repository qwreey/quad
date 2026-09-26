--!nocheck
local H = require("./probe.e1.harness")
local q, Instance, Slot, dispatch = H.q, H.Instance, H.Slot, H.dispatch
local leaves, names, nm = H.leaves, H.names, H.nm
local mock = H.mock
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function show(label, parent) print(label, names(H.P(parent)), "viol:", table.concat(H.violations, "; "), "known:", table.concat(H.known, "; ")); table.clear(H.violations); table.clear(H.known) end
local function try(label, fn) local ok, e = pcall(fn); print(label, ok, if ok then "" else tostring(e):sub(1, 200)) return ok end

print("== T3 host destroyed while Slot mounted; then CRUD ==")
do
	local parent = Instance.new("Folder")
	local a = F("a")
	local s = Slot({ a })
	dispatch.drive(parent, { s })
	parent:Destroy()
	print("slot destroyed?", s._destroyed, "mounted", s._mounted, "a destroyed", mock.isDestroyed(a))
	try("Add after host destroy", function() s:Add(F("b")) end)
	print("elements", #s._elements, "Length", s.Length:Get())
	try("dispose(slot)", function() q.dispose(s) end)
end

print("== T4 State<Slot> swap to a Slot held elsewhere (rejected) then recover ==")
do
	local parent = Instance.new("Folder")
	local A, Bs, C = Slot({ F("A1") }), Slot({ F("B1") }), Slot({ F("C1") })
	local other = Slot({ Bs }) -- Bs held by other (unmounted)
	local holder = q.Source(A)
	dispatch.drive(parent, { "L", holder, "T" })
	show("init", parent)
	try("Set(Bs held)", function() holder:Set(Bs) end)
	show("after reject", parent)
	print("A mounted", A._mounted, "Bs mounted", Bs._mounted)
	try("Set(C)", function() holder:Set(C) end)
	show("after C", parent)
	print("C Offset", C.Offset:Get(), "C mounted", C._mounted)
	try("Set(A)", function() holder:Set(A) end)
	show("after A", parent)
end

print("== T5 Detached elements across a host change ==")
do
	local p1, p2 = Instance.new("Folder"), Instance.new("Folder")
	local frames = {}
	local data = q.Source({ 1, 2 })
	local list = Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return q.Detach, ctx.UserData end
		frames[ctx.Item] = frames[ctx.Item] or F("k" .. ctx.Item)
		return frames[ctx.Item], ctx.Item
	end, function(v) return v end)
	local h1, h2 = q.Source(list), q.Source(nil)
	dispatch.drive(p1, { h1 })
	data:Set({ 1 }) -- 2 detached
	print("detached k2 parent", frames[2].Parent, "destroyed", mock.isDestroyed(frames[2]))
	h1:Set(nil)
	try("mount on p2", function() h2:Set(list) end)
	dispatch.drive(p2, { h2 })
	show("p2", p2)
	p1:Destroy()
	print("after p1 destroyed: k2 destroyed?", mock.isDestroyed(frames[2]))
	data:Set({ 1, 2 })
	show("p2 revive", p2)
	p2:Destroy()
	print("after p2 destroyed: k1", mock.isDestroyed(frames[1]), "k2", mock.isDestroyed(frames[2]))
end

print("== T5b Detached, unmounted (not remounted), old host destroyed ==")
do
	local p1 = Instance.new("Folder")
	local frames = {}
	local data = q.Source({ 1, 2 })
	local list = Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return q.Detach, ctx.UserData end
		frames[ctx.Item] = frames[ctx.Item] or F("k" .. ctx.Item)
		return frames[ctx.Item], ctx.Item
	end, function(v) return v end)
	local h1 = q.Source(list)
	dispatch.drive(p1, { h1 })
	data:Set({ 1 })
	h1:Set(nil)
	p1:Destroy()
	print("k2 destroyed?", mock.isDestroyed(frames[2]), "k1 destroyed?", mock.isDestroyed(frames[1]), "list destroyed", list._destroyed)
	local p3 = Instance.new("Folder")
	try("remount on p3", function() dispatch.drive(p3, { list }) end)
	show("p3", p3)
	data:Set({ 1, 2 })
	show("p3 revive", p3)
end
