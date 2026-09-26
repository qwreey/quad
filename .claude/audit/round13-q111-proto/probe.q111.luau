--!nocheck
-- P-Q111 probes (scratch). Run from <copy>/ as `luau test/probe.q111.luau` (copied into test/).
local mock = require("./mock")
local Instance = mock.Instance
local function F(n) local f = Instance.new("Frame"); f.Name = n or "f"; return f end
local function tryp(label, fn)
	local ok, err = pcall(fn)
	local e = tostring(err)
	print(`  {label}: {if ok then "ok" else (string.match(e, "Quad%d%d%d%d") or e) .. " blame=" .. (string.match(e, "^[^:]+:(%d+):") or "?")}`)
	return ok, e
end
local function owner(q, x) return q._probeOwner:GetWeak(x, "__owner") end

print("Q1 — P6: outer{st}, st:Set(inner), inner:Add(outer) (never mounted)")
do
	local q = mock.newQuad()
	local outer = q.Slot()
	local st = q.Source(nil)
	outer:Add(st)
	local inner = q.Slot({ F("i1") })
	st:Set(inner)
	tryp("inner:Add(outer)", function() inner:Add(outer) end)
	print(`  inner len={#inner._elements} outer owner={owner(q, outer)}`)
	local host = Instance.new("Folder")
	tryp("drive(host, {inner})", function() q.Dispatch.drive(host, { inner }) end)
	print(`  inner materializing? {inner._materializing}; outer materializing? {outer._materializing}; host children={#host:GetChildren()}`)
	tryp("inner:Add(F()) afterwards", function() inner:Add(F("late")) end)
	print(`  host children={#host:GetChildren()} inner.Length={inner.Length:Get()}`)
end

print("Q1b — same, deeper: outer{ mid{ st } }, st:Set(inner), inner:Add(outer)")
do
	local q = mock.newQuad()
	local st = q.Source(nil)
	local mid = q.Slot({ st })
	local outer = q.Slot({ mid })
	local inner = q.Slot()
	st:Set(inner)
	tryp("inner:Add(outer)", function() inner:Add(outer) end)
end

print("Q1c — two States chained: outer{st1}; st1:Set(mid); mid{st2}; st2:Set(inner); inner:Add(outer)")
do
	local q = mock.newQuad()
	local st1, st2 = q.Source(nil), q.Source(nil)
	local outer = q.Slot({ st1 })
	local mid = q.Slot({ st2 })
	local inner = q.Slot()
	st1:Set(mid); st2:Set(inner)
	tryp("inner:Add(outer)", function() inner:Add(outer) end)
	tryp("Splice form: inner:Splice(1, 0, F(), outer)", function() inner:Splice(1, 0, F("x"), outer) end)
	tryp("constructor form: can't (outer must be inside new Slot) — q.Slot{outer} ok", function() q.Slot({ outer }) end)
end

print("Q1d — State of State: outer{ stA }, stA holds stB, stB holds inner")
do
	local q = mock.newQuad()
	local stB = q.Source(nil)
	local stA = q.Source(stB)
	local outer = q.Slot({ stA })
	local inner = q.Slot()
	stB:Set(inner)
	tryp("inner:Add(outer)", function() inner:Add(outer) end)
end

print("Q1e — user identity :Single(st) (no updateFn) instead of a wrapper")
do
	local q = mock.newQuad()
	local st = q.Source(nil)
	local ss = q.Slot():Single(st)
	local outer = q.Slot({ ss })
	local inner = q.Slot()
	st:Set(inner)
	tryp("inner:Add(outer)", function() inner:Add(outer) end)
end

print("Q1f — non-identity :Single(st, updateFn) returning its data (not covered by A)")
do
	local q = mock.newQuad()
	local st = q.Source(nil)
	local ss = q.Slot():Single(st, function(ctx) if ctx.Item == q.KeyGone then return nil end; return ctx.Item end)
	local outer = q.Slot({ ss })
	local inner = q.Slot()
	st:Set(inner)
	tryp("inner:Add(outer)", function() inner:Add(outer) end)
end

print("Q2 — MOUNTED tree: st:Set(own ancestor)")
do
	local q = mock.newQuad()
	local host = Instance.new("Folder")
	local st = q.Source(F("a"))
	local mid = q.Slot({ st, F("m2") })
	local root = q.Slot({ F("r1"), mid })
	q.Dispatch.drive(host, { root })
	local w = mid._elements[1]
	tryp("st:Set(root)", function() st:Set(root) end)
	print(`  wrapper blocker on? {q.Bookkeeping.getBlocker(w).Blocking}; wrapper len={#w._elements}; st:Get()==root? {st:Get() == root}; root.Length={root.Length:Get()}`)
	tryp("st:Set(mid)", function() st:Set(mid) end)
	tryp("st:Set(w itself? no — st:Set(F('b')) recovery)", function() st:Set(F("b")) end)
	print(`  after: wrapper len={#w._elements} wrapper.Length={w.Length:Get()} root.Length={root.Length:Get()} (model 3) host children={#host:GetChildren()}`)
	tryp("st:Set(nil)", function() st:Set(nil) end)
	print(`  after Set(nil): wrapper.Length={w.Length:Get()} (model 0) root.Length={root.Length:Get()} (model 2)`)
	tryp("root:Add(F())", function() root:Add(F("more")) end)
	print(`  root.Length={root.Length:Get()} (model 3)`)
end

print("Q2b — MOUNTED: st:Set(unmounted Slot that holds the wrapper's ancestor via another State)")
do
	local q = mock.newQuad()
	local host = Instance.new("Folder")
	local st = q.Source(nil)
	local root = q.Slot({ st })
	local holderSt = q.Source(nil)
	local free = q.Slot({ holderSt })
	q.Dispatch.drive(host, { root })
	holderSt:Set(root)            -- free{holderSt=root} while free is unmounted: nothing checks
	tryp("st:Set(free)", function() st:Set(free) end)
	local w = root._elements[1]
	print(`  wrapper blocker on? {q.Bookkeeping.getBlocker(w).Blocking}; root.Length={root.Length:Get()}`)
end

print("Q3 — UNMOUNTED Set order (Add first, Set later): outer{st}; inner:Add(outer); st:Set(inner)")
do
	local q = mock.newQuad()
	local st = q.Source(nil)
	local outer = q.Slot({ st })
	local inner = q.Slot({ F("i1") })
	tryp("inner:Add(outer) (st nil)", function() inner:Add(outer) end)
	tryp("st:Set(inner) (unmounted — no observer)", function() st:Set(inner) end)
	local host = Instance.new("Folder")
	tryp("drive(host, {inner})", function() q.Dispatch.drive(host, { inner }) end)
	print(`  inner materializing? {inner._materializing}; outer materializing? {outer._materializing}; host children={#host:GetChildren()}`)
end

print("Q3b — mounted-once then unmounted wrapper, Set(ancestor) while unmounted, remount")
do
	local q = mock.newQuad()
	local host = Instance.new("Folder")
	local st = q.Source(F("a"))
	local root = q.Slot({ st })
	local holder = q.Source(root)
	q.Dispatch.drive(host, { holder })
	holder:Set(nil)
	tryp("st:Set(root) while unmounted", function() st:Set(root) end)
	tryp("remount holder:Set(root)", function() holder:Set(root) end)
	print(`  root materializing? {root._materializing}; host children={#host:GetChildren()}`)
end

print("Q4 — P4: the same nil State placed twice")
do
	local q = mock.newQuad()
	local host = Instance.new("Folder")
	local st = q.Source(nil)
	local s1, s2 = q.Slot(), q.Slot()
	tryp("s1:Add(st)", function() s1:Add(st) end)
	tryp("s2:Add(st)", function() s2:Add(st) end)
	tryp("s1:Add(st) again (same Slot)", function() s1:Add(st) end)
	tryp("s1:Splice(1,0,st2,st2) (batch dup, nil State)", function() local st2 = q.Source(nil); s1:Splice(1, 0, st2, st2) end)
	tryp("q.Slot{ st3, st3 } (nil State)", function() local st3 = q.Source(nil); q.Slot({ st3, st3 }) end)
	q.Dispatch.drive(host, { s1, s2 })
	local g = F("g")
	tryp("st:Set(g)", function() st:Set(g) end)
	print(`  s1.Length={s1.Length:Get()} s2.Length={s2.Length:Get()} (model 1, 0)`)
end

print("Q4b — seat released: Extract / Remove / dispose of the holder, then Add elsewhere")
do
	local q = mock.newQuad()
	local st = q.Source(nil)
	local s1, s2 = q.Slot({ st }), q.Slot()
	tryp("s1:Extract(1) then s2:Add(st)", function() s1:Extract(1); s2:Add(st) end)
	tryp("s2:Remove(1) then s1:Add(st)", function() s2:Remove(1); s1:Add(st) end)
	tryp("q.dispose(s1) then s2:Add(st)", function() q.dispose(s1); s2:Add(st) end)
	tryp("s2:Replace(1, st) (same seat)", function() s2:Replace(1, st) end)
	tryp("s2:Splice(1, 1, st) (put back what it removes)", function() s2:Splice(1, 1, st) end)
	local s3 = q.Slot()
	tryp("failed pre-pass leaves no seat: s3:Splice(1,0, st4, nil)", function() local st4 = q.Source(nil); s3:Splice(1, 0, st4, q.None) end)
end

print("Q4c — mounted: two seats of a Slot-valued State (was Quad0172 before too)")
do
	local q = mock.newQuad()
	local st = q.Source(q.Slot({ F("x") }))
	local s1 = q.Slot({ st })
	tryp("q.Slot():Add(st)", function() q.Slot():Add(st) end)
end

print("Q5 — cost: does the pre-pass run Compute fns it did not run before?")
do
	local q = mock.newQuad()
	local runs = 0
	local src = q.Source(1)
	local c = src:Compute(function(v) runs += 1; return nil end)
	local outer = q.Slot({ c })
	local inner = q.Slot()
	src:Set(2) -- c is dirty now (unobserved)
	local r0 = runs
	inner:Add(outer)
	print(`  dirty Compute inside the candidate's subtree — fn runs during inner:Add(outer): {runs - r0}`)
	local c2 = src:Compute(function(v) runs += 1; return nil end)
	local deep = q.Slot({ q.Slot({ c2 }) })
	src:Set(3)
	local r2 = runs
	q.Slot():Add(deep)
	print(`  two levels down, dirty — fn runs during q.Slot():Add(deep): {runs - r2}`)
	local r3 = runs
	print(`  (base reads only the target Slot's own elements' occupants)`)
end

print("Q5b — Quad0184: an Add made from inside a Compute fn whose value sits in the candidate's subtree")
do
	local q = mock.newQuad()
	local src = q.Source(1)
	local target = q.Slot()
	local holder = q.Slot()
	local res = "fn did not run"
	local c = src:Compute(function(v)
		if v:Get() == 2 then
			local ok, e = pcall(function() target:Add(holder) end)
			res = if ok then "ok" else (string.match(tostring(e), "Quad%d%d%d%d") or tostring(e))
		end
		return nil
	end)
	holder:Add(c)
	src:Set(2)
	c:Get()
	print(`  inside c's fn: target:Add(holder) -> {res}`)
end

print("Q5c — a throwing (dirty) Compute two levels inside the candidate")
do
	local q = mock.newQuad()
	local src = q.Source(1)
	local c = src:Compute(function(v) if v:Get() == 2 then error("user compute boom") end; return nil end)
	local deep = q.Slot({ q.Slot({ c }) })
	src:Set(2)
	local ok, e = pcall(function() q.Slot():Add(deep) end)
	print(`  q.Slot():Add(deep) -> {if ok then "ok" else string.sub(tostring(e), 1, 90)}`)
end

print("Q4d — a rejected second seat must not erase the first seat's record")
do
	local q = mock.newQuad()
	local st = q.Source(nil)
	local s1, s2 = q.Slot({ st }), q.Slot()
	tryp("s2:Add(st) #1", function() s2:Add(st) end)
	tryp("s2:Add(st) #2 (still rejected?)", function() s2:Add(st) end)
end

print("Q6 — after a reconcile-depth raise from a State element Set, unmount + remount")
for _, mode in { "held (base Quad0156 path)", "ancestor (A Quad0173 path)" } do
	local q = mock.newQuad()
	local host = Instance.new("Folder")
	local a = F("a")
	local st = q.Source(a)
	local root = q.Slot({ st, F("t") })
	local other = q.Slot({ F("held") })
	local holder = q.Source(root)
	q.Dispatch.drive(host, { holder, other })
	print(`  [{mode}]`)
	if mode:sub(1, 4) == "held" then
		tryp("st:Set(held)", function() st:Set(other:Get(1)) end)
	else
		tryp("st:Set(root)", function() st:Set(root) end)
	end
	tryp("st:Set(a) (back to the shown value)", function() st:Set(a) end)
	tryp("unmount holder:Set(nil)", function() holder:Set(nil) end)
	tryp("remount holder:Set(root)", function() holder:Set(root) end)
	tryp("st:Set(F('z')) after", function() st:Set(F("z")) end)
end
