--!strict
--[[
	M3 common buttons: Filled, Tonal, Elevated, Outlined, Text (one function, `Variant` prop).

	    local Button = require("@self")                         -- via the kit root: Material.Button
	    Button({ Label = "Save", OnClick = save })               -- Filled (default)
	    Button({ Variant = "Outlined", Label = "Cancel", Icon = "rbxassetid://123", OnClick = cancel })
	    Button({ Label = labelState, Disabled = busySource, Modifier = D.Modifier.TextButton():Size(UDim2.new(1, 0, 0, 40)) })

	Props (all `read`):
	  Variant   "Filled" | "Tonal" | "Elevated" | "Outlined" | "Text"        default "Filled"
	  Label     string | State<string>
	  Icon      string | State<string>?      image asset id; presence is decided at construction (an 18 px
	                                         leading icon + 8 px gap, leading padding 16/12 as in M3)
	  Disabled  boolean | State<boolean>?    container onSurface@12 %, content onSurface@38 %, no state layer,
	                                         not clickable/selectable (`Interactable = false`)
	  OnClick   (() -> ())?                  fires on Activated (mouse, touch, gamepad A) unless disabled
	  Theme     Theme?                       default `Theme.default`
	  Modifier  TextButton Modifier?         applied AFTER the base style (later wins) so a caller can resize
	                                         (`Size`, `AutomaticSize`), reposition, set LayoutOrder, ...
	Returns the host `TextButton`.

	Choice: ONE function with a `Variant` prop (not five functions) — the five variants differ only in a small
	table of color roles (Style below), so a shared body is smaller and a wrapper per variant is one line.

	Structure and cost (counted in test/spec.button.luau): host TextButton + UICorner + state layer (Frame +
	UICorner + UIStroke focus ring) + Content Frame (UIPadding + Label) = 8 instances at rest, no icon;
	+ImageLabel +UIListLayout with an icon (10); Outlined +1 UIStroke; Elevated +1 UIShadow.
	The UIPadding and the UIListLayout live on the Content frame, NOT on the host: on the engine a UIPadding
	insets the area that children's scale sizes use, and a UIListLayout positions every GuiObject sibling, so
	on the host they would shrink / list-lay-out the state layer and the ripple CanvasGroup (which must cover
	the whole button and stay put). The layer is a direct child of the host. (Content is AutomaticSize X like the host and
	centered with AnchorPoint/Position 0.5, so a caller-fixed wider host keeps the label centered.) A press adds a transient 4
	(ripple, see Ripple.luau). Compared with RoStrap's RippleButton (40 at rest) and qwreey's round button (70).
	Size: height 40, shape full (pill), width = content + padding (AutomaticSize X); label = LabelLarge.
	Deviation from the spec text: Filled/Tonal do not raise elevation 1 on hover (no shadow instance at all);
	the state layer is the feedback. Elevated does (1 -> 2).
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Elevation = require("./Elevation")
local Text = require("./Text")
local Style = require("@self/Style")
local ColorTokens = require("./Tokens/Color")
local D = q.Declaration

export type Variant = "Filled" | "Tonal" | "Elevated" | "Outlined" | "Text"


export type Props = {
	read Variant: Variant?,
	read Label: string | q.State<string>,
	read Icon: (string | q.State<string>)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnClick: (() -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}

type Spec = {
	Container: ColorTokens.Role?,
	Content: ColorTokens.Role,
	Stroke: boolean,
	Shadow: number?, -- rest elevation; nil = no shadow instance
	PadLeft: number,
	PadLeftIcon: number,
	PadRight: number,
}

-- variant -> color roles. Container nil = transparent.
local Specs: { [Variant]: Spec } = {
	Filled = { Container = "Primary", Content = "OnPrimary", Stroke = false, Shadow = nil, PadLeft = 24, PadLeftIcon = 16, PadRight = 24 },
	Tonal = {
		Container = "SecondaryContainer",
		Content = "OnSecondaryContainer",
		Stroke = false,
		Shadow = nil,
		PadLeft = 24,
		PadLeftIcon = 16,
		PadRight = 24,
	},
	Elevated = {
		Container = "SurfaceContainerLow",
		Content = "Primary",
		Stroke = false,
		Shadow = 1,
		PadLeft = 24,
		PadLeftIcon = 16,
		PadRight = 24,
	},
	Outlined = { Container = nil, Content = "Primary", Stroke = true, Shadow = nil, PadLeft = 24, PadLeftIcon = 16, PadRight = 24 },
	Text = { Container = nil, Content = "Primary", Stroke = false, Shadow = nil, PadLeft = 12, PadLeftIcon = 12, PadRight = 12 },
}

local baseModifier = D.Modifier.TextButton()
	:Size(UDim2.fromOffset(0, 40))
	:AutomaticSize(Enum.AutomaticSize.X)
	:BorderSizePixel(0)
	:AutoButtonColor(false)
	:Text("")
local labelStyle = Text.Label("LabelLarge")

local function Button(props: Props)
	local theme = Theme.resolve(props.Theme)
	local variant: Variant = props.Variant or "Filled"
	local spec = Specs[variant]
	local disabled = Util.asState(props.Disabled)
	local corner = Tokens.Shape.corner("Full")
	local hasIcon = props.Icon ~= nil
	local hooks = Util.hooks(props.Hooks)

	local contentColor = Style.disabledPick(disabled, theme.Raw[spec.Content], theme.Raw.OnSurface)
	local contentTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)
	local interactable: q.State<boolean> = Util.interactable(disabled)

	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = theme.Color[spec.Content],
		Corner = corner,
	})

	local container = spec.Container
	local shadow: Instance? = nil
	if spec.Shadow ~= nil then
		local rest = spec.Shadow
		local level: q.State<number> = fx.Hovered:Compute(function(self, _prev, dis)
			if dis:Get() then
				return 0
			end
			return if self:Get() then rest + 1 else rest
		end, disabled)
		shadow = Elevation.Shadow({ Level = level, Theme = theme })
	end

	local stroke: Instance? = nil
	if spec.Stroke then
		stroke = D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,
			Color = Style.disabledPick(disabled, theme.Raw.Outline, theme.Raw.OnSurface),
			Transparency = Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency),
		}
	end

	local icon: Instance? = nil
	local layout: Instance? = nil
	if hasIcon then
		icon = D.ImageLabel {
			Name = "Icon",
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = props.Icon,
			ImageColor3 = contentColor,
			ImageTransparency = contentTransparency,
			LayoutOrder = 1,
		}
		layout = D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}
	end

	return D.TextButton {
		Name = "Button",
		baseModifier,
		props.Modifier or q.None,
		fx.Hook,
		BackgroundColor3 = if container then Style.disabledPick(disabled, theme.Raw[container], theme.Raw.OnSurface) else nil,
		BackgroundTransparency = if container then Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency) else 1,
		Interactable = interactable,
		Activated = function()
			if props.OnClick and not Util.peekBool(disabled) then
				props.OnClick()
			end
		end,
		UICorner = corner,
		shadow or q.None,
		stroke or q.None,
		fx.Layer,
		D.Frame {
			Name = "Content",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIPadding {
				PaddingLeft = UDim.new(0, if hasIcon then spec.PadLeftIcon else spec.PadLeft),
				PaddingRight = UDim.new(0, spec.PadRight),
			},
			layout or q.None,
			icon or q.None,
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
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				LayoutOrder = 2,
			},
		},
		table.unpack(hooks),
	}
end

return Button
