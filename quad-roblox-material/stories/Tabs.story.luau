--!strict
local Material = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local StoryParts = require("./StoryParts")
local ICON = StoryParts.ICON
local holder = StoryParts.holder
local caption = StoryParts.caption
local show = StoryParts.show
local tostr = StoryParts.tostr
local page = StoryParts.page
local themed = StoryParts.themed

-- Tabs: the tab list is a State (`TabsState`) so the count / icon controls edit it in place; `Selected` is a
-- Source<string>. Variant is construction-time, so the story rebuilds on it (the selection Source survives).
type Tab = Material.Tab<string>

return StoryKit.story({
	controls = {
		Variant = StoryKit.Choose({ "Primary", "Secondary" }),
		Count = StoryKit.Slider(3, 3, 6, 1),
		Icons = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)
		local selected = q.Source("t1")
		local tabs: q.State<{ Tab }> = c.Count:Compute(function(self, _prev, icons)
			local list: { Tab } = {}
			for i = 1, self:Get() do
				table.insert(list, { Key = "t" .. i, Label = "Tab " .. i, Icon = if icons:Get() == true then ICON else nil })
			end
			return list
		end, c.Icons)
		local variant: q.State<Material.TabsVariant> = c.Variant:Compute(function(self)
			return if self:Get() == "Secondary" then "Secondary" else "Primary"
		end)
		local changes = q.Source(0)
		return page(theme, follow, {
			holder(
				72,
				StoryKit.rebuild<<Material.TabsVariant>>(variant, function(v: Material.TabsVariant)
					return Material.Tabs<<string>>({
						Variant = v,
						TabsState = tabs,
						Selected = selected,
						Theme = theme,
						OnChange = function()
							changes:Set(changes:Get() + 1)
						end,
					})
				end)
			),
			caption(theme, show<<string>>(selected, "Selected = ", tostr)),
			caption(theme, show<<number>>(changes, "OnChange fired ", tostr)),
		})
	end,
})
