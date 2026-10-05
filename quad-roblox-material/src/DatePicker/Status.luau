--!strict
--[[
	How a day cell looks, as a function of (visible month grid, picked value(s)). One `State<Chip.Status>` per
	cell — see Chip.luau for what each status draws. These are the only per-cell Computes that read the data.

	Status.selectable(min, max, isDisabled) -> (Date) -> boolean     inside [min, max] and not disabled
	Status.single(opts) -> StatusFor                                 one picked date
	Status.range(opts) -> StatusFor                                  start / end / in-between

	Priority (single): Hidden (out of month) > Selected (the picked date, even if it is outside the allowed
	range — an externally set value is shown honestly) > Disabled > Today > Normal.
	Priority (range): Hidden > Selected (start/end) > Disabled > InRange > Today > Normal. A range whose
	start == end draws as one Selected day.
]]

local q = require("../Quad")
local Calendar = require("./Calendar")
local Chip = require("./Chip")
local View = require("./View")

type State<T> = q.State<T>
type Date = Calendar.Date

export type StatusFor = (grid: State<View.Grid>, row: number, col: number) -> State<Chip.Status>

local function selectable(min: Date?, max: Date?, isDisabled: ((Date) -> boolean)?): (Date) -> boolean
	return function(d: Date): boolean
		if not Calendar.isInRange(d, min, max) then
			return false
		end
		return not (isDisabled ~= nil and isDisabled(d))
	end
end

export type SingleOptions = {
	Value: State<Date?>,
	Today: Date,
	Selectable: (Date) -> boolean,
}

local function single(o: SingleOptions): StatusFor
	return function(grid: State<View.Grid>, row: number, col: number): State<Chip.Status>
		local status: State<Chip.Status> = grid:Compute(function(self, _prev, value)
			local cell = self:Get()[row][col]
			if not cell.InMonth then
				return "Hidden"
			end
			local d = cell.Date
			local picked = value:Get()
			if picked ~= nil and Calendar.equals(picked, d) then
				return "Selected"
			elseif not o.Selectable(d) then
				return "Disabled"
			elseif Calendar.equals(d, o.Today) then
				return "Today"
			end
			return "Normal"
		end, o.Value)
		return status
	end
end

export type RangeOptions = {
	Start: State<Date?>,
	End: State<Date?>,
	Today: Date,
	Selectable: (Date) -> boolean,
}

local function range(o: RangeOptions): StatusFor
	return function(grid: State<View.Grid>, row: number, col: number): State<Chip.Status>
		local status: State<Chip.Status> = grid:Compute(function(self, _prev, startH, endH)
			local cell = self:Get()[row][col]
			if not cell.InMonth then
				return "Hidden"
			end
			local d = cell.Date
			local s, e = startH:Get(), endH:Get()
			local isStart = s ~= nil and Calendar.equals(s, d)
			local isEnd = e ~= nil and Calendar.equals(e, d)
			local between = false
			if s ~= nil and e ~= nil then
				between = Calendar.rangeContains(s, e, d)
			end
			if isStart or isEnd then
				return "Selected"
			elseif not o.Selectable(d) then
				return "Disabled"
			elseif between then
				return "InRange"
			elseif Calendar.equals(d, o.Today) then
				return "Today"
			end
			return "Normal"
		end, o.Start, o.End)
		return status
	end
end

return { selectable = selectable, single = single, range = range }
