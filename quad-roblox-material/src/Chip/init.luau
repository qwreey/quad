--!strict
--[[
	M3 chips: Assist, Filter, Input, Suggestion (+ `Chip.ChipSet`, a wrapping keyed row of them).

	    Chip.Assist({ Label = "Directions", Icon = "rbxassetid://1", OnClick = go })
	    Chip.Filter({ Label = "Sale", Selected = onSale })                  -- onSale: Source<boolean>, toggled by a click
	    Chip.Input({ Label = "ada@example.com", OnRemove = function() ... end })
	    Chip.Suggestion({ Label = "Cheap flights", Elevated = true, OnClick = pick })
	    Chip.ChipSet({ Items = tags, Key = function(t) return t.Id end, Render = function(tag, order)
	        return Chip.Input({ Label = tag:Compute(function(self) return self:Get().Name end),
	            Modifier = D.Modifier.TextButton():LayoutOrder(order), OnRemove = ... })
	    end })

	Common props (all `read`): Label (string | State<string>), Icon (image asset id; leading 18 px; presence is
	decided at construction), Elevated (boolean?, default false = outlined; the elevated look has no outline and
	a level-1 shadow that rises to 2 on hover), Disabled (boolean | State<boolean>?), OnClick, Theme, Modifier
	(TextButton Modifier applied AFTER the base style so a caller can resize / set LayoutOrder), Hooks (array-part values on the
	host).
	Filter:  Selected (REQUIRED `Source<boolean>` — the chip flips it itself on a click, then calls `OnChange(new)`
	         and `OnClick`); selected = secondaryContainer fill, no outline, a leading check replaces `Icon`.
	         `CheckIcon` (image asset id) overrides the default check glyph.
	Input:   OnRemove (() -> ()?) adds a trailing remove button (18 px "x" glyph, 48 x 48 transparent TOUCH TARGET centered
	         24 px in from the chip's right edge; it is a child of the chip host, outside the Content layout, which reserves
	         its 24 px slot through the right padding); `RemoveIcon` (image asset id) overrides the glyph. The Icon prop is the leading icon/avatar (18 px).
	Assist / Suggestion: only the common props.
	Returns the host `TextButton` (height 32, shape Small = corner 8, width = content, AutomaticSize X, label LabelLarge).

	Roblox deviations: (1) no icon font ships with the kit, so the check and the remove "x" are TEXT GLYPHS
	(`Icons`: check / close) unless an asset id is given (the prop, or one registered with `Icons.override`) — the engine's font fallback draws them; pass `CheckIcon` /
	`RemoveIcon` for pixel-exact art. (2) The trailing remove button sits INSIDE the chip's button: hovering it
	also lights the chip's state layer. Its hit target is 48 x 48 (it overhangs the 32 px chip vertically and 4 px at the
	right edge, as M3's touch target does); the chip body itself stays 32 px high. (3) Filter/Input selected-with-elevation hover rises like the
	unselected one. Everything else follows M3 chip specs (heights, paddings 16/8, outline 1 px Outline,
	disabled onSurface 12 % container / 38 % content).

	Structure and cost (counted in test/spec.chip.luau): host TextButton + UICorner + UIStroke(outline, not
	elevated) + state layer (Frame + UICorner + UIStroke focus ring) + Content frame (UIPadding + UIListLayout) +
	Label = 10 instances at rest for an outlined chip without icon (elevated: 10 too, UIShadow replaces the outline);
	+1 per icon / check / remove button. The padding/layout sit on the Content frame, NOT on the host, because a
	UIPadding/UIListLayout on the host would also inset/lay out the state layer. A press adds a transient 4 (ripple).
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Elevation = require("./Elevation")
local Text = require("./Text")
local Icons = require("./Icons")
local GlyphButton = require("./GlyphButton")
local Style = require("./Button/Style")
local ColorTokens = require("./Tokens/Color")
local KeyedSlot = require("@self/KeyedSlot")
local D = q.Declaration

type Kind = "Assist" | "Filter" | "Input" | "Suggestion"


export type AssistProps = {
	read Label: string | q.State<string>,
	read Icon: string?,
	read Elevated: boolean?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnClick: (() -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}
export type SuggestionProps = AssistProps

export type FilterProps = {
	read Label: string | q.State<string>,
	read Selected: q.Source<boolean>,
	read Icon: string?,
	read CheckIcon: string?,
	read Elevated: boolean?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((selected: boolean) -> ())?,
	read OnClick: (() -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}

export type InputProps = {
	read Label: string | q.State<string>,
	read Icon: string?,
	read RemoveIcon: string?,
	read OnRemove: (() -> ())?,
	read Elevated: boolean?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnClick: (() -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.TextButtonModifier?,
	read Hooks: Util.Hooks?,
}

type Core = {
	Kind: Kind,
	Label: string | q.State<string>,
	Icon: string?,
	Selected: q.Source<boolean>?,
	CheckIcon: string?,
	RemoveIcon: string?,
	OnRemove: (() -> ())?,
	OnChange: ((selected: boolean) -> ())?,
	Hooks: Util.Hooks?,
	Elevated: boolean?,
	Disabled: (boolean | q.State<boolean>)?,
	OnClick: (() -> ())?,
	Theme: Theme.Theme?,
	Modifier: q.TextButtonModifier?,
}

local HEIGHT = 32
local ICON = 18
local REMOVE = 24
local TouchTarget = 48
local RemoveInset = 8 -- the right padding next to the remove slot

local baseModifier = D.Modifier.TextButton()
	:Size(UDim2.fromOffset(0, HEIGHT))
	:AutomaticSize(Enum.AutomaticSize.X)
	:BorderSizePixel(0)
	:AutoButtonColor(false)
	:Text("")
local labelStyle = Text.Label("LabelLarge")

-- An 18 px glyph/image leading or trailing element: an ImageLabel when an asset id is given, else a text glyph.
local function glyphIcon(
	name: string,
	asset: string?,
	glyph: string,
	color: Theme.Animated,
	transparency: Theme.Animated,
	order: number,
	visible: q.State<boolean>?
): Instance
	if asset ~= nil then
		return D.ImageLabel {
			Name = name,
			Size = UDim2.fromOffset(ICON, ICON),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = asset,
			ImageColor3 = color,
			ImageTransparency = transparency,
			LayoutOrder = order,
			Visible = visible,
		}
	end
	return D.TextLabel {
		Name = name,
		labelStyle,
		Size = UDim2.fromOffset(ICON, ICON),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = glyph,
		TextSize = ICON,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextColor3 = color,
		TextTransparency = transparency,
		LayoutOrder = order,
		Visible = visible,
	}
end

local function build(p: Core): TextButton
	local theme = Theme.resolve(p.Theme)
	local R = theme.Raw
	local kind = p.Kind
	local elevated = p.Elevated == true
	local disabled = Util.asState(p.Disabled)
	local selected: q.State<boolean> = p.Selected or q.Source(false)
	local corner = Tokens.Shape.corner("Small")
	local interactable: q.State<boolean> = Util.interactable(disabled)

	-- ── colors (M3 chip roles; selected = secondaryContainer family) ─────────────
	local labelRole: ColorTokens.Role = if kind == "Assist" then "OnSurface" else "OnSurfaceVariant"
	local labelRaw = Style.choose(selected, R.OnSecondaryContainer, R[labelRole])
	local labelColor = Style.disabledPick(disabled, labelRaw, R.OnSurface)
	local contentTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)
	local iconRaw = Style.choose(selected, R.OnSecondaryContainer, R.Primary)
	local iconColor = Style.disabledPick(disabled, iconRaw, R.OnSurface)

	local containerVisible: q.State<boolean> = selected:Compute(function(self)
		return elevated or self:Get()
	end)
	local containerRaw = Style.choose(selected, R.SecondaryContainer, if elevated then R.SurfaceContainerLow else R.SecondaryContainer)
	local containerTransparency: q.State<number> = containerVisible:Compute(function(self, _prev, dis)
		if not self:Get() then
			return 1
		end
		return if dis:Get() then Style.DisabledContainerTransparency else 0
	end, disabled)

	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = Style.animated(labelRaw),
		Corner = corner,
	})

	local shadow: Instance? = nil
	if elevated then
		local level: q.State<number> = fx.Hovered:Compute(function(self, _prev, dis)
			if dis:Get() then
				return 0
			end
			return if self:Get() then 2 else 1
		end, disabled)
		shadow = Elevation.Shadow({ Level = level, Theme = theme })
	end

	local stroke: Instance? = nil
	if not elevated then
		local strokeTransparency: q.State<number> = selected:Compute(function(self, _prev, dis)
			if self:Get() then
				return 1
			end
			return if dis:Get() then Style.DisabledContainerTransparency else 0
		end, disabled)
		stroke = D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,
			Color = Style.disabledPick(disabled, R.Outline, R.OnSurface),
			Transparency = strokeTransparency:Apply(Style.animation()),
		}
	end

	-- ── leading / trailing elements ─────────────────────────────────────────────
	local isFilter = kind == "Filter"
	local hasIcon = p.Icon ~= nil
	local hasRemove = kind == "Input" and p.OnRemove ~= nil
	local notSelected: q.State<boolean> = Util.negate(selected)

	local icon: Instance? = nil
	if p.Icon ~= nil then
		icon = D.ImageLabel {
			Name = "Icon",
			Size = UDim2.fromOffset(ICON, ICON),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = p.Icon,
			ImageColor3 = iconColor,
			ImageTransparency = contentTransparency,
			LayoutOrder = 1,
			Visible = if isFilter then notSelected else nil,
		}
	end
	local check: Instance? = nil
	if isFilter then
		check = glyphIcon("Check", p.CheckIcon or Icons.asset("check"), Icons.glyph("check"), iconColor, contentTransparency, 2, selected)
	end
	local remove: Instance? = nil
	if hasRemove and p.OnRemove ~= nil then
		remove = GlyphButton.new({
			Name = "Remove",
			Glyph = Icons.glyph("close"),
			Asset = p.RemoveIcon or Icons.asset("close"),
			Size = ICON,
			Hit = TouchTarget,
			Layer = false, -- inside the chip: hovering it already lights the chip's own state layer
			Color = labelColor,
			Transparency = contentTransparency,
			TextSize = ICON,
			Role = "LabelLarge",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -(RemoveInset + REMOVE / 2), 0.5, 0),
			Disabled = disabled,
			Theme = theme,
			OnClick = p.OnRemove,
		})
	end

	-- padding: 16 without a leading element, 8 with one (the Filter check appears on selection), 8 right of a
	-- trailing remove button
	local padLeft: q.State<UDim> = selected:Compute(function(self)
		local leading = hasIcon or (isFilter and self:Get())
		return UDim.new(0, if leading then 8 else 16)
	end)
	local padRight = UDim.new(0, if hasRemove then RemoveInset + REMOVE else 16)

	local onChange = p.OnChange
	local onClick = p.OnClick
	local sel = p.Selected
	return D.TextButton {
		Name = "Chip",
		baseModifier,
		p.Modifier or q.None,
		fx.Hook,
		BackgroundColor3 = Style.disabledPick(disabled, containerRaw, R.OnSurface),
		BackgroundTransparency = containerTransparency:Apply(Style.animation()),
		Interactable = interactable,
		Activated = function()
			if Util.peekBool(disabled) then
				return
			end
			if sel ~= nil then
				local v = not sel:Get()
				sel:Set(v)
				if onChange then
					onChange(v)
				end
			end
			if onClick then
				onClick()
			end
		end,
		UICorner = corner,
		shadow or q.None,
		stroke or q.None,
		fx.Layer,
		-- the padding and the row layout live on a CONTENT frame: a UIPadding / UIListLayout on the host itself
		-- would also inset / lay out the state layer (a child GuiObject of the host)
		D.Frame {
			Name = "Content",
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIPadding { PaddingLeft = padLeft, PaddingRight = padRight },
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			},
			icon or q.None,
			check or q.None,
			D.TextLabel {
				Name = "Label",
				labelStyle,
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = p.Label,
				TextColor3 = labelColor,
				TextTransparency = contentTransparency,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				LayoutOrder = 3,
			},
		},
		remove or q.None,
		table.unpack(Util.hooks(p.Hooks)),
	}
end

local function Assist(props: AssistProps): TextButton
	return build({
		Kind = "Assist",
		Label = props.Label,
		Icon = props.Icon,
		Elevated = props.Elevated,
		Disabled = props.Disabled,
		OnClick = props.OnClick,
		Theme = props.Theme,
		Modifier = props.Modifier,
		Hooks = props.Hooks,
	})
end

local function Suggestion(props: SuggestionProps): TextButton
	return build({
		Kind = "Suggestion",
		Label = props.Label,
		Icon = props.Icon,
		Elevated = props.Elevated,
		Disabled = props.Disabled,
		OnClick = props.OnClick,
		Theme = props.Theme,
		Modifier = props.Modifier,
		Hooks = props.Hooks,
	})
end

local function Filter(props: FilterProps): TextButton
	return build({
		Kind = "Filter",
		Label = props.Label,
		Icon = props.Icon,
		Selected = props.Selected,
		CheckIcon = props.CheckIcon,
		OnChange = props.OnChange,
		Elevated = props.Elevated,
		Disabled = props.Disabled,
		OnClick = props.OnClick,
		Theme = props.Theme,
		Modifier = props.Modifier,
		Hooks = props.Hooks,
	})
end

local function Input(props: InputProps): TextButton
	return build({
		Kind = "Input",
		Label = props.Label,
		Icon = props.Icon,
		RemoveIcon = props.RemoveIcon,
		OnRemove = props.OnRemove,
		Elevated = props.Elevated,
		Disabled = props.Disabled,
		OnClick = props.OnClick,
		Theme = props.Theme,
		Modifier = props.Modifier,
		Hooks = props.Hooks,
	})
end

-- ChipSet --------------------------------------------------------------------------------------------------

export type ChipSetProps<T> = {
	read Items: q.State<{ T }>,
	read Key: (item: T) -> string | number,
	read Render: (item: q.State<T>, order: q.State<number>) -> Instance,
	read Gap: number?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local chipSetBase = D.Modifier.Frame()
	:Size(UDim2.new(1, 0, 0, 0))
	:AutomaticSize(Enum.AutomaticSize.Y)
	:BackgroundTransparency(1)
	:BorderSizePixel(0)

--[[
	ChipSet<T>({ Items, Key, Render, Gap?, Modifier?, Hooks? }) -> Frame
	A WRAPPING row of chips, one element per `Key(item)` (the keyed `Slot:List` pattern — an element is built once
	per key and reused; its row data and 1-based position arrive as `State<T>` / `State<number>`; plug the order
	into the chip's `LayoutOrder` through its `Modifier`). A key that leaves `Items` destroys its chip.
	Layout: one `UIListLayout` (horizontal, `Wraps = true`, `Padding = Gap` default 8, M3 chip spacing) in a Frame
	that is full width and grows in height (`AutomaticSize = Y`) — the chips flow onto new lines at the Frame's
	width; give the Frame a width through `Modifier` for a narrower set. (UIGridLayout was rejected: it forces one
	cell size on chips of different widths.)
	The vertical gap between wrapped lines is `UIListLayout.Padding` as well — measured on the mock only (the mock
	has no layout engine); confirm on a device (kit README open item).
]]
local function ChipSet<T>(props: ChipSetProps<T>): Frame
	local gap = props.Gap or 8
	return D.Frame {
		Name = "ChipSet",
		chipSetBase,
		props.Modifier or q.None,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			Wraps = true,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = UDim.new(0, gap),
		},
		KeyedSlot.new(props.Items, props.Key, props.Render),
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return {
	Assist = Assist,
	Filter = Filter,
	Input = Input,
	Suggestion = Suggestion,
	ChipSet = ChipSet,
}
