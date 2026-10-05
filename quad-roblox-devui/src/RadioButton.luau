--!strict
--[[
	RadioButton (Iris: RadioButton) — a round box with a dot and a label. A group is several RadioButtons that share
	one Source; each is selected while `Value:Get() == Option`.

		RadioButton<T> {
			Text: string | State<string>,
			Value: Source<T>,                      the shared selection of the group (required — a lone radio makes no sense)
			Option: T,                             what this button selects (compared with ==)
			OnChange: ((option: T) -> ())?,        after the user selected this option (not when it was already selected)
			Disabled: (boolean | State<boolean>)?,
			Hooks: { any }?,                       appended at the end of the element's array part (see Button)
			Style: Style?, Modifier: TextButtonModifier?,
		}

		local pick = q.Source("a")
		Devui.RadioButton<<string>> { Text = "A", Value = pick, Option = "a" }
		Devui.RadioButton<<string>> { Text = "B", Value = pick, Option = "b" }

	The type argument is REQUIRED in strict code: the solver cannot infer `T` from a `Source<T>` argument (a call without
	it fails with "No valid instantiation could be inferred").

	One TextButton + box Frame + dot Frame (Input/Choice.luau). Clicking the selected button does nothing.
]]

local Quad = require("./Quad")
local Choice = require("./Input/Choice")
local Common = require("./Common")
local Style = require("./Style")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type RadioButtonProps<T> = {
	read Text: string | State<string>,
	read Value: Source<T>,
	read Option: T,
	read OnChange: ((option: T) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Hooks: { any }?,
	read Style: Style?,
	read Modifier: Quad.TextButtonModifier?,
}

local function RadioButton<T>(props: RadioButtonProps<T>): TextButton
	local value = props.Value
	local option = props.Option
	local onChange = props.OnChange
	local selected: State<boolean> = value:Compute(function(self)
		return self:Get() == option
	end)
	return Choice.build({
		Name = "RadioButton",
		Text = props.Text,
		Selected = selected,
		Enabled = Common.enabled(props.Disabled),
		Round = true,
		OnActivate = function()
			if value:Get() ~= option then
				value:Set(option)
				if onChange then
					onChange(option)
				end
			end
		end,
		Style = props.Style or Style.default,
		Modifier = props.Modifier,
		Hooks = props.Hooks,
	})
end

return RadioButton
