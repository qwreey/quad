--!strict
--[[
	M3 docked date-RANGE picker: same calendar as Docked, two Sources (Start, End).

	    local s, e = q.Source<<Date?>>(nil), q.Source<<Date?>>(nil)
	    DatePicker.RangeDocked({ Start = s, End = e })

	Selection rule (derived from the Sources themselves — no hidden state):
	  * Start set and End nil  -> the next click completes the range: `Calendar.normalizeRange(Start, clicked)`
	                              (clicking an earlier day swaps them); both Sources are written.
	  * otherwise (nothing picked, or a complete range) -> the click starts a new range: End := nil, Start := clicked.
	Look: Start/End are filled primary circles; days between are a secondaryContainer band built from the day
	chips themselves (an in-range chip widens to the full 48 px slot and squares its corners — still 3 instances per
	cell), joined to the start/end circles by two half-band Frames per month grid (`BandStart` from the start circle's
	center to its slot's right edge, `BandEnd` from the left edge to the end circle's center — MonthView `BandEnds`; the
	first version had none and the circles floated 4 px apart from the strip, Studio QA 2026-10-07 2nd).
	Deviation from M3: no rounded caps at the ends of a week row.
	Motion (Compose): the band and the END circle appear / clear at once, only the start circle fades in (Chip `snaps` —
	androidx/androidx@40ff481 DatePicker.kt:2063-2066 `animateChecked = startDateSelected`, :976-977 in-range content color
	not animated, DateRangePicker.kt:1039 `drawRangeBackground` unanimated); tweening them was the Studio QA 2026-10-08
	dark flicker (the idle chip's color is onSurface at transparency 1).
	Known canon difference, kept: with only Start set, tapping an EARLIER day swaps (`normalizeRange`) — Compose makes that
	day the new Start instead (user 2026-10-08: out of scope for now).

	Props: Start, End (Source<Date?>), Min, Max, IsDisabled, FirstDayOfWeek, Locale, Today, UtcOffset, Theme, Modifier
	as Docked, plus `OnChange: ((start: Date, end: Date?) -> ())?` after each click (End is nil after the first).
	Disabled days inside a chosen range stay in the band's slot but are drawn Disabled (the range is a plain
	interval, `Calendar.rangeContains` — disabled days are not removed from it).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Elevation = require("../Elevation")
local Body = require("./Body")
local Calendar = require("./Calendar")
local Docked = require("./Docked")
local Status = require("./Status")
local View = require("./View")
local D = q.Declaration

type Date = Calendar.Date

export type Props = {
	read Start: q.Source<Date?>,
	read End: q.Source<Date?>,
	read Min: Date?,
	read Max: Date?,
	read IsDisabled: ((date: Date) -> boolean)?,
	read FirstDayOfWeek: number?,
	read Locale: Docked.Locale?,
	read Today: Date?,
	read UtcOffset: number?,
	read OnChange: ((start: Date, finish: Date?) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local baseModifier = D.Modifier.Frame():Size(UDim2.fromOffset(Body.Width, Body.Height)):BorderSizePixel(0)

local function RangeDocked(props: Props): Frame
	local theme = Theme.resolve(props.Theme)
	local locale: Docked.Locale = props.Locale or "en"
	local today = props.Today or Calendar.today(nil, props.UtcOffset)
	local selectable = Status.selectable(props.Min, props.Max, props.IsDisabled)
	local startSource, endSource = props.Start, props.End
	local current = startSource:Get()
	local initial = if current ~= nil then current else Calendar.clamp(today, props.Min, props.Max)

	local body = Body.new({
		Min = props.Min,
		Max = props.Max,
		IsDisabled = props.IsDisabled,
		FirstDayOfWeek = props.FirstDayOfWeek or 0,
		Locale = locale,
		Today = today,
		Theme = theme,
		InitialMonth = View.containing(initial),
		Follow = startSource,
		StatusFor = Status.range({ Start = startSource, End = endSource, Today = today, Selectable = selectable }),
		Band = true,
		BandEnds = Status.rangeEnds({ Start = startSource, End = endSource, Today = today, Selectable = selectable }),
		OnPick = function(date: Date)
			local s, e = startSource:Get(), endSource:Get()
			if s ~= nil and e == nil then
				local a, b = Calendar.normalizeRange(s, date)
				startSource:Set(a)
				endSource:Set(b)
				if props.OnChange then
					props.OnChange(a, b)
				end
			else
				endSource:Set(nil)
				startSource:Set(date)
				if props.OnChange then
					props.OnChange(date, nil)
				end
			end
		end,
	})

	return D.Frame {
		Name = "DockedRangePicker",
		baseModifier,
		props.Modifier or q.None,
		BackgroundColor3 = theme.Color.SurfaceContainerHigh,
		UICorner = Tokens.Shape.corner("Large"),
		Elevation.Shadow({ Level = 3, Theme = theme }),
		body.Frame,
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return RangeDocked
