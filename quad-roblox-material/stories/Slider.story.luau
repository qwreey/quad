--!strict
local Material = require("../src")
local q = require("../src/Quad")
local D = q.Declaration
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local tostr = StoryParts.tostr
local page = StoryParts.page
local themed = StoryParts.themed

-- Slider (the M3 look — three-part track, bar handle; M2Slider.story is the Material 2 look): Min/Max/Step/ticks are construction-time (the story rebuilds on change); the value Source lives outside the
-- rebuild so the position survives, and `Disabled` / `ShowLabel` are live. `Format` shows percent.
type Look = { Min: number, Max: number, Step: number?, Ticks: boolean, Label: boolean, Percent: boolean }

return StoryKit.story({
	controls = {
		Min = StoryKit.Slider(0, -50, 50, 1),
		Max = StoryKit.Slider(100, 60, 200, 1),
		Step = StoryKit.Slider(0, 0, 20, 1), -- 0 = continuous
		ShowTicks = false,
		ShowLabel = true,
		Percent = false,
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local value = q.Source(30)
		local ended = q.Source(0)
		local look: q.State<Look> = c.Min:Compute(function(self, _prev, max, step, ticks, label, percent)
			local s: number = step:Get()
			return {
				Min = self:Get(),
				Max = max:Get(),
				Step = if s > 0 then s else nil,
				Ticks = ticks:Get() == true,
				Label = label:Get() == true,
				Percent = percent:Get() == true,
			}
		end, c.Max, c.Step, c.ShowTicks, c.ShowLabel, c.Percent)
		return page(theme, follow, {
			-- the M3 value label is a 32 px pill 12 px above the 44 px handle: leave it room inside the holder
			holder(
				112,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					local mn, mx = l.Min, l.Max
					return Material.Slider({
						Modifier = D.Modifier.Frame():Position(UDim2.fromOffset(0, 68)),
						Value = value,
						Min = mn,
						Max = mx,
						Step = l.Step,
						ShowTicks = l.Ticks,
						ShowLabel = l.Label,
						Format = if l.Percent
							then function(v: number): string
								return string.format("%d%%", (v - mn) / (mx - mn) * 100)
							end
							else nil,
						Disabled = c.Disabled,
						OnChangeEnd = function(v: number)
							ended:Set(v)
						end,
						Theme = theme,
					})
				end)
			),
			caption(theme, show<<number>>(value, "Value = ", function(v: number)
				return string.format("%.2f", v)
			end)),
			caption(theme, show<<number>>(ended, "Last drag ended at ", tostr)),
		})
	end,
})
