--!strict
-- Layout: SameLine (Spacing), Group, Indent (Width), Separator, SeparatorText. Spacing / Width are plain construction
-- values, so those rows are rebuilt (StoryKit.rebuild) when their control moves; the heading text is a live Source.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Heading = "Section",
		Spacing = StoryKit.Slider(8, 0, 40, 1),
		IndentWidth = StoryKit.Slider(20, 0, 60, 1),
	},
	render = function(c)
		local row = StoryKit.rebuild(c.Spacing, function(spacing: any)
			return Devui.SameLine({
				Spacing = spacing,
				Children = Kids(
					Devui.SmallButton({ Text = "one" }),
					Devui.SmallButton({ Text = "two" }),
					Devui.SmallButton({ Text = "three" })
				),
			})
		end)
		local indent = StoryKit.rebuild(c.IndentWidth, function(width: any)
			return Devui.Group({
				Children = Kids(
					Devui.Text({ Text = "not indented" }),
					Devui.Indent({
						Width = width,
						Children = Kids(Devui.Text({ Text = "indented" }), Devui.Indent({ Children = Kids(Devui.Text({ Text = "nested (default width)" })) })),
					})
				),
			})
		end)
		return Devui.Window({
			Title = "Layout",
			Size = q.Source(Vector2.new(300, 260)),
			Children = Kids(
				Devui.SeparatorText({ Text = c.Heading }),
				row,
				Devui.Separator({}),
				indent
			),
		})
	end,
})
