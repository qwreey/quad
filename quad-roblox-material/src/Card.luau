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
	  Disabled   boolean | State<boolean>?   interactive cards only: container/content M3 disabled look, no input
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
	M3 deviations: Filled/Outlined do not raise on hover (no shadow instance); disabled non-interactive cards do not exist.
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

type Spec = { Container: ColorTokens.Role, OnContainer: ColorTokens.Role, Shadow: number?, Stroke: boolean }

local Specs: { [Variant]: Spec } = {
	Elevated = { Container = "SurfaceContainerLow", OnContainer = "OnSurface", Shadow = 1, Stroke = false },
	Filled = { Container = "SurfaceContainerHighest", OnContainer = "OnSurface", Shadow = nil, Stroke = false },
	Outlined = { Container = "Surface", OnContainer = "OnSurface", Shadow = nil, Stroke = true },
}

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
			local level: q.State<number> = f.Hovered:Compute(function(self, _prev, dis)
				if dis:Get() then
					return 0
				end
				return if self:Get() then rest + 1 else rest
			end, disabled)
			shadow = Elevation.Shadow({ Level = level, Theme = theme })
		end
	elseif spec.Shadow ~= nil then
		shadow = Elevation.Shadow({ Level = spec.Shadow, Theme = theme })
	end

	local container: Theme.Animated | q.State<Color3>
	local containerTransparency: (number | Theme.Animated)?
	if interactive then
		container = Style.disabledPick(disabled, theme.Raw[spec.Container], theme.Raw.OnSurface)
		containerTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency)
	else
		container = theme.Color[spec.Container]
		containerTransparency = 0
	end

	local stroke: Instance? = nil
	if spec.Stroke then
		stroke = D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 1,
			Color = if interactive then Style.disabledPick(disabled, theme.Raw.OutlineVariant, theme.Raw.OnSurface) else theme.Color.OutlineVariant,
			Transparency = if interactive then Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency) else 0,
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
			BackgroundTransparency = containerTransparency,
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
		BackgroundTransparency = containerTransparency,
		LayoutOrder = props.LayoutOrder,
		UICorner = corner,
		shadow or q.None,
		stroke or q.None,
		content(),
		table.unpack(Util.hooks(props.Hooks)),
	} :: GuiObject
end

return Card
