--!strict
-- PlotLines / PlotHistogram. The series is a Compute over three controls (Count / Amplitude / Frequency) — no
-- Heartbeat loop: moving a slider republishes the array and the plots follow.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Count = StoryKit.Slider(48, 2, 120, 1),
		Amplitude = StoryKit.Slider(80, 0, 100, 1),
		Frequency = StoryKit.Slider(3, 0.5, 12, 0.5),
		Label = "sine",
	},
	render = function(c)
		local series: q.State<{ number }> = c.Count:Compute(function(self, _prev, amp, freq)
			local n = math.floor(self:Get())
			local out: { number } = {}
			for i = 1, n do
				out[i] = amp:Get() * math.sin(i / n * math.pi * 2 * freq:Get())
			end
			return out
		end, c.Amplitude, c.Frequency)
		local magnitude: q.State<{ number }> = series:Compute(function(self)
			local out: { number } = {}
			for i, v in self:Get() do
				out[i] = math.abs(v)
			end
			return out
		end)
		return Devui.Window({
			Title = "Plots",
			Size = q.Source(Vector2.new(360, 330)),
			Children = Kids(
				Devui.PlotLines({ Values = series, Min = -100, Max = 100, Height = 90, Text = c.Label }),
				Devui.PlotHistogram({ Values = magnitude, Min = 0, Max = 100, Height = 70 }),
				Devui.PlotLines({ Values = series, Height = 50, Text = "auto range" }),
				Shared.show("points", c.Count)
			),
		})
	end,
})
