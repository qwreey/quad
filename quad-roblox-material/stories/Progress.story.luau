--!strict
local Material = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local D = q.Declaration
local StoryParts = require("./StoryParts")
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local page = StoryParts.page
local themed = StoryParts.themed

-- LinearProgress and CircularProgress. `Value` (a 0..1 State) and `Visible` are live; "Indeterminate" (no Value at
-- all), Size and Thickness are construction-time, so the story rebuilds the indicators on those.
type Look = { Indeterminate: boolean, Size: number, Thickness: number }

return StoryKit.story({
	controls = {
		Value = StoryKit.Slider(0.4, 0, 1, 0.01),
		Indeterminate = false,
		Visible = true,
		Size = StoryKit.Slider(48, 24, 96, 4),
		Thickness = StoryKit.Slider(4, 2, 10, 1),
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local look: q.State<Look> = c.Indeterminate:Compute(function(self, _prev, size, thickness)
			return { Indeterminate = self:Get() == true, Size = size:Get(), Thickness = thickness:Get() }
		end, c.Size, c.Thickness)
		return page(theme, follow, {
			caption(theme, show<<any>>(c.Value, "Value = ", function(v: number)
				return string.format("%.2f", v)
			end)),
			holder(
				120,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					local value = if l.Indeterminate then nil else c.Value
					return D.Frame {
						Name = "Indicators",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						D.UIListLayout {
							FillDirection = Enum.FillDirection.Vertical,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 16),
						},
						Material.LinearProgress({ Value = value, Visible = c.Visible, Theme = theme }),
						Material.CircularProgress({
							Value = value,
							Size = l.Size,
							Thickness = l.Thickness,
							Visible = c.Visible,
							Theme = theme,
						}),
					}
				end)
			),
		})
	end,
})
