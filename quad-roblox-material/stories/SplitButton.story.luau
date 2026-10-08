--!strict
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local ICON = StoryParts.ICON
local row = StoryParts.row
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local tostr = StoryParts.tostr
local page = StoryParts.page
local themed = StoryParts.themed

-- SplitButton (M3 Expressive, small): the leading half is the action, the trailing half a menu button. Here the
-- trailing half toggles `Selected` (the open-menu look: circle shape, arrow turned) instead of opening a menu — the
-- gallery's Buttons section opens a real Menu. `Variant` and the leading icon are construction-time (rebuild).
type Look = { Variant: Material.SplitButtonVariant, Icon: boolean }

return StoryKit.story({
	controls = {
		Label = "Save",
		Variant = StoryKit.Choose({ "Filled", "Tonal", "Elevated", "Outlined" }),
		Icon = false,
		Selected = false,
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local look: q.State<Look> = c.Variant:Compute(function(self, _prev, icon)
			return { Variant = self:Get(), Icon = icon:Get() == true }
		end, c.Icon)
		local clicks = q.Source(0)
		local menuClicks = q.Source(0)
		local selected: q.State<boolean> = c.Selected:Compute(function(self)
			return self:Get() == true
		end)
		return page(theme, follow, {
			holder(
				48,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					return Material.SplitButton({
						Label = c.Label,
						Variant = l.Variant,
						Icon = if l.Icon then ICON else nil,
						Selected = selected,
						Disabled = c.Disabled,
						Theme = theme,
						OnClick = function()
							clicks:Set(clicks:Get() + 1)
						end,
						OnTrailingClick = function()
							menuClicks:Set(menuClicks:Get() + 1)
						end,
					})
				end)
			),
			caption(theme, show<<number>>(clicks, "Leading clicks: ", tostr)),
			caption(theme, show<<number>>(menuClicks, "Trailing clicks: ", tostr)),
			caption(theme, "All variants (static)"),
			row({
				Material.SplitButton({ Label = "Filled", Variant = "Filled", Theme = theme, Disabled = c.Disabled }),
				Material.SplitButton({ Label = "Tonal", Variant = "Tonal", Theme = theme, Disabled = c.Disabled }),
				Material.SplitButton({ Label = "Elevated", Variant = "Elevated", Theme = theme, Disabled = c.Disabled }),
				Material.SplitButton({ Label = "Outlined", Variant = "Outlined", Theme = theme, Disabled = c.Disabled }),
				Material.SplitButton({ Label = "Selected", Icon = "check", Selected = true, Theme = theme, Disabled = c.Disabled }),
			}),
		})
	end,
})
