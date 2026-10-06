--!strict
--[[
	M3 exposed dropdown ("select"): a read-only TextField (with a dropdown arrow) that opens a `Menu` under
	the field. The chosen option is highlighted in the menu.

	    local choice = q.Source<<string?>>(nil)
	    Select({ Label = "Fruit", Options = { "Apple", "Pear", "Plum" }, Value = choice })
	    Select({ Variant = "Outlined", Label = "Unit", Options = unitsState, Value = unit,
	             Format = function(u: Unit) return u.Name end })

	Props (all `read`; generic in the option type `T`)
	  Options    { T } | State<{ T }>     read when the menu opens (a State is read at that moment, not tracked live)
	  Value      Source<T?>               two-way: shows `Format(value)`, an item click writes the option
	  OnChange   ((option: T) -> ())?     after a USER pick (an item click), not on programmatic Value writes
	  Format     ((T) -> string)?         default `tostring`
	  Label, Variant, Placeholder, SupportingText, Error, ErrorText, LeadingIcon, Disabled, Theme, Modifier, NotchColor, Hooks
	             as TextField (Variant "Filled" | "Outlined")
	  Overlay    Overlay.Overlay?         default `Overlay.default()`
	  MaxMenuHeight number?               the list scrolls past this
	Returns the TextField host `Frame`.

	Behavior: clicking (or gamepad A on) the field opens the menu with the field's width, below the field
	container (above if there is no room). The field shows the focused look (primary indicator/outline, floated
	label) while the menu is open. Selecting writes the option and closes; an outside click closes without
	changing. Options are compared with `==` for the highlight.
	The arrow is a text glyph (`Icons.glyph("arrowDown")` through `TextField` `TrailingGlyph`) because the kit ships no icon
	assets; register an image with `Icons.override({ arrowDown = "rbxassetid://..." })` and it becomes a `TrailingIcon`. The arrow does not rotate while open.
	Not implemented: typing to filter (that is the autocomplete variant), keyboard open/arrow keys.
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Util = require("./Util")
local Menu = require("./Menu")
local Icons = require("./Icons")
local Overlay = require("./Overlay")
local Field = require("./TextField/Field")

export type Props<T> = {
	read Options: { T } | q.State<{ T }>,
	read Value: q.Source<T?>,
	read OnChange: ((option: T) -> ())?,
	read Format: ((option: T) -> string)?,
	read Label: (string | q.State<string>)?,
	read Variant: Field.Variant?,
	read Placeholder: string?,
	read SupportingText: (string | q.State<string>)?,
	read Error: (boolean | q.State<boolean>)?,
	read ErrorText: (string | q.State<string>)?,
	read LeadingIcon: string?,
	read Disabled: (boolean | q.State<boolean>)?,
	read NotchColor: (Color3 | q.State<Color3>)?,
	read Overlay: Overlay.Overlay?,
	read MaxMenuHeight: number?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local function Select<T>(props: Props<T>): Frame
	local format: (T) -> string = props.Format or function(o: T): string
		return tostring(o)
	end
	local value = props.Value
	local open = q.Source(false)

	local display: q.State<string> = value:Compute(function(self)
		local v = self:Get()
		if v == nil then
			return ""
		end
		return format(v)
	end)

	local function currentOptions(): { T }
		local opts = props.Options
		if q.isState(opts) then
			return (opts :: q.State<{ T }>):Get()
		end
		return opts :: { T }
	end

	local parts: Field.Parts
	parts = Field.build({
		Variant = props.Variant,
		Label = props.Label,
		Text = display,
		Placeholder = props.Placeholder,
		SupportingText = props.SupportingText,
		Error = props.Error,
		ErrorText = props.ErrorText,
		LeadingIcon = props.LeadingIcon,
		TrailingIcon = Icons.asset("arrowDown"),
		TrailingGlyph = Icons.glyph("arrowDown"),
		Disabled = props.Disabled,
		ForceFocused = open,
		NotchColor = props.NotchColor,
		Theme = props.Theme,
		Modifier = props.Modifier,
		Hooks = props.Hooks,
		OnClick = function()
			if open:Get() then
				return
			end
			local current = value:Get()
			local entries: { Menu.Entry } = {}
			for _, option in currentOptions() do
				local chosen = option
				table.insert(entries, {
					Label = format(chosen),
					Selected = chosen == current,
					OnClick = function()
						value:Set(chosen)
						if props.OnChange then
							props.OnChange(chosen)
						end
					end,
				})
			end
			-- flag AFTER the menu opened: a dead overlay makes Menu.open throw, and the field must not stay "open"
			-- the field's own width (Menu's default clamps an anchor's width to 112..280; a select menu matches its field)
			local fieldWidth = parts.Container.AbsoluteSize.X
			Menu.open({
				Anchor = parts.Container,
				Width = if fieldWidth > 0 then fieldWidth else nil,
				Items = entries,
				Overlay = props.Overlay,
				Theme = props.Theme,
				MaxHeight = props.MaxMenuHeight,
				OnClose = function()
					open:Set(false)
				end,
			})
			open:Set(true)
		end,
	})
	return parts.Host
end

return Select
