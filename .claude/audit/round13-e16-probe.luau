--!nocheck
-- round13 E16 probe (2026-09-27) — Tag/Attr/AttrKey × Ref/PreRef/PostRef/dispose. Run from repo root: luau .claude/audit/round13-e16-probe.luau
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local installProperty = require("../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../quad-roblox/src/Handlers/Event")
local installShorthand = require("../../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../../quad-roblox/src/EngineOps")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Visible", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
getfenv(installProperty).game = gameShim
getfenv(installProperty).TweenInfo = mock.tweenInfoShim
getfenv(installProperty).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" } }
getfenv(installEvent).game = gameShim
getfenv(installEngineOps).game = gameShim
getfenv(installShorthand).UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
getfenv(q.Declaration.New).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local D, None = q.Declaration, q.None
-- engine-call log: wrap backend tag/attr ops
local log = {}
local oa, orm, osa = q.Backend.addTag, q.Backend.removeTag, q.Backend.setAttr
q.Backend.addTag = function(i, n) local c = table.clone(n); table.sort(c); table.insert(log, "+" .. table.concat(c, "|")); return oa(i, n) end
q.Backend.removeTag = function(i, n) local c = table.clone(n); table.sort(c); table.insert(log, "-" .. table.concat(c, "|")); return orm(i, n) end
q.Backend.setAttr = function(i, k, v) table.insert(log, "A:" .. k .. "=" .. tostring(v)); return osa(i, k, v) end
local function L() local s = table.concat(log, " "); table.clear(log); return s end
local function tags(i) return table.concat(mock.getTags(i), ",") end
local function attrs(i) local t = {} for k, v in mock.getAttributes(i) do table.insert(t, k .. "=" .. tostring(v)) end table.sort(t) return table.concat(t, ",") end
local function first(e) return (tostring(e):gsub("\n.*", "")) end
local function sec(name, f) print("=== " .. name .. " ==="); local ok, e = pcall(f); if not ok then print("  !! ERR:", first(e)) end end
local function try(label, f) local ok, e = pcall(f); print("  " .. label, ok and "ok" or ("ERR " .. first(e))); return ok end

-- ================= (1) Tag =================
sec("T1 State<Tag> dup names / big set / timing", function()
	local s = q.Source(q.Tag("a", "a", { "a", { "a" } }))
	local f = D.Frame({ s })
	print("  tags", tags(f), "log", L())
	local big = {} for i = 1, 20000 do big[i] = "n" .. i end
	local t0 = os.clock(); s:Set(q.Tag(big)); local t1 = os.clock()
	print("  big add ms", math.floor((t1 - t0) * 1000), "#tags", #mock.getTags(f)); L()
	local big2 = {} for i = 2, 20001 do big2[i - 1] = "n" .. i end
	t0 = os.clock(); s:Set(q.Tag(big2)); t1 = os.clock()
	print("  big shift-by-one ms", math.floor((t1 - t0) * 1000), "log", L())
end)

sec("T2 State<Tag> -> nil / None / string / Attr / Ref / number", function()
	for _, case in { { "nil", function() return nil end }, { "None", function() return None end },
		{ "string", function() return "x" end }, { "Attr", function() return q.Attr({ X = 1 }) end },
		{ "Ref", function() return q.Ref(nil) end }, { "number", function() return 5 end }, { "false", function() return false end } } do
		local s = q.Source(q.Tag("k"))
		local f = D.Frame({ s })
		L()
		local ok, e = pcall(function() s:Set(case[2]()) end)
		print("  ->" .. case[1], ok and "ok" or ("ERR " .. first(e)), "tags", tags(f), "log", L())
		local ok2, e2 = pcall(function() s:Set(q.Tag("k2")) end)
		print("     back to Tag(k2)", ok2 and "ok" or ("ERR " .. first(e2)), "tags", tags(f), "log", L())
	end
end)

sec("T3 two positions overlap: static Tag(a) + State<Tag>(a,b); State -> Tag() -> nil", function()
	local s = q.Source(q.Tag("a", "b"))
	local f = D.Frame({ q.Tag("a"), s })
	print("  init tags", tags(f), "log", L())
	s:Set(q.Tag()); print("  State->Tag() tags", tags(f), "log", L())
	s:Set(nil); print("  State->nil tags", tags(f), "log", L())
	s:Set(q.Tag("a")); print("  State->Tag(a) tags", tags(f), "log", L())
end)

sec("T3b two State<Tag> positions sharing one Tag object, swap values", function()
	local A, B = q.Tag("x", "y"), q.Tag("y", "z")
	local s1, s2 = q.Source(A), q.Source(B)
	local f = D.Frame({ s1, s2 })
	print("  init", tags(f), L())
	s1:Set(B); print("  s1=B", tags(f), L())
	s2:Set(A); print("  s2=A", tags(f), L())
	s1:Set(nil); s2:Set(nil); print("  both nil", tags(f), L())
end)

sec("T4 Claim template with pre-existing tag + quad State<Tag> of same and different names", function()
	local root = Instance.new("Frame")
	game = gameShim
	gameShim:GetService("CollectionService"):AddTag(root, "Studio")
	gameShim:GetService("CollectionService"):AddTag(root, "Shared")
	local s = q.Source(q.Tag("Shared", "Mine"))
	q.Claim(root, q.Declaration.Mapper.Frame(q.Declaration.Mapper.Root)({ s }))
	print("  after claim", tags(root), L())
	s:Set(q.Tag("Mine")); print("  State drops Shared", tags(root), L())
end)

sec("T5 Destroy / dispose then State<Tag> Set — engine calls on the corpse?", function()
	local s = q.Source(q.Tag("a"))
	local f = D.Frame({ s })
	L()
	f:Destroy()
	print("  after Destroy tags(mock data)", tags(f), L())
	s:Set(q.Tag("b")); print("  Set after Destroy", tags(f), "log", L())
	collectgarbage("collect"); collectgarbage("collect")
	s:Set(q.Tag("c")); print("  Set after GC", "log", L())
	local s2 = q.Source(q.Tag("a"))
	local g = D.Frame({ s2 })
	q.dispose(g); L()
	s2:Set(q.Tag("z")); print("  Set after q.dispose", tags(g), "log", L())
end)

sec("T6 Tag in Modifier / Slot element / hash key", function()
	try("Modifier{Tag}", function() local m = q.Modifier({ q.Tag("m") }); local f = D.Frame({ m }); print("    tags", tags(f)) end)
	try("Frame{Tag at hash key}", function() D.Frame({ Foo = q.Tag("m") }) end)
	try("Slot{Tag}", function() local sl = q.Slot({ q.Tag("m") }); local f = D.Frame({ sl }); print("    tags", tags(f)) end)
	try("Slot:Add(Tag)", function() local sl = q.Slot(); local f = D.Frame({ sl }); sl:Add(q.Tag("m")); print("    tags", tags(f)) end)
	L()
end)

sec("T7 __iter order + pairs", function()
	local t = q.Tag("c", "a", "b")
	local out = {} for n, v in t do table.insert(out, n .. ":" .. tostring(v)) end
	print("  iter", table.concat(out, ","), "tostring", tostring(t))
	local ok, e = pcall(function() for k in pairs(t) do end end)
	print("  pairs(tag)", ok, ok and "" or first(e))
end)

sec("T8 non-string names: numbers, booleans, huge string, whitespace, unicode", function()
	try("Tag(1)", function() q.Tag(1) end)
	try("Tag(' ')", function() local f = D.Frame({ q.Tag(" ") }); print("    tags[", tags(f), "]") end)
	try("Tag(huge 100k)", function() local f = D.Frame({ q.Tag(string.rep("x", 100000)) }); print("    len", #mock.getTags(f)[1]) end)
	try("Tag('한글')", function() local f = D.Frame({ q.Tag("한글") }); print("    tags", tags(f)) end)
	L()
end)
return nil
