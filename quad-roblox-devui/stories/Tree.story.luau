--!strict
-- Tree / CollapsingHeader / TabBar+Tab. The control panel owns the first tree's open state and the selected tab;
-- the widgets write back when you click them in the story view.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		TreeOpen = true,
		HeaderOpen = true,
		Tab = StoryKit.Choose({ "Alpha", "Beta", "Gamma" }, 1),
		Label = "Node",
	},
	render = function(c)
		local tabs: { Devui.TabDef<string> } = {
			Devui.Tab<<string>>({ Key = "Alpha", Text = "Alpha", Children = Kids(Devui.Text({ Text = "first tab" })) }),
			Devui.Tab<<string>>({
				Key = "Beta",
				Text = "Beta",
				Children = Kids(Devui.Text({ Text = "second tab" }), Devui.Button({ Text = "a button in a tab" })),
			}),
			Devui.Tab<<string>>({ Key = "Gamma", Text = "Gamma", Children = Kids(Devui.TextDisabled({ Text = "third tab" })) }),
		}
		return Devui.Window({
			Title = "Tree / Tab",
			Size = q.Source(Vector2.new(340, 440)),
			Children = Kids(
				Devui.Tree({
					Text = c.Label,
					Open = c.TreeOpen,
					Children = Kids(
						Devui.Text({ Text = "leaf" }),
						Devui.Tree({ Text = "nested", Children = Kids(Devui.Text({ Text = "deeper leaf" })) }),
						Devui.Tree({ Text = "SpanAvailWidth", SpanAvailWidth = true, Children = Kids(Devui.Text({ Text = "x" })) })
					),
				}),
				Shared.show("tree open", c.TreeOpen),
				Devui.CollapsingHeader({
					Text = "CollapsingHeader",
					Open = c.HeaderOpen,
					Children = Kids(Devui.Text({ Text = "header content" }), Devui.Checkbox({ Text = "inside" })),
				}),
				Shared.show("header open", c.HeaderOpen),
				Devui.TabBar<<string>>({ Tabs = tabs, Selected = c.Tab }),
				Shared.show("tab", c.Tab)
			),
		})
	end,
})
