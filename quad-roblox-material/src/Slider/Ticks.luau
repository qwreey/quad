--!strict
--[[
	Slider ticks (discrete sliders only): one 2 px Frame per step, colored by which side of the handle it is on.

	    Ticks.build({ Frac = frac, Range = max - min, Step = step, ShowTicks = props.ShowTicks, Disabled = disabled, Theme = theme })
	      -> { Instance }     empty for a continuous slider, `ShowTicks = false`, or more than 100 steps

	The caller seats the list in the rail through a `Slot`. Cost: one Frame per tick (Step count + 1); the per-tick color
	is a Compute of one shared "handle index" State (and, for RangeSlider's `FracLow`, the low handle's index).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local D = q.Declaration

export type Options = {
	Frac: q.State<number>,
	FracLow: q.State<number>?, -- RangeSlider: ticks are active only between FracLow and Frac
	Range: number,
	Step: number?,
	ShowTicks: boolean?,
	Disabled: q.State<boolean>,
	Theme: Theme.Theme,
}

local MAX_TICKS = 100

local function build(o: Options): { Instance }
	local ticks: { Instance } = {}
	local step = o.Step
	if step == nil or o.ShowTicks == false then
		return ticks
	end
	local range = o.Range
	local R = o.Theme.Raw
	local disabled = o.Disabled
	local count = math.floor(range / step + 1e-9)
	if count < 1 or count > MAX_TICKS then
		return ticks
	end
	local index: q.State<number> = o.Frac:Compute(function(self)
		return math.floor(self:Get() * range / step + 0.5)
	end)
	local fracLow = o.FracLow
	local lowIndex: q.State<number> = if fracLow ~= nil
		then fracLow:Compute(function(self)
			return math.floor(self:Get() * range / step + 0.5)
		end)
		else q.Source(0)
	local tickActive: q.State<Color3> = disabled:Compute(function(self, _prev, onPrimary, onSurface)
		return if self:Get() then onSurface:Get() else onPrimary:Get()
	end, R.OnPrimary, R.OnSurface)
	local tickInactive: q.State<Color3> = disabled:Compute(function(self, _prev, variant, onSurface)
		return if self:Get() then onSurface:Get() else variant:Get()
	end, R.OnSurfaceVariant, R.OnSurface)
	for i = 0, count do
		local color: q.State<Color3> = index:Compute(function(self, _prev, low, a, b)
			return if i <= self:Get() and i >= low:Get() then a:Get() else b:Get()
		end, lowIndex, tickActive, tickInactive)
		table.insert(
			ticks,
			D.Frame {
				Name = "Tick",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(i * step / range, 0, 0.5, 0),
				Size = UDim2.fromOffset(2, 2),
				BackgroundColor3 = color,
				BackgroundTransparency = 0.62,
				BorderSizePixel = 0,
			}
		)
	end
	return ticks
end

return { build = build }
