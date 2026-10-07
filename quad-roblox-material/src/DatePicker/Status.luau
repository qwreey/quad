--!strict
--[[
	How a day cell looks, as a function of (visible month grid, picked value(s)). One `State<Chip.Status>` per
	cell — see Chip.luau for what each status draws. These are the only per-cell Computes that read the data.

	Status.selectable(min, max, isDisabled) -> (Date) -> boolean     inside [min, max] and not disabled
	Status.single(opts) -> StatusFor                                 one picked date
	Status.range(opts) -> StatusFor                                  start / end / in-between
	Status.rangeEnds(opts) -> (grid) -> State<BandEnds>              where the joining half bands go (visible
	                                                                 start / end cells of a two-day-or-longer range)

	Priority (single): Hidden (out of month) > Selected (the picked date, even if it is outside the allowed
	range — an externally set value is shown honestly) > Disabled > Today > Normal.
	Priority (range): Hidden > RangeStart/RangeEnd (start/end of a complete range; Selected while only one end is
	picked) > Disabled > InRange > Today > Normal. A range whose start == end draws as one Selected day.
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
			if isStart and isEnd then
				return "Selected" -- a one-day range: one circle, no band
			elseif isStart then
				return if e ~= nil then "RangeStart" else "Selected"
			elseif isEnd then
				return if s ~= nil then "RangeEnd" else "Selected"
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

-- the cell (row, col) of a visible range end, for the half band that joins its circle to the strip; nil when that end is
-- not in the visible month, when the range is incomplete or one day long. Start = the earlier date (RangeDocked keeps
-- Start <= End; a reversed pair is normalized here too).
export type CellPos = { Row: number, Col: number }
export type BandEnds = { Start: CellPos?, End: CellPos? }

local function rangeEnds(o: RangeOptions): (grid: State<View.Grid>) -> State<BandEnds>
	return function(grid: State<View.Grid>): State<BandEnds>
		local ends: State<BandEnds> = grid:Compute(function(self, _prev, startH, endH): BandEnds
			local s, e = startH:Get(), endH:Get()
			if s == nil or e == nil or Calendar.equals(s, e) then
				return {}
			end
			local a, b = s, e
			if Calendar.isAfter(a, b) then
				a, b = b, a
			end
			local out: BandEnds = {}
			for row, cells in self:Get() do
				for col, cell in cells do
					if cell.InMonth then
						if Calendar.equals(cell.Date, a) then
							out.Start = { Row = row, Col = col }
						elseif Calendar.equals(cell.Date, b) then
							out.End = { Row = row, Col = col }
						end
					end
				end
			end
			return out
		end, o.Start, o.End)
		return ends
	end
end

return { selectable = selectable, single = single, range = range, rangeEnds = rangeEnds }
