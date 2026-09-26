--!nocheck
-- 재현: quad-roblox/test/로 복사한 뒤 ./scripts/relink.sh && luau quad-roblox/test/probe.e6.luau (2026-09-26 E6)
-- E6 scratch probe (round13) — Claim/Mapper, Tag, Attr
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

local function tpl()
	local root = Instance.new("Frame")
	local title = Instance.new("TextLabel"); title.Name = "Title"; title.Parent = root
	local list = Instance.new("Frame"); list.Name = "List"; list.Parent = root
	local inner = Instance.new("TextLabel"); inner.Name = "Inner"; inner.Parent = list
	return root, title, list, inner
end
local function try(label, f)
	local ok, err = pcall(f)
	print(label, ok, ok and "" or tostring(err))
	return ok
end
local function claimed(x) return q.Backend.isClaimed(x) end
local function tags(i) return table.concat(mock.getTags(i), ",") end

print("--- C1 descriptor at a hash key (not array) ---")
do
	local root, title = tpl()
	local desc = M.Frame(M.Root)({ Kid = M.TextLabel("Title")({ Text = "x" }), BackgroundTransparency = 0.5 })
	try("C1 claim", function() q.Claim(root, desc) end)
	print("C1 root claimed after throw:", claimed(root), "BT:", root.BackgroundTransparency, "fired:", desc._fired)
	try("C1 retry (fixed)", function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "x" }) })) end)
end

print("--- C2 descriptor inside a State at array slot ---")
do
	local root = tpl()
	local s = q.Source(M.TextLabel("Title")({ Text = "y" }))
	try("C2 claim", function() q.Claim(root, M.Frame(M.Root)({ s })) end)
	print("C2 root claimed after throw:", claimed(root))
end

print("--- C3 descriptor inside a Slot at array slot ---")
do
	local root = tpl()
	try("C3 claim", function() q.Claim(root, M.Frame(M.Root)({ q.Slot({ M.TextLabel("Title")({ Text = "y" }) }) })) end)
	print("C3 root claimed after throw:", claimed(root))
end

print("--- C4 descriptor inside a Modifier field ---")
do
	local root = tpl()
	local mod = q.Modifier({ Kid = M.TextLabel("Title")({ Text = "z" }) })
	try("C4 claim", function() q.Claim(root, M.Frame(M.Root)({ mod })) end)
	print("C4 root claimed after throw:", claimed(root))
end

print("--- C5 root class mismatch (M.TextLabel(M.Root) on a Frame) ---")
do
	local root, title = tpl()
	try("C5a claim, overlap-only props", function() q.Claim(root, M.TextLabel(M.Root)({ Name = "R" })) end)
	print("C5a root claimed:", claimed(root), "name", root.Name)
	local root2 = tpl()
	try("C5b claim, Text prop", function() q.Claim(root2, M.TextLabel(M.Root)({ M.TextLabel("Title")({ Text = "t" }), Text = "boom" })) end)
	print("C5b root claimed after throw:", claimed(root2), "child claimed:", claimed(root2:FindFirstChild("Title")), "child Text:", root2:FindFirstChild("Title").Text)
end

print("--- C6 bad prop on a mapped child (drive throw) — residue ---")
do
	local root, title = tpl()
	local desc = M.Frame(M.Root)({ M.TextLabel("Title")({ Nope = 1 }) })
	try("C6 claim", function() q.Claim(root, desc) end)
	print("C6 root claimed", claimed(root), "title claimed", claimed(title))
end

print("--- C7 same child name twice, different class (UB — FindFirstChild first) ---")
do
	local root = Instance.new("Frame")
	local a = Instance.new("ImageLabel"); a.Name = "Kid"; a.Parent = root
	local b = Instance.new("TextLabel"); b.Name = "Kid"; b.Parent = root
	try("C7 claim TextLabel Kid", function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Kid")({ Text = "k" }) })) end)
end

print("--- C8 root descriptor used as child of another claim / descriptor reused after success ---")
do
	local root = tpl()
	local d = M.TextLabel("Title")({ Text = "a" })
	try("C8 first", function() q.Claim(root, M.Frame(M.Root)({ d })) end)
	local root2 = tpl()
	try("C8 reuse", function() q.Claim(root2, M.Frame(M.Root)({ d })) end)
	print("C8 root2 claimed", claimed(root2))
end

print("--- C9 Claim twice pass1 same child via root: child descriptor that maps root itself? (key = name of root) ---")
do
	local root = Instance.new("Frame"); root.Name = "R"
	try("C9", function() q.Claim(root, M.Frame(M.Root)({ M.Frame("R")({}) })) end)
end

print("--- C10 Claim then D.Frame child mixed then Destroy root, claim a new clone ---")
do
	local root, title = tpl()
	local made
	q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "a" }), D.Frame({ Name = "Made" }) }))
	made = root:FindFirstChild("Made")
	print("C10 made exists", made ~= nil, "Length", q.Bookkeeping.getOffsetAt(root, 3))
end

print("--- C11 mapper props contain a State for the static child position (State<Instance>)? ---")
do
	local root, title = tpl()
	local s = q.Source(nil)
	try("C11", function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "a" }), s })) end)
	local f = D.Frame({})
	try("C11 set", function() s:Set(f) end)
	print("C11 f parent is root", f.Parent == root)
end

print("--- C12 Claim props non-array numeric keys: [0] with a non-descriptor (drive's domain) ---")
do
	local root = tpl()
	try("C12 [2.5] = D.Frame", function() q.Claim(root, M.Frame(M.Root)({ [2.5] = D.Frame({}) })) end)
	print("C12 root claimed after throw", claimed(root))
end

------------------------------------------------------------ Tag
print("--- T1 nil rules ---")
do
	local T = q.Tag
	try("T Added(nil)", function() print(tostring(T("a"):Added(nil))) end)
	try("T Removed(nil)", function() print(tostring(T("a"):Removed(nil))) end)
	try("T Merged(nil, tag, nil)", function() print(tostring(T.Merged(nil, T("a"), nil))) end)
	try("T Merged()", function() print(tostring(T.Merged())) end)
	try("T ctor(nil,'a',nil)", function() print(tostring(T(nil, "a", nil))) end)
	try("T list {nil,'b'}", function() print(tostring(T({ nil, "b" }))) end)
	try("T list {'a',nil,'c'}", function() print(tostring(T({ "a", nil, "c" }))) end)
	try("T Added({'a', nil})", function() print(tostring(T():Added({ "a", nil }))) end)
	try("T Merged('a')", function() print(tostring(T.Merged("a"))) end)
	try("T Contains()", function() print(T("a"):Contains()) end)
	try("T Contains(nil)", function() print(T("a"):Contains(nil)) end)
	try("T Added(State)", function() print(tostring(T():Added(q.Source("x")))) end)
	try("T Added(None)", function() print(tostring(T():Added(q.None))) end)
	try("T ctor(None)", function() print(tostring(T(q.None))) end)
	try("T Added(false)", function() print(tostring(T():Added(false))) end)
	local n = 0
	for name in T("a", "b") do n += 1 end
	print("T iter count", n)
end

print("--- T2 State<Tag> swaps: minimal engine calls ---")
do
	local calls = {}
	local oa, orr = q.Backend.addTag, q.Backend.removeTag
	q.Backend.addTag = function(i, n) table.insert(calls, "+" .. table.concat(n, "|")); oa(i, n) end
	q.Backend.removeTag = function(i, n) table.insert(calls, "-" .. table.concat(n, "|")); orr(i, n) end
	local s = q.Source(q.Tag("a", "b"))
	local f = D.Frame({ s })
	s:Set(q.Tag("b", "c"))
	s:Set(q.Tag("b", "c"))
	s:Set(q.None)
	s:Set(q.Tag("x"))
	s:Set(nil)
	s:Set(q.Tag("y"))
	print("T2 calls", table.concat(calls, " "), "final", tags(f))
	-- two positions overlapping + State
	calls = {}
	local s2 = q.Source(q.Tag("x"))
	local g = D.Frame({ q.Tag("x", "y"), s2 })
	s2:Set(q.Tag("z"))
	s2:Set(q.Tag("x"))
	print("T2b calls", table.concat(calls, " "), "final", tags(g))
	-- State<Tag> -> non-Tag value (Attr) at same position
	calls = {}
	local s3 = q.Source(q.Tag("t"))
	local h = D.Frame({ s3 })
	try("T2c swap Tag->Attr", function() s3:Set(q.Attr({ k = 1 })) end)
	print("T2c calls", table.concat(calls, " "), "tags", tags(h), "attr k", h:GetAttribute("k"))
	try("T2c swap Attr->Tag", function() s3:Set(q.Tag("t2")) end)
	print("T2c2 tags", tags(h), "attr k", h:GetAttribute("k"))
	q.Backend.addTag, q.Backend.removeTag = oa, orr
end

print("--- T3 re-drive same position with a different Tag / Tag at pos via drive then State ---")
do
	local f = D.Frame({ q.Tag("p", "q") })
	q.Dispatch.drive(f, { [1] = q.Tag("q", "r") })
	print("T3 after redrive", tags(f))
	q.Dispatch.drive(f, { [1] = q.None })
	print("T3 after None redrive", tags(f))
	local t = q.Tag("s")
	local g = D.Frame({ t, t })
	print("T3 same obj two pos", tags(g))
	q.Dispatch.drive(g, { [1] = q.None })
	print("T3 one retracted", tags(g))
	q.Dispatch.drive(g, { [2] = q.None })
	print("T3 both retracted", tags(g))
end

print("--- T4 Tag + Claim: pre-existing tag on template ---")
do
	local root = tpl()
	game_cs = nil
	q.Backend.addTag(root, { "Pre" })
	local s = q.Source(q.Tag("Pre"))
	q.Claim(root, M.Frame(M.Root)({ s }))
	s:Set(nil)
	print("T4 tags after retract (Q69 known)", tags(root))
end

------------------------------------------------------------ Attr
print("--- A1 group swap, None, nil State ---")
do
	local s = q.Source(q.Attr({ a = 1, b = 2 }))
	local f = D.Frame({ s })
	s:Set(q.Attr({ b = 3, c = q.None }))
	print("A1 attrs a,b,c", f:GetAttribute("a"), f:GetAttribute("b"), f:GetAttribute("c"))
	local st = q.Source(5)
	s:Set(q.Attr({ c = st }))
	st:Set(nil)
	print("A1 c after nil State", f:GetAttribute("c"))
	st:Set(q.None)
	print("A1 c after None State", f:GetAttribute("c"))
	st:Set(7)
	print("A1 c after 7", f:GetAttribute("c"))
	s:Set(nil)
	st:Set(9)
	print("A1 c after group retract + st 9 (should stay 7)", f:GetAttribute("c"))
end

print("--- A2 AttrKey ownership conflict + release + reacquire ---")
do
	local grp = q.Source(q.Attr({ hp = 1 }))
	local f = D.Frame({ grp })
	try("A2 direct conflicting", function() q.Dispatch.drive(f, { [q.AttrKey("hp")] = 5 }) end)
	print("A2 hp", f:GetAttribute("hp"))
	grp:Set(nil)
	try("A2 direct after release", function() q.Dispatch.drive(f, { [q.AttrKey("hp")] = 6 }) end)
	print("A2 hp", f:GetAttribute("hp"))
	try("A2 group reacquire while direct holds", function() grp:Set(q.Attr({ hp = 7 })) end)
	print("A2 hp", f:GetAttribute("hp"))
	try("A2 recovery: group to other names", function() grp:Set(q.Attr({ mp = 1 })) end)
	print("A2 mp", f:GetAttribute("mp"))
end

print("--- A3 partial group conflict: group {a, hp} vs direct hp; later valid group ---")
do
	local f = D.Frame({ [q.AttrKey("hp")] = 1 })
	local g = q.Source(q.Attr({ zz = 1 }))
	q.Dispatch.drive(f, { g })
	local ok = try("A3 set conflicting group", function() g:Set(q.Attr({ a1 = 1, a2 = 2, a3 = 3, hp = 9, a4 = 4 })) end)
	print("A3 hp", f:GetAttribute("hp"), "a1..a4", f:GetAttribute("a1"), f:GetAttribute("a2"), f:GetAttribute("a3"), f:GetAttribute("a4"), "zz", f:GetAttribute("zz"))
	try("A3 set valid group reusing a1", function() g:Set(q.Attr({ a1 = 100 })) end)
	print("A3 a1", f:GetAttribute("a1"))
end

print("--- A4 typed Attr wrong type via State ---")
do
	local st = q.Source(5)
	local f
	try("A4 StringAttr with State<number>", function() f = D.Frame({ q.StringAttr("s", st) }) end)
	print("A4 s", f and f:GetAttribute("s"), typeof(f and f:GetAttribute("s")))
	try("A4 NumberAttr(name, true)", function() q.NumberAttr("n", true) end)
	try("A4 Attr{x = State<table>}", function()
		local t = q.Source({ 1 })
		D.Frame({ q.Attr({ x = t }) })
	end)
	try("A4 Attr{x = State<function>}", function()
		local t = q.Source(function() end)
		D.Frame({ q.Attr({ x = t }) })
	end)
end

print("--- A5 Merged dup keys, Store args ---")
do
	try("A5 Merged dup", function() q.Attr.Merged(q.Attr({ a = 1 }), q.Attr({ a = 2 })) end)
	try("A5 Merged same obj twice", function() local x = q.Attr({ a = 1 }); q.Attr.Merged(x, x) end)
	try("A5 Merged(nil)", function() q.Attr.Merged(nil) end)
	try("A5 Attr(nil)", function() print(tostring(q.Attr(nil))) end)
	try("A5 Attr({}, nil, {b=1})", function() print(tostring(q.Attr({}, nil, { b = 1 }))) end)
	try("A5 ctor overlap last wins", function() print(q.Attr({ a = 1 }, { a = 2 }):NameMap().a) end)
end

print("--- A6 same group object on two instances, and position-claim after re-drive ---")
do
	local grp = q.Attr({ w = 1 })
	local f1 = D.Frame({ grp })
	local f2 = D.Frame({ grp })
	print("A6 f1 w", f1:GetAttribute("w"), "f2 w", f2:GetAttribute("w"))
	local sA = q.Source(grp)
	try("A6 same group via State at pos 2 of f1", function() q.Dispatch.drive(f1, { [2] = sA }) end)
end

print("--- A7 AttrKey hash nil value / None ---")
do
	local f = D.Frame({ [q.AttrKey("k")] = 3 })
	q.Dispatch.drive(f, { [q.AttrKey("k")] = q.None })
	print("A7 after None", f:GetAttribute("k"))
	local st = q.Source(4)
	q.Dispatch.drive(f, { [q.AttrKey("k")] = st })
	print("A7 st", f:GetAttribute("k"))
	st:Set(nil)
	print("A7 st nil", f:GetAttribute("k"))
end

print("--- A8 group with Store arg; store field swap ---")
do
	local ok, store = pcall(function() return q.Store({ hp = 1, mp = 2 }) end)
	if ok then
		local f = D.Frame({ q.Attr(store) })
		print("A8", f:GetAttribute("hp"), f:GetAttribute("mp"))
		store.hp:Set(10)
		print("A8 after", f:GetAttribute("hp"))
	else
		print("A8 store ctor", store)
	end
end
print("=== probe done ===")
print("--- C13 [0]=descriptor (H-560, pre-claim) vs [0]=D.Frame (drive gate after claim) ---")
do
	local r1 = tpl()
	try("C13a [0]=desc", function() q.Claim(r1, M.Frame(M.Root)({ [0] = M.TextLabel("Title")({}) })) end)
	print("C13a root claimed", claimed(r1))
	local r2 = tpl()
	try("C13b [0]=D.Frame", function() q.Claim(r2, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "c" }), [0] = D.Frame({}) })) end)
	print("C13b root claimed", claimed(r2), "child claimed", claimed(r2:FindFirstChild("Title")), "child Text", r2:FindFirstChild("Title").Text)
	try("C13b retry fixed", function() q.Claim(r2, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "c" }) })) end)
end
print("--- C14 Destroy then re-Claim same root / fresh clone ---")
do
	local r = tpl()
	q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({}), M.Frame("List")({ M.TextLabel("Inner")({}) }) }))
	r:Destroy()
	print("C14 isClaimed after destroy", claimed(r))
	try("C14 re-claim corpse (H-293 UB)", function() q.Claim(r, M.Frame(M.Root)({})) end)
end
print("=== probe2 done ===")
