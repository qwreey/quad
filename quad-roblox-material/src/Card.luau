--!strict
--[[
	M3 card: Elevated / Filled / Outlined surface with corner 12 and a caller-provided body.

	    Card({ Variant = "Outlined", Padding = 16, Gap = 8, Children = q.Slot<<Instance>>({ title, body }) })
	    Card({ Variant = "Filled", OnClick = open, Children = slot })           -- interactive: state layer + ripple

	Props (all `read`):
	  Variant    "Elevated" | "Filled" | "Outlined"      default "Elevated"
	               Elevated  surfaceContainerLow, shadow level 1 (hover 2 when interactive)
	               Filled    surfaceContainerHighest, no shadow
	               Outlined  surface + 1 px outlineVariant stroke, no shadow
	  Children   Slot<Instance>?        the body (`props.Children or q.None` — a Slot is the quad boundary form)
	  OnClick    (() -> ())?            presence (decided at construction) makes the card a TextButton host with the
	                                    interaction visual; without it the host is a plain Frame (no layer at all)
	  Disabled   boolean | State<boolean>?   interactive cards only: the M3 disabled container / outline / shadow (table
	                                    below), no input. The CONTENT is the caller's: the kit has no content-color scope
	                                    (Compose's LocalContentColor), so dimming the children to 38 % is up to the caller
	  Padding    number?                inner padding on all four sides (the host `UIPaddingOffset` shorthand: one managed UIPadding); default none
	  Gap        number?                vertical stack of the children with this spacing (adds ONE UIListLayout);
	                                    default none — without it the children position themselves
	  LayoutOrder number | State<number>?
	  Theme, Modifier                   Modifier: any GuiObject modifier (`D.Modifier.GuiObject()...`), applied AFTER
	                                    the base style (later wins). The base Size is `0,0` + AutomaticSize XY
	                                    (shrink-wrap): pass `Size`/`AutomaticSize` to fix a width.
	Returns the host (Frame, or TextButton when `OnClick`).

	The Children (and the Padding / Gap) are under an inner transparent `Content` frame (AutomaticSize XY, shrink-wrap),
	not directly under the host: the state layer must be a direct child of a host without UIPadding / UIListLayout.
	Consequence: with a caller-fixed host width the Content still shrink-wraps its children (scale-width children
	do not fill the card; give them offsets or a wider Content via the children themselves).
	Instances at rest: Frame + UICorner + Content (+ UIShadow when Elevated, + UIStroke when Outlined, + UIPadding/
	UIListLayout when asked); interactive adds the state layer (Frame + UICorner + UIStroke focus ring = 3).

	DISABLED (interactive cards) — canon: Compose `Card.kt` `CardDefaults` (androidx-main, read 2026-10-13) with
	`FilledCardTokens` / `ElevatedCardTokens` / `OutlinedCardTokens`. The disabled colors are COMPOSITED, opaque colors
	(`a.copy(alpha).compositeOver(b)` = `b:Lerp(a, alpha)` in sRGB), not a translucent "onSurface @ 12 %" container:
	              container                                              outline                              shadow
	    Filled    SurfaceVariant @ 38 % over SurfaceContainerHighest     —                                    Level0
	              (`defaultCardColors`: DisabledContainerColor.copy(alpha = DisabledContainerOpacity 0.38)
	              .compositeOver(ContainerColor))
	    Elevated  Surface @ 38 % over Surface = Surface                  —                                    Level1
	              (`defaultElevatedCardColors`: composited over the DisabledContainerColor token itself,      (stays: Disabled-
	              so the result is plain Surface; the enabled SurfaceContainerLow is dropped)                 ContainerElevation)
	    Outlined  Surface, unchanged (`defaultOutlinedCardColors`)       Outline @ 12 % over                  Level0
	                                                                     SurfaceContainerLow (`outlinedCardBorder(false)`:
	                                                                     DisabledOutlineColor.copy(alpha = 0.12)
	                                                                     .compositeOver(ElevatedCardTokens.ContainerColor))
	    content   contentColorFor(container) @ 38 % (`DisabledAlpha`) — not applied by the kit, see `Disabled` above.
	The composites are `:Compute`s of the theme's RAW roles, animated once (Short4 / Standard, `Style.disabledPick`): a
	scheme switch and a disabled flip both cross-fade, and no instance is added. Compose snaps the elevation when a card
	becomes disabled ("No transition when moving to a disabled state"); here the shadow level animates like every other
	level change of the kit.
	M3 deviations: Filled/Outlined do not raise on hover (no shadow instance; canon: Hover Level1); disabled
	non-interactive cards do not exist; the disabled content color is the caller's.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interactive = require("./Interactive")
local Elevation = require("./Elevation")
local Style = require("./Button/Style")
local ColorTokens = require("./Tokens/Color")
local D = q.Declaration
local cardFrameName = D.Modifier.Frame():Name("Card")
local cardButtonName = D.Modifier.TextButton():Name("Card")

export type Variant = "Elevated" | "Filled" | "Outlined"

export type Props = {
	read Variant: Variant?,
	read Children: q.Slot<Instance>?,
	read OnClick: (() -> ())?,
	read Disabled: (boolean | q.State<boolean>)?,
	read Padding: number?,
	read Gap: number?,
	read LayoutOrder: (number | q.State<number>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.IntoGuiObject?,
	read Hooks: Util.Hooks?,
}

-- `Tint` at `DisabledContainerOpacity` composited over `Over` (see DISABLED in the header)
type Composite = { Tint: ColorTokens.Role, Over: ColorTokens.Role }

type Spec = {
	Container: ColorTokens.Role,
	OnContainer: ColorTokens.Role,
	Shadow: number?,
	Stroke: boolean,
	-- the disabled container; nil = the container does not change
	Disabled: Composite?,
}

local Specs: { [Variant]: Spec } = {
	Elevated = {
		Container = "SurfaceContainerLow",
		OnContainer = "OnSurface",
		Shadow = 1,
		Stroke = false,
		Disabled = { Tint = "Surface", Over = "Surface" },
	},
	Filled = {
		Container = "SurfaceContainerHighest",
		OnContainer = "OnSurface",
		Shadow = nil,
		Stroke = false,
		Disabled = { Tint = "SurfaceVariant", Over = "SurfaceContainerHighest" },
	},
	Outlined = { Container = "Surface", OnContainer = "OnSurface", Shadow = nil, Stroke = true, Disabled = nil },
}

local DisabledContainerOpacity = 0.38 -- FilledCardTokens / ElevatedCardTokens.DisabledContainerOpacity
local DisabledOutlineOpacity = 0.12 -- OutlinedCardTokens.DisabledOutlineOpacity
local DisabledOutline: Composite = { Tint = "Outline", Over = "SurfaceContainerLow" }

-- Compose `tint.copy(alpha).compositeOver(over)`: the opaque color of `tint` at `alpha` painted on `over`
local function composite(theme: Theme.Theme, c: Composite, alpha: number): q.State<Color3>
	return theme.Raw[c.Tint]:Compute(function(self, _prev, over)
		return over:Get():Lerp(self:Get(), alpha)
	end, theme.Raw[c.Over])
end

local baseFrame = D.Modifier.Frame():Size(UDim2.fromOffset(0, 0)):AutomaticSize(Enum.AutomaticSize.XY):BorderSizePixel(0)
local baseButton = D.Modifier.TextButton()
	:Size(UDim2.fromOffset(0, 0))
	:AutomaticSize(Enum.AutomaticSize.XY)
	:BorderSizePixel(0)
	:AutoButtonColor(false)
	:Text("")

local function Card(props: Props): GuiObject
	local theme = Theme.resolve(props.Theme)
	local variant: Variant = props.Variant or "Elevated"
	local spec = Specs[variant]
	local corner = Tokens.Shape.corner("Medium")
	local interactive = props.OnClick ~= nil
	local disabled = Util.asState(props.Disabled)

	local fx: Interactive.Interactive? = nil
	local shadow: Instance? = nil
	if interactive then
		local f = Interactive.new({
			Theme = theme,
			Disabled = disabled,
			OnColor = theme.Color[spec.OnContainer],
			Corner = corner,
		})
		fx = f
		if spec.Shadow ~= nil then
			local rest = spec.Shadow
			-- disabled: DisabledContainerElevation — Level1 for the Elevated card, the same as its resting level
			local level: q.State<number> = f.Hovered:Compute(function(self, _prev, dis)
				return if self:Get() and not dis:Get() then rest + 1 else rest
			end, disabled)
			shadow = Elevation.Shadow({ Level = level, Theme = theme })
		end
	elseif spec.Shadow ~= nil then
		shadow = Elevation.Shadow({ Level = spec.Shadow, Theme = theme })
	end

	local container: Theme.Animated | q.State<Color3>
	local off = spec.Disabled
	if interactive and off ~= nil then
		container = Style.disabledPick(disabled, theme.Raw[spec.Container], composite(theme, off, DisabledContainerOpacity))
	else
		container = theme.Color[spec.Container]
	end

	local stroke: Instance? = nil
	if spec.Stroke then
		stroke = D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,
			Color = if interactive
				then Style.disabledPick(disabled, theme.Raw.OutlineVariant, composite(theme, DisabledOutline, DisabledOutlineOpacity))
				else theme.Color.OutlineVariant,
		}
	end

	local layout: Instance? = nil
	if props.Gap ~= nil then
		layout = D.UIListLayout {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, props.Gap),
		}
	end

	-- padding / layout / children live on an inner transparent Content frame for BOTH forms (one code path): the
	-- state layer + ripple must be a direct child of a host without UIPadding / UIListLayout (Interactive.luau).
	local function content(): Frame
		return D.Frame {
			Name = "Content",
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UIPaddingOffset = props.Padding,
			layout or q.None,
			props.Children or q.None,
		}
	end

	if interactive then
		local f = fx :: Interactive.Interactive
		local interactable: q.State<boolean> = Util.interactable(disabled)
		return D.TextButton {
			cardButtonName,
			baseButton,
			if props.Modifier then props.Modifier:AsGuiObject():AsTextButton() else q.None,
			f.Hook,
			BackgroundColor3 = container,
			BackgroundTransparency = 0,
			LayoutOrder = props.LayoutOrder,
			Interactable = interactable,
			Activated = function()
				if props.OnClick and not Util.peekBool(disabled) then
					props.OnClick()
				end
			end,
			UICorner = corner,
			shadow or q.None,
			stroke or q.None,
			f.Layer,
			content(),
			table.unpack(Util.hooks(props.Hooks)),
		} :: GuiObject
	end

	return D.Frame {
		cardFrameName,
		baseFrame,
		if props.Modifier then props.Modifier:AsGuiObject():AsFrame() else q.None,
		BackgroundColor3 = container,
		BackgroundTransparency = 0,
		LayoutOrder = props.LayoutOrder,
		UICorner = corner,
		shadow or q.None,
		stroke or q.None,
		content(),
		table.unpack(Util.hooks(props.Hooks)),
	} :: GuiObject
end

return Card
