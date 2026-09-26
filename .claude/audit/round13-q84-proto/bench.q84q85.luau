--!nocheck
-- round13 Q84/Q85 prototype bench (N=1000) — Claim time only, templates/descriptors built outside the clock
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
local N = 1000
local REPS = 31
local function median(t) table.sort(t); return t[(#t + 1) // 2] end
local function bench(label, build)
	local times = {}
	for _ = 1, REPS do
		local r, desc = build()
		local t0 = os.clock()
		q.Claim(r, desc)
		table.insert(times, (os.clock() - t0) * 1000)
	end
	print(string.format("%-40s median %.2f ms", label, median(times)))
end
bench("A 1000 mapped children", function()
	local r = mk("Frame", "R")
	local kids = {}
	for i = 1, N do mk("TextLabel", "K" .. i, r); kids[i] = M.TextLabel("K" .. i)({ Text = "t" }) end
	return r, M.Frame(M.Root)(kids)
end)
bench("B 1 mapped + 1000 raw claimed Instances", function()
	local r = mk("Frame", "R"); mk("TextLabel", "Title", r)
	local props = { M.TextLabel("Title")({}) }
	for i = 1, N do props[i + 1] = D.Frame({ Name = "F" .. i }) end
	return r, M.Frame(M.Root)(props)
end)
bench("C 1000 mapped, each Modifier(2 fields)+State", function()
	local r = mk("Frame", "R")
	local kids = {}
	for i = 1, N do
		local k = mk("Frame", "K" .. i, r)
		kids[i] = M.Frame("K" .. i)({ q.Modifier({ BackgroundTransparency = 0.1, Name = "K" .. i }), q.Source(nil) })
	end
	return r, M.Frame(M.Root)(kids)
end)
