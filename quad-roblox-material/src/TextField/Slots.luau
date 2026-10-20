--!strict
--[[
	TextField slots: the leading icon, the trailing icon / glyph, the error mark and the prefix / suffix affixes.
	All are positioned against the container (24 px icons 12 px from the edges, centered on the first line of a
	multi-line field); the row's padding (Field.luau) makes room for them.

	AFFIX: the prefix / suffix fade with the input phase like Compose `internal/TextFieldImpl.kt` (androidx@26506f4)
	`affixOpacity`: Focused 1, UnfocusedEmpty 0 under a label that rests in the field (1 without a label),
	UnfocusedNotEmpty 1 — i.e. shown once the label has floated (they would otherwise sit under the resting label) —
	every change animated with `MotionSchemeKeyTokens.FastEffects` (damping 1.0 / stiffness 3800 -> 0.11 s = Short2, the
	same mapping as the placeholder, Field.luau PLACEHOLDER), Standard easing; a disabled flip keeps the content
	animation (Short4). Compose drops an affix from composition while its alpha is 0 (`showAffix`), so it also gives up
	its width; the kit keeps the label in the row and only fades its text. The width it keeps is invisible: alpha 0 only
	in UnfocusedEmpty under a label, where the input is empty and the placeholder is at 0 too, so the row draws nothing.
]]

local q = require("../Quad")
local Util = require("../Util")
local Theme = require("../Theme")
local Tokens = require("../Tokens")
local MotionTokens = require("../Tokens/Motion")
local Icons = require("../Icons")
local Style = require("../Button/Style")
local Text = require("../Text")
local Ctx = require("./Ctx")
local ImageLabel = q.Elem "ImageLabel"
local TextLabel = q.Elem "TextLabel"

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
	return ImageLabel {
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
		el = ImageLabel {
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
		el = TextLabel {
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
		mark = TextLabel {
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

-- the affix fade (see AFFIX in the header)
local AffixFast = Tokens.Motion.options("Short2", "Standard") -- FastEffects
local AffixContent = Tokens.Motion.options("Short4", "Standard") -- a disabled flip (Style.animation)

type AffixLook = { Shown: boolean, Transparency: number, Motion: MotionTokens.AnimateOptions }

-- the text transparency both affixes share: without a label the affixes always show (opacity 1 in every phase), so the
-- plain content transparency; with one, Compose's `affixOpacity` — out only while the label rests in the field
local function affixTransparency(c: Ctx.Ctx): Theme.Animated
	if not c.HasLabel then
		return c.ContentTransparency
	end
	local look: q.State<AffixLook> = c.Floated:Compute(function(self, prev: AffixLook?, dis): AffixLook
		local shown = self:Get()
		local content = if dis:Get() then Style.DisabledContentTransparency else 0
		return {
			Shown = shown,
			Transparency = if shown then content else 1,
			Motion = if prev ~= nil and prev.Shown ~= shown then AffixFast else AffixContent,
		}
	end, c.Disabled)
	return look:Compute(function(self)
		local l = self:Get()
		return q.Tween({ Value = l.Transparency, Time = l.Motion.Time, Style = l.Motion.Style, Direction = l.Motion.Direction })
	end)
end

-- `transparency`: `affixTransparency(c)`, built once and shared by the prefix and the suffix
local function affix(c: Ctx.Ctx, name: string, text: string, transparency: Theme.Animated): Instance
	local R = c.Theme.Raw
	return TextLabel {
		Name = name,
		bodyLarge,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = Style.disabledPick(c.Disabled, R.OnSurfaceVariant, R.OnSurface),
		-- stays in the row while faded out (AFFIX in the header)
		TextTransparency = transparency,
		LayoutOrder = if name == "Prefix" then 1 else 3,
	}
end

return { leading = leading, trailing = trailing, affix = affix, affixTransparency = affixTransparency }
