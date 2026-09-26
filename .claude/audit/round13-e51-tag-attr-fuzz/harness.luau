--!nocheck
-- E51 harness — ONE install (quad-roblox/luau_packages quad_base, typing-limits 8.34) + quad-base mock provider.
-- newQ(log) = Quad.New() + mockProvider + installTagAttrOps(q, log) (observation re-install).
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local mock = require("../../../quad-base/test/mock")

local function newQ(log)
	local q = Quad.New()
	q:UseProvider(mock.mockProvider)
	mock.installTagAttrOps(q, log)
	return q
end

local function idOf(err)
	return string.match(tostring(err), "Quad%d%d%d%d") or ("RAW:" .. (tostring(err):gsub("\n.*", "")))
end

return { Quad = Quad, newQ = newQ, mock = mock, Instance = mock.Instance, idOf = idOf }
