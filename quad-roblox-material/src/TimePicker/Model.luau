--!strict
--[[
	Model: the kit's form of Compose's `TimePickerState` (TimePicker.kt 1487-1551, TimePickerStateImpl 1647-1719) shared by
	the dial, the text input and the modal (which builds both over ONE model, as Compose's samples pass one state to
	`TimePicker` and `TimeInput`).

	    local m = Model.new({ Value = time, Is24Hour = false, OnChange = fn })
	  .Value        Source<Time>            the valid time (Compose `hour` / `minute`); written on a valid user change
	  .Is24Hour     boolean                 Compose `is24hour` (fixed for the model's life)
	  .Selection    Source<Selection>       "Hour" | "Minute" — which one the dial / input edits (Compose `selection`)
	  .HourInput    Source<number>          what the hour field holds (may be invalid while typing — Compose `hourInput`)
	  .MinuteInput  Source<number>          (Compose `minuteInput`)
	  .HourValid / .MinuteValid / .Valid    State<boolean>   Compose `isHourInputValid` / `isMinuteInputValid` /
	                                        `isInputValid` (the modal's OK is enabled by `Valid` — TimePickerSamples.kt 183)
	  .Sync         Effect                  keeps HourInput / MinuteInput equal to Value after any write of Value
	                                        (Compose's `hour` setter sets `hourInput` too, 1670-1689) — place it in a host
	  :SetTime(t)                            a USER change: writes Value when it differs, then calls OnChange
	  :SetHourInput(n) / :SetMinuteInput(n)  a USER edit of a field: stores the input, and writes Value when valid
	  :SetPeriod(pm)                          the AM / PM toggle: moves the hour by 12 while the hour input is valid
	Validity follows `isValidHour` (1563-1571): in 12 h the PERIOD of the current valid hour decides which 12 values count.
]]

local q = require("../Quad")
local Clock = require("./Clock")

type Time = Clock.Time
type State<T> = q.State<T>

export type Selection = Clock.Selection

export type Options = {
	Value: q.Source<Time>,
	Is24Hour: boolean,
	OnChange: ((time: Time) -> ())?,
	Selection: Selection?,
}

export type Model = {
	read Value: q.Source<Time>,
	read Is24Hour: boolean,
	read Selection: q.Source<Selection>,
	read HourInput: q.Source<number>,
	read MinuteInput: q.Source<number>,
	read HourValid: State<boolean>,
	read MinuteValid: State<boolean>,
	read Valid: State<boolean>,
	read Sync: q.Effect,
	SetTime: (self: Model, t: Time) -> (),
	SetHourInput: (self: Model, n: number) -> (),
	SetMinuteInput: (self: Model, n: number) -> (),
	SetPeriod: (self: Model, pm: boolean) -> (),
}

local function new(o: Options): Model
	local value = o.Value
	local is24 = o.Is24Hour
	local start = value:Get()
	local selection = q.Source((o.Selection or "Hour") :: Selection)
	local hourInput = q.Source(start.Hour)
	local minuteInput = q.Source(start.Minute)

	local hourValid: State<boolean> = hourInput:Compute(function(self, _prev, v)
		return Clock.isValidHour(self:Get(), is24, Clock.isPm(v:Get().Hour))
	end, value)
	local minuteValid: State<boolean> = minuteInput:Compute(function(self)
		local m = self:Get()
		return m >= 0 and m <= 59 and m == math.floor(m)
	end)
	local valid: State<boolean> = hourValid:Compute(function(self, _prev, mv)
		return self:Get() and mv:Get()
	end, minuteValid)

	local sync = q.Effect(function()
		local t = value:Get()
		hourInput:SetIfChanged(t.Hour)
		minuteInput:SetIfChanged(t.Minute)
	end, value)

	local self: Model
	self = {
		Value = value,
		Is24Hour = is24,
		Selection = selection,
		HourInput = hourInput,
		MinuteInput = minuteInput,
		HourValid = hourValid,
		MinuteValid = minuteValid,
		Valid = valid,
		Sync = sync,
		SetTime = function(_self: Model, t: Time)
			local cur = value:Get()
			hourInput:SetIfChanged(t.Hour)
			minuteInput:SetIfChanged(t.Minute)
			if not Clock.equals(cur, t) then
				value:Set(t)
				if o.OnChange then
					o.OnChange(t)
				end
			end
		end,
		SetHourInput = function(m: Model, n: number)
			hourInput:SetIfChanged(n)
			local cur = value:Get()
			if Clock.isValidHour(n, is24, Clock.isPm(cur.Hour)) and n ~= cur.Hour then
				m:SetTime(Clock.time(n, cur.Minute))
			end
		end,
		SetMinuteInput = function(m: Model, n: number)
			minuteInput:SetIfChanged(n)
			local cur = value:Get()
			if n >= 0 and n <= 59 and n == math.floor(n) and n ~= cur.Minute then
				m:SetTime(Clock.time(cur.Hour, n))
			end
		end,
		SetPeriod = function(m: Model, pm: boolean)
			if not hourValid:Get() then
				return
			end
			local cur = value:Get()
			if Clock.isPm(cur.Hour) ~= pm then
				m:SetTime(Clock.withPeriod(cur, pm))
			end
		end,
	}
	return self
end

return { new = new }
