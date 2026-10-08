--!strict
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local ICON = StoryParts.ICON
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local page = StoryParts.page
local themed = StoryParts.themed

-- TextField: Label / SupportingText / Error / ErrorText / Disabled are live; Variant, adornments, MultiLine and
-- MaxLength are construction-time (the story rebuilds). `Value` is a Source the story reads back below the field.
type Look = {
	Variant: Material.TextFieldVariant,
	Icons: boolean,
	Affix: boolean,
	Multi: boolean,
	MaxLength: number?,
}

return StoryKit.story({
	controls = {
		Label = "Display name",
		Variant = StoryKit.Choose({ "Filled", "Outlined" }),
		Placeholder = "Type here",
		SupportingText = "Shown under the field",
		Error = false,
		ErrorText = "That name is taken",
		Disabled = false,
		LeadingAndTrailingIcon = false,
		PrefixAndSuffix = false,
		MultiLine = false,
		MaxLength = StoryKit.Slider(0, 0, 40, 1), -- 0 = unlimited
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local text = q.Source("")
		local submitted = q.Source("")
		local look: q.State<Look> = c.Variant:Compute(function(self, _prev, icons, affix, multi, maxLen)
			local m: number = maxLen:Get()
			return {
				Variant = if self:Get() == "Outlined" then "Outlined" else "Filled",
				Icons = icons:Get() == true,
				Affix = affix:Get() == true,
				Multi = multi:Get() == true,
				MaxLength = if m > 0 then m else nil,
			}
		end, c.LeadingAndTrailingIcon, c.PrefixAndSuffix, c.MultiLine, c.MaxLength)
		local placeholder: string = c.Placeholder:Get()
		return page(theme, follow, {
			holder(
				120,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					return Material.TextField({
						Variant = l.Variant,
						Label = c.Label,
						Value = text,
						Placeholder = placeholder,
						SupportingText = c.SupportingText,
						Error = c.Error,
						ErrorText = c.ErrorText,
						Disabled = c.Disabled,
						LeadingIcon = if l.Icons then ICON else nil,
						TrailingIcon = if l.Icons then ICON else nil,
						Prefix = if l.Affix then "$" else nil,
						Suffix = if l.Affix then "USD" else nil,
						MultiLine = l.Multi,
						MaxLength = l.MaxLength,
						Theme = theme,
						OnSubmit = function(t: string)
							submitted:Set(t)
						end,
					})
				end)
			),
			caption(theme, show<<string>>(text, "Value = ", function(t: string)
				return string.format("%q", t)
			end)),
			caption(theme, show<<string>>(submitted, "Submitted: ", function(t: string)
				return string.format("%q", t)
			end)),
		})
	end,
})
