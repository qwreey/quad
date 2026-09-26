local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch = q.Slot, q.Dispatch
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function try(label, f) local ok, e = pcall(f) print(label, ok and "ok" or ("ERR " .. tostring(e))) return ok, e end
print("--- C1 State-held element survives every discard path")
local function mk() local f = F("st"); return f, q.Source(f) end
do local f, st = mk(); local s = Slot(); s:Add(F("x")); s:Add(st); local p = Instance.new("Folder"); dispatch.drive(p, { s })
	s:Replace(2, F("y")); print("Replace: destroyed", mock.isDestroyed(f), "Parent", f.Parent)
	local s2 = Slot(); try("  re-add to other Slot", function() s2:Add(f) end) end
do local f, st = mk(); local s = Slot(); s:Add(st); local p = Instance.new("Folder"); dispatch.drive(p, { s })
	s:Clear(); print("Clear: destroyed", mock.isDestroyed(f), "Parent", f.Parent)
	try("  re-add", function() Slot():Add(f) end) end
do local f, st = mk(); local data = q.Source({ 1 }); local s = Slot()
	s:List(data, function(ctx) if ctx.Item == q.KeyGone then return nil end return st end)
	local p = Instance.new("Folder"); dispatch.drive(p, { s })
	print("List mounted f.Parent==p", f.Parent == p)
	data:Set({}); print("KeyGone(nil): destroyed", mock.isDestroyed(f), "Parent", f.Parent)
	try("  re-add", function() Slot():Add(f) end) end
do local f, st = mk(); local s = Slot(); s:Add(st); local outer = Slot(); outer:Add(s); local p = Instance.new("Folder"); dispatch.drive(p, { outer })
	outer:Extract(1); print("extracted s; f.Parent", f.Parent)
	q.dispose(s); print("dispose(slot): destroyed", mock.isDestroyed(f), "Parent", f.Parent)
	try("  re-add", function() Slot():Add(f) end) end
do local f, st = mk(); local s = Slot(); s:Add(st); local p = Instance.new("Folder"); dispatch.drive(p, { s })
	s:Remove(1); print("Remove: destroyed", mock.isDestroyed(f), "Parent", f.Parent) end
do local f, st = mk(); local s = Slot(); s:Add(st)
	s:Clear(); print("Clear before mount: destroyed", mock.isDestroyed(f)) ; try("  re-add", function() Slot():Add(f) end) end
do local f, st = mk(); local s = Slot(); s:Add(st); local p = Instance.new("Folder"); dispatch.drive(p, { s })
	s:Splice(1, 1, F("n")); print("Splice: destroyed", mock.isDestroyed(f), "Parent", f.Parent) end
do local f, st = mk(); local outer = Slot(); local s = Slot(); s:Add(st); outer:Add(s); local p = Instance.new("Folder"); dispatch.drive(p, { outer })
	outer:Remove(1); print("owner Slot destroyed by parent Remove: destroyed", mock.isDestroyed(f), "Parent", f.Parent) end

print("--- C2 Slot:Add index gates")
do local s = Slot(); s:Add(F("a"))
	try("Add idx 3 (limit 2)", function() s:Add(F("b"), 3) end)
	try("Add idx 1.5", function() s:Add(F("b"), 1.5) end)
	try("Add idx 0", function() s:Add(F("b"), 0) end)
	try("Add idx -1", function() s:Add(F("b"), -1) end)
	print("#elements", #s._elements) end

print("--- C3 WeakUnsubscribe leaves cleanup; unbindLifetime does not run cleanup")
do local cl = 0; local e = q.Effect(function() return function() cl += 1 end end); e:WeakSubscribe(); e:WeakUnsubscribe()
	print("WeakUnsubscribe cleanups", cl); e:Subscribe(); print("re-Subscribe cleanups (held replay?)", cl); e:Unsubscribe(); print("Unsubscribe cleanups", cl) end
do local cl = 0; local e = q.Effect(function() return function() cl += 1 end end); local inst = Instance.new("Frame"); dispatch.drive(inst, { e })
	q.Backend.unbindLifetime(e); print("unbindLifetime cleanups", cl); inst:Destroy(); print("after inst destroy cleanups", cl) end

print("--- C4 RunInit throws → second RunInit no-op; Store undeclared dot read")
do local calls = 0; local function bad(m) calls += 1; error("boom") end
	try("first", function() q:RunInit(bad) end); try("second", function() q:RunInit(bad) end); print("calls", calls) end
do local st = q.Store({ a = q.Source(1) }); print("undeclared read", (st :: any).zzz, "names", table.concat(st:Names(), ",")) end
do local s = Slot{}; try("empty Slot{} then :List", function() s:List({}, function() end) end) end
