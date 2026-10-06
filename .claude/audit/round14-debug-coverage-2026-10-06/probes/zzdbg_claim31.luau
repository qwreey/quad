--!nocheck
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")
local W = { Write = "" }
local REFLECTED = { Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W } }, TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } } }
local gameShim = mock.gameShim(REFLECTED)
for _, dbg in { false, true } do
	local q = Quad.New():UseProvider(QuadRoblox)
	;(getfenv(installProperty)).game = gameShim
	;(getfenv(installEvent)).game = gameShim
	;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
	q.Backend.isInst = mock.isMockInstance
	q.debug = dbg
	local root = mock.Instance.foreign("Frame")
	local t = mock.Instance.foreign("TextLabel"); t.Name = "Title"; t.Parent = root
	local M = q.Declaration.Mapper
	local ok, err = pcall(function()
		q.Claim(root, M.Frame(M.Root)({ Size = 2, [2.5] = M.TextLabel("Title")({ Text = "y" }) }))
	end)
	print(`--- [Q0031 Claim fractional array key] debug={dbg}: ok={ok} {string.sub(tostring(err), 1, 200)} rootClaimed={q.Backend.isClaimed(root)} titleClaimed={q.Backend.isClaimed(t)}`)
end
