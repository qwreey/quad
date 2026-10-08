--!strict
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local row = StoryParts.row
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local tostr = StoryParts.tostr
local page = StoryParts.page
local themed = StoryParts.themed

-- RadioGroup (options fixed at construction, so Direction rebuilds it) and loose Radios sharing a Source.
return StoryKit.story({
	controls = {
		Direction = StoryKit.Choose({ "Vertical", "Horizontal" }),
		Error = false,
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local fruit = q.Source("pear")
		local size = q.Source("m")
		local direction: q.State<"Vertical" | "Horizontal"> = c.Direction:Compute(function(self)
			return if self:Get() == "Horizontal" then "Horizontal" else "Vertical"
		end)
		return page(theme, follow, {
			caption(theme, "RadioGroup"),
			holder(
				120,
				StoryKit.rebuild<<"Vertical" | "Horizontal">>(direction, function(d: "Vertical" | "Horizontal")
					return Material.RadioGroup({
						Value = fruit,
						Direction = d,
						Error = c.Error,
						Disabled = c.Disabled,
						Theme = theme,
						Options = {
							{ Option = "apple", Label = "Apple" },
							{ Option = "pear", Label = "Pear" },
							{ Option = "plum", Label = "Plum (always disabled)", Disabled = true },
						},
					})
				end)
			),
			caption(theme, show<<string>>(fruit, "Value = ", tostr)),
			caption(theme, "Loose Radios, one shared Source"),
			row({
				Material.Radio({ Value = size, Option = "s", Error = c.Error, Disabled = c.Disabled, Theme = theme }),
				Material.Radio({ Value = size, Option = "m", Error = c.Error, Disabled = c.Disabled, Theme = theme }),
				Material.Radio({ Value = size, Option = "l", Error = c.Error, Disabled = c.Disabled, Theme = theme }),
				caption(theme, show<<string>>(size, "size = ", tostr)),
			}),
		})
	end,
})
