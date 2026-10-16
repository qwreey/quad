--!strict
--[[
	InputMode: the text-entry panel of the modal date picker (M3 "input mode"): an outlined field that parses
	what the user types with `Calendar.parseLocalized` and writes the picked date into `Draft`.

	    local panel = InputMode.new({ Draft = draft, Error = err, Locale = "ko", Min = min, Max = max })
	    panel.Frame            the panel (360 x 396, same as the calendar body so the modal keeps its size)
	    panel.Sync()           reload the field from `Draft` (call when switching calendar -> input)

	Behaviour
	  * every keystroke is parsed (an Effect over the text Source the TextField writes back to):
	      empty                 Draft := nil, no error (the modal's OK stays disabled: nothing picked)
	      unparseable           Error := strings.ErrInvalid     (Draft keeps its last valid value)
	      parsed, out of [Min, Max]      Error := ErrRange
	      parsed, IsDisabled(date)       Error := ErrDisabled
	      valid                 Error := nil, Draft := date (only when it differs, so no churn per keystroke)
	  * accepted forms are Calendar.parseLocalized's: 2026-10-05, 2026/10/5, 2026.10.5, 2026년 10월 5일,
	    "Oct 5, 2026" in English. The field shows ISO `YYYY-MM-DD`.
	  * the field is the kit's Outlined `TextField` (TextField/init.luau): the "Date" label floats in the outline, the
	    format hint is its `Placeholder` (fades in on focus, out on blur — TextField/Field.luau PLACEHOLDER), the
	    supporting row shows the hint, or the error text in the error color while `Error` holds one (error outline).
	Canon: Compose `DateInput.kt` (androidx@26506f4) — `DateInputTextField` is an `OutlinedTextField` with
	`label = DateInputLabel` and `placeholder = dateInputFormat.patternWithDelimiters.uppercase()`.
	Deviations: Compose's supporting text is the error only (the hint lives in the placeholder and the label's
	semantics); the kit keeps the hint in the supporting row too. Compose pads the field 24 / 24 / 10; the kit keeps 16
	(the panel's former layout).
	Instances: 27 — the panel + its TextField (Outlined + label: 22 incl. its host, + the Placeholder label, the error
	mark, the supporting TextLabel + UIPadding); asserted in spec.datepicker.
]]

local q = require("../Quad")
local Util = require("../Util")
local Theme = require("../Theme")
local TextField = require("../TextField")
local Calendar = require("./Calendar")
local Strings = require("./Strings")
local D = q.Declaration

type Date = Calendar.Date
type State<T> = q.State<T>

export type Options = {
	Draft: q.Source<Date?>,
	Error: q.Source<string?>,
	Locale: string,
	Min: Date?,
	Max: Date?,
	IsDisabled: ((date: Date) -> boolean)?,
	Theme: Theme.Theme?,
	Width: number,
	Height: number,
	Visible: (boolean | State<boolean>)?,
	Position: UDim2?,
}

export type InputMode = {
	read Frame: Frame,
	Sync: () -> (),
}

local function trim(s: string): string
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function new(o: Options): InputMode
	local strings = Strings.get(o.Locale)
	local draft, err = o.Draft, o.Error
	local initial = draft:Get()
	local text = q.Source(if initial ~= nil then Calendar.formatISO(initial) else "")

	local validate = q.Effect(function()
		local t = trim(text:Get())
		if t == "" then
			err:SetIfChanged(nil)
			if draft:Get() ~= nil then
				draft:Set(nil)
			end
			return
		end
		local d = Calendar.parseLocalized(t, o.Locale)
		if d == nil then
			err:SetIfChanged(strings.ErrInvalid)
		elseif not Calendar.isInRange(d, o.Min, o.Max) then
			err:SetIfChanged(strings.ErrRange)
		elseif o.IsDisabled ~= nil and o.IsDisabled(d) then
			err:SetIfChanged(strings.ErrDisabled)
		else
			err:SetIfChanged(nil)
			local cur = draft:Get()
			if cur == nil or not Calendar.equals(cur, d) then
				draft:Set(d)
			end
		end
	end, text)

	local isError: State<boolean> = err:Compute(function(self)
		return self:Get() ~= nil
	end)
	local errorText: State<string> = err:Compute(function(self)
		return self:Get() or ""
	end)

	local frame = D.Frame {
		Name = "DateInput",
		Position = o.Position or UDim2.new(),
		Size = UDim2.fromOffset(o.Width, o.Height),
		Visible = Util.visible(o.Visible),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		validate,
		TextField({
			Variant = "Outlined",
			Label = strings.DateLabel,
			Value = text,
			Placeholder = strings.Hint,
			SupportingText = strings.Hint,
			Error = isError,
			ErrorText = errorText,
			Theme = o.Theme,
			Modifier = D.Modifier.Frame()
				:Name("DateField")
				:Size(UDim2.fromOffset(o.Width - 32, 0))
				:Position(UDim2.fromOffset(16, 16)),
		}),
	}

	return {
		Frame = frame,
		Sync = function()
			local d = draft:Get()
			text:Set(if d ~= nil then Calendar.formatISO(d) else "")
		end,
	}
end

return { new = new }
