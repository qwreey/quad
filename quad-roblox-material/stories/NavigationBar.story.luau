--!strict
-- Navigation bar (ShortNavigationBar) and navigation rail (WideNavigationRail) in mock screens. Count / Arrangement /
-- IconPosition / Badges are construction-time, so the bar and the rail are rebuilt when they change; the selected
-- destination is ONE Source shared by both; Expanded drives the rail's WideNavigationRailState.
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local D = q.Declaration
local themed = StoryParts.themed

type Config = { Count: number, Arrangement: Material.ShortNavigationBarArrangement, IconPosition: Material.NavigationItemIconPosition, Badges: boolean }

return StoryKit.story({
	controls = {
		Destinations = StoryKit.Slider(4, 3, 6, 1),
		Arrangement = StoryKit.Choose({ "EqualWeight", "Centered" }),
		IconPosition = StoryKit.Choose({ "Top", "Start" }),
		Badges = true,
		RailExpanded = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local page = q.Source<<string>>("dest1")
		local rail = Material.WideNavigationRailState()
		local sync = q.Effect(function()
			if c.RailExpanded:Get() == true then
				rail.Expand()
			else
				rail.Collapse()
			end
			return nil :: any
		end, c.RailExpanded)

		local config: q.State<Config> = c.Destinations:Compute(function(self: q.StateData<any>, _prev: Config?, arrangement: q.State<any>, position: q.State<any>, badges: q.State<any>): Config
			return {
				Count = self:Get(),
				Arrangement = if arrangement:Get() == "Centered" then "Centered" else "EqualWeight",
				IconPosition = if position:Get() == "Start" then "Start" else "Top",
				Badges = badges:Get() == true,
			}
		end, c.Arrangement, c.IconPosition, c.Badges)

		local function destinations(cfg: Config): { Material.NavigationDestination<string> }
			local list: { Material.NavigationDestination<string> } = {}
			for i = 1, cfg.Count do
				local badge: string? = nil
				if cfg.Badges and i == 2 then
					badge = ""
				elseif cfg.Badges and i == 3 then
					badge = "12"
				end
				table.insert(list, { Key = `dest{i}`, Label = `Item {i}`, Icon = "check", Badge = badge })
			end
			return list
		end

		local screens = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			return D.Frame {
				Name = "Screens",
				Size = UDim2.fromOffset(640, 560),
				BackgroundTransparency = 1,
				D.Frame {
					Name = "BarScreen",
					Size = UDim2.fromOffset(640, 160),
					BackgroundColor3 = theme.Color.Surface,
					ClipsDescendants = true,
					Material.ShortNavigationBar<<string>>({
						Theme = theme,
						Items = destinations(cfg),
						Selected = page,
						Arrangement = cfg.Arrangement,
						IconPosition = cfg.IconPosition,
						Modifier = D.Modifier.Frame():AnchorPoint(Vector2.new(0, 1)):Position(UDim2.fromScale(0, 1)),
					}),
				},
				D.Frame {
					Name = "RailScreen",
					Position = UDim2.fromOffset(0, 176),
					Size = UDim2.fromOffset(640, 384),
					BackgroundColor3 = theme.Color.SurfaceContainerLow,
					ClipsDescendants = true,
					Material.WideNavigationRail<<string>>({
						Theme = theme,
						State = rail,
						Items = destinations(cfg),
						Selected = page,
						Header = Material.IconButton({
							Theme = theme,
							Icon = Material.Icons.asset("menu") or "",
							TouchTarget = true,
							OnClick = rail.Toggle,
							Modifier = D.Modifier.TextButton():Position(UDim2.fromOffset(24, 0)),
						}),
					}),
				},
			}
		end, { Size = UDim2.fromOffset(640, 560) })

		return StoryParts.page(theme, follow, {
			StoryParts.caption(theme, StoryParts.show<<string>>(page, "Selected = ", StoryParts.tostr)),
			screens,
			D.Frame { Name = "Sync", Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, sync },
		})
	end,
})
