--!nocheck
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")
local W = { Write = "" }
local REFLECTED = { Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W } } }
local gameShim = mock.gameShim(REFLECTED)
for _, dbg in { false, true } do
	local q = Quad.New():UseProvider(QuadRoblox)
	;(getfenv(installProperty)).game = gameShim
	;(getfenv(installEvent)).game = gameShim
	;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
	q.Backend.isInst = mock.isMockInstance
	q.debug = dbg
	print(`--- [K5 Slot at a reflected property key Size] debug={dbg}`)
	local ok, err = pcall(function() return q.Declaration.Frame({ Size = q.Slot() }) end)
	print(`  ok={ok} {if ok then "built, Size=" .. tostring(err.Size) else string.sub(tostring(err), 1, 200)}`)
end
