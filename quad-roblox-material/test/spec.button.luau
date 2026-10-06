--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Theme = require("../src/Theme")
local Tokens = require("../src/Tokens")
local Button = require("../src/Button")
local IconButton = require("../src/Button/IconButton")
local FAB = require("../src/Button/FAB")
local Tooltip = require("../src/Tooltip")
local Overlay = require("../src/Overlay")
local Interactive = require("../src/Interactive")
local Util = require("../src/Util")

local UIS = H.UserInputService
local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections
end
local baseConns = uisConns()
local L, Dk = Tokens.Color.Light, Tokens.Color.Dark

local function prop(inst: any, key: string): any
	return inst[key]
end

-- layer + ripple must be direct children of the host; padding / list layout must NOT be (they inset / lay out siblings)
local function childClasses(inst: any): { [string]: number }
	local out: { [string]: number } = {}
	for _, c in inst:GetChildren() do
		out[c.ClassName] = (out[c.ClassName] or 0) + 1
	end
	return out
end

local function assertLayerLayout(host: any, what: string)
	local cc = childClasses(host)
	assert(cc.UIPadding == nil and cc.UIListLayout == nil, what .. ": no UIPadding / UIListLayout on the host")
	local layer = H.find(host, "StateLayer")
	assert(layer ~= nil and layer.Parent == host, what .. ": state layer is a direct child of the host")
	local content = H.find(host, "Content")
	assert(content ~= nil and content.Parent == host, what .. ": Content frame is a direct child of the host")
	assert(content.BackgroundTransparency == 1)
	local ck = childClasses(content)
	assert(ck.UIPadding == 1, what .. ": UIPadding lives on Content")
	-- auto width: Content at (0, 0) by offset — nothing the auto-sized host measures depends on its own width
	assert(content.AnchorPoint ~= Vector2.new(0.5, 0.5) and content.Position ~= UDim2.fromScale(0.5, 0.5), what .. ": Content placed by offset")
	assert(layer.Parent == host and #layer:GetChildren() >= 1)
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local function class(inst: any, name: string): { any }
	return H.findAll(inst, function(c: any)
		return c.ClassName == name
	end)
end

H.section("Filled button at rest: structure and instance count", function()
	local btn = Button({ Label = "Save" })
	assert(btn.ClassName == "TextButton" and btn.Name == "Button")
	local count = H.countDescendants(btn)
	print("Filled button (no icon) descendants: " .. count .. " (+1 host = " .. (count + 1) .. " instances)")
	H.resetOutput() -- measurement lines are not q.debug output
	assert(count == 7, "UICorner, layer (3), Content, UIPadding, Label... = 7 descendants, got " .. count)
	assertLayerLayout(btn, "filled")
	assert(H.find(btn, "Label").Parent == H.find(btn, "Content"), "label inside Content")
	local label = H.find(btn, "Label")
	assert(label.Text == "Save" and label.TextSize == 14)
	assert(label.FontFace.Family == "rbxasset://fonts/families/Roboto.json" and label.FontFace.Weight == Enum.FontWeight.Medium)
	assert(btn.BackgroundColor3 == L.Primary and btn.BackgroundTransparency == 0)
	assert(label.TextColor3 == L.OnPrimary and label.TextTransparency == 0)
	assert(btn.Size == UDim2.fromOffset(0, 40) and btn.AutomaticSize == Enum.AutomaticSize.X, "height 40, width auto")
	assert(btn.AutoButtonColor == false and btn.Text == "" and btn.Interactable == true)
	assert(#class(btn, "UIPadding") == 1)
	local p = class(btn, "UIPadding")[1]
	assert(p.PaddingLeft == UDim.new(0, 24) and p.PaddingRight == UDim.new(0, 24), "24 px horizontal padding")
	assert(H.find(btn, "_quad_round").CornerRadius == UDim.new(0.5, 0), "shape full")
	assert(#class(btn, "CanvasGroup") == 0, "no CanvasGroup at rest")
	assert(btn.SelectionImageObject ~= nil, "default selection box replaced")
	q.dispose(btn)
	H.assertNoDebugOutput("filled rest")
end)

H.section("Width: a fixed width (pixels or UDim), Content fills it and centers the label", function()
	local px = Button({ Label = "OK", Width = 120 })
	assert(px.Size == UDim2.fromOffset(120, 40) and px.AutomaticSize == Enum.AutomaticSize.None, "fixed 120 x 40")
	local content = H.find(px, "Content")
	assert(content.Size == UDim2.fromScale(1, 1) and content.AutomaticSize == Enum.AutomaticSize.None, "Content fills the host")
	local layout = class(content, "UIListLayout")[1]
	assert(layout ~= nil and layout.HorizontalAlignment == Enum.HorizontalAlignment.Center, "label centered by a layout")
	assert(H.countDescendants(px) == 8, "+1 UIListLayout, got " .. H.countDescendants(px))
	local fill = Button({ Label = "Wide", Width = UDim.new(1, -16), Variant = "Outlined" })
	assert(fill.Size == UDim2.new(1, -16, 0, 40) and fill.AutomaticSize == Enum.AutomaticSize.None)
	q.dispose(px)
	q.dispose(fill)
	H.assertNoDebugOutput("button width")
end)

H.section("variants: roles, extra instances", function()
	local function make(v: any)
		return Button({ Variant = v, Label = "X" })
	end
	local tonal = make("Tonal")
	assert(tonal.BackgroundColor3 == L.SecondaryContainer and H.find(tonal, "Label").TextColor3 == L.OnSecondaryContainer)
	assert(H.countDescendants(tonal) == 7)
	local elevated = make("Elevated")
	assert(elevated.BackgroundColor3 == L.SurfaceContainerLow and H.find(elevated, "Label").TextColor3 == L.Primary)
	assert(H.countDescendants(elevated) == 8 and #class(elevated, "UIShadow") == 1, "Elevated adds one UIShadow")
	local outlined = make("Outlined")
	assert(outlined.BackgroundTransparency == 1 and H.find(outlined, "Label").TextColor3 == L.Primary)
	local stroke = H.find(outlined, "Outline")
	assert(stroke ~= nil and stroke.Thickness == 1 and stroke.Color == L.Outline and H.countDescendants(outlined) == 8)
	local text = make("Text")
	assert(text.BackgroundTransparency == 1 and H.countDescendants(text) == 7 and #class(text, "UIStroke") == 1, "text button: only the focus ring stroke")
	local tp = class(text, "UIPadding")[1]
	assert(tp.PaddingLeft == UDim.new(0, 12) and tp.PaddingRight == UDim.new(0, 12))
	for _, b in { tonal, elevated, outlined, text } do
		q.dispose(b)
	end
	H.assertNoDebugOutput("variants")
end)

H.section("icon: leading 18 px image, list layout, padding 16/24", function()
	local icon = q.Source("rbxassetid://111")
	local btn = Button({ Label = "Add", Icon = icon })
	local img = H.find(btn, "Icon")
	assert(img.Image == "rbxassetid://111" and img.Size == UDim2.fromOffset(18, 18) and img.ImageColor3 == L.OnPrimary)
	assert(#class(btn, "UIListLayout") == 1 and H.countDescendants(btn) == 9, "icon + UIListLayout + Content/padding = 9 descendants")
	assertLayerLayout(btn, "icon button")
	assert(childClasses(H.find(btn, "Content")).UIListLayout == 1, "UIListLayout lives on Content")
	local p = class(btn, "UIPadding")[1]
	assert(p.PaddingLeft == UDim.new(0, 16) and p.PaddingRight == UDim.new(0, 24))
	local lay = class(btn, "UIListLayout")[1]
	assert(lay.Padding == UDim.new(0, 8) and lay.FillDirection == Enum.FillDirection.Horizontal)
	icon:Set("rbxassetid://222")
	assert(img.Image == "rbxassetid://222", "Icon State drives the image")
	q.dispose(btn)
	H.assertNoDebugOutput("icon")
end)

H.section("click: OnClick fires; Source -> UI -> input -> Source round trip", function()
	local count = q.Source(0)
	local text: Q.State<string> = count:Compute(function(self)
		return `Clicked {self:Get()}`
	end)
	local btn = Button({
		Label = text,
		OnClick = function()
			count:Set(count:Get() + 1)
		end,
	})
	local label = H.find(btn, "Label")
	assert(label.Text == "Clicked 0")
	H.fire(btn, "Activated", H.input({}), 1)
	H.fire(btn, "Activated", H.input({}), 1)
	assert(count:Get() == 2 and label.Text == "Clicked 2", "UI follows the Source the click wrote")
	q.dispose(btn)
	H.assertNoDebugOutput("click")
end)

H.section("disabled: no click, no layer, disabled colors (Source flips it live)", function()
	local disabled = q.Source(true)
	local clicks = 0
	local btn = Button({
		Label = "Go",
		Disabled = disabled,
		OnClick = function()
			clicks += 1
		end,
	})
	local label = H.find(btn, "Label")
	H.finishTweens()
	assert(btn.Interactable == false, "not interactable while disabled")
	assert(btn.BackgroundColor3 == L.OnSurface and near(btn.BackgroundTransparency, 0.88), "container onSurface @ 12 %")
	assert(label.TextColor3 == L.OnSurface and near(label.TextTransparency, 0.62), "content onSurface @ 38 %")
	H.fire(btn, "Activated", H.input({}), 1)
	assert(clicks == 0, "disabled swallows the click")
	H.fire(btn, "MouseEnter")
	H.finishTweens()
	assert(H.find(btn, "StateLayer").BackgroundTransparency == 1, "no hover layer while disabled")
	disabled:Set(false)
	H.finishTweens()
	assert(prop(btn, "Interactable") == true and btn.BackgroundColor3 == L.Primary and btn.BackgroundTransparency == 0 and label.TextTransparency == 0)
	H.fire(btn, "Activated", H.input({}), 1)
	assert(clicks == 1)
	q.dispose(btn)
	H.assertNoDebugOutput("disabled")
end)

H.section("hover state layer and gamepad focus ring", function()
	local btn = Button({ Label = "Hi" })
	local layer = H.find(btn, "StateLayer")
	assert(layer.BackgroundColor3 == L.OnPrimary, "layer uses the on color")
	H.fire(btn, "MouseEnter")
	H.finishTweens()
	assert(near(layer.BackgroundTransparency, 0.92), "hover .08")
	H.fire(btn, "SelectionGained")
	H.finishTweens()
	assert(near(layer.BackgroundTransparency, 0.90) and H.find(btn, "FocusRing").Enabled == true, "focus .10 + ring")
	local ring = H.find(btn, "FocusRing")
	assert(ring.Thickness == 3 and ring.Color == L.Secondary and ring.BorderStrokePosition == Enum.BorderStrokePosition.Outer)
	H.fire(btn, "SelectionLost")
	H.fire(btn, "MouseLeave")
	H.finishTweens()
	assert(layer.BackgroundTransparency == 1 and ring.Enabled == false)
	q.dispose(btn)
end)

H.section("press: one transient ripple (4 instances), cleaned up after the fade", function()
	local btn = Button({ Label = "Press me" })
	H.setAbs(btn, 0, 0, 120, 40)
	H.setAbs(H.find(btn, "StateLayer"), 0, 0, 120, 40)
	local rest = H.countDescendants(btn)
	H.fire(btn, "InputBegan", H.input({ Position = Vector3.new(60, 20, 0) }))
	local during = H.countDescendants(btn)
	print("Filled button instances at rest: " .. (rest + 1) .. ", during a ripple: " .. (during + 1))
	H.resetOutput() -- measurement lines are not q.debug output
	assert(during - rest == 4)
	local group = H.find(btn, "Ripple")
	assert(group.Parent == H.find(btn, "StateLayer") and H.find(btn, "StateLayer").Parent == btn, "ripple group under the direct-child layer")
	assert(H.find(btn, "RippleCircle").Position == UDim2.fromOffset(60, 20), "press point is relative to the host's AbsolutePosition")
	H.fire(btn, "InputEnded", H.input({}))
	H.advance(0.4)
	assert(H.countDescendants(btn) == rest, "back to rest")
	q.dispose(btn)
	H.assertNoDebugOutput("press")
end)

H.section("theme: dark switch, per-component theme, caller Modifier overrides the base", function()
	local theme = Theme.new({ Scheme = "light" })
	local btn = Button({
		Label = "Themed",
		Theme = theme,
		Modifier = D.Modifier.TextButton():Size(UDim2.new(1, 0, 0, 48)),
	})
	assert(btn.Size == UDim2.new(1, 0, 0, 48), "caller Modifier wins over the base size")
	assert(btn.BackgroundColor3 == L.Primary)
	theme:SetScheme("dark")
	H.finishTweens()
	assert(btn.BackgroundColor3 == Dk.Primary and H.find(btn, "Label").TextColor3 == Dk.OnPrimary, "follows the scheme")
	-- the default theme is untouched
	local other = Button({ Label = "Default" })
	assert(other.BackgroundColor3 == L.Primary)
	q.dispose(btn)
	q.dispose(other)
	H.assertNoDebugOutput("theme")
end)

H.section("Elevated: hover raises 1 -> 2, disabled drops to 0", function()
	local disabled = q.Source(false)
	local btn = Button({ Variant = "Elevated", Label = "Up", Disabled = disabled })
	local shadow = class(btn, "UIShadow")[1]
	H.finishTweens()
	local lv = Tokens.Elevation.Levels
	assert(shadow.Enabled == true and shadow.BlurRadius == UDim.new(0, lv[1].BlurRadius) and shadow.ShowBehindParent == true)
	assert(near(shadow.Transparency, lv[1].Transparency) and shadow.Color == L.Shadow)
	H.fire(btn, "MouseEnter")
	H.finishTweens()
	assert(shadow.BlurRadius == UDim.new(0, lv[2].BlurRadius) and shadow.Offset == UDim2.fromOffset(0, lv[2].OffsetY), "hover = level 2")
	disabled:Set(true)
	H.finishTweens()
	assert(shadow.Enabled == false, "disabled elevated has no shadow")
	q.dispose(btn)
	H.assertNoDebugOutput("elevated")
end)

H.section("IconButton: 40x40, icon 24, toggle colors follow Selected", function()
	local sel = q.Source(false)
	local clicks = 0
	local ib = IconButton({
		Variant = "Filled",
		Icon = "rbxassetid://5",
		Selected = sel,
		OnClick = function()
			clicks += 1
			sel:Set(not sel:Get())
		end,
	})
	assert(ib.Size == UDim2.fromOffset(40, 40) and ib.ClassName == "TextButton")
	local icon = H.find(ib, "Icon")
	assert(icon.Size == UDim2.fromOffset(24, 24) and icon.Image == "rbxassetid://5")
	assert(H.countDescendants(ib) == 5, "UICorner, layer(3), icon = 5 descendants, got " .. H.countDescendants(ib))
	H.finishTweens()
	assert(ib.BackgroundColor3 == L.SurfaceContainerHighest and icon.ImageColor3 == L.Primary, "unselected filled toggle")
	H.fire(ib, "Activated", H.input({}), 1)
	H.finishTweens()
	assert(clicks == 1 and sel:Get() == true)
	assert(ib.BackgroundColor3 == L.Primary and icon.ImageColor3 == L.OnPrimary, "selected filled toggle")
	q.dispose(ib)

	local std = IconButton({ Icon = "rbxassetid://1" })
	assert(std.BackgroundTransparency == 1 and H.find(std, "Icon").ImageColor3 == L.OnSurfaceVariant)
	local stdSel = q.Source(true)
	local std2 = IconButton({ Icon = "rbxassetid://1", Selected = stdSel })
	assert(H.find(std2, "Icon").ImageColor3 == L.Primary and std2.BackgroundTransparency == 1, "selected standard: primary icon, no container")
	local outlined = IconButton({ Variant = "Outlined", Icon = "rbxassetid://1" })
	assert(H.find(outlined, "Outline") ~= nil and outlined.BackgroundTransparency == 1)
	local dis = IconButton({ Variant = "Tonal", Icon = "rbxassetid://1", Disabled = true })
	H.finishTweens()
	assert(dis.Interactable == false and near(dis.BackgroundTransparency, 0.88) and H.find(dis, "Icon").ImageColor3 == L.OnSurface)
	for _, b in { std, std2, outlined, dis } do
		q.dispose(b)
	end
	H.assertNoDebugOutput("iconbutton")
end)

H.section("FAB: sizes, colors, extended, elevation 3 -> 4", function()
	local fab = FAB({ Icon = "rbxassetid://9" })
	assert(fab.Size == UDim2.fromOffset(56, 56) and H.find(fab, "_quad_round").CornerRadius == UDim.new(0, 16))
	assert(fab.BackgroundColor3 == L.PrimaryContainer and H.find(fab, "Icon").ImageColor3 == L.OnPrimaryContainer)
	local shadow = class(fab, "UIShadow")[1]
	H.finishTweens()
	assert(shadow.BlurRadius == UDim.new(0, Tokens.Elevation.Levels[3].BlurRadius))
	H.fire(fab, "MouseEnter")
	H.finishTweens()
	assert(shadow.BlurRadius == UDim.new(0, Tokens.Elevation.Levels[4].BlurRadius), "hover level 4")
	assert(H.countDescendants(fab) == 6, "UICorner, UIShadow, layer(3), icon = 6, got " .. H.countDescendants(fab))
	assert(childClasses(fab).UIPadding == nil and H.find(fab, "Icon").Parent == fab, "regular FAB: icon is centered directly on the host")
	local small = FAB({ Size = "Small", Color = "Surface", Icon = "rbxassetid://9" })
	assert(small.Size == UDim2.fromOffset(40, 40) and H.find(small, "_quad_round").CornerRadius == UDim.new(0, 12))
	assert(small.BackgroundColor3 == L.SurfaceContainerHigh and H.find(small, "Icon").ImageColor3 == L.Primary)
	local large = FAB({ Size = "Large", Color = "Tertiary", Icon = "rbxassetid://9" })
	assert(large.Size == UDim2.fromOffset(96, 96) and H.find(large, "Icon").Size == UDim2.fromOffset(36, 36))
	assert(large.BackgroundColor3 == L.TertiaryContainer)
	local ext = FAB({ Icon = "rbxassetid://9", Label = "Compose", Color = "Secondary" })
	assert(ext.Size == UDim2.fromOffset(0, 56) and ext.AutomaticSize == Enum.AutomaticSize.X and H.find(ext, "Label").Text == "Compose")
	assertLayerLayout(ext, "extended FAB")
	assert(H.countDescendants(ext) == 10 and H.find(ext, "Icon").Parent == H.find(ext, "Content") and H.find(ext, "Label").Parent == H.find(ext, "Content"))
	assert(childClasses(H.find(ext, "Content")).UIListLayout == 1)
	local clicks = 0
	local dis = FAB({ Icon = "rbxassetid://9", Disabled = true, OnClick = function() clicks += 1 end })
	H.fire(dis, "Activated", H.input({}), 1)
	assert(clicks == 0)
	H.finishTweens()
	assert(class(dis, "UIShadow")[1].Enabled == false)
	for _, b in { fab, small, large, ext, dis } do
		q.dispose(b)
	end
	H.assertNoDebugOutput("fab")
end)

H.section("Hooks pass-through: Tooltip.hook on Button / IconButton / FAB, plus a plain hook; Util.asState default", function()
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	local tip = Tooltip.hook({ Text = "Save it", Overlay = overlay })
	local created = 0
	local btn: any = Button({
		Label = "Save",
		Hooks = { tip.Hook, Util.preHook(function() created += 1 end) },
	})
	H.setAbs(btn, 200, 100, 100, 40)
	H.fire(btn, "MouseEnter")
	H.advance(0.6)
	assert(tip.IsOpen:Get() and created == 1, "tooltip hook on a Button works")
	H.fire(btn, "MouseLeave")
	H.finishTweens()
	H.advance(0.3)
	assert(overlay.Count:Get() == 0)
	-- no hooks / empty hooks: unchanged
	local plain = Button({ Label = "x", Hooks = {} })
	assert(H.countDescendants(plain) == 7)
	local tip2 = Tooltip.hook({ Text = "More", Overlay = overlay })
	local ib: any = IconButton({ Icon = "rbxassetid://1", Hooks = { tip2.Hook } })
	H.setAbs(ib, 0, 0, 40, 40)
	H.fire(ib, "MouseEnter")
	H.advance(0.6)
	assert(tip2.IsOpen:Get(), "IconButton hook")
	H.fire(ib, "MouseLeave")
	H.advance(0.4)
	local tip3 = Tooltip.hook({ Text = "Compose", Overlay = overlay })
	local fab: any = FAB({ Icon = "rbxassetid://1", Label = "Go", Hooks = { tip3.Hook } })
	H.setAbs(fab, 0, 0, 100, 56)
	H.fire(fab, "MouseEnter")
	H.advance(0.6)
	assert(tip3.IsOpen:Get(), "FAB hook")
	H.fire(fab, "MouseLeave")
	H.advance(0.4)
	for _, b in { btn, plain, ib, fab } do
		q.dispose(b)
	end
	q.dispose(screen)
	-- Util.asState default, Interactive.noSelectionImage
	assert(Util.asState(nil):Get() == false and Util.asState(nil, true):Get() == true and Util.asState(false, true):Get() == false)
	assert(Interactive.noSelectionImage() == Interactive.noSelectionImage(), "shared instance")
	H.assertNoDebugOutput("hooks")
end)

H.section("dispose: a whole row of buttons is destroyed, nothing leaks", function()
	local root = D.Frame {
		Button({ Label = "A" }),
		Button({ Variant = "Outlined", Label = "B", Icon = "rbxassetid://1" }),
		IconButton({ Icon = "rbxassetid://2" }),
		FAB({ Icon = "rbxassetid://3" }),
	}
	local all = H.findAll(root, function() return true end)
	H.fire(H.find(root, "Button"), "InputBegan", H.input({ Position = Vector3.new(1, 1, 0) }))
	q.dispose(root)
	for _, c in all do
		assert(H.isDestroyed(c), "undestroyed: " .. c.Name)
	end
	assert(uisConns() == baseConns, "no global connections")
	H.advance(2)
	assert(H.pendingTimers() == 0)
	H.assertNoDebugOutput("dispose")
end)

H.section("D7 IconButton TouchTarget: 48x48 transparent host owns the input, 40x40 Container child draws", function()
	local clicks = 0
	local ib = IconButton({
		Variant = "Filled",
		Icon = "rbxassetid://1",
		TouchTarget = true,
		OnClick = function()
			clicks += 1
		end,
	})
	assert(ib.Size == UDim2.fromOffset(48, 48) and ib.BackgroundTransparency == 1 and ib.ClassName == "TextButton")
	local container = H.find(ib, "Container")
	assert(container.Parent == ib and container.Size == UDim2.fromOffset(40, 40) and container.AnchorPoint == Vector2.new(0.5, 0.5))
	assert(container.BackgroundColor3 == L.Primary and container.BackgroundTransparency == 0, "the visual keeps the container look")
	assert(H.find(container, "StateLayer").Parent == container and H.find(container, "Icon").Parent == container)
	H.fire(ib, "Activated", H.input({}), 1)
	assert(clicks == 1)
	local plain = IconButton({ Icon = "rbxassetid://1" })
	assert(plain.Size == UDim2.fromOffset(40, 40) and H.find(plain, "Container") == nil, "default unchanged")
	q.dispose(ib)
	q.dispose(plain)
	assert(uisConns() == baseConns)
	H.assertNoDebugOutput("touch target")
end)

H.done()
