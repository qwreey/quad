--!strict
--[[
	SliderNum (Iris: SliderNum) — a track with a grab handle and the value centred on it.

		SliderNum {
			Text: string | State<string>?,         trailing label
			Value: Source<number>?,                two-way; an internal Source (starting at Min) when omitted
			Min: number? (0), Max: number? (100),
			Step: number?,                         snap to multiples of Step counted from Min (Step = 1: integer slider)
			Format: string?,                       default "%d" for an integral Step, else "%.3f"
			OnChange: ((n: number) -> ())?,        after Value changed through the UI
			Disabled: (boolean | State<boolean>)?,
			Style: Style?, Modifier: FrameModifier?, TrackModifier: FrameModifier?,
		}

	Press / drag anywhere on the track: the grab centre follows the pointer (x taken from the input position against
	the AbsolutePosition/AbsoluteSize of the track, read at event time — layout may move). Interaction.drag tracks the pointer
	globally only while held. Returns a row Frame: Track (FrameBg) > Grab + ValueText, then the optional label.
]]

local Quad = require("../Quad")
local q = Quad
local D = q.Declaration
local Common = require("../Common")
local Interaction = require("../Interaction")
local NumberFormat = require("./NumberFormat")
local Style = require("../Style")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type SliderNumProps = {
	read Text: (string | State<string>)?,
	read Value: Source<number>?,
	read Min: number?,
	read Max: number?,
	read Step: number?,
	read Format: string?,
	read OnChange: ((n: number) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
	read TrackModifier: Quad.FrameModifier?,
}

local function SliderNum(props: SliderNumProps): Frame
	local style = props.Style or Style.default
	local min = props.Min or 0
	local max = props.Max or 100
	local step = props.Step
	local fmt = props.Format or NumberFormat.defaultFormat(step)
	local value: Source<number> = props.Value or q.Source(min)
	local enabled = Common.enabled(props.Disabled)
	local set = Common.setter(value, props.OnChange)
	local trackRef: Quad.Ref<Frame?> = q.Ref<<Frame?>>(nil)
	local grabMin = style.Metrics.GrabMinSize

	local fraction: State<number> = value:Compute(function(self)
		return NumberFormat.toFraction(self:Get(), min, max)
	end)
	local shown: State<string> = value:Compute(function(self)
		return NumberFormat.format(self:Get(), fmt, step)
	end)
	local grabAnchor: State<Vector2> = fraction:Compute(function(self)
		return Vector2.new(self:Get(), 0.5)
	end)
	local grabPos: State<UDim2> = fraction:Compute(function(self)
		return UDim2.fromScale(self:Get(), 0.5)
	end)
	local grabSize: State<UDim2> = grabMin:Compute(function(self)
		return UDim2.new(0, self:Get(), 1, -4)
	end)

	local function setFromX(x: number)
		if not enabled:Get() then
			return
		end
		local track = trackRef.Value
		if track == nil then
			return
		end
		local f = NumberFormat.pixelToFraction(x, track.AbsolutePosition.X, track.AbsoluteSize.X, grabMin:Get())
		set(NumberFormat.normalize(NumberFormat.fromFraction(f, min, max), min, max, step))
	end

	local hover = Interaction.hover()
	local drag = Interaction.drag({
		Enabled = enabled,
		OnBegin = function(x, _y)
			setFromX(x)
		end,
		OnMove = function(x, _y, _dx, _dy)
			setFromX(x)
		end,
	})
	local look = Common.fieldLook(style, hover, enabled)
	local grabLook = Style.interactive(style, "SliderGrab", hover.Hovered, drag.Dragging)
	local textLook = Common.textLook(style, enabled)

	return D.Frame({
		props.Modifier or q.None,
		Name = "SliderNum",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Common.rowLayout(style),
		D.Frame({
			props.TrackModifier or q.None,
			trackRef,
			hover.Hook,
			drag.Hook,
			Name = "Track",
			LayoutOrder = 1,
			Size = Common.frameHeight(style),
			BackgroundColor3 = look.Color,
			BackgroundTransparency = look.Transparency,
			BorderSizePixel = 0,
			UICorner = style.Metrics.FrameRounding,
			Common.stroke(style),
			D.UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
			D.Frame({
				Name = "Grab",
				AnchorPoint = grabAnchor,
				Position = grabPos,
				Size = grabSize,
				BackgroundColor3 = grabLook.Color,
				BackgroundTransparency = grabLook.Transparency,
				BorderSizePixel = 0,
				UICorner = style.Metrics.GrabRounding,
			}),
			D.TextLabel({
				Name = "ValueText",
				ZIndex = 2,
				Size = UDim2.fromScale(1, 1),
				Text = shown,
				FontFace = style.Metrics.TextFont,
				TextSize = style.Metrics.TextSize,
				TextColor3 = textLook.Color,
				TextTransparency = textLook.Transparency,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Active = false,
			}),
		}),
		if props.Text then Common.label(style, props.Text, enabled, 2) else q.None,
	})
end

return SliderNum
