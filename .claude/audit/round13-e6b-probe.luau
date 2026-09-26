--!nocheck
-- 재현: quad-roblox/test/로 복사한 뒤 ./scripts/relink.sh && luau quad-roblox/test/probe.e6b.luau (2026-09-27 E6-2)
-- E6-2 scratch probe (round13) — Claim/Mapper depth, Slot inside claimed tree, Attr/Tag on claimed, dispose/destroy, descriptor reuse
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local installEngineOps = require("../src/EngineOps")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance

local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "BackgroundTransparency", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
	ImageLabel = { { Name = "Name", Permits = W }, { Name = "Image", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installEvent)).game = gameShim
;(getfenv(installEngineOps)).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local M = q.Declaration.Mapper
local D = q.Declaration

local function try(label, f)
	local ok, err = pcall(f)
	print(label, ok, ok and "" or tostring(err))
	return ok
end
local function claimed(x) return q.Backend.isClaimed(x) end
local function tags(i) local t = mock.getTags(i); table.sort(t); return table.concat(t, ",") end
local function mk(class, name, parent)
	local i = Instance.new(class); i.Name = name; if parent then i.Parent = parent end; return i
end

-- depth-4 chain template: Root(Frame) > A(Frame) > B(Frame) > C(Frame) > Leaf(TextLabel)
local function chain()
	local r = mk("Frame", "Root")
	local a = mk("Frame", "A", r)
	local b = mk("Frame", "B", a)
	local c = mk("Frame", "C", b)
	local leaf = mk("TextLabel", "Leaf", c)
	return r, a, b, c, leaf
end
local function allClaimed(...)
	local out = {}
	for _, x in { ... } do table.insert(out, tostring(claimed(x))) end
	return table.concat(out, ",")
end

print("=== N1 depth 4 success ===")
do
	local r, a, b, c, leaf = chain()
	try("N1", function()
		q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.Frame("B")({ M.Frame("C")({ M.TextLabel("Leaf")({ Text = "deep" }) }), BackgroundTransparency = 0.3 }) }) }))
	end)
	print("N1 claimed r,a,b,c,leaf", allClaimed(r, a, b, c, leaf), "Text", leaf.Text, "B.BT", b.BackgroundTransparency)
	print("N1 offsets a@1", q.Bookkeeping.getOffsetAt(a, 1), "c pos2 offset", q.Bookkeeping.getOffsetAt(c, 2))
end

print("=== N2 depth 4 class mismatch at leaf -> nothing claimed/applied ===")
do
	local r, a, b, c, leaf = chain()
	local dLeaf = M.ImageLabel("Leaf")({ Image = "x" })
	local dB = M.Frame("B")({ M.Frame("C")({ dLeaf }), BackgroundTransparency = 0.3 })
	local root = M.Frame(M.Root)({ M.Frame("A")({ dB }), BackgroundTransparency = 0.9 })
	try("N2", function() q.Claim(r, root) end)
	print("N2 claimed", allClaimed(r, a, b, c, leaf), "BT r,b", r.BackgroundTransparency, b.BackgroundTransparency, "fired root,B,leaf", root._fired, dB._fired, dLeaf._fired, "B props[1] is desc", q.isMapperDescriptor and q.isMapperDescriptor(dB._props[1]))
	-- fixed retry with fresh descriptor
	try("N2 retry", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.Frame("B")({ M.Frame("C")({ M.TextLabel("Leaf")({ Text = "ok" }) }) }) }) })) end)
	print("N2 retry leaf", leaf.Text, allClaimed(r, a, b, c, leaf))
end

print("=== N3 depth 3 missing name / wrong name at depth 3 ===")
do
	local r, a, b, c, leaf = chain()
	try("N3", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.Frame("B")({ M.Frame("Nope")({}) }) }) })) end)
	print("N3 claimed", allClaimed(r, a, b, c, leaf))
end

print("=== N4 same descriptor at two depths (depth1 and depth3) ===")
do
	local r = mk("Frame", "Root")
	local a = mk("Frame", "A", r)
	local x = mk("TextLabel", "X", r)
	local b = mk("Frame", "B", a)
	local x2 = mk("TextLabel", "X", b)
	local dx = M.TextLabel("X")({ Text = "shared" })
	try("N4", function() q.Claim(r, M.Frame(M.Root)({ dx, M.Frame("A")({ M.Frame("B")({ dx }) }) })) end)
	print("N4 claimed", allClaimed(r, a, x, b, x2), "fired", dx._fired)
end

print("=== N5 deep child already claimed (D.Frame parked in template at depth 3) ===")
do
	local r, a, b = chain()
	local made = D.TextLabel({ Name = "Made" })
	made.Parent = b -- parked outside quad bookkeeping (template authoring)
	try("N5", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.Frame("B")({ M.TextLabel("Made")({ Text = "m" }) }) }) })) end)
	print("N5 claimed r,a,b", allClaimed(r, a, b))
end

print("=== N6 same name twice at depth 2 (UB §3) + class filter picks? ===")
do
	local r = mk("Frame", "Root")
	local a = mk("Frame", "A", r)
	local k1 = mk("ImageLabel", "K", a)
	local k2 = mk("TextLabel", "K", a)
	try("N6 TextLabel K (second child)", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.TextLabel("K")({ Text = "t" }) }) })) end)
	print("N6 claimed r,a,k1,k2", allClaimed(r, a, k1, k2))
	-- two descriptors same name same class at depth 2
	local r2 = mk("Frame", "Root")
	local a2 = mk("Frame", "A", r2)
	local j1 = mk("TextLabel", "J", a2)
	local j2 = mk("TextLabel", "J", a2)
	try("N6b two descs 'J'", function() q.Claim(r2, M.Frame(M.Root)({ M.Frame("A")({ M.TextLabel("J")({}), M.TextLabel("J")({}) }) })) end)
	print("N6b claimed", allClaimed(r2, a2, j1, j2))
end

print("=== N7 depth-3 props gate/[0] key/drive throw at deepest ===")
do
	local r, a, b, c, leaf = chain()
	try("N7a non-table props at depth 4", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.Frame("B")({ M.Frame("C")(5) }) }) })) end)
	print("N7a claimed", allClaimed(r, a, b, c, leaf))
	try("N7b [0]=desc at depth 3", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.Frame("B")({ [0] = M.Frame("C")({}) }) }) })) end)
	print("N7b claimed", allClaimed(r, a, b, c, leaf))
	try("N7c bad prop at depth 4 (drive)", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.Frame("B")({ M.Frame("C")({ M.TextLabel("Leaf")({ Nope = 1 }) }) }) }), BackgroundTransparency = 0.7 })) end)
	print("N7c claimed", allClaimed(r, a, b, c, leaf), "r BT", r.BackgroundTransparency)
end

print("=== N8 depth: descriptor under a D.Frame inside a Mapper (New child holding a mapper desc) ===")
do
	local r = mk("Frame", "Root")
	try("N8", function() q.Claim(r, M.Frame(M.Root)({ D.Frame({ M.TextLabel("X")({}) }) })) end)
	print("N8 r claimed", claimed(r))
end

------------------------------------------------------------ Slot in claimed tree
-- physical oracle: phys list per parent, fed by native* ops
local phys = setmetatable({}, { __mode = "k" })
local violations = {}
local function nm(e) return e and e.Name or "nil" end
local B = q.Backend
local oIns, oExt, oRem, oMove, oSwap = B.nativeInsert, B.nativeExtract, B.nativeRemove, B.nativeMove, B.nativeSwap
local function P(t) phys[t] = phys[t] or {}; return phys[t] end
local function takeAt(t, off, els, op)
	local l = P(t)
	for k, e in ipairs(els) do if l[off + k] ~= e then table.insert(violations, `{op}: expected {nm(e)} at {off + k} got {nm(l[off + k])}`) end end
	for _, e in ipairs(els) do local i = table.find(l, e); if i then table.remove(l, i) end end
end
local function putAt(t, off, els, op)
	local l = P(t)
	if off < 0 or off > #l then table.insert(violations, `{op}: offset {off} out of [0,{#l}]`); off = math.clamp(off, 0, #l) end
	for k, e in ipairs(els) do table.insert(l, off + k, e) end
end
B.nativeInsert = function(t, off, els) putAt(t, off, els, "insert"); oIns(t, off, els) end
B.nativeExtract = function(t, off, els, new) takeAt(t, off, els, "extract"); if new then putAt(t, off, new, "extract/new") end; oExt(t, off, els, new) end
B.nativeRemove = function(t, off, els, new) takeAt(t, off, els, "remove"); if new then putAt(t, off, new, "remove/new") end; oRem(t, off, els, new) end
B.nativeMove = function(t, fo, els, to) takeAt(t, fo, els, "move"); putAt(t, to, els, "move/to"); oMove(t, fo, els, to) end
B.nativeSwap = function(t, oa, ea, ob, eb)
	local l = P(t)
	local before = table.move(l, 1, oa, 1, {})
	for k, e in ipairs(ea) do if l[oa + k] ~= e then table.insert(violations, `swapA @{oa + k} {nm(e)} got {nm(l[oa + k])}`) end end
	for k, e in ipairs(eb) do if l[ob + k] ~= e then table.insert(violations, `swapB @{ob + k} {nm(e)} got {nm(l[ob + k])}`) end end
	local mid = table.move(l, oa + #ea + 1, ob, 1, {})
	local after = table.move(l, ob + #eb + 1, #l, 1, {})
	local out = {}
	for _, x in before do table.insert(out, x) end
	for _, x in eb do table.insert(out, x) end
	for _, x in mid do table.insert(out, x) end
	for _, x in ea do table.insert(out, x) end
	for _, x in after do table.insert(out, x) end
	phys[t] = out
	oSwap(t, oa, ea, ob, eb)
end
local function physStr(t) local o = {}; for _, e in P(t) do table.insert(o, nm(e)) end; return table.concat(o, " ") end
-- model: statics + slot elements in descriptor order
local function modelStr(layout)
	local o = {}
	for _, x in layout do
		if type(x) == "table" and x.Get then for i = 1, x.Length:Get() do table.insert(o, nm(x:Get(i))) end else table.insert(o, nm(x)) end
	end
	return table.concat(o, " ")
end
local function check(label, parent, layout)
	local p, m = physStr(parent), modelStr(layout)
	print(label, p == m and "OK" or "MISMATCH", "phys:", p, "| model:", m, "#viol", #violations)
	if #violations > 0 then for _, v in violations do print("   viol:", v) end; table.clear(violations) end
end

local function item(n) return D.TextLabel({ Name = n }) end

print("=== S1 manual Slot between claimed template siblings ===")
do
	local r = mk("Frame", "Root")
	local top = mk("TextLabel", "Top", r)
	local bot = mk("TextLabel", "Bot", r)
	phys[r] = { top } -- descriptor order: Top, [slot], Bot ; bot seeded after claim
	local s = q.Slot({ item("s1"), item("s2") })
	-- seed bot BEFORE claim so oracle has Top, Bot and slot inserts between
	phys[r] = { top, bot }
	try("S1 claim", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Top")({}), s, M.TextLabel("Bot")({}) })) end)
	check("S1 after claim", r, { top, s, bot })
	print("S1 offsets pos2", q.Bookkeeping.getOffsetAt(r, 2), "pos3", q.Bookkeeping.getOffsetAt(r, 3))
	s:Add(item("s3"))
	s:Add(item("s0"), 1)
	check("S1 add", r, { top, s, bot })
	s:Move(1, 3)
	s:Swap(1, 4)
	check("S1 move/swap", r, { top, s, bot })
	local ex = s:Extract(2)
	s:Remove(1)
	check("S1 extract/remove", r, { top, s, bot })
	s:Replace(1, item("r1"))
	s:Splice(1, 1, item("p1"), item("p2"))
	check("S1 replace/splice", r, { top, s, bot })
	s:Clear()
	check("S1 clear", r, { top, s, bot })
	s:Add(ex)
	check("S1 re-add extracted", r, { top, s, bot })
end

print("=== S2 :List at depth 2 inside claimed tree, with claimed siblings, reorder + Detach + OwnsElements=false ===")
do
	local r = mk("Frame", "Root")
	local list = mk("Frame", "List", r)
	local hdr = mk("TextLabel", "Hdr", list)
	local ftr = mk("TextLabel", "Ftr", list)
	phys[list] = { hdr, ftr }
	local data = q.Source({ "a", "b", "c" })
	local cache = {}
	local s = q.Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then
			if ctx.Prev and ctx.Prev.Name == "b" then return q.Detach end
			return nil
		end
		if ctx.Prev then return ctx.Prev end
		local e = cache[ctx.Item] or item(ctx.Item)
		return e
	end, function(x) return x end)
	try("S2 claim", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("List")({ M.TextLabel("Hdr")({}), s, M.TextLabel("Ftr")({ Text = "f" }) }) })) end)
	check("S2 after claim", list, { hdr, s, ftr })
	data:Set({ "c", "a", "b" })
	check("S2 reorder", list, { hdr, s, ftr })
	data:Set({ "c", "a" }) -- b detached
	check("S2 detach b", list, { hdr, s, ftr })
	data:Set({ "b", "c", "a", "d" }) -- b reattached
	check("S2 reattach b + d", list, { hdr, s, ftr })
	data:Set({})
	check("S2 empty", list, { hdr, s, ftr })
	print("S2 ftr offset", q.Bookkeeping.getOffsetAt(list, 3))
end

print("=== S3 OwnsElements=false :List whose elements are Claimed clones (updateFn claims per item) ===")
do
	local r = mk("Frame", "Root")
	local hdr = mk("TextLabel", "Hdr", r)
	phys[r] = { hdr }
	local function tplCard()
		local c = mk("Frame", "Card")
		mk("TextLabel", "Title", c)
		return c
	end
	local data = q.Source({ "x", "y" })
	local made = {}
	local s = q.Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local c = tplCard()
		c.Name = ctx.Item
		-- idiom: fresh descriptor per item
		q.Claim(c, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = ctx.Item }) }))
		made[ctx.Item] = c
		return c
	end, function(x) return x end, { OwnsElements = false })
	try("S3 claim", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Hdr")({}), s })) end)
	check("S3 after", r, { hdr, s })
	print("S3 title x", made.x and made.x:FindFirstChild("Title").Text)
	data:Set({ "y" })
	print("S3 x after removal: destroyed?", mock.isDestroyed and mock.isDestroyed(made.x), "parent", made.x.Parent, "claimed", claimed(made.x))
	check("S3 after remove", r, { hdr, s })
	-- re-add the orphaned claimed card to a manual Slot elsewhere
	local s2 = q.Slot()
	local host = D.Frame({ s2 })
	try("S3 reuse orphan in other slot", function() s2:Add(made.x) end)
end

print("=== S4 Slot as mapped-child sibling; Claim root then dispose(slot element) / template child destroyed outside ===")
do
	local r = mk("Frame", "Root")
	local top = mk("TextLabel", "Top", r)
	local bot = mk("TextLabel", "Bot", r)
	phys[r] = { top, bot }
	local s = q.Slot({ item("e1"), item("e2") })
	q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Top")({}), s, M.TextLabel("Bot")({}) }))
	check("S4 claim", r, { top, s, bot })
	-- template child Top destroyed outside
	top:Destroy()
	print("S4 after Top:Destroy offset pos2", q.Bookkeeping.getOffsetAt(r, 2), "pos3", q.Bookkeeping.getOffsetAt(r, 3), "Length slot", s.Length:Get())
	-- oracle: Top removed physically by the engine (no native op)
	local l = P(r); table.remove(l, table.find(l, top))
	try("S4 add after Top destroyed", function() s:Add(item("e3"), 1) end)
	check("S4 after add", r, { s, bot })
	print("S4 violations list printed above; offset used would be", q.Bookkeeping.getOffsetAt(r, 2))
end

------------------------------------------------------------ Attr/Tag on claimed
print("=== A1 Attr(store) on claimed instance with pre-existing attribute ===")
do
	local r = mk("Frame", "Root")
	r:SetAttribute("hp", 99)
	r:SetAttribute("keep", "k")
	mock.getTags(r)
	q.Backend.addTag(r, { "Pre", "Card" })
	local store = q.Store({ hp = q.Source(1), mp = q.Source(2) })
	local tagS = q.Source(q.Tag("Card", "New"))
	local grp = q.Source(q.Attr(store))
	try("A1 claim", function() q.Claim(r, M.Frame(M.Root)({ grp, tagS })) end)
	print("A1 after claim hp,mp,keep", r:GetAttribute("hp"), r:GetAttribute("mp"), r:GetAttribute("keep"), "tags", tags(r))
	store.hp:Set(10)
	print("A1 hp after store set", r:GetAttribute("hp"))
	grp:Set(nil)
	tagS:Set(nil)
	print("A1 after retract hp,mp,keep", r:GetAttribute("hp"), r:GetAttribute("mp"), r:GetAttribute("keep"), "tags", tags(r))
	store.hp:Set(11)
	print("A1 hp after retract + store set", r:GetAttribute("hp"))
	-- store gets a new name via Of after mount
	local grp2 = q.Source(q.Attr(store))
	q.Dispatch.drive(r, { [3] = grp2 })
	store:Of("late"):Set(3)
	print("A1 late name via Of after mount", r:GetAttribute("late"))
end

print("=== A2 Attr on mapped deep child; mapped child re-claimed? AttrKey conflict with root ===")
do
	local r, a, b, c, leaf = chain()
	leaf:SetAttribute("x", 1)
	try("A2", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.Frame("B")({ M.Frame("C")({ M.TextLabel("Leaf")({ [q.AttrKey("x")] = 5, q.Tag("t") }) }) }) }) })) end)
	print("A2 leaf x", leaf:GetAttribute("x"), "tags", tags(leaf))
	q.dispose(r)
	print("A2 after dispose root: leaf destroyed", mock.isDestroyed and mock.isDestroyed(leaf), "x", leaf:GetAttribute("x"))
end

------------------------------------------------------------ dispose / destroy
print("=== D1 q.dispose(claimed root) / dispose(mapped child) ===")
do
	local r, a, b, c, leaf = chain()
	q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.Frame("B")({}) }) }))
	-- c and leaf are unmapped (contract violation §3 but common) - just observe
	try("D1 dispose mapped child b (sits at a pos1)", function() q.dispose(b) end)
	try("D1 dispose unmapped c", function() q.dispose(c) end)
	print("D1 c destroyed", mock.isDestroyed(c), "leaf destroyed", mock.isDestroyed(leaf))
	try("D1 dispose root", function() q.dispose(r) end)
	print("D1 r,a destroyed", mock.isDestroyed(r), mock.isDestroyed(a), "claimed r,a", allClaimed(r, a))
end

print("=== D2 mapped template child destroyed outside, then drive / re-Claim root ===")
do
	local r = mk("Frame", "Root")
	local t = mk("TextLabel", "Title", r)
	local l = mk("Frame", "List", r)
	local titleText = q.Source("a")
	q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = titleText }), M.Frame("List")({}) }))
	t:Destroy()
	print("D2 t claimed after destroy", claimed(t), "offset pos2", q.Bookkeeping.getOffsetAt(r, 2))
	try("D2 set Text on destroyed title", function() titleText:Set("b") end)
	print("D2 t.Text", t.Text)
	try("D2 re-claim root (already claimed)", function() q.Claim(r, M.Frame(M.Root)({})) end)
	-- replace the dead static child position via drive
	local nt = D.TextLabel({ Name = "Title2" })
	try("D2 drive pos1 new child", function() q.Dispatch.drive(r, { [1] = nt }) end)
	print("D2 nt parent is r", nt.Parent == r, "offset pos2", q.Bookkeeping.getOffsetAt(r, 2))
	try("D2 dispose root", function() q.dispose(r) end)
end

print("=== D3 fresh clone: template child already destroyed before Claim (corpse child) ===")
do
	local r = mk("Frame", "Root")
	local t = mk("TextLabel", "Title", r)
	-- Title destroyed -> Parent nil, so FindFirstChild no longer finds it
	t:Destroy()
	try("D3 claim with destroyed child mapped", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({}) })) end)
	print("D3 r claimed", claimed(r))
end

------------------------------------------------------------ descriptor/props reuse
print("=== R1 same descriptor across two Claims (Quad0027) ===")
do
	local d = M.TextLabel("Title")({ Text = "a" })
	local r1 = mk("Frame", "R1"); mk("TextLabel", "Title", r1)
	local r2 = mk("Frame", "R2"); mk("TextLabel", "Title", r2)
	q.Claim(r1, M.Frame(M.Root)({ d }))
	try("R1 reuse", function() q.Claim(r2, M.Frame(M.Root)({ d })) end)
	print("R1 r2 claimed", claimed(r2))
end

print("=== R2 shared props TABLE across two descriptors (mutated in place by first Claim) ===")
do
	local props = { M.TextLabel("Title")({ Text = "a" }), BackgroundTransparency = 0.5 }
	local r1 = mk("Frame", "R1"); local t1 = mk("TextLabel", "Title", r1)
	local r2 = mk("Frame", "R2"); local t2 = mk("TextLabel", "Title", r2)
	q.Claim(r1, M.Frame(M.Root)(props))
	print("R2 props[1] after first Claim is", typeof(props[1]), props[1] == t1 and "t1" or "?")
	try("R2 second Claim with same props table", function() q.Claim(r2, M.Frame(M.Root)(props)) end)
	print("R2 r2 claimed", claimed(r2), "t2 claimed", claimed(t2), "t1.Parent==r1", t1.Parent == r1, "t1.Parent==r2", t1.Parent == r2, "r2 BT", r2.BackgroundTransparency)
end

print("=== R3 Slot:List updateFn hoisted descriptor (reuse across items) ===")
do
	local host = D.Frame({})
	local shared = M.TextLabel("Title")({ Text = "same" })
	local s = q.Slot()
	try("R3 list", function()
		s:List({ "p", "q" }, function(ctx)
			if ctx.Item == q.KeyGone then return nil end
			local c = mk("Frame", ctx.Item); mk("TextLabel", "Title", c)
			return q.Claim(c, M.Frame(M.Root)({ shared }))
		end)
		q.Dispatch.drive(host, { s })
	end)
	print("R3 slot length", s.Length:Get())
end

print("=== R4 Slot:List updateFn per-item fresh descriptors, update of existing key re-claims prev? ===")
do
	local host = D.Frame({})
	local data = q.Source({ "p" })
	local s = q.Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		local c = ctx.Prev or (function() local c = mk("Frame", ctx.Item); mk("TextLabel", "Title", c); return c end)()
		-- naive idiom: always Claim (even for Prev) -> double claim on update
		return q.Claim(c, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = ctx.Item }) }))
	end, function(x) return x end)
	q.Dispatch.drive(host, { s })
	try("R4 second reconcile same key", function() data:Set({ "p", "z" }) end)
	print("R4 length", s.Length:Get())
end

print("=== probe done ===")

print("=== R5 generalisation: numeric seat holds an Instance that drive will reject (mounted elsewhere / foreign) ===")
do
	local r = mk("Frame", "R"); local t = mk("TextLabel", "Title", r)
	local seated = D.Frame({ Name = "Seated" })
	local host = D.Frame({ seated })
	try("R5a mounted-elsewhere Instance in claim props", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "t" }), seated })) end)
	print("R5a r claimed", claimed(r), "Title claimed", claimed(t), "Title.Text", t.Text)
	local r2 = mk("Frame", "R2"); local t2 = mk("TextLabel", "Title", r2)
	local foreign = mk("Frame", "Foreign") -- never claimed
	try("R5b foreign Instance in claim props", function() q.Claim(r2, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "t" }), foreign })) end)
	print("R5b r2 claimed", claimed(r2), "Title claimed", claimed(t2))
	try("R5b retry fixed", function() q.Claim(r2, M.Frame(M.Root)({ M.TextLabel("Title")({}) })) end)
	-- same shapes with D.Frame (control): nothing to claim, just half-built
	try("R5c control D.Frame with foreign", function() D.Frame({ foreign }) end)
end

print("=== S5 Claim'd template child placed into a Slot of the same claimed root ===")
do
	local r = mk("Frame", "Root")
	local top = mk("TextLabel", "Top", r)
	local row = mk("Frame", "Row", r) -- template row, to be claimed separately and put in a slot
	phys[r] = { top, row }
	local claimedRow = q.Claim(row, M.Frame(M.Root)({}))
	local s = q.Slot({ claimedRow })
	try("S5 claim root with slot containing its own template child", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Top")({}), s })) end)
	print("S5 row parent is r", row.Parent == r, "slot len", s.Length:Get(), "phys", physStr(r), "#viol", #violations)
	for _, v in violations do print("   viol:", v) end; table.clear(violations)
end

print("=== S6 depth-3 mapper hosting State<Instance> seat + Slot + mapped sibling ===")
do
	local r, a, b, c = chain()
	local sib = mk("TextLabel", "Sib", c)
	phys[c] = { c:FindFirstChild("Leaf"), sib }
	local st = q.Source(nil)
	local s = q.Slot({ item("z1") })
	try("S6 claim", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("A")({ M.Frame("B")({ M.Frame("C")({ M.TextLabel("Leaf")({}), st, s, M.TextLabel("Sib")({}) }) }) }) })) end)
	print("S6 offsets pos3(slot) pos4(sib)", q.Bookkeeping.getOffsetAt(c, 3), q.Bookkeeping.getOffsetAt(c, 4))
	local f = D.Frame({ Name = "StateKid" })
	st:Set(f)
	print("S6 after State set: slot pos3 offset", q.Bookkeeping.getOffsetAt(c, 3), "sib", q.Bookkeeping.getOffsetAt(c, 4))
	-- oracle: state child is static (Parent=), insert into phys by hand at offset 1
	table.insert(P(c), 2, f)
	s:Add(item("z2"), 1)
	check("S6 slot add after state child", c, { c:FindFirstChild("Leaf"), f, s, sib })
	st:Set(nil)
	table.remove(P(c), table.find(P(c), f))
	s:Add(item("z3"))
	check("S6 after state cleared", c, { c:FindFirstChild("Leaf"), s, sib })
end
print("=== probe2 done ===")
print("=== R6 realistic: template child passed directly instead of a descriptor ===")
do
	local r = mk("Frame", "R"); local t = mk("TextLabel", "Title", r); local l = mk("Frame", "List", r)
	try("R6", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("List")({ BackgroundTransparency = 0.2 }), r:FindFirstChild("Title") })) end)
	print("R6 r claimed", claimed(r), "List claimed", claimed(l), "List BT", l.BackgroundTransparency, "Title claimed", claimed(t))
	try("R6 retry fixed", function() q.Claim(r, M.Frame(M.Root)({ M.Frame("List")({}), M.TextLabel("Title")({}) })) end)
	local r3 = mk("Frame", "R3")
	try("R6b root in its own props", function() q.Claim(r3, M.Frame(M.Root)({ r3 })) end)
	print("R6b r3 claimed", claimed(r3))
end
