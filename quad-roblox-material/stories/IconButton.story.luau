--!strict
local Material = require("../src")
local q = require("../src/Quad")
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

-- IconButton (toggle via `Selected`) and the FAB are in the same family; FAB has its own story.
type Look = { Variant: Material.IconButtonVariant, Touch: boolean }

return StoryKit.story({
	controls = {
		Variant = StoryKit.Choose({ "Standard", "Filled", "Tonal", "Outlined" }),
		Selected = false,
		Disabled = false,
		TouchTarget = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local look: q.State<Look> = c.Variant:Compute(function(self, _prev, touch)
			return { Variant = self:Get(), Touch = touch:Get() == true }
		end, c.TouchTarget)
		local toggled = q.Source(false)
		local clicks = q.Source(0)
		return page(theme, follow, {
			holder(
				56,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					return Material.IconButton({
						Variant = l.Variant,
						Icon = ICON,
						Selected = c.Selected,
						Disabled = c.Disabled,
						TouchTarget = l.Touch,
						Theme = theme,
						OnClick = function()
							clicks:Set(clicks:Get() + 1)
						end,
					})
				end)
			),
			caption(theme, show<<number>>(clicks, "Clicks: ", tostr)),
			caption(theme, "A toggle: Selected follows the Source the story's own button writes"),
			row({
				Material.IconButton({
					Variant = "Tonal",
					Icon = ICON,
					Selected = toggled,
					Disabled = c.Disabled,
					Theme = theme,
					OnClick = function()
						toggled:Set(not toggled:Get())
					end,
				}),
				caption(theme, show<<boolean>>(toggled, "Selected: ", tostr)),
			}),
		})
	end,
})
