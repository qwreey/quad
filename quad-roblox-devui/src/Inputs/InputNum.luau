--!strict
--[[
	InputNum (Iris: InputNum) — a number box with `-` / `+` step buttons and an optional trailing label.

		InputNum {
			Text: string | State<string>?,         trailing label
			Value: Source<number>?,                two-way; an internal Source (starting at Min or 0) when omitted
			Min: number?, Max: number?,            clamp range (plain numbers)
			Step: number?,                         button step (default 1) AND snapping of typed values when given
			Format: string?,                       string.format pattern; default "%d" for an integral Step, else "%.3f"
			OnChange: ((n: number) -> ())?,        after Value changed through the UI (not for external :Set)
			Disabled: (boolean | State<boolean>)?,
			Style: Style?, Modifier: ModifierInto<Frame>?, FieldModifier: ModifierInto<TextBox>?, FieldSpread: SpreadInto<TextBox>?,
		}

	Typing commits on Enter / focus loss (parse -> clamp/snap); text that does not parse reverts to the current value.
	One row Frame + TextBox + two SmallButtons (+ label). Returns the row Frame.
]]

local Quad = require("../Quad")
local q = Quad
local Frame = q.Elem "Frame"
local FrameModifier = q.Modifier "Frame"
local TextButtonModifier = q.Modifier "TextButton"
local inputNumName = FrameModifier():Name("InputNum")
local Button = require("../Button")
local Common = require("../Common")
local NumberField = require("./NumberField")
local NumberFormat = require("./NumberFormat")
local Style = require("../Style")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type InputNumProps = {
	read Text: (string | State<string>)?,
	read Value: Source<number>?,
	read Min: number?,
	read Max: number?,
	read Step: number?,
	read Format: string?,
	read OnChange: ((n: number) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
	read FieldModifier: Quad.ModifierInto<TextBox>?,
	read FieldSpread: Quad.SpreadInto<TextBox>?, -- [3.4.0] spread into the inner box (refs, hooks, descriptors)
}

local function InputNum(props: InputNumProps): Frame
	local style = props.Style or Style.default
	local min, max, step = props.Min, props.Max, props.Step
	local value: Source<number> = props.Value or q.Source(NumberFormat.normalize(0, min, max, step))
	local enabled = Common.enabled(props.Disabled)
	local set = Common.setter(value, props.OnChange)
	local stride = step or 1

	local function nudge(sign: number)
		if enabled:Get() then
			set(NumberFormat.normalize(value:Get() + sign * stride, min, max, step))
		end
	end

	return Frame({
		inputNumName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Common.rowLayout(style),
		NumberField.Edit({
			Value = value,
			OnSet = set,
			Min = min,
			Max = max,
			Step = step,
			Format = props.Format,
			Enabled = enabled,
			Style = style,
			Modifier = props.FieldModifier,
			Spread = props.FieldSpread,
			LayoutOrder = 1,
		}),
		Button.SmallButton({
			Text = "-",
			OnClick = function()
				nudge(-1)
			end,
			Style = style,
			Modifier = TextButtonModifier():LayoutOrder(2),
		}),
		Button.SmallButton({
			Text = "+",
			OnClick = function()
				nudge(1)
			end,
			Style = style,
			Modifier = TextButtonModifier():LayoutOrder(3),
		}),
		if props.Text then Common.label(style, props.Text, enabled, 4) else q.None,
	})
end

return InputNum
