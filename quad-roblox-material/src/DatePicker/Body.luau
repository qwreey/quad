--!strict
--[[
	Body: the calendar part shared by Docked, Modal and RangeDocked — header row (month/year toggle + prev/next),
	the month view and the year grid — on a transparent 360 x 396 Frame. It owns the visible month.

	    ┌ 360 ─────────────────────────────────────────┐
	    │ [October 2026 ▾]                    ‹   ›    │ 56   header (label = text button; arrows hidden in year mode)
	    │  S   M   T   W   T   F   S                    │ 40   weekday row
	    │  ·   ·   1   2   3   4   5   ...             │ 6*48 day grid (fixed six rows)
	    └ 12 px bottom padding ────────────────────────┘   = 396 total

	Options
	  Min, Max, IsDisabled, FirstDayOfWeek, Locale, Today, Theme   (see Docked)
	  InitialMonth   ViewMonth                     where the picker opens
	  Follow         State<Date?>?                 when it changes to a date outside the visible month the view moves
	                                               there (the value is "what the picker shows"); the user's own
	                                               prev/next/year navigation is never overridden otherwise
	  StatusFor      (grid, row, col) -> State<Status>
	  OnPick         (Date) -> ()
	  Band           boolean?
	  BandEnds       ((grid) -> State<BandEnds>)?  range: where the half bands joining the end circles go (MonthView)
	  Visible        boolean | State<boolean>?     (the Modal hides the calendar in text-input mode)
	Returns { Frame, View, Month, ShowYears }

	Month change = one `View:Set`; the 42 day cells keep their identity (spec.datepicker "navigation keeps the
	same cell instances"). The year grid is windowed (YearView.luau).
	The month-year button is a Text Button with a TRAILING ICON (10th QA): `Icons` arrowDown, arrowUp while the year grid
	is open (Compose DatePicker.kt `YearPickerMenuButton`: Icons.Filled.ArrowDropDown rotated 180 degrees when expanded —
	arrow_drop_up is the same triangle turned); when either image is overridden away, the "▼"/"▲" glyphs go back into the
	label text (both in Roboto). Compose's button keeps the plain TextButton padding 12 / 12 and a 24 dp icon; the kit
	Button's trailing icon is 18 px with the material-web Text-button padding 16 / 12 — a deviation of the kit Button,
	not reproduced here by hand. The month arrows are GlyphButtons given `Icons.asset("chevronLeft"/"chevronRight")` — the
	Material keyboard_arrow_left / right images by default (icon size 24), the ‹ › glyphs when overridden away.
]]

local q = require("../Quad")
local Util = require("../Util")
local Theme = require("../Theme")
local Button = require("../Button")
local Icons = require("../Icons")
local Calendar = require("./Calendar")
local Chip = require("./Chip")
local GlyphButton = require("../GlyphButton")
local MonthView = require("./MonthView")
local Strings = require("./Strings")
local View = require("./View")
local YearView = require("./YearView")
local Frame = q.Elem "Frame"
local TextButtonModifier = q.Modifier "TextButton"

type State<T> = q.State<T>
type Date = Calendar.Date

export type Options = {
	Min: Date?,
	Max: Date?,
	IsDisabled: ((date: Date) -> boolean)?,
	FirstDayOfWeek: number,
	Locale: string,
	Today: Date,
	Theme: Theme.Theme?,
	InitialMonth: View.ViewMonth,
	Follow: State<Date?>?,
	StatusFor: (grid: State<View.Grid>, row: number, col: number) -> State<Chip.Status>,
	OnPick: (date: Date) -> (),
	Band: boolean?,
	BandEnds: ((grid: State<View.Grid>) -> State<MonthView.BandEnds>)?,
	Visible: (boolean | State<boolean>)?,
	Position: UDim2?,
}

export type Body = {
	read Frame: Frame,
	read View: q.Source<View.ViewMonth>,
	read Month: MonthView.MonthView,
	read ShowYears: q.Source<boolean>,
}

local WIDTH = MonthView.Metrics.Width
local PAD = MonthView.Metrics.Pad
local HEADER_H = 56
local MONTH_H = MonthView.Metrics.WeekdayHeight + MonthView.Metrics.GridHeight
local HEIGHT = HEADER_H + MONTH_H + 12

local function new(o: Options): Body
	local theme = Theme.resolve(o.Theme)
	local strings = Strings.get(o.Locale)
	local view = q.Source(o.InitialMonth)
	local showYears = q.Source(false)
	local grid = View.gridState(view, o.FirstDayOfWeek)
	local notYears: State<boolean> = Util.negate(showYears)

	local function selectable(d: Date): boolean
		if not Calendar.isInRange(d, o.Min, o.Max) then
			return false
		end
		local dis = o.IsDisabled
		return not (dis ~= nil and dis(d))
	end

	local month = MonthView.new({
		Grid = grid,
		View = view,
		Theme = theme,
		Locale = o.Locale,
		FirstDayOfWeek = o.FirstDayOfWeek,
		Min = o.Min,
		Max = o.Max,
		StatusFor = o.StatusFor,
		Selectable = selectable,
		OnPick = o.OnPick,
		FocusDate = Calendar.clamp(o.Today, o.Min, o.Max),
		Band = o.Band,
		BandEnds = o.BandEnds,
		Visible = notYears,
		Position = UDim2.fromOffset(0, HEADER_H),
	})

	local years = YearView.new({
		View = view,
		Min = o.Min,
		Max = o.Max,
		Today = o.Today,
		Shown = showYears,
		Theme = theme,
		Height = MONTH_H,
		Position = UDim2.fromOffset(PAD, HEADER_H),
		OnPick = function(year: number)
			local v = view:Get()
			view:Set(View.clampMonth(year, v.Month, o.Min, o.Max))
			showYears:Set(false)
		end,
	})

	-- the year-menu arrow: the arrowDown / arrowUp images as the button's trailing icon, or (an image overridden away)
	-- the glyphs inside the label
	local arrowImages = Icons.asset("arrowDown") ~= nil and Icons.asset("arrowUp") ~= nil
	local label: State<string> = view:Compute(function(self, _prev, shown)
		local text = Calendar.format(View.first(self:Get()), strings.MonthYear, o.Locale)
		if arrowImages then
			return text
		end
		return text .. " " .. Icons.glyph(if shown:Get() then "arrowUp" else "arrowDown")
	end, showYears)
	local arrow: State<string>? = nil
	if arrowImages then
		arrow = showYears:Compute(function(self)
			return if self:Get() then "arrowUp" else "arrowDown"
		end)
	end

	local prevDisabled: State<boolean> = view:Compute(function(self)
		local v = self:Get()
		return not Calendar.canGoToPrevMonth(v.Year, v.Month, o.Min)
	end)
	local nextDisabled: State<boolean> = view:Compute(function(self)
		local v = self:Get()
		return not Calendar.canGoToNextMonth(v.Year, v.Month, o.Max)
	end)

	local follow: any = q.None
	local followSource = o.Follow
	if followSource ~= nil then
		follow = q.Effect(function()
			local d = followSource:Get()
			if d ~= nil and not View.contains(view:Get(), d) then
				view:Set(View.containing(d))
			end
		end, followSource)
	end

	local frame = Frame {
		Name = "DatePickerBody",
		Position = o.Position or UDim2.new(),
		Visible = Util.visible(o.Visible),
		Size = UDim2.fromOffset(WIDTH, HEIGHT),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		follow,
		Button({
			Variant = "Text",
			Label = label,
			Icon = arrow,
			IconPosition = "Trailing",
			Theme = theme,
			OnClick = function()
				showYears:Set(not showYears:Get())
			end,
			Modifier = TextButtonModifier():Position(UDim2.fromOffset(PAD - 8, 8)),
		}),
		GlyphButton.new({
			Name = "Prev",
			Glyph = Icons.glyph("chevronLeft"),
			Asset = Icons.asset("chevronLeft"),
			Position = UDim2.fromOffset(WIDTH - PAD - 80, 8),
			Disabled = prevDisabled,
			Visible = notYears,
			Theme = theme,
			OnClick = function()
				local v = view:Get()
				if Calendar.canGoToPrevMonth(v.Year, v.Month, o.Min) then
					view:Set(View.step(v, -1))
				end
			end,
		}),
		GlyphButton.new({
			Name = "Next",
			Glyph = Icons.glyph("chevronRight"),
			Asset = Icons.asset("chevronRight"),
			Position = UDim2.fromOffset(WIDTH - PAD - 40, 8),
			Disabled = nextDisabled,
			Visible = notYears,
			Theme = theme,
			OnClick = function()
				local v = view:Get()
				if Calendar.canGoToNextMonth(v.Year, v.Month, o.Max) then
					view:Set(View.step(v, 1))
				end
			end,
		}),
		month.Frame,
		years,
	}
	return { Frame = frame, View = view, Month = month, ShowYears = showYears }
end

return { new = new, Width = WIDTH, Height = HEIGHT, HeaderHeight = HEADER_H }
