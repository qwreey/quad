--!strict
--[[
	NumberField — a `TextField` whose value is a NUMBER. Not a Material 3 component (Compose gets there with keyboard
	options and input transformations, MDC with `inputType` — neither exists on Roblox): a kit addition on top of
	`TextField` and `Unit` (user decision 2026-10-13).

	    local price = q.Source(1999)                                             -- cents, an integer
	    NumberField({ Label = "Price", Value = price, Unit = { Scale = 0.01, Prefix = "$" }, Min = 0, Step = 1 })
	    -- shows "$" as the field's prefix and "19.99" as the text; typing "5" and leaving the field writes 500

	The text is FREE while the field is focused — nothing is rewritten under the caret. It is COMMITTED when the field
	loses focus (Enter included): the text is read back through the unit (`Unit.parse`: the prefix / suffix and spaces
	are optional), snapped to `Step`, clamped to `Min` / `Max`, written to `Value` when it differs, and the text is
	tidied to the unit's precision. A text that is not a number writes nothing and turns the field to its error look
	until the next edit; an EMPTY text is not an error — the field goes back to showing the current value.

	Props (all `read`) — the `TextField` props (`./TextField`) with these differences:
	  Value      Source<number>?     the number (nil = an own Source at `Min`, or 0). A programmatic `Value:Set` rewrites
	                                 the text unless the field is focused (then at the next commit, if still in force)
	  Unit       Unit?               (`./Unit.luau`) how the number is shown and read back; default { Scale = 1, Decimals
	                                 = 0 } with a `Step`-less field showing up to 6 decimals of what was typed. The
	                                 unit's Prefix / Suffix become the field's `Prefix` / `Suffix` (unless those props are
	                                 given), so the editable text is the bare number
	  Min, Max   number?             clamp (Max must be >= Min when both are given)
	  Step       number?             snaps to Min + n * Step (0 + n * Step without a Min); positive
	  OnChange   ((value: number) -> ())?    after a USER commit that changed the value — not on a programmatic Set
	  OnSubmit   ((value: number) -> ())?    after the commit of an Enter (the value, changed or not; not when the text
	                                         was not a number)
	  Error / ErrorText              as TextField; the field's own "not a number" state is OR-ed into `Error`
	  InvalidText   (string | State<string>)?   shown as the error text while the typed text is not a number (default:
	                                            `ErrorText`, else nothing — only the error colors)
	Not taken from TextField: `MultiLine`, `Height`, `MaxLength`, `ShowCounter` (a number has no counter).
	Returns the host `Frame` (the TextField's).
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Util = require("./Util")
local Unit = require("./Unit")
local TextField = require("./TextField")

export type Props = {
	read Variant: TextField.Variant?,
	read Label: (string | q.State<string>)?,
	read Value: q.Source<number>?,
	read Unit: Unit.Unit?,
	read Min: number?,
	read Max: number?,
	read Step: number?,
	read Placeholder: string?,
	read SupportingText: (string | q.State<string>)?,
	read Error: (boolean | q.State<boolean>)?,
	read ErrorText: (string | q.State<string>)?,
	read InvalidText: (string | q.State<string>)?,
	read LeadingIcon: string?,
	read TrailingIcon: string?,
	read Prefix: string?,
	read Suffix: string?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((value: number) -> ())?,
	read OnSubmit: ((value: number) -> ())?,
	read OnFocusChanged: ((focused: boolean) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local PLAIN: Unit.Unit = table.freeze({ Scale = 1, Decimals = 0 })

-- without a unit and without a step: what was typed, up to 6 decimals, no trailing zeros
local function plainText(value: number): string
	local text = string.format("%.6f", value)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	if text == "-0" then
		text = "0"
	end
	return text
end

local function NumberField(props: Props): Frame
	local unit = props.Unit
	if unit ~= nil then
		Unit.check(unit, 2)
	end
	local min, max, step = props.Min, props.Max, props.Step
	if min ~= nil and max ~= nil and max < min then
		error("NumberField: Max must not be less than Min", 2)
	end
	if step ~= nil and not (step > 0) then
		error("NumberField: Step must be positive", 2)
	end

	-- the editable text is the bare number: the unit without its prefix / suffix
	local bare: Unit.Unit? = if unit ~= nil then { Scale = unit.Scale, Decimals = unit.Decimals } else nil
	local function show(value: number): string
		if bare ~= nil then
			return Unit.format(bare, value)
		elseif step ~= nil then
			return Unit.format(PLAIN, value)
		end
		return plainText(value)
	end
	local function settle(value: number): number
		if step ~= nil then
			local origin = min or 0
			value = origin + math.floor((value - origin) / step + 0.5) * step
		end
		if min ~= nil and value < min then
			value = min
		end
		if max ~= nil and value > max then
			value = max
		end
		return value
	end

	local value: q.Source<number> = props.Value or q.Source(min or 0)
	local text = q.Source(show(value:Get()))
	local invalid = q.Source(false)
	local focused = false

	-- a programmatic Set shows at once, except under the caret
	local follow = value:Observer(function(self: q.StateData<number>)
		if not focused then
			text:SetIfChanged(show(self:Get()))
		end
	end)

	local function commit(): boolean
		local typed = text:Get()
		if string.match(typed, "^%s*$") ~= nil then
			invalid:SetIfChanged(false)
			text:SetIfChanged(show(value:Get()))
			return true
		end
		local parsed = Unit.parse(unit or PLAIN, typed)
		if parsed == nil then
			invalid:SetIfChanged(true)
			return false
		end
		invalid:SetIfChanged(false)
		local settled = settle(parsed)
		local changed = settled ~= value:Get()
		if changed then
			value:Set(settled)
		end
		text:SetIfChanged(show(settled))
		if changed and props.OnChange then
			props.OnChange(settled)
		end
		return true
	end

	local external = props.Error
	local errorState: q.State<boolean> = if external == nil
		then invalid
		elseif type(external) == "boolean" then invalid:Compute(function(self: q.StateData<boolean>): boolean
			return external or self:Get()
		end)
		else invalid:Compute(function(self: q.StateData<boolean>, _prev: boolean?, ext: q.State<boolean>): boolean
			return ext:Get() or self:Get()
		end, external)

	local committed = true
	local hooks: Util.Hooks = table.clone(Util.hooks(props.Hooks))
	table.insert(hooks, follow)
	return TextField({
		Variant = props.Variant,
		Label = props.Label,
		Value = text,
		Placeholder = props.Placeholder,
		SupportingText = props.SupportingText,
		Error = errorState,
		ErrorText = if props.InvalidText ~= nil then props.InvalidText else props.ErrorText,
		LeadingIcon = props.LeadingIcon,
		TrailingIcon = props.TrailingIcon,
		Prefix = if props.Prefix ~= nil then props.Prefix elseif unit ~= nil then unit.Prefix else nil,
		Suffix = if props.Suffix ~= nil then props.Suffix elseif unit ~= nil then unit.Suffix else nil,
		Disabled = props.Disabled,
		-- an edit clears the "not a number" look: the user is fixing it
		OnChange = function(_typed: string)
			invalid:SetIfChanged(false)
		end,
		OnFocusChanged = function(isFocused: boolean)
			focused = isFocused
			if not isFocused then
				committed = commit()
			end
			if props.OnFocusChanged then
				props.OnFocusChanged(isFocused)
			end
		end,
		-- TextField calls OnFocusChanged(false) first, so the commit has run
		OnSubmit = function(_typed: string)
			if committed and props.OnSubmit then
				props.OnSubmit(value:Get())
			end
		end,
		Theme = props.Theme,
		Modifier = props.Modifier,
		Hooks = hooks,
	})
end

return NumberField
