--!strict
--[[
	Checkbox (Iris: Checkbox) — a square box with a check mark and a label, bound to a boolean Source.

		Checkbox {
			Text: string | State<string>,
			Value: Source<boolean>?,               two-way; an internal Source (false) when omitted
			OnChange: ((checked: boolean) -> ())?, after Value was toggled by the user (not for external :Set)
			Disabled: (boolean | State<boolean>)?,
			Hooks: { any }?,                       appended at the end of the element's array part (see Button)
			Style: Style?, Modifier: TextButtonModifier?,
		}

	One TextButton (the whole row is clickable) + box Frame + check ImageLabel — see Inputs/Choice.luau. Activated
	(mouse, touch, gamepad) toggles; hover/press colours follow the FrameBg tokens; the mark follows `Value`.
]]

local Quad = require("./Quad")
local q = Quad
local Choice = require("./Inputs/Choice")
local Common = require("./Common")
local Style = require("./Style")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type CheckboxProps = {
	read Text: string | State<string>,
	read Value: Source<boolean>?,
	read OnChange: ((checked: boolean) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Hooks: { any }?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<TextButton>?,
}

local function Checkbox(props: CheckboxProps): TextButton
	local value: Source<boolean> = props.Value or q.Source(false)
	local onChange = props.OnChange
	return Choice.build({
		Name = "Checkbox",
		Text = props.Text,
		Selected = value,
		Enabled = Common.enabled(props.Disabled),
		Round = false,
		OnActivate = function()
			local checked = not value:Get()
			value:Set(checked)
			if onChange then
				onChange(checked)
			end
		end,
		Style = props.Style or Style.default,
		Modifier = props.Modifier,
		Hooks = props.Hooks,
	})
end

return Checkbox
