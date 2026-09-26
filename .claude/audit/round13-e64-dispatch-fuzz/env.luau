--!nocheck
-- E64 environment: one install (quad-roblox/luau_packages — typing-limits 8.34).
-- newBase(): fresh Quad.New() + mock backend (lifetime/native ops; base handlers only)
-- newProv(): fresh Quad.New() + real quad-roblox provider (Property/Event/Shorthand/InstanceChild/OnChange) on mock shims
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local installProperty = require("../../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../../quad-roblox/src/Handlers/Event")
local installShorthand = require("../../../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../../../quad-roblox/src/EngineOps")
local mock = require("../../../quad-base/test/mock")
local EG = require("../round13-e44-ref-statemachine/engine-globals")
local W = { Write = "" }
local function props(...)
	local t = {}
	for _, n in { ... } do table.insert(t, { Name = n, Permits = W }) end
	return t
end
local REFLECTED = {
	Frame = props("Name", "Size", "Visible", "ZIndex", "Parent", "Position"),
	TextButton = props("Name", "Size", "Visible", "ZIndex", "Parent", "Text"),
}
mock.declareEvents("Frame", { "MouseEnter", "MouseLeave" })
mock.declareEvents("TextButton", { "MouseEnter", "Activated" })
local gameShim = mock.gameShim(REFLECTED)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty)).Enum = EG.Enum
;(getfenv(installEvent)).game = gameShim
;(getfenv(installEngineOps)).game = gameShim
;(getfenv(installShorthand)).UDim = EG.UDim

local E = { Quad = Quad, mock = mock }
function E.newBase()
	local q = Quad.New()
	q:UseProvider(mock.mockProvider)
	return q
end
function E.newProv()
	local q = Quad.New()
	q:UseProvider(QuadRoblox)
	;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
	q.Backend.isInst = mock.isMockInstance
	return q
end
function E.id(err)
	local s = tostring(err)
	return s:match("Quad%d%d%d%d") or s:match("U[A-Z]+:h%d+") or ("RAW:" .. (s:gsub("\n.*", "")))
end
return E
