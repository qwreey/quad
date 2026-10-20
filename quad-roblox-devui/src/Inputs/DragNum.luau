--!strict
--[[
	DragNum (Iris: DragNum) — drag horizontally on the field to change the value; click without dragging to type.

		DragNum {
			Text: string | State<string>?,         trailing label
			Value: Source<number>?,                two-way; an internal Source (starting at Min or 0) when omitted
			Speed: number?,                        value units per pixel (default: Step, else 1)
			Min: number?, Max: number?, Step: number?,
			Format: string?,                       default "%d" for an integral Step, else "%.3f"
			OnChange: ((n: number) -> ())?,        after Value changed through the UI
			Disabled: (boolean | State<boolean>)?,
			Style: Style?, Modifier: ModifierInto<Frame>?, FieldModifier: ModifierInto<TextBox>?, FieldSpread: SpreadInto<TextBox>?,
		}

	The drag uses Interaction.drag (global pointer tracking only while the button is held; closed on release, focus
	loss and destroy). Movement inside a 3px dead zone is a click and opens the text editor; Enter / focus loss commits
	typed text (invalid text reverts). Returns a row Frame (field + optional label).
]]

local Quad = require("../Quad")
local q = Quad
local Frame = q.Elem "Frame"
local FrameModifier = q.Modifier "Frame"
local dragNumName = FrameModifier():Name("DragNum")
local Common = require("../Common")
local NumberField = require("./NumberField")
local NumberFormat = require("./NumberFormat")
local Style = require("../Style")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type DragNumProps = {
	read Text: (string | State<string>)?,
	read Value: Source<number>?,
	read Speed: number?,
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

local function DragNum(props: DragNumProps): Frame
	local style = props.Style or Style.default
	local value: Source<number> = props.Value or q.Source(NumberFormat.normalize(0, props.Min, props.Max, props.Step))
	local enabled = Common.enabled(props.Disabled)
	return Frame({
		dragNumName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Common.rowLayout(style),
		NumberField.Drag({
			Value = value,
			OnSet = Common.setter(value, props.OnChange),
			Min = props.Min,
			Max = props.Max,
			Step = props.Step,
			Format = props.Format,
			Speed = props.Speed,
			Enabled = enabled,
			Style = style,
			Modifier = props.FieldModifier,
			Spread = props.FieldSpread,
			LayoutOrder = 1,
		}),
		if props.Text then Common.label(style, props.Text, enabled, 2) else q.None,
	})
end

return DragNum
