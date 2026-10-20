--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Tokens = require("../src/Tokens")
local Util = require("../src/Util")
local GlyphButton = require("../src/GlyphButton")
local Bounded = require("./support/bounded")

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
	assert(n == 3, "state layer (Frame, UICorner, UIStroke) = 3 below the host, got " .. n)
	-- glyph clipping (Studio QA 2026-10-08): a UICorner on the host would round the host's own TEXT and cut the glyph
	for _, ch in b:GetChildren() do
		assert(ch.ClassName ~= "UICorner", "the text-glyph host carries no UICorner")
	end
	assert(b.LineHeight == 1, "one glyph: LineHeight 1 (its em box is the centered box), got " .. tostring(b.LineHeight))
	assert(H.find(b, "StateLayer").Size == UDim2.fromScale(1, 1), "the round shape is the state layer's own corner")
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
	assert(label.LineHeight == 1, "wrapped glyph label: LineHeight 1")
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

-- Studio QA 2026-10-08 (8th): in the date picker modal (a card under a UIScale — .92 -> 1 on enter, times a fitting factor
-- < 1 in a small layer) the round mode-toggle's ripple grew only in the top-left and was cut straight short of the right
-- and bottom edges: Ripple wrote absolute pixels as Offsets, which the UIScale shrank a second time. 9th: the box is in
-- LOCAL units (screen pixels / the product of the UIScales above the host) as whole Offsets — never a partial Scale (the
-- AutomaticSize loop). Here the UIScales are real mock instances (one or two nested), and the layout (AbsoluteSize =
-- 40 * product) is set by hand.
H.section("ripple under ancestor UIScales: local-unit Offsets that cover the WHOLE host (the modal's mode toggle)", function()
	local Frame = q.Elem "Frame"
	local UIScale = q.Elem "UIScale"
	local Ripple = require("../src/Ripple")
	for _, scales in { { 0.8 }, { 0.92, 0.85 }, { 1.25 } } do
		local b = make({ Name = "ModeToggle", Glyph = "\u{270E}", Position = UDim2.fromOffset(296, 56), OnClick = function() end })
		local root: any = b
		local k = 1
		for _, sc in scales do
			root = Frame { UIScale { Scale = sc }, root }
			k *= sc
		end
		local layer: any = H.find(b, "StateLayer")
		local side = 40 * k
		H.setAbs(b, 500.3, 120.6, side, side)
		H.setAbs(layer, 500.3, 120.6, side, side)
		assert(math.abs(Ripple.localScale(layer) - k) < 1e-9, "UIScale product")
		-- press near the bottom-right: the part of the host the 8th bug never painted
		H.fire(b, "InputBegan", H.input({ Position = Vector3.new(500.3 + side * 0.8, 120.6 + side * 0.8, 0) }))
		local circle = H.find(b, "RippleCircle")
		assert(circle ~= nil, "a ripple")
		assert(circle.Position == UDim2.fromOffset(32, 32), "starts at the press point in LOCAL units (k " .. k .. "): " .. tostring(circle.Position))
		local reachedRight, reachedBottom = false, false
		for _ = 1, 60 do
			H.advance(1 / 120)
			local p, z = circle.Position, circle.Size
			Bounded.assertNoScale(b, "glyph (k " .. k .. ")")
			if Bounded.isCovered(circle) then
				reachedRight, reachedBottom = true, true
				continue
			end
			assert(p.X.Offset >= 0 and p.Y.Offset >= 0 and p.X.Offset + z.X.Offset <= 40 and p.Y.Offset + z.Y.Offset <= 40, "inside the 40-unit host")
			reachedRight = reachedRight or p.X.Offset + z.X.Offset == 40
			reachedBottom = reachedBottom or p.Y.Offset + z.Y.Offset == 40
		end
		assert(reachedRight and reachedBottom, "the disc reaches the right and bottom edges (k " .. k .. ")")
		H.advance(0.5)
		Bounded.assertCovered(circle, "ends covering the whole host (k " .. k .. ")")
		q.dispose(root)
	end
	H.assertNoDebugOutput("ripple under UIScale")
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
