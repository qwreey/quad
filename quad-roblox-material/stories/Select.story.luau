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

-- Select: the option list is a State (the "Options" count control rebuilds it in place), `Value` is a Source<string?>.
-- Its dropdown opens in the story's overlay (`Overlay = ctx.Overlay`).
type Look = { Variant: Material.TextFieldVariant, Icon: boolean }

return StoryKit.story({
	controls = {
		Label = "Fruit",
		Variant = StoryKit.Choose({ "Filled", "Outlined" }),
		Options = StoryKit.Slider(5, 1, 12, 1),
		Placeholder = "Pick one",
		SupportingText = "Select one option",
		Error = false,
		ErrorText = "Required",
		Disabled = false,
		LeadingIcon = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c, ctx)
		local theme, follow = themed(c.Scheme)
		local value = q.Source(nil :: string?)
		local picked = q.Source("(nothing)")
		local options: q.State<{ string }> = c.Options:Compute(function(self)
			local list: { string } = {}
			for i = 1, self:Get() do
				table.insert(list, "Option " .. i)
			end
			return list
		end)
		local look: q.State<Look> = c.Variant:Compute(function(self, _prev, icon)
			return { Variant = if self:Get() == "Outlined" then "Outlined" else "Filled", Icon = icon:Get() == true }
		end, c.LeadingIcon)
		local placeholder: string = c.Placeholder:Get()
		return page(theme, follow, {
			holder(
				80,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					return Material.Select<<string>>({
						Options = options,
						Value = value,
						Label = c.Label,
						Variant = l.Variant,
						Placeholder = placeholder,
						SupportingText = c.SupportingText,
						Error = c.Error,
						ErrorText = c.ErrorText,
						Disabled = c.Disabled,
						LeadingIcon = if l.Icon then ICON else nil,
						Overlay = ctx.Overlay,
						MaxMenuHeight = 240,
						Theme = theme,
						OnChange = function(o: string)
							picked:Set(o)
						end,
					})
				end)
			),
			caption(theme, show<<string?>>(value, "Value = ", function(v: string?)
				return if v == nil then "nil" else v
			end)),
			caption(theme, show<<string>>(picked, "Last OnChange: ", tostr)),
		})
	end,
})
