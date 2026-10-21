--!strict
--[[
	PopupParts — internal building blocks shared by Combo / Menu (the popup widgets). Not part of the public surface
	(init.luau does not export it), but stable for the kit's own files.

		PopupParts.row(spec)          one selectable row (a TextButton): Header look on hover / press / selected / active,
		                              optional check mark, shortcut text or submenu arrow on the right
		PopupParts.stroke(style)      the popup border (UIStroke following PopupBorderSize / Border)
		PopupParts.onEscape(fn)       connects UserInputService.InputBegan and calls `fn` on Escape; returns the
		                              disconnect function. Open it when a popup opens and call the disconnect from the
		                              popup's OnClose — nothing is connected while no popup is open.
		PopupParts.whileOpen(anchor, close)   onEscape(close) + Visibility.whenHidden(anchor, close) in one disconnect:
		                              a popup also closes when its anchor (or the window it is in) is hidden — hiding
		                              an ancestor fires nothing on the anchor, so a closed window would leave it open.

	A row without Check / Shortcut / Arrow is ONE TextButton (+ UIPadding); otherwise the button holds a horizontal list
	of [check] label [shortcut | arrow] (label fills the free width).
]]

local Input = require("./Input")
local Quad = require("./Quad")
local q = Quad
local ImageLabel = q.Elem "ImageLabel"
local TextButton = q.Elem "TextButton"
local TextLabel = q.Elem "TextLabel"
local UIFlexItem = q.Elem "UIFlexItem"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local UIStroke = q.Elem "UIStroke"
local Interaction = require("./Interaction")
local Style = require("./Style")
local Util = require("./Util")
local Visibility = require("./Visibility")

type State<T> = Quad.State<T>
type Style = Style.Style

export type RowSpec = {
	Style: Style,
	Name: string?,
	Text: string | State<string>,
	OnClick: () -> (),
	OnHover: (() -> ())?,
	-- Header-coloured "this is the current choice" look (Combo's selected option)
	Selected: State<boolean>?,
	-- same look, used for "its submenu is open" (Menu)
	Active: State<boolean>?,
	Disabled: State<boolean>?,
	-- toggle rows: the check mark column is reserved, the mark shows while true
	Checked: State<boolean>?,
	Shortcut: string?,
	-- submenu arrow on the right
	Arrow: boolean?,
	-- width: "Fill" = the parent's width (Combo list), "Stretch" = auto-size, then stretched to the widest sibling
	-- (Menu popup), nil = auto-size (bar items)
	Width: ("Fill" | "Stretch")?,
	-- run when the row is destroyed (Menu closes its popup here)
	OnDestroyed: (() -> ())?,
	-- hook values appended at the end of the row's array part (a menu item's tooltip — the `Hooks` prop)
	Hooks: { any }?,
}

local PopupParts = {}

-- a never-changing `false` shared by every row that has no Selected / Active / Disabled state
local NEVER: State<boolean> = q.Source(false)

function PopupParts.onEscape(fn: () -> ()): () -> ()
	local conn = Input.service().InputBegan:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.Escape then
			fn()
		end
	end)
	return function()
		conn:Disconnect()
	end
end

function PopupParts.whileOpen(anchor: Instance, close: () -> ()): () -> ()
	local offEscape = PopupParts.onEscape(close)
	local offHidden = Visibility.whenHidden(anchor, close)
	return function()
		offEscape()
		offHidden()
	end
end

function PopupParts.stroke(style: Style): UIStroke
	return UIStroke({
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = style.Metrics.PopupBorderSize,
		Color = style.Color.Border,
		Transparency = style.Transparency.Border,
	})
end

function PopupParts.row(spec: RowSpec): TextButton
	local style = spec.Style
	local hover = Interaction.hover()
	local selected = spec.Selected or NEVER
	local active = spec.Active or NEVER
	local disabled = spec.Disabled or NEVER

	-- Header / HeaderHovered / HeaderActive (the colour only matters while the row is visibly highlighted)
	local look = Style.interactive(style, "Header", hover.Hovered, hover.Pressed)
	local color = look.Color
	-- fully transparent at rest; hover / press / selected / active show the Header alpha (which already follows
	-- hover / press); a disabled row never highlights
	local alpha: State<number> = hover.Hovered:Compute(function(self, _prev, pressed, sel, act, dis, shown)
		if dis:Get() then
			return 1
		elseif self:Get() or pressed:Get() or sel:Get() or act:Get() then
			return shown:Get()
		end
		return 1
	end, hover.Pressed, selected, active, disabled, look.Transparency)

	local textColor: State<Color3>
	local textAlpha: State<number>
	if spec.Disabled then
		textColor = disabled:Compute(function(self, _prev, normal, dim)
			return if self:Get() then dim:Get() else normal:Get()
		end, style.Color.Text, style.Color.TextDisabled)
		textAlpha = disabled:Compute(function(self, _prev, normal, dim)
			return if self:Get() then dim:Get() else normal:Get()
		end, style.Transparency.Text, style.Transparency.TextDisabled)
	else
		textColor = style.Color.Text
		textAlpha = style.Transparency.Text
	end

	local padX: State<UDim> = Util.pxX(style.Metrics.FramePadding)
	local padY: State<UDim> = Util.pxY(style.Metrics.FramePadding)
	local gap: State<UDim> = Util.pxX(style.Metrics.ItemSpacing)
	local onClick = spec.OnClick
	local onHover = spec.OnHover
	local onDestroyed = spec.OnDestroyed
	local checked = spec.Checked
	local width = spec.Width
	local simple = checked == nil and spec.Shortcut == nil and not spec.Arrow

	local textSquare: State<UDim2> = style.Metrics.TextSize:Compute(function(self)
		local s = math.floor(self:Get() * 0.8)
		return UDim2.fromOffset(s, s)
	end)

	local checkAlpha: State<number>? = nil
	if checked then
		checkAlpha = checked:Compute(function(self, _prev, a)
			return if self:Get() then a:Get() else 1
		end, style.Transparency.CheckMark)
	end

	local function makeLabel(): TextLabel
		return TextLabel({
			Name = "Label",
			Text = spec.Text,
			FontFace = style.Metrics.TextFont,
			TextSize = style.Metrics.TextSize,
			TextColor3 = textColor,
			TextTransparency = textAlpha,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			LayoutOrder = 2,
			UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
		})
	end

	return TextButton({
		hover.Hook,
		Name = spec.Name or "Row",
		-- simple rows carry the text themselves (one instance); composite rows hold labels in a list
		Text = if simple then spec.Text else "",
		FontFace = style.Metrics.TextFont,
		TextSize = style.Metrics.TextSize,
		TextColor3 = textColor,
		TextTransparency = textAlpha,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = color,
		BackgroundTransparency = alpha,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		AutomaticSize = if width == "Fill" then Enum.AutomaticSize.Y else Enum.AutomaticSize.XY,
		Size = if width == "Fill" then UDim2.new(1, 0, 0, 0) else UDim2.fromOffset(0, 0),
		Activated = function()
			if not disabled:Get() then
				onClick()
			end
		end,
		MouseEnter = if onHover
			then function()
				if not disabled:Get() then
					onHover()
				end
			end
			else q.None,
		UIPadding({ PaddingLeft = padX, PaddingRight = padX, PaddingTop = padY, PaddingBottom = padY }),
		if width == "Stretch" then UIFlexItem({ ItemLineAlignment = Enum.ItemLineAlignment.Stretch }) else q.None,
		if simple
			then q.None
			else UIListLayout({
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = gap,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		if checkAlpha
			then ImageLabel({
				Name = "Check",
				LayoutOrder = 1,
				Size = textSquare,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = style.Icons.CheckMark,
				ImageColor3 = style.Color.CheckMark,
				ImageTransparency = checkAlpha,
			})
			else q.None,
		if simple then q.None else makeLabel(),
		if spec.Shortcut
			then TextLabel({
				Name = "Shortcut",
				LayoutOrder = 3,
				Text = spec.Shortcut,
				FontFace = style.Metrics.TextFont,
				TextSize = style.Metrics.TextSize,
				TextColor3 = style.Color.TextDisabled,
				TextTransparency = style.Transparency.TextDisabled,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromOffset(0, 0),
			})
			else q.None,
		if spec.Arrow
			then ImageLabel({
				Name = "Arrow",
				LayoutOrder = 3,
				Size = textSquare,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = style.Icons.RightTriangle,
				ImageColor3 = style.Color.Text,
				ImageTransparency = style.Transparency.Text,
			})
			else q.None,
		if onDestroyed
			then q.OnDestroyed(function()
				onDestroyed()
			end)
			else q.None,
		table.unpack(spec.Hooks or {}),
	})
end

return PopupParts
