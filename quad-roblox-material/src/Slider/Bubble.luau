--!strict
--[[
	Slider value-label bubble (shared by the M3 and M2 looks — each passes its own style): a pill with the formatted value,
	visible while the handle is dragged or focused (and not disabled). It sits outside the host (above the handle), so an
	ancestor with `ClipsDescendants` clips it. Cost: TextLabel + UICorner + UIPadding (3).

	    Bubble.build({ Dragging, Focused, Disabled, Value, Format, Theme, Style })  -> TextLabel
	The caller parents it under the handle (or the handle's halo) and gives the bottom-center `Position` in that parent —
	or, with `AnchorPoint`, any other anchor: the vertical M3 slider puts it LEFT of the handle (AnchorPoint (1, 0.5),
	12 px out — MDC BaseSlider `calculateLabelBounds`, vertical: the horizontal label box below the track center, turned
	90 degrees clockwise with the view, which lands it on the left).
	Styles (`Bubble.M3`, `Bubble.M2`):
	  M3  32 px tall pill (corner Full), 10 px side padding, `InverseSurface` / `InverseOnSurface`, text = `LabelLarge` size /
	      line height at the BodyLarge weight (Regular). Sources (2026-10-08, "follow the canonical spec"): the M3 token set
	      md.comp.slider value-indicator.* (material-web tokens/versions/latest/sass/_md-comp-slider.scss, Material 3
	      v34.0.21; androidx compose material3 SliderTokens.kt ValueIndicator*) gives the colors, the LabelLarge font /
	      size / line height with label-text.weight = body-large-weight, and active.bottom-space 12 (the gap above the
	      handle, see the looks) — it has NO container height / width / shape token. Those come from Google's own M3
	      Android implementation, material-components-android slider/res/values/styles.xml `Widget.Material3.Slider.Label`:
	      android:minHeight 32dp (the drawn height: TooltipDrawable.getIntrinsicHeight = max(textSize, minHeight)),
	      paddingStart/End 10dp, shape from its parent `Widget.Material3.Tooltip` = ShapeAppearance.Material3.Corner.Full.
	      Not taken: that style's paddingTop/Bottom 12dp and the drawable's 4dp `android:padding` / 28dp minWidth (the
	      Tooltip styleable reads only `android:padding`, so on Android the stated 10dp side padding is not what draws),
	      and its BodySmall text appearance (inherited from the plain tooltip; the slider token says LabelLarge).
	      Until 2026-10-08 this was 44 px / 16 px from memory of a spec drawing — no source.
	  M2  28 px tall, 12 px side padding, `Primary` / `OnPrimary`, `LabelMedium` (the 2022 classic form)
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Text = require("../Text")
local Tokens = require("../Tokens")
local Typography = require("../Tokens/Typography")
local Style = require("../Button/Style")
local D = q.Declaration

export type BubbleStyle = {
	Height: number,
	Padding: number,
	Container: Theme.Role,
	Content: Theme.Role,
	Text: (typeof(Text.Label("LabelLarge"))),
}

export type Options = {
	Dragging: q.State<boolean>,
	Focused: q.State<boolean>,
	Disabled: q.State<boolean>,
	Value: q.State<number>,
	Format: (value: number) -> string,
	Theme: Theme.Theme,
	Style: BubbleStyle,
	Position: UDim2, -- bottom center (or `AnchorPoint`), in the parent
	AnchorPoint: Vector2?, -- default (0.5, 1)
}

local M3: BubbleStyle = {
	Height = 32,
	Padding = 10,
	Container = "InverseSurface",
	Content = "InverseOnSurface",
	-- md.comp.slider.value-indicator.label.label-text: LabelLarge size / line height, weight = body-large-weight (400)
	Text = Text.Label("LabelLarge"):FontFace(Typography.font("BodyLarge")),
}
local M2: BubbleStyle = { Height = 28, Padding = 12, Container = "Primary", Content = "OnPrimary", Text = Text.Label("LabelMedium") }

local function build(o: Options): TextLabel
	local theme = o.Theme
	local format = o.Format
	local style = o.Style
	local shown: q.State<boolean> = o.Dragging:Compute(function(self, _prev, focused, dis)
		return (self:Get() or focused:Get()) and not dis:Get()
	end, o.Focused, o.Disabled)
	local bubbleTransparency: q.State<number> = shown:Compute(function(self)
		return if self:Get() then 0 else 1
	end)
	local text: q.State<string> = o.Value:Compute(function(self)
		return format(self:Get())
	end)
	return D.TextLabel {
		Name = "Label",
		style.Text,
		AnchorPoint = o.AnchorPoint or Vector2.new(0.5, 1),
		Position = o.Position,
		Size = UDim2.fromOffset(0, style.Height),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = theme.Color[style.Container],
		BackgroundTransparency = bubbleTransparency:Apply(Style.animation()),
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = theme.Color[style.Content],
		TextTransparency = bubbleTransparency:Apply(Style.animation()),
		UICorner = Tokens.Shape.corner("Full"),
		D.UIPadding { PaddingLeft = UDim.new(0, style.Padding), PaddingRight = UDim.new(0, style.Padding) },
	}
end

return { build = build, M3 = M3, M2 = M2 }
