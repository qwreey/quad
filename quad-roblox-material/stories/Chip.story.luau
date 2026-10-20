--!strict
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local TextButtonModifier = q.Modifier "TextButton"
local StoryParts = require("./StoryParts")
local ICON = StoryParts.ICON
local row = StoryParts.row
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local tostr = StoryParts.tostr
local page = StoryParts.page
local themed = StoryParts.themed

-- Chip families: Assist, Suggestion, Filter (a Source<boolean> `Selected`), Input (removable), and the wrapping
-- ChipSet. Label/Disabled are live; Elevated and the leading icon are construction-time (the story rebuilds the set
-- of single chips).
type Look = { Elevated: boolean, Icon: boolean }

return StoryKit.story({
	controls = {
		Label = "Chip",
		Elevated = false,
		Icon = false,
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local selected = q.Source(false)
		local taps = q.Source(0)
		local tags = q.Source({ "Lua", "Luau", "Roblox" })
		local look: q.State<Look> = c.Elevated:Compute(function(self, _prev, icon)
			return { Elevated = self:Get() == true, Icon = icon:Get() == true }
		end, c.Icon)
		local function tap()
			taps:Set(taps:Get() + 1)
		end
		return page(theme, follow, {
			holder(
				40,
				StoryKit.rebuild<<Look>>(look, function(l: Look)
					local icon: string? = if l.Icon then ICON else nil
					return row({
						Material.Chip.Assist({ Label = c.Label, Icon = icon, Elevated = l.Elevated, Disabled = c.Disabled, OnClick = tap, Theme = theme }),
						Material.Chip.Suggestion({ Label = c.Label, Elevated = l.Elevated, Disabled = c.Disabled, OnClick = tap, Theme = theme }),
						Material.Chip.Filter({ Label = c.Label, Selected = selected, Icon = icon, Elevated = l.Elevated, Disabled = c.Disabled, Theme = theme }),
						Material.Chip.Input({ Label = c.Label, Icon = icon, OnRemove = tap, Elevated = l.Elevated, Disabled = c.Disabled, Theme = theme }),
					})
				end)
			),
			caption(theme, show<<boolean>>(selected, "Filter selected = ", tostr)),
			caption(theme, show<<number>>(taps, "Taps / removes: ", tostr)),
			caption(theme, "ChipSet: remove a tag with its x, or add one"),
			Material.Chip.ChipSet<<string>>({
				Items = tags,
				Key = function(item: string)
					return item
				end,
				Render = function(item: q.State<string>, order: q.State<number>)
					return Material.Chip.Input({
						Label = item,
						Disabled = c.Disabled,
						Theme = theme,
						Modifier = TextButtonModifier():LayoutOrder(order),
						OnRemove = function()
							local gone = item:Get()
							local keep: { string } = {}
							for _, t in tags:Get() do
								if t ~= gone then
									table.insert(keep, t)
								end
							end
							tags:Set(keep)
						end,
					})
				end,
			}),
			Material.Button({
				Label = "Add tag",
				Variant = "Text",
				Theme = theme,
				OnClick = function()
					local next = table.clone(tags:Get())
					table.insert(next, "Tag " .. (#next + 1))
					tags:Set(next)
				end,
			}),
		})
	end,
})
