--!strict
-- Floating toolbars: horizontal (leading / content / trailing) and vertical, each with and without a FAB; Expanded is a
-- live Source; Colors and FAB position are construction-time (rebuilt).
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local D = q.Declaration
local themed = StoryParts.themed

type Config = { Colors: Material.FloatingToolbarColors, FabAtStart: boolean }

return StoryKit.story({
	controls = {
		Expanded = true,
		Colors = StoryKit.Choose({ "Standard", "Vibrant" }),
		FabAtStart = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local expanded: q.State<boolean> = c.Expanded:Compute(function(self)
			return self:Get() == true
		end)
		local bold = q.Source(false)
		local last = q.Source("none")
		local function did(label: string): () -> ()
			return function()
				last:Set(label)
			end
		end
		local function a(icon: string, label: string): Material.AppBarAction
			return { Icon = icon, Label = label, OnClick = did(label) }
		end
		local config: q.State<Config> = c.Colors:Compute(function(self: q.StateData<any>, _prev: Config?, start: q.State<any>): Config
			return { Colors = if self:Get() == "Vibrant" then "Vibrant" else "Standard", FabAtStart = start:Get() == true }
		end, c.FabAtStart)
		local screen = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			return D.Frame {
				Name = "Screen",
				Size = UDim2.fromOffset(640, 400),
				BackgroundColor3 = theme.Color.Surface,
				ClipsDescendants = true,
				Material.HorizontalFloatingToolbar({
					Theme = theme,
					Expanded = expanded,
					Colors = cfg.Colors,
					Modifier = D.Modifier.Frame():Position(UDim2.fromOffset(16, 16)),
					LeadingContent = {
						{ Icon = "edit", Label = "Bold", Checked = bold, OnCheckedChange = function(v: boolean)
							bold:Set(v)
						end },
					},
					Content = { a("check", "Done"), a("calendar", "Calendar") },
					TrailingContent = { a("close", "Close") },
				}),
				Material.HorizontalFloatingToolbar({
					Theme = theme,
					Expanded = expanded,
					Colors = cfg.Colors,
					Modifier = D.Modifier.Frame():Position(UDim2.fromOffset(16, 112)),
					Content = { a("check", "Done"), a("calendar", "Calendar"), a("edit", "Edit") },
					FloatingActionButton = { Icon = "edit", OnClick = did("FAB") },
					FloatingActionButtonPosition = if cfg.FabAtStart then "Start" else "End",
				}),
				Material.VerticalFloatingToolbar({
					Theme = theme,
					Expanded = expanded,
					Colors = cfg.Colors,
					Modifier = D.Modifier.Frame():AnchorPoint(Vector2.new(1, 0)):Position(UDim2.new(1, -112, 0, 16)),
					LeadingContent = { a("chevronLeft", "Back") },
					Content = { a("check", "Done"), a("edit", "Edit") },
					TrailingContent = { a("close", "Close") },
				}),
				Material.VerticalFloatingToolbar({
					Theme = theme,
					Expanded = expanded,
					Colors = cfg.Colors,
					Modifier = D.Modifier.Frame():AnchorPoint(Vector2.new(1, 0)):Position(UDim2.new(1, -16, 0, 16)),
					Content = { a("check", "Done"), a("edit", "Edit") },
					FloatingActionButton = { Icon = "edit", OnClick = did("FAB") },
					FloatingActionButtonPosition = if cfg.FabAtStart then "Top" else "Bottom",
				}),
			}
		end, { Size = UDim2.fromOffset(640, 400) })
		return StoryParts.page(theme, follow, {
			StoryParts.caption(theme, StoryParts.show<<string>>(last, "Last action = ", StoryParts.tostr)),
			screen,
		})
	end,
})
