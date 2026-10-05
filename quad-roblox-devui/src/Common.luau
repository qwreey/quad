--!strict
--[[
	Common — small pieces shared by the widgets (internal; not exported from the kit root).

		Common.enabled(disabled)              State<boolean>   `Disabled` prop (boolean | State<boolean> | nil) -> "is enabled"
		Common.textLook(style, enabled)       { Color, Transparency }   Text / TextDisabled tokens by enabled
		Common.look(style, base, hover, enabled)  { Color, Transparency }  `base` / BaseHovered / BaseActive tokens (the resting
		                                      token while disabled)
		Common.fieldLook(style, hover, enabled)   Common.look with the FrameBg tokens (input fields, check boxes)
		Common.headerLook(style, hover, selected, always)  Header tokens; transparent at rest unless `selected` / `always`
		Common.label(style, text, enabled, order)  TextLabel       the trailing widget label ("Text" prop)
		Common.rowLayout(style)               UIListLayout     horizontal row, ItemInnerSpacing.X apart, centred
		Common.frameHeight(style)             State<UDim2>     fromOffset(0, FrameHeight)  (field height; width via flex)
		Common.stroke(style)                  UIStroke         the standard frame border (FrameBorderSize / Border)
		Common.padXY(token)                   (State<UDim>, State<UDim>)   a Vector2 metric as horizontal / vertical padding
		Common.setter(value, onChange)        (n) -> ()        write a Source<number> only when changed, then report via OnChange
		Common.hooks(list)                    the `Hooks` prop of a leaf widget, spliced at the END of its array part
]]

local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
local Interaction = require("./Interaction")
local Style = require("./Style")
local Util = require("./Util")

type State<T> = Quad.State<T>
type Style = Style.Style

export type Look = { Color: State<Color3>, Transparency: State<number> }

local Common = {}

function Common.enabled(disabled: (boolean | State<boolean>)?): State<boolean>
	if disabled == nil then
		return q.Source(true)
	elseif type(disabled) == "boolean" then
		return q.Source(not disabled)
	end
	local out: State<boolean> = disabled:Compute(function(self)
		return not self:Get()
	end)
	return out
end

function Common.textLook(style: Style, enabled: State<boolean>): Look
	local color: State<Color3> = enabled:Compute(function(self, _prev, text, dim)
		return if self:Get() then text:Get() else dim:Get()
	end, style.Color.Text, style.Color.TextDisabled)
	local alpha: State<number> = enabled:Compute(function(self, _prev, text, dim)
		return if self:Get() then text:Get() else dim:Get()
	end, style.Transparency.Text, style.Transparency.TextDisabled)
	return { Color = color, Transparency = alpha }
end

function Common.look(style: Style, base: string, hover: Interaction.HoverHandle, enabled: State<boolean>): Look
	local live = Style.interactive(style, base, hover.Hovered, hover.Pressed)
	-- a disabled widget shows the resting token whatever the pointer does
	local color: State<Color3> = enabled:Compute(function(self, _prev, hot, rest)
		return if self:Get() then hot:Get() else rest:Get()
	end, live.Color, style:ColorOf(base))
	local alpha: State<number> = enabled:Compute(function(self, _prev, hot, rest)
		return if self:Get() then hot:Get() else rest:Get()
	end, live.Transparency, style:AlphaOf(base))
	return { Color = color, Transparency = alpha }
end

function Common.fieldLook(style: Style, hover: Interaction.HoverHandle, enabled: State<boolean>): Look
	return Common.look(style, "FrameBg", hover, enabled)
end

-- Header look: transparent at rest, shown while hovered / pressed / `selected`; `always` = the full Header look
function Common.headerLook(style: Style, hover: Interaction.HoverHandle, selected: State<boolean>?, always: boolean?): Look
	local live = Style.interactive(style, "Header", hover.Hovered, hover.Pressed)
	if always == true then
		return live
	end
	local flag: State<boolean> = selected or hover.Hovered
	local alpha: State<number> = flag:Compute(function(self, _prev, hovered, pressed, shown)
		if self:Get() or hovered:Get() or pressed:Get() then
			return shown:Get()
		end
		return 1
	end, hover.Hovered, hover.Pressed, live.Transparency)
	return { Color = live.Color, Transparency = alpha }
end

function Common.label(style: Style, text: string | State<string>, enabled: State<boolean>, order: number): TextLabel
	local look = Common.textLook(style, enabled)
	return D.TextLabel({
		Name = "Label",
		LayoutOrder = order,
		Text = text,
		FontFace = style.Metrics.TextFont,
		TextSize = style.Metrics.TextSize,
		TextColor3 = look.Color,
		TextTransparency = look.Transparency,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
	})
end

-- the write path every Source-backed widget uses: write only a changed value, then report it
function Common.setter(value: Quad.Source<number>, onChange: ((n: number) -> ())?): (n: number) -> ()
	return function(n: number)
		if value:Get() ~= n then
			value:Set(n)
			if onChange then
				onChange(n)
			end
		end
	end
end

function Common.stroke(style: Style): UIStroke
	return D.UIStroke({
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = style.Metrics.FrameBorderSize,
		Color = style.Color.Border,
		Transparency = style.Transparency.Border,
	})
end

function Common.padXY(token: State<Vector2>): (State<UDim>, State<UDim>)
	return Util.pxX(token), Util.pxY(token)
end

-- the `Hooks` prop (a list of hook values: Interaction handles' `.Hook`, Tooltip `.Hook`, q.OnRendered ...)
local NO_HOOKS: { any } = {}
function Common.hooks(list: { any }?): { any }
	return list or NO_HOOKS
end

function Common.rowLayout(style: Style): UIListLayout
	return D.UIListLayout({
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = Util.pxX(style.Metrics.ItemInnerSpacing),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	})
end

function Common.frameHeight(style: Style): State<UDim2>
	local out: State<UDim2> = style.FrameHeight:Compute(function(self)
		return UDim2.fromOffset(0, self:Get())
	end)
	return out
end

return Common
