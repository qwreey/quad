--!strict
local Material = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local page = StoryParts.page
local themed = StoryParts.themed

-- RangeSlider: Min/Max/Step/ticks are construction-time (the story rebuilds on change); the two Sources live outside the
-- rebuild so the handles keep their place, and `Disabled` / `ShowLabel` are live.
type Look = { Min: number, Max: number, Step: number?, Ticks: boolean, Label: boolean }

return StoryKit.story({
	controls = {
		Min = StoryKit.Slider(0, -50, 50, 1),
		Max = StoryKit.Slider(100, 60, 200, 1),
		Step = StoryKit.Slider(0, 0, 20, 1), -- 0 = continuous
		ShowTicks = false,
		ShowLabel = true,
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local lo = q.Source(20)
		local hi = q.Source(70)
		local ended = q.Source("-")
		local look: q.State<Look> = c.Min:Compute(function(self, _prev, max, step, ticks, label)
			local s: number = step:Get()
			return {
				Min = self:Get(),
				Max = max:Get(),
				Step = if s > 0 then s else nil,
				Ticks = ticks:Get() == true,
				Label = label:Get() == true,
			}
		end, c.Max, c.Step, c.ShowTicks, c.ShowLabel)
		local both: q.State<string> = lo:Compute(function(self, _prev, h)
			return string.format("%.2f .. %.2f", self:Get(), h:Get())
		end, hi)
		return page(theme, follow, {
			holder(
				56,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					return Material.RangeSlider({
						Start = lo,
						End = hi,
						Min = l.Min,
						Max = l.Max,
						Step = l.Step,
						ShowTicks = l.Ticks,
						ShowLabel = l.Label,
						Disabled = c.Disabled,
						OnChangeEnd = function(a: number, b: number)
							ended:Set(string.format("%.2f .. %.2f", a, b))
						end,
						Theme = theme,
					})
				end)
			),
			caption(theme, show<<string>>(both, "Start .. End = ", function(s: string)
				return s
			end)),
			caption(theme, show<<string>>(ended, "Last drag ended at ", function(s: string)
				return s
			end)),
			caption(theme, "A press grabs the nearest handle; keys move one handle, Return / gamepad X switches."),
		})
	end,
})
