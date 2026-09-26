--!nocheck
-- scratch harness (2026-09-26 doc snippet sweep) — not part of the project's test suite.
-- Sets up a quad-roblox instance with a permissive REFLECTED property table (any
-- property name is writable/readable) plus common Roblox value-type shims, so
-- getting-started/how-to code blocks can be concatenated per chapter and run.

local Quad = require("../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../quad-roblox/src").QuadRoblox
local installProperty = require("../../../quad-roblox/src/Handlers/Property")
local installEvent = require("../../../quad-roblox/src/Handlers/Event")
local installShorthand = require("../../../quad-roblox/src/Handlers/InstanceShorthand")
local installEngineOps = require("../../../quad-roblox/src/EngineOps")
local mock = require("../../../quad-base/test/mock")

local W = { Write = "" }

-- Permissive reflection: any className/propertyName pair is "writable" unless it's
-- one of the known read-only ones below. Real engine calls this a real Instance;
-- our mock just returns whatever list GetPropertiesOfClass hands back.
local READONLY = {
	AbsoluteSize = true,
	AbsolutePosition = true,
	AbsoluteRotation = true,
	AbsoluteCanvasSize = true,
	AbsoluteWindowSize = true,
	TextBounds = true,
	ContentText = true,
}
local reflectedMeta = {
	__index = function(_self, _className)
		return setmetatable({}, {
			__index = function() return nil end,
		})
	end,
}
-- GetPropertiesOfClass needs an array; we fake it with a metatable-backed proxy that,
-- when the Property handler iterates `for _, d in list`, yields nothing special —
-- so instead we take the simpler, correct-enough route used by the real specs: a
-- concrete REFLECTED table covering every class/property this doc corpus touches.
local REFLECTED: { [string]: { any } } = {}
local KNOWN_CLASSES = {
	"Frame", "ScreenGui", "TextLabel", "TextButton", "TextBox", "ScrollingFrame",
	"ImageLabel", "ImageButton", "UICorner", "UIListLayout", "UIPadding", "UIGridLayout",
	"UIStroke", "UIGradient", "UIScale", "UIAspectRatioConstraint", "Folder", "CanvasGroup",
	"ViewportFrame", "VideoFrame",
}
local COMMON_PROPS = {
	"Name", "Parent", "Visible", "Size", "Position", "AnchorPoint", "Rotation",
	"BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderSizePixel",
	"ZIndex", "LayoutOrder", "ClipsDescendants", "Active", "Selectable", "Interactable",
	"AutomaticSize", "SizeConstraint", "Archivable",
	"Text", "TextColor3", "TextSize", "TextScaled", "TextWrapped", "TextXAlignment",
	"TextYAlignment", "Font", "FontFace", "RichText", "PlaceholderText", "PlaceholderColor3",
	"ClearTextOnFocus", "MultiLine", "TextEditable", "CanSubmit",
	"Image", "ImageColor3", "ImageTransparency", "ScaleType",
	"ScrollBarThickness", "ScrollBarImageColor3", "CanvasSize", "CanvasPosition",
	"AutomaticCanvasSize",
	"CornerRadius", "Thickness", "Color", "PaddingLeft", "PaddingRight", "PaddingTop",
	"PaddingBottom", "Offset", "Scale", "FillDirection", "HorizontalAlignment",
	"VerticalAlignment", "SortOrder", "Padding", "Wraps",
	"ResetOnSpawn", "DisplayOrder", "IgnoreGuiInset", "Enabled", "ClassName",
}
for _, className in KNOWN_CLASSES do
	local list = {}
	for _, propName in COMMON_PROPS do
		local d: any = { Name = propName }
		if not READONLY[propName] then
			d.Permits = W
		end
		table.insert(list, d)
	end
	REFLECTED[className] = list
end

local gameShim = mock.gameShim(REFLECTED)

-- events: declare the common ones on every interactive class so `Activated =`,
-- `MouseButton1Click =`, etc. connect instead of raising "no such event".
local COMMON_EVENTS = {
	"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up",
	"MouseEnter", "MouseLeave", "MouseMoved", "InputBegan", "InputEnded",
	"InputChanged", "FocusLost", "Focused", "Changed", "AncestryChanged",
	"Destroying",
}
for _, className in KNOWN_CLASSES do
	mock.declareEvents(className, COMMON_EVENTS)
end

local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installProperty) :: any).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty) :: any).Enum = setmetatable({}, {
	__index = function(_t, k)
		return setmetatable({}, { __index = function(_t2, k2) return k .. "." .. k2 end })
	end,
})
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(installShorthand) :: any).UDim = { new = function(s: number, o: number) return { Scale = s, Offset = o, __udim = true } end }
;(getfenv(installEngineOps) :: any).game = gameShim
local taskShim = {
	delay = function(delay: number, fn: (...any) -> ()): thread
		local th = coroutine.create(fn)
		coroutine.resume(th) -- run synchronously for the doc sweep (no virtual clock needed for most snippets)
		return th
	end,
	cancel = function(th: thread)
		if coroutine.status(th) ~= "dead" then
			coroutine.close(th)
		end
	end,
	wait = function(t: number?) return t or 0 end,
	spawn = function(fn: (...any) -> (), ...: any)
		return coroutine.wrap(fn)(...)
	end,
	defer = function(fn: (...any) -> (), ...: any)
		return coroutine.wrap(fn)(...)
	end,
}
;(getfenv(installEngineOps) :: any).task = taskShim
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance

-- Roblox value-type shims (not part of the real Luau CLI globals).
local function makeUDim(scale: number, offset: number)
	return { Scale = scale, Offset = offset, __udim = true }
end
local UDim = { new = makeUDim }
local UDim2 = {
	new = function(xs, xo, ys, yo) return { X = makeUDim(xs or 0, xo or 0), Y = makeUDim(ys or 0, yo or 0), __udim2 = true } end,
	fromScale = function(xs, ys) return { X = makeUDim(xs or 0, 0), Y = makeUDim(ys or 0, 0), __udim2 = true } end,
	fromOffset = function(xo, yo) return { X = makeUDim(0, xo or 0), Y = makeUDim(0, yo or 0), __udim2 = true } end,
}
local Vector2 = {
	new = function(x, y) return { X = x or 0, Y = y or 0, __vector2 = true } end,
}
local Vector3 = {
	new = function(x, y, z) return { X = x or 0, Y = y or 0, Z = z or 0, __vector3 = true } end,
}
local Color3 = {
	new = function(r, g, b) return { R = r or 0, G = g or 0, B = b or 0, __color3 = true } end,
	fromRGB = function(r, g, b) return { R = (r or 0) / 255, G = (g or 0) / 255, B = (b or 0) / 255, __color3 = true } end,
	fromHSV = function(h, s, v) return { R = h or 0, G = s or 0, B = v or 0, __color3 = true } end,
	fromHex = function(hex) return { __color3 = true, __hex = hex } end,
}
local ColorSequenceKeypoint = { new = function(t, c) return { Time = t, Value = c } end }
local ColorSequence = {
	new = function(a, b)
		if b then return { Keypoints = { ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b) }, __colorsequence = true } end
		return { Keypoints = a, __colorsequence = true }
	end,
}
local NumberSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
local NumberSequence = {
	new = function(a, b)
		if b then return { Keypoints = { NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) }, __numbersequence = true } end
		return { Keypoints = a, __numbersequence = true }
	end,
}
local Rect = { new = function(a, b, c, d) return { Min = { X = a, Y = b }, Max = { X = c, Y = d }, __rect = true } end }
local CFrame = { new = function(...) return { __cframe = true, args = table.pack(...) } end }

local EnumShim = setmetatable({}, {
	__index = function(_t, k)
		return setmetatable({}, { __index = function(_t2, k2) return k .. "." .. k2 end })
	end,
})

local TweenInfoShim = mock.tweenInfoShim

local Players = {
	LocalPlayer = mock.Instance.new("Player") :: any,
}
local function playerGuiFor(player: any)
	if player._playerGui == nil then
		player._playerGui = mock.Instance.new("Folder")
		player._playerGui.Name = "PlayerGui"
		player._playerGui.Parent = player
	end
	return player._playerGui
end
Players.LocalPlayer.WaitForChild = function(_self, name: string)
	if name == "PlayerGui" then
		return playerGuiFor(Players.LocalPlayer)
	end
	error("shim: WaitForChild(" .. name .. ") not supported")
end

local gameGlobal: any = {
	IsLoaded = function() return true end,
	Loaded = { Wait = function() end, Connect = function() end },
	GetService = function(_self, name: string)
		if name == "Players" then return Players end
		return gameShim:GetService(name)
	end,
}

return {
	q = q,
	Quad = Quad,
	QuadRoblox = QuadRoblox,
	mock = mock,
	gameShim = gameShim,
	game = gameGlobal,
	Players = Players,
	task = taskShim,
	UDim = UDim,
	UDim2 = UDim2,
	Vector2 = Vector2,
	Vector3 = Vector3,
	Color3 = Color3,
	ColorSequence = ColorSequence,
	ColorSequenceKeypoint = ColorSequenceKeypoint,
	NumberSequence = NumberSequence,
	NumberSequenceKeypoint = NumberSequenceKeypoint,
	Rect = Rect,
	CFrame = CFrame,
	Enum = EnumShim,
	TweenInfo = TweenInfoShim,
}
