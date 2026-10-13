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
	until the next edit; an EMPTY text is not an error — the field goes back to showing the current value. Leaving the
	field WITHOUT having edited the text commits nothing (the value is not rounded to what the text shows, `OnChange`
	is not called): the text is only rewritten from the value.

	Props (all `read`) — the `TextField` props (`./TextField`) with these differences:
	  Value      Source<number>?     the number (nil = an own Source at `Min`, or 0). A programmatic `Value:Set` rewrites
	                                 the text unless the field is focused; then leaving the field shows it — unless the
	                                 user typed meanwhile, in which case the typed text is committed over it
	  Unit       Unit?               (`./Unit.luau`) how the number is shown and read back. Without one: a `Step` sets the
	                                 decimals shown (Step 0.5 -> one, a whole Step -> none), and with neither the text
	                                 is the value with up to 6 decimals. With a unit and no `Step` a typed number is
	                                 stored at the unit's precision. The unit's Prefix / Suffix become the field's
	                                 `Prefix` / `Suffix` (unless those props are given), so the editable text is the
	                                 bare number
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
	-- a Step alone sets the precision too: Step 0.5 shows one decimal ("2.5", not "2" — which the next commit
	-- would have written back as 2), Step 0.25 two; a whole Step none
	local stepUnit: Unit.Unit? = nil
	if step ~= nil and bare == nil then
		local decimals = 0
		while decimals < 6 and math.abs(step * 10 ^ decimals - math.floor(step * 10 ^ decimals + 0.5)) > 1e-9 do
			decimals += 1
		end
		stepUnit = if decimals == 0 then PLAIN else { Scale = 1, Decimals = decimals }
	end
	local function show(value: number): string
		if bare ~= nil then
			return Unit.format(bare, value)
		elseif stepUnit ~= nil then
			return Unit.format(stepUnit, value)
		end
		return plainText(value)
	end
	local function settle(value: number): number
		if step ~= nil then
			local origin = min or 0
			value = origin + math.floor((value - origin) / step + 0.5) * step
		elseif bare ~= nil then
			-- a unit without a Step: the unit's precision is the step — "37.255" at two decimals is stored as what
			-- the field then shows ("37.26" -> 3726), not as 3725.5 that the next commit would change again
			value = Unit.parse(bare, Unit.format(bare, value)) or value
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
	-- the text was edited by the USER since it was last written from the value: only then does leaving the field
	-- commit. Otherwise a focus alone would write the value back through the text — a value finer than the text shows
	-- (0.12345 shown "0.12") would be rounded, a programmatic Set made during the focus would be undone, and OnChange
	-- would fire for a change the user did not make.
	local edited = false

	-- a programmatic Set shows at once, except under the caret
	local follow = value:Observer(function(self: q.StateData<number>)
		if not focused then
			text:SetIfChanged(show(self:Get()))
		end
	end)

	local function commit(): boolean
		local typed = text:Get()
		if not edited or string.match(typed, "^%s*$") ~= nil then
			edited = false
			invalid:SetIfChanged(false)
			text:SetIfChanged(show(value:Get()))
			return true
		end
		edited = false
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

	-- the field's own "not a number" shows InvalidText; an external Error shows ErrorText (InvalidText falls back to it)
	local errorText: (string | q.State<string>)? = props.ErrorText
	if props.InvalidText ~= nil then
		local invalidText = Util.asStringState(props.InvalidText)
		local outer = Util.asStringState(props.ErrorText)
		errorText = invalid:Compute(function(self: q.StateData<boolean>, _prev: string?, own: q.State<string>, other: q.State<string>): string
			return if self:Get() then own:Get() else other:Get()
		end, invalidText, outer)
	end

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
		ErrorText = errorText,
		LeadingIcon = props.LeadingIcon,
		TrailingIcon = props.TrailingIcon,
		Prefix = if props.Prefix ~= nil then props.Prefix elseif unit ~= nil then unit.Prefix else nil,
		Suffix = if props.Suffix ~= nil then props.Suffix elseif unit ~= nil then unit.Suffix else nil,
		Disabled = props.Disabled,
		-- an edit clears the "not a number" look: the user is fixing it
		OnChange = function(_typed: string)
			edited = true
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
