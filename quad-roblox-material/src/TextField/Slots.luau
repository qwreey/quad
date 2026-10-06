--!strict
--[[
	TextField slots: the leading icon, the trailing icon / glyph, the error mark and the prefix / suffix affixes.
	All are positioned against the container (24 px icons 12 px from the edges, centered on the first line of a
	multi-line field); the row's padding (Field.luau) makes room for them.
]]

local q = require("../Quad")
local Util = require("../Util")
local Icons = require("../Icons")
local Style = require("../Button/Style")
local Text = require("../Text")
local Ctx = require("./Ctx")
local D = q.Declaration

local bodyLarge = Text.Label("BodyLarge")

local function iconY(c: Ctx.Ctx): number
	return if c.Multi then 28 else c.Height / 2
end

local function leading(c: Ctx.Ctx): Instance?
	local icon = c.Props.LeadingIcon
	if icon == nil then
		return nil
	end
	local R = c.Theme.Raw
	return D.ImageLabel {
		Name = "LeadingIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0, iconY(c)),
		Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = icon,
		ImageColor3 = Style.disabledPick(c.Disabled, R.OnSurfaceVariant, R.OnSurface),
		ImageTransparency = c.ContentTransparency,
	}
end

-- returns the trailing icon / glyph and the error mark (either may be nil)
local function trailing(c: Ctx.Ctx): (Instance?, Instance?)
	local props = c.Props
	local el: Instance? = nil
	-- the trailing slot yields to the error mark while Error is on (M3: the error icon replaces the trailing icon)
	local notError: q.State<boolean> = Util.negate(c.Error)
	if props.TrailingIcon ~= nil then
		el = D.ImageLabel {
			Name = "TrailingIcon",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0, iconY(c)),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = props.TrailingIcon,
			ImageColor3 = c.Colors.Trailing,
			ImageTransparency = c.ContentTransparency,
			Visible = notError,
		}
	elseif props.TrailingGlyph ~= nil then
		el = D.TextLabel {
			Name = "TrailingGlyph",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0, iconY(c)),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = props.TrailingGlyph,
			-- Select's dropdown arrow: "▼" fills its whole em box, so at 20 px it drew a triangle twice M3's
			-- arrow_drop_down (a 10 x 5 triangle in the 24 px icon) — Studio QA 2026-10-07; 12 px is about that size
			TextSize = 12,
			TextColor3 = c.Colors.Trailing,
			TextTransparency = c.ContentTransparency,
			Visible = notError,
		}
	end
	-- error state is not color alone: a bold "!" mark in the trailing slot (only for fields that can enter the state)
	local mark: Instance? = nil
	if props.Error ~= nil then
		mark = D.TextLabel {
			Name = "ErrorMark",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0, iconY(c)),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = Icons.glyph("error"),
			TextSize = 20,
			FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold),
			TextColor3 = c.Theme.Raw.Error,
			TextTransparency = c.ContentTransparency,
			Visible = c.Error,
		}
	end
	return el, mark
end

local function affix(c: Ctx.Ctx, name: string, text: string): Instance
	local R = c.Theme.Raw
	return D.TextLabel {
		Name = name,
		bodyLarge,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = Style.disabledPick(c.Disabled, R.OnSurfaceVariant, R.OnSurface),
		TextTransparency = c.ContentTransparency,
		-- like M3, prefix/suffix only show once the label has floated (otherwise they would sit under it)
		Visible = if c.HasLabel then c.Floated else true,
		LayoutOrder = if name == "Prefix" then 1 else 3,
	}
end

return { leading = leading, trailing = trailing, affix = affix }
