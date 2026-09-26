--!nocheck
-- round13 Q84/Q85 prototype probe (2026-09-27) — apply q84-a1.*.diff + q85-a.*.diff to a cp -rL copy, put this in quad-roblox/test/, sync quad_base, run with luau
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
print("=== X1 Q85 edge: State(descriptor) at a string key ===")
do
	local r = mk("Frame", "R"); mk("TextLabel", "Title", r)
	try("X1", function() q.Claim(r, M.Frame(M.Root)({ Kid = q.Source(M.TextLabel("Title")({})) })) end)
	print("X1 r claimed", claimed(r))
end
print("=== X2 Q85 edge: Modifier field holding State(descriptor) ===")
do
	local r = mk("Frame", "R"); mk("TextLabel", "Title", r)
	try("X2", function() q.Claim(r, M.Frame(M.Root)({ q.Modifier({ Kid = q.Source(M.TextLabel("Title")({})) }) })) end)
	print("X2 r claimed", claimed(r))
end
print("=== X3 same raw Instance at two numeric keys ===")
do
	local r = mk("Frame", "R"); local t = mk("TextLabel", "Title", r)
	local x = D.Frame({ Name = "X" })
	try("X3", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({}), x, x })) end)
	print("X3 r claimed", claimed(r), "Title claimed", claimed(t))
end
print("=== X4 raw Instance equal to a mapped child (descriptor AND the Instance) ===")
do
	local r = mk("Frame", "R"); local t = mk("TextLabel", "Title", r)
	try("X4", function() q.Claim(r, M.Frame(M.Root)({ t, M.TextLabel("Title")({}) })) end)
	print("X4 r claimed", claimed(r), "Title claimed", claimed(t))
end
print("=== X5 RESIDUE cycle: a claimed ancestor placed in the claimed root's props (needs .Parent) ===")
do
	local host = D.Frame({ Name = "Host" })
	local r = mk("Frame", "R"); mk("TextLabel", "Title", r); r.Parent = host -- template parked under a quad-made host (not seated)
	try("X5", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({}), host })) end)
	print("X5 r claimed", claimed(r))
end
print("=== X6 RESIDUE: State holding a foreign Instance at a numeric key ===")
do
	local r = mk("Frame", "R"); mk("TextLabel", "Title", r)
	local foreign = mk("Frame", "Foreign")
	try("X6", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({}), q.Source(foreign) })) end)
	print("X6 r claimed", claimed(r))
end
print("=== X7 RESIDUE: Modifier at a string key (flatten's Quad0068, a pure check) ===")
do
	local r = mk("Frame", "R"); mk("TextLabel", "Title", r)
	try("X7", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({}), Kid = q.Modifier({ BackgroundTransparency = 1 }) })) end)
	print("X7 r claimed", claimed(r))
end
print("=== X8 controls: valid claims still pass (raw claimed Instance, State, Modifier, sparse none) ===")
do
	local r = mk("Frame", "R"); local t = mk("TextLabel", "Title", r)
	local x = D.Frame({ Name = "X" })
	local s = q.Source(D.Frame({ Name = "S" }))
	try("X8", function() q.Claim(r, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "ok" }), x, s, q.Modifier({ BackgroundTransparency = 0.25 }) })) end)
	print("X8 r claimed", claimed(r), "t.Text", t.Text, "x.Parent==r", x.Parent == r, "BT", r.BackgroundTransparency)
end
print("=== X9 Q84 control: right-class root, subclass-free ===")
do
	local r = mk("TextLabel", "Lbl")
	try("X9", function() q.Claim(r, M.TextLabel(M.Root)({ Text = "k" })) end)
	print("X9 claimed", claimed(r), r.Text)
end
print("=== probe done ===")
