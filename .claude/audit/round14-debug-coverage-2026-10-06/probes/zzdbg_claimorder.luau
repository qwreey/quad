--!nocheck
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")
local W = { Write = "" }
local REFLECTED = { Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W } }, TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } } }
local gameShim = mock.gameShim(REFLECTED)
local q = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installEvent)).game = gameShim
;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local unclaimedSeen = 0
local origProcess = q.Dispatch.process
q.Dispatch.process = function(inst, k, v, i)
	if not q.Backend.isClaimed(inst) then unclaimedSeen += 1; print("  process on UNCLAIMED inst key=" .. tostring(k)) end
	return origProcess(inst, k, v, i)
end
local origDrive = q.Dispatch.drive
q.Dispatch.drive = function(inst, props)
	if not q.Backend.isClaimed(inst) then print("  drive on UNCLAIMED inst") end
	return origDrive(inst, props)
end
print("--- D.Frame build")
local f = q.Declaration.Frame({ Size = 1, q.Declaration.TextLabel({ Text = "x" }) })
print("--- Claim of a foreign tree")
local root = mock.Instance.foreign("Frame")
local t = mock.Instance.foreign("TextLabel"); t.Name = "Title"; t.Parent = root
local M = q.Declaration.Mapper
q.Claim(root, M.Frame(M.Root)({ Size = 2, M.TextLabel("Title")({ Text = "y" }) }))
print("--- raw drive on a foreign alive Frame")
local ff = mock.Instance.foreign("Frame")
local ok, err = pcall(function() origDrive(ff, { Size = 3 }) end)
print("  ok=" .. tostring(ok) .. " " .. tostring(err) .. " Size=" .. tostring(ff.Size))
print("unclaimedSeen(wrapped)=" .. unclaimedSeen)
