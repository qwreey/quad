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

-- Switch (the M3 look; M2Switch.story is the Material 2 look — drag the handle past the half or tap): `Value` (two-way) and the controlled `Checked` form; the thumb icons are plain props, so toggling "Icons"
-- rebuilds the two-way switch.
return StoryKit.story({
	controls = {
		On = false,
		Icons = false,
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local value = q.Source(true)
		local icons: q.State<boolean> = c.Icons:Compute(function(self)
			return self:Get() == true
		end)
		return page(theme, follow, {
			caption(theme, "Value (two-way)"),
			holder(
				40,
				StoryKit.rebuild<<boolean>>(icons, function(on: boolean)
					return Material.Switch({
						Value = value,
						IconOn = if on then ICON else nil,
						IconOff = if on then ICON else nil,
						Disabled = c.Disabled,
						Theme = theme,
					})
				end)
			),
			caption(theme, show<<boolean>>(value, "Value = ", tostr)),
			caption(theme, "Checked (controlled by the control panel's \"On\")"),
			Material.Switch({ Checked = c.On, Disabled = c.Disabled, Theme = theme }),
			caption(theme, show<<any>>(c.On, "On = ", tostr)),
		})
	end,
})
