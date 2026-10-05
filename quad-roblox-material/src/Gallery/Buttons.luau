--!strict
--[[
	Gallery section "Buttons": Button (five variants, icon, disabled), IconButton (four variants + a toggle), FAB (sizes,
	colors, extended). A Switch in the first group drives the `Disabled` State of every button below it, so the disabled
	look of each variant can be compared with its enabled twin.
]]

local q = require("../Quad")
local Common = require("./Common")
local Button = require("../Button")
local IconButton = require("../Button/IconButton")
local FAB = require("../Button/FAB")
local Switch = require("../Switch")

type Ctx = Common.Ctx
type Variant = "Filled" | "Tonal" | "Elevated" | "Outlined" | "Text"
type IconVariant = "Standard" | "Filled" | "Tonal" | "Outlined"

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
			Button({
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
		table.insert(disabledSet, Button({ Theme = theme, Variant = v, Label = v, Disabled = disabled }))
	end
	table.insert(disabledSet, Button({ Theme = theme, Label = "With icon", Icon = ctx.Icon, Disabled = disabled }))
	table.insert(disabledSet, Button({ Theme = theme, Variant = "Outlined", Label = "Always disabled", Disabled = true }))

	local iconButtons: { Instance } = {}
	for _, v in ICON_VARIANTS do
		table.insert(iconButtons, IconButton({ Theme = theme, Variant = v, Icon = ctx.Icon, Disabled = disabled }))
	end
	local toggles: { Instance } = {
		IconButton({
			Theme = theme,
			Variant = "Standard",
			Icon = ctx.Icon,
			Selected = liked,
			OnClick = function()
				liked:Set(not liked:Get())
			end,
		}),
		IconButton({
			Theme = theme,
			Variant = "Filled",
			Icon = ctx.Icon,
			Selected = bookmarked,
			OnClick = function()
				bookmarked:Set(not bookmarked:Get())
			end,
		}),
		IconButton({
			Theme = theme,
			Variant = "Tonal",
			Icon = ctx.Icon,
			Selected = bookmarked,
			OnClick = function()
				bookmarked:Set(not bookmarked:Get())
			end,
		}),
		IconButton({
			Theme = theme,
			Variant = "Outlined",
			Icon = ctx.Icon,
			Selected = liked,
			OnClick = function()
				liked:Set(not liked:Get())
			end,
		}),
	}

	local fabs: { Instance } = {
		FAB({ Theme = theme, Size = "Small", Icon = ctx.Icon, Disabled = disabled }),
		FAB({ Theme = theme, Icon = ctx.Icon, Disabled = disabled }),
		FAB({ Theme = theme, Size = "Large", Icon = ctx.Icon, Disabled = disabled }),
		FAB({ Theme = theme, Color = "Surface", Icon = ctx.Icon, Disabled = disabled }),
		FAB({ Theme = theme, Color = "Secondary", Icon = ctx.Icon, Disabled = disabled }),
		FAB({ Theme = theme, Color = "Tertiary", Icon = ctx.Icon, Disabled = disabled }),
		FAB({ Theme = theme, Icon = ctx.Icon, Label = "Compose", Disabled = disabled }),
	}

	return Common.Section(ctx, "Buttons", "Buttons", {
		Common.Group(ctx, "Button: five variants", variants),
		Common.Group(ctx, "Disable switch", {
			Switch({ Theme = theme, Value = disabled }),
			Common.Caption(ctx, Common.text<<boolean>>(disabled, function(v: boolean)
				return if v then "Disabled: the buttons below ignore input" else "Enabled"
			end), false),
		}, "One Source<boolean> feeds the Disabled State of every button below."),
		Common.Group(ctx, "Button: disabled, icon", disabledSet),
		Common.Group(ctx, "IconButton: variants", iconButtons),
		Common.Group(ctx, "IconButton: toggles (Selected)", toggles, "Standard/Outlined share `liked`, Filled/Tonal share `bookmarked`."),
		Common.Group(ctx, "FAB: sizes, colors, extended", fabs),
	})
end
