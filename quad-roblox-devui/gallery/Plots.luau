--!strict
--[[
	Demo section "Plots" — PlotLines fed by a rolling frame-time series and a PlotHistogram over the same data.

	COST (documented): a `Clock.ticker` samples Heartbeat every 0.1 s; per sample ONE new array of at most `WINDOW`
	numbers is built and `:Set` (PlotLines reads the whole series, replace-to-update). Between samples Heartbeat only
	adds dt to a number. The plot widgets keep a bounded instance count (`Plot.MaxPoints`).
	Pause with the checkbox: the Heartbeat connection stays (it belongs to the section) but nothing is allocated. The
	ticker is gated on `active` (the demo window's Open and not Collapsed; the Plots header's own open state is NOT part of it): a hidden window has no Heartbeat connection at all.
]]

local Devui = require("../src")
local Context = require("./Context")
local Clock = require("./Clock")
local q = require("./Quad")

type Context = Context.Context

local Kids = Devui.Kids

local WINDOW = 60
local PERIOD = 0.1

local function Plots(ctx: Context, active: q.State<boolean>): Instance
	local style = ctx.Style
	local paused = q.Source(false)
	local series = q.Source<<{ number }>>({})
	local last = 0

	local ticker = Clock.ticker(PERIOD, function(elapsed: number)
		if paused:Get() then
			return
		end
		last = 1 / math.max(elapsed, 1e-3)
		local old: { number } = series:Get()
		local n = #old
		local first = if n >= WINDOW then 2 else 1
		local nextSeries: { number } = {}
		for i = first, n do
			table.insert(nextSeries, old[i])
		end
		table.insert(nextSeries, last)
		series:Set(nextSeries)
	end, active)

	local label: q.State<string> = series:Compute(function(self)
		local v = self:Get()
		return string.format("%.0f samples/s  (%d points)", v[#v] or 0, #v)
	end)

	return Devui.CollapsingHeader({
		Text = "Plots",
		Style = style,
		Children = Kids(
			ticker,
			Devui.Checkbox({ Text = "pause sampling", Value = paused, Style = style }),
			Devui.PlotLines({ Values = series, Min = 0, Height = 70, Text = label, Style = style }),
			Devui.PlotHistogram({ Values = series, Min = 0, Height = 50, Style = style }),
			Devui.TextDisabled({ Text = "Rolling series of 1 / Heartbeat dt, sampled at 10 Hz.", Style = style })
		),
	})
end

return Plots
