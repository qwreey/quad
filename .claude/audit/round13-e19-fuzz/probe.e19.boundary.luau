--!nocheck
-- E19 boundary probes: inputs the contract calls errors/UB, kept OUT of the fuzzer.
-- Each case prints: label | error ID (or "no error") | blame line (the `:NN:` prefix) | expected user line.
-- Run like the fuzzer (scratch copy with HOOKS.txt): luau test/probe.e19.boundary.luau
local mock = require("./mock")
local Instance = mock.Instance
local function env()
	local q = mock.newQuad()
	q.Dispatch.addHandler({ name = "ProbeLeaf", isHandlable = function(_i, k, v) return type(k) == "number" and type(v) == "string" end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst, k, v) local f = Instance.new("Frame"); f.Name = v; q.Bookkeeping.setOffsetSource(inst, k, q.None); q.Backend.nativeInsert(inst, q.Bookkeeping.getOffsetAt(inst, k), { f }); q.Bookkeeping.setLength(inst, k, 1); return q.Void end })
	return q
end
local function F(n) local f = Instance.new("Frame"); f.Name = n or "f"; return f end
local function row(label, line, fn)
	local ok, err = pcall(fn)
	local e = tostring(err)
	local id = if ok then "no error" else (string.match(e, "Quad%d%d%d%d") or ("raw: " .. string.sub(e, 1, 80)))
	local bl = if ok then "-" else (string.match(e, "^[^:]+:(%d+):") or "?")
	print(`B | {label} | {id} | blame={bl} | user={line}`)
	return ok, err
end
local L = debug.info(1, "l")
local function here() return debug.info(2, "l") end

-- ── index domain (every index-taking op) ──
do
	local q = env()
	local s = q.Slot({ F(), F(), F() })
	local ln
	ln = here(); row("Add idx 0", ln, function() s:Add(F(), 0) end)
	ln = here(); row("Add idx n+2", ln, function() s:Add(F(), 5) end)
	ln = here(); row("Add idx 1.5", ln, function() s:Add(F(), 1.5) end)
	ln = here(); row("Add idx NaN", ln, function() s:Add(F(), 0/0) end)
	ln = here(); row("Add idx math.huge", ln, function() s:Add(F(), math.huge) end)
	ln = here(); row("Add idx '1'", ln, function() s:Add(F(), "1") end)
	ln = here(); row("Remove idx n+1", ln, function() s:Remove(4) end)
	ln = here(); row("Remove idx 0", ln, function() s:Remove(0) end)
	ln = here(); row("Remove idx nil", ln, function() s:Remove(nil) end)
	ln = here(); row("Replace idx n+1", ln, function() s:Replace(4, F()) end)
	ln = here(); row("Extract idx n+1", ln, function() s:Extract(4) end)
	ln = here(); row("Extract idx -1", ln, function() s:Extract(-1) end)
	ln = here(); row("Move to n+1", ln, function() s:Move(1, 4) end)
	ln = here(); row("Move from 0", ln, function() s:Move(0, 1) end)
	ln = here(); row("Swap b n+1", ln, function() s:Swap(1, 4) end)
	ln = here(); row("Splice idx n+2", ln, function() s:Splice(5, 0) end)
	ln = here(); row("Splice rc past end", ln, function() s:Splice(2, 3) end)
	ln = here(); row("Splice rc -1", ln, function() s:Splice(1, -1) end)
	ln = here(); row("Splice rc 1.5", ln, function() s:Splice(1, 1.5) end)
	ln = here(); row("Splice rc nil", ln, function() s:Splice(1, nil) end)
	ln = here(); row("Splice idx n+1 rc 0 (end insert)", ln, function() s:Splice(4, 0, F()) end)
	ln = here(); row("Get idx 99 (nil ok)", ln, function() assert(s:Get(99) == nil) end)
	ln = here(); row("Get idx 'x'", ln, function() s:Get("x") end)
	ln = here(); row("Get idx 1.5 (nil?)", ln, function() print("   Get(1.5) ->", s:Get(1.5)) end)
	print(`   state after index probes: len={#s._elements} (4 = only the end-insert Splice succeeded)`)
end

-- ── dead elements ──
do
	local q = env()
	local s = q.Slot()
	local dead = F("dead"); dead:Destroy()
	local ln
	ln = here(); row("Add destroyed Instance", ln, function() s:Add(dead) end)
	local ds = q.Slot(); q.dispose(ds)
	ln = here(); row("Add destroyed Slot", ln, function() s:Add(ds) end)
	ln = here(); row("Add State holding destroyed Slot", ln, function() s:Add(q.Source(ds)) end)
	ln = here(); row("Add State holding destroyed Instance", ln, function() s:Add(q.Source(dead)) end)
	ln = here(); row("CRUD on destroyed Slot", ln, function() ds:Add(F()) end)
	ln = here(); row("Move on destroyed Slot", ln, function() ds:Move(1, 1) end)
	ln = here(); row("Get on destroyed Slot", ln, function() print("   ds:Get(1) ->", ds:Get(1)) end)
	ln = here(); row("Splice with destroyed in the middle", ln, function() s:Splice(1, 0, F("x1"), dead, F("x2")) end)
	print(`   after: len={#s._elements} (pre-pass: expect 0)`)
	-- element destroyed outside quad while seated (host mounted)
	local host = Instance.new("Folder")
	local s2 = q.Slot({ F("a"), F("b") })
	q.Dispatch.drive(host, { "L", s2, "T" })
	local a = s2:Get(1)
	a:Destroy()
	ln = here(); row("Remove element destroyed outside quad", ln, function() s2:Remove(1) end)
	ln = here(); row("Extract element destroyed outside quad (then reuse)", ln, function() local x = s2:Extract(1); q.Slot():Add(x) end)
	local ob = F("ob"); local s3 = q.Slot({ ob }); q.Dispatch.drive(Instance.new("Folder"), { s3 }); ob:Destroy()
	ln = here(); row("Replace over destroyed element", ln, function() s3:Replace(1, F()) end)
end

-- ── already-held / cycles ──
do
	local q = env()
	local host = Instance.new("Folder")
	local a, b = q.Slot(), q.Slot()
	local ln
	ln = here(); row("Add self (free)", ln, function() a:Add(a) end)
	a:Add(b)
	ln = here(); row("Add parent into child (free root)", ln, function() b:Add(a) end)
	q.Dispatch.drive(host, { a })
	ln = here(); row("Add parent into child (mounted root)", ln, function() b:Add(a) end)
	local f = F()
	b:Add(f)
	ln = here(); row("Add held leaf into other Slot", ln, function() q.Slot():Add(f) end)
	ln = here(); row("Add held leaf into same Slot", ln, function() b:Add(f) end)
	ln = here(); row("Replace(i, Get(i))", ln, function() b:Replace(1, b:Get(1)) end)
	ln = here(); row("Splice puts back what it removes", ln, function() b:Splice(1, 1, f) end)
	local st = q.Source(nil)
	b:Add(st)
	ln = here(); row("same nil-State twice (second place)", ln, function() q.Slot():Add(st) end)
	local c = q.Slot(); local st2 = q.Source(nil); c:Add(st2); c:Add(st2) -- both wrappers accept a nil State
	print(`   same nil-State added twice to one Slot: len={#c._elements}`)
	q.Dispatch.drive(Instance.new("Folder"), { c })
	local g = F("g")
	ln = here(); row("Set that State to a leaf (two wrappers race for it)", ln, function() st2:Set(g) end)
	print(`   -> g owner is wrapper#1? {q._probeOwner:GetWeak(g, "__owner") == c._elements[1]} wrapper#2? {q._probeOwner:GetWeak(g, "__owner") == c._elements[2]}; c.Length={c.Length:Get()} (Blocker left on? {q.Bookkeeping.getBlocker(c._elements[2]).Blocking})`)
end

-- ── cycle through a State element whose wrapper has not claimed yet (fuzzer seed 3415) ──
do
	local q = env()
	local outer = q.Slot()          -- free, never mounted
	local st = q.Source(nil)
	outer:Add(st)                   -- wrapper not materialized: claims nothing
	local inner = q.Slot()
	st:Set(inner)                   -- logically outer ⊃ st ⊃ inner
	local ln = here() + 1 -- the row() call is on the next line
	local ok = row("inner:Add(outer) — cycle via unclaimed State link", ln, function() inner:Add(outer) end)
	if ok then
		print(`   outer owner={q._probeOwner:GetWeak(outer, "__owner") == inner and "inner" or "?"}; inner owner={tostring(q._probeOwner:GetWeak(inner, "__owner"))}`)
		local host = Instance.new("Folder")
		ln = here(); row("  then mount outer's owner chain (drive inner)", ln, function() q.Dispatch.drive(host, { inner }) end)
		ln = here(); row("  then dispose(inner)", ln, function() q.dispose(inner) end)
	end
	-- same, but with the State set AFTER the add (both orders)
	local q2 = env()
	local o2 = q2.Slot(); local st2 = q2.Source(nil); o2:Add(st2); local i2 = q2.Slot()
	i2:Add(o2)
	ln = here(); row("st:Set(inner) after inner:Add(outer) (free tree)", ln, function() st2:Set(i2) end)
	local h2 = Instance.new("Folder")
	ln = here(); row("  then drive(i2)", ln, function() q2.Dispatch.drive(h2, { i2 }) end)
	-- mounted variant: State set to an ancestor while mounted
	local q3 = env()
	local root = q3.Slot(); local st3 = q3.Source(nil); root:Add(st3)
	q3.Dispatch.drive(Instance.new("Folder"), { root })
	ln = here(); row("mounted: st:Set(its own ancestor)", ln, function() st3:Set(root) end)
	local q4 = env()
	local r4 = q4.Slot(); local m4 = q4.Slot(); local st4 = q4.Source(nil); m4:Add(st4); r4:Add(m4)
	q4.Dispatch.drive(Instance.new("Folder"), { r4 })
	local free = q4.Slot()
	ln = here(); row("mounted: st:Set(free Slot containing ... nothing) ok", ln, function() st4:Set(free) end)
	ln = here(); row("mounted: free:Add(r4) where r4 ⊃ m4 ⊃ st4 ⊃ free", ln, function() free:Add(r4) end)
end

-- ── re-entry (UB in the contract) ──
do
	local q = env()
	local host = Instance.new("Folder")
	local s = q.Slot({ F("a") })
	local nested = q.Slot({ F("n") })
	s:Add(nested)
	q.Dispatch.drive(host, { "L", s, "T" })
	local fired = 0
	local ob = nested.Offset:Observer(function() fired += 1; if fired == 2 then s:Add(F("fromObserver"), 1) end end); ob:Subscribe()
	local ln = here() + 1 -- the row() call is on the next line
	row("Offset observer CRUDs the parent Slot (re-entry)", ln, function() s:Add(F("x"), 1) end)
	print(`   s len={#s._elements} Length={s.Length:Get()} nested.Offset={nested.Offset:Get()} (logical: leaves before nested = {s:IndexOf(nested) - 1 + 1})`)
	local src = q.Source("a")
	local sub = q.Slot()
	local parent = q.Slot()
	sub:Single(src, function(ctx) if ctx.Item == q.KeyGone then return nil end; parent:Add(F("anc")); return F(ctx.Item) end)
	parent:Add(sub)
	ln = here(); row("Single updateFn CRUDs its ancestor during mount", ln, function() q.Dispatch.drive(Instance.new("Folder"), { parent }) end)
	local q5 = env()
	local p5 = q5.Slot(); local src5 = q5.Source("a"); local sub5 = q5.Slot()
	local n5 = 0
	sub5:Single(src5, function(ctx) if ctx.Item == q5.KeyGone then return nil end; n5 += 1; if n5 == 2 then p5:Add(F("anc2")) end; return F(ctx.Item) end)
	p5:Add(sub5); q5.Dispatch.drive(Instance.new("Folder"), { p5 })
	ln = here(); row("Single updateFn CRUDs its ancestor after mount (src:Set)", ln, function() src5:Set("b") end)
	print(`   p5 len={#p5._elements} Length={p5.Length:Get()}`)
	local n6 = 0
	local q6 = env(); local p6 = q6.Slot(); local src6 = q6.Source("a"); local sub6 = q6.Slot()
	sub6:Single(src6, function(ctx) if ctx.Item == q6.KeyGone then return nil end; n6 += 1; if n6 == 2 then src6:Set("c") end; return F(ctx.Item) end)
	p6:Add(sub6); q6.Dispatch.drive(Instance.new("Folder"), { p6 })
	ln = here(); row("Single updateFn re-Sets its own data (UB)", ln, function() src6:Set("b") end)
	print(`   sub6 element={sub6._elements[1] and sub6._elements[1].Name} calls={n6}`)
end
