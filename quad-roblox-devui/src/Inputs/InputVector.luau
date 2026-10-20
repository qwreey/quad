--!strict
--[[
	InputVector2 / InputUDim2 (Iris: InputVector2 / InputUDim2) — one row of number fields editing the components of a
	Vector2 / UDim2 Source.

		InputVector2 {
			Text: string | State<string>?,         trailing label
			Value: Source<Vector2>?,               two-way; an internal Source (Vector2.zero) when omitted
			Min: number?, Max: number?,            applied to both components
			Step: number?, Format: string?,        as InputNum (default format "%d" for an integral Step, else "%.3f")
			Drag: boolean?,                        true: DragNum fields (drag / click to type); false (default): typed fields
			Speed: number?,                        Drag only
			OnChange: ((v: Vector2) -> ())?,       after Value changed through the UI
			Disabled: (boolean | State<boolean>)?,
			Style: Style?, Modifier: ModifierInto<Frame>?,
		}

		InputUDim2 { same minus Min/Max/Step/Format/Speed }   four fields: scale X, offset X, scale Y, offset Y
		             (scale fields "%.3f" speed 0.01, offset fields "%d" speed 1)

	Each field reads its component through a Compute and, on a user change, writes the WHOLE value back built from the
	the current value of the Source (so two fields committing in turn never overwrite each other with a stale copy).
]]

local Quad = require("../Quad")
local q = Quad
local Frame = q.Elem "Frame"
local FrameModifier = q.Modifier "Frame"
local inputVector2Name = FrameModifier():Name("InputVector2")
local inputUDim2Name = FrameModifier():Name("InputUDim2")
local Common = require("../Common")
local NumberField = require("./NumberField")
local Style = require("../Style")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type InputVector2Props = {
	read Text: (string | State<string>)?,
	read Value: Source<Vector2>?,
	read Min: number?,
	read Max: number?,
	read Step: number?,
	read Format: string?,
	read Drag: boolean?,
	read Speed: number?,
	read OnChange: ((v: Vector2) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

export type InputUDim2Props = {
	read Text: (string | State<string>)?,
	read Value: Source<UDim2>?,
	read Drag: boolean?,
	read OnChange: ((v: UDim2) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

export type FieldOptions = {
	Drag: boolean,
	Min: number?,
	Max: number?,
	Step: number?,
	Format: string?,
	Speed: number?,
	Enabled: State<boolean>,
	Style: Style,
}

-- one component field of a `Source<T>`: reads `get(value)`, writes `with(current, n)` back whole
local function component<T>(
	value: Source<T>,
	get: (T) -> number,
	with: (T, number) -> T,
	onChange: ((T) -> ())?,
	o: FieldOptions,
	order: number,
	name: string
): TextBox
	local shown: State<number> = value:Compute(function(self)
		return get(self:Get())
	end)
	local fieldProps: NumberField.FieldProps = {
		Value = shown,
		OnSet = function(n: number)
			local current = value:Get()
			local nextValue = with(current, n)
			if nextValue ~= current then
				value:Set(nextValue)
				if onChange then
					onChange(nextValue)
				end
			end
		end,
		Min = o.Min,
		Max = o.Max,
		Step = o.Step,
		Format = o.Format,
		Speed = o.Speed,
		Enabled = o.Enabled,
		Style = o.Style,
		Name = name,
		LayoutOrder = order,
	}
	return if o.Drag then NumberField.Drag(fieldProps) else NumberField.Edit(fieldProps)
end

local InputVector = {}

-- shared with InputColor3
InputVector.component = component

function InputVector.InputVector2(props: InputVector2Props): Frame
	local style = props.Style or Style.default
	local value: Source<Vector2> = props.Value or q.Source(Vector2.new(0, 0))
	local enabled = Common.enabled(props.Disabled)
	local o: FieldOptions = {
		Drag = props.Drag == true,
		Min = props.Min,
		Max = props.Max,
		Step = props.Step,
		Format = props.Format,
		Speed = props.Speed,
		Enabled = enabled,
		Style = style,
	}
	return Frame({
		inputVector2Name,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Common.rowLayout(style),
		component<<Vector2>>(value, function(v: Vector2)
			return v.X
		end, function(v: Vector2, n: number)
			return Vector2.new(n, v.Y)
		end, props.OnChange, o, 1, "X"),
		component<<Vector2>>(value, function(v: Vector2)
			return v.Y
		end, function(v: Vector2, n: number)
			return Vector2.new(v.X, n)
		end, props.OnChange, o, 2, "Y"),
		if props.Text then Common.label(style, props.Text, enabled, 3) else q.None,
	})
end

function InputVector.InputUDim2(props: InputUDim2Props): Frame
	local style = props.Style or Style.default
	local value: Source<UDim2> = props.Value or q.Source(UDim2.new(0, 0, 0, 0))
	local enabled = Common.enabled(props.Disabled)
	local drag = props.Drag == true
	local scale: FieldOptions = { Drag = drag, Format = "%.3f", Speed = 0.01, Enabled = enabled, Style = style }
	local offset: FieldOptions = { Drag = drag, Step = 1, Speed = 1, Enabled = enabled, Style = style }
	return Frame({
		inputUDim2Name,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Common.rowLayout(style),
		component<<UDim2>>(value, function(v: UDim2)
			return v.X.Scale
		end, function(v: UDim2, n: number)
			return UDim2.new(n, v.X.Offset, v.Y.Scale, v.Y.Offset)
		end, props.OnChange, scale, 1, "ScaleX"),
		component<<UDim2>>(value, function(v: UDim2)
			return v.X.Offset
		end, function(v: UDim2, n: number)
			return UDim2.new(v.X.Scale, n, v.Y.Scale, v.Y.Offset)
		end, props.OnChange, offset, 2, "OffsetX"),
		component<<UDim2>>(value, function(v: UDim2)
			return v.Y.Scale
		end, function(v: UDim2, n: number)
			return UDim2.new(v.X.Scale, v.X.Offset, n, v.Y.Offset)
		end, props.OnChange, scale, 3, "ScaleY"),
		component<<UDim2>>(value, function(v: UDim2)
			return v.Y.Offset
		end, function(v: UDim2, n: number)
			return UDim2.new(v.X.Scale, v.X.Offset, v.Y.Scale, n)
		end, props.OnChange, offset, 4, "OffsetY"),
		if props.Text then Common.label(style, props.Text, enabled, 5) else q.None,
	})
end

return InputVector
