--!strict
--[[
	M3 icon button: 40x40 container, 24 px icon, shape full. Variants Standard / Filled / Tonal / Outlined,
	optional toggle (`Selected`).

	    IconButton({ Icon = "rbxassetid://123", OnClick = more })                        -- Standard
	    IconButton({ Variant = "Filled", Icon = "rbxassetid://456", Selected = liked })  -- toggle
	Props (all `read`):
	  Variant   "Standard" | "Filled" | "Tonal" | "Outlined"     default "Standard"
	  Icon      string | State<string>         image asset id (required)
	  Selected  boolean | State<boolean>?      nil = plain button; a value = TOGGLE button: the variant's
	                                           M3 unselected/selected colors apply (Standard: icon turns primary;
	                                           Filled: surfaceContainerHighest -> primary; Tonal:
	                                           surfaceContainerHighest -> secondaryContainer; Outlined: outlined ->
	                                           inverseSurface). The component does not flip it — `OnClick`
	                                           should `:Set` the Source you passed.
	  ContentColor  Color3 | State<Color3>?    the icon (and state layer) color of the plain / unselected look, in place of the
	                                           variant's role — Compose `IconButtonColors.contentColor`; Compose's standard icon
	                                           button takes `LocalContentColor` from its container, which the kit has not, so the
	                                           app bars / toolbars pass their own icon color here (a raw role State such as
	                                           `theme.Raw.OnSurface` animates like the roles; the selected look keeps its role)
	  Disabled, OnClick (() -> ()), Theme, Modifier, Hooks   as Button (Hooks: extra array-part values, see Button)
	  TouchTarget  boolean?                   default false = the host IS the 40x40 container (instance count minimal, no layout
	                                           surprise in toolbars laid out at 40 px pitch). true = M3's 48 dp touch target:
	                                           the host becomes a 48x48 TRANSPARENT TextButton that owns the input
	                                           (hover/press/focus, Activated, Interactable, Hooks) and the 40x40 visual
	                                           (container color, outline, state layer, icon) is a centered child Frame
	                                           named "Container" (+1 instance). `Modifier` then applies to the 48x48 host.
	Returns the host `TextButton`. Hit target is the 40x40 container unless `TouchTarget` is set.
	Instances at rest: TextButton + UICorner + state layer (Frame + UICorner + UIStroke) + Icon = 6
	(+1 UIStroke for Outlined; +1 Container frame with TouchTarget).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Interactive = require("../Interactive")
local Style = require("./Style")
local ColorTokens = require("../Tokens/Color")
local D = q.Declaration
local iconButtonName = D.Modifier.TextButton():Name("IconButton")

export type Variant = "Standard" | "Filled" | "Tonal" | "Outlined"


export type Props = {
	read Variant: Variant?,
	read Icon: string | q.State<string>,
	read Selected: (boolean | q.State<boolean>)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnClick: (() -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
	read TouchTarget: boolean?,
	read ContentColor: (Color3 | q.State<Color3>)?,
}

type Look = { Container: ColorTokens.Role?, Content: ColorTokens.Role, Stroke: boolean }
type Spec = { Default: Look, Unselected: Look, Selected: Look }

local Specs: { [Variant]: Spec } = {
	Standard = {
		Default = { Container = nil, Content = "OnSurfaceVariant", Stroke = false },
		Unselected = { Container = nil, Content = "OnSurfaceVariant", Stroke = false },
		Selected = { Container = nil, Content = "Primary", Stroke = false },
	},
	Filled = {
		Default = { Container = "Primary", Content = "OnPrimary", Stroke = false },
		Unselected = { Container = "SurfaceContainerHighest", Content = "Primary", Stroke = false },
		Selected = { Container = "Primary", Content = "OnPrimary", Stroke = false },
	},
	Tonal = {
		Default = { Container = "SecondaryContainer", Content = "OnSecondaryContainer", Stroke = false },
		Unselected = { Container = "SurfaceContainerHighest", Content = "OnSurfaceVariant", Stroke = false },
		Selected = { Container = "SecondaryContainer", Content = "OnSecondaryContainer", Stroke = false },
	},
	Outlined = {
		Default = { Container = nil, Content = "OnSurfaceVariant", Stroke = true },
		Unselected = { Container = nil, Content = "OnSurfaceVariant", Stroke = true },
		Selected = { Container = "InverseSurface", Content = "InverseOnSurface", Stroke = false },
	},
}

local baseModifier = D.Modifier.TextButton()
	:Size(UDim2.fromOffset(40, 40))
	:BorderSizePixel(0)
	:AutoButtonColor(false)
	:Text("")

local function IconButton(props: Props)
	local theme = Theme.resolve(props.Theme)
	local variant: Variant = props.Variant or "Standard"
	local spec = Specs[variant]
	local disabled = Util.asState(props.Disabled)
	local toggle = props.Selected ~= nil
	local selected = Util.asState(props.Selected)
	local corner = Tokens.Shape.corner("Full")

	local fallbackRole: ColorTokens.Role = "Surface"
	local function raw(role: ColorTokens.Role?): q.State<Color3>
		return theme.Raw[if role ~= nil then role else fallbackRole]
	end
	-- the look that applies now: constant (no toggle) or chosen by `selected`
	local function colorOf(pick: (Look) -> ColorTokens.Role?): q.State<Color3>
		if not toggle then
			return raw(pick(spec.Default))
		end
		return Style.choose(selected, raw(pick(spec.Selected)), raw(pick(spec.Unselected)))
	end

	local content = colorOf(function(l)
		return l.Content
	end)
	local given = props.ContentColor
	if given ~= nil then
		local own: q.State<Color3> = if typeof(given) == "Color3" then q.Source(given) else given :: q.State<Color3>
		content = if toggle then Style.choose(selected, raw(spec.Selected.Content), own) else own
	end
	local contentColor = Style.disabledPick(disabled, content, theme.Raw.OnSurface)
	local contentTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)

	local hasContainer = spec.Default.Container ~= nil or spec.Selected.Container ~= nil
	local container = colorOf(function(l)
		return l.Container
	end)
	local containerVisible: q.State<boolean> = selected:Compute(function(self)
		local look = if not toggle then spec.Default elseif self:Get() then spec.Selected else spec.Unselected
		return look.Container ~= nil
	end)
	local containerTransparency: q.State<number> = containerVisible:Compute(function(self, _prev, dis)
		if not self:Get() then
			return 1
		end
		return if dis:Get() then Style.DisabledContainerTransparency else 0
	end, disabled)

	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = Style.animated(content),
		Corner = corner,
	})

	local stroke: Instance? = nil
	if spec.Default.Stroke or spec.Selected.Stroke or spec.Unselected.Stroke then
		local strokeTransparency: q.State<number> = selected:Compute(function(self, _prev, dis)
			if toggle and self:Get() then
				return 1
			end
			return if dis:Get() then Style.DisabledContainerTransparency else 0
		end, disabled)
		stroke = D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,
			Color = Style.disabledPick(disabled, theme.Raw.Outline, theme.Raw.OnSurface),
			Transparency = strokeTransparency:Apply(Style.animation()),
		}
	end
	local interactable: q.State<boolean> = Util.interactable(disabled)
	local hooks = Util.hooks(props.Hooks)

	local icon = D.ImageLabel {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = props.Icon,
		ImageColor3 = contentColor,
		ImageTransparency = contentTransparency,
	}
	local function activated()
		if props.OnClick and not Util.peekBool(disabled) then
			props.OnClick()
		end
	end

	if props.TouchTarget == true then
		return D.TextButton {
			iconButtonName,
			Size = UDim2.fromOffset(48, 48),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			props.Modifier or q.None,
			fx.Hook,
			Interactable = interactable,
			Activated = activated,
			D.Frame {
				Name = "Container",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(40, 40),
				BorderSizePixel = 0,
				BackgroundColor3 = if hasContainer then Style.disabledPick(disabled, container, theme.Raw.OnSurface) else nil,
				BackgroundTransparency = if hasContainer then containerTransparency:Apply(Style.animation()) else 1,
				UICorner = corner,
				stroke or q.None,
				fx.Layer,
				icon,
			},
			table.unpack(hooks),
		}
	end

	return D.TextButton {
		iconButtonName,
		baseModifier,
		props.Modifier or q.None,
		fx.Hook,
		BackgroundColor3 = if hasContainer then Style.disabledPick(disabled, container, theme.Raw.OnSurface) else nil,
		BackgroundTransparency = if hasContainer then containerTransparency:Apply(Style.animation()) else 1,
		Interactable = interactable,
		Activated = activated,
		UICorner = corner,
		stroke or q.None,
		fx.Layer,
		icon,
		table.unpack(hooks),
	}
end

return IconButton
