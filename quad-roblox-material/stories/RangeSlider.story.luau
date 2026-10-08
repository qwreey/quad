--!strict
local Material = require("../src")
local q = require("../src/Quad")
local D = q.Declaration
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local page = StoryParts.page
local themed = StoryParts.themed

-- RangeSlider (the M3 look; M2RangeSlider.story is the Material 2 look): Min/Max/Step/ticks are construction-time (the story rebuilds on change); the two Sources live outside the
-- rebuild so the handles keep their place, and `Disabled` / `ShowLabel` are live.
-- The M3 variants Size / Vertical / TopToBottom are construction-time too (TopToBottom only when Vertical).
type Look = { Min: number, Max: number, Step: number?, Ticks: boolean, Label: boolean }
type Variant = { Size: Material.SliderSize, Vertical: boolean, TopToBottom: boolean }
type Both = { Look: Look, Variant: Variant }

return StoryKit.story({
	controls = {
		Min = StoryKit.Slider(0, -50, 50, 1),
		Max = StoryKit.Slider(100, 60, 200, 1),
		Step = StoryKit.Slider(0, 0, 20, 1), -- 0 = continuous
		ShowTicks = false,
		ShowLabel = true,
		Size = StoryKit.Choose({ "XS", "S", "M", "L", "XL" }),
		Vertical = false,
		TopToBottom = false,
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
		local variant: q.State<Variant> = c.Size:Compute(function(self, _prev, vertical, ttb)
			return { Size = self:Get(), Vertical = vertical:Get() == true, TopToBottom = ttb:Get() == true }
		end, c.Vertical, c.TopToBottom)
		local built: q.State<Both> = look:Compute(function(self, _prev, v)
			return { Look = self:Get(), Variant = v:Get() }
		end, variant)
		local both: q.State<string> = lo:Compute(function(self, _prev, h)
			return string.format("%.2f .. %.2f", self:Get(), h:Get())
		end, hi)
		return page(theme, follow, {
			-- the M3 value label is a 32 px pill 12 px above the 44 px handle: leave it room inside the holder
			holder(
				260,
				StoryKit.rebuild<<Both>>(built, function(b: Both)
					local l, v = b.Look, b.Variant
					local handleH = if v.Size == "L" then 68 elseif v.Size == "XL" then 108 else 44
					return Material.RangeSlider({
						Modifier = if v.Vertical
							then D.Modifier.Frame():Position(UDim2.fromOffset(64, 30)):Size(UDim2.fromOffset(handleH, 200))
							else D.Modifier.Frame():Position(UDim2.fromOffset(0, 68)),
						Size = v.Size,
						Orientation = if v.Vertical then "Vertical" else "Horizontal",
						TopToBottom = if v.Vertical and v.TopToBottom then true else nil,
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
