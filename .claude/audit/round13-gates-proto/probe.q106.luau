--!nocheck
-- P-gates Q106 probe (2026-09-27): module `is*` probe widening. Run from scratch root: luau probes/pgates.q106.luau
local Quad = require("../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../quad-roblox/src").QuadRoblox
local installProperty = require("../quad-roblox/src/Handlers/Property")
local installEvent = require("../quad-roblox/src/Handlers/Event")
local installShorthand = require("../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../quad-roblox/src/EngineOps")
local mock = require("../quad-base/test/mock")
local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W }, { Name = "Visible", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
getfenv(installProperty).game = gameShim
getfenv(installProperty).TweenInfo = mock.tweenInfoShim
getfenv(installProperty).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" } }
getfenv(installEvent).game = gameShim
getfenv(installEngineOps).game = gameShim
getfenv(installShorthand).UDim = { new = function(s, o) return { Scale = s, Offset = o } end }
local function E(f)
	local ok, err = pcall(f)
	if ok then return "ok" end
	local s = tostring(err)
	return (s:match("Quad%d+[^\n]*") or s):sub(1, 220)
end
local function T(name, f) print(name .. " => " .. E(f)) end
local function newRoblox()
	local m = Quad.New():UseProvider(QuadRoblox)
	getfenv(m.Declaration.New).Instance = { new = mock.Instance.new }
	m.Backend.isInst = mock.isMockInstance
	return m
end

-- replicas of the verdict (old: {} and 0; new: widened) — the real one is local to Dispatch
local OLD = function() return { {}, 0 } end
local NEW = function() return { {}, 0, { 1 }, { x = 1 }, "s", true } end
local function verdict(pred, probes)
	for _, p in probes() do
		local ok, r = pcall(pred, p)
		if not ok or r == true then return false end
	end
	return true
end

print("== P1 every module `is*` field (mock bare quad + roblox-backed quad) under old/new probe ==")
local bare = mock.newQuad()
local rb = newRoblox()
for label, m in { bare = bare, roblox = rb } do
	local names = {}
	for k, v in m do
		if type(k) == "string" and string.sub(k, 1, 2) == "is" and type(v) == "function" then table.insert(names, k) end
	end
	table.sort(names)
	local bad = {}
	for _, k in names do
		if not verdict(m[k], NEW) then table.insert(bad, k .. (verdict(m[k], OLD) and "(old ok)" or "(old too)")) end
	end
	print(`  {label}: {#names} is* fields: {table.concat(names, ",")}`)
	print(`  {label}: failing new probe: {#bad == 0 and "none" or table.concat(bad, ",")}`)
end
-- Backend is* too (not scanned by brandNameOf, listed for completeness)
do
	local names = {}
	for k, v in rb.Backend do if type(k) == "string" and string.sub(k,1,2) == "is" and type(v) == "function" then table.insert(names, k) end end
	table.sort(names)
	print("  roblox Backend is* (NOT scanned — brandNameOf walks the module only):", table.concat(names, ","))
end

print("== P2 helper shapes — old vs new verdict (true = treated as brand predicate) ==")
local helpers = {
	isArray = function(t) return type(t) == "table" and #t > 0 end,
	isNonEmptyList = function(t) return type(t) == "table" and #t > 0 end,
	isConfig = function(t) return type(t) == "table" and next(t) ~= nil end,
	isNonEmpty = function(t) return type(t) == "table" and next(t) ~= nil end,
	isEmpty = function(t) return type(t) == "table" and next(t) == nil end,
	isMobile = function() return true end,
	isString = function(v) return type(v) == "string" end,
	isBool = function(v) return type(v) == "boolean" end,
	isTruthy = function(v) return v and true or false end,
	isPositive = function(v) return v > 0 end, -- throws on tables
	isFrameLike = function(v) return typeof(v) == "Instance" end,
	isKindConfig = function(t) return type(t) == "table" and t.Kind == "config" end, -- field-keyed: residual
	isHasName = function(t) return type(t) == "table" and t.Name ~= nil end, -- field-keyed: residual (props often have Name)
	isNonNil = function(v) return v ~= nil end,
	isTableWithMeta = function(t) return type(t) == "table" and getmetatable(t) ~= nil end,
}
local hn = {}
for k in helpers do table.insert(hn, k) end
table.sort(hn)
for _, k in hn do print(`  {k}: old={verdict(helpers[k], OLD)} new={verdict(helpers[k], NEW)}`) end

print("== P3 behaviour through the real scan (fresh instance per helper) ==")
for _, k in hn do
	local m = newRoblox()
	m[k] = helpers[k]
	print(`  {k}: D.Frame\{Name='x', TextLabel\} => ` .. E(function() m.Declaration.Frame { Name = "x", m.Declaration.TextLabel {} } end))
end
do
	local m = newRoblox()
	m:AddPlugin(function() return { isConfig = helpers.isConfig } end)
	T("  AddPlugin isConfig then D.Frame{Name='x'}", function() m.Declaration.Frame { Name = "x" } end)
end

print("== P4 provider brand still named in no-match diagnostic ==")
do
	local m = newRoblox()
	m.isNonEmptyList = helpers.isNonEmptyList
	T("  D.Frame{ Bogus = Tween{Value=1} } (want 'got Tween' / provider hint)", function() m.Declaration.Frame { Bogus = m.Tween({ Value = 1 }) } end)
	T("  D.Frame{ Bogus = {1,2} } (plain table)", function() m.Declaration.Frame { Bogus = { 1, 2 } } end)
	T("  D.Frame{ Bogus = Source(1) }", function() m.Declaration.Frame { Bogus = m.Source(1) } end)
end

print("== P5 cost: first-diagnostic time with 50 helpers (probe runs once per fn, weak cache) ==")
do
	local m = newRoblox()
	for i = 1, 50 do m["isH" .. i] = function(v) return type(v) == "table" and v.__h == i end end
	local c = os.clock()
	E(function() m.Declaration.Frame { Bogus = { 1 } } end)
	local t1 = os.clock() - c
	c = os.clock()
	for _ = 1, 100 do E(function() m.Declaration.Frame { Bogus = { 1 } } end) end
	local t2 = (os.clock() - c) / 100
	print(string.format("  first failing call %.3f ms, subsequent avg %.3f ms", t1 * 1000, t2 * 1000))
end
