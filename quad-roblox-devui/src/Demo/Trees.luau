--!strict
--[[
	Demo section "Trees & Tabs" — Tree / CollapsingHeader nesting and a TabBar whose pages keep their state when hidden.
	Closed tree children stay mounted (Visible = false) — see Tree.luau — so the checkbox inside "Node B" keeps its value
	across a collapse.
]]

local Devui = require("./Kit")
local Context = require("./Context")
local q = require("../Quad")

type Context = Context.Context

local Kids = Devui.Kids

local function Trees(ctx: Context): Instance
	local style = ctx.Style
	local tab = q.Source("counter")
	local nodeOpen = q.Source(false)
	local innerCheck = q.Source(false)
	local counterText: q.State<string> = ctx.Counter:Compute(function(self)
		return `shared counter = {self:Get()}`
	end)
	local openText: q.State<string> = nodeOpen:Compute(function(self)
		return if self:Get() then "Node A is open (a Source you can set from outside)" else "Node A is closed"
	end)

	return Devui.CollapsingHeader({
		Text = "Trees & Tabs",
		Style = style,
		Children = Kids(
			Devui.Tree({
				Text = "Node A",
				Open = nodeOpen,
				Style = style,
				Children = Kids(
					Devui.Text({ Text = "leaf 1", Style = style }),
					Devui.Tree({
						Text = "Node B",
						Style = style,
						Children = Kids(
							Devui.Checkbox({ Text = "survives collapsing", Value = innerCheck, Style = style }),
							Devui.Text({ Text = "leaf 2", Style = style })
						),
					})
				),
			}),
			Devui.TextDisabled({ Text = openText, Style = style }),
			Devui.Button({
				Text = "Toggle Node A from outside",
				Style = style,
				OnClick = function()
					nodeOpen:Set(not nodeOpen:Get())
				end,
			}),
			Devui.Tree({
				Text = "Tree SpanAvailWidth",
				SpanAvailWidth = true,
				Style = style,
				Children = Kids(Devui.Text({ Text = "the whole header row is the hit area", Style = style })),
			}),
			Devui.CollapsingHeader({
				Text = "A nested CollapsingHeader",
				Style = style,
				Children = Kids(Devui.Text({ Text = "children are not indented here", Style = style })),
			}),
			Devui.SeparatorText({ Text = "TabBar", Style = style }),
			Devui.TabBar<<string>>({
				Selected = tab,
				Style = style,
				Tabs = {
					Devui.Tab<<string>>({
						Key = "counter",
						Text = "Counter",
						Children = Kids(
							Devui.Text({ Text = counterText, Style = style }),
							Devui.Button({
								Text = "+1",
								Style = style,
								OnClick = function()
									ctx.Counter:Set(ctx.Counter:Get() + 1)
								end,
							})
						),
					}),
					Devui.Tab<<string>>({
						Key = "name",
						Text = "Name",
						Children = Kids(Devui.InputText({ Text = "shared name", Value = ctx.Name, Style = style })),
					}),
					Devui.Tab<<string>>({
						Key = "about",
						Text = "About",
						Children = Kids(Devui.TextWrapped({ Text = "Pages are Visible only while selected; their widgets stay mounted.", Style = style })),
					}),
				},
			})
		),
	})
end

return Trees
