--!nocheck
-- round13 E18 probe D — GS 01 settings-module idiom. Run from repo root.
local q1 = require("./round13-e18-probe-settings1")
local q1b = require("./round13-e18-probe-settings1")
local q2 = require("./round13-e18-probe-settings2")
local Quad = require("../../quad-roblox/luau_packages/quad_base")
print("q1 == q1b", q1 == q1b, "q1 == q2", q1 == q2, "q1 == Quad singleton", q1 == Quad)
print("q1.Theme leaked from settings2:", q1.Theme)
print("Declaration same", q1.Declaration == q2.Declaration)
-- a second copy of the quad_base package (as a vendored dependency would be)
local ok, err = pcall(function()
	local copy = require("../../quad-base/src") -- different module path = different package copy
	print("copy == singleton", copy == Quad, "copy.Version", copy.Version, "copy.moduleIdentity == Quad.moduleIdentity", copy.moduleIdentity == Quad.moduleIdentity)
	print("copy.isState(Quad.Source(1))", copy.isState(Quad.Source(1)))
	local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
	copy:UseProvider(QuadRoblox)
	print("copy got Declaration", copy.Declaration ~= nil)
end)
print("second copy:", ok, err)
