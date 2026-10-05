--!strict
--[[
	ProgressBar (Iris: ProgressBar).

		ProgressBar { Value: number | State<number>,        -- 0..1 (clamped)
		              Text: string | State<string>?,        -- overlay text; default is the percentage ("42%")
		              Style: Style?, Modifier: FrameModifier? }

	Two GuiObjects (track Frame + Fill Frame) and one TextLabel overlay, plus UICorner helpers. Full width,
	FrameHeight tall. The fill colour is the PlotHistogram token, the track FrameBg.
]]

local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
local Style = require("./Style")

type State<T> = Quad.State<T>
type Style = Style.Style

export type ProgressBarProps = {
	read Value: number | State<number>,
	read Text: (string | State<string>)?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

local function asState(v: number | State<number>): State<number>
	if type(v) == "number" then
		return q.Source(v)
	end
	return v
end

local function ProgressBar(props: ProgressBarProps): Frame
	local style = props.Style or Style.default
	local value = asState(props.Value)
	local fraction: State<number> = value:Compute(function(self)
		return math.clamp(self:Get(), 0, 1)
	end)
	local fillSize: State<UDim2> = fraction:Compute(function(self)
		return UDim2.new(self:Get(), 0, 1, 0)
	end)
	local label: string | State<string>
	if props.Text ~= nil then
		label = props.Text
	else
		local percent: State<string> = fraction:Compute(function(self)
			return `{math.floor(self:Get() * 100 + 0.5)}%`
		end)
		label = percent
	end
	local height: State<UDim2> = style.FrameHeight:Compute(function(self)
		return UDim2.new(1, 0, 0, self:Get())
	end)
	return D.Frame({
		props.Modifier or q.None,
		Name = "ProgressBar",
		Size = height,
		BackgroundColor3 = style.Color.FrameBg,
		BackgroundTransparency = style.Transparency.FrameBg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		UICorner = style.Metrics.FrameRounding,
		D.Frame({
			Name = "Fill",
			Size = fillSize,
			BackgroundColor3 = style.Color.PlotHistogram,
			BackgroundTransparency = style.Transparency.PlotHistogram,
			BorderSizePixel = 0,
		}),
		D.TextLabel({
			Name = "Label",
			Size = UDim2.fromScale(1, 1),
			Text = label,
			FontFace = style.Metrics.TextFont,
			TextSize = style.Metrics.TextSize,
			TextColor3 = style.Color.Text,
			TextTransparency = style.Transparency.Text,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
		}),
	})
end

return {
	ProgressBar = ProgressBar,
}
