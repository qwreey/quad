--!strict
-- MenuBar / Menu / MenuItem / MenuToggle (with a submenu). Menus open in the story overlay. Disabled is a control Source.
local Devui = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local Shared = require("./Shared")
local Kids = Devui.Kids

return StoryKit.story({
	controls = {
		Disabled = false,
		Title = "File",
	},
	render = function(c, ctx)
		local last = q.Source("(nothing yet)")
		local grid = q.Source(true)
		local function chose(name: string)
			return function()
				last:Set(name)
			end
		end
		local bar = Devui.MenuBar({
			Children = Kids(
				Devui.Menu({
					Text = c.Title,
					Disabled = c.Disabled,
					Overlay = ctx.Overlay,
					Children = function(scope)
						return Kids(
							Devui.MenuItem({ Text = "Open", Shortcut = "Ctrl+O", Scope = scope, OnClick = chose("Open") }),
							Devui.MenuItem({ Text = "Save", Shortcut = "Ctrl+S", Scope = scope, OnClick = chose("Save") }),
							Devui.MenuItem({ Text = "Disabled item", Disabled = true, Scope = scope, OnClick = chose("never") }),
							Devui.Menu({
								Text = "Recent",
								Scope = scope,
								Children = function(sub)
									return Kids(
										Devui.MenuItem({ Text = "a.txt", Scope = sub, OnClick = chose("a.txt") }),
										Devui.MenuItem({ Text = "b.txt", Scope = sub, OnClick = chose("b.txt") })
									)
								end,
							})
						)
					end,
				}),
				Devui.Menu({
					Text = "View",
					Overlay = ctx.Overlay,
					Children = function(scope)
						return Kids(Devui.MenuToggle({ Text = "Show grid", Value = grid, Shortcut = "G", Scope = scope }))
					end,
				})
			),
		})
		return Devui.Window({
			Title = "Menu",
			Size = q.Source(Vector2.new(340, 220)),
			Children = Kids(
				bar,
				Devui.Text({ Text = "Open a menu from the bar." }),
				Shared.show("last chosen", last),
				Shared.show("grid", grid)
			),
		})
	end,
})
