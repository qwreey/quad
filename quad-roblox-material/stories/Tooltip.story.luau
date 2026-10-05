--!strict
-- Tooltip: `Tooltip.hook` on a button (Text follows the control while the tooltip is up), a disabled-able hook, and the
-- bare `Tooltip.Plain` visual. The hook is one-shot per target, so a changed Delay / Gap rebuilds the target.
local Material = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local D = q.Declaration
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

type Config = { Delay: number, Gap: number }

return StoryKit.story({
	controls = {
		Text = "Add to favorites",
		Delay = StoryKit.Slider(0.5, 0, 2, 0.1),
		Gap = StoryKit.Slider(4, 0, 24, 2),
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c, ctx)
		local theme, follow = themed(c.Scheme)
		local config: q.State<Config> = c.Delay:Compute(function(self: q.StateData<any>, _prev: Config?, gap: q.State<any>): Config
			return { Delay = self:Get(), Gap = gap:Get() }
		end, c.Gap)

		local target = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			local tip = Material.Tooltip.hook({
				Text = c.Text,
				Delay = cfg.Delay,
				Gap = cfg.Gap,
				Disabled = c.Disabled,
				Overlay = ctx.Overlay,
				Theme = theme,
			})
			return Material.Button({
				Theme = theme,
				Variant = "Tonal",
				Label = "Hover or select me",
				Hooks = { tip.Hook },
				Modifier = D.Modifier.TextButton():Position(UDim2.fromOffset(0, 40)),
			})
		end, { Size = UDim2.fromOffset(240, 100), AutomaticSize = Enum.AutomaticSize.None, LayoutOrder = 1 })

		return D.Frame {
			follow,
			Name = "TooltipStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Surface,
			UIPaddingOffset = 24,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 16) },
			target,
			Material.Tooltip.Plain({ Theme = theme, Text = c.Text }),
		}
	end,
})
