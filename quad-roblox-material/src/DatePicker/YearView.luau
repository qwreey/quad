--!strict
--[[
	YearView: the M3 year grid (3 columns, 72x36 pill per year, the visible year filled, this year outlined),
	WINDOWED: only the rows around the scroll position exist.

	  years            [firstYear .. lastYear] = [Min.Year .. Max.Year]; an open end defaults to the visible
	                   year at construction -/+ `OpenSpan` (100) years (so an unbounded picker never builds the
	                   9999-year calendar). Clamped to 1..9999.
	  layout           row height 52, column width 112, viewport 5 rows (260 px). Chips are positioned
	                   absolutely from the year (`Position`), CanvasSize is fixed (rows * 52) — how-to 03 windowing.
	  window           `firstRow` Source is written by a `q.OnChange("CanvasPosition")` handler with SetIfChanged
	                   (so a scroll only re-cuts the list when the first row changes); the keyed `Slot:List` over
	                   the cut keeps the chips whose year stays in the window and creates/destroys the rest.
	  instances        the scroll frame + at most (ceil(height / 52) + 2) * 3 chips (3 instances each) — 27 chips
	                   (about 80 instances) at the Body's 328 px height, independent of the year range.
	  scroll to year   a PostRef on the scroll frame sets CanvasPosition so the visible year sits near the middle,
	                   and an Effect on `Shown` repeats that every time the view is opened.
	                   [unverified in Studio] the engine clamps CanvasPosition to the canvas; CanvasSize is set
	                   in the same drive, so the postHook position holds — report 미완 if a place shows year 1900.

	Options
	  View       Source<ViewMonth>   (its Year is the selected/visible year)
	  Min, Max   Date?
	  Today      Date
	  Shown      State<boolean>      Visible binding + re-center trigger
	  Theme      Theme?
	  Height     number?             viewport height, default 260
	  OnPick     (year: number) -> ()
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Chip = require("./Chip")
local View = require("./View")
local Calendar = require("./Calendar")
local D = q.Declaration

type State<T> = q.State<T>

export type Options = {
	View: q.Source<View.ViewMonth>,
	Min: Calendar.Date?,
	Max: Calendar.Date?,
	Today: Calendar.Date,
	Shown: State<boolean>,
	Theme: Theme.Theme?,
	Height: number?,
	Position: UDim2?,
	OnPick: (year: number) -> (),
}

local COLS = 3
local ROW_H = 52
local COL_W = 112
local CHIP_W, CHIP_H = 72, 36
local OPEN_SPAN = 100

type YearCtx = {
	Item: number | q.KeyGone,
	Index: number,
	Offset: State<number>,
	Prev: q.SlotItem<Instance>?,
	UserData: nil,
}

local function new(o: Options): ScrollingFrame
	local theme = Theme.resolve(o.Theme)
	local centerYear = o.View:Get().Year
	local firstYear = math.max(1, if o.Min then o.Min.Year else centerYear - OPEN_SPAN)
	local lastYear = math.min(9999, if o.Max then o.Max.Year else centerYear + OPEN_SPAN)
	if lastYear < firstYear then
		lastYear = firstYear
	end
	local total = lastYear - firstYear + 1
	local rows = math.ceil(total / COLS)
	local height = o.Height or 5 * ROW_H
	-- rows that can intersect the viewport (+ partial at both ends) plus one row of margin above
	local windowRows = math.ceil(height / ROW_H) + 2

	-- scroll offset that puts `year`'s row near the middle of the viewport
	local function targetY(year: number): number
		local row = math.floor((math.clamp(year, firstYear, lastYear) - firstYear) / COLS)
		local y = row * ROW_H - (height - ROW_H) / 2
		return math.clamp(y, 0, math.max(0, rows * ROW_H - height))
	end
	local function rowOf(y: number): number
		return math.max(0, math.floor(y / ROW_H) - 1)
	end

	local firstRow = q.Source(rowOf(targetY(centerYear)))
	local window: State<{ number }> = firstRow:Compute(function(self)
		local r0 = self:Get()
		local list: { number } = {}
		local from = firstYear + r0 * COLS
		local to = math.min(lastYear, firstYear + (r0 + windowRows) * COLS - 1)
		for y = from, to do
			table.insert(list, y)
		end
		return list
	end)

	local items = q.Slot<<Instance>>()
	items:List(window, function(ctx: YearCtx): (any, nil)
		if ctx.Item == q.KeyGone then
			return nil, nil
		end
		if ctx.Prev then
			return ctx.Prev, nil
		end
		local year = ctx.Item :: number
		local idx = year - firstYear
		local col, row = idx % COLS, idx // COLS
		local status: State<Chip.Status> = o.View:Compute(function(self)
			if self:Get().Year == year then
				return "Selected"
			elseif o.Today.Year == year then
				return "Today"
			end
			return "Normal"
		end)
		return Chip.new({
			Name = "Year",
			Size = UDim2.fromOffset(CHIP_W, CHIP_H),
			Position = UDim2.fromOffset(col * COL_W + (COL_W - CHIP_W) // 2, row * ROW_H + (ROW_H - CHIP_H) // 2),
			Text = tostring(year),
			Status = status,
			Theme = theme,
			OnActivated = function()
				o.OnPick(year)
			end,
		}),
			nil
	end, function(year: number): any
		return year
	end)

	local ref = q.Ref<<ScrollingFrame?>>(nil)
	local function center()
		local inst = ref.Value
		if inst ~= nil then
			inst.CanvasPosition = Vector2.new(0, targetY(o.View:Get().Year))
		end
	end

	return D.ScrollingFrame {
		Name = "Years",
		ref,
		Size = UDim2.fromOffset(COLS * COL_W, height),
		Position = o.Position or UDim2.new(),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, rows * ROW_H),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = o.Shown,
		q.OnChange("CanvasPosition", function(pos: Vector2)
			firstRow:SetIfChanged(rowOf(pos.Y))
		end),
		Util.postHook(function()
			center()
		end),
		q.Effect(function()
			if o.Shown:Get() then
				center()
			end
		end, o.Shown),
		items,
	}
end

return { new = new }
