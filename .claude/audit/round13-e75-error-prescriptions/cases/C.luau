--!nocheck
-- E75 group C: docs/reference/errors/03-slot.md (Quad0140..0180, 0236, 0238..0242)
local H = require("../harness")
local R = require("../runner")
local q, D = H.q, H.D
local Mock = H.mock

local function kids(f) return #f:GetChildren() end
local function label(t) return D.TextLabel({ Text = t or "x" }) end
local function gone(item) return item == q.KeyGone end

-- ── Quad0140 ─────────────────────────────────────────────
R.case({ id = "Quad0140",
	trigger = function() local s = q.Slot(); q.dispose(s); D.Frame({ s }) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); return kids(f) == 1, "children=" .. kids(f) end })

-- ── Quad0141 ─────────────────────────────────────────────
R.case({ id = "Quad0141", note = "a: string key",
	trigger = function() D.Frame({ Items = q.Slot({ label() }) }) end,
	fix = function() local f = D.Frame({ q.Slot({ label() }) }); return kids(f) == 1, "a children=" .. kids(f) end })
R.case({ id = "Quad0141", note = "b: State at string key",
	trigger = function() D.Frame({ Items = q.Source(q.Slot({ label() })) }) end,
	fix = function() local f = D.Frame({ q.Source(q.Slot({ label() })) }); return kids(f) == 1, "b children=" .. kids(f) end })
R.case({ id = "Quad0141", note = "c: Dispatch.process k=0",
	trigger = function() local f = D.Frame({}); q.Dispatch.process(f, 0, q.Slot({ label() }), 1) end,
	fix = function() local f = D.Frame({ q.Slot({ label() }) }); return kids(f) == 1, "c children=" .. kids(f) end })

-- ── Quad0142 ─────────────────────────────────────────────
R.case({ id = "Quad0142",
	trigger = function()
		local data = q.Source({ "a" }); local s = q.Slot()
		s:List(data, function(ctx) if gone(ctx.Item) then return nil end return ctx.Prev or label(ctx.Item) end)
		D.Frame({ s }); data:Set("b")
	end,
	fix = function()
		local data = q.Source({ "a" }); local s = q.Slot()
		s:List(data, function(ctx) if gone(ctx.Item) then return nil end return ctx.Prev or label(ctx.Item) end)
		local f = D.Frame({ s }); data:Set({ "b", "c" })
		return kids(f) == 2, "children=" .. kids(f)
	end })
R.case({ id = "Quad0142", note = "b: data State holds a Store (branded)",
	trigger = function()
		local data = q.Source({ "a" }); local s = q.Slot()
		s:List(data, function(ctx) if gone(ctx.Item) then return nil end return label(ctx.Item) end)
		D.Frame({ s }); data:Set(q.Store({ x = q.Source(1) }))
	end,
	fix = function()
		local data = q.Source({ "a" }); local s = q.Slot()
		s:List(data, function(ctx) if gone(ctx.Item) then return nil end return ctx.Prev or label(ctx.Item) end)
		local f = D.Frame({ s }); data:Set({ "b", "c" })
		return kids(f) == 2, "b children=" .. kids(f)
	end })

-- ── Quad0143 ─────────────────────────────────────────────
R.case({ id = "Quad0143",
	trigger = function()
		local s = q.Slot(); s:List({ u1 = "a", u2 = "b" }, function(ctx) return label(ctx.Item) end); D.Frame({ s })
	end,
	fix = function()
		local s = q.Slot(); s:List({ "a", "b" }, function(ctx) return label(ctx.Item) end); local f = D.Frame({ s })
		return kids(f) == 2, "children=" .. kids(f)
	end })

-- ── Quad0144 ─────────────────────────────────────────────
R.case({ id = "Quad0144",
	trigger = function()
		local s = q.Slot(); s:List({ { t = "a" } }, function(ctx) return label(ctx.Item.t) end, function(x) return x.id end); D.Frame({ s })
	end,
	fix = function()
		local s = q.Slot(); s:List({ { id = 1, t = "a" } }, function(ctx) return label(ctx.Item.t) end, function(x) return x.id end); local f = D.Frame({ s })
		return kids(f) == 1, "children=" .. kids(f)
	end })

-- ── Quad0145 (reuse smoke) ───────────────────────────────
R.case({ id = "Quad0145",
	trigger = function()
		local s = q.Slot()
		s:List({ "a", "a" }, function(ctx) return D.TextLabel({ Text = ctx.Item }) end, function(x) return x end)
		D.Frame({ s })
	end,
	fix = function()
		local s = q.Slot()
		s:List({ { id = 1, t = "a" }, { id = 2, t = "a" } }, function(ctx) return D.TextLabel({ Text = ctx.Item.t }) end, function(x) return x.id end)
		local f = D.Frame({ s })
		return kids(f) == 2, "children=" .. kids(f)
	end })

-- ── Quad0146 ─────────────────────────────────────────────
R.case({ id = "Quad0146", note = "fix a: drop (nil)",
	trigger = function()
		local s = q.Slot(); s:List({ "a", "" }, function(ctx) if ctx.Item == "" then return q.KeyGone end return label(ctx.Item) end); D.Frame({ s })
	end,
	fix = function()
		local s = q.Slot(); s:List({ "a", "" }, function(ctx) if ctx.Item == "" then return nil end if gone(ctx.Item) then return nil end return label(ctx.Item) end)
		local f = D.Frame({ s }); return kids(f) == 1, "a children=" .. kids(f)
	end })
R.case({ id = "Quad0146", note = "fix b: q.Detach (hold) — on the first call there is no Prev to hold",
	trigger = function()
		local s = q.Slot(); s:List({ "a", "" }, function(ctx) if ctx.Item == "" then return q.KeyGone end return label(ctx.Item) end); D.Frame({ s })
	end,
	fix = function()
		local data = q.Source({ "a", "b" }); local s = q.Slot()
		s:List(data, function(ctx) if gone(ctx.Item) then return nil end if ctx.Item == "" then return q.Detach end return ctx.Prev or label(ctx.Item) end)
		local f = D.Frame({ s }); data:Set({ "a", "" })
		return kids(f) == 1, "b children=" .. kids(f)
	end })

-- ── Quad0147 ─────────────────────────────────────────────
R.case({ id = "Quad0147",
	trigger = function()
		local data = q.Source({ "a", "b" }); local s = q.Slot()
		s:List(data, function(ctx) if gone(ctx.Item) then return label("gone") end return ctx.Prev or label(ctx.Item) end)
		D.Frame({ s }); data:Set({ "a" })
	end,
	fix = function()
		local data = q.Source({ "a", "b" }); local s = q.Slot()
		local held
		s:List(data, function(ctx) if gone(ctx.Item) then held = ctx.Prev; return q.Detach end return ctx.Prev or label(ctx.Item) end)
		local f = D.Frame({ s }); data:Set({ "a" })
		local n1 = kids(f); data:Set({ "a", "b" }); local n2 = kids(f)
		return n1 == 1 and n2 == 2 and held ~= nil and held.Parent == f, ("Detach hold: %d→%d reattached=%s"):format(n1, n2, tostring(held and held.Parent == f))
	end })

-- ── Quad0148 ─────────────────────────────────────────────
R.case({ id = "Quad0148",
	trigger = function()
		local s = q.Slot(); s:List({ "a" }, function(ctx) return label(ctx.Item) end); D.Frame({ s })
		s:List({ "b", "c" }, function(ctx) return label(ctx.Item) end)
	end,
	fix = function()
		local data = q.Source({ "a" }); local s = q.Slot()
		s:List(data, function(ctx) if gone(ctx.Item) then return nil end return ctx.Prev or label(ctx.Item) end)
		local f = D.Frame({ s }); data:Set({ "b", "c" })
		return kids(f) == 2, "children=" .. kids(f)
	end })

-- ── Quad0149 ─────────────────────────────────────────────
R.case({ id = "Quad0149", note = "a: q.Slot({})",
	trigger = function() local s = q.Slot({}); s:List({ "a" }, function(ctx) return label(ctx.Item) end) end,
	fix = function() local s = q.Slot(); s:List({ "a" }, function(ctx) return label(ctx.Item) end); local f = D.Frame({ s }); return kids(f) == 1, "a children=" .. kids(f) end })
R.case({ id = "Quad0149", note = "b: after Add",
	trigger = function() local s = q.Slot(); s:Add(label("h")); s:List({ "a" }, function(ctx) return label(ctx.Item) end) end,
	fix = function()
		-- intent: header + list items. Literal fix: list Slot without CRUD; header goes elsewhere (sibling)
		local s = q.Slot(); s:List({ "a" }, function(ctx) return label(ctx.Item) end)
		local f = D.Frame({ label("h"), s }); return kids(f) == 2, "b children=" .. kids(f)
	end })

-- ── Quad0150..0155 argument gates ───────────────────────
R.case({ id = "Quad0150",
	trigger = function() q.Slot():List({ "a" }, "label") end,
	fix = function() local s = q.Slot(); s:List({ "a" }, function(ctx) return label(ctx.Item) end); local f = D.Frame({ s }); return kids(f) == 1, "children=" .. kids(f) end })
R.case({ id = "Quad0151",
	trigger = function() q.Slot():List(q.Store({ x = q.Source("a") }), function(ctx) return label(ctx.Item) end) end,
	fix = function() local s = q.Slot(); s:List(q.Source({ "a" }), function(ctx) if gone(ctx.Item) then return nil end return label(ctx.Item) end); local f = D.Frame({ s }); return kids(f) == 1, "children=" .. kids(f) end })
R.case({ id = "Quad0152", note = "a: pass function",
	trigger = function() q.Slot():List({ { id = 1 } }, function(ctx) return label() end, "id") end,
	fix = function() local s = q.Slot(); s:List({ { id = 1 } }, function(ctx) return label() end, function(x) return x.id end); local f = D.Frame({ s }); return kids(f) == 1, "a children=" .. kids(f) end })
R.case({ id = "Quad0152", note = "b: omit",
	trigger = function() q.Slot():List({ { id = 1 } }, function(ctx) return label() end, "id") end,
	fix = function() local s = q.Slot(); s:List({ { id = 1 } }, function(ctx) return label() end); local f = D.Frame({ s }); return kids(f) == 1, "b children=" .. kids(f) end })
R.case({ id = "Quad0153",
	trigger = function() q.Slot():List({ "a" }, function(ctx) return label() end, nil, "OwnsElements") end,
	fix = function()
		local s = q.Slot(); local el
		s:List({ "a" }, function(ctx) if gone(ctx.Item) then return nil end el = label(); return el end, nil, { OwnsElements = false })
		local f = D.Frame({ s }); return kids(f) == 1, "children=" .. kids(f)
	end })
R.case({ id = "Quad0154", note = "a: pass function",
	trigger = function() q.Slot():Single(q.Source("a"), "label") end,
	fix = function() local s = q.Slot(); s:Single(q.Source("a"), function(ctx) if gone(ctx.Item) then return nil end return label(ctx.Item) end); local f = D.Frame({ s }); return kids(f) == 1, "a children=" .. kids(f) end })
R.case({ id = "Quad0154", note = "b: omit (identity) — state must then hold the element",
	trigger = function() q.Slot():Single(q.Source(label()), 5) end,
	fix = function() local s = q.Slot(); s:Single(q.Source(label())); local f = D.Frame({ s }); return kids(f) == 1, "b children=" .. kids(f) end })
R.case({ id = "Quad0155",
	trigger = function() q.Slot():Single(q.Source(label()), nil, true) end,
	fix = function() local s = q.Slot(); s:Single(q.Source(label()), nil, { OwnsElements = false }); local f = D.Frame({ s }); return kids(f) == 1, "children=" .. kids(f) end })

-- ── Quad0156 ─────────────────────────────────────────────
R.case({ id = "Quad0156", note = "a: element held by a manual Slot; fix = Extract first",
	trigger = function()
		local el = label(); local a = q.Slot({ el }); D.Frame({ a })
		local s = q.Slot(); s:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end return el end); D.Frame({ s })
	end,
	fix = function()
		local el = label(); local a = q.Slot({ el }); D.Frame({ a })
		a:Extract(1)
		local s = q.Slot(); s:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end return el end); local f = D.Frame({ s })
		return el.Parent == f and a.Length:Get() == 0, "moved=" .. tostring(el.Parent == f)
	end })
R.case({ id = "Quad0156", note = "b: same element for two keys — 'extract from old seat' has nothing to extract",
	trigger = function()
		local el = label(); local s = q.Slot(); s:List({ 1, 2 }, function(ctx) if gone(ctx.Item) then return nil end return el end); D.Frame({ s })
	end,
	fix = function()
		-- literal: take it out of the old seat — the old seat is key 1 of this same List, reachable only as s:Extract (manual CRUD) -> expect 0166
		local el = label(); local s = q.Slot()
		s:List({ 1, 2 }, function(ctx)
			if gone(ctx.Item) then return nil end
			if ctx.Item == 2 then s:Extract(1) end
			return el
		end)
		D.Frame({ s })
		return true, "no error?"
	end })
R.case({ id = "Quad0156", note = "c: updateFn returns its own Slot",
	trigger = function()
		local s = q.Slot(); s:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end return s end); D.Frame({ s })
	end,
	fixnote = "self-return is a cycle; the prescription (take it out of the old seat) does not apply — see notes" })

-- ── Quad0157..0163 Bookkeeping (extension API) ──────────
local BK = q.Bookkeeping
R.case({ id = "Quad0157",
	trigger = function() BK.claimOwnerAt(nil, D.Frame({}), 1) end,
	fix = function() local el, p = label(), D.Frame({}); local r = BK.claimOwnerAt(el, p, 1); BK.releaseOwner(el, p); return r == true, "claim=" .. tostring(r) end })
R.case({ id = "Quad0158",
	trigger = function() BK.claimOwnerAt(label(), nil, 1) end,
	fix = function() local el, p = label(), D.Frame({}); local r = BK.claimOwnerAt(el, p, 1); BK.releaseOwner(el, p); return r == true, "claim=" .. tostring(r) end })
R.case({ id = "Quad0159",
	trigger = function() BK.claimOwnerAt(label(), D.Frame({}), nil) end,
	fix = function() local el, p = label(), D.Frame({}); local r = BK.claimOwnerAt(el, p, "Child"); BK.releaseOwner(el, p); return r == true, "claim=" .. tostring(r) end })
R.case({ id = "Quad0160",
	trigger = function() local el = label(); BK.claimOwnerAt(el, D.Frame({}), 1); BK.claimOwnerAt(el, D.Frame({}), 1) end,
	fix = function()
		local el, p1, p2 = label(), D.Frame({}), D.Frame({})
		BK.claimOwnerAt(el, p1, 1); BK.releaseOwner(el, p1)
		local r = BK.claimOwnerAt(el, p2, 1); BK.releaseOwner(el, p2)
		return r == true, "reclaim=" .. tostring(r)
	end })
R.case({ id = "Quad0160", note = "b: static child re-placed into another static seat (public path)",
	trigger = function() local el = label(); D.Frame({ el }); D.Frame({ el }) end,
	fixnote = "see Quad0172 b (no public API to take a literal static child off its seat)" })
R.case({ id = "Quad0161",
	trigger = function() BK.releaseOwner(nil, D.Frame({})) end,
	fix = function() local el, p = label(), D.Frame({}); BK.claimOwnerAt(el, p, 1); BK.releaseOwner(el, p); local r = BK.claimOwnerAt(el, D.Frame({}), 1); return r == true, "released" end })
R.case({ id = "Quad0162",
	trigger = function() BK.releaseOwner(label(), nil) end,
	fix = function() local el, p = label(), D.Frame({}); BK.claimOwnerAt(el, p, 1); BK.releaseOwner(el, p); local r = BK.claimOwnerAt(el, D.Frame({}), 1); return r == true, "released" end })
R.case({ id = "Quad0163",
	trigger = function() local el, p = label(), D.Frame({}); BK.claimOwnerAt(el, p, 1); BK.releaseOwner(el, D.Frame({})) end,
	fix = function() local el, p = label(), D.Frame({}); BK.claimOwnerAt(el, p, 1); BK.releaseOwner(el, p); local r = BK.claimOwnerAt(el, D.Frame({}), 1); return r == true, "released" end })


-- ── Quad0164 (try: host disposed mid-walk, before a sibling nested Slot is materialized) ──
R.case({ id = "Quad0164", note = "host q.dispose'd from a nested :List updateFn while outer walk pending",
	trigger = function()
		local F = D.Frame({})
		local outer = q.Slot()
		local innerA = q.Slot(); innerA:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end q.dispose(F); return label() end)
		local innerB = q.Slot({ label() })
		outer:Add(innerA); outer:Add(innerB)
		q.Dispatch.drive(F, { outer })
	end,
	fix = function()
		local F = D.Frame({})
		local outer = q.Slot({ q.Slot({ label() }), q.Slot({ label() }) })
		q.Dispatch.drive(F, { outer })
		return kids(F) == 2, "children=" .. kids(F)
	end })
R.case({ id = "Quad0164", note = "b: host disposed from Observer fired during mount (State Set in updateFn)",
	trigger = function()
		local F = D.Frame({})
		local kill = q.Source(false)
		local obs = kill:Observer(function() if kill:Get() then q.dispose(F) end end)
		H.q.Backend.bindLifetime(D.Frame({}), obs)
		local outer = q.Slot()
		local innerA = q.Slot(); innerA:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end kill:Set(true); return label() end)
		outer:Add(innerA); outer:Add(q.Slot({ label() }))
		q.Dispatch.drive(F, { outer })
	end,
	fixnote = "same as a" })

-- ── Quad0165 ─────────────────────────────────────────────
R.case({ id = "Quad0165",
	trigger = function() local s = q.Slot({ label() }); q.dispose(s); s:Add(label()) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); q.dispose(f); local s2 = q.Slot({ label(), label() }); local g = D.Frame({ s2 }); return kids(g) == 2, "new slot children=" .. kids(g) end })

-- ── Quad0166 ─────────────────────────────────────────────
R.case({ id = "Quad0166", note = "a: via the data State",
	trigger = function() local s = q.Slot(); s:List({ "a" }, function(ctx) return label(ctx.Item) end); D.Frame({ s }); s:Add(label("b")) end,
	fix = function()
		local data = q.Source({ "a" }); local s = q.Slot()
		s:List(data, function(ctx) if gone(ctx.Item) then return nil end return ctx.Prev or label(ctx.Item) end, function(x) return x end)
		local f = D.Frame({ s }); local d = table.clone(data:Get()); table.insert(d, "b"); data:Set(d)
		return kids(f) == 2, "a children=" .. kids(f)
	end })
R.case({ id = "Quad0166", note = "b: plain-array data (not a State) — 'change the data State' has no State to change",
	trigger = function() local s = q.Slot(); s:List({ "a" }, function(ctx) return label(ctx.Item) end); D.Frame({ s }); s:Add(label("b")) end,
	fix = function()
		-- literal second branch: new Slot without the install, manual CRUD
		local s = q.Slot(); local f = D.Frame({ s }); s:Add(label("a")); s:Add(label("b"))
		return kids(f) == 2, "b children=" .. kids(f)
	end })

-- ── Quad0167 ─────────────────────────────────────────────
local function nestedOuter(onUpdate)
	local outer = q.Slot()
	local inner = q.Slot(); inner:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end onUpdate(outer); return label("i") end)
	outer:Add(inner)
	return outer
end
R.case({ id = "Quad0167", note = "a: fix = do it after the mount",
	trigger = function() local outer = nestedOuter(function(o) o:Add(label("x")) end); D.Frame({ outer }) end,
	fix = function() local outer = nestedOuter(function() end); local f = D.Frame({ outer }); outer:Add(label("x")); return kids(f) == 2, "a children=" .. kids(f) end })
R.case({ id = "Quad0167", note = "b: fix = 'from an Observer' whose State is Set inside updateFn",
	trigger = function() local outer = nestedOuter(function(o) o:Add(label("x")) end); D.Frame({ outer }) end,
	fix = function()
		local want = q.Source(false)
		local outerRef
		local obs = want:Observer(function() if want:Get() then outerRef:Add(label("x")) end end)
		q.Backend.bindLifetime(D.Frame({}), obs)
		local outer = nestedOuter(function() want:Set(true) end); outerRef = outer
		local f = D.Frame({ outer })
		return kids(f) == 2, "b children=" .. kids(f)
	end })
R.case({ id = "Quad0167", note = "c: 'earlier mount threw' — recovery = q.dispose the host (Dispatch.drive form: host reachable)",
	trigger = function()
		local F = D.Frame({})
		local outer = q.Slot()
		local inner = q.Slot(); inner:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end error("boom") end)
		outer:Add(inner)
		pcall(q.Dispatch.drive, F, { outer })
		outer:Add(label("x"))
	end,
	fix = function()
		local F = D.Frame({})
		local outer = q.Slot()
		local inner = q.Slot(); inner:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end error("boom") end)
		outer:Add(inner)
		pcall(q.Dispatch.drive, F, { outer })
		q.dispose(F)
		local s2 = q.Slot({ label() }); local g = D.Frame({ s2 })
		return kids(g) == 1, "host disposed; rebuilt children=" .. kids(g)
	end })
R.case({ id = "Quad0167", note = "d: 'earlier mount threw' inside D.Frame { outer } — host never returned",
	trigger = function()
		local outer = q.Slot()
		local inner = q.Slot(); inner:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end error("boom") end)
		outer:Add(inner)
		pcall(D.Frame, { outer })
		outer:Add(label("x"))
	end,
	fix = function()
		local outer = q.Slot()
		local inner = q.Slot(); inner:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end error("boom") end)
		outer:Add(inner)
		local ok, host = pcall(D.Frame, { outer })
		-- literal: q.dispose its host Instance — which one? pcall returned the error, not the host
		local p = outer._physicalTarget
		local okd, e = pcall(q.dispose, p)
		return okd and p ~= nil, "host via public API unavailable (pcall ret=" .. tostring(host):sub(1, 40) .. "); internal target dispose ok=" .. tostring(okd) .. " " .. tostring(e)
	end })

-- ── Quad0168 / Quad0236 ─────────────────────────────────
R.case({ id = "Quad0168",
	trigger = function() local s = q.Slot({ label() }); D.Frame({ s }); s:Remove(0) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); s:Remove(1); return kids(f) == 0, "children=" .. kids(f) end })
R.case({ id = "Quad0236",
	trigger = function() local s = q.Slot({ label() }); D.Frame({ s }); s:Remove(2) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); s:Remove(s.Length:Get()); return kids(f) == 0, "children=" .. kids(f) end })
R.case({ id = "Quad0236", note = "b: Add at n+2",
	trigger = function() local s = q.Slot({ label() }); D.Frame({ s }); s:Add(label(), 3) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); s:Add(label(), 2); return kids(f) == 2, "b children=" .. kids(f) end })

-- ── Quad0169 ─────────────────────────────────────────────
R.case({ id = "Quad0169",
	trigger = function() local d = q.Slot(); q.dispose(d); q.Slot():Add(q.Source(d)) end,
	fix = function() local s = q.Slot(); local f = D.Frame({ s }); s:Add(q.Source(q.Slot({ label() }))); return kids(f) == 1, "children=" .. kids(f) end })

-- ── Quad0170 ─────────────────────────────────────────────
R.case({ id = "Quad0170", note = "re-add to move to end; fix = Move",
	trigger = function() local a, b = label("a"), label("b"); local s = q.Slot({ a, b }); D.Frame({ s }); s:Add(s:Get(1)) end,
	fix = function()
		local a, b = label("a"), label("b"); local s = q.Slot({ a, b }); D.Frame({ s }); s:Move(1, 2)
		return s:Get(1) == b and s:Get(2) == a, "order=" .. s:Get(1).Text .. s:Get(2).Text
	end })
R.case({ id = "Quad0170", note = "b: Replace(i, Get(i)) — intent is a no-op",
	trigger = function() local s = q.Slot({ label() }); s:Replace(1, s:Get(1)) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); return kids(f) == 1, "just don't call it; children=" .. kids(f) end })

-- ── Quad0171 ─────────────────────────────────────────────
R.case({ id = "Quad0171",
	trigger = function() local a = label(); q.Slot({ a, a }) end,
	fix = function() local s = q.Slot({ label(), label() }); local f = D.Frame({ s }); return kids(f) == 2, "children=" .. kids(f) end })

-- ── Quad0172 ─────────────────────────────────────────────
R.case({ id = "Quad0172", note = "a: held by another manual Slot; fix = Extract first",
	trigger = function() local el = label(); local a = q.Slot({ el }); D.Frame({ a }); q.Slot():Add(el) end,
	fix = function()
		local el = label(); local a = q.Slot({ el }); D.Frame({ a })
		a:Extract(1); local s = q.Slot(); local f = D.Frame({ s }); s:Add(el)
		return el.Parent == f, "moved=" .. tostring(el.Parent == f)
	end })
R.case({ id = "Quad0172", note = "b: literal static child D.Frame{ el } — how to take it off?",
	trigger = function() local el = label(); D.Frame({ el }); q.Slot():Add(el) end,
	fix = function()
		local el = label(); local host = D.Frame({ el })
		el.Parent = nil -- the only 'take it out' a user has for a literal static child
		local s = q.Slot(); local f = D.Frame({ s }); s:Add(el)
		return el.Parent == f, "moved=" .. tostring(el.Parent == f)
	end })
R.case({ id = "Quad0172", note = "c: static child via State seat; fix = Set(nil) then Add",
	trigger = function() local el = label(); D.Frame({ q.Source(el) }); q.Slot():Add(el) end,
	fix = function()
		local el = label(); local st = q.Source(el); D.Frame({ st }); st:Set(nil)
		local s = q.Slot(); local f = D.Frame({ s }); s:Add(el)
		return el.Parent == f, "moved=" .. tostring(el.Parent == f)
	end })

-- ── Quad0173 ─────────────────────────────────────────────
R.case({ id = "Quad0173",
	trigger = function() local a = q.Slot(); local b = q.Slot({ a }); a:Add(b) end,
	fix = function() local a = q.Slot({ label() }); local b = q.Slot({ a }); local f = D.Frame({ b }); return kids(f) == 1, "acyclic children=" .. kids(f) end })

-- ── Quad0174 ─────────────────────────────────────────────
R.case({ id = "Quad0174",
	trigger = function() local s = q.Slot({ label(), label() }); D.Frame({ s }); s:Splice(2, 5) end,
	fix = function() local s = q.Slot({ label(), label() }); local f = D.Frame({ s }); s:Splice(2, s.Length:Get() - 2 + 1); return kids(f) == 1, "children=" .. kids(f) end })
R.case({ id = "Quad0174", note = "b: removeCount omitted",
	trigger = function() local s = q.Slot({ label() }); s:Splice(1) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); s:Splice(1, 1); return kids(f) == 0, "b children=" .. kids(f) end })

-- ── Quad0175 ─────────────────────────────────────────────
R.case({ id = "Quad0175",
	trigger = function() local s = q.Slot({ label() }); s:Get("1") end,
	fix = function() local el = label(); local s = q.Slot({ el }); return s:Get(1) == el and s:Get(5) == nil, "Get(1) ok, Get(5)=nil" end })

-- ── Quad0176 / 0177 ─────────────────────────────────────
R.case({ id = "Quad0176",
	trigger = function() q.Slot(label()) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); return kids(f) == 1, "children=" .. kids(f) end })
R.case({ id = "Quad0177",
	trigger = function() q.Slot({ header = label() }) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); return kids(f) == 1, "children=" .. kids(f) end })

-- ── Quad0178 ─────────────────────────────────────────────
R.case({ id = "Quad0178",
	trigger = function() q.dispose(nil) end,
	fix = function() local f = D.Frame({}); q.dispose(f); return f._destroyed == true or f.Parent == nil, "disposed" end })

-- ── Quad0179 ─────────────────────────────────────────────
local function isDead(x) return x._destroyed == true or x.__destroyed == true end
R.case({ id = "Quad0179", note = "a: manual Slot — Extract then dispose",
	trigger = function() local el = label(); local s = q.Slot({ el }); D.Frame({ s }); q.dispose(el) end,
	fix = function() local el = label(); local s = q.Slot({ el }); local f = D.Frame({ s }); s:Extract(1); q.dispose(el); return kids(f) == 0, "a children=" .. kids(f) end })
R.case({ id = "Quad0179", note = "a2: manual Slot — Remove then dispose",
	trigger = function() local el = label(); local s = q.Slot({ el }); D.Frame({ s }); q.dispose(el) end,
	fix = function() local el = label(); local s = q.Slot({ el }); local f = D.Frame({ s }); s:Remove(1); q.dispose(el); return kids(f) == 0, "a2 children=" .. kids(f) end })
R.case({ id = "Quad0179", note = "b: :List — drop key then dispose",
	trigger = function()
		local data = q.Source({ "a" }); local s = q.Slot(); local el
		s:List(data, function(ctx) if gone(ctx.Item) then return nil end el = ctx.Prev or label(ctx.Item); return el end)
		D.Frame({ s }); q.dispose(el)
	end,
	fix = function()
		local data = q.Source({ "a" }); local s = q.Slot(); local el
		s:List(data, function(ctx) if gone(ctx.Item) then return nil end el = ctx.Prev or label(ctx.Item); return el end)
		local f = D.Frame({ s }); data:Set({}); q.dispose(el)
		return kids(f) == 0, "b children=" .. kids(f)
	end })
R.case({ id = "Quad0179", note = "b2: :List Detach-held element — destroy the owner Slot",
	trigger = function()
		local data = q.Source({ "a" }); local s = q.Slot(); local el
		s:List(data, function(ctx) if gone(ctx.Item) then return q.Detach end el = ctx.Prev or label(ctx.Item); return el end)
		D.Frame({ s }); data:Set({}); q.dispose(el)
	end,
	fix = function()
		local data = q.Source({ "a" }); local s = q.Slot(); local el
		s:List(data, function(ctx) if gone(ctx.Item) then return q.Detach end el = ctx.Prev or label(ctx.Item); return el end)
		local f = D.Frame({ s }); data:Set({})
		-- literal: destroy the owner Slot — the Slot is mounted in f; q.dispose(s) itself is 0179 (held at numeric seat)
		local ok, e = pcall(q.dispose, s)
		return ok, "dispose(owner Slot) ok=" .. tostring(ok) .. " " .. R.first(tostring(e)):sub(1, 120)
	end })
R.case({ id = "Quad0179", note = "b3: Detach-held element — alternative: q.dispose the host (not in the page)",
	trigger = function()
		local data = q.Source({ "a" }); local s = q.Slot(); local el
		s:List(data, function(ctx) if gone(ctx.Item) then return q.Detach end el = ctx.Prev or label(ctx.Item); return el end)
		D.Frame({ s }); data:Set({}); q.dispose(el)
	end,
	fix = function()
		local data = q.Source({ "a" }); local s = q.Slot(); local el
		s:List(data, function(ctx) if gone(ctx.Item) then return q.Detach end el = ctx.Prev or label(ctx.Item); return el end)
		local f = D.Frame({ s }); data:Set({})
		q.dispose(f)
		local dead = R.raises(function() q.Slot():Add(el) end, "Quad0241")
		return dead, "host dispose killed detached el (Add -> 0241): " .. tostring(dead)
	end })
R.case({ id = "Quad0179", note = "b4: Detach-held, owner Slot at a State seat — Set(nil) then dispose(owner Slot)",
	trigger = function()
		local data = q.Source({ "a" }); local s = q.Slot(); local el
		s:List(data, function(ctx) if gone(ctx.Item) then return q.Detach end el = ctx.Prev or label(ctx.Item); return el end)
		D.Frame({ q.Source(s) }); data:Set({}); q.dispose(el)
	end,
	fix = function()
		local data = q.Source({ "a" }); local s = q.Slot(); local el
		s:List(data, function(ctx) if gone(ctx.Item) then return q.Detach end el = ctx.Prev or label(ctx.Item); return el end)
		local st = q.Source(s); D.Frame({ st }); data:Set({})
		st:Set(nil); q.dispose(s)
		local dead = R.raises(function() q.Slot():Add(el) end, "Quad0241")
		return dead, "owner Slot disposed; detached el dead: " .. tostring(dead)
	end })
R.case({ id = "Quad0179", note = "c: numeric-key State seat — Set(nil) then dispose",
	trigger = function() local el = label(); D.Frame({ q.Source(el) }); q.dispose(el) end,
	fix = function() local el = label(); local st = q.Source(el); local f = D.Frame({ st }); st:Set(nil); q.dispose(el); return kids(f) == 0, "c children=" .. kids(f) end })
R.case({ id = "Quad0179", note = "c2: literal static child (no State) — page gives no branch",
	trigger = function() local el = label(); D.Frame({ el }); q.dispose(el) end,
	fixnote = "no prescribed branch for a literal static child" })
R.case({ id = "Quad0179", note = "d: shorthand-managed child — set its key to nil",
	trigger = function() local f = D.Frame({ UICorner = 8 }); local c = f:FindFirstChild("_quad_round"); assert(c, "no shorthand child"); q.dispose(c) end,
	fix = function()
		local st = q.Source(8); local f = D.Frame({ UICorner = st }); local c = f:FindFirstChild("_quad_round")
		st:Set(nil)
		local ok, e = pcall(q.dispose, c)
		return ok and f:FindFirstChild("_quad_round") == nil, "after key nil: dispose ok=" .. tostring(ok) .. " " .. R.first(tostring(e)):sub(1, 100)
	end })

-- ── Quad0180 ─────────────────────────────────────────────
R.case({ id = "Quad0180", note = "a: plain table",
	trigger = function() q.dispose({}) end,
	fix = function() local s = q.Slot({ label() }); q.dispose(s); return s._destroyed == true, "slot disposed" end })
R.case({ id = "Quad0180", note = "b: a State (user wanted to dispose a State)",
	trigger = function() q.dispose(q.Source(1)) end,
	fixnote = "page gives no path for a State — see notes" })

-- ── Quad0238..0242 ──────────────────────────────────────
R.case({ id = "Quad0238",
	trigger = function() q.Slot():Add(q.Ref()) end,
	fix = function() local ref = q.Ref(); local el = D.TextLabel({ Text = "x", ref }); local s = q.Slot(); local f = D.Frame({ s }); s:Add(el); return ref.Value == el and kids(f) == 1, "ref.Value==el " .. tostring(ref.Value == el) end })
R.case({ id = "Quad0238", note = "b: Observer as element in :List",
	trigger = function() local st = q.Source(1); local s = q.Slot(); s:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end return st:Observer(function() end) end); D.Frame({ s }) end,
	fix = function()
		local st = q.Source(1); local hits = 0; local s = q.Slot()
		s:List({ 1 }, function(ctx) if gone(ctx.Item) then return nil end return D.TextLabel({ st:Observer(function() hits += 1 end) }) end)
		local f = D.Frame({ s }); st:Set(2)
		return kids(f) == 1 and hits >= 1, "b observer hits=" .. hits
	end })
R.case({ id = "Quad0239", note = "Add(None)",
	trigger = function() q.Slot({ label() }):Add(q.None) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); s:Remove(1); return kids(f) == 0, "children=" .. kids(f) end })
R.case({ id = "Quad0239", note = "b: Replace(i, nil) to empty a position",
	trigger = function() local s = q.Slot({ label() }); s:Replace(1, nil) end,
	fix = function() local s = q.Slot({ label() }); local f = D.Frame({ s }); local x = s:Extract(1); return kids(f) == 0 and x ~= nil, "b extract children=" .. kids(f) end })
R.case({ id = "Quad0240",
	trigger = function() q.Slot():Add("hello") end,
	fix = function() local s = q.Slot(); local f = D.Frame({ s }); s:Add(label("hello")); return kids(f) == 1, "children=" .. kids(f) end })
R.case({ id = "Quad0241", note = "a: Declaration",
	trigger = function() q.Slot():Add(Mock.Instance.new("Frame")) end,
	fix = function() local s = q.Slot(); local f = D.Frame({ s }); s:Add(D.Frame({})); return kids(f) == 1, "a children=" .. kids(f) end })
R.case({ id = "Quad0241", note = "b: Claim first",
	trigger = function() q.Slot():Add(Mock.Instance.new("Frame")) end,
	fix = function()
		local raw = Mock.Instance.new("Frame")
		local root = q.Claim(raw, D.Mapper.Frame(D.Mapper.Root)({}))
		local s = q.Slot(); local f = D.Frame({ s }); s:Add(root)
		return root == raw and raw.Parent == f, "b claimed root==raw " .. tostring(root == raw) .. " parent ok " .. tostring(raw.Parent == f)
	end })
R.case({ id = "Quad0241", note = "c: destroyed Instance",
	trigger = function() local fr = D.Frame({}); q.dispose(fr); q.Slot():Add(fr) end,
	fix = function() local s = q.Slot(); local f = D.Frame({ s }); s:Add(D.Frame({})); return kids(f) == 1, "c new children=" .. kids(f) end })
R.case({ id = "Quad0242",
	trigger = function() local d = q.Slot(); q.dispose(d); q.Slot():Add(d) end,
	fix = function() local s = q.Slot(); local f = D.Frame({ s }); s:Add(q.Slot({ label() })); return kids(f) == 1, "children=" .. kids(f) end })

R.done()
