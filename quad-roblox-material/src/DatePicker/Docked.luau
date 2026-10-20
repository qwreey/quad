--!strict
--[[
	M3 docked date picker (the calendar that opens under a date field), as a plain component.

	    local value = q.Source<<Date?>>(nil)
	    DatePicker.Docked({ Value = value, Min = Calendar.date(2026, 1, 1), Locale = "ko" })

	Props (all `read`)
	  Value           Source<Date?>      the picked date (two-way: a click `:Set`s it; an external `:Set` shows it
	                                     and — when it lies outside the visible month — moves the view to its
	                                     month, so "the picker shows the value"; the user's own navigation is not
	                                     overridden by anything else)
	  Min, Max        Date?              inclusive bounds; earlier/later days are disabled, prev/next stop at the
	                                     bounds, the year grid spans [Min.Year, Max.Year] (open end: visible year -/+ 100)
	  IsDisabled      (Date) -> boolean  extra disabled days (evaluated per cell when the month changes; static —
	                                     rebuild the picker to change the rule)
	  FirstDayOfWeek  0..6               0 = Sunday (default), 1 = Monday ...
	  Locale          "en" | "ko"        header text, weekday letters, patterns (default "en")
	  Today           Date?              the highlighted "today"; default `Calendar.today(nil, UtcOffset)`
	  UtcOffset       number?            seconds east of UTC for the default Today (the module never reads the
	                                     machine time zone: pass e.g. `9 * 3600` for KST)
	  OnChange        ((Date) -> ())?    called after Value was set by a USER click / Enter
	  Theme, Modifier, Hooks             as every kit component (Modifier = Frame Modifier, applied after the base)
	Returns the host Frame (360 x 396, surfaceContainerHigh, shape Large, elevation 3 UIShadow).

	INSTANCES at rest (measured in test/spec.datepicker.luau): host Frame + UICorner + UIShadow, header
	(label Button 7 + 2 GlyphButtons 6 each — the default `Icons` images: ImageButton + UICorner + state layer 3 + Icon;
	4 each with the glyph fallback, whose text host has no UICorner — GlyphButton.luau "Glyph clipping"),
	month view 135 (7 weekday labels + days Frame + 42 chips * 3 + wrapper),
	year grid ~85 (windowed — see YearView.luau). The 42 day cells are created once and survive every month change.

	M3 deviations: day chips are 40 px hit targets (M3: 48 dp touch slot); out-of-month days are hidden (as M3);
	state layers are the chip's own background transparency (no separate layer Frame); arrow/dropdown glyphs
	are text characters; no swipe-between-months gesture.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Elevation = require("../Elevation")
local Body = require("./Body")
local Calendar = require("./Calendar")
local Status = require("./Status")
local View = require("./View")
local Frame = q.Elem "Frame"
local FrameModifier = q.Modifier "Frame"
local pickerName = FrameModifier():Name("DockedDatePicker")

type Date = Calendar.Date

export type Locale = "en" | "ko"

export type Props = {
	read Value: q.Source<Date?>,
	read Min: Date?,
	read Max: Date?,
	read IsDisabled: ((date: Date) -> boolean)?,
	read FirstDayOfWeek: number?,
	read Locale: Locale?,
	read Today: Date?,
	read UtcOffset: number?,
	read OnChange: ((date: Date) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.ModifierInto<Frame>?,
	read Hooks: Util.Hooks?,
}

local baseModifier = FrameModifier():Size(UDim2.fromOffset(Body.Width, Body.Height)):BorderSizePixel(0)

local function Docked(props: Props): Frame
	local theme = Theme.resolve(props.Theme)
	local locale: Locale = props.Locale or "en"
	local today = props.Today or Calendar.today(nil, props.UtcOffset)
	local value = props.Value
	local selectable = Status.selectable(props.Min, props.Max, props.IsDisabled)
	local current = value:Get()
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
		Follow = value,
		StatusFor = Status.single({ Value = value, Today = today, Selectable = selectable }),
		OnPick = function(date: Date)
			value:Set(date)
			if props.OnChange then
				props.OnChange(date)
			end
		end,
	})

	return Frame {
		pickerName,
		baseModifier,
		props.Modifier or q.None,
		BackgroundColor3 = theme.Color.SurfaceContainerHigh,
		UICorner = Tokens.Shape.corner("Large"),
		Elevation.Shadow({ Level = 3, Theme = theme }),
		body.Frame,
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return Docked
