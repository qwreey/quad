--!strict
--[[
	M3 Expressive split button (androidx Compose material3 `SplitButtonLayout` / `SplitButtonDefaults`, small size —
	the 40 px height of the kit's Button): a LEADING button (the primary action: label, optional icon) and a TRAILING
	button (a related secondary action, typically a menu: a down arrow) side by side, 2 px apart. Each half is a pill
	whose two INNER corners are small and morph while pressed; a SELECTED trailing button (its menu is open — Compose's
	`checked`) turns into a full circle-ended pill and its arrow turns upside down.

	    SplitButton({ Label = "Save", OnClick = save, OnTrailingClick = openMenu, Selected = menuOpen })
	    SplitButton({ Variant = "Tonal", Label = "Send", Icon = "rbxassetid://123", OnTrailingClick = more })

	Props (all `read`):
	  Variant          "Filled" | "Tonal" | "Elevated" | "Outlined"   default "Filled" (Compose LeadingButton /
	                   TonalLeadingButton / ElevatedLeadingButton / OutlinedLeadingButton; there is no text split
	                   button). Colors and elevation are the kit Button's of the same variant (Compose: "has the same
	                   visual as a [Button]").
	  Label            string | State<string>          the leading button's text (LabelLarge)
	  Icon             (string | State<string>)?       the leading button's leading icon — an ICON PROP value (`Icons.luau`
	                   "ICON PROPS"), 20 px (SplitButtonDefaults.LeadingIconSize = ButtonSmallTokens.IconSize), 8 px
	                   before the label (ButtonDefaults.IconSpacing; SplitButtonSamples.kt FilledSplitButtonSample)
	  OnClick          (() -> ())?                     the leading button
	  OnTrailingClick  (() -> ())?                     the trailing button (open your `Menu` here — see the gallery)
	  Selected         (boolean | State<boolean>)?     the trailing button's checked state (Compose TrailingButton
	                   `checked`): circle shape, arrow rotated 180 degrees, a content-colored overlay at the pressed
	                   state-layer opacity (10 %). The component does not flip it — write the Source you passed
	                   (typically: true while the menu is open, `handle.IsOpen`).
	  Disabled         (boolean | State<boolean>)?     both halves: container onSurface@12 %, content @38 %, no input
	  Theme, Modifier (Frame Modifier on the host, after the base), Hooks (host array part)
	Returns the host `Frame` (auto width: the two halves + 2; height 40).

	Dimensions (androidx/androidx@5ac4c7c compose/material3/.../tokens/SplitButtonSmallTokens.kt 22~51 and
	SplitButton.kt 204~420): height 40; space between the halves 2 (BetweenSpace); outer corners Full (20); inner corners
	4 at rest (InnerCornerCornerSize = CornerValueExtraSmall), 12 while that half is pressed (InnerPressedCornerCornerSize
	= CornerValueMedium); a SELECTED trailing half is a circle shape (TrailingCheckedShape = CircleShape: all corners 20)
	— pressed wins over selected (shapeByInteraction); leading padding 16 / 12 (LeadingButtonLeadingSpace /
	TrailingSpace), trailing padding 13 / 13 and its arrow 22 px (TrailingIconSize); each half at least 48 px wide
	(LeadingButtonMinWidth / TrailingButtonMinWidth), its content centered in it. The trailing content is shifted by
	Compose's optical centering (HorizontalCenterOptically.kt: 0.11 x (start corner - end corner), rounded — 2 px toward
	the inner side at rest, 1 px while pressed, 0 when selected). The arrow is Icons.Filled.KeyboardArrowDown rotated
	0 -> 180 when selected (SplitButtonSamples.kt 114~126) — the `Icons` name "chevronDown". Corner morph, arrow
	rotation and the optical shift animate together (Motion Short4 / Standard — Compose uses its DefaultEffects spring).

	Each half is one `Segment` cell (`./Segment.luau` — the drawing below is shared with `ButtonGroup`, `./Group.luau`).
	ASYMMETRIC SHAPE (a UICorner has ONE radius): each half draws its container as two FACES, both the half's full
	rectangle, one rounded 20 and one rounded at the inner radius, each inside a rectangle clip that shows only its own
	side (outer side [0, W/2] of the leading half, inner side [W/2, W]; mirrored for the trailing half) — the same
	composition as the M3 slider track (`../Slider/Track.luau` "ASYMMETRIC ROUNDING"), so a translucent (disabled)
	container has no seam. Each face carries its own state layer and its own ripple (`Ripple.luau`) with the face's
	corner: the two ripples start at the same press point in the same full-rectangle geometry, so the visible halves of
	the two discs meet exactly at the clip line. The outline (Outlined) is a 1 px Inner UIStroke on each face (an outer
	stroke would be cut by the clips).
	ELEVATED SHADOW: each FACE carries its own UIShadow (`Elevation.Shadow`), so each half casts the shadow of its own
	shape — outer corners 20, inner corners 4 / 12 pressed / 20 selected, as Compose draws it (a UIShadow follows its
	parent's one UICorner, so the two faces give the two radii) — and the two shadows of a half meet at the split line
	like the faces do. For that the clips of an Elevated half are OPEN on the three sides that are not the split line:
	by the shadow's reach (2 x blur + spread + y-offset of the hovered level = 15) above, below and on the half's outer
	side, and by the 2 px gap on its inner side (further in, the trailing half's shadow would be drawn over the leading
	half's container — it is the later sibling); the faces sit at the same place as before. The other variants keep the
	clips at the half's rectangle. (Before 2026-10-13 one ShadowCaster Frame per half — the half's rectangle rounded 20
	on all four corners — carried the shadow: it curled in at the gap and left the middle of the button without a
	shadow. An Elevated split button is 2 instances SMALLER now: 4 UIShadow instead of 2 x (Frame + UICorner +
	UIShadow). Engine facts, Studio 2026-10-13: a UIShadow is drawn for a transparent parent too, as a FILLED shape —
	one transparent caster across both halves shows through the gap as a dark line; ClipsDescendants of an ancestor
	cuts a UIShadow.)
	Every size that feeds the layout below the host is Offset (no Scale fraction under an auto-sized ancestor —
	`Ripple.luau` "NOT SCALE"; the Selected overlay is a full-cover Scale leaf under an Offset-sized face, which is fine):
	a half's width W = max(48, its content's width), read from the content frame's AbsoluteSize in local units (divided
	by the UIScale product, `Ripple.localScale`); the half is not auto-sized itself. (The open clips of an Elevated half
	reach outside the half; the host's AutomaticSize measures its children — the two halves — not their descendants.)

	Structure at rest (Filled, no icon): host Frame + UIListLayout; per half: TextButton > OuterClip > Face (UICorner,
	StateLayer > UICorner), InnerClip > Face (same), FocusRing (Frame + UICorner + UIStroke), Content (UIPadding + ...):
	leading Content = UIPadding + Label (+ Icon + UIListLayout with an icon); trailing Content = UIPadding + Icon, and the
	trailing faces each hold a Selected overlay (Frame + UICorner); Elevated: + a UIShadow on each of the four faces.
	Counted in test/spec.button.luau. A press adds two transient ripples (2 x 3).
	M3 deviations: the focus ring is one rounded rectangle at the outer radius (the half's inner corners are rounder in
	the ring than in the shape); a half's shadow ends 2 px past its inner edge (ELEVATED SHADOW); no hover shape (the
	token InnerHoveredCornerCornerSize exists, Compose does not use it); one `Disabled` for both halves (Compose: one
	`enabled` per half); small size only (the XS / M / L / XL split buttons are not here — the kit Button is the 40 px
	one).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Text = require("../Text")
local IconView = require("../IconView")
local Style = require("./Style")
local Segment = require("./Segment")
local ColorTokens = require("../Tokens/Color")
local D = q.Declaration
local splitName = D.Modifier.Frame():Name("SplitButton")

export type Variant = "Filled" | "Tonal" | "Elevated" | "Outlined"

export type Props = {
	read Variant: Variant?,
	read Label: string | q.State<string>,
	read Icon: (string | q.State<string>)?,
	read OnClick: (() -> ())?,
	read OnTrailingClick: (() -> ())?,
	read Selected: (boolean | q.State<boolean>)?,
	read Disabled: (boolean | q.State<boolean>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

type Spec = { Container: ColorTokens.Role?, Content: ColorTokens.Role, Stroke: boolean, Shadow: number? }

-- the kit Button's roles per variant (Button/init.luau Specs)
local Specs: { [Variant]: Spec } = {
	Filled = { Container = "Primary", Content = "OnPrimary", Stroke = false, Shadow = nil },
	Tonal = { Container = "SecondaryContainer", Content = "OnSecondaryContainer", Stroke = false, Shadow = nil },
	Elevated = { Container = "SurfaceContainerLow", Content = "Primary", Stroke = false, Shadow = 1 },
	Outlined = { Container = nil, Content = "Primary", Stroke = true, Shadow = nil },
}

-- SplitButtonSmallTokens / SplitButtonDefaults (see the header)
local HEIGHT = 40
local BETWEEN = 2
local OUTER = HEIGHT / 2 -- CornerFull
local INNER = 4 -- InnerCornerCornerSize (CornerValueExtraSmall)
local INNER_PRESSED = 12 -- InnerPressedCornerCornerSize (CornerValueMedium)
local MIN_WIDTH = 48
local LEADING_PAD = { 16, 12 }
local TRAILING_PAD = { 13, 13 }
local LEADING_ICON = 20
local TRAILING_ICON = 22
local ICON_GAP = 8
local SELECTED_OPACITY = Tokens.State.Opacity.Pressed -- TrailingButtonStateLayerAlpha = PressedStateLayerOpacity

local labelStyle = Text.Label("LabelLarge")

local function animation()
	return q.Animate(Tokens.Motion.options("Short4", "Standard"))
end

type HalfOptions = {
	Side: "Leading" | "Trailing",
	Spec: Spec,
	Theme: Theme.Theme,
	Disabled: q.State<boolean>,
	Selected: q.State<boolean>?, -- trailing only
	OnClick: (() -> ())?,
	Content: { Instance }, -- children of the content frame after its UIPadding
	Pad: { number },
	Optical: boolean, -- shift the content by the optical-centering offset (trailing)
}

-- one half = one `Segment` cell (./Segment.luau draws the faces, clips, ripples, shadows and the content frame); this
-- function supplies the split button's colors: the kit Button's roles, and a content-colored overlay while Selected
local function half(o: HalfOptions): TextButton
	local theme, spec, disabled = o.Theme, o.Spec, o.Disabled
	local container = spec.Container
	local contentColor = Style.disabledPick(disabled, theme.Raw[spec.Content], theme.Raw.OnSurface)
	local selected = o.Selected
	local overlay: q.State<number>? = nil
	if selected ~= nil then
		local raw: q.State<number> = selected:Compute(function(self, _prev, dis)
			return if self:Get() and not dis:Get() then 1 - SELECTED_OPACITY else 1
		end, disabled)
		overlay = raw
	end
	local stroke: Segment.Stroke? = nil
	if spec.Stroke then
		stroke = {
			Color = Style.disabledPick(disabled, theme.Raw.Outline, theme.Raw.OnSurface),
			Transparency = Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency),
		}
	end
	return Segment.new({
		Name = o.Side,
		Side = o.Side,
		LayoutOrder = if o.Side == "Leading" then 1 else 2,
		Theme = theme,
		Disabled = disabled,
		Selected = selected,
		Height = HEIGHT,
		Between = BETWEEN,
		MinWidth = MIN_WIDTH,
		Outer = OUTER,
		Inner = INNER,
		InnerPressed = INNER_PRESSED,
		InnerSelected = OUTER, -- TrailingCheckedShape = CircleShape
		ContainerColor = if container then Style.disabledPick(disabled, theme.Raw[container], theme.Raw.OnSurface) else nil,
		ContainerTransparency = if container then Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency) else nil,
		ContentColor = contentColor,
		Stroke = stroke,
		Shadow = spec.Shadow,
		Overlay = overlay,
		Content = o.Content,
		Pad = o.Pad,
		Optical = o.Optical,
		OnClick = o.OnClick,
	})
end

local function SplitButton(props: Props)
	local theme = Theme.resolve(props.Theme)
	local variant: Variant = props.Variant or "Filled"
	local spec = Specs[variant]
	if spec == nil then
		error(`SplitButton: Variant must be "Filled", "Tonal", "Elevated" or "Outlined", got {tostring(variant)}`, 2)
	end
	local disabled = Util.asState(props.Disabled)
	local selected = Util.asState(props.Selected)
	local contentColor = Style.disabledPick(disabled, theme.Raw[spec.Content], theme.Raw.OnSurface)
	local contentT = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)

	-- leading content: [icon] label
	local leadingContent: { Instance } = {}
	if props.Icon ~= nil then
		table.insert(
			leadingContent,
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, ICON_GAP),
			}
		)
		local icon = IconView.new({
			Name = "Icon",
			Icon = props.Icon,
			Size = LEADING_ICON,
			Color = contentColor,
			Transparency = contentT,
			LayoutOrder = 1,
		})
		table.insert(leadingContent, icon)
	end
	table.insert(
		leadingContent,
		D.TextLabel {
			Name = "Label",
			labelStyle,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = props.Label,
			TextColor3 = contentColor,
			TextTransparency = contentT,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			LayoutOrder = 2,
		}
	)

	-- trailing content: the arrow, turned upside down while selected
	local rotationRaw: q.State<number> = selected:Compute(function(self)
		return if self:Get() then 180 else 0
	end)
	local arrow = IconView.new({
		Name = "Icon",
		Icon = "chevronDown",
		Size = TRAILING_ICON,
		Color = contentColor,
		Transparency = contentT,
		Position = UDim2.fromOffset(0, (HEIGHT - TRAILING_ICON) / 2),
		Rotation = rotationRaw:Apply(animation()),
	})

	local leadingHalf = half({
		Side = "Leading",
		Spec = spec,
		Theme = theme,
		Disabled = disabled,
		OnClick = props.OnClick,
		Content = leadingContent,
		Pad = LEADING_PAD,
		Optical = false,
	})
	local trailingHalf = half({
		Side = "Trailing",
		Spec = spec,
		Theme = theme,
		Disabled = disabled,
		Selected = selected,
		OnClick = props.OnTrailingClick,
		Content = { arrow },
		Pad = TRAILING_PAD,
		Optical = true,
	})

	return D.Frame {
		splitName,
		D.Modifier.Frame()
			:Size(UDim2.fromOffset(0, HEIGHT))
			:AutomaticSize(Enum.AutomaticSize.X)
			:BackgroundTransparency(1)
			:BorderSizePixel(0),
		props.Modifier or q.None,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, BETWEEN),
		},
		leadingHalf,
		trailingHalf,
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return SplitButton
