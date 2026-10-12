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
			Style: Style?, Modifier: FrameModifier?, FieldModifier: TextBoxModifier?,
		}

	The drag uses Interaction.drag (global pointer tracking only while the button is held; closed on release, focus
	loss and destroy). Movement inside a 3px dead zone is a click and opens the text editor; Enter / focus loss commits
	typed text (invalid text reverts). Returns a row Frame (field + optional label).
]]

local Quad = require("../Quad")
local q = Quad
local D = q.Declaration
local dragNumName = D.Modifier.Frame():Name("DragNum")
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
	read Modifier: Quad.FrameModifier?,
	read FieldModifier: Quad.TextBoxModifier?,
}

local function DragNum(props: DragNumProps): Frame
	local style = props.Style or Style.default
	local value: Source<number> = props.Value or q.Source(NumberFormat.normalize(0, props.Min, props.Max, props.Step))
	local enabled = Common.enabled(props.Disabled)
	return D.Frame({
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
			LayoutOrder = 1,
		}),
		if props.Text then Common.label(style, props.Text, enabled, 2) else q.None,
	})
end

return DragNum
