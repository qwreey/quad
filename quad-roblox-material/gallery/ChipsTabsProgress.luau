--!strict
--[[
	Gallery section "Chips, tabs, progress": the four chips (a Filter set bound to Sources, an Input chip set that removes
	itself from a keyed list, Assist / Suggestion), Primary and Secondary Tabs (a nested page switch — these are plain
	Tabs, unrelated to the gallery's own), and linear / wavy / circular progress (determinate driven by a Slider-like pair
	of buttons, indeterminate — with the M3 Expressive loading indicator — under a Visible toggle that also stops the
	Heartbeat loops).
]]

local q = require("./Quad")
local Common = require("./Common")
local Material = require("../src")

type Ctx = Common.Ctx
type Tag = { Id: number, Name: string }

return function(ctx: Ctx): Instance
	local theme = ctx.Theme

	-- chips
	local onSale = ctx.Memo("chip.sale", function()
		return q.Source(true)
	end)
	local inStock = ctx.Memo("chip.stock", function()
		return q.Source(false)
	end)
	local picked = ctx.Memo("chip.picked", function()
		return q.Source("(none)")
	end)
	local tags = ctx.Memo("chip.tags", function()
		return q.Source<<{ Tag }>>({
			{ Id = 1, Name = "ada@example.com" },
			{ Id = 2, Name = "grace@example.com" },
			{ Id = 3, Name = "linus@example.com" },
		})
	end)
	local function removeTag(id: number)
		local keep: { Tag } = {}
		for _, t in tags:Get() do
			if t.Id ~= id then
				table.insert(keep, t)
			end
		end
		tags:Set(keep)
	end
	local saleText: q.State<string> = onSale:Compute(function(self, _prev, stock)
		return `On sale: {self:Get()}, in stock: {stock:Get()}`
	end, inStock)
	local assist: { Instance } = {
		Material.Chip.Assist({ Theme = theme, Label = "Directions", Icon = ctx.Icon, OnClick = function() picked:Set("directions") end }),
		Material.Chip.Assist({ Theme = theme, Label = "Elevated", Elevated = true, OnClick = function() picked:Set("elevated") end }),
		Material.Chip.Assist({ Theme = theme, Label = "Disabled", Disabled = true }),
		Material.Chip.Suggestion({ Theme = theme, Label = "Cheap flights", OnClick = function() picked:Set("cheap flights") end }),
		Material.Chip.Suggestion({ Theme = theme, Label = "Elevated suggestion", Elevated = true, OnClick = function() picked:Set("suggestion") end }),
		Common.Caption(ctx, picked:Compute(function(self)
			return `Last chip: {self:Get()}`
		end), false),
	}
	local filters: { Instance } = {
		Material.Chip.Filter({ Theme = theme, Label = "On sale", Selected = onSale }),
		Material.Chip.Filter({ Theme = theme, Label = "In stock", Selected = inStock }),
		Material.Chip.Filter({ Theme = theme, Label = "Elevated", Selected = q.Source(false), Elevated = true }),
		Material.Chip.Filter({ Theme = theme, Label = "Disabled", Selected = q.Source(true), Disabled = true }),
		Common.Caption(ctx, saleText, false),
	}
	local inputs: { Instance } = {
		Material.Chip.ChipSet<<Tag>>({
			Items = tags,
			Key = function(t: Tag)
				return t.Id
			end,
			Render = function(tag: q.State<Tag>, order: q.State<number>)
				return Material.Chip.Input({
					Theme = theme,
					Label = Common.text<<Tag>>(tag, function(t: Tag)
						return t.Name
					end),
					Modifier = q.Modifier "TextButton"():LayoutOrder(order),
					OnRemove = function()
						removeTag(tag:Get().Id)
					end,
				})
			end,
		}),
	}

	-- tabs
	local primary = ctx.Memo("tabs.primary", function()
		return q.Source("flights")
	end)
	local secondary = ctx.Memo("tabs.secondary", function()
		return q.Source("a")
	end)
	local primaryTabs: { Material.Tab<string> } = {
		{ Key = "flights", Label = "Flights" },
		{ Key = "trips", Label = "Trips" },
		{ Key = "explore", Label = "Explore" },
	}
	local secondaryTabs: { Material.Tab<string> } = {
		{ Key = "a", Label = "First" },
		{ Key = "b", Label = "Second" },
		{ Key = "c", Label = "Third" },
		{ Key = "d", Label = "Fourth" },
	}
	local tabsPrimary: { Instance } = {
		Common.Column({
			Material.Tabs<<string>>({
				Theme = theme,
				Selected = primary,
				Tabs = primaryTabs,
			}),
			Common.Caption(ctx, Common.text<<string>>(primary, function(key: string)
				return `Selected: {key}`
			end), false),
			Material.Tabs<<string>>({
				Theme = theme,
				Variant = "Secondary",
				Selected = secondary,
				Tabs = secondaryTabs,
			}),
		}, 360, 8),
	}

	-- progress
	local value = ctx.Memo("prog.value", function()
		return q.Source(0.35)
	end)
	local busy = ctx.Memo("prog.busy", function()
		return q.Source(true)
	end)
	local function bump(d: number): () -> ()
		return function()
			value:Set(math.clamp(value:Get() + d, 0, 1))
		end
	end
	local determinate: { Instance } = {
		Common.Column({
			Material.LinearProgress({ Theme = theme, Value = value }),
			Material.WavyProgress({ Theme = theme, Value = value, Visible = busy }),
			-- the four strokes of the arc sheet (Thickness / Size = 0.05, 0.10 (M3 default), 0.15, 0.20)
			Common.Flow({
				Material.CircularProgress({ Theme = theme, Value = value, Thickness = 2 }),
				Material.CircularProgress({ Theme = theme, Value = value }),
				Material.CircularProgress({ Theme = theme, Value = value, Thickness = 6 }),
				Material.CircularProgress({ Theme = theme, Value = value, Thickness = 8 }),
			}),
			Common.Flow({
				Material.Button({ Theme = theme, Variant = "Tonal", Label = "-10 %", OnClick = bump(-0.1) }),
				Material.Button({ Theme = theme, Variant = "Tonal", Label = "+10 %", OnClick = bump(0.1) }),
				Common.Caption(ctx, Common.text<<number>>(value, function(v: number)
					return string.format("%d %%", math.floor(v * 100 + 0.5))
				end), false),
			}),
		}, 360, 12),
	}
	local indeterminate: { Instance } = {
		Common.Column({
			Common.Labeled(ctx, Material.Switch({ Theme = theme, Value = busy }), "Busy (Visible)"),
			Material.LinearProgress({ Theme = theme, Visible = busy }),
			Common.Flow({
				Material.CircularProgress({ Theme = theme, Visible = busy }),
				Material.LoadingIndicator({ Theme = theme, Visible = busy }),
				Material.LoadingIndicator({ Theme = theme, Visible = busy, Contained = true }),
			}),
		}, 360, 12),
	}

	return Common.Section(ctx, "ChipsTabsProgress", "Chips, tabs and progress", {
		Common.Group(ctx, "Chip: assist and suggestion", assist),
		Common.Group(ctx, "Chip: filter", filters),
		Common.Group(ctx, "Chip: input (ChipSet)", inputs, "Remove a chip with its x; the keyed set rebuilds nothing else."),
		Common.Group(ctx, "Tabs: Primary and Secondary", tabsPrimary),
		Common.Group(ctx, "Progress: determinate", determinate, "Flat bar, wavy bar (M3 Expressive — its wave travels while Busy is on), rings in the four strokes (2 / 4 / 6 / 8 px at 40)."),
		Common.Group(
			ctx,
			"Progress: indeterminate",
			indeterminate,
			"Bar, ring, and the M3 Expressive loading indicator (plain and contained). Turning Busy off disconnects every loop."
		),
	})
end
