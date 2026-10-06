--!strict
--[[
	M3 floating action button: Small (40, radius 12), Regular (56, radius 16), Large (96, radius 28), and the
	Extended form (56 high, radius 16, icon + label) when `Label` is given.

	    FAB({ Icon = "rbxassetid://123", OnClick = compose })                           -- Regular, Primary
	    FAB({ Size = "Large", Color = "Tertiary", Icon = "rbxassetid://123" })
	    FAB({ Icon = "rbxassetid://123", Label = "Compose", OnClick = compose })         -- Extended
	Props (all `read`):
	  Size      "Small" | "Regular" | "Large"        default "Regular" (ignored when `Label` is set)
	  Color     "Surface" | "Primary" | "Secondary" | "Tertiary"   default "Primary"
	            container / content: Surface = surfaceContainerHigh / primary; Primary = primaryContainer /
	            onPrimaryContainer; Secondary = secondaryContainer / onSecondaryContainer; Tertiary =
	            tertiaryContainer / onTertiaryContainer
	  Icon      string | State<string>               image asset id (24 px; 36 px on Large)
	  Label     string | State<string>?              makes it an Extended FAB (LabelLarge text)
	  Disabled, OnClick (() -> ()), Theme, Modifier, Hooks  as Button (Hooks: extra array-part values, see Button)
	Elevation: level 3 at rest, 4 on hover (a UIShadow; see Elevation.luau); 0 when disabled.
	Instances at rest: TextButton + UICorner + UIShadow + state layer (3) + Icon = 7. Extended: the Icon, Label,
	UIListLayout and UIPadding sit on a Content frame (a UIPadding / UIListLayout on the host would inset / list-lay-out
	the state layer and ripple): 7 + Content + Label + UIListLayout + UIPadding = 11.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Interactive = require("../Interactive")
local Elevation = require("../Elevation")
local Text = require("../Text")
local Style = require("./Style")
local ColorTokens = require("../Tokens/Color")
local ShapeTokens = require("../Tokens/Shape")
local D = q.Declaration

export type Size = "Small" | "Regular" | "Large"
export type ColorName = "Surface" | "Primary" | "Secondary" | "Tertiary"


export type Props = {
	read Size: Size?,
	read Color: ColorName?,
	read Icon: string | q.State<string>,
	read Label: (string | q.State<string>)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnClick: (() -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}

local Sizes: { [Size]: { Box: number, Radius: ShapeTokens.Role, Icon: number } } = {
	Small = { Box = 40, Radius = "Medium", Icon = 24 },
	Regular = { Box = 56, Radius = "Large", Icon = 24 },
	Large = { Box = 96, Radius = "ExtraLarge", Icon = 36 },
}

local Colors: { [ColorName]: { Container: ColorTokens.Role, Content: ColorTokens.Role } } = {
	Surface = { Container = "SurfaceContainerHigh", Content = "Primary" },
	Primary = { Container = "PrimaryContainer", Content = "OnPrimaryContainer" },
	Secondary = { Container = "SecondaryContainer", Content = "OnSecondaryContainer" },
	Tertiary = { Container = "TertiaryContainer", Content = "OnTertiaryContainer" },
}

local labelStyle = Text.Label("LabelLarge")

local function FAB(props: Props)
	local theme = Theme.resolve(props.Theme)
	local sizeName: Size = props.Size or "Regular"
	local colorName: ColorName = props.Color or "Primary"
	local sz = Sizes[sizeName]
	local col = Colors[colorName]
	local extended = props.Label ~= nil
	local disabled = Util.asState(props.Disabled)
	local radius: ShapeTokens.Role = if extended then "Large" else sz.Radius
	local corner = Tokens.Shape.corner(radius)

	local contentColor = Style.disabledPick(disabled, theme.Raw[col.Content], theme.Raw.OnSurface)
	local contentTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)
	local interactable: q.State<boolean> = Util.interactable(disabled)

	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = theme.Color[col.Content],
		Corner = corner,
	})
	local level: q.State<number> = fx.Hovered:Compute(function(self, _prev, dis)
		if dis:Get() then
			return 0
		end
		return if self:Get() then 4 else 3
	end, disabled)

	local base = D.Modifier.TextButton()
		:Size(if extended then UDim2.fromOffset(0, 56) else UDim2.fromOffset(sz.Box, sz.Box))
		:BorderSizePixel(0)
		:AutoButtonColor(false)
		:Text("")
	if extended then
		base = base:AutomaticSize(Enum.AutomaticSize.X)
	end

	local iconSize = if extended then 24 else sz.Icon
	local icon = D.ImageLabel {
		Name = "Icon",
		AnchorPoint = if extended then Vector2.new(0, 0.5) else Vector2.new(0.5, 0.5),
		Position = if extended then UDim2.fromScale(0, 0.5) else UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(iconSize, iconSize),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = props.Icon,
		ImageColor3 = contentColor,
		ImageTransparency = contentTransparency,
		LayoutOrder = 1,
	}

	local content: Instance? = nil
	if extended then
		content = D.Frame {
			Name = "Content",
			-- at (0, 0) by offset: the host is AutomaticSize X, so a centered (scale) position would depend on the width
			-- being computed (Button/init.luau "SIZING")
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIPadding { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 20) },
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left, -- auto-sized Content: Left (Button/init.luau "SIZING")
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			},
			icon,
			D.TextLabel {
				Name = "Label",
				labelStyle,
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = props.Label,
				TextColor3 = contentColor,
				TextTransparency = contentTransparency,
				LayoutOrder = 2,
			},
		}
	end
	local hooks = Util.hooks(props.Hooks)

	return D.TextButton {
		Name = "FAB",
		base,
		props.Modifier or q.None,
		fx.Hook,
		BackgroundColor3 = Style.disabledPick(disabled, theme.Raw[col.Container], theme.Raw.OnSurface),
		BackgroundTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency),
		Interactable = interactable,
		Activated = function()
			if props.OnClick and not Util.peekBool(disabled) then
				props.OnClick()
			end
		end,
		UICorner = corner,
		Elevation.Shadow({ Level = level, Theme = theme }),
		fx.Layer,
		content or icon,
		table.unpack(hooks),
	}
end

return FAB
