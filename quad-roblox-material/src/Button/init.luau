--!strict
--[[
	M3 common buttons: Filled, Tonal, Elevated, Outlined, Text (one function, `Variant` prop).

	    local Button = require("@self")                         -- via the kit root: Material.Button
	    Button({ Label = "Save", OnClick = save })               -- Filled (default)
	    Button({ Variant = "Outlined", Label = "Cancel", Icon = "rbxassetid://123", OnClick = cancel })
	    Button({ Variant = "Text", Label = "More", Icon = "arrowDown", IconPosition = "Trailing" })   -- an Icons name
	    Button({ Label = labelState, Disabled = busySource, Width = UDim.new(1, 0) })   -- full width, label centered
	    Button({ Label = "OK", Width = 120 })                                              -- fixed 120 px
	The split button (a leading action + a trailing menu button) is `Material.SplitButton` (`./Split.luau`).

	Props (all `read`):
	  Variant   "Filled" | "Tonal" | "Elevated" | "Outlined" | "Text"        default "Filled"
	  Label     string | State<string>
	  Icon      string | State<string>?      an ICON PROP value (`Icons.luau` "ICON PROPS"): an `Icons` name, an image URL,
	                                         or text drawn as a glyph; a State is an image (`Icons.imageOf` per value).
	                                         Presence is decided at construction: an 18 px icon 8 px from the label
	  IconPosition  "Leading" | "Trailing"?  default "Leading" — the icon before or after the label (material-web
	                                         `trailing-icon`; Compose ButtonDefaults.contentPaddingFor hasStartIcon /
	                                         hasEndIcon). Without `Icon` it is ignored.
	  Disabled  boolean | State<boolean>?    container onSurface@10 % (Tonal 12 % — canon), content onSurface@38 %, no state layer,
	                                         not clickable/selectable (`Interactable = false`)
	  OnClick   (() -> ())?                  fires on Activated (mouse, touch, gamepad A) unless disabled
	  Width     (number | UDim)?             a fixed width — a number is pixels, a UDim is scale + offset of the parent
	                                         (`UDim.new(1, 0)` = fill); the label (and icon) is centered in it. nil = the
	                                         width of the content (AutomaticSize X, the M3 default — handy in flex/list
	                                         rows). A label longer than a fixed width overflows: size it for the text.
	  Theme     Theme?                       default `Theme.default`
	  Modifier  TextButton Modifier?         applied AFTER the base style (later wins) so a caller can reposition, set
	                                         LayoutOrder, ... — use `Width` to resize: a `Size` through the Modifier
	                                         keeps AutomaticSize X (Size becomes a minimum) and the label stays at the left
	Returns the host `TextButton`.

	ICON SPACING (material-components/material-web@763a973 tokens/_md-comp-{filled,filled-tonal,elevated,outlined,text}-
	button.scss 94~106 — the hard-coded spaces "until spacing tokens are formally added"; the 18 px icon is
	with-icon.icon.size in tokens/versions/latest/sass, the 8 px gap button/internal/_shared.scss 23; the same numbers as
	Compose ButtonDefaults.ButtonWithIconContentPadding / TextButtonWithIconContentPadding / IconSize / IconSpacing):
	                        no icon      leading icon   trailing icon     (left / right padding, px)
	  Filled, Tonal,
	  Elevated, Outlined    24 / 24      16 / 24        24 / 16
	  Text                  12 / 12      12 / 16        16 / 12

	Choice: ONE function with a `Variant` prop (not five functions) — the five variants differ only in a small
	table of color roles (Style below), so a shared body is smaller and a wrapper per variant is one line.

	Structure and cost (counted in test/spec.button.luau): host TextButton + UICorner + state layer (Frame +
	UICorner + UIStroke focus ring) + Content Frame (UIPadding + Label) = 8 instances at rest, no icon;
	+Icon (ImageLabel, or a TextLabel glyph) +UIListLayout with an icon (10), either position; Outlined +1 UIStroke;
	Elevated +1 UIShadow.
	The UIPadding and the UIListLayout live on the Content frame, NOT on the host: on the engine a UIPadding
	insets the area that children's scale sizes use, and a UIListLayout positions every GuiObject sibling, so
	on the host they would shrink / list-lay-out the state layer and the ripple CanvasGroup (which must cover
	the whole button and stay put). The layer is a direct child of the host. A press adds a transient 3 (ripple, see
	Ripple.luau). Compared with RoStrap's RippleButton (40 at rest) and qwreey's round button (70).
	SIZING — nothing the host measures may depend on the host's own width: with AutomaticSize X the Content frame sits at
	(0, 0) by offset and is AutomaticSize X itself, so the host is exactly content + padding. (An earlier version centered
	Content with AnchorPoint/Position 0.5 — a position that depends on the very width the engine was computing, so the
	host settled to the right width only over several layout passes: labels poked out until a hover/click re-laid it out.)
	The same holds inside Content: its UIListLayout (with an icon) aligns Left — a Center alignment positions the children
	from the frame's width, which AutomaticSize is computing from those positions. The icon and the label are placed by
	`LayoutOrder` (icon 1 / label 2 leading, label 2 / icon 3 trailing), never by a Scale position.
	With `Width` the host is fixed, Content fills it and a UIListLayout centers the label (+1 instance without an icon).
	Size: height 40, shape full (pill), width = content + padding (AutomaticSize X) or `Width`; label = LabelLarge.
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
local IconView = require("./IconView")
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local TextLabel = q.Elem "TextLabel"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local UIStroke = q.Elem "UIStroke"
local TextButtonModifier = q.Modifier "TextButton"
local buttonName = TextButtonModifier():Name("Button")

export type Variant = "Filled" | "Tonal" | "Elevated" | "Outlined" | "Text"
export type IconPosition = "Leading" | "Trailing"


export type Props = {
	read Variant: Variant?,
	read Label: string | q.State<string>,
	read Icon: (string | q.State<string>)?,
	read IconPosition: IconPosition?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnClick: (() -> ())?,
	read Width: (number | UDim)?,
	read Theme: Theme.Theme?,
	read Modifier: q.ModifierInto<TextButton>?,
	read Hooks: Util.Hooks?,
}

type Spec = {
	Container: ColorTokens.Role?,
	Content: ColorTokens.Role,
	Stroke: boolean,
	Shadow: number?, -- rest elevation; nil = no shadow instance
	-- left / right padding: no icon, leading icon, trailing icon (material-web <variant>-button tokens, see the header)
	Pad: { number },
	PadLeading: { number },
	PadTrailing: { number },
}

-- variant -> color roles. Container nil = transparent.
local Specs: { [Variant]: Spec } = {
	Filled = { Container = "Primary", Content = "OnPrimary", Stroke = false, Shadow = nil, Pad = { 24, 24 }, PadLeading = { 16, 24 }, PadTrailing = { 24, 16 } },
	Tonal = {
		Container = "SecondaryContainer",
		Content = "OnSecondaryContainer",
		Stroke = false,
		Shadow = nil,
		Pad = { 24, 24 },
		PadLeading = { 16, 24 },
		PadTrailing = { 24, 16 },
	},
	Elevated = {
		Container = "SurfaceContainerLow",
		Content = "Primary",
		Stroke = false,
		Shadow = 1,
		Pad = { 24, 24 },
		PadLeading = { 16, 24 },
		PadTrailing = { 24, 16 },
	},
	Outlined = { Container = nil, Content = "Primary", Stroke = true, Shadow = nil, Pad = { 24, 24 }, PadLeading = { 16, 24 }, PadTrailing = { 24, 16 } },
	Text = { Container = nil, Content = "Primary", Stroke = false, Shadow = nil, Pad = { 12, 12 }, PadLeading = { 12, 16 }, PadTrailing = { 16, 12 } },
}

local ICON_SIZE = 18 -- md.comp.<variant>-button.with-icon.icon.size / ButtonDefaults.IconSize
local ICON_GAP = 8 -- material-web button/internal/_shared.scss gap / ButtonDefaults.IconSpacing

local baseModifier = TextButtonModifier()
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
	local iconValue = props.Icon
	local hasIcon = iconValue ~= nil
	local trailing = hasIcon and props.IconPosition == "Trailing"
	if props.IconPosition ~= nil and props.IconPosition ~= "Leading" and props.IconPosition ~= "Trailing" then
		Util.fail("Button", `IconPosition must be "Leading" or "Trailing", got {tostring(props.IconPosition)}`)
	end
	local hooks = Util.hooks(props.Hooks)
	local width = props.Width
	local fixed = width ~= nil
	local sizing: q.Modifier<TextButton>? = nil
	if width ~= nil then
		local x = if type(width) == "number" then UDim.new(0, width) else width
		sizing = TextButtonModifier():Size(UDim2.new(x, UDim.new(0, 40))):AutomaticSize(Enum.AutomaticSize.None)
	end

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
		stroke = UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,
			Color = Style.disabledPick(disabled, theme.Raw.Outline, theme.Raw.OnSurface),
			Transparency = Style.disabledNumber(disabled, 0, Style.DisabledButtonContainerTransparency),
		}
	end

	local icon: Instance? = nil
	local layout: Instance? = nil
	if hasIcon or fixed then
		layout = UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			-- Left in an auto-sized Content: a centered layout places its children by the frame's width, the very
			-- width AutomaticSize derives from them (see SIZING); Center only inside a fixed `Width`
			HorizontalAlignment = if fixed then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, ICON_GAP),
		}
	end
	if iconValue ~= nil then
		icon = IconView.new({
			Name = "Icon",
			Icon = iconValue,
			Size = ICON_SIZE,
			Color = contentColor,
			Transparency = contentTransparency,
			LayoutOrder = if trailing then 3 else 1,
		})
	end
	local pad = if not hasIcon then spec.Pad elseif trailing then spec.PadTrailing else spec.PadLeading

	return TextButton {
		buttonName,
		baseModifier,
		sizing or q.None,
		props.Modifier or q.None,
		fx.Hook,
		BackgroundColor3 = if container then Style.disabledPick(disabled, theme.Raw[container], theme.Raw.OnSurface) else nil,
		BackgroundTransparency = if container then Style.disabledNumber(disabled, 0, Style.disabledContainerTransparencyOf(variant)) else 1,
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
		Frame {
			Name = "Content",
			-- auto width: at (0, 0), as wide as its content (see SIZING); fixed width: fills the host
			Size = if fixed then UDim2.fromScale(1, 1) else UDim2.fromScale(0, 1),
			AutomaticSize = if fixed then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UIPadding {
				PaddingLeft = UDim.new(0, pad[1]),
				PaddingRight = UDim.new(0, pad[2]),
			},
			layout or q.None,
			icon or q.None,
			TextLabel {
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
