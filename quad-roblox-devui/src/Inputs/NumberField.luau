--!strict
--[[
	NumberField — the numeric text field every number widget is built from (InputNum, DragNum, the vector and colour
	rows). One TextBox that SHOWS a number and reports user edits through `OnSet`; it owns no value itself, so the
	vector widgets can feed it one component of a bigger value.

		NumberField.Edit { Value, OnSet, Min?, Max?, Step?, Format?, Enabled, Style?, Modifier?, Name? }
			type, then commit on FocusLost/Enter: parse -> clamp/snap -> `OnSet(n)`. Invalid text reverts to the current value.
		NumberField.Drag { same + Speed? }
			drag horizontally to change the value (`Speed` units per pixel, default = Step or 1; a 3px dead zone separates
			a click from a drag); a click without drag (release inside the dead zone) enters text editing, which commits
			like Edit.

	Props:
		Value    State<number>         what is shown (a Source works: it is a State)
		OnSet    (n: number) -> ()      called with the normalized number on every user change (text commit / drag move)
		Enabled  State<boolean>         false: not editable, drag ignored (Common.enabled(props.Disabled))

	WHY NOT q.Out HERE: while typing, the text is not a number yet ("1." / "-" / ""), so nothing is written mid-wave; the
	text is read from the box when it loses focus and the canonical text is pushed back through a refresh tick on the
	`shown` Compute (so an invalid or unchanged commit still repaints the box with the canonical text). Nothing here
	feeds the upstream of an Observer: the box only ever reads `Value`; writes happen in the FocusLost / drag callbacks.
]]

local Quad = require("../Quad")
local q = Quad
local D = q.Declaration
local Common = require("../Common")
local Interaction = require("../Interaction")
local NumberFormat = require("./NumberFormat")
local Style = require("../Style")
local Util = require("../Util")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type FieldProps = {
	read Value: State<number>,
	read OnSet: (n: number) -> (),
	read Min: number?,
	read Max: number?,
	read Step: number?,
	read Format: string?,
	read Speed: number?,
	read Enabled: State<boolean>,
	read Style: Style?,
	read Modifier: Quad.TextBoxModifier?,
	read Name: string?,
	read LayoutOrder: number?,
}

-- pointer travel (px) below which a press-release is a click, not a drag
local DRAG_DEAD_ZONE = 3

local NumberField = {}

-- the text of the box now, or nil when it does not exist any more
local function boxText(ref: Quad.Ref<TextBox?>): string?
	local box = ref.Value
	if box == nil then
		return nil
	end
	return box.Text
end

local function build(props: FieldProps, dragging: boolean): TextBox
	local style = props.Style or Style.default
	local min, max, step = props.Min, props.Max, props.Step
	local fmt = props.Format or NumberFormat.defaultFormat(step)
	local value = props.Value
	local enabled = props.Enabled

	local refresh: Source<number> = q.Source(0)
	local shown: State<string> = value:Compute(function(self, _prev, _tick)
		return NumberFormat.format(self:Get(), fmt, step)
	end, refresh)
	local boxRef: Quad.Ref<TextBox?> = q.Ref<<TextBox?>>(nil)
	local editing: Source<boolean> = q.Source(not dragging)

	local function repaint()
		refresh:Set(refresh:Get() + 1)
	end

	-- commit the text typed into the box (FocusLost / Enter)
	local function commit()
		local text = boxText(boxRef)
		if text ~= nil then
			local n = NumberFormat.commitText(text, min, max, step)
			if n ~= nil then
				props.OnSet(n)
			end
		end
		repaint()
	end

	local hover = Interaction.hover()
	local look = Common.fieldLook(style, hover, enabled)
	local textLook = Common.textLook(style, enabled)
	local padX: State<UDim> = Util.pxX(style.Metrics.FramePadding)

	-- drag state (per field instance)
	local startValue = 0
	local moved = false
	local tracking = false
	local speed = props.Speed or step or 1

	local dragHook: any = q.None
	if dragging then
		local drag = Interaction.drag({
			Enabled = enabled,
			OnBegin = function(_x, _y)
				if editing:Get() or not enabled:Get() then
					return
				end
				tracking = true
				moved = false
				startValue = value:Get()
			end,
			OnMove = function(_x, _y, dx, _dy)
				if not tracking then
					return
				end
				if not moved then
					if math.abs(dx) <= DRAG_DEAD_ZONE then
						return
					end
					moved = true
				end
				props.OnSet(NumberFormat.normalize(startValue + dx * speed, min, max, step))
			end,
			OnEnd = function(_x, _y, _dx, _dy, cancelled)
				if not tracking then
					return
				end
				tracking = false
				if not moved and not cancelled then
					-- a click: edit the text
					editing:Set(true)
					local box = boxRef.Value
					if box ~= nil then
						box:CaptureFocus()
					end
				end
			end,
		})
		dragHook = drag.Hook
	end

	return D.TextBox({
		props.Modifier or q.None,
		boxRef,
		hover.Hook,
		dragHook,
		Name = props.Name or (if dragging then "DragField" else "InputField"),
		LayoutOrder = props.LayoutOrder or 0,
		Text = shown,
		TextEditable = if dragging then editing else enabled,
		ClearTextOnFocus = false,
		FontFace = style.Metrics.TextFont,
		TextSize = style.Metrics.TextSize,
		TextColor3 = textLook.Color,
		TextTransparency = textLook.Transparency,
		TextXAlignment = if dragging then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
		BackgroundColor3 = look.Color,
		BackgroundTransparency = look.Transparency,
		BorderSizePixel = 0,
		Size = Common.frameHeight(style),
		FocusLost = function(_enterPressed: boolean, _input: InputObject)
			if editing:Get() then
				commit()
			end
			if dragging then
				editing:Set(false)
			end
		end,
		UICorner = style.Metrics.FrameRounding,
		D.UIPadding({ PaddingLeft = padX, PaddingRight = padX }),
		Common.stroke(style),
		D.UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
	})
end

function NumberField.Edit(props: FieldProps): TextBox
	return build(props, false)
end

function NumberField.Drag(props: FieldProps): TextBox
	return build(props, true)
end

return NumberField
