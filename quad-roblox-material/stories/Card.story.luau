--!strict
-- Card: Elevated / Filled / Outlined surfaces. Title / Body are Sources bound straight into the body labels;
-- Variant / Padding / Gap are construction-time props, so one combined State rebuilds the cards (StoryKit.rebuild).
-- An interactive card (OnClick), a disabled interactive one, and the click count shown live.
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local UIListLayout = q.Elem "UIListLayout"
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

type Config = { Variant: Material.CardVariant, Padding: number, Gap: number }

return StoryKit.story({
	controls = {
		Title = "Elevated card",
		Body = "Surface container low with a level 1 shadow. The text is a Source from the control panel.",
		Variant = StoryKit.Choose({ "Elevated", "Filled", "Outlined" }),
		Padding = StoryKit.Slider(16, 0, 32, 4),
		Gap = StoryKit.Slider(8, 0, 24, 2),
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local clicks = q.Source(0)
		local config: q.State<Config> = c.Variant:Compute(function(self: q.StateData<any>, _prev: Config?, padding: q.State<any>, gap: q.State<any>): Config
			return { Variant = self:Get(), Padding = padding:Get(), Gap = gap:Get() }
		end, c.Padding, c.Gap)

		local function body(): q.Slot<Instance>
			return q.Slot<<Instance>>({
				TextLabel {
					Material.Text.Label("TitleMedium"),
					Name = "Title",
					Size = UDim2.fromOffset(260, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = theme.Color.OnSurface,
					Text = c.Title,
				},
				TextLabel {
					Material.Text.Label("BodyMedium"),
					Name = "Body",
					Size = UDim2.fromOffset(260, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = theme.Color.OnSurfaceVariant,
					Text = c.Body,
				},
			})
		end

		local static = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			return Material.Card({
				Theme = theme,
				Variant = cfg.Variant,
				Padding = cfg.Padding,
				Gap = cfg.Gap,
				Children = body(),
			})
		end, { Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = 1 })

		local interactive = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			return Material.Card({
				Theme = theme,
				Variant = cfg.Variant,
				Padding = cfg.Padding,
				Gap = cfg.Gap,
				Disabled = c.Disabled,
				OnClick = function()
					clicks:Set(clicks:Get() + 1)
				end,
				Children = body(),
			})
		end, { Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = 2 })

		return Frame {
			follow,
			Name = "CardStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Surface,
			UIPaddingOffset = 24,
			UIListLayout {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 16),
			},
			static,
			interactive,
			TextLabel {
				Material.Text.Label("LabelMedium"),
				Name = "Clicks",
				LayoutOrder = 3,
				Size = UDim2.fromOffset(300, 20),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = theme.Color.OnSurfaceVariant,
				Text = clicks:Compute(function(self: q.StateData<number>): string
					return `Interactive card clicked {self:Get()} times (Disabled blocks it)`
				end),
			},
		}
	end,
})
