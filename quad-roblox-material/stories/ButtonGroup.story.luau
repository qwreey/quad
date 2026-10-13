--!strict
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local row = StoryParts.row
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local page = StoryParts.page
local themed = StoryParts.themed

-- ButtonGroup (M3 Expressive connected button group, small): a row of toggle cells 2 px apart — outer ends fully round,
-- inner corners 8 (4 while pressed), a selected cell a pill in the selected colors. `Multiple` switches the story
-- between the two forms (`Value: Source<string?>` / `Values: Source<{ [string]: boolean }>`); `Variant`, the icons, the
-- fill width and `Required` are construction-time (rebuild).
type Look = { Variant: Material.ButtonGroupVariant, Multiple: boolean, Icons: boolean, Fill: boolean, Required: boolean }

local function setText(set: { [string]: boolean }): string
	local keys: { string } = {}
	for key, on in set do
		if on then
			table.insert(keys, key)
		end
	end
	table.sort(keys)
	return if #keys == 0 then "(none)" else table.concat(keys, ", ")
end

return StoryKit.story({
	controls = {
		Variant = StoryKit.Choose({ "Filled", "Tonal", "Elevated", "Outlined" }),
		Multiple = false,
		Icons = false,
		Fill = false,
		Required = true,
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local look: q.State<Look> = c.Variant:Compute(function(self, _prev, multiple, icons, fill, required)
			return {
				Variant = self:Get(),
				Multiple = multiple:Get() == true,
				Icons = icons:Get() == true,
				Fill = fill:Get() == true,
				Required = required:Get() == true,
			}
		end, c.Multiple, c.Icons, c.Fill, c.Required)
		local single = q.Source("week" :: string?)
		local many = q.Source({ week = true } :: { [string]: boolean })
		local changes = q.Source(0)
		local function items(icons: boolean): { Material.ButtonGroupItem }
			return {
				{ Key = "day", Label = "Day", Icon = if icons then "check" else nil },
				{ Key = "week", Label = "Week", Icon = if icons then "edit" else nil },
				{ Key = "month", Label = "Month", Icon = if icons then "calendar" else nil },
				{ Key = "year", Label = "Year", Icon = if icons then "schedule" else nil },
			}
		end
		local two: { Material.ButtonGroupItem } = { { Key = "on", Label = "On" }, { Key = "off", Label = "Off" } }
		local staticValue = q.Source("on" :: string?)
		return page(theme, follow, {
			holder(
				48,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					local width: UDim? = if l.Fill then UDim.new(1, 0) else nil
					if l.Multiple then
						return Material.ButtonGroup({
							Items = items(l.Icons),
							Values = many,
							Required = l.Required,
							Variant = l.Variant,
							Width = width,
							Disabled = c.Disabled,
							Theme = theme,
							OnValuesChange = function()
								changes:Set(changes:Get() + 1)
							end,
						})
					end
					return Material.ButtonGroup({
						Items = items(l.Icons),
						Value = single,
						Required = l.Required,
						Variant = l.Variant,
						Width = width,
						Disabled = c.Disabled,
						Theme = theme,
						OnChange = function()
							changes:Set(changes:Get() + 1)
						end,
					})
				end)
			),
			caption(theme, show<<string?>>(single, "Value: ", function(v: string?)
				return v or "(nil)"
			end)),
			caption(theme, show<<{ [string]: boolean }>>(many, "Values: ", setText)),
			caption(theme, show<<number>>(changes, "User changes: ", tostring)),
			caption(theme, "All variants (static, one Source)"),
			row({
				Material.ButtonGroup({ Items = two, Value = staticValue, Variant = "Filled", Theme = theme, Disabled = c.Disabled }),
				Material.ButtonGroup({ Items = two, Value = staticValue, Variant = "Tonal", Theme = theme, Disabled = c.Disabled }),
				Material.ButtonGroup({ Items = two, Value = staticValue, Variant = "Elevated", Theme = theme, Disabled = c.Disabled }),
				Material.ButtonGroup({ Items = two, Value = staticValue, Variant = "Outlined", Theme = theme, Disabled = c.Disabled }),
			}),
		})
	end,
})
