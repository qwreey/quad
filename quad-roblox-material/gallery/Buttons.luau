--!strict
--[[
	Gallery section "Buttons": Button (five variants, icon, disabled, leading / trailing icons from `Icons` names), the
	split button (four variants, a menu on the trailing half, disabled), the connected button group (single and multiple
	selection, four variants, a disabled cell, a shared fixed width), IconButton (four variants + a toggle), FAB
	(sizes, colors, extended). A Switch in the first group drives the `Disabled` State of every button below it, so the disabled
	look of each variant can be compared with its enabled twin.
]]

local q = require("./Quad")
local Common = require("./Common")
local Material = require("../src")

type Ctx = Common.Ctx
type Variant = Material.ButtonVariant
type IconVariant = Material.IconButtonVariant

local VARIANTS: { Variant } = { "Filled", "Tonal", "Elevated", "Outlined", "Text" }
local ICON_VARIANTS: { IconVariant } = { "Standard", "Filled", "Tonal", "Outlined" }

return function(ctx: Ctx): Instance
	local theme = ctx.Theme
	local clicks = ctx.Memo("buttons.clicks", function()
		return q.Source(0)
	end)
	local disabled = ctx.Memo("buttons.disabled", function()
		return q.Source(false)
	end)
	local liked = ctx.Memo("buttons.liked", function()
		return q.Source(false)
	end)
	local bookmarked = ctx.Memo("buttons.bookmarked", function()
		return q.Source(true)
	end)
	local count: q.State<string> = clicks:Compute(function(self)
		return `Clicked {self:Get()} times`
	end)

	local variants: { Instance } = {}
	for _, v in VARIANTS do
		table.insert(
			variants,
			Material.Button({
				Theme = theme,
				Variant = v,
				Label = v,
				OnClick = function()
					clicks:Set(clicks:Get() + 1)
				end,
			})
		)
	end
	table.insert(variants, Common.Caption(ctx, count, false))

	local disabledSet: { Instance } = {}
	for _, v in VARIANTS do
		table.insert(disabledSet, Material.Button({ Theme = theme, Variant = v, Label = v, Disabled = disabled }))
	end
	table.insert(disabledSet, Material.Button({ Theme = theme, Label = "With icon", Icon = ctx.Icon, Disabled = disabled }))
	table.insert(disabledSet, Material.Button({ Theme = theme, Variant = "Outlined", Label = "Always disabled", Disabled = true }))

	local iconButtons: { Instance } = {}
	for _, v in ICON_VARIANTS do
		table.insert(iconButtons, Material.IconButton({ Theme = theme, Variant = v, Icon = ctx.Icon, Disabled = disabled }))
	end
	local toggles: { Instance } = {
		Material.IconButton({
			Theme = theme,
			Variant = "Standard",
			Icon = ctx.Icon,
			Selected = liked,
			OnClick = function()
				liked:Set(not liked:Get())
			end,
		}),
		Material.IconButton({
			Theme = theme,
			Variant = "Filled",
			Icon = ctx.Icon,
			Selected = bookmarked,
			OnClick = function()
				bookmarked:Set(not bookmarked:Get())
			end,
		}),
		Material.IconButton({
			Theme = theme,
			Variant = "Tonal",
			Icon = ctx.Icon,
			Selected = bookmarked,
			OnClick = function()
				bookmarked:Set(not bookmarked:Get())
			end,
		}),
		Material.IconButton({
			Theme = theme,
			Variant = "Outlined",
			Icon = ctx.Icon,
			Selected = liked,
			OnClick = function()
				liked:Set(not liked:Get())
			end,
		}),
	}

	-- icons: leading / trailing, an `Icons` name, an image URL, a text glyph
	local iconButtons2: { Instance } = {
		Material.Button({ Theme = theme, Label = "Leading", Icon = "check" }),
		Material.Button({ Theme = theme, Variant = "Tonal", Label = "Trailing", Icon = "arrowDown", IconPosition = "Trailing" }),
		Material.Button({ Theme = theme, Variant = "Outlined", Label = "Image id", Icon = ctx.Icon }),
		Material.Button({ Theme = theme, Variant = "Text", Label = "Next", Icon = "chevronRight", IconPosition = "Trailing" }),
		Material.Button({ Theme = theme, Variant = "Text", Label = "Glyph", Icon = "\u{266A}" }),
		Material.Button({ Theme = theme, Variant = "Elevated", Label = "Disabled", Icon = "edit", Disabled = disabled }),
	}

	-- split buttons: the trailing half opens a Menu under the button and is Selected while it is open
	local splitPicked = ctx.Memo("buttons.splitPicked", function()
		return q.Source("Save")
	end)
	type SplitVariant = "Filled" | "Tonal" | "Elevated" | "Outlined"
	local splits: { Instance } = {}
	for _, v in { "Filled", "Tonal", "Elevated", "Outlined" } :: { SplitVariant } do
		local open = q.Source(false)
		local host: GuiObject? = nil
		table.insert(
			splits,
			Material.SplitButton({
				Theme = theme,
				Variant = v,
				Label = splitPicked,
				Icon = if v == "Filled" then "check" else nil,
				Selected = open,
				OnClick = function()
					clicks:Set(clicks:Get() + 1)
				end,
				OnTrailingClick = function()
					local anchor = host
					if anchor == nil or open:Get() then
						return
					end
					open:Set(true)
					Material.Menu.open({
						Anchor = anchor,
						Overlay = ctx.Overlay,
						Theme = theme,
						Items = {
							{ Label = "Save", OnClick = function() splitPicked:Set("Save") end },
							{ Label = "Save as", OnClick = function() splitPicked:Set("Save as") end },
							{ Label = "Export", OnClick = function() splitPicked:Set("Export") end },
						},
						OnClose = function()
							open:Set(false)
						end,
					})
				end,
				Hooks = {
					Material.Util.preHook(function(inst: GuiObject)
						host = inst
					end),
				},
			})
		)
	end
	table.insert(splits, Material.SplitButton({ Theme = theme, Label = "Disabled", Disabled = disabled }))

	-- connected button groups: one selection (`Value`) or several (`Values`); the Sources live in the Memo
	local view = ctx.Memo("buttons.groupView", function()
		return q.Source("week" :: string?)
	end)
	local days = ctx.Memo("buttons.groupDays", function()
		return q.Source({ mon = true, wed = true } :: { [string]: boolean })
	end)
	local viewItems: { Material.ButtonGroupItem } = {
		{ Key = "day", Label = "Day" },
		{ Key = "week", Label = "Week" },
		{ Key = "month", Label = "Month" },
	}
	local dayItems: { Material.ButtonGroupItem } = {
		{ Key = "mon", Label = "Mon" },
		{ Key = "tue", Label = "Tue" },
		{ Key = "wed", Label = "Wed" },
		{ Key = "thu", Label = "Thu" },
		{ Key = "fri", Label = "Fri" },
	}
	local groupSingle: { Instance } = {
		Material.ButtonGroup({ Theme = theme, Items = viewItems, Value = view }),
		Material.ButtonGroup({
			Theme = theme,
			Variant = "Tonal",
			Items = {
				{ Key = "day", Label = "Day", Icon = "schedule" },
				{ Key = "week", Label = "Week", Icon = "calendar" },
				{ Key = "month", Label = "Month", Icon = "calendar" },
			},
			Value = view,
			Required = false,
		}),
		Common.Caption(ctx, Common.text<<string?>>(view, function(v: string?)
			return `Value: {v or "nil"}`
		end), false),
	}
	local groupMultiple: { Instance } = {
		Material.ButtonGroup({ Theme = theme, Items = dayItems, Values = days }),
		Common.Caption(ctx, Common.text<<{ [string]: boolean }>>(days, function(set: { [string]: boolean })
			local keys: { string } = {}
			for _, item in dayItems do
				if set[item.Key] then
					table.insert(keys, item.Key)
				end
			end
			return `Values: {if #keys == 0 then "(none)" else table.concat(keys, ", ")}`
		end), false),
	}
	local groupVariants: { Instance } = {}
	for _, v in { "Filled", "Tonal", "Elevated", "Outlined" } :: { Material.ButtonGroupVariant } do
		table.insert(
			groupVariants,
			Material.ButtonGroup({
				Theme = theme,
				Variant = v,
				Items = {
					{ Key = "day", Label = v },
					{ Key = "week", Label = "Week" },
					{ Key = "month", Label = "Off", Disabled = true },
				},
				Value = view,
				Disabled = disabled,
			})
		)
	end
	local groupWidth: { Instance } = {
		Material.ButtonGroup({ Theme = theme, Variant = "Outlined", Items = viewItems, Value = view, Width = 360 }),
	}

	local fabs: { Instance } = {
		Material.FAB({ Theme = theme, Size = "Small", Icon = ctx.Icon, Disabled = disabled }),
		Material.FAB({ Theme = theme, Icon = ctx.Icon, Disabled = disabled }),
		Material.FAB({ Theme = theme, Size = "Large", Icon = ctx.Icon, Disabled = disabled }),
		Material.FAB({ Theme = theme, Color = "Surface", Icon = ctx.Icon, Disabled = disabled }),
		Material.FAB({ Theme = theme, Color = "Secondary", Icon = ctx.Icon, Disabled = disabled }),
		Material.FAB({ Theme = theme, Color = "Tertiary", Icon = ctx.Icon, Disabled = disabled }),
		Material.FAB({ Theme = theme, Icon = ctx.Icon, Label = "Compose", Disabled = disabled }),
	}

	return Common.Section(ctx, "Buttons", "Buttons", {
		Common.Group(ctx, "Button: five variants", variants),
		Common.Group(ctx, "Disable switch", {
			Material.Switch({ Theme = theme, Value = disabled }),
			Common.Caption(ctx, Common.text<<boolean>>(disabled, function(v: boolean)
				return if v then "Disabled: the buttons below ignore input" else "Enabled"
			end), false),
		}, "One Source<boolean> feeds the Disabled State of every button below."),
		Common.Group(ctx, "Button: disabled, icon", disabledSet),
		Common.Group(ctx, "Button: fixed width", {
			Material.Button({ Theme = theme, Label = "OK", Width = 160 }),
			Material.Button({ Theme = theme, Variant = "Outlined", Label = "Cancel", Width = 160 }),
			Material.Button({ Theme = theme, Variant = "Tonal", Label = "With icon", Icon = ctx.Icon, Width = 200 }),
		}, "`Width = 160` (pixels) or a UDim such as `UDim.new(1, 0)`: the label stays centered. Without `Width` a button is as wide as its label."),
		Common.Group(
			ctx,
			"Button: icons — leading / trailing",
			iconButtons2,
			"`Icon` takes an Icons name (\"check\"), an image id, or text drawn as a glyph; `IconPosition = \"Trailing\"` puts it after the label (padding 24 / 16, Text 16 / 12)."
		),
		Common.Group(
			ctx,
			"SplitButton (M3 Expressive)",
			splits,
			"The leading half is the action (counts into the caption above); the trailing half opens a menu and stays Selected (circle, arrow turned) while it is open. Inner corners 4, 12 while pressed."
		),
		Common.Group(
			ctx,
			"ButtonGroup (M3 Expressive): single selection",
			groupSingle,
			"A connected button group — the segmented button's place. `Value` is a Source<string?> of the selected Key; both groups share it. The second one has `Required = false`: a click on its selected cell clears the selection. Inner corners 8, 4 while pressed; the selected cell is a pill."
		),
		Common.Group(ctx, "ButtonGroup: multiple selection", groupMultiple, "`Values` is a Source<{ [string]: boolean }>: every cell toggles on its own."),
		Common.Group(
			ctx,
			"ButtonGroup: variants, a disabled cell",
			groupVariants,
			"Filled / Tonal / Elevated / Outlined toggle colors; the last cell of each is always disabled, the disable switch above disables the whole group."
		),
		Common.Group(ctx, "ButtonGroup: fixed width", groupWidth, "`Width = 360`: the cells share the width equally, labels centered."),
		Common.Group(ctx, "IconButton: variants", iconButtons),
		Common.Group(ctx, "IconButton: toggles (Selected)", toggles, "Standard/Outlined share `liked`, Filled/Tonal share `bookmarked`."),
		Common.Group(ctx, "FAB: sizes, colors, extended", fabs),
	})
end
