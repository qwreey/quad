--!strict
local Material = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local tostr = StoryParts.tostr
local page = StoryParts.page
local themed = StoryParts.themed

-- M2.Switch (the Material 2 look — same props and behaviour as Switch.story; M2 thumbs carry no icon, so there is no
-- "Icons" control): `Value` (two-way) and the controlled `Checked` form. Drag the thumb past the half or tap.
return StoryKit.story({
	controls = {
		On = false,
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local value = q.Source(true)
		return page(theme, follow, {
			caption(theme, "Value (two-way) — drag the thumb or tap"),
			holder(40, Material.M2.Switch({ Value = value, Disabled = c.Disabled, Theme = theme })),
			caption(theme, show<<boolean>>(value, "Value = ", tostr)),
			caption(theme, "Checked (controlled by the control panel's \"On\")"),
			Material.M2.Switch({ Checked = c.On, Disabled = c.Disabled, Theme = theme }),
			caption(theme, show<<any>>(c.On, "On = ", tostr)),
		})
	end,
})
