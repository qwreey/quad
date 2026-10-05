--!strict
--[[
	The visible month of a picker and the shared grid State derived from it.

	ViewMonth = { Year, Month }  (frozen). A picker owns ONE `Source<ViewMonth>`; the 6x7 `grid` State is computed
	from it once and every day cell reads its own `[row][col]` from that State (no instance is created or
	destroyed when the month changes — see Body.luau).
]]

local q = require("../Quad")
local Calendar = require("./Calendar")

type Date = Calendar.Date

export type ViewMonth = { read Year: number, read Month: number }
export type Grid = { { Calendar.Cell } }

local function make(year: number, month: number): ViewMonth
	return table.freeze({ Year = year, Month = month })
end

local function containing(d: Date): ViewMonth
	return make(d.Year, d.Month)
end

local function contains(v: ViewMonth, d: Date): boolean
	return v.Year == d.Year and v.Month == d.Month
end

local function first(v: ViewMonth): Date
	return Calendar.date(v.Year, v.Month, 1)
end

local function step(v: ViewMonth, months: number): ViewMonth
	return containing(Calendar.addMonths(first(v), months))
end

-- The month nearest to (year, month) that intersects [min, max].
local function clampMonth(year: number, month: number, min: Date?, max: Date?): ViewMonth
	-- clamping the 1st is enough: a month wholly before `min` clamps to `min`, one wholly after `max` to `max`,
	-- and a month that merely contains a bound keeps its own 1st (or the bound, in the same month)
	return containing(Calendar.clamp(Calendar.date(year, month, 1), min, max))
end

local function gridState(view: q.State<ViewMonth>, firstDayOfWeek: number): q.State<Grid>
	local grid: q.State<Grid> = view:Compute(function(self)
		local v = self:Get()
		return Calendar.monthGrid(v.Year, v.Month, { FirstDayOfWeek = firstDayOfWeek, FixedWeeks = true })
	end)
	return grid
end

return {
	make = make,
	containing = containing,
	contains = contains,
	first = first,
	step = step,
	clampMonth = clampMonth,
	gridState = gridState,
}
