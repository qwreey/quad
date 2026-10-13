--!strict
-- List: one ListItem whose texts / Selected / Disabled are Sources (Lines and Clickable are construction-time, so they
-- rebuild the item), a static List with dividers, a keyed ListData over a Source<{Item}> with add / remove buttons, and a
-- drag-to-reorder ListData (`OnReorder`): the story moves the row itself, at once or 2 s later (`ReorderDelay` — the
-- rows wait for that answer because `Reordering` is true meanwhile); the lifted row's content takes the dragged colors
-- (`Render`'s third argument -> `ListItem`'s `Dragged`).
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local D = q.Declaration
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

type Item = { Id: number, Name: string }
type Config = { Lines: number, Clickable: boolean }

local function avatar(theme: Material.Theme): Frame
	return D.Frame {
		Name = "Avatar",
		Size = UDim2.fromOffset(40, 40),
		BorderSizePixel = 0,
		BackgroundColor3 = theme.Color.PrimaryContainer,
		UICorner = UDim.new(0.5, 0),
	}
end

local function header(theme: Material.Theme, text: string, order: number): TextLabel
	return D.TextLabel {
		Material.Text.Label("LabelLarge"),
		LayoutOrder = order,
		Size = UDim2.fromOffset(360, 20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = theme.Color.Primary,
		Text = text,
	}
end

return StoryKit.story({
	controls = {
		Headline = "Inbox",
		Supporting = "Two lines: headline and supporting text",
		Overline = "Overline",
		Lines = StoryKit.Choose({ "1", "2", "3" }, 2),
		Clickable = true,
		Selected = false,
		Disabled = false,
		ReorderDelay = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local picked = q.Source("(nothing)")
		local nextId = 4
		local items = q.Source<<{ Item }>>({
			{ Id = 1, Name = "Alpha" },
			{ Id = 2, Name = "Beta" },
			{ Id = 3, Name = "Gamma" },
		})

		local config: q.State<Config> = c.Lines:Compute(function(self: q.StateData<any>, _prev: Config?, clickable: q.State<any>): Config
			return { Lines = tonumber(self:Get()) or 1, Clickable = clickable:Get() == true }
		end, c.Clickable)

		local single = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			return Material.ListItem({
				Theme = theme,
				Headline = c.Headline,
				Supporting = if cfg.Lines >= 2 then c.Supporting else nil,
				Overline = if cfg.Lines >= 3 then c.Overline else nil,
				Lines = cfg.Lines,
				Leading = avatar(theme),
				TrailingText = "12:30",
				Selected = c.Selected,
				Disabled = c.Disabled,
				OnClick = if cfg.Clickable
					then function()
						picked:Set("single item")
					end
					else nil,
			})
		end, { Size = UDim2.fromOffset(360, 88), AutomaticSize = Enum.AutomaticSize.None, LayoutOrder = 2 })

		local static = Material.List({
			Theme = theme,
			Modifier = D.Modifier.Frame():Size(UDim2.fromOffset(360, 0)),
			LayoutOrder = 4,
			Children = q.Slot<<Instance>>({
				Material.ListItem({
					Theme = theme,
					Headline = "Static one",
					OnClick = function()
						picked:Set("static one")
					end,
				}),
				Material.Divider({ Theme = theme, Inset = "Start" }),
				Material.ListItem({
					Theme = theme,
					Headline = "Static two",
					Supporting = "Selected follows the last click",
					Selected = picked:Compute(function(self: q.StateData<string>): boolean
						return self:Get() == "static two"
					end),
					OnClick = function()
						picked:Set("static two")
					end,
				}),
			}),
		})

		local data = Material.ListData<<Item>>({
			Theme = theme,
			Items = items,
			Key = function(item: Item)
				return item.Id
			end,
			Render = function(item: q.State<Item>, index: q.State<number>)
				return Material.ListItem({
					Theme = theme,
					Headline = item:Compute(function(self: q.StateData<Item>): string
						return self:Get().Name
					end),
					TrailingText = index:Compute(function(self: q.StateData<number>): string
						return `#{self:Get()}`
					end),
					LayoutOrder = index,
					OnClick = function()
						picked:Set(item:Get().Name)
					end,
				})
			end,
			Modifier = D.Modifier.Frame():Size(UDim2.fromOffset(360, 0)),
		})

		local tracks = q.Source<<{ Item }>>({
			{ Id = 1, Name = "Drag my handle" },
			{ Id = 2, Name = "Second" },
			{ Id = 3, Name = "Third" },
			{ Id = 4, Name = "Fourth" },
		})
		local awaiting = q.Source(false)
		local reorder = Material.ListData<<Item>>({
			Theme = theme,
			Items = tracks,
			Reordering = awaiting,
			Key = function(item: Item)
				return item.Id
			end,
			Render = function(item: q.State<Item>, index: q.State<number>, dragged: q.State<boolean>)
				return Material.ListItem({
					Theme = theme,
					Dragged = dragged,
					Headline = item:Compute(function(self: q.StateData<Item>): string
						return self:Get().Name
					end),
					TrailingText = index:Compute(function(self: q.StateData<number>): string
						return `#{self:Get()}`
					end),
				})
			end,
			OnReorder = function(from: number, to: number)
				local function apply()
					local list = table.clone(tracks:Get())
					table.insert(list, to, table.remove(list, from) :: Item)
					tracks:Set(list)
				end
				picked:Set(`OnReorder({from}, {to})`)
				if c.ReorderDelay:Get() == true then
					awaiting:Set(true)
					task.delay(2, function()
						apply()
						awaiting:Set(false)
					end)
				else
					apply()
				end
			end,
			Modifier = D.Modifier.Frame():Size(UDim2.fromOffset(360, 0)),
		})

		return D.Frame {
			follow,
			Name = "ListStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Surface,
			UIPaddingOffset = 24,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) },
			header(theme, "ListItem (controls)", 1),
			single,
			header(theme, "List (static children + divider)", 3),
			static,
			header(theme, "ListData (keyed)", 5),
			D.Frame {
				Name = "DataButtons",
				LayoutOrder = 6,
				Size = UDim2.fromOffset(360, 40),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
				},
				Material.Button({
					Theme = theme,
					Variant = "Tonal",
					Label = "Add",
					LayoutOrder = 1,
					OnClick = function()
						local list = table.clone(items:Get())
						table.insert(list, { Id = nextId, Name = `Item {nextId}` })
						nextId += 1
						items:Set(list)
					end,
				}),
				Material.Button({
					Theme = theme,
					Variant = "Outlined",
					Label = "Remove first",
					LayoutOrder = 2,
					OnClick = function()
						local list = table.clone(items:Get())
						table.remove(list, 1)
						items:Set(list)
					end,
				}),
			},
			D.Frame {
				Name = "DataHost",
				LayoutOrder = 7,
				Size = UDim2.fromOffset(360, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				data,
			},
			D.TextLabel {
				Material.Text.Label("LabelMedium"),
				Name = "Picked",
				LayoutOrder = 8,
				Size = UDim2.fromOffset(360, 20),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = theme.Color.OnSurfaceVariant,
				Text = picked:Compute(function(self: q.StateData<string>): string
					return `Last clicked: {self:Get()}`
				end),
			},
			header(theme, "ListData (drag to reorder: OnReorder)", 9),
			D.Frame {
				Name = "ReorderHost",
				LayoutOrder = 10,
				Size = UDim2.fromOffset(360, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				reorder,
			},
		}
	end,
})
