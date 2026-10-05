--!strict
--[[
	Demo section "Basic" — text, buttons, checkbox, radio buttons, selectables, layout helpers, tooltips.
	Everything is live: the counter button feeds a label, the checkbox drives a label, one Source is shared by the radio
	group, the selectables and the readout under them.
]]

local Devui = require("./Kit")
local Context = require("./Context")
local q = require("../Quad")

type Context = Context.Context

local Kids = Devui.Kids

local function Basic(ctx: Context): Instance
	local style = ctx.Style
	local counter = ctx.Counter
	local checked = q.Source(true)
	local flavor = q.Source("vanilla")
	local pickedRow = q.Source("alpha")
	local toggled = q.Source(false)

	local counterText: q.State<string> = counter:Compute(function(self)
		return `Clicked {self:Get()} times`
	end)
	local checkText: q.State<string> = checked:Compute(function(self)
		return if self:Get() then "the checkbox is ON" else "the checkbox is off"
	end)
	local flavorText: q.State<string> = flavor:Compute(function(self)
		return `flavor = {self:Get()}`
	end)
	local rowText: q.State<string> = pickedRow:Compute(function(self)
		return `selected row = {self:Get()}`
	end)
	local toggledText: q.State<string> = toggled:Compute(function(self)
		return if self:Get() then "toggle row: selected" else "toggle row: not selected"
	end)

	local saveTip = Devui.Tooltip({ Text = "Hover for 0.5 s: a plain text tooltip.", Style = style, Overlay = ctx.Overlay })
	local richTip = Devui.Tooltip({
		Style = style,
		Overlay = ctx.Overlay,
		Delay = 0.2,
		Content = function()
			return Devui.Group({
				Style = style,
				Children = Kids(
					Devui.TextColored({ Text = "A factory-built tooltip", Color = Color3.fromRGB(250, 200, 80), Style = style }),
					Devui.Text({ Text = counterText, Style = style })
				),
			})
		end,
	})

	return Devui.CollapsingHeader({
		Text = "Basic widgets",
		Style = style,
		Open = q.Source(true),
		Children = Kids(
			Devui.SeparatorText({ Text = "Text", Style = style }),
			Devui.Text({ Text = "Text — one line.", Style = style }),
			Devui.TextWrapped({ Text = "TextWrapped wraps at the available width, so a long sentence like this one keeps growing downwards instead of running out of the window.", Style = style }),
			Devui.TextColored({ Text = "TextColored", Color = Color3.fromRGB(255, 120, 120), Style = style }),
			Devui.TextDisabled({ Text = "TextDisabled", Style = style }),
			Devui.LabelText({ Label = "label", Text = "value (LabelText)", Style = style }),
			Devui.SeparatorText({ Text = "Buttons", Style = style }),
			Devui.SameLine({
				Style = style,
				Children = Kids(
					Devui.Button({
						Text = "Count up",
						Style = style,
						Hooks = { saveTip.Hook },
						OnClick = function()
							counter:Set(counter:Get() + 1)
						end,
					}),
					Devui.SmallButton({
						Text = "reset",
						Style = style,
						Hooks = { richTip.Hook },
						OnClick = function()
							counter:Set(0)
						end,
					}),
					Devui.Text({ Text = counterText, Style = style })
				),
			}),
			Devui.SeparatorText({ Text = "Checkbox / RadioButton", Style = style }),
			Devui.Checkbox({ Text = "Enable the thing", Value = checked, Style = style }),
			Devui.TextDisabled({ Text = checkText, Style = style }),
			Devui.Checkbox({ Text = "Disabled checkbox", Disabled = true, Style = style }),
			Devui.Group({
				Style = style,
				Children = Kids(
					Devui.RadioButton<<string>>({ Text = "vanilla", Value = flavor, Option = "vanilla", Style = style }),
					Devui.RadioButton<<string>>({ Text = "chocolate", Value = flavor, Option = "chocolate", Style = style }),
					Devui.RadioButton<<string>>({ Text = "mint", Value = flavor, Option = "mint", Style = style })
				),
			}),
			Devui.TextDisabled({ Text = flavorText, Style = style }),
			Devui.SeparatorText({ Text = "Selectable", Style = style }),
			Devui.SelectableOption<<string>>({ Text = "alpha", Value = pickedRow, Option = "alpha", Style = style }),
			Devui.SelectableOption<<string>>({ Text = "beta", Value = pickedRow, Option = "beta", Style = style }),
			Devui.SelectableOption<<string>>({ Text = "gamma", Value = pickedRow, Option = "gamma", Style = style }),
			Devui.TextDisabled({ Text = rowText, Style = style }),
			Devui.Selectable({ Text = "a toggle row (click flips it)", Selected = toggled, Style = style }),
			Devui.TextDisabled({ Text = toggledText, Style = style }),
			Devui.SeparatorText({ Text = "Layout", Style = style }),
			Devui.Indent({
				Style = style,
				Children = Kids(
					Devui.Text({ Text = "Indent", Style = style }),
					Devui.Indent({ Style = style, Children = Kids(Devui.Text({ Text = "Indent, nested", Style = style })) })
				),
			}),
			Devui.Separator({ Style = style }),
			Devui.SameLine({
				Style = style,
				Children = Kids(
					Devui.Group({
						Style = style,
						Children = Kids(Devui.Text({ Text = "Group A", Style = style }), Devui.Text({ Text = "second line", Style = style })),
					}),
					Devui.Group({
						Style = style,
						Children = Kids(Devui.Text({ Text = "Group B", Style = style }), Devui.Text({ Text = "second line", Style = style })),
					})
				),
			})
		),
	})
end

return Basic
