--!strict
-- Scaffold: a top app bar (with its scroll behavior) over a scrolling list, a bottom bar, a FAB at the chosen position and a
-- snackbar host (the FAB, or the "Show snackbar" row, shows one above the FAB / the bottom bar). The list fills the content
-- region (from the bar's current bottom — its scrollbar is never under a bar) and takes innerPadding.Top as its top padding.
-- Every control is construction-time (rebuilt).
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local D = q.Declaration
local themed = StoryParts.themed

type Config = { TopBar: string, Behavior: string, BottomBar: string, Fab: string, FabPosition: string }

return StoryKit.story({
	controls = {
		TopBar = StoryKit.Choose({ "MediumFlexible", "Small", "none" }),
		Behavior = StoryKit.Choose({ "exitUntilCollapsed", "enterAlways", "pinned" }),
		BottomBar = StoryKit.Choose({ "ShortNavigationBar", "BottomAppBar", "FlexibleBottomAppBar", "none" }),
		Fab = StoryKit.Choose({ "Regular", "Extended", "none" }),
		FabPosition = StoryKit.Choose({ "End", "Start", "Center", "EndOverlay" }),
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
		local config: q.State<Config> = c.TopBar:Compute(function(self: q.StateData<any>, _prev: Config?, behavior: q.State<any>, bottomBar: q.State<any>, fab: q.State<any>, position: q.State<any>): Config
			return { TopBar = self:Get(), Behavior = behavior:Get(), BottomBar = bottomBar:Get(), Fab = fab:Get(), FabPosition = position:Get() }
		end, c.Behavior, c.BottomBar, c.Fab, c.FabPosition)
		local page = q.Source("home")

		local screen = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			local behavior: Material.TopAppBarScrollBehavior
			if cfg.Behavior == "pinned" then
				behavior = Material.TopAppBarDefaults.pinnedScrollBehavior()
			elseif cfg.Behavior == "enterAlways" then
				behavior = Material.TopAppBarDefaults.enterAlwaysScrollBehavior()
			else
				behavior = Material.TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
			end
			local topBar: Frame? = nil
			if cfg.TopBar == "MediumFlexible" then
				topBar = Material.MediumFlexibleTopAppBar({ Theme = theme, Title = "Scaffold", Subtitle = "MediumFlexibleTopAppBar", ScrollBehavior = behavior,
					NavigationIcon = { Icon = "menu", Label = "Menu", OnClick = did("Menu") } })
			elseif cfg.TopBar == "Small" then
				topBar = Material.TopAppBar({ Theme = theme, Title = "Scaffold", ScrollBehavior = behavior,
					NavigationIcon = { Icon = "menu", Label = "Menu", OnClick = did("Menu") } })
			end
			local bottomBar: Frame? = nil
			if cfg.BottomBar == "ShortNavigationBar" then
				bottomBar = Material.ShortNavigationBar<<string>>({
					Theme = theme,
					Selected = page,
					Items = { { Key = "home", Label = "Home", Icon = "check" }, { Key = "edit", Label = "Edit", Icon = "edit" }, { Key = "calendar", Label = "Calendar", Icon = "calendar" } },
				})
			elseif cfg.BottomBar == "BottomAppBar" then
				bottomBar = Material.BottomAppBar({ Theme = theme, Actions = { { Icon = "check", Label = "Done", OnClick = did("Done") }, { Icon = "edit", Label = "Edit", OnClick = did("Edit") } } })
			elseif cfg.BottomBar == "FlexibleBottomAppBar" then
				bottomBar = Material.FlexibleBottomAppBar({ Theme = theme, Actions = { { Icon = "edit", Label = "Edit", OnClick = did("Edit") }, { Icon = "check", Label = "Done", OnClick = did("Done") }, { Icon = "close", Label = "Close", OnClick = did("Close") } } })
			end
			-- the snackbar layer and its host belong to this build (a rebuild destroys the layer)
			local layer = Material.Overlay.new({ Theme = theme })
			local snackbars = Material.Snackbar.new({ Overlay = layer, Theme = theme })
			local count = 0
			local function snack()
				count += 1
				snackbars:Show({ Text = `Snackbar {count}`, Action = { Label = "Undo", OnClick = did("Undo") } })
			end
			local fab: TextButton? = nil
			if cfg.Fab ~= "none" then
				fab = Material.FAB({ Theme = theme, Icon = Material.Icons.asset("edit") or "", Label = if cfg.Fab == "Extended" then "Compose" else nil, OnClick = snack })
			end
			local rows: { Instance } = {
				Material.Button({ Theme = theme, Label = "Show snackbar", Variant = "Tonal", OnClick = snack, Modifier = D.Modifier.TextButton():LayoutOrder(0) }),
			}
			for i = 1, 30 do
				table.insert(rows, D.TextLabel {
					Name = "Row",
					Material.Text.Label("BodyLarge"),
					Size = UDim2.new(1, 0, 0, 48),
					BackgroundTransparency = 1,
					LayoutOrder = i,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = theme.Color.OnSurface,
					Text = `List item {i}`,
				})
			end
			return D.Frame {
				Name = "Screen",
				Size = UDim2.fromOffset(400, 520),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				Material.Scaffold({
					Theme = theme,
					TopBar = topBar,
					BottomBar = bottomBar,
					FloatingActionButton = fab,
					FloatingActionButtonPosition = cfg.FabPosition :: Material.FabPosition,
					SnackbarHost = layer.Layer,
					Content = function(innerPadding: Material.PaddingValues): GuiObject
						return D.ScrollingFrame {
							Name = "Content",
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							CanvasSize = UDim2.fromOffset(0, 0),
							AutomaticCanvasSize = Enum.AutomaticSize.Y,
							ScrollBarThickness = 4,
							ScrollBarImageColor3 = theme.Color.OnSurface,
							behavior.Hook,
							D.UIPadding { PaddingTop = innerPadding.Top, PaddingLeft = UDim.new(0, 16) },
							D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder },
							q.Slot<<Instance>>(rows),
						}
					end,
				}),
			}
		end, { Size = UDim2.fromOffset(400, 520) })

		return StoryParts.page(theme, follow, {
			StoryParts.caption(theme, StoryParts.show<<string>>(last, "Last action = ", StoryParts.tostr)),
			screen,
		})
	end,
})
