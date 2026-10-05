--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Tokens = require("../src/Tokens")
local Util = require("../src/Util")
local GlyphButton = require("../src/GlyphButton")

local L = Tokens.Color.Light

-- the built host seen through its concrete class (the mock is class-flat; `GuiButton` has no Text* keys)
local function make(o: GlyphButton.Options): any
	return GlyphButton.new(o)
end

H.section("text glyph, 40 px, state layer: the date picker shape", function()
	local clicks = 0
	local b = make({
		Name = "Prev",
		Glyph = "\u{2039}",
		Position = UDim2.fromOffset(8, 8),
		OnClick = function()
			clicks += 1
		end,
	})
	assert(b.ClassName == "TextButton" and b.Name == "Prev" and b.Text == "\u{2039}")
	assert(b.Size == UDim2.fromOffset(40, 40) and b.Position == UDim2.fromOffset(8, 8) and b.BackgroundTransparency == 1)
	assert(b.TextColor3 == L.OnSurfaceVariant)
	local n = H.countDescendants(b)
	assert(n == 4, "UICorner + state layer (Frame, UICorner, UIStroke) = 4 below the host, got " .. n)
	H.fire(b, "Activated", H.input({}), 1)
	assert(clicks == 1)
	q.dispose(b)
	H.assertNoDebugOutput("glyph text")
end)

H.section("disabled: no click, 38 % content, not interactable (live State)", function()
	local off = q.Source(true)
	local clicks = 0
	local b = make({
		Glyph = "x",
		Disabled = off,
		OnClick = function()
			clicks += 1
		end,
	})
	H.finishTweens()
	assert(b.Interactable == false and math.abs(b.TextTransparency - 0.62) < 1e-6)
	H.fire(b, "Activated", H.input({}), 1)
	assert(clicks == 0)
	off:Set(false)
	H.finishTweens()
	assert(b.Interactable == true and b.TextTransparency == 0)
	q.dispose(b)
end)

H.section("hit target larger than the visual: a Visual circle inside a 48 px host (the Snackbar close)", function()
	local b = make({
		Glyph = "\u{00D7}",
		Size = 36,
		Hit = 48,
		TextSize = 24,
		ColorRole = "InverseOnSurface",
		OnClick = function() end,
	})
	assert(b.Size == UDim2.fromOffset(48, 48) and b.Text == "", "the host is the transparent hit square")
	local visual = H.find(b, "Visual")
	assert(visual.Size == UDim2.fromOffset(36, 36) and visual.AnchorPoint == Vector2.new(0.5, 0.5))
	local label = H.find(visual, "Label")
	assert(label.Text == "\u{00D7}" and label.TextSize == 24 and label.TextColor3 == L.InverseOnSurface)
	assert(H.find(visual, "StateLayer") ~= nil, "the state layer lives in the Visual (clipped to the circle)")
	q.dispose(b)
	-- an asset draws an ImageLabel instead
	local img = make({ Asset = "rbxassetid://5", Glyph = "x", Size = 36, Hit = 48, OnClick = function() end })
	assert(H.find(img, "Icon").ClassName == "ImageLabel" and H.find(img, "Icon").Image == "rbxassetid://5")
	assert(H.find(img, "Icon").Size == UDim2.fromOffset(24, 24) and H.find(img, "Icon").Position == UDim2.fromScale(0.5, 0.5), "wrapped path: centered icon-size image")
	q.dispose(img)
end)

H.section("no layer: a bare hit target that draws the glyph itself (the Chip remove shape); asset = ImageButton", function()
	local c = q.Source(Color3.new(1, 0, 0))
	local t = q.Source(0.25)
	local b = make({
		Glyph = "x",
		Hit = 48,
		Size = 18,
		Layer = false,
		Color = c,
		Transparency = t,
		TextSize = 18,
		AnchorPoint = Vector2.new(0.5, 0.5),
		OnClick = function() end,
	})
	assert(b.Size == UDim2.fromOffset(48, 48) and b.TextSize == 18 and b.AnchorPoint == Vector2.new(0.5, 0.5))
	assert(H.countDescendants(b) == 0, "nothing below the host")
	assert(b.TextColor3 == Color3.new(1, 0, 0) and b.TextTransparency == 0.25, "explicit color / transparency")
	c:Set(Color3.new(0, 1, 0))
	assert(b.TextColor3 == Color3.new(0, 1, 0))
	q.dispose(b)
	local img = make({ Asset = "rbxassetid://6", Layer = false, Hit = 48, Size = 18, OnClick = function() end })
	assert(img.ClassName == "ImageButton" and H.countDescendants(img) == 1)
	local ic = H.find(img, "Icon")
	assert(ic.Image == "rbxassetid://6" and ic.Size == UDim2.fromOffset(24, 24) and ic.Position == UDim2.fromScale(0.5, 0.5), "bare path: centered icon-size ImageLabel (default 24)")
	q.dispose(img)
end)

H.section("Visible State and Hooks reach the host", function()
	local vis = q.Source(false)
	local seen = 0
	local b = make({
		Glyph = "x",
		Visible = vis,
		OnClick = function() end,
		Hooks = {
			Util.preHook(function()
				seen += 1
			end),
		},
	})
	assert(b.Visible == false and seen == 1)
	vis:Set(true)
	assert(b.Visible == true)
	q.dispose(b)
	H.assertNoDebugOutput("glyph misc")
end)

H.done()
