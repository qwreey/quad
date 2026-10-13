--!strict
--[[
	MonthView: the weekday header row + the 6x7 day grid of a date picker. The 42 cells are created ONCE; month
	navigation only changes the `Grid` State (the visible month's `Calendar.monthGrid`), and every cell derives
	its text / visibility / selected / disabled look from it. The same 42 Instances live for the picker's life.

	Layout (px): 12 px side padding, then 7 columns of 48 (weekday labels AND the day grid both start at x = 12); weekday
	row 40 high; day rows 48; a 40x40 chip centred in each 48x48 slot
	(M3's 40 dp day circle — the 48 dp touch target is the slot, the chip itself is the hit area: deviation).
	Instances: weekday labels 7 + grid Frame 1 + 42 chips * 3 = 134 (+ the Frame wrapper = 135); a range grid (`BandEnds`)
	adds the two half-band Frames (137).

	Options
	  Grid         State<Grid>                   the visible month (View.gridState)
	  View         Source<ViewMonth>             keyboard navigation moves it when focus leaves the month
	  Theme, Locale, FirstDayOfWeek, Min, Max
	  StatusFor    (grid, row, col) -> State<Status>   how one cell looks (single value / range — Body decides)
	  Selectable   (Date) -> boolean             in range and not disabled (keyboard skips the others)
	  OnPick       (Date) -> ()                  a selectable cell was activated (click / tap / gamepad A / Enter)
	  FocusDate    Date                          initial keyboard focus date (Source `focusDate` exposed below)
	  Band         boolean?                      range band chips
	  BandEnds     ((grid) -> State<BandEnds>)?  with Band: where the range's start / end circles sit (Status.rangeEnds) —
	                                             two half-band Frames (`BandStart` / `BandEnd`, under the chips) join each
	                                             end circle to the in-range strip, as M3's range picker draws it: the start
	                                             circle sits on a band from its center to the slot's right edge, the end
	                                             circle on one from the left edge to its center (Studio QA 2026-10-07, 2nd:
	                                             the circles floated apart from the strip by the 4 px slot margin)
	  Visible      boolean | State<boolean>?     the Frame's Visible (hidden while the year grid shows)

	KEYBOARD (hardware keyboard): while ANY cell holds engine selection the grid listens (the shared `KeyNav` hook, one per
	cell, ignoring `processed` — KeyNav's premise, device-unverified; at most one `UserInputService.InputBegan` connection is open) — arrows +-1 day / +-7 days, PageUp/PageDown +-1 month, Home/End week row ends
	(`Calendar.moveFocus`, skipping non-selectable dates by repeating the move; Home/End go to the row end, or to the
	selectable day nearest to it on this side of the focused one). Enter/KeypadEnter picks the
	focused date through the ENGINE — it fires `Activated` on the selected cell (measured); this handler leaves the key alone. KeyNav opens the connection on `SelectionGained` of a cell and closes it on `SelectionLost` and when the
	cell is destroyed — at most one connection, zero when nothing is focused. Moving focus to another
	month moves the visible month, then the engine selection (`GuiService.SelectedObject`) to the new cell.
	`gameProcessed` is NOT consulted (the engine marks nav keys processed while a cell holds selection). The grid
	does NOT pin `NextSelection*` (`Pin = "None"`): the gamepad D-pad is the engine's geometric selection, which moves between
	cells and can leave the grid for the header / actions (a pinned grid would trap a gamepad — the Docked picker has no
	dialog B to escape with). A hardware keyboard's arrows are handled here as above (the engine may also nudge selection;
	`onKey` then sets the exact cell). Gamepad: ButtonL1 / ButtonR1 page the previous / next month keeping the focused day
	(`Calendar.moveFocus` pageUp / pageDown, skipping non-selectable dates). Hidden out-of-month cells are
	`Selectable = false`, so the engine never lands on them. `focusDate` still follows `SelectionGained` (pointer / touch /
	gamepad focus). All gamepad behaviour is device-unverified.
]]

local q = require("../Quad")
local Util = require("../Util")
local Theme = require("../Theme")
local Text = require("../Text")
local Chip = require("./Chip")
local View = require("./View")
local Calendar = require("./Calendar")
local KeyNav = require("../KeyNav")
local D = q.Declaration

local GuiService = game:GetService("GuiService")

type State<T> = q.State<T>
type Date = Calendar.Date

export type Options = {
	Grid: State<View.Grid>,
	View: q.Source<View.ViewMonth>,
	Theme: Theme.Theme?,
	Locale: string,
	FirstDayOfWeek: number,
	Min: Date?,
	Max: Date?,
	StatusFor: (grid: State<View.Grid>, row: number, col: number) -> State<Chip.Status>,
	Selectable: (date: Date) -> boolean,
	OnPick: (date: Date) -> (),
	FocusDate: Date,
	Band: boolean?,
	BandEnds: ((grid: State<View.Grid>) -> State<BandEnds>)?,
	Visible: (boolean | State<boolean>)?,
	Position: UDim2?,
}

export type BandEnds = { Start: { Row: number, Col: number }?, End: { Row: number, Col: number }? }

export type MonthView = {
	read Frame: Frame,
	read Cells: { TextButton }, -- row-major, 42
	read FocusDate: q.Source<Date>,
}

local COL_W, ROW_H = 48, 48
local CHIP = 40
local WEEKDAY_H = 40
local PAD = 12
export type Metrics = { Width: number, WeekdayHeight: number, GridHeight: number, Pad: number }
local Metrics: Metrics = { Width = PAD * 2 + 7 * COL_W, WeekdayHeight = WEEKDAY_H, GridHeight = 6 * ROW_H, Pad = PAD }

local DAY_TEXT: { string } = {}
for d = 1, 31 do
	DAY_TEXT[d] = tostring(d)
end

-- keyed by KeyCode NAME (strings intern everywhere; EnumItem userdata identity is not guaranteed off-engine)
local KEYS: { [string]: Calendar.FocusAction } = {
	Left = "left",
	Right = "right",
	Up = "up",
	Down = "down",
	-- gamepad: only the shoulder buttons are ours (previous / next month); the D-pad is left to the engine's geometric
	-- selection so it can leave the grid (the Docked picker has no dialog B to escape with)
	ButtonL1 = "pageUp",
	ButtonR1 = "pageDown",
	PageUp = "pageUp",
	PageDown = "pageDown",
	Home = "home",
	End = "end",
}

local weekdayStyle = Text.Label("BodyLarge")

-- first character (UTF-8 aware) of a weekday name: "Sun" -> "S", "일" -> "일"
local function firstChar(s: string): string
	local nextStart = utf8.offset(s, 2)
	if nextStart == nil then
		return s
	end
	return s:sub(1, nextStart - 1)
end

local function new(o: Options): MonthView
	local theme = Theme.resolve(o.Theme)
	local locale = o.Locale
	local grid = o.Grid
	local cells: { TextButton } = {}
	local focusDate = q.Source(o.FocusDate)

	-- next date in direction `action` that is selectable (nil: nothing reachable / at the bound)
	local function reach(from: Date, action: Calendar.FocusAction): Date?
		local bounds: Calendar.FocusOptions = { FirstDayOfWeek = o.FirstDayOfWeek, Min = o.Min, Max = o.Max }
		-- (compared as plain strings: narrowing `action` to "home" | "end" makes the new solver reject the call below)
		local name: string = action
		if name == "home" or name == "end" then
			-- the end of the week row, or — when that day is not selectable — the nearest selectable day on the way
			-- back to `from` (repeating home / end would stand still: it is the same day again)
			local back: Calendar.FocusAction = if name == "home" then "right" else "left"
			local cur = Calendar.moveFocus(from, action, bounds)
			for _ = 1, 6 do
				if Calendar.equals(cur, from) then
					return nil
				end
				if o.Selectable(cur) then
					return cur
				end
				cur = Calendar.moveFocus(cur, back, bounds)
			end
			return nil
		end
		local cur = from
		for _ = 1, 400 do
			local nxt = Calendar.moveFocus(cur, action, bounds)
			if Calendar.equals(nxt, cur) then
				return nil
			end
			cur = nxt
			if o.Selectable(cur) then
				return cur
			end
		end
		return nil
	end

	local function cellFor(d: Date): TextButton?
		local g = grid:Get()
		local idx = Calendar.diffDays(d, g[1][1].Date)
		return cells[idx + 1]
	end

	-- delivered by one KeyNav hook per cell (one InputBegan connection while a cell holds selection). `processed` is not
	-- consulted (KeyNav premise: the engine marks nav keys processed while a control holds selection); `Pin = "None"`: the
	-- engine's own D-pad selection is left alone, `onKey` handles keyboard keys and ButtonL1/ButtonR1 month paging.
	local function onKey(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Keyboard and string.sub(input.UserInputType.Name, 1, 7) ~= "Gamepad" then
			return
		end
		local action = KEYS[input.KeyCode.Name]
		if action then
			local nxt = reach(focusDate:Get(), action)
			if nxt == nil then
				return
			end
			focusDate:Set(nxt)
			if not View.contains(o.View:Get(), nxt) then
				o.View:Set(View.containing(nxt))
			end
			local cell = cellFor(nxt)
			if cell ~= nil then
				GuiService.SelectedObject = cell
			end
		-- Enter / KeypadEnter is NOT handled here: the engine activates the selected cell on Return (its `Activated`
		-- picks — Chip.luau). Handling it here as well picked TWICE per press (Studio 2026-10-13: Docked `OnChange`
		-- twice; a range closed start = end on one Enter).
		end
	end

	local function focused(row: number, col: number)
		focusDate:Set(grid:Get()[row][col].Date)
	end

	-- weekday header
	local header: { Instance } = {}
	for i, wd in Calendar.weekdayOrder(o.FirstDayOfWeek) do
		table.insert(
			header,
			D.TextLabel {
				Name = "Weekday",
				weekdayStyle,
				Size = UDim2.fromOffset(COL_W, WEEKDAY_H),
				Position = UDim2.fromOffset(PAD + (i - 1) * COL_W, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = firstChar(Calendar.weekdayName(locale, wd, true)),
				TextColor3 = theme.Color.OnSurface,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}
		)
	end

	local gridChildren: { Instance } = {}
	for row = 1, 6 do
		for col = 1, 7 do
			local text: State<string> = grid:Compute(function(self)
				return DAY_TEXT[self:Get()[row][col].Date.Day]
			end)
			local chip = Chip.new({
				Name = "Day",
				Size = UDim2.fromOffset(CHIP, CHIP),
				Position = UDim2.fromOffset((col - 1) * COL_W + (COL_W - CHIP) // 2, (row - 1) * ROW_H + (ROW_H - CHIP) // 2),
				Text = text,
				Status = o.StatusFor(grid, row, col),
				Theme = theme,
				Band = o.Band,
				BandExtra = (COL_W - CHIP) // 2,
				OnActivated = function()
					o.OnPick(grid:Get()[row][col].Date)
				end,
				OnFocused = function()
					focused(row, col)
				end,
				Hooks = { KeyNav.hook(onKey, nil, { Pin = "None" }) },
			})
			table.insert(cells, chip)
			table.insert(gridChildren, chip)
		end
	end

	-- range: the two half bands joining the end circles to the strip (drawn under the chips: chips are ZIndex 2 in Band mode)
	if o.Band and o.BandEnds ~= nil then
		local ends = o.BandEnds(grid)
		local bandColor = theme.Color.SecondaryContainer
		local function half(name: string, which: "Start" | "End")
			local pos: State<UDim2> = ends:Compute(function(self)
				local cell = if which == "Start" then self:Get().Start else self:Get().End
				if cell == nil then
					return UDim2.fromOffset(0, 0)
				end
				local x = (cell.Col - 1) * COL_W + (if which == "Start" then COL_W // 2 else 0)
				return UDim2.fromOffset(x, (cell.Row - 1) * ROW_H + (ROW_H - CHIP) // 2)
			end)
			local shown: State<boolean> = ends:Compute(function(self)
				return (if which == "Start" then self:Get().Start else self:Get().End) ~= nil
			end)
			return D.Frame {
				Name = name,
				Size = UDim2.fromOffset(COL_W // 2, CHIP),
				Position = pos,
				Visible = shown,
				BackgroundColor3 = bandColor,
				BorderSizePixel = 0,
				ZIndex = 1,
			}
		end
		table.insert(gridChildren, 1, half("BandStart", "Start"))
		table.insert(gridChildren, 2, half("BandEnd", "End"))
	end

	-- the day columns line up with the weekday labels: both start PAD px in (the grid's 7 * 48 px sit inside the
	-- 12 px side padding, like the header row)
	local gridFrame = D.Frame {
		Name = "Days",
		Size = UDim2.fromOffset(7 * COL_W, Metrics.GridHeight),
		Position = UDim2.fromOffset(PAD, WEEKDAY_H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		table.unpack(gridChildren),
	}

	local frame = D.Frame {
		Name = "Month",
		Size = UDim2.fromOffset(Metrics.Width, WEEKDAY_H + Metrics.GridHeight),
		Visible = Util.visible(o.Visible),
		Position = o.Position or UDim2.new(),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		gridFrame,
		table.unpack(header), -- last: a trailing call expands to every weekday label
	}
	return { Frame = frame, Cells = cells, FocusDate = focusDate }
end

return { new = new, Metrics = Metrics, firstChar = firstChar }
