--!nocheck
-- round13 P-Q84b probe (2026-09-27): nativeIsA predicate shape (V1 root / V2 unified) + Q85 C4 alternative.
-- Run in a patched cp -rL copy: put in quad-roblox/test/, ./scripts/relink.sh, luau quad-roblox/test/probe.q84b.luau
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
	return root, title, list
end
local function try(label, f)
	local ok, err = pcall(f)
	print(label, ok, ok and "" or tostring(err))
	return ok
end
local function claimed(x) return q.Backend.isClaimed(x) end

print("--- C5a root class mismatch, overlap-only props ---")
do
	local root = tpl()
	try("C5a", function() q.Claim(root, M.TextLabel(M.Root)({ Name = "R" })) end)
	print("C5a root claimed:", claimed(root), "name", root.Name)
end
print("--- C5b root class mismatch + Text prop + mapped child ---")
do
	local root, title = tpl()
	local desc = M.TextLabel(M.Root)({ M.TextLabel("Title")({ Text = "t" }), Text = "boom" })
	try("C5b", function() q.Claim(root, desc) end)
	print("C5b root claimed:", claimed(root), "child claimed:", claimed(title), "child Text:", title.Text, "fired:", desc._fired)
	try("C5b retry fixed", function() q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "t" }) })) end)
	print("C5b retry root claimed:", claimed(root), "Text", title.Text)
end
print("--- K1 control: right class root ---")
do
	local r = Instance.new("TextLabel"); r.Name = "L"
	try("K1", function() q.Claim(r, M.TextLabel(M.Root)({ Text = "k" })) end)
	print("K1 claimed", claimed(r), r.Text)
end
print("--- K2 abstract class via newMapperClass('GuiObject') at root (Roblox IsA would pass; mock is ClassName ==) ---")
do
	local r = Instance.new("Frame")
	try("K2 root", function() q.Claim(r, q.newMapperClass("GuiObject")(M.Root)({})) end)
	print("K2 root claimed", claimed(r))
	local r2, t2 = tpl()
	try("K2 child", function() q.Claim(r2, M.Frame(M.Root)({ q.newMapperClass("GuiObject")("Title")({}) })) end)
	print("K2 child r2 claimed", claimed(r2))
end
print("--- K3 child class mismatch (Q49 path) — message after V2 unify ---")
do
	local r, t = tpl()
	try("K3", function() q.Claim(r, M.Frame(M.Root)({ M.ImageLabel("Title")({}) })) end)
	print("K3 r claimed", claimed(r))
	local r2 = tpl()
	try("K3 absent", function() q.Claim(r2, M.Frame(M.Root)({ M.TextLabel("Nope")({}) })) end)
end
print("--- K4 provider that predates the op: base stub on every Claim ---")
do
	local q2: any = Quad.New()
	local stub = q2.Backend.nativeIsA -- LifetimeHandle's notInstalled stub (no provider yet)
	-- a provider that fills everything except the new op: borrow q's ops, leave the stub
	for k, v in q.Backend do
		if k ~= "nativeIsA" and type(v) == "function" and q2.Backend[k] ~= nil then q2.Backend[k] = v end
	end
	print("K4 stub kept", q2.Backend.nativeIsA == stub)
	local r = Instance.new("Frame")
	try("K4 claim", function() q2.Claim(r, q2.newMapperClass("Frame")(q2.MapperRoot)({})) end)
end

print("--- C4 (Q85): descriptor inside a Modifier field ---")
do
	local root = tpl()
	local ok = try("C4 Modifier build", function() return q.Modifier({ Kid = M.TextLabel("Title")({ Text = "z" }) }) end)
	if ok then
		local mod = q.Modifier({ Kid = M.TextLabel("Title")({ Text = "z" }) })
		try("C4 claim", function() q.Claim(root, M.Frame(M.Root)({ mod })) end)
		print("C4 root claimed after throw:", claimed(root))
	end
end
print("--- C4s (Q85): descriptor through the setter path / typed factory / Modifier merge ---")
do
	try("C4s setter", function() return q.Modifier({}):Kid(M.TextLabel("Title")({})) end)
	try("C4s setter transform", function() return q.Modifier({ Kid = 1 }):Kid(function() return M.TextLabel("Title")({}) end) end)
	try("C4s typed", function() return D.Modifier.Frame({ Kid = M.TextLabel("Title")({}) }) end)
	local root = tpl()
	local ok = pcall(function() return q.Modifier({}):Kid(M.TextLabel("Title")({})) end)
	if ok then
		try("C4s claim", function() q.Claim(root, M.Frame(M.Root)({ q.Modifier({}):Kid(M.TextLabel("Title")({})) })) end)
		print("C4s root claimed after throw:", claimed(root))
	end
	-- same misuse outside Claim (plain Declaration): was Quad0076 at drive
	try("C4d D.Frame", function() return D.Frame({ q.Modifier({ Kid = M.TextLabel("Title")({}) }) }) end)
end
print("--- C4b (Q85): State(descriptor) inside a Modifier field (X2) ---")
do
	local root = tpl()
	local ok = try("C4b Modifier build", function() return q.Modifier({ Kid = q.Source(M.TextLabel("Title")({})) }) end)
	if ok then
		try("C4b claim", function() q.Claim(root, M.Frame(M.Root)({ q.Modifier({ Kid = q.Source(M.TextLabel("Title")({})) }) })) end)
		print("C4b root claimed after throw:", claimed(root))
	end
end
print("--- C4c (Q85): Modifier setter path (D.Modifier.Frame():...) / :Apply / Compute holding a descriptor ---")
do
	local root = tpl()
	local src = q.Source(1)
	local ok = try("C4c Compute-descriptor field", function() return q.Modifier({ Kid = src:Compute(function() return M.TextLabel("Title")({}) end) }) end)
	if ok then
		try("C4c claim", function() q.Claim(root, M.Frame(M.Root)({ q.Modifier({ Kid = src:Compute(function() return M.TextLabel("Title")({}) end) }) })) end)
		print("C4c root claimed after throw:", claimed(root))
	end
end
print("--- C1 (Q85): descriptor at a string key (not a Modifier) ---")
do
	local root = tpl()
	try("C1", function() q.Claim(root, M.Frame(M.Root)({ Kid = M.TextLabel("Title")({ Text = "x" }) })) end)
	print("C1 root claimed after throw:", claimed(root))
end
print("--- C2 (Q85): descriptor inside a State at array slot ---")
do
	local root = tpl()
	try("C2", function() q.Claim(root, M.Frame(M.Root)({ q.Source(M.TextLabel("Title")({ Text = "y" })) })) end)
	print("C2 root claimed after throw:", claimed(root))
end
print("--- X5 cycle: claimed ancestor in the claimed root's props ---")
do
	local host = D.Frame({ Name = "Host" })
	local r = Instance.new("Frame"); local t = Instance.new("TextLabel"); t.Name = "Title"; t.Parent = r; r.Parent = host
	try("X5", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({}), host })) end)
	print("X5 r claimed", claimed(r))
end
print("--- X6 State holding a foreign Instance ---")
do
	local r = tpl()
	local foreign = Instance.foreign and Instance.foreign("Frame") or Instance.new("Frame")
	try("X6", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({}), q.Source(foreign) })) end)
	print("X6 r claimed", claimed(r))
end
print("--- X7 Modifier at a string key ---")
do
	local r = tpl()
	try("X7", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({}), Kid = q.Modifier({ BackgroundTransparency = 1 }) })) end)
	print("X7 r claimed", claimed(r))
end
print("--- X8 controls: valid claim with raw claimed Instance, State, Modifier ---")
do
	local r, t = tpl()
	local x = D.Frame({ Name = "X" })
	local s = q.Source(D.Frame({ Name = "S" }))
	try("X8", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "ok" }), x, s, q.Modifier({ BackgroundTransparency = 0.25 }) })) end)
	print("X8 r claimed", claimed(r), "t.Text", t.Text, "x.Parent==r", x.Parent == r, "BT", r.BackgroundTransparency)
end
print("=== probe done ===")
