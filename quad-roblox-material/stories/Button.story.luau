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

-- Button: the five M3 variants. `Label`/`Disabled` are Sources the component binds directly; `Variant`, the icon and
-- its position are decided at construction, so the story rebuilds the button when any changes (StoryKit.rebuild).
-- `Icon` takes an `Icons` name ("check"), an image id, or text drawn as a glyph; `IconPosition` "Leading" / "Trailing".
type Look = { Variant: Material.ButtonVariant, Icon: boolean, Trailing: boolean }

return StoryKit.story({
	controls = {
		Label = "Save",
		Variant = StoryKit.Choose({ "Filled", "Tonal", "Outlined", "Text", "Elevated" }),
		Icon = false,
		TrailingIcon = false,
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local look: q.State<Look> = c.Variant:Compute(function(self, _prev, icon, trailing)
			return { Variant = self:Get(), Icon = icon:Get() == true, Trailing = trailing:Get() == true }
		end, c.Icon, c.TrailingIcon)
		local clicks = q.Source(0)
		return page(theme, follow, {
			holder(
				48,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					return Material.Button({
						Label = c.Label,
						Variant = l.Variant,
						Icon = if l.Icon then ICON else nil,
						IconPosition = if l.Trailing then "Trailing" else "Leading",
						Disabled = c.Disabled,
						Theme = theme,
						OnClick = function()
							clicks:Set(clicks:Get() + 1)
						end,
					})
				end)
			),
			caption(theme, show<<number>>(clicks, "Clicks: ", tostr)),
			caption(theme, "All variants (static)"),
			row({
				Material.Button({ Label = "Filled", Variant = "Filled", Theme = theme, Disabled = c.Disabled }),
				Material.Button({ Label = "Tonal", Variant = "Tonal", Theme = theme, Disabled = c.Disabled }),
				Material.Button({ Label = "Outlined", Variant = "Outlined", Theme = theme, Disabled = c.Disabled }),
				Material.Button({ Label = "Text", Variant = "Text", Theme = theme, Disabled = c.Disabled }),
				Material.Button({ Label = "Elevated", Variant = "Elevated", Theme = theme, Disabled = c.Disabled }),
			}),
			caption(theme, "Icons: leading / trailing (Icons names), a glyph"),
			row({
				Material.Button({ Label = "Done", Icon = "check", Theme = theme, Disabled = c.Disabled }),
				Material.Button({ Label = "More", Variant = "Tonal", Icon = "arrowDown", IconPosition = "Trailing", Theme = theme, Disabled = c.Disabled }),
				Material.Button({ Label = "Next", Variant = "Text", Icon = "chevronRight", IconPosition = "Trailing", Theme = theme, Disabled = c.Disabled }),
				Material.Button({ Label = "Music", Variant = "Outlined", Icon = "\u{266A}", Theme = theme, Disabled = c.Disabled }),
			}),
			caption(theme, "Fixed width (`Width = 160`, label centered)"),
			row({
				Material.Button({ Label = c.Label, Variant = "Filled", Width = 160, Theme = theme, Disabled = c.Disabled }),
				Material.Button({ Label = c.Label, Variant = "Outlined", Width = 160, Theme = theme, Disabled = c.Disabled }),
			}),
		})
	end,
})
