--!strict
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local Frame = q.Elem "Frame"
local UIListLayout = q.Elem "UIListLayout"
local StoryParts = require("./StoryParts")
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local page = StoryParts.page
local themed = StoryParts.themed

-- LinearProgress, CircularProgress and the M3 Expressive pair: WavyProgress (determinate only — shown while
-- "Indeterminate" is off) and LoadingIndicator (always indeterminate; Size and Contained apply to it too). `Value` (a 0..1
-- State) and `Visible` are live; "Indeterminate" (no Value at all), Size and Contained are construction-time, so the
-- story rebuilds the indicators on those. CircularProgress is shown in a row of the arc sheet's four strokes
-- (Thickness = 0.05 / 0.10 / 0.15 / 0.20 x Size — the stroke snaps to these, so a free Thickness slider is not shown).
type Look = { Indeterminate: boolean, Size: number, Contained: boolean }

return StoryKit.story({
	controls = {
		Value = StoryKit.Slider(0.4, 0, 1, 0.01),
		Indeterminate = false,
		Visible = true,
		Size = StoryKit.Slider(48, 24, 96, 4),
		Contained = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local look: q.State<Look> = c.Indeterminate:Compute(function(self, _prev, size, contained)
			return {
				Indeterminate = self:Get() == true,
				Size = size:Get(),
				Contained = contained:Get() == true,
			}
		end, c.Size, c.Contained)
		return page(theme, follow, {
			caption(theme, show<<any>>(c.Value, "Value = ", function(v: number)
				return string.format("%.2f", v)
			end)),
			holder(
				260,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					local value = if l.Indeterminate then nil else c.Value
					return Frame {
						Name = "Indicators",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						UIListLayout {
							FillDirection = Enum.FillDirection.Vertical,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 16),
						},
						Material.LinearProgress({ Value = value, Visible = c.Visible, Theme = theme }),
						if value ~= nil
							then Material.WavyProgress({ Value = value, Visible = c.Visible, Theme = theme })
							else q.None,
						Material.LoadingIndicator({ Size = l.Size, Contained = l.Contained, Visible = c.Visible, Theme = theme }),
						Frame {
							Name = "Rings",
							Size = UDim2.new(1, 0, 0, l.Size),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							UIListLayout {
								FillDirection = Enum.FillDirection.Horizontal,
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 12),
							},
							Material.CircularProgress({ Value = value, Size = l.Size, Thickness = l.Size * 0.05, Visible = c.Visible, Theme = theme }),
							Material.CircularProgress({ Value = value, Size = l.Size, Thickness = l.Size * 0.10, Visible = c.Visible, Theme = theme }),
							Material.CircularProgress({ Value = value, Size = l.Size, Thickness = l.Size * 0.15, Visible = c.Visible, Theme = theme }),
							Material.CircularProgress({ Value = value, Size = l.Size, Thickness = l.Size * 0.20, Visible = c.Visible, Theme = theme }),
						},
					}
				end)
			),
		})
	end,
})
