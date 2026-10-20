--!strict
local H = require("./support/harness")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Frame = q.Elem "Frame"
local TextButtonModifier = q.Modifier "TextButton"
local Theme = require("../src/Theme")
local Tokens = require("../src/Tokens")
local Button = require("../src/Button")
local IconButton = require("../src/Button/IconButton")
local FAB = require("../src/Button/FAB")
local SplitButton = require("../src/Button/Split")
local Icons = require("../src/Icons")
local Tooltip = require("../src/Tooltip")
local Overlay = require("../src/Overlay")
local Interactive = require("../src/Interactive")
local Util = require("../src/Util")
local Bounded = require("./support/bounded")

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
	assert(btn.BackgroundColor3 == L.OnSurface and near(btn.BackgroundTransparency, 0.9), "container onSurface @ 10 % (FilledButtonTokens)")
	-- token audit 2026-10-13: per variant, as canon — Elevated 10 %, the standalone Tonal button still 12 %, the Outlined
	-- button's outline 10 %
	local disElevated = Button({ Label = "e", Variant = "Elevated", Disabled = true })
	local disTonal = Button({ Label = "t", Variant = "Tonal", Disabled = true })
	local disOutlined = Button({ Label = "o", Variant = "Outlined", Disabled = true })
	H.finishTweens()
	assert(near(disElevated.BackgroundTransparency, 0.9), "Elevated @ 10 %")
	assert(near(disTonal.BackgroundTransparency, 0.88), "Tonal @ 12 % (Button.kt filledTonalButtonColors)")
	assert(near(H.find(disOutlined, "Outline").Transparency, 0.9), "Outlined outline @ 10 %")
	q.dispose(disElevated)
	q.dispose(disTonal)
	q.dispose(disOutlined)
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
	assert(during - rest == 3)
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
		Modifier = TextButtonModifier():Size(UDim2.new(1, 0, 0, 48)),
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
	assert(dis.Interactable == false and near(dis.BackgroundTransparency, 0.9) and H.find(dis, "Icon").ImageColor3 == L.OnSurface, "icon button container @ 10 %")
	local disOutlinedIcon = IconButton({ Variant = "Outlined", Icon = "rbxassetid://1", Disabled = true })
	H.finishTweens()
	assert(near(H.find(disOutlinedIcon, "Outline").Transparency, 0.62), "outlined icon button: the outline fades like the icon, 38 % (OutlinedIconButtonTokens.DisabledOpacity)")
	q.dispose(disOutlinedIcon)
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
	local screen = Frame { overlay.Layer }
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
	local root = Frame {
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

-- ── icon position / values (10th QA) ────────────────────────────────────────
local function padOf(btn: any): (number, number)
	local p = class(btn, "UIPadding")[1]
	return p.PaddingLeft.Offset, p.PaddingRight.Offset
end

H.section("icon position: leading / trailing, the material-web spaces per variant, the icon after the label when trailing", function()
	-- material-web tokens/_md-comp-*-button.scss: no icon / leading icon / trailing icon (left, right)
	local want: { [string]: { { number } } } = {
		Filled = { { 24, 24 }, { 16, 24 }, { 24, 16 } },
		Tonal = { { 24, 24 }, { 16, 24 }, { 24, 16 } },
		Elevated = { { 24, 24 }, { 16, 24 }, { 24, 16 } },
		Outlined = { { 24, 24 }, { 16, 24 }, { 24, 16 } },
		Text = { { 12, 12 }, { 12, 16 }, { 16, 12 } },
	}
	for variant, rows in want do
		local v: any = variant
		local plain = Button({ Variant = v, Label = "x" })
		local lead = Button({ Variant = v, Label = "x", Icon = "rbxassetid://1" })
		local trail = Button({ Variant = v, Label = "x", Icon = "rbxassetid://1", IconPosition = "Trailing" })
		local pl, pr = padOf(plain)
		assert(pl == rows[1][1] and pr == rows[1][2], variant .. " no icon")
		pl, pr = padOf(lead)
		assert(pl == rows[2][1] and pr == rows[2][2], variant .. " leading icon: " .. pl .. "/" .. pr)
		pl, pr = padOf(trail)
		assert(pl == rows[3][1] and pr == rows[3][2], variant .. " trailing icon: " .. pl .. "/" .. pr)
		local li, ll = H.find(lead, "Icon"), H.find(lead, "Label")
		local ti, tl = H.find(trail, "Icon"), H.find(trail, "Label")
		assert(li.LayoutOrder < ll.LayoutOrder and ti.LayoutOrder > tl.LayoutOrder, variant .. ": order follows IconPosition")
		assert(class(trail, "UIListLayout")[1].Padding == UDim.new(0, 8) and ti.Size == UDim2.fromOffset(18, 18), "8 px gap, 18 px icon")
		assert(H.countDescendants(trail) == H.countDescendants(lead), "same instance count either side")
		q.dispose(plain)
		q.dispose(lead)
		q.dispose(trail)
	end
	local noIcon = Button({ Label = "x", IconPosition = "Trailing" })
	assert(H.find(noIcon, "Icon") == nil and select(1, padOf(noIcon)) == 24, "IconPosition without Icon: ignored")
	q.dispose(noIcon)
	assert(not pcall(Button, { Label = "x", Icon = "check", IconPosition = "Left" :: any }), "a bad IconPosition is an error")
	H.assertNoDebugOutput("icon position")
end)

H.section("icon values: an Icons name -> its image (its glyph once overridden away), a URL -> image, other text -> glyph", function()
	local named = Button({ Label = "Done", Icon = "check" })
	local i1 = H.find(named, "Icon")
	assert(i1.ClassName == "ImageLabel" and i1.Image == Icons.Defaults.check, "a name draws its default image")
	local url = Button({ Label = "u", Icon = "rbxassetid://42" })
	assert(H.find(url, "Icon").ClassName == "ImageLabel" and H.find(url, "Icon").Image == "rbxassetid://42")
	local glyph = Button({ Variant = "Text", Label = "Music", Icon = "\u{266A}" })
	local g = H.find(glyph, "Icon")
	assert(g.ClassName == "TextLabel" and g.Text == "\u{266A}" and g.TextSize == 18 and g.LineHeight == 1, "text is a glyph, 18 px, LineHeight 1")
	assert(g.TextColor3 == L.Primary, "glyph in the content color")
	Icons.override({ check = false })
	local fallback = Button({ Label = "Done", Icon = "check" })
	local f = H.find(fallback, "Icon")
	assert(f.ClassName == "TextLabel" and f.Text == Icons.glyph("check"), "overridden away: the glyph")
	Icons.override({ check = Icons.Defaults.check })
	local which = q.Source("arrowDown")
	local stateful = Button({ Variant = "Text", Label = "m", Icon = which, IconPosition = "Trailing" })
	local si = H.find(stateful, "Icon")
	assert(si.ClassName == "ImageLabel" and si.Image == Icons.Defaults.arrowDown)
	which:Set("arrowUp")
	assert(si.Image == Icons.Defaults.arrowUp, "a State follows names through Icons.imageOf")
	for _, b in { named, url, glyph, fallback, stateful } do
		q.dispose(b)
	end
	H.assertNoDebugOutput("icon values")
end)

-- ── SplitButton (M3 Expressive, small) ──────────────────────────────────────
local function face(half: any, clipName: string): any
	return H.find(H.find(half, clipName), "Face")
end
local function cornerOf(inst: any): UDim
	return H.find(inst, "_quad_round").CornerRadius
end
-- lays the two halves out: their content frames measured `lw` / `tw` local px wide (no UIScale in the mock)
local function layoutSplit(sb: any, lw: number, tw: number)
	H.setAbs(H.find(H.find(sb, "Leading"), "Content"), 0, 0, lw, 40)
	H.setAbs(H.find(H.find(sb, "Trailing"), "Content"), 0, 0, tw, 40)
end

H.section("SplitButton: two halves 2 px apart, 48 px minimum, outer corners 20, inner 4, one face per side, instance count", function()
	local sb = SplitButton({ Label = "Save" })
	assert(sb.ClassName == "Frame" and sb.Name == "SplitButton" and sb.AutomaticSize == Enum.AutomaticSize.X and sb.Size == UDim2.fromOffset(0, 40))
	local lay = class(sb, "UIListLayout")[1]
	assert(lay.Parent == sb and lay.Padding == UDim.new(0, 2) and lay.FillDirection == Enum.FillDirection.Horizontal, "BetweenSpace 2")
	local lead, trail = H.find(sb, "Leading"), H.find(sb, "Trailing")
	assert(lead.ClassName == "TextButton" and trail.ClassName == "TextButton" and lead.LayoutOrder < trail.LayoutOrder)
	assert(lead.Size == UDim2.fromOffset(48, 40) and trail.Size == UDim2.fromOffset(48, 40), "unmeasured: the 48 px minimum")
	local n = H.countDescendants(sb)
	print("SplitButton (Filled, no icon) descendants: " .. n .. " (+1 host = " .. (n + 1) .. ")")
	H.resetOutput()
	-- per half: the TextButton 1 + 2 sides x (clip + face + UICorner + StateLayer + its UICorner) = 10 + ring 3 +
	-- Content + UIPadding 2; leading + Label 1 = 17; trailing + arrow 1 + a Selected overlay per face (Frame + UICorner)
	-- x 2 = 4 -> 21; the host's UIListLayout 1 -> 39
	assert(n == 39, "39 descendants, got " .. n)
	layoutSplit(sb, 75.4, 48)
	assert(lead.Size == UDim2.fromOffset(76, 40), "W = ceil(content) = 76: " .. tostring(lead.Size))
	assert(trail.Size == UDim2.fromOffset(48, 40), "trailing: 13 + 22 + 13 = 48")
	-- leading: outer side [0, 38] rounded 20, inner side [38, 76] rounded 4; both faces are the full 76 x 40
	local lo, li = H.find(lead, "OuterClip"), H.find(lead, "InnerClip")
	assert(lo.ClipsDescendants and li.ClipsDescendants and lo.Position == UDim2.fromOffset(0, 0) and lo.Size == UDim2.fromOffset(38, 40))
	assert(li.Position == UDim2.fromOffset(38, 0) and li.Size == UDim2.fromOffset(38, 40))
	assert(face(lead, "OuterClip").Position == UDim2.fromOffset(0, 0) and face(lead, "InnerClip").Position == UDim2.fromOffset(-38, 0))
	assert(face(lead, "OuterClip").Size == UDim2.fromOffset(76, 40) and face(lead, "InnerClip").Size == UDim2.fromOffset(76, 40))
	H.finishTweens()
	assert(cornerOf(face(lead, "OuterClip")) == UDim.new(0, 20) and cornerOf(face(lead, "InnerClip")) == UDim.new(0, 4), "Full outside, ExtraSmall inside")
	-- trailing: inner side first
	local ti, to = H.find(trail, "InnerClip"), H.find(trail, "OuterClip")
	assert(ti.Position == UDim2.fromOffset(0, 0) and ti.Size == UDim2.fromOffset(24, 40) and to.Position == UDim2.fromOffset(24, 0))
	assert(face(trail, "OuterClip").Position == UDim2.fromOffset(-24, 0))
	assert(cornerOf(face(trail, "InnerClip")) == UDim.new(0, 4) and cornerOf(face(trail, "OuterClip")) == UDim.new(0, 20))
	-- colors and content
	assert(face(lead, "OuterClip").BackgroundColor3 == L.Primary and face(trail, "InnerClip").BackgroundColor3 == L.Primary)
	local label = H.find(lead, "Label")
	assert(label.Text == "Save" and label.TextColor3 == L.OnPrimary)
	local lp = class(H.find(lead, "Content"), "UIPadding")[1]
	local tp = class(H.find(trail, "Content"), "UIPadding")[1]
	assert(lp.PaddingLeft == UDim.new(0, 16) and lp.PaddingRight == UDim.new(0, 12), "leading 16 / 12")
	assert(tp.PaddingLeft == UDim.new(0, 13) and tp.PaddingRight == UDim.new(0, 13), "trailing 13 / 13")
	local arrow = H.find(trail, "Icon")
	assert(arrow.ClassName == "ImageLabel" and arrow.Image == Icons.Defaults.chevronDown and arrow.Size == UDim2.fromOffset(22, 22), "keyboard_arrow_down, 22 px")
	assert(arrow.Rotation == 0)
	-- content centered, the trailing one shifted by Compose's optical centering: round(0.11 * (4 - 20)) = -2
	assert(H.find(lead, "Content").Position == UDim2.fromOffset(0, 0), "leading content fills its half")
	assert(H.find(trail, "Content").Position == UDim2.fromOffset(-2, 0), "optical shift -2: " .. tostring(H.find(trail, "Content").Position))
	-- a short label: the half keeps 48 and centers the content
	local short = SplitButton({ Label = "A" })
	layoutSplit(short, 37, 48)
	H.finishTweens()
	assert(H.find(short, "Leading").Size == UDim2.fromOffset(48, 40) and H.find(H.find(short, "Leading"), "Content").Position == UDim2.fromOffset(5, 0))
	q.dispose(short)
	q.dispose(sb)
	H.assertNoDebugOutput("split mount")
end)

H.section("SplitButton: pressed inner corners 4 -> 12; Selected = circle, arrow 180, 10 % overlay; pressed wins over selected", function()
	local selected = q.Source(false)
	local sb = SplitButton({ Label = "Save", Selected = selected })
	layoutSplit(sb, 80, 48)
	local lead, trail = H.find(sb, "Leading"), H.find(sb, "Trailing")
	H.fire(lead, "InputBegan", H.input({ Position = Vector3.new(10, 10, 0) }))
	H.finishTweens()
	assert(cornerOf(face(lead, "InnerClip")) == UDim.new(0, 12), "pressed: CornerValueMedium 12")
	assert(cornerOf(face(trail, "InnerClip")) == UDim.new(0, 4), "only the pressed half morphs")
	H.fire(lead, "InputEnded", H.input({}))
	H.finishTweens()
	assert(cornerOf(face(lead, "InnerClip")) == UDim.new(0, 4))
	selected:Set(true)
	H.finishTweens()
	local arrow = H.find(trail, "Icon")
	assert(cornerOf(face(trail, "InnerClip")) == UDim.new(0, 20) and cornerOf(face(trail, "OuterClip")) == UDim.new(0, 20), "circle shape")
	assert(arrow.Rotation == 180, "the arrow turns over")
	assert(H.find(trail, "Content").Position == UDim2.fromOffset(0, 0), "no optical shift on a symmetric shape")
	for _, clipName in { "InnerClip", "OuterClip" } do
		local overlay = H.find(face(trail, clipName), "Selected")
		assert(overlay.BackgroundColor3 == L.OnPrimary and math.abs(overlay.BackgroundTransparency - 0.9) < 1e-6, "content color @ 10 %")
	end
	H.fire(trail, "InputBegan", H.input({ Position = Vector3.new(10, 10, 0) }))
	H.finishTweens()
	assert(cornerOf(face(trail, "InnerClip")) == UDim.new(0, 12), "pressed wins over selected (shapeByInteraction)")
	assert(H.find(trail, "Content").Position == UDim2.fromOffset(-1, 0), "optical shift round(0.11 * (12 - 20)) = -1")
	H.fire(trail, "InputEnded", H.input({}))
	selected:Set(false)
	H.finishTweens()
	assert(arrow.Rotation == 0 and cornerOf(face(trail, "InnerClip")) == UDim.new(0, 4))
	for _, clipName in { "InnerClip", "OuterClip" } do
		assert(H.find(face(trail, clipName), "Selected").BackgroundTransparency == 1)
	end
	q.dispose(sb)
	H.assertNoDebugOutput("split states")
end)

H.section("SplitButton: one press = two ripples (one per face, each with its face's corner) of the same disc; Offsets only; clicks", function()
	local leads, trails = 0, 0
	local sb = SplitButton({
		Label = "Save",
		OnClick = function()
			leads += 1
		end,
		OnTrailingClick = function()
			trails += 1
		end,
	})
	layoutSplit(sb, 80, 48)
	local lead = H.find(sb, "Leading")
	local layers = H.findAll(lead, function(c: any)
		return c.Name == "StateLayer"
	end)
	assert(#layers == 2, "a state layer per face")
	for _, layer in layers do
		H.setAbs(layer, 100, 50, 80, 40) -- both faces are the half's full rectangle
	end
	H.fire(lead, "InputBegan", H.input({ Position = Vector3.new(160, 62, 0) }))
	local circles = H.findAll(lead, function(c: any)
		return c.Name == "RippleCircle"
	end)
	assert(#circles == 2, "two ripples, got " .. #circles)
	local groups = H.findAll(lead, function(c: any)
		return c.ClassName == "CanvasGroup"
	end)
	H.finishTweens()
	local radii: { [number]: boolean } = {}
	for _, g in groups do
		radii[cornerOf(g).Offset] = true
	end
	assert(radii[20] and radii[12], "the outer ripple clips at 20, the inner one follows the pressed corner 12")
	for _ = 1, 40 do
		H.advance(1 / 60)
		assert(circles[1].Position == circles[2].Position and circles[1].Size == circles[2].Size, "the two discs coincide")
		assert(circles[1].ImageRectOffset == circles[2].ImageRectOffset and circles[1].ImageRectSize == circles[2].ImageRectSize)
	end
	H.fire(lead, "InputEnded", H.input({}))
	H.advance(1)
	-- nothing below the host is a partial Scale (AutomaticSize ancestors — Ripple.luau "NOT SCALE")
	local function ok(u: UDim): boolean
		return u.Scale == 0 or u.Scale == 1
	end
	local function isDrawn(x: any): boolean
		return x.ClassName == "Frame" or x.ClassName == "TextButton" or x.ClassName == "ImageLabel" or x.ClassName == "TextLabel"
	end
	for _, c in H.findAll(sb, isDrawn) do
		local p, z = c.Position or UDim2.new(), c.Size or UDim2.new()
		assert(ok(p.X) and ok(p.Y) and ok(z.X) and ok(z.Y), c.Name .. ": no partial Scale: " .. tostring(p) .. " " .. tostring(z))
	end
	H.fire(lead, "Activated", H.input({}), 1)
	H.fire(H.find(sb, "Trailing"), "Activated", H.input({}), 1)
	assert(leads == 1 and trails == 1, "each half its own callback")
	-- Studio 2026-10-13: the leading half's focus ring (5 px out) was painted over by the trailing half 2 px away (a later
	-- sibling). The half that holds the selection is raised (Segment.luau "FOCUS RING").
	local trailHalf = H.find(sb, "Trailing")
	assert(lead.ZIndex == 1 and trailHalf.ZIndex == 1)
	H.fire(lead, "SelectionGained")
	assert(lead.ZIndex == 2 and trailHalf.ZIndex == 1 and H.find(H.find(lead, "FocusRing"), "Ring").Enabled == true, "the focused half is drawn above the other")
	H.fire(lead, "SelectionLost")
	assert(lead.ZIndex == 1)
	q.dispose(sb)
	H.assertNoDebugOutput("split ripple")
end)

H.section("SplitButton: variants (kit Button roles), Outlined inner outline on every face, icon, disabled", function()
	local tonal = SplitButton({ Variant = "Tonal", Label = "t", Icon = "check" })
	assert(face(H.find(tonal, "Leading"), "OuterClip").BackgroundColor3 == L.SecondaryContainer)
	local icon = H.find(H.find(tonal, "Leading"), "Icon")
	assert(icon.Image == Icons.Defaults.check and icon.Size == UDim2.fromOffset(20, 20), "leading icon 20 px (ButtonSmallTokens.IconSize)")
	assert(class(H.find(tonal, "Leading"), "UIListLayout")[1].Padding == UDim.new(0, 8), "8 px to the label")
	q.dispose(tonal)
	local outlined = SplitButton({ Variant = "Outlined", Label = "o" })
	local strokes = H.findAll(outlined, function(c: any)
		return c.Name == "Outline"
	end)
	assert(#strokes == 4, "one outline per face")
	for _, st in strokes do
		assert(st.BorderStrokePosition == Enum.BorderStrokePosition.Inner and st.Thickness == 1 and st.Color == L.Outline, "inside the face (an outer stroke would be clipped)")
	end
	assert(face(H.find(outlined, "Leading"), "OuterClip").BackgroundTransparency == 1)
	q.dispose(outlined)
	-- Elevated: covered by the next section; here only that the variant mounts with the kit Button's roles
	local elevated0 = SplitButton({ Variant = "Elevated", Label = "e" })
	assert(face(H.find(elevated0, "Leading"), "OuterClip").BackgroundColor3 == L.SurfaceContainerLow and H.find(elevated0, "Label").TextColor3 == L.Primary)
	q.dispose(elevated0)
	assert(not pcall(SplitButton, { Variant = "Text" :: any, Label = "x" }), "no text split button")
	local disabled = q.Source(true)
	local clicks = 0
	local sb = SplitButton({
		Label = "d",
		Disabled = disabled,
		OnClick = function()
			clicks += 1
		end,
	})
	H.finishTweens()
	local lead = H.find(sb, "Leading")
	assert(lead.Interactable == false and H.find(sb, "Trailing").Interactable == false)
	assert(face(lead, "InnerClip").BackgroundColor3 == L.OnSurface and math.abs(face(lead, "InnerClip").BackgroundTransparency - 0.9) < 1e-6, "Filled @ 10 %")
	local sbTonal = SplitButton({ Label = "t", Variant = "Tonal", Disabled = true })
	H.finishTweens()
	assert(math.abs(face(H.find(sbTonal, "Leading"), "InnerClip").BackgroundTransparency - 0.88) < 1e-6, "Tonal SplitButton @ 12 % (canon)")
	q.dispose(sbTonal)
	assert(H.find(lead, "Label").TextColor3 == L.OnSurface and math.abs(H.find(lead, "Label").TextTransparency - 0.62) < 1e-6)
	H.fire(lead, "Activated", H.input({}), 1)
	assert(clicks == 0)
	disabled:Set(false)
	H.fire(lead, "Activated", H.input({}), 1)
	assert(clicks == 1)
	q.dispose(sb)
	assert(uisConns() == baseConns)
	H.assertNoDebugOutput("split variants")
end)

-- Studio QA 2026-10-13: the Elevated shadow curled in at the gap (one caster per half, rounded 20 on all four corners)
-- and the middle of the button had no shadow. Now every face casts its own shadow (outer radius / inner radius) through
-- a clip that is open on the three sides that are not the split line. What it LOOKS like is a Studio matter
-- (.claude/audit/kit-studio-2026-10-13 split-shadow-*.jpg); this pins the structure.
H.section("SplitButton Elevated: a UIShadow per face (the half's own shape), clips open by the shadow's reach outside and by the gap inside", function()
	local selected = q.Source(false)
	local disabled = q.Source(false)
	local sb = SplitButton({ Variant = "Elevated", Label = "Save", Selected = selected, Disabled = disabled })
	local lead, trail = H.find(sb, "Leading"), H.find(sb, "Trailing")
	assert(#H.findAll(sb, function(c: any)
		return c.Name == "ShadowCaster"
	end) == 0, "no caster frame")
	local shadows = class(sb, "UIShadow")
	assert(#shadows == 4, "one UIShadow per face, got " .. #shadows)
	-- Filled 39 (counted above) + 4 UIShadow
	assert(H.countDescendants(sb) == 43, "43 descendants, got " .. H.countDescendants(sb))
	local function shadowOf(half: any, clipName: string): any
		local f = face(half, clipName)
		local sh = class(f, "UIShadow")[1]
		assert(sh ~= nil and sh.Parent == f, clipName .. ": the shadow is the face's own child (it follows the face's UICorner)")
		return sh
	end
	local lv = Tokens.Elevation.Levels
	-- reach = 2 x blur + spread + y-offset of the hovered level (rest 1 + 1)
	local R = 2 * lv[2].BlurRadius + lv[2].Spread + lv[2].OffsetY
	assert(R == 15, "reach 15 with the kit's level 2, got " .. R)
	local function assertGeometry(lw: number, tw: number)
		local lm, tm = math.floor(lw / 2), math.floor(tw / 2)
		local lo, li = H.find(lead, "OuterClip"), H.find(lead, "InnerClip")
		local ti, to = H.find(trail, "InnerClip"), H.find(trail, "OuterClip")
		assert(lead.Size == UDim2.fromOffset(lw, 40) and trail.Size == UDim2.fromOffset(tw, 40), `halves {lead.Size} / {trail.Size}`)
		-- leading: outer side [-R, m], inner side [m, W + 2]; both R above and below
		assert(lo.Position == UDim2.fromOffset(-R, -R) and lo.Size == UDim2.fromOffset(lm + R, 40 + 2 * R), `leading outer clip {lo.Position} {lo.Size}`)
		assert(li.Position == UDim2.fromOffset(lm, -R) and li.Size == UDim2.fromOffset(lw - lm + 2, 40 + 2 * R), `leading inner clip {li.Position} {li.Size}`)
		-- trailing: inner side [-2, m], outer side [m, W + R]
		assert(ti.Position == UDim2.fromOffset(-2, -R) and ti.Size == UDim2.fromOffset(tm + 2, 40 + 2 * R), `trailing inner clip {ti.Position} {ti.Size}`)
		assert(to.Position == UDim2.fromOffset(tm, -R) and to.Size == UDim2.fromOffset(tw - tm + R, 40 + 2 * R), `trailing outer clip {to.Position} {to.Size}`)
		-- every face is still the half's rectangle at the half's origin: clip position + face position = (0, 0)
		for _, pair in { { lead, lw }, { trail, tw } } :: { { any } } do
			for _, clipName in { "OuterClip", "InnerClip" } do
				local c, f = H.find(pair[1], clipName), face(pair[1], clipName)
				assert(c.ClipsDescendants == true and f.Size == UDim2.fromOffset(pair[2], 40), clipName .. " face size")
				assert(c.Position.X.Offset + f.Position.X.Offset == 0 and c.Position.Y.Offset + f.Position.Y.Offset == 0, clipName .. ": the face stays at the half's origin")
			end
		end
	end
	assertGeometry(48, 48) -- unmeasured: the 48 px minimum
	layoutSplit(sb, 75.4, 48)
	assertGeometry(76, 48)
	layoutSplit(sb, 91, 48) -- a longer label: clips, faces (and with them the shadows) follow the half's width
	assertGeometry(91, 48)
	H.finishTweens()
	-- the shadow's shape = its face's corner: outer 20, inner 4 -> 12 pressed -> 20 selected
	assert(cornerOf(face(lead, "OuterClip")) == UDim.new(0, 20) and cornerOf(face(lead, "InnerClip")) == UDim.new(0, 4))
	assert(cornerOf(face(trail, "OuterClip")) == UDim.new(0, 20) and cornerOf(face(trail, "InnerClip")) == UDim.new(0, 4))
	for _, sh in shadows do
		assert(sh.Enabled == true and sh.ShowBehindParent == true and sh.Color == L.Shadow, "level 1 at rest")
		assert(sh.BlurRadius == UDim.new(0, lv[1].BlurRadius) and sh.Offset == UDim2.fromOffset(0, lv[1].OffsetY) and near(sh.Transparency, lv[1].Transparency))
	end
	H.fire(lead, "InputBegan", H.input({ Position = Vector3.new(10, 10, 0) }))
	H.finishTweens()
	assert(cornerOf(shadowOf(lead, "InnerClip").Parent) == UDim.new(0, 12) and cornerOf(shadowOf(lead, "OuterClip").Parent) == UDim.new(0, 20), "pressed: the inner shadow follows 12")
	H.fire(lead, "InputEnded", H.input({}))
	selected:Set(true)
	H.finishTweens()
	assert(cornerOf(shadowOf(trail, "InnerClip").Parent) == UDim.new(0, 20), "selected: the trailing half casts a pill's shadow")
	assertGeometry(91, 48) -- a shape change does not move the clips
	selected:Set(false)
	-- hover raises the hovered half alone (rest + 1), both of its faces together
	H.fire(lead, "MouseEnter")
	H.finishTweens()
	for _, clipName in { "OuterClip", "InnerClip" } do
		assert(shadowOf(lead, clipName).BlurRadius == UDim.new(0, lv[2].BlurRadius) and shadowOf(lead, clipName).Spread == UDim2.fromOffset(lv[2].Spread, lv[2].Spread), "hovered half: level 2")
		assert(shadowOf(trail, clipName).BlurRadius == UDim.new(0, lv[1].BlurRadius), "the other half stays at level 1")
	end
	H.fire(lead, "MouseLeave")
	H.finishTweens()
	assert(shadowOf(lead, "InnerClip").BlurRadius == UDim.new(0, lv[1].BlurRadius))
	-- disabled: no shadow (level 0), translucent container
	disabled:Set(true)
	H.finishTweens()
	for _, sh in shadows do
		assert(sh.Enabled == false, "disabled: shadow off")
	end
	assert(math.abs(face(lead, "InnerClip").BackgroundTransparency - 0.9) < 1e-6, "Elevated @ 10 %")
	disabled:Set(false)
	H.finishTweens()
	assert(shadows[1].Enabled == true)
	-- the other variants: no shadow, clips at the half's rectangle (asserted for Filled in the first SplitButton section)
	local tonal = SplitButton({ Variant = "Tonal", Label = "t" })
	assert(#class(tonal, "UIShadow") == 0 and H.find(H.find(tonal, "Leading"), "OuterClip").Position == UDim2.fromOffset(0, 0))
	assert(H.find(H.find(tonal, "Trailing"), "OuterClip").Size == UDim2.fromOffset(24, 40) and H.countDescendants(tonal) == 39)
	q.dispose(tonal)
	q.dispose(sb)
	H.assertNoDebugOutput("split elevated shadow")
end)

-- Studio QA 2026-10-08, 10th follow-up: an auto-width button (the date picker's month-year button: Text, trailing icon)
-- held until the ripple filled it jumped to the full available width — the disc took Size Scale 1 at full cover. Below a
-- ripple group nothing has any Scale, through the expand and after full cover (Ripple.luau "NOT SCALE", "FULL COVER").
H.section("auto-width buttons: no Scale below the ripple group, through full cover (leading / trailing icon, none)", function()
	for _, o in {
		{ Variant = "Text", Label = "October 2026", Icon = "arrowDown", IconPosition = "Trailing" },
		{ Variant = "Filled", Label = "Save", Icon = "arrowDown" },
		{ Variant = "Outlined", Label = "Cancel" },
	} :: { Button.Props } do
		local btn = Button(o)
		assert(btn.AutomaticSize == Enum.AutomaticSize.X, "auto width")
		Bounded.pressBounded(btn, 121.5, 40, `{o.Variant} {o.IconPosition or ""}`)
		q.dispose(btn)
	end
	H.assertNoDebugOutput("auto-width full cover")
end)

H.done()
