--!strict
local Material = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local row = StoryParts.row
local caption = StoryParts.caption
local show = StoryParts.show
local tostr = StoryParts.tostr
local page = StoryParts.page
local themed = StoryParts.themed

-- Checkbox, two forms: `Value` (two-way Source, a click writes it) and the controlled `Checked` (the owner decides —
-- here the control panel's "Checked" is the owner and a click only fires OnChange). Every prop is a live Source.
return StoryKit.story({
	controls = {
		Checked = false,
		Indeterminate = false,
		Error = false,
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local value = q.Source(true)
		local lastRequest = q.Source("none")
		return page(theme, follow, {
			caption(theme, "Value (two-way)"),
			row({
				Material.Checkbox({
					Value = value,
					Indeterminate = c.Indeterminate,
					Error = c.Error,
					Disabled = c.Disabled,
					Theme = theme,
				}),
				caption(theme, show<<boolean>>(value, "Value = ", tostr)),
			}),
			caption(theme, "Checked (controlled by the control panel)"),
			row({
				Material.Checkbox({
					Checked = c.Checked,
					Indeterminate = c.Indeterminate,
					Error = c.Error,
					Disabled = c.Disabled,
					Theme = theme,
					OnChange = function(v: boolean)
						lastRequest:Set(tostring(v))
					end,
				}),
				caption(theme, show<<any>>(c.Checked, "Checked = ", tostr)),
				caption(theme, show<<string>>(lastRequest, "last click asked for: ", tostr)),
			}),
			caption(theme, "Fixed states"),
			row({
				Material.Checkbox({ Value = q.Source(true), Disabled = true, Theme = theme }),
				Material.Checkbox({ Value = q.Source(false), Disabled = true, Theme = theme }),
				Material.Checkbox({ Value = q.Source(false), Error = true, Theme = theme }),
			}),
		})
	end,
})
