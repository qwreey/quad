--!strict
-- Top app bars over a scrolling list, laid out by a Scaffold (the list fills the content region, which starts at the bar's
-- current bottom edge, and takes innerPadding.Top — what the bar has collapsed — as its top padding: the rows move as in
-- Compose's Scaffold, the scrollbar stays visible), and the bottom app bars. Kind / Behavior / Subtitle / Center are
-- construction-time (rebuilt).
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local Frame = q.Elem "Frame"
local ScrollingFrame = q.Elem "ScrollingFrame"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local themed = StoryParts.themed

type Config = { Kind: string, Behavior: string, Subtitle: boolean, Center: boolean }

return StoryKit.story({
	controls = {
		Kind = StoryKit.Choose({ "Small", "CenterAligned", "Medium", "MediumFlexible", "Large", "LargeFlexible" }),
		Behavior = StoryKit.Choose({ "exitUntilCollapsed", "enterAlways", "pinned", "none" }),
		Subtitle = false,
		Center = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local last = q.Source("none")
		local function did(label: string): () -> ()
			return function()
				last:Set(label)
			end
		end
		local config: q.State<Config> = c.Kind:Compute(function(self: q.StateData<any>, _prev: Config?, behavior: q.State<any>, subtitle: q.State<any>, center: q.State<any>): Config
			return { Kind = self:Get(), Behavior = behavior:Get(), Subtitle = subtitle:Get() == true, Center = center:Get() == true }
		end, c.Behavior, c.Subtitle, c.Center)

		local screen = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			local behavior: Material.TopAppBarScrollBehavior? = nil
			if cfg.Behavior == "pinned" then
				behavior = Material.TopAppBarDefaults.pinnedScrollBehavior()
			elseif cfg.Behavior == "enterAlways" then
				behavior = Material.TopAppBarDefaults.enterAlwaysScrollBehavior()
			elseif cfg.Behavior == "exitUntilCollapsed" then
				behavior = Material.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
			end
			local props: Material.TopAppBarProps = {
				Theme = theme,
				Title = cfg.Kind .. " title",
				Subtitle = if cfg.Subtitle then "Subtitle" else nil,
				TitleHorizontalAlignment = if cfg.Center then "Center" else "Start",
				NavigationIcon = { Icon = "menu", Label = "Menu", OnClick = did("Menu") },
				Actions = {
					{ Icon = "edit", Label = "Edit", OnClick = did("Edit") },
					{ Icon = "calendar", Label = "Calendar", OnClick = did("Calendar") },
					{ Icon = "check", Label = "Done", OnClick = did("Done") },
				},
				MaxItemCount = 2,
				ScrollBehavior = behavior,
			}
			local bar: Frame
			if cfg.Kind == "CenterAligned" then
				bar = Material.CenterAlignedTopAppBar(props)
			elseif cfg.Kind == "Medium" then
				bar = Material.MediumTopAppBar(props)
			elseif cfg.Kind == "MediumFlexible" then
				bar = Material.MediumFlexibleTopAppBar(props)
			elseif cfg.Kind == "Large" then
				bar = Material.LargeTopAppBar(props)
			elseif cfg.Kind == "LargeFlexible" then
				bar = Material.LargeFlexibleTopAppBar(props)
			else
				bar = Material.TopAppBar(props)
			end
			local rows: { Instance } = {}
			for i = 1, 30 do
				table.insert(rows, StoryParts.caption(theme, `List item {i}`))
			end
			return Frame {
				Name = "Screen",
				Size = UDim2.fromOffset(400, 480),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Material.Scaffold({
					Theme = theme,
					ContainerColor = theme.Color.Surface,
					TopBar = bar,
					Content = function(innerPadding: Material.PaddingValues): GuiObject
						return ScrollingFrame {
							Name = "Content",
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							CanvasSize = UDim2.fromOffset(0, 0),
							AutomaticCanvasSize = Enum.AutomaticSize.Y,
							if behavior then behavior.Hook else q.None,
							UIPadding {
								PaddingTop = innerPadding.Top,
								PaddingLeft = UDim.new(0, 16),
							},
							UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 24) },
							q.Slot<<Instance>>(rows),
						}
					end,
				}),
			}
		end, { Size = UDim2.fromOffset(400, 480) })

		return StoryParts.page(theme, follow, {
			StoryParts.caption(theme, StoryParts.show<<string>>(last, "Last action = ", StoryParts.tostr)),
			screen,
			Frame {
				Name = "Bottom",
				Size = UDim2.fromOffset(400, 156),
				BackgroundTransparency = 1,
				UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) },
				Material.FlexibleBottomAppBar({
					Theme = theme,
					LayoutOrder = 1,
					Actions = { { Icon = "edit", Label = "Edit", OnClick = did("Edit") }, { Icon = "check", Label = "Done", OnClick = did("Done") }, { Icon = "close", Label = "Close", OnClick = did("Close") } },
				}),
				Material.BottomAppBar({
					Theme = theme,
					LayoutOrder = 2,
					Actions = { { Icon = "check", Label = "Done", OnClick = did("Done") }, { Icon = "edit", Label = "Edit", OnClick = did("Edit") } },
					FloatingActionButton = { Icon = "edit", OnClick = did("FAB") },
				}),
			},
		})
	end,
})
