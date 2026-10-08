--!strict
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local ICON = StoryParts.ICON
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local tostr = StoryParts.tostr
local page = StoryParts.page
local themed = StoryParts.themed

-- FAB: three sizes, four colours; a `Label` makes it the extended FAB. Size/Colour/Label are construction-time, so the
-- story rebuilds the FAB when one changes (StoryKit.rebuild); `Disabled` stays a live Source.
type Look = {
	Size: "Small" | "Regular" | "Large",
	Color: "Surface" | "Primary" | "Secondary" | "Tertiary",
	Extended: boolean,
}

return StoryKit.story({
	controls = {
		Size = StoryKit.Choose({ "Small", "Regular", "Large" }, 2),
		Color = StoryKit.Choose({ "Primary", "Secondary", "Tertiary", "Surface" }),
		Extended = false,
		Label = "Compose",
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local look: q.State<Look> = c.Size:Compute(function(self, _prev, color, ext)
			return { Size = self:Get(), Color = color:Get(), Extended = ext:Get() == true }
		end, c.Color, c.Extended)
		local clicks = q.Source(0)
		return page(theme, follow, {
			holder(
				104,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					return Material.FAB({
						Size = l.Size,
						Color = l.Color,
						Icon = ICON,
						Label = if l.Extended then c.Label else nil,
						Disabled = c.Disabled,
						Theme = theme,
						OnClick = function()
							clicks:Set(clicks:Get() + 1)
						end,
					})
				end)
			),
			caption(theme, show<<number>>(clicks, "Clicks: ", tostr)),
		})
	end,
})
