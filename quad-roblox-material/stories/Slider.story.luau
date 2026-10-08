--!strict
local Material = require("../src")
local q = require("./Quad")
local D = q.Declaration
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local tostr = StoryParts.tostr
local page = StoryParts.page
local themed = StoryParts.themed

-- Slider (the M3 look — three-part track, bar handle; M2Slider.story is the Material 2 look): Min/Max/Step/ticks and
-- the M3 variants (Size, Vertical, TopToBottom, Centered, inset icons) are construction-time (the story rebuilds on
-- change); the value Source lives outside the rebuild so the position survives, and `Disabled` is live. `Format` shows
-- percent. Combinations the slider refuses are skipped here: TopToBottom only when Vertical, inset icons only from size
-- M on a standard (not centered) slider.
type Look = { Min: number, Max: number, Step: number?, Ticks: boolean, Label: boolean, Percent: boolean }
type Variant = { Size: Material.SliderSize, Vertical: boolean, TopToBottom: boolean, Centered: boolean, Icons: boolean }
type Both = { Look: Look, Variant: Variant }

return StoryKit.story({
	controls = {
		Min = StoryKit.Slider(0, -50, 50, 1),
		Max = StoryKit.Slider(100, 60, 200, 1),
		Step = StoryKit.Slider(0, 0, 20, 1), -- 0 = continuous
		ShowTicks = false,
		ShowLabel = true,
		Percent = false,
		Size = StoryKit.Choose({ "XS", "S", "M", "L", "XL" }),
		Vertical = false,
		TopToBottom = false,
		Centered = false,
		InsetIcons = false,
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
		local variant: q.State<Variant> = c.Size:Compute(function(self, _prev, vertical, ttb, centered, icons)
			return {
				Size = self:Get(),
				Vertical = vertical:Get() == true,
				TopToBottom = ttb:Get() == true,
				Centered = centered:Get() == true,
				Icons = icons:Get() == true,
			}
		end, c.Vertical, c.TopToBottom, c.Centered, c.InsetIcons)
		local both: q.State<Both> = look:Compute(function(self, _prev, v)
			return { Look = self:Get(), Variant = v:Get() }
		end, variant)
		return page(theme, follow, {
			-- the M3 value label is a 32 px pill 12 px above the handle (left of it when vertical): leave it room
			holder(
				260,
				StoryKit.rebuild<<Both>>(both, function(b: Both)
					local l, v = b.Look, b.Variant
					local mn, mx = l.Min, l.Max
					local icons = v.Icons and not v.Centered and (v.Size == "M" or v.Size == "L" or v.Size == "XL")
					local handleH = if v.Size == "L" then 68 elseif v.Size == "XL" then 108 else 44
					return Material.Slider({
						Modifier = if v.Vertical
							then D.Modifier.Frame():Position(UDim2.fromOffset(64, 30)):Size(UDim2.fromOffset(handleH, 200))
							else D.Modifier.Frame():Position(UDim2.fromOffset(0, 68)),
						Size = v.Size,
						Orientation = if v.Vertical then "Vertical" else "Horizontal",
						TopToBottom = if v.Vertical and v.TopToBottom then true else nil,
						Centered = v.Centered,
						TrackIconActiveStart = if icons then "check" else nil,
						TrackIconInactiveEnd = if icons then "close" else nil,
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
