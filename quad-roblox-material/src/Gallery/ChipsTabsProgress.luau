--!strict
--[[
	Gallery section "Chips, tabs, progress": the four chips (a Filter set bound to Sources, an Input chip set that removes
	itself from a keyed list, Assist / Suggestion), Primary and Secondary Tabs (a nested page switch — these are plain
	Tabs, unrelated to the gallery's own), and linear / circular progress (determinate driven by a Slider-like pair of
	buttons, indeterminate with a Visible toggle that also stops the Heartbeat loop).
]]

local q = require("../Quad")
local Common = require("./Common")
local Chip = require("../Chip")
local Tabs = require("../Tabs")
local Progress = require("../Progress")
local Button = require("../Button")
local Switch = require("../Switch")

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
		Chip.Assist({ Theme = theme, Label = "Directions", Icon = ctx.Icon, OnClick = function() picked:Set("directions") end }),
		Chip.Assist({ Theme = theme, Label = "Elevated", Elevated = true, OnClick = function() picked:Set("elevated") end }),
		Chip.Assist({ Theme = theme, Label = "Disabled", Disabled = true }),
		Chip.Suggestion({ Theme = theme, Label = "Cheap flights", OnClick = function() picked:Set("cheap flights") end }),
		Chip.Suggestion({ Theme = theme, Label = "Elevated suggestion", Elevated = true, OnClick = function() picked:Set("suggestion") end }),
		Common.Caption(ctx, picked:Compute(function(self)
			return `Last chip: {self:Get()}`
		end), false),
	}
	local filters: { Instance } = {
		Chip.Filter({ Theme = theme, Label = "On sale", Selected = onSale }),
		Chip.Filter({ Theme = theme, Label = "In stock", Selected = inStock }),
		Chip.Filter({ Theme = theme, Label = "Elevated", Selected = q.Source(false), Elevated = true }),
		Chip.Filter({ Theme = theme, Label = "Disabled", Selected = q.Source(true), Disabled = true }),
		Common.Caption(ctx, saleText, false),
	}
	local inputs: { Instance } = {
		Chip.ChipSet<<Tag>>({
			Items = tags,
			Key = function(t: Tag)
				return t.Id
			end,
			Render = function(tag: q.State<Tag>, order: q.State<number>)
				return Chip.Input({
					Theme = theme,
					Label = Common.text<<Tag>>(tag, function(t: Tag)
						return t.Name
					end),
					Modifier = q.Declaration.Modifier.TextButton():LayoutOrder(order),
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
	local primaryTabs: { Tabs.Tab<string> } = {
		{ Key = "flights", Label = "Flights" },
		{ Key = "trips", Label = "Trips" },
		{ Key = "explore", Label = "Explore" },
	}
	local secondaryTabs: { Tabs.Tab<string> } = {
		{ Key = "a", Label = "First" },
		{ Key = "b", Label = "Second" },
		{ Key = "c", Label = "Third" },
		{ Key = "d", Label = "Fourth" },
	}
	local tabsPrimary: { Instance } = {
		Common.Column({
			Tabs<<string>>({
				Theme = theme,
				Selected = primary,
				Tabs = primaryTabs,
			}),
			Common.Caption(ctx, Common.text<<string>>(primary, function(key: string)
				return `Selected: {key}`
			end), false),
			Tabs<<string>>({
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
			Progress.LinearProgress({ Theme = theme, Value = value }),
			Common.Flow({
				Progress.CircularProgress({ Theme = theme, Value = value }),
				Progress.CircularProgress({ Theme = theme, Value = value, Size = 24, Thickness = 3 }),
				Button({ Theme = theme, Variant = "Tonal", Label = "-10 %", OnClick = bump(-0.1) }),
				Button({ Theme = theme, Variant = "Tonal", Label = "+10 %", OnClick = bump(0.1) }),
				Common.Caption(ctx, Common.text<<number>>(value, function(v: number)
					return string.format("%d %%", math.floor(v * 100 + 0.5))
				end), false),
			}),
		}, 360, 12),
	}
	local indeterminate: { Instance } = {
		Common.Column({
			Common.Labeled(ctx, Switch({ Theme = theme, Value = busy }), "Busy (Visible)"),
			Progress.LinearProgress({ Theme = theme, Visible = busy }),
			Progress.CircularProgress({ Theme = theme, Visible = busy }),
		}, 360, 12),
	}

	return Common.Section(ctx, "ChipsTabsProgress", "Chips, tabs and progress", {
		Common.Group(ctx, "Chip: assist and suggestion", assist),
		Common.Group(ctx, "Chip: filter", filters),
		Common.Group(ctx, "Chip: input (ChipSet)", inputs, "Remove a chip with its x; the keyed set rebuilds nothing else."),
		Common.Group(ctx, "Tabs: Primary and Secondary", tabsPrimary),
		Common.Group(ctx, "Progress: determinate", determinate),
		Common.Group(ctx, "Progress: indeterminate", indeterminate, "Turning Busy off disconnects the Heartbeat loop of both."),
	})
end
