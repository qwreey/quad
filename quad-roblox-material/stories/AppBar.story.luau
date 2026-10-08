--!strict
-- Top app bars over a scrolling list (the list starts at the bar's current bottom edge and pads its canvas by what the bar
-- has collapsed — the rows move as in Compose Scaffold's content-behind-the-bar layout, the scrollbar stays visible), and
-- the bottom app bars. Kind / Behavior / Subtitle / Center are construction-time (rebuilt).
local Material = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local D = q.Declaration
local themed = StoryParts.themed

type Config = { Kind: string, Behavior: string, Subtitle: boolean, Center: boolean }

local HEIGHTS: { [string]: number } = { Small = 64, CenterAligned = 64, Medium = 112, MediumFlexible = 112, Large = 152, LargeFlexible = 120 }

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
			local expanded = HEIGHTS[cfg.Kind] or 64
			if cfg.Subtitle and cfg.Kind == "MediumFlexible" then
				expanded = 136
			elseif cfg.Subtitle and cfg.Kind == "LargeFlexible" then
				expanded = 152
			end
			local rows: { Instance } = {}
			for i = 1, 30 do
				table.insert(rows, StoryParts.caption(theme, `List item {i}`))
			end
			-- the list starts at the bar's current bottom edge (the native scrollbar never under the bar) and pads its canvas by
			-- what the bar has collapsed, so the rows sit where a full-screen list padded by `expanded` would put them
			local offset: q.State<number> = if behavior then behavior.State.HeightOffset else q.Source(0)
			local top: q.State<number> = offset:Compute(function(self: q.StateData<number>): number
				return math.max(0, math.round(expanded + self:Get()))
			end)
			local position: q.State<UDim2> = top:Compute(function(self: q.StateData<number>): UDim2
				return UDim2.fromOffset(0, self:Get())
			end)
			local size: q.State<UDim2> = top:Compute(function(self: q.StateData<number>): UDim2
				return UDim2.new(1, 0, 1, -self:Get())
			end)
			local padding: q.State<UDim> = top:Compute(function(self: q.StateData<number>): UDim
				return UDim.new(0, expanded - self:Get())
			end)
			return D.Frame {
				Name = "Screen",
				Size = UDim2.fromOffset(400, 480),
				BackgroundColor3 = theme.Color.Surface,
				ClipsDescendants = true,
				D.ScrollingFrame {
					Name = "Content",
					Position = position,
					Size = size,
					BackgroundTransparency = 1,
					CanvasSize = UDim2.fromOffset(0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					if behavior then behavior.Hook else q.None,
					D.UIPadding {
						PaddingTop = padding,
						PaddingLeft = UDim.new(0, 16),
					},
					D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 24) },
					q.Slot<<Instance>>(rows),
				},
				D.Frame { Name = "BarLayer", Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 2, bar },
			}
		end, { Size = UDim2.fromOffset(400, 480) })

		return StoryParts.page(theme, follow, {
			StoryParts.caption(theme, StoryParts.show<<string>>(last, "Last action = ", StoryParts.tostr)),
			screen,
			D.Frame {
				Name = "Bottom",
				Size = UDim2.fromOffset(400, 156),
				BackgroundTransparency = 1,
				D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) },
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
