--!strict
--[[
	Gallery section "Surfaces": Elevation levels, Card (Elevated / Filled / Outlined, one interactive, the three variants
	disabled — the kit colors the container / outline / shadow, the gallery dims its own text to 38 %), Divider (plain,
	inset, vertical) and List (static rows of one / two / three lines with leading + trailing, selection, disabled; a
	keyed `ListData` whose rows are added / removed from the buttons above it; and a drag-to-reorder `ListData` — rows of
	two heights, the owner applies each move at once, after a pretend 2 s server round trip (`Reordering` keeps the rows
	waiting), or not at all; `Render` passes its `dragged` State to `ListItem`'s `Dragged`).
]]

local q = require("./Quad")
local Common = require("./Common")
local Material = require("../src")
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local UIListLayout = q.Elem "UIListLayout"
local GuiObjectModifier = q.Modifier "GuiObject"

type Ctx = Common.Ctx
type Row = { Id: number, Title: string }
type Track = { Id: number, Title: string, Artist: string? }

local bodyStyle = Material.Text.Label("BodyMedium")
local titleStyle = Material.Text.Label("TitleMedium")

local function cardWidth()
	return GuiObjectModifier():Size(UDim2.fromOffset(240, 0)):AutomaticSize(Enum.AutomaticSize.Y)
end

-- `dim`: the content of a DISABLED card. The Card colors its container, outline and shadow; its children are the
-- caller's, so the caller dims them (M3: content at 38 %).
local function cardBody(ctx: Ctx, title: string, body: string, dim: boolean?): { Instance }
	local theme = ctx.Theme
	local textTransparency = if dim then 1 - Material.Tokens.State.Opacity.DisabledContent else 0
	return {
		TextLabel {
			Name = "Title",
			titleStyle,
			Size = UDim2.fromOffset(208, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = theme.Color.OnSurface,
			TextTransparency = textTransparency,
			Text = title,
		},
		TextLabel {
			Name = "Body",
			bodyStyle,
			Size = UDim2.fromOffset(208, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = theme.Color.OnSurfaceVariant,
			TextTransparency = textTransparency,
			Text = body,
		},
	}
end

return function(ctx: Ctx): Instance
	local theme = ctx.Theme

	-- elevation
	local levels: { Instance } = {}
	for level = 0, 5 do
		table.insert(
			levels,
			Frame {
				Name = `Level{level}`,
				Size = UDim2.fromOffset(72, 56),
				BorderSizePixel = 0,
				BackgroundColor3 = theme.Color.SurfaceContainerLow,
				UICorner = UDim.new(0, 12),
				Material.Elevation.Shadow({ Level = level, Theme = theme }),
				TextLabel {
					bodyStyle,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					TextColor3 = theme.Color.OnSurface,
					Text = `Level {level}`,
				},
			}
		)
	end

	-- cards
	local opened = ctx.Memo("surf.opened", function()
		return q.Source(0)
	end)
	local cards: { Instance } = {
		Material.Card({
			Theme = theme,
			Variant = "Elevated",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			Children = q.Slot<<Instance>>(cardBody(ctx, "Elevated", "Surface container low with a level 1 shadow.")),
		}),
		Material.Card({
			Theme = theme,
			Variant = "Filled",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			Children = q.Slot<<Instance>>(cardBody(ctx, "Filled", "Surface container highest, no shadow.")),
		}),
		Material.Card({
			Theme = theme,
			Variant = "Outlined",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			Children = q.Slot<<Instance>>(cardBody(ctx, "Outlined", "Surface with a 1 px outline variant stroke.")),
		}),
		Material.Card({
			Theme = theme,
			Variant = "Filled",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			OnClick = function()
				opened:Set(opened:Get() + 1)
			end,
			Children = q.Slot<<Instance>>(cardBody(ctx, "Interactive", "State layer, ripple and focus ring. Click me.")),
		}),
		Material.Card({
			Theme = theme,
			Variant = "Elevated",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			Disabled = true,
			OnClick = function() end,
			Children = q.Slot<<Instance>>(cardBody(ctx, "Disabled (Elevated)", "Surface, the level 1 shadow stays.", true)),
		}),
		Material.Card({
			Theme = theme,
			Variant = "Filled",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			Disabled = true,
			OnClick = function() end,
			Children = q.Slot<<Instance>>(cardBody(ctx, "Disabled (Filled)", "Surface variant at 38 % over the container.", true)),
		}),
		Material.Card({
			Theme = theme,
			Variant = "Outlined",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			Disabled = true,
			OnClick = function() end,
			Children = q.Slot<<Instance>>(cardBody(ctx, "Disabled (Outlined)", "Surface, the outline at 12 %.", true)),
		}),
		Common.Caption(ctx, opened:Compute(function(self)
			return `Interactive card opened {self:Get()} times`
		end), false),
	}

	-- dividers
	local dividers: { Instance } = {
		Common.Column({
			Material.Divider({ Theme = theme }),
			Material.Divider({ Theme = theme, Inset = "Start" }),
			Material.Divider({ Theme = theme, Inset = "Both" }),
			Frame {
				Name = "VerticalDemo",
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 16),
				},
				Common.Caption(ctx, "left", false),
				Material.Divider({ Theme = theme, Orientation = "Vertical" }),
				Common.Caption(ctx, "right", false),
			},
		}, 280, 12),
	}

	-- static list
	local picked = ctx.Memo("surf.picked", function()
		return q.Source("inbox")
	end)
	local function pick(key: string): () -> ()
		return function()
			picked:Set(key)
		end
	end
	local function selected(key: string): q.State<boolean>
		return picked:Compute(function(self)
			return self:Get() == key
		end)
	end
	local staticList = Material.List({
		Theme = theme,
		Children = q.Slot<<Instance>>({
			Material.ListItem({
				Theme = theme,
				Headline = "Inbox",
				Leading = ctx.Icon,
				TrailingText = "24",
				Selected = selected("inbox"),
				OnClick = pick("inbox"),
			}),
			Material.ListItem({
				Theme = theme,
				Headline = "Sent",
				Supporting = "Two lines: headline and supporting text",
				Leading = ctx.Icon,
				Selected = selected("sent"),
				OnClick = pick("sent"),
			}),
			Material.Divider({ Theme = theme, Inset = "Start" }),
			Material.ListItem({
				Theme = theme,
				Overline = "Overline",
				Headline = "Drafts",
				Supporting = "Three lines: overline, headline and ONE supporting line (cut when long)",
				Leading = ctx.Icon,
				Selected = selected("drafts"),
				OnClick = pick("drafts"),
			}),
			Material.ListItem({
				Theme = theme,
				Headline = "Archive",
				Supporting = "Three lines without an overline: the supporting text may take a second line when it is long",
				Lines = 3,
				Leading = ctx.Icon,
				Selected = selected("archive"),
				OnClick = pick("archive"),
			}),
			Material.ListItem({ Theme = theme, Headline = "Trash (disabled)", Leading = ctx.Icon, Disabled = true, OnClick = pick("trash") }),
			Material.ListItem({ Theme = theme, Headline = "Static row (no click)", Supporting = "No state layer is built" }),
		}),
	})

	-- keyed data list
	local nextId = ctx.Memo("surf.nextId", function()
		return { value = 3 }
	end)
	local rows = ctx.Memo("surf.rows", function()
		return q.Source<<{ Row }>>({
			{ Id = 1, Title = "Row one" },
			{ Id = 2, Title = "Row two" },
			{ Id = 3, Title = "Row three" },
		})
	end)
	local dataList = Material.ListData<<Row>>({
		Theme = theme,
		Items = rows,
		Key = function(r: Row)
			return r.Id
		end,
		Render = function(row: q.State<Row>, index: q.State<number>)
			return Material.ListItem({
				Theme = theme,
				Headline = Common.text<<Row>>(row, function(r: Row)
					return r.Title
				end),
				Supporting = Common.text<<number>>(index, function(i: number)
					return `Position {i}; click to remove`
				end),
				LayoutOrder = index,
				OnClick = function()
					local id = row:Get().Id
					local keep: { Row } = {}
					for _, r in rows:Get() do
						if r.Id ~= id then
							table.insert(keep, r)
						end
					end
					rows:Set(keep)
				end,
			})
		end,
	})
	local dataButtons = Common.Flow({
		Material.Button({
			Theme = theme,
			Variant = "Tonal",
			Label = "Add row",
			OnClick = function()
				nextId.value += 1
				local copy = table.clone(rows:Get())
				table.insert(copy, { Id = nextId.value, Title = `Row {nextId.value}` })
				rows:Set(copy)
			end,
		}),
		Material.Button({
			Theme = theme,
			Variant = "Text",
			Label = "Reverse",
			OnClick = function()
				local old = rows:Get()
				local copy: { Row } = {}
				for i = #old, 1, -1 do
					table.insert(copy, old[i])
				end
				rows:Set(copy)
			end,
		}),
	})

	-- drag to reorder: the list only calls back; this owner moves the row — at once, late (a server round trip, during
	-- which `Reordering` is true and the dropped rows wait) or never
	local tracks = ctx.Memo("surf.tracks", function()
		return q.Source<<{ Track }>>({
			{ Id = 1, Title = "Opening", Artist = "Two lines: drag the handle at the end" },
			{ Id = 2, Title = "Interlude" },
			{ Id = 3, Title = "Main theme", Artist = "Rows of different heights give way by the dragged row's height" },
			{ Id = 4, Title = "Bridge" },
			{ Id = 5, Title = "Finale", Artist = "Escape cancels a drag" },
		})
	end)
	local serverDelay = ctx.Memo("surf.reorderDelay", function()
		return q.Source(false)
	end)
	local serverRefuses = ctx.Memo("surf.reorderRefuse", function()
		return q.Source(false)
	end)
	local lastMove = ctx.Memo("surf.reorderLast", function()
		return q.Source("No move yet")
	end)
	local awaiting = ctx.Memo("surf.reorderAwaiting", function()
		return q.Source(false)
	end)
	local reorderList = Material.ListData<<Track>>({
		Theme = theme,
		Items = tracks,
		Key = function(t: Track)
			return t.Id
		end,
		Reordering = awaiting,
		Render = function(track: q.State<Track>, index: q.State<number>, dragged: q.State<boolean>)
			return Material.ListItem({
				Theme = theme,
				Dragged = dragged, -- the lifted row's content takes the dragged colors
				Leading = ctx.Icon,
				Headline = Common.text<<Track>>(track, function(t: Track)
					return t.Title
				end),
				-- two-line or one-line is decided when the row is built (rows are keyed by Id, so the item never changes kind)
				Supporting = if track:Get().Artist ~= nil
					then Common.text<<Track>>(track, function(t: Track)
						return t.Artist or ""
					end)
					else nil,
				TrailingText = Common.text<<number>>(index, function(i: number)
					return `#{i}`
				end),
			})
		end,
		OnReorder = function(from: number, to: number)
			local function apply()
				local copy = table.clone(tracks:Get())
				if copy[from] ~= nil and to <= #copy then
					table.insert(copy, to, table.remove(copy, from) :: Track)
					tracks:Set(copy)
				end
			end
			local refused = serverRefuses:Get()
			if serverDelay:Get() then
				-- the server flow: `Reordering` is true until the answer, the rows wait where they were dropped
				lastMove:Set(`OnReorder({from}, {to}) sent: waiting for the server (2 s)`)
				awaiting:Set(true)
				task.delay(2, function()
					if refused then
						lastMove:Set(`OnReorder({from}, {to}): the server refused, the rows go back`)
					else
						lastMove:Set(`OnReorder({from}, {to}) applied by the server after 2 s`)
						apply()
					end
					awaiting:Set(false)
				end)
			elseif refused then
				lastMove:Set(`OnReorder({from}, {to}) refused: the rows go back after 1 s`)
			else
				lastMove:Set(`OnReorder({from}, {to}) applied at once`)
				apply()
			end
		end,
	})
	local reorderControls = Common.Flow({
		Common.Labeled(ctx, Material.Switch({ Theme = theme, Value = serverDelay }), "Server delay 2 s"),
		Common.Labeled(ctx, Material.Switch({ Theme = theme, Value = serverRefuses }), "Server refuses"),
	})

	return Common.Section(ctx, "Surfaces", "Surfaces", {
		Common.Group(ctx, "Elevation", levels, "A UIShadow per level; it follows the UICorner."),
		Common.Group(ctx, "Card", cards),
		Common.Group(ctx, "Divider", dividers),
		Common.Group(ctx, "List: static rows", { Common.Column({ staticList }, 360) }),
		Common.Group(ctx, "ListData: keyed rows", {
			Common.Column({ dataButtons, dataList }, 360, 8),
		}, "Rows are built once per key; reversing re-orders through LayoutOrder only."),
		Common.Group(ctx, "ListData: drag to reorder", {
			Common.Column({ reorderControls, Common.Caption(ctx, lastMove), reorderList }, 360, 8),
		}, "OnReorder(from, to) is all the list does; the owner edits Items (Reordering = waiting for the server). Engage a handle with Enter / A, then Up / Down."),
	})
end
