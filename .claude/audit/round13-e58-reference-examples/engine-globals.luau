--!nocheck
-- [E58 copy] 변경: EasingStyle.Quart, Enum.FrameStyle 추가.
-- Bare-global engine type shims shared by the S10 runners (docs snippets reference
-- UDim2/Color3/Font/Enum/Vector2 as engine globals, not through `game`).
local UDIM2_MT = { __eq = function(a, b) return a.X.Scale == b.X.Scale and a.X.Offset == b.X.Offset and a.Y.Scale == b.Y.Scale and a.Y.Offset == b.Y.Offset end }
local function udim(scale, offset) return { Scale = scale, Offset = offset } end
local UDim2 = {
	new = function(xs, xo, ys, yo) return setmetatable({ X = udim(xs, xo), Y = udim(ys, yo) }, UDIM2_MT) end,
	fromOffset = function(x, y) return setmetatable({ X = udim(0, x), Y = udim(0, y) }, UDIM2_MT) end,
	fromScale = function(x, y) return setmetatable({ X = udim(x, 0), Y = udim(y, 0) }, UDIM2_MT) end,
}
local COLOR3_MT = { __eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end }
local Color3 = {
	fromRGB = function(r, g, b) return setmetatable({ R = r / 255, G = g / 255, B = b / 255 }, COLOR3_MT) end,
	new = function(r, g, b) return setmetatable({ R = r, G = g, B = b }, COLOR3_MT) end,
	fromHSV = function(h, s, v) return setmetatable({ R = h, G = s, B = v }, COLOR3_MT) end,
}
local Font = {
	fromEnum = function(e) return { family = tostring(e) } end,
	new = function(family) return { family = family } end,
}
local Vector2 = {
	new = function(x, y) return { X = x, Y = y } end,
}
local UDim = {
	new = function(s, o) return udim(s, o) end,
}
local function enumTable(names)
	local t = {}
	for _, n in names do t[n] = n end
	return t
end
local Enum = {
	EasingStyle = enumTable({ "Quad", "Linear", "Bounce", "Sine", "Back", "Quart" }),
	EasingDirection = enumTable({ "Out", "In", "InOut" }),
	PlaybackState = enumTable({ "Completed", "Cancelled", "Playing", "Begin", "Paused" }),
	TextXAlignment = enumTable({ "Left", "Center", "Right" }),
	TextYAlignment = enumTable({ "Top", "Center", "Bottom" }),
	FillDirection = enumTable({ "Horizontal", "Vertical" }),
	SortOrder = enumTable({ "LayoutOrder", "Name" }),
	ScrollingDirection = enumTable({ "X", "Y", "XY" }),
	Font = enumTable({ "GothamBold", "Gotham", "SourceSans" }),
	UserInputType = enumTable({ "MouseButton1", "Touch", "Keyboard" }),
	FrameStyle = enumTable({ "Custom", "RobloxRound" }),
	KeyCode = enumTable({ "Return", "Escape", "Space" }),
}

return {
	UDim2 = UDim2,
	Color3 = Color3,
	Font = Font,
	Vector2 = Vector2,
	UDim = UDim,
	Enum = Enum,
}
