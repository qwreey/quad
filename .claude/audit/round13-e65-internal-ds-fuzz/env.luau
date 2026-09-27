--!nocheck
-- E65 environment: one install (quad-roblox/luau_packages — typing-limits 8.34), base + mock backend.
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local mock = require("../../../quad-base/test/mock")
local E = { Quad = Quad, mock = mock }
function E.newBase()
	local q = Quad.New()
	q:UseProvider(mock.mockProvider)
	return q
end
function E.id(err)
	local s = tostring(err)
	return s:match("Quad%d%d%d%d") or ("RAW:" .. (s:gsub("\n.*", "")))
end
return E
