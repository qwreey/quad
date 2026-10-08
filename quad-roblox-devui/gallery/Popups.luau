--!strict
--[[
	Demo section "Popups" — Combo / ComboArray / ComboEnum (list drawn in the Overlay layer) and a nested Menu opened
	from a button-like bar inside the section. Tooltips are in "Basic widgets".
]]

local Devui = require("../src")
local Context = require("./Context")
local q = require("./Quad")

type Context = Context.Context

local Kids = Devui.Kids

local function Popups(ctx: Context): Instance
	local style = ctx.Style
	local overlay = ctx.Overlay
	local fruit = q.Source("apple")
	local sizeIndex = q.Source(2)
	local easing = q.Source<<EnumItem>>(Enum.EasingStyle.Quad)
	local lastAction = q.Source("(nothing yet)")
	local verbose = q.Source(false)

	local fruitText: q.State<string> = fruit:Compute(function(self)
		return `fruit = {self:Get()}`
	end)
	local sizeText: q.State<string> = sizeIndex:Compute(function(self)
		return `size index = {self:Get()}`
	end)
	local easingText: q.State<string> = easing:Compute(function(self)
		return `easing = {tostring(self:Get())}`
	end)
	local actionText: q.State<string> = lastAction:Compute(function(self, _prev, isVerbose)
		return `last menu action: {self:Get()}{if isVerbose:Get() then " (verbose on)" else ""}`
	end, verbose)

	local function act(name: string): () -> ()
		return function()
			lastAction:Set(name)
		end
	end

	return Devui.CollapsingHeader({
		Text = "Popups",
		Style = style,
		Children = Kids(
			Devui.Combo<<string>>({ Text = "fruit", Value = fruit, Options = { "apple", "banana", "cherry", "date" }, Overlay = overlay, Style = style }),
			Devui.TextDisabled({ Text = fruitText, Style = style }),
			Devui.ComboArray<<string>>({ Text = "size", Index = sizeIndex, Options = { "small", "medium", "large" }, Overlay = overlay, Style = style }),
			Devui.TextDisabled({ Text = sizeText, Style = style }),
			Devui.ComboEnum({ Text = "Enum.EasingStyle", Value = easing, Enum = Enum.EasingStyle, Overlay = overlay, Style = style }),
			Devui.TextDisabled({ Text = easingText, Style = style }),
			Devui.SeparatorText({ Text = "Menu", Style = style }),
			Devui.MenuBar({
				Style = style,
				Children = Kids(
					Devui.Menu({
						Text = "Actions",
						Overlay = overlay,
						Style = style,
						Children = function(scope)
							return Kids(
								Devui.MenuItem({ Text = "Run", Shortcut = "F5", Scope = scope, Style = style, OnClick = act("Run") }),
								Devui.MenuToggle({ Text = "Verbose", Value = verbose, Scope = scope, Style = style }),
								Devui.MenuItem({ Text = "Locked", Disabled = true, Scope = scope, Style = style, OnClick = act("Locked") }),
								Devui.Menu({
									Text = "More",
									Scope = scope,
									Overlay = overlay,
									Style = style,
									Children = function(sub)
										return Kids(
											Devui.MenuItem({ Text = "Stop", Scope = sub, Style = style, OnClick = act("Stop") }),
											Devui.MenuItem({ Text = "Reset", Scope = sub, Style = style, OnClick = act("Reset") })
										)
									end,
								})
							)
						end,
					})
				),
			}),
			Devui.TextDisabled({ Text = actionText, Style = style })
		),
	})
end

return Popups
