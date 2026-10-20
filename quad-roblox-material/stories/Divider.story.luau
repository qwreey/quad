--!strict
-- Divider: Orientation and Inset are construction-time props, so one combined State rebuilds the demo. The three
-- static samples underneath show every Inset at once.
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local UIListLayout = q.Elem "UIListLayout"
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

type Config = { Orientation: "Horizontal" | "Vertical", Inset: "None" | "Start" | "Both" }

local function caption(theme: Material.Theme, text: string, order: number): TextLabel
	return TextLabel {
		Material.Text.Label("BodyMedium"),
		LayoutOrder = order,
		Size = UDim2.fromOffset(120, 24),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = theme.Color.OnSurface,
		Text = text,
	}
end

return StoryKit.story({
	controls = {
		Orientation = StoryKit.Choose({ "Horizontal", "Vertical" }),
		Inset = StoryKit.Choose({ "None", "Start", "Both" }),
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local config: q.State<Config> = c.Orientation:Compute(function(self: q.StateData<any>, _prev: Config?, inset: q.State<any>): Config
			return { Orientation = self:Get(), Inset = inset:Get() }
		end, c.Inset)

		local demo = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			local vertical = cfg.Orientation == "Vertical"
			return Frame {
				Name = "Demo",
				Size = if vertical then UDim2.fromOffset(280, 56) else UDim2.fromOffset(280, 0),
				AutomaticSize = if vertical then Enum.AutomaticSize.None else Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIListLayout {
					FillDirection = if vertical then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 12),
				},
				caption(theme, "Before", 1),
				Material.Divider({ Theme = theme, Orientation = cfg.Orientation, Inset = cfg.Inset, LayoutOrder = 2 }),
				caption(theme, "After", 3),
			}
		end, { Size = UDim2.fromOffset(280, 72), AutomaticSize = Enum.AutomaticSize.None, LayoutOrder = 1 })

		return Frame {
			follow,
			Name = "DividerStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Surface,
			UIPaddingOffset = 24,
			UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 16) },
			demo,
			Frame {
				Name = "Samples",
				LayoutOrder = 2,
				Size = UDim2.fromOffset(280, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) },
				Material.Divider({ Theme = theme, LayoutOrder = 1 }),
				Material.Divider({ Theme = theme, Inset = "Start", LayoutOrder = 2 }),
				Material.Divider({ Theme = theme, Inset = "Both", LayoutOrder = 3 }),
			},
		}
	end,
})
