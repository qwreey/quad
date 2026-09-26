--!nocheck
local H = require("./probe.e1.harness")
local q, Instance, Slot, dispatch = H.q, H.Instance, H.Slot, H.dispatch
local mock = H.mock
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function try(label, fn) local ok, e = pcall(fn); print(label, ok, if ok then "" else tostring(e):sub(1, 160)) return ok end
local function show(label, p) print(label, H.names(H.P(p)), "viol:", table.concat(H.violations, "; "), "known:", table.concat(H.known, "; ")); table.clear(H.violations); table.clear(H.known) end

print("== T10 State<Slot> as a Slot element ==")
do
	local parent = Instance.new("Folder")
	local A, B = Slot({ F("a1"), F("a2") }), Slot({ F("b1") })
	local st = q.Source(A)
	local outer = Slot({ F("x"), st, F("y") })
	dispatch.drive(parent, { outer })
	show("A", parent)
	st:Set(B); show("B", parent)
	print("A mounted", A._mounted, "A destroyed", A._destroyed, "outer.Length", outer.Length:Get())
	st:Set(nil); show("nil", parent)
	st:Set(A); show("A again", parent)
	print("outer.Length", outer.Length:Get())
	local got = outer:Extract(2)
	print("extracted is st", got == st)
	show("after extract", parent)
	local other = Slot()
	try("other:Add(A) after wrapper left", function() other:Add(A) end)
	try("other2:Add(B)", function() Slot():Add(B) end)
end

print("== T11 claimOwnerAt vs Slot:Add symmetry ==")
do
	local host = Instance.new("Folder")
	local f = F("f")
	q.Bookkeeping.claimOwnerAt(f, host, 1)
	try("Slot:Add(claimed-at-seat f)", function() Slot():Add(f) end)
	local g = F("g")
	local s = Slot({ g })
	try("claimOwnerAt(g in Slot)", function() q.Bookkeeping.claimOwnerAt(g, host, 2) end)
	try("dispose(f seated)", function() q.dispose(f) end)
end

print("== T12 :List updateFn returns the same Frame for two keys ==")
do
	local parent = Instance.new("Folder")
	local shared = F("shared")
	local data = q.Source({ 1 })
	local list = Slot():List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return shared end)
	dispatch.drive(parent, { list, "T" })
	try("Set {1,2}", function() data:Set({ 1, 2 }) end)
	print("blocker left on?", q.Bookkeeping.getBlocker(list).Blocking, "#elements", #list._elements, "Length", list.Length:Get())
	try("Set {1}", function() data:Set({ 1 }) end)
	print("after: Length", list.Length:Get(), "#elements", #list._elements)
end
