--!nocheck
-- round13 E11 probe C — the same user program on the mock backend vs the REAL provider (over mock instances)
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installEngineOps = require("../src/EngineOps")
local mock = require("../../quad-base/test/mock")
local QT = require("../luau_packages/quad_types")
;(getfenv(installEngineOps)).game = mock.gameShim({})
local function try(label, f)
	local ok, e = pcall(f)
	print(string.format("%-62s %s %s", label, ok and "OK " or "ERR", ok and "" or tostring(e)))
end
local function backends()
	local m = mock.newQuad()
	local r = Quad.New():UseProvider(QuadRoblox)
	r.Backend.isInst = mock.isMockInstance -- the quad-roblox specs' own override (real isInst = typeof=="Instance")
	r.errorNamespace.setFuncLevel(QT.ERROR_LEVEL_SURFACE, r.Backend.isInst)
	return { { "mock", m }, { "real", r } }
end
for _, pair in backends() do
	local name, q = pair[1], pair[2]
	print("---- " .. name .. " ----")
	try(name .. ": drive(foreign, { Effect })", function()
		local f = mock.Instance.foreign("Frame")
		q.Dispatch.drive(f, { q.Effect(function() end) })
		print("   isClaimed(foreign) after =", q.Backend.isClaimed(f))
	end)
	try(name .. ": drive(foreign, { Slot })", function()
		local f = mock.Instance.foreign("Frame")
		local s = q.Slot()
		q.Dispatch.drive(f, { s })
	end)
	try(name .. ": drive(Instance.new, { Effect })  [mock: born claimed]", function()
		q.Dispatch.drive(mock.Instance.new("Frame"), { q.Effect(function() end) })
	end)
	try(name .. ": bindLifetime(foreign, {}) then Claim(foreign)", function()
		local f = mock.Instance.foreign("Frame")
		pcall(q.Backend.bindLifetime, f, {})
		q.Claim(f, q.newMapperClass("Frame")(q.MapperRoot)({}))
	end)
	try(name .. ": drive(new, {[AttrKey('T')] = {}})", function()
		q.Dispatch.drive(mock.Instance.new("Frame"), { [q.AttrKey("T")] = {} })
	end)
end
print("---- attr value domain, claimed host (real claims via nativeClaim) ----")
for _, pair in backends() do
	local name, q = pair[1], pair[2]
	local function host()
		local i = mock.Instance.foreign("Frame"); q.Backend.nativeClaim(i); return i
	end
	try(name .. ": drive(host, {[AttrKey('T')] = {}})", function()
		local h = host(); q.Dispatch.drive(h, { [q.AttrKey("T")] = {} }); print("   GetAttribute T type", type(h:GetAttribute("T")))
	end)
	try(name .. ": drive(host, { Attr({S = src}) }); src:Set({})", function()
		local h = host(); local src = q.Source(1); q.Dispatch.drive(h, { q.Attr({ S = src }) }); src:Set({}); print("   GetAttribute S type", type(h:GetAttribute("S")))
	end)
	try(name .. ": drive(host, {[AttrKey('F')] = function})", function()
		local h = host(); q.Dispatch.drive(h, { [q.AttrKey("F")] = function() end })
	end)
end
