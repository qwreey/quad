--!nocheck
-- round13 E1-2 probe (Q73 install-window loss, Q74 grandparent materializing). Run: copy to quad-base/test/,
-- ./scripts/relink.sh, luau quad-base/test/probe.e1b.luau. To try the prototypes: `cp -rL quad-base <scratch>/`,
-- apply `round13-e1b-probe-patches/*.diff` inside the copy, run the same file there (PATCH_STATS line reports reruns).
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
local Slot, dispatch, Source = q.Slot, q.Dispatch, q.Source
local function F(n) local f = Instance.new("Frame"); f.Name = n; return f end
local function leaves(s, out) out = out or {}; for _, e in ipairs(s._elements) do if q.isSlot(e) then leaves(e, out) else table.insert(out, e) end end; return out end
local function T(name, f)
	local ok, err = pcall(f)
	if not ok then print(`--- {name}: ERR {tostring(err):sub(1, 200)}`) end
end
local function row(case, verdict, detail) print(`[{case}] {verdict} | {detail}`) end

-- A1: fn Sets its own State directly during install (the H-159/H-164 case)
T("A1", function()
	local s = Source(0)
	local runs, seen = 0, {}
	local o = s:Observer(function(st)
		runs += 1
		seen[#seen + 1] = st:Get()
		if st:Get() == 0 then st:Set(1) end
	end)
	row("A1 fn Sets own State (install)", if seen[#seen] == s:Get() then "no-loss" else "LOSS",
		`runs {runs} seen {table.concat(seen, ",")} s {s:Get()} rerunReq {o._rerunRequired}`)
	o:Subscribe()
	row("A1' after Subscribe", if seen[#seen] == s:Get() then "no-loss" else "LOSS", `runs {runs} seen {table.concat(seen, ",")}`)
end)

-- A2: fn Sets own State unconditionally to a fixed point (clamp) — run count
T("A2", function()
	local s = Source(50)
	local runs = 0
	local o = s:Observer(function(st) runs += 1; if st:Get() > 10 then st:Set(10) end end)
	row("A2 clamp own State (install)", "runs", `runs {runs} s {s:Get()} rerunReq {o._rerunRequired}`)
	o:Subscribe()
	row("A2' after Subscribe", "runs", `runs {runs}`)
end)

-- B: fn's side effect wakes ANOTHER subscribed Observer that Sets the observed State (P2)
T("B", function()
	local s, other = Source(0), Source(0)
	local o1 = other:Observer(function(_, _, from) if from ~= nil then s:Set(s:Get() + 1) end end):Subscribe()
	local seen = {}
	local o2 = s:Observer(function(st) seen[#seen + 1] = st:Get(); if #seen == 1 then other:Set(1) end end)
	row("B other Observer Sets (install)", if seen[#seen] == s:Get() then "no-loss" else "LOSS", `seen {table.concat(seen, ",")} s {s:Get()} rerunReq {o2._rerunRequired}`)
	o2:Subscribe()
	row("B' after Subscribe", if seen[#seen] == s:Get() then "no-loss" else "LOSS (Subscribe catch-up does not recover)", `seen {table.concat(seen, ",")}`)
	local _ = o1
end)

-- C1: setLength (Bookkeeping) — nested runtime Add, sibling Offset Observer CRUDs a grandchild of the new Slot (E1 T5)
T("C1", function()
	local parent = Instance.new("Folder")
	local S1, S22 = Slot(), Slot()
	local R2 = Slot({ S22, F("f58") })
	dispatch.drive(parent, { S1, R2 })
	local S14 = Slot()
	local S12 = Slot({ S14, F("f36") })
	local fired = false
	S22.Offset:Observer(function() if not fired and S22.Offset:Get() > 0 then fired = true; S14:Add(F("new")) end end):Subscribe()
	S1:Add(S12, 1)
	row("C1 setLength nested (sibling Offset obs → grandchild Add)", if R2.Offset:Get() == #leaves(S1) and S1.Length:Get() == #leaves(S1) then "no-loss" else "LOSS",
		`fired {fired} S1.Length {S1.Length:Get()} leaves {#leaves(S1)} R2.Offset {R2.Offset:Get()} (want {#leaves(S1)})`)
end)

-- C2: setLength top-level via State<Slot> holder (E1 T7)
T("C2", function()
	local parent = Instance.new("Folder")
	local child = Slot()
	local R = Slot({ child, F("r") })
	local R2 = Slot({ F("z") })
	local holder = Source(nil)
	dispatch.drive(parent, { holder, R2 })
	local fired = false
	R2.Offset:Observer(function() if not fired and R2.Offset:Get() > 0 then fired = true; child:Add(F("new")) end end):Subscribe()
	holder:Set(R)
	row("C2 setLength top-level holder:Set(R)", if R2.Offset:Get() == #leaves(R) then "no-loss" else "LOSS",
		`fired {fired} R.Length {R.Length:Get()} R2.Offset {R2.Offset:Get()} (want {#leaves(R)})`)
end)

-- C3x: an OSCILLATING user graph (badge on list.Length == 1 inside the row adds a leaf → Length 2 → badge off → 1 …)
-- — no correct fixed point exists; recorded to show what each side does with genuinely cyclic user code.
T("C3x", function()
	local parent = Instance.new("Folder")
	local list = Slot()
	local after = Slot({ F("footer") })
	dispatch.drive(parent, { list, after })
	local badge = list.Length:Compute(function(h) return if h:Get() == 1 then F("only") else nil end)
	local r1 = Slot({ badge, F("r1") })
	local ok, err = pcall(function() list:Add(r1) end)
	row("C3x oscillator (badge on list.Length==1)", if not ok then "ERR" elseif after.Offset:Get() == list.Length:Get() and list.Length:Get() == #leaves(list) then "no-loss" else "LOSS",
		`ok {ok} {err and tostring(err):sub(1, 90) or ""} list.Length {list.Length:Get()} leaves {#leaves(list)} footer Offset {after.Offset:Get()}`)
end)

-- C3: "natural" — each row has a delete button shown only while the list holds more than one leaf
-- (monotone: once shown it stays). Adding the SECOND row flips the new row's button during the
-- list's setLength install fire for that row.
T("C3", function()
	local parent = Instance.new("Folder")
	local list = Slot()
	local after = Slot({ F("footer") })
	dispatch.drive(parent, { list, after })
	local function Row(name)
		local del = list.Length:Compute(function(h) return if h:Get() > 1 then F(name .. "-del") else nil end)
		return Slot({ F(name), del })
	end
	list:Add(Row("r1"))
	row("C3a first Add", if after.Offset:Get() == list.Length:Get() and list.Length:Get() == #leaves(list) then "no-loss" else "LOSS",
		`list.Length {list.Length:Get()} leaves {#leaves(list)} footer Offset {after.Offset:Get()}`)
	local ok, err = pcall(function() list:Add(Row("r2")) end)
	local kids = {}
	for _, c in parent:GetChildren() do kids[#kids + 1] = c.Name end
	row("C3b natural: per-row delete button on list.Length>1, second Add", if not ok then "ERR" elseif after.Offset:Get() == list.Length:Get() and list.Length:Get() == #leaves(list) then "no-loss" else "LOSS",
		`ok {ok} {err and tostring(err):sub(1, 90) or ""} list.Length {list.Length:Get()} leaves {#leaves(list)} footer Offset {after.Offset:Get()} children {table.concat(kids, ",")}`)
end)

-- C3c: row button shown while the list is non-empty — the row that makes it non-empty flips its OWN button
T("C3c", function()
	local parent = Instance.new("Folder")
	local list = Slot()
	local after = Slot({ F("footer") })
	dispatch.drive(parent, { list, after })
	local function Row(name)
		local b = list.Length:Compute(function(h) return if h:Get() > 0 then F(name .. "-btn") else nil end)
		return Slot({ F(name), b })
	end
	local ok, err = pcall(function() list:Add(Row("r1")) end)
	row("C3c row button on list.Length>0, first Add", if not ok then "ERR" elseif after.Offset:Get() == list.Length:Get() and list.Length:Get() == #leaves(list) then "no-loss" else "LOSS",
		`ok {ok} {err and tostring(err):sub(1, 90) or ""} list.Length {list.Length:Get()} leaves {#leaves(list)} footer Offset {after.Offset:Get()}`)
end)

-- C3d: a header row reacting to the list's Length, added as a new sibling? No — the natural "shows only while
-- the list has >1 leaf" but only the NEW row carries the conditional (older rows are plain)
T("C3d", function()
	local parent = Instance.new("Folder")
	local list = Slot({ F("r1") })
	local after = Slot({ F("footer") })
	dispatch.drive(parent, { list, after })
	local sep = list.Length:Compute(function(h) return if h:Get() > 1 then F("sep") else nil end)
	local ok, err = pcall(function() list:Add(Slot({ sep, F("r2") })) end)
	row("C3d new row: separator shown when list.Length>1 (older rows plain)", if not ok then "ERR" elseif after.Offset:Get() == list.Length:Get() and list.Length:Get() == #leaves(list) then "no-loss" else "LOSS",
		`ok {ok} {err and tostring(err):sub(1, 90) or ""} list.Length {list.Length:Get()} leaves {#leaves(list)} footer Offset {after.Offset:Get()}`)
end)

-- C5: new subtree reacts to a LATER sibling's Offset (the sibling moves because of this Add) — Compute, no Observer
T("C5", function()
	local parent = Instance.new("Folder")
	local list = Slot()
	local footer = Slot({ F("footer") })
	dispatch.drive(parent, { list, footer })
	local hint = footer.Offset:Compute(function(h) return if h:Get() > 0 then F("hint") else nil end)
	local ok, err = pcall(function() list:Add(Slot({ F("r1"), hint })) end)
	row("C5 new row: hint on footer.Offset>0 (Compute only, no user Observer)", if not ok then "ERR" elseif footer.Offset:Get() == list.Length:Get() and list.Length:Get() == #leaves(list) then "no-loss" else "LOSS",
		`ok {ok} {err and tostring(err):sub(1, 90) or ""} list.Length {list.Length:Get()} leaves {#leaves(list)} footer Offset {footer.Offset:Get()}`)
end)

-- C4: "natural" variant — row shows a divider when its Offset > 0; prepend a row so the EXISTING row moves
T("C4", function()
	local parent = Instance.new("Folder")
	local list = Slot()
	local after = Slot({ F("footer") })
	dispatch.drive(parent, { list, after })
	local function Row(name)
		local r = Slot()
		local divider = r.Offset:Compute(function(h) return if h:Get() > 0 then F(name .. "-div") else nil end)
		r:Add(divider); r:Add(F(name))
		return r
	end
	pcall(function() list:Add(Row("a")) end)
	local ok, err = pcall(function() list:Add(Row("b"), 1) end)
	row("C4 natural: divider on own row.Offset>0, prepend", if not ok then "ERR" elseif after.Offset:Get() == list.Length:Get() and list.Length:Get() == #leaves(list) then "no-loss" else "LOSS",
		`ok {ok} {err and tostring(err):sub(1, 120) or ""} list.Length {list.Length:Get()} leaves {#leaves(list)} footer Offset {after.Offset:Get()}`)
	local ok2, err2 = pcall(function() list:Add(Row("c")) end)
	row("C4' append (new row's own Offset>0)", if not ok2 then "ERR" elseif after.Offset:Get() == list.Length:Get() and list.Length:Get() == #leaves(list) then "no-loss" else "LOSS",
		`ok {ok2} {err2 and tostring(err2):sub(1, 120) or ""} list.Length {list.Length:Get()} leaves {#leaves(list)} footer Offset {after.Offset:Get()}`)
end)

-- D: StoreBind (Dispatch/StoreBind.luau:68) — mounting the holder's value fires a user Observer that Sets the holder
T("D", function()
	local parent = Instance.new("Folder")
	local A = Slot({ F("A") })
	local Bs = Slot({ F("B") })
	local holder = Source(A)
	local fired = false
	A.Offset:Observer(function() if not fired and A.Offset:Get() > 0 then fired = true; holder:Set(Bs) end end):Subscribe()
	dispatch.drive(parent, { Slot({ F("x") }), holder })
	local kids = {}
	for _, c in parent:GetChildren() do kids[#kids + 1] = c.Name end
	row("D StoreBind install (value's mount Sets holder)", if holder:Get() == Bs and Bs._mounted then "no-loss" elseif fired then "LOSS" else "not-fired",
		`fired {fired} holder==B {holder:Get() == Bs} A mounted {A._mounted} B mounted {Bs._mounted} children {table.concat(kids, ",")}`)
end)

-- E: Slot/Tree.luau:25 makeBaseObserver — install fire runs at Slot construction and returns early (unmaterialized):
-- no user code in the window. Checked structurally: the flag after construction.
T("E", function()
	local s = Slot()
	row("E Tree makeBaseObserver", "no user code in window", `_rerunRequired {s._baseObserver._rerunRequired} (install fire returns before any Set)`)
end)

-- F: Slot/List.luau:200 — data:Observer(reconcile): updateFn Sets the data State during the first reconcile (documented reentrancy UB)
T("F", function()
	local parent = Instance.new("Folder")
	local data = Source({ "a" })
	local list = Slot()
	local done = false
	list:List(data, function(ctx)
		if not done then done = true; data:Set({ "a", "b" }) end
		return F(tostring(ctx.Item))
	end)
	local ok, err = pcall(function() dispatch.drive(parent, { list }) end)
	row("F List data install (updateFn Sets data — UB)", if not ok then "ERR" elseif list.Length:Get() == #data:Get() then "no-loss" else "LOSS",
		`ok {ok} {err and tostring(err):sub(1, 100) or ""} list.Length {list.Length:Get()} data# {#data:Get()}`)
end)

-- ── Q74 ──
T("Q74-T6", function()
	local parent = Instance.new("Folder")
	local inner = Slot()
	local outer = Slot({ inner })
	dispatch.drive(parent, { outer })
	local fired, rmOk, rmErr = false, nil, nil
	inner.Length:Observer(function()
		if inner.Length:Get() > 0 and not fired then fired = true; rmOk, rmErr = pcall(function() outer:Remove(1) end) end
	end):Subscribe()
	local f = F("leaf")
	local sub = Slot({ f })
	local addOk, addErr = pcall(function() inner:Add(sub) end)
	row("Q74 T6 grandparent Remove in attach window", if sub._destroyed and sub._mounted then "GHOST" else "clean",
		`remove ok {rmOk} {rmErr and tostring(rmErr):match("Quad%d+") or ""} add ok {addOk} {addErr and tostring(addErr):sub(1,80) or ""} sub destroyed {sub._destroyed} mounted {sub._mounted} f.Parent==parent {f.Parent == parent} #children {#parent:GetChildren()}`)
end)
T("Q74-deep", function()
	-- great-great-grandparent (depth 4) CRUD from the attach window
	local parent = Instance.new("Folder")
	local s3 = Slot(); local s2 = Slot({ s3 }); local s1 = Slot({ s2 }); local s0 = Slot({ s1 })
	dispatch.drive(parent, { s0 })
	local fired, rmOk, rmErr = false, nil, nil
	s3.Length:Observer(function()
		if s3.Length:Get() > 0 and not fired then fired = true; rmOk, rmErr = pcall(function() s0:Clear() end) end
	end):Subscribe()
	local sub = Slot({ F("leaf") })
	pcall(function() s3:Add(sub) end)
	row("Q74 depth-4 ancestor Clear in attach window", if sub._destroyed and sub._mounted then "GHOST" else "clean",
		`clear ok {rmOk} {rmErr and tostring(rmErr):match("Quad%d+") or ""} sub destroyed {sub._destroyed} mounted {sub._mounted} #children {#parent:GetChildren()}`)
end)
T("Q74-sibling", function()
	-- control: CRUD of a sibling subtree (not an ancestor) from the attach window must still pass
	local parent = Instance.new("Folder")
	local inner = Slot(); local sib = Slot({ F("s") })
	local outer = Slot({ inner, sib })
	dispatch.drive(parent, { outer })
	local fired, ok, err = false, nil, nil
	inner.Length:Observer(function()
		if inner.Length:Get() > 0 and not fired then fired = true; ok, err = pcall(function() sib:Add(F("s2")) end) end
	end):Subscribe()
	pcall(function() inner:Add(Slot({ F("leaf") })) end)
	row("Q74 control sibling Add in attach window", if ok then "passes" else "REFUSED", `ok {ok} {err and tostring(err):match("Quad%d+") or ""} outer.Length {outer.Length:Get()} leaves {#leaves(outer)}`)
end)

local PS = (require("../src/Observer") :: any).PATCH_STATS
print("PATCH_STATS", PS and `installs {PS.installs} reruns {PS.reruns}` or "(unpatched)")
