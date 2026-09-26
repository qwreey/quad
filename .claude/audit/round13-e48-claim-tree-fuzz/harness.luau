--!nocheck
-- E48 harness — ONE install (quad-roblox/luau_packages, typing-limits 8.34) + quad-base mock tree.
-- Same shim set as quad-roblox/test/spec.claim.luau (+ TweenInfo for axis f). `newQ()` returns a
-- fresh module instance (Quad.New()) — each has its own Relate (claim registry), so axis (g) works.
local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local installProperty = require("../../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../../quad-roblox/src/Handlers/Event")
local mock = require("../../../quad-base/test/mock")

local W = { Write = "" }
local function props(...)
	local t = {}
	for _, n in { ... } do table.insert(t, { Name = n, Permits = W }) end
	return t
end
local REFLECTED = {
	Frame = props("Name", "BackgroundTransparency", "LayoutOrder"),
	ScrollingFrame = props("Name", "BackgroundTransparency", "LayoutOrder"),
	TextLabel = props("Name", "BackgroundTransparency", "LayoutOrder", "Text"),
	TextButton = props("Name", "BackgroundTransparency", "LayoutOrder", "Text"),
	ImageLabel = props("Name", "BackgroundTransparency", "LayoutOrder", "Image"),
	Folder = props("Name"),
	Part = props("Name", "Anchored"),
	GuiObject = props("Name", "BackgroundTransparency"),
}
local gameShim = mock.gameShim(REFLECTED)
;(getfenv(installProperty)).game = gameShim
;(getfenv(installProperty)).TweenInfo = mock.tweenInfoShim
;(getfenv(installEvent)).game = gameShim
local function enumTable(names) local t = {} for _, n in names do t[n] = n end return t end
;(getfenv(installProperty)).Enum = {
	EasingStyle = enumTable({ "Quad", "Linear", "Sine" }),
	EasingDirection = enumTable({ "Out", "In", "InOut" }),
	PlaybackState = enumTable({ "Completed", "Cancelled", "Playing", "Begin", "Paused" }),
}

local function newQ()
	local q = Quad.New():UseProvider(QuadRoblox)
	;(getfenv(q.Declaration.New)).Instance = { new = mock.Instance.new }
	q.Backend.isInst = mock.isMockInstance
	return q
end

local function idOf(err)
	return string.match(tostring(err), "Quad%d%d%d%d") or ("RAW:" .. (tostring(err):gsub("\n.*", "")))
end

return { Quad = Quad, newQ = newQ, mock = mock, Instance = mock.Instance, idOf = idOf, gameShim = gameShim }
