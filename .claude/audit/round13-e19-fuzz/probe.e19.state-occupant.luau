--!nocheck
-- E19 probes around State elements (wrapper Slots) and :Single slots that the fuzzer surfaced.
local mock = require("./mock")
local Instance = mock.Instance
local function env()
	local q = mock.newQuad()
	return q
end
local function F(n) local f = Instance.new("Frame"); f.Name = n or "f"; return f end
local function tryp(label, fn)
	local ok, err = pcall(fn)
	local e = tostring(err)
	print(`  {label}: {if ok then "ok" else (string.match(e, "Quad%d%d%d%d") or e) .. " blame=" .. (string.match(e, "^[^:]+:(%d+):") or "?")}`)
	return ok
end

print("P1 — State element value changed while its Slot is UNMOUNTED: the old occupant stays claimed until remount")
do
	local q = env()
	local host = Instance.new("Folder")
	local A, B = F("A"), F("B")
	local st = q.Source(A)
	local root = q.Slot({ st })
	local holder = q.Source(root)
	q.Dispatch.drive(host, { holder })
	print("  mounted: A.Parent=host?", A.Parent == host)
	holder:Set(nil)
	st:Set(B)
	print("  after unmount + st:Set(B): A owner is wrapper?", q._probeOwner:GetWeak(A, "__owner") == root._elements[1])
	tryp("other:Add(A)", function() q.Slot():Add(A) end)
	tryp("q.dispose(A)", function() q.dispose(A) end)
	holder:Set(root)
	print("  after remount: A owner=", q._probeOwner:GetWeak(A, "__owner"), " B.Parent=host?", B.Parent == host, " A.Parent=", A.Parent)
	tryp("q.dispose(A) after remount", function() q.dispose(A) end)
end
do
	local q = env()
	local A, B = F("A"), F("B")
	local st = q.Source(A)
	local root = q.Slot({ st }) -- never mounted
	st:Set(B)
	tryp("never-mounted: q.dispose(A)", function() q.dispose(A) end)
end
print("P1b — same for a user :Single(src) with OwnsElements=false, data changed while unmounted")
do
	local q = env()
	local host = Instance.new("Folder")
	local src = q.Source("a")
	local made = {}
	local ss = q.Slot():Single(src, function(ctx) if ctx.Item == q.KeyGone then return nil end; if ctx.Prev and ctx.Prev.Name == ctx.Item then return ctx.Prev end; local f = F(ctx.Item); made[ctx.Item] = f; return f end, { OwnsElements = false })
	local holder = q.Source(ss)
	q.Dispatch.drive(host, { holder })
	holder:Set(nil)
	src:Set("b")
	tryp("q.dispose(old 'a' element) while unmounted", function() q.dispose(made.a) end)
	holder:Set(ss)
	tryp("q.dispose(old 'a' element) after remount", function() q.dispose(made.a) end)
end

print("P2 — remount materializes the STALE occupant subtree before the catch-up swap")
do
	local q = env()
	local host = Instance.new("Folder")
	local calls = 0
	local src = q.Source("x")
	local innerSingle = q.Slot():Single(src, function(ctx) calls += 1; if ctx.Item == q.KeyGone then return nil end; return F("inner-" .. ctx.Item) end)
	local oldOcc = q.Slot({ F("old1"), innerSingle })
	local st = q.Source(oldOcc)
	local root = q.Slot({ st })
	local holder = q.Source(nil) -- never mounted before...
	q.Dispatch.drive(host, { holder })
	holder:Set(root); holder:Set(nil)
	print("  first mount: innerSingle updateFn calls =", calls)
	-- now make innerSingle's parent leave the State while unmounted
	local parents = {}
	local old1 = oldOcc:Get(1)
	old1:GetPropertyChangedSignal("Parent"):Connect(function() table.insert(parents, tostring(old1.Parent)) end)
	st:Set(F("new"))
	holder:Set(root)
	print("  after remount: innerSingle calls =", calls, " old1 Parent changes during remount =", table.concat(parents, ","), " final old1.Parent =", old1.Parent)
end
do
	local q = env()
	local host = Instance.new("Folder")
	local calls = 0
	local src = q.Source("x")
	local innerSingle = q.Slot():Single(src, function(ctx) calls += 1; if ctx.Item == q.KeyGone then return nil end; return F("inner-" .. ctx.Item) end)
	local oldOcc = q.Slot({ innerSingle })
	local st = q.Source(nil)
	local root = q.Slot({ st })
	local holder = q.Source(root)
	q.Dispatch.drive(host, { holder }) -- wrapper activated with nil
	holder:Set(nil)
	st:Set(oldOcc)   -- set while unmounted (pending)
	st:Set(F("final")) -- and moved on again
	holder:Set(root)
	print("  pending nil->Slot->leaf, remount: innerSingle updateFn calls =", calls, "(0 = the intermediate Slot never mounted)")
end

do
	local q = env()
	local host = Instance.new("Folder")
	local calls = 0
	local oldOcc = q.Slot({ F("old1") })
	local st = q.Source(oldOcc)
	local root = q.Slot({ st })
	local holder = q.Source(root)
	q.Dispatch.drive(host, { holder })
	holder:Set(nil)
	st:Set(F("new"))                    -- oldOcc is leaving
	local src = q.Source("x")
	local fresh = q.Slot():Single(src, function(ctx) calls += 1; if ctx.Item == q.KeyGone then return nil end; return F("inner-" .. ctx.Item) end)
	oldOcc:Add(fresh)                   -- a never-mounted :Single inside the leaving occupant
	holder:Set(root)
	print("  fresh :Single inside the stale occupant — updateFn calls at remount =", calls, " its element =", fresh._elements[1], " parented? ", fresh._elements[1] and fresh._elements[1].Parent)
	print("  oldOcc Length/Offset after remount =", oldOcc.Length:Get(), oldOcc.Offset:Get(), " (it is no longer in the tree)")
end

print("P3 — a State element set to an already-held value while MOUNTED (reconcile-depth raise), then recovery")
do
	local q = env()
	local host = Instance.new("Folder")
	local held = F("held")
	local other = q.Slot({ held })
	local st = q.Source(F("a"))
	local root = q.Slot({ st, F("tail") })
	q.Dispatch.drive(host, { root, other })
	tryp("st:Set(held)", function() st:Set(held) end)
	local w = root._elements[1]
	print(`  after raise: wrapper elements={#w._elements} wrapper.Length={w.Length:Get()} root.Length={root.Length:Get()} wrapper blocker on? {q.Bookkeeping.getBlocker(w).Blocking}`)
	local fresh = F("fresh")
	tryp("st:Set(fresh) (recover?)", function() st:Set(fresh) end)
	print(`  after: wrapper elements={#w._elements} wrapper.Length={w.Length:Get()} root.Length={root.Length:Get()} fresh.Parent=host? {fresh.Parent == host}`)
	root:Add(F("more"))
	print(`  root:Add after: root.Length={root.Length:Get()} (model 3)`)
	tryp("st:Set(nil)", function() st:Set(nil) end)
	print(`  after Set(nil): wrapper elements={#w._elements} wrapper.Length={w.Length:Get()} (model 0) root.Length={root.Length:Get()} (model 2) tail Parent=host? {root:Get(2).Parent == host}`)
	tryp("st:Set(F('again'))", function() st:Set(F("again")) end)
	print(`  after Set(again): wrapper.Length={w.Length:Get()} (model 1) root.Length={root.Length:Get()} (model 3)`)
end

print("P4 — the same nil State placed twice (pre-pass sees no occupant), then Set")
do
	local q = env()
	local host = Instance.new("Folder")
	local st = q.Source(nil)
	local s1, s2 = q.Slot(), q.Slot()
	tryp("s1:Add(st)", function() s1:Add(st) end)
	tryp("s2:Add(st) (same State, second seat)", function() s2:Add(st) end)
	q.Dispatch.drive(host, { s1, s2 })
	local g = F("g")
	tryp("st:Set(g)", function() st:Set(g) end)
	local w1, w2 = s1._elements[1], s2._elements[1]
	print(`  g owner: w1={q._probeOwner:GetWeak(g, "__owner") == w1} w2={q._probeOwner:GetWeak(g, "__owner") == w2}; s1.Length={s1.Length:Get()} s2.Length={s2.Length:Get()} blockers w1={q.Bookkeeping.getBlocker(w1).Blocking} w2={q.Bookkeeping.getBlocker(w2).Blocking}`)
	tryp("st:Set(F()) again", function() st:Set(F("h")) end)
	print(`  s1.Length={s1.Length:Get()} s2.Length={s2.Length:Get()}`)
end

print("P5 — element destroyed outside quad while seated, then Extract and reuse")
do
	local q = env()
	local host = Instance.new("Folder")
	local a = F("a")
	local s = q.Slot({ a, F("b") })
	q.Dispatch.drive(host, { s })
	a:Destroy()
	local x
	tryp("s:Extract(1)", function() x = s:Extract(1) end)
	tryp("q.Slot():Add(extracted corpse)", function() q.Slot():Add(x) end)
	print(`  s.Length={s.Length:Get()} len={#s._elements}`)
end

print("P6 — cycle via State link: what the mount-time raise leaves behind")
do
	local q = env()
	local outer = q.Slot()
	local st = q.Source(nil)
	outer:Add(st)
	local inner = q.Slot({ F("i1") })
	st:Set(inner)
	tryp("inner:Add(outer)", function() inner:Add(outer) end)
	local host = Instance.new("Folder")
	tryp("drive(host, {inner})", function() q.Dispatch.drive(host, { inner }) end)
	print(`  inner owner=host? {q._probeOwner:GetWeak(inner, "__owner") == host}; outer materializing? {outer._materializing}; inner materializing? {inner._materializing}; host children={#host:GetChildren()}`)
	tryp("inner:Add(F()) afterwards", function() inner:Add(F("late")) end)
	tryp("outer:Remove(1) afterwards", function() outer:Remove(1) end)
end
