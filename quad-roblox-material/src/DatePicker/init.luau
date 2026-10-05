--!strict
--[[
	Date pickers (Material 3): docked calendar, date-range calendar, modal dialog (with text-input mode).

	    local DatePicker = Material.DatePicker
	    DatePicker.Docked({ Value = date })                          -- Source<Date?>, calendar in place
	    DatePicker.RangeDocked({ Start = s, End = e })
	    DatePicker.Modal.open({ Value = date, OnConfirm = save })    -- through the Overlay
	    DatePicker.Calendar                                          -- the pure date math (no engine)

	All date math (leap years, weekdays, month grids, clamping, parsing, formatting) lives in Calendar.luau and is
	covered by test/spec.pure.calendar.luau; the UI never computes a date itself. Dates are the frozen
	`Calendar.Date = { Year, Month, Day }` tables; compare them with `Calendar.equals`.
	Time zones: there is none in the UI — "today" is `Calendar.today(nil, UtcOffset)` (UTC + the offset you pass in
	seconds) or the `Today` prop. The module never reads the machine's time zone.

	Files: Calendar (math) / Strings (locale texts) / View (visible month + grid State) / Chip (round cell, 3
	instances) / MonthView (weekday row + 42 persistent day cells + keyboard) / YearView (windowed year grid) /
	(the shared ../GlyphButton) / Body (header + month + years) / Status (what a cell looks like) / Docked / RangeDocked /
	InputMode / Modal.
]]

local Docked = require("@self/Docked")
local RangeDocked = require("@self/RangeDocked")
local Modal = require("@self/Modal")
local Calendar = require("@self/Calendar")

export type Date = Calendar.Date
export type Locale = Docked.Locale
export type DockedProps = Docked.Props
export type RangeDockedProps = RangeDocked.Props
export type ModalOptions = Modal.OpenOptions

return {
	Docked = Docked,
	RangeDocked = RangeDocked,
	Modal = Modal,
	Calendar = Calendar,
}
