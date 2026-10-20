--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Frame = q.Elem "Frame"
local TextButtonModifier = q.Modifier "TextButton"
local Tokens = require("../src/Tokens")
local Chip = require("../src/Chip")
local Icons = require("../src/Icons")

local UIS = H.UserInputService
local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local baseConns = uisConns()
local L = Tokens.Color.Light

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end
local function class(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.ClassName == name
	end)
end

H.section("Assist (outlined) at rest: structure, count, M3 sizes and roles", function()
	local chip = Chip.Assist({ Label = "Directions" })
	assert(chip.ClassName == "TextButton" and chip.Name == "Chip")
	local count = H.countDescendants(chip)
	print("Assist chip instances at rest: " .. (count + 1))
	H.resetOutput()
	assert(count == 9, "UICorner, Outline, layer(3), Content(+UIPadding, UIListLayout), Label = 9, got " .. count)
	assert(chip.Size == UDim2.fromOffset(0, 32) and chip.AutomaticSize == Enum.AutomaticSize.X, "height 32, width auto")
	assert(H.find(chip, "_quad_round").CornerRadius == UDim.new(0, 8), "corner Small = 8")
	assert(chip.BackgroundTransparency == 1, "outlined: no container fill")
	local outline = H.find(chip, "Outline")
	assert(outline.Thickness == 1 and outline.Color == L.Outline and outline.Transparency == 0)
	local label = H.find(chip, "Label")
	assert(label.Text == "Directions" and label.TextSize == 14 and label.TextColor3 == L.OnSurface, "assist label = onSurface")
	local pad = class(chip, "UIPadding")[1]
	assert(pad.PaddingLeft == UDim.new(0, 16) and pad.PaddingRight == UDim.new(0, 16))
	assert(#class(chip, "UIShadow") == 0 and #class(chip, "CanvasGroup") == 0)
	q.dispose(chip)
	H.assertNoDebugOutput("assist rest")
end)

H.section("icon, Elevated and Suggestion variants", function()
	local icon = q.Source("rbxassetid://7")
	local assist = Chip.Assist({ Label = "Go", Icon = icon:Get() })
	local img = H.find(assist, "Icon")
	assert(img.Size == UDim2.fromOffset(18, 18) and img.ImageColor3 == L.Primary and img.Image == "rbxassetid://7")
	assert(class(assist, "UIPadding")[1].PaddingLeft == UDim.new(0, 8), "8 px left with a leading icon")
	local el = Chip.Suggestion({ Label = "Cheap", Elevated = true })
	H.finishTweens()
	assert(el.BackgroundColor3 == L.SurfaceContainerLow and el.BackgroundTransparency == 0)
	assert(#class(el, "UIShadow") == 1 and H.find(el, "Outline") == nil, "elevated: shadow, no outline")
	assert(H.find(el, "Label").TextColor3 == L.OnSurfaceVariant, "suggestion label = onSurfaceVariant")
	local clicks = 0
	local sug = Chip.Suggestion({ Label = "X", OnClick = function() clicks += 1 end })
	H.fire(sug, "Activated", H.input({}), 1)
	assert(clicks == 1)
	for _, c in { assist, el, sug } do
		q.dispose(c)
	end
	H.assertNoDebugOutput("variants")
end)

H.section("Filter: Source round trip, check glyph, colors, outline hides", function()
	local on = q.Source(false)
	local toggles: { boolean } = {}
	local chip = Chip.Filter({
		Label = "Sale",
		Selected = on,
		OnChange = function(v)
			table.insert(toggles, v)
		end,
	})
	H.finishTweens()
	local check = H.find(chip, "Check")
	assert(chip.BackgroundTransparency == 1 and check.Visible == false)
	assert(H.find(chip, "Outline").Transparency == 0)
	assert(class(chip, "UIPadding")[1].PaddingLeft == UDim.new(0, 16))
	assert(H.countDescendants(chip) == 10, "the check (an image by default) adds one instance")
	assert(check.ClassName == "ImageLabel" and check.Image == Icons.asset("check"), "the Material check image (Icons default)")
	H.fire(chip, "Activated", H.input({}), 1)
	H.finishTweens()
	assert(on:Get() == true and toggles[1] == true, "click flips the Source")
	assert(chip.BackgroundColor3 == L.SecondaryContainer and chip.BackgroundTransparency == 0, "selected container")
	assert(H.find(chip, "Label").TextColor3 == L.OnSecondaryContainer and check.Visible == true)
	assert(check.ImageColor3 == L.OnSecondaryContainer and H.find(chip, "Outline").Transparency == 1)
	assert(class(chip, "UIPadding")[1].PaddingLeft == UDim.new(0, 8), "8 px left once the check shows")
	-- external write also drives the UI
	on:Set(false)
	H.finishTweens()
	assert(chip.BackgroundTransparency == 1 and check.Visible == false)
	H.fire(chip, "Activated", H.input({}), 1)
	H.fire(chip, "Activated", H.input({}), 1)
	assert(on:Get() == false and #toggles == 3)
	q.dispose(chip)

	local withIcon = Chip.Filter({ Label = "I", Selected = q.Source(false), Icon = "rbxassetid://3", CheckIcon = "rbxassetid://4" })
	assert(H.find(withIcon, "Icon").Visible == true and H.find(withIcon, "Check").Image == "rbxassetid://4", "image check override")
	H.fire(withIcon, "Activated", H.input({}), 1)
	assert(H.find(withIcon, "Icon").Visible == false and H.find(withIcon, "Check").Visible == true, "check replaces the icon")
	q.dispose(withIcon)
	H.assertNoDebugOutput("filter")
end)

H.section("Input: trailing remove fires OnRemove only, disabled swallows", function()
	local removed, clicked = 0, 0
	local dis = q.Source(false)
	local chip = Chip.Input({
		Label = "ada@example.com",
		Icon = "rbxassetid://9",
		Disabled = dis,
		OnRemove = function()
			removed += 1
		end,
		OnClick = function()
			clicked += 1
		end,
	})
	local rm = H.find(chip, "Remove")
	local rmIcon = H.find(rm, "Icon")
	assert(rm.Size == UDim2.fromOffset(48, 48) and rm.ClassName == "ImageButton", "D7: 48 px touch target")
	assert(rmIcon.Image == Icons.asset("close") and rmIcon.Size == UDim2.fromOffset(18, 18), "the Material close image (Icons default), 18 px")
	assert(rm.Parent == chip and rm.Position == UDim2.new(1, -20, 0.5, 0), "centered 20 px in from the right edge, outside the layout")
	assert(class(chip, "UIPadding")[1].PaddingRight == UDim.new(0, 32), "reserves the 24 px slot + 8")
	H.fire(rm, "Activated", H.input({}), 1)
	assert(removed == 1 and clicked == 0, "remove button does not click the chip")
	H.fire(chip, "Activated", H.input({}), 1)
	assert(clicked == 1)
	dis:Set(true)
	H.finishTweens()
	assert(chip.Interactable == false and rm.Interactable == false)
	assert(near(rmIcon.ImageTransparency, 0.62) and near(chip.BackgroundTransparency, 1), "flat chip stays transparent")
	H.fire(rm, "Activated", H.input({}), 1)
	H.fire(chip, "Activated", H.input({}), 1)
	assert(removed == 1 and clicked == 1)
	assert(near(H.find(chip, "Outline").Transparency, 0.88) and H.find(chip, "Label").TextColor3 == L.OnSurface)
	local plain = Chip.Input({ Label = "no remove" })
	assert(H.find(plain, "Remove") == nil and class(plain, "UIPadding")[1].PaddingRight == UDim.new(0, 16))
	local img = Chip.Input({ Label = "img", OnRemove = function() end, RemoveIcon = "rbxassetid://2" })
	assert(H.find(img, "Remove").ClassName == "ImageButton")
	local ri = H.find(H.find(img, "Remove"), "Icon")
	assert(ri.Image == "rbxassetid://2" and ri.Size == UDim2.fromOffset(18, 18) and ri.AnchorPoint == Vector2.new(0.5, 0.5) and ri.Position == UDim2.fromScale(0.5, 0.5), "centered icon-size image inside the hit host")
	for _, c in { chip, plain, img } do
		q.dispose(c)
	end
	H.assertNoDebugOutput("input")
end)

H.section("hover state layer + press ripple (via Interactive)", function()
	local chip = Chip.Assist({ Label = "Hi" })
	local layer = H.find(chip, "StateLayer")
	H.fire(chip, "MouseEnter")
	H.finishTweens()
	assert(near(layer.BackgroundTransparency, 0.92) and layer.BackgroundColor3 == L.OnSurface)
	H.setAbs(chip, 0, 0, 90, 32)
	H.setAbs(layer, 0, 0, 90, 32)
	local rest = H.countDescendants(chip)
	H.fire(chip, "InputBegan", H.input({ Position = Vector3.new(10, 10, 0) }))
	assert(H.countDescendants(chip) - rest == 3)
	H.fire(chip, "InputEnded", H.input({}))
	H.advance(0.4)
	assert(H.countDescendants(chip) == rest)
	q.dispose(chip)
	H.assertNoDebugOutput("hover")
end)

type Tag = { Id: string, Name: string }

H.section("ChipSet: keyed insert/remove reuses elements, order follows the data", function()
	local tags = q.Source({ { Id = "a", Name = "Alpha" }, { Id = "b", Name = "Beta" } } :: { Tag })
	local set = Chip.ChipSet<<Tag>>({
		Items = tags,
		Key = function(t: Tag)
			return t.Id
		end,
		Render = function(tag: Q.State<Tag>, order: Q.State<number>)
			local name: Q.State<string> = tag:Compute(function(self)
				return self:Get().Name
			end)
			return Chip.Input({
				Label = name,
				Modifier = TextButtonModifier():LayoutOrder(order),
				OnRemove = function() end,
			})
		end,
	})
	local lay = class(set, "UIListLayout")[1]
	assert(lay.Wraps == true and lay.FillDirection == Enum.FillDirection.Horizontal and lay.Padding == UDim.new(0, 8))
	assert(set.AutomaticSize == Enum.AutomaticSize.Y and set.Size == UDim2.new(1, 0, 0, 0))
	local function chips(): { any }
		return H.findAll(set, function(c: any)
			return c.Name == "Chip"
		end)
	end
	assert(#chips() == 2)
	local a = chips()[1]
	local b = chips()[2]
	assert(H.find(a, "Label").Text == "Alpha" and a.LayoutOrder == 1 and b.LayoutOrder == 2)
	tags:Set({ { Id = "c", Name = "Gamma" }, { Id = "a", Name = "Alpha 2" }, { Id = "b", Name = "Beta" } } :: { Tag })
	assert(#chips() == 3)
	local function byLabel(t: string): any
		for _, c in chips() do
			if H.find(c, "Label").Text == t then
				return c
			end
		end
		error("no chip " .. t)
	end
	assert(byLabel("Alpha 2") == a and byLabel("Beta") == b, "same elements reused, text updated through the item State")
	assert(byLabel("Gamma").LayoutOrder == 1 and a.LayoutOrder == 2 and b.LayoutOrder == 3, "order follows the array")
	tags:Set({ { Id = "b", Name = "Beta" } } :: { Tag })
	assert(#chips() == 1 and H.isDestroyed(a) and not H.isDestroyed(b) and b.LayoutOrder == 1)
	q.dispose(set)
	assert(H.isDestroyed(b))
	H.assertNoDebugOutput("chipset")
end)

H.section("dispose: everything destroyed, nothing leaks", function()
	local on = q.Source(true)
	local root = Frame {
		Chip.Assist({ Label = "A", Elevated = true }),
		Chip.Filter({ Label = "F", Selected = on }),
		Chip.Input({ Label = "I", OnRemove = function() end }),
		Chip.Suggestion({ Label = "S" }),
	}
	local all = H.findAll(root, function()
		return true
	end)
	H.fire(H.find(root, "Chip"), "InputBegan", H.input({ Position = Vector3.new(1, 1, 0) }))
	q.dispose(root)
	for _, c in all do
		assert(H.isDestroyed(c), "undestroyed: " .. c.Name)
	end
	assert(uisConns() == baseConns)
	H.advance(2)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("dispose")
end)

H.done()
