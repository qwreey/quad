--!strict
--[[
	Gallery section "Surfaces": Elevation levels, Card (Elevated / Filled / Outlined, one interactive), Divider (plain,
	inset, vertical) and List (static rows of one / two / three lines with leading + trailing, selection, disabled; and a
	keyed `ListData` whose rows are added / removed from the buttons above it).
]]

local q = require("../Quad")
local Common = require("./Common")
local Text = require("../Text")
local Button = require("../Button")
local Card = require("../Card")
local Divider = require("../Divider")
local ListModule = require("../List")
local Elevation = require("../Elevation")
local D = q.Declaration

type Ctx = Common.Ctx
type Row = { Id: number, Title: string }

local bodyStyle = Text.Label("BodyMedium")
local titleStyle = Text.Label("TitleMedium")

local function cardWidth()
	return D.Modifier.GuiObject():Size(UDim2.fromOffset(240, 0)):AutomaticSize(Enum.AutomaticSize.Y)
end

local function cardBody(ctx: Ctx, title: string, body: string): { Instance }
	local theme = ctx.Theme
	return {
		D.TextLabel {
			Name = "Title",
			titleStyle,
			Size = UDim2.fromOffset(208, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = theme.Color.OnSurface,
			Text = title,
		},
		D.TextLabel {
			Name = "Body",
			bodyStyle,
			Size = UDim2.fromOffset(208, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = theme.Color.OnSurfaceVariant,
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
			D.Frame {
				Name = `Level{level}`,
				Size = UDim2.fromOffset(72, 56),
				BorderSizePixel = 0,
				BackgroundColor3 = theme.Color.SurfaceContainerLow,
				UICorner = UDim.new(0, 12),
				Elevation.Shadow({ Level = level, Theme = theme }),
				D.TextLabel {
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
		Card({
			Theme = theme,
			Variant = "Elevated",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			Children = q.Slot<<Instance>>(cardBody(ctx, "Elevated", "Surface container low with a level 1 shadow.")),
		}),
		Card({
			Theme = theme,
			Variant = "Filled",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			Children = q.Slot<<Instance>>(cardBody(ctx, "Filled", "Surface container highest, no shadow.")),
		}),
		Card({
			Theme = theme,
			Variant = "Outlined",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			Children = q.Slot<<Instance>>(cardBody(ctx, "Outlined", "Surface with a 1 px outline variant stroke.")),
		}),
		Card({
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
		Card({
			Theme = theme,
			Variant = "Elevated",
			Padding = 16,
			Gap = 4,
			Modifier = cardWidth(),
			Disabled = true,
			OnClick = function() end,
			Children = q.Slot<<Instance>>(cardBody(ctx, "Disabled", "An interactive card in its disabled look.")),
		}),
		Common.Caption(ctx, opened:Compute(function(self)
			return `Interactive card opened {self:Get()} times`
		end), false),
	}

	-- dividers
	local dividers: { Instance } = {
		Common.Column({
			Divider({ Theme = theme }),
			Divider({ Theme = theme, Inset = "Start" }),
			Divider({ Theme = theme, Inset = "Both" }),
			D.Frame {
				Name = "VerticalDemo",
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 16),
				},
				Common.Caption(ctx, "left", false),
				Divider({ Theme = theme, Orientation = "Vertical" }),
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
	local staticList = ListModule.List({
		Theme = theme,
		Children = q.Slot<<Instance>>({
			ListModule.ListItem({
				Theme = theme,
				Headline = "Inbox",
				Leading = ctx.Icon,
				TrailingText = "24",
				Selected = selected("inbox"),
				OnClick = pick("inbox"),
			}),
			ListModule.ListItem({
				Theme = theme,
				Headline = "Sent",
				Supporting = "Two lines: headline and supporting text",
				Leading = ctx.Icon,
				Selected = selected("sent"),
				OnClick = pick("sent"),
			}),
			Divider({ Theme = theme, Inset = "Start" }),
			ListModule.ListItem({
				Theme = theme,
				Overline = "Overline",
				Headline = "Drafts",
				Supporting = "Three lines: overline, headline and ONE supporting line (cut when long)",
				Leading = ctx.Icon,
				Selected = selected("drafts"),
				OnClick = pick("drafts"),
			}),
			ListModule.ListItem({
				Theme = theme,
				Headline = "Archive",
				Supporting = "Three lines without an overline: the supporting text may take a second line when it is long",
				Lines = 3,
				Leading = ctx.Icon,
				Selected = selected("archive"),
				OnClick = pick("archive"),
			}),
			ListModule.ListItem({ Theme = theme, Headline = "Trash (disabled)", Leading = ctx.Icon, Disabled = true, OnClick = pick("trash") }),
			ListModule.ListItem({ Theme = theme, Headline = "Static row (no click)", Supporting = "No state layer is built" }),
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
	local dataList = ListModule.ListData<<Row>>({
		Theme = theme,
		Items = rows,
		Key = function(r: Row)
			return r.Id
		end,
		Render = function(row: q.State<Row>, index: q.State<number>)
			return ListModule.ListItem({
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
		Button({
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
		Button({
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

	return Common.Section(ctx, "Surfaces", "Surfaces", {
		Common.Group(ctx, "Elevation", levels, "A UIShadow per level; it follows the UICorner."),
		Common.Group(ctx, "Card", cards),
		Common.Group(ctx, "Divider", dividers),
		Common.Group(ctx, "List: static rows", { Common.Column({ staticList }, 360) }),
		Common.Group(ctx, "ListData: keyed rows", {
			Common.Column({ dataButtons, dataList }, 360, 8),
		}, "Rows are built once per key; reversing re-orders through LayoutOrder only."),
	})
end
