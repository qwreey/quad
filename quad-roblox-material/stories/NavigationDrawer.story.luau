--!strict
-- Navigation drawer: a ModalNavigationDrawer in a clipped mock screen with a NavigationDrawerItems list (headline,
-- destinations with icons and a badge, a divider). Count / Kind are construction-time, so the drawer is rebuilt when they
-- change; the selected destination is one Source shown live, Open / Close drive the DrawerState.
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local Frame = q.Elem "Frame"
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

type Config = { Count: number, Kind: string, Gestures: boolean }

return StoryKit.story({
	controls = {
		Destinations = StoryKit.Slider(6, 1, 24, 1),
		Kind = StoryKit.Choose({ "Modal", "Dismissible", "Permanent" }),
		GesturesEnabled = true,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local page = q.Source<<string>>("dest1")
		local state: Material.DrawerState? = nil

		local config: q.State<Config> = c.Destinations:Compute(function(self: q.StateData<any>, _prev: Config?, kind: q.State<any>, gestures: q.State<any>): Config
			return { Count = self:Get(), Kind = kind:Get(), Gestures = gestures:Get() == true }
		end, c.Kind, c.GesturesEnabled)

		local drawer = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			local items: { Material.NavigationDrawerEntry<string> } = { { Headline = "Destinations" } }
			for i = 1, cfg.Count do
				table.insert(items, { Key = `dest{i}`, Label = `Destination {i}`, Icon = "check", Badge = if i == 1 then "3" else nil })
			end
			local divider: Material.NavigationDrawerEntry<string> = "divider"
			table.insert(items, divider)
			table.insert(items, { Key = "settings", Label = "Settings" })
			local list = Material.NavigationDrawerItems<<string>>({ Theme = theme, Items = items, Selected = page })
			local content = q.Slot<<Instance>>({ StoryParts.caption(theme, StoryParts.show<<string>>(page, "Page: ", StoryParts.tostr)) })
			local s = Material.DrawerState({ InitialValue = "Closed" })
			state = s
			local layout: Instance
			if cfg.Kind == "Modal" then
				layout = Material.ModalNavigationDrawer({
					Theme = theme,
					DrawerState = s,
					GesturesEnabled = cfg.Gestures,
					DrawerContent = Material.ModalDrawerSheet({ Theme = theme, Children = q.Slot<<Instance>>({ list }) }),
					Content = content,
				})
			elseif cfg.Kind == "Dismissible" then
				layout = Material.DismissibleNavigationDrawer({
					Theme = theme,
					DrawerState = s,
					GesturesEnabled = cfg.Gestures,
					DrawerContent = Material.DismissibleDrawerSheet({ Theme = theme, Children = q.Slot<<Instance>>({ list }) }),
					Content = content,
				})
			else
				layout = Material.PermanentNavigationDrawer({
					Theme = theme,
					DrawerContent = Material.PermanentDrawerSheet({ Theme = theme, Children = q.Slot<<Instance>>({ list }) }),
					Content = content,
				})
			end
			return Frame {
				Name = "Screen",
				Size = UDim2.fromOffset(640, 440),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
				layout,
			}
		end, { Size = UDim2.fromOffset(640, 440) })

		return StoryParts.scrollPage(theme, follow, {
			StoryParts.row({
				Material.Button({
					Theme = theme,
					Label = "Open",
					OnClick = function()
						local s = state
						if s then
							s.Open()
						end
					end,
				}),
				Material.Button({
					Theme = theme,
					Variant = "Outlined",
					Label = "Close",
					OnClick = function()
						local s = state
						if s then
							s.Close()
						end
					end,
				}),
			}),
			drawer,
		})
	end,
})
