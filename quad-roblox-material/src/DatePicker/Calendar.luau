--!strict
--[[
Calendar: pure date math for a Material 3 date picker. No engine, no quad, no globals except the
standard library. `os.time` is touched only inside `Calendar.today` (and only when no clock is injected).

Calendar system: proleptic Gregorian, supported years 1..9999. Operations that would leave that range
CLAMP to 0001-01-01 / 9999-12-31 (a UI never needs an error from "next month" at year 9999).

VALUE
  Date = { Year: number, Month: number (1-12), Day: number }   -- frozen; compare with Calendar.equals

CONSTRUCTION / VALIDATION
  date(y, m, d): Date                  validates (integers, real calendar day), errors with a clear message
  isValid(y, m, d): boolean
  MIN_DATE / MAX_DATE                  0001-01-01 / 9999-12-31
  isLeapYear(y): boolean
  daysInMonth(y, m): number            errors for m outside 1..12

ARITHMETIC
  toOrdinal(d): number                 days since 1970-01-01 (negative before). Hinnant days_from_civil
  fromOrdinal(n): Date                 inverse, clamped to the supported range
  weekday(d): number                   0 = Sunday .. 6 = Saturday
  dayOfYear(d): number                 1..366
  addDays(d, n) / addMonths(d, n) / addYears(d, n)
                                       months/years clamp the day (Jan 31 + 1 month = Feb 28/29,
                                       Feb 29 + 1 year = Feb 28)
  diffDays(a, b): number               a - b in days
  compare(a, b): -1 | 0 | 1            equals / isBefore / isAfter
  clamp(d, min?, max?): Date           isInRange(d, min?, max?): boolean   (bounds inclusive, nil = open)

MONTH GRID
  weekdayOrder(firstDayOfWeek?): {number}              header order, e.g. 1 -> {1,2,3,4,5,6,0}
  monthGrid(year, month, opts?): {{Cell}}              Cell = { Date, InMonth, Weekday }
      opts.FirstDayOfWeek 0..6 (default 0 = Sunday), opts.FixedWeeks (default true = always 6 rows;
      false = 4..6 rows). Cells outside the month are the neighbouring months' days (InMonth = false).
      At the very edges of the supported range the outside cells clamp (duplicates of the edge date).

NAVIGATION (all bounds inclusive, nil = open)
  canGoToPrevMonth(year, month, min?): boolean         false if the previous month ends before `min`
  canGoToNextMonth(year, month, max?): boolean         false if the next month starts after `max`
  firstSelectableInMonth(year, month, min?, max?, isDisabled?): Date?
  moveFocus(date, action, opts?): Date
      action: "left" | "right" | "up" | "down" | "pageUp" | "pageDown" | "home" | "end"
      left/right +-1 day, up/down +-7 days, page +-1 month (day clamped), home/end = first/last day of
      the week row (respects opts.FirstDayOfWeek); result clamped to opts.Min / opts.Max.
      Unknown action errors. Does NOT skip disabled dates (the UI decides).

PARSE / FORMAT
  formatISO(d): string                 "2026-10-05"
  parseISO(text): (Date?, string?)     strict YYYY-MM-DD; on failure nil + reason
  locales: { en: Locale, ko: Locale }  Locale = { Months, MonthsShort, Weekdays (Sun first),
                                       WeekdaysShort, LongPattern, FirstDayOfWeek }
  monthName(locale, month, short?) / weekdayName(locale, weekday, short?)
  format(d, pattern, locale?): string  tokens (longest match first): YYYY MMMM MMM MM M DD D dddd ddd.
      Anything else is literal; wrap literal text in [brackets] to protect token letters: "[Day] D".
      `locale` is a key ("en" default, "ko") ; unknown key errors.
  parseLocalized(text, locale?): (Date?, string?)
      accepts YYYY-MM-DD, YYYY/MM/DD, YYYY.MM.DD (month/day may be 1 or 2 digits, spaces around
      separators tolerated, trailing "." tolerated), Korean "2026년 10월 5일" (any locale), and for
      `en` "October 5, 2026" / "Oct 5, 2026". Rejects impossible dates (2025-02-29) with a reason.

RANGES
  normalizeRange(a, b): (Date, Date)   swapped so start <= end
  rangeContains(start, end, d): boolean   inclusive, start/end may be given in any order

CLOCK
  today(clock?, offsetSeconds?): Date  `clock` returns unix seconds (default os.time, which is UTC).
      The result is the calendar date at UTC + offsetSeconds (default 0 = UTC). To get local time pass
      the user's UTC offset in seconds; the module never reads the machine time zone.
]]

export type Date = { read Year: number, read Month: number, read Day: number }
export type Cell = { read Date: Date, read InMonth: boolean, read Weekday: number }
export type Locale = {
	Months: { string },
	MonthsShort: { string },
	Weekdays: { string },
	WeekdaysShort: { string },
	LongPattern: string,
	FirstDayOfWeek: number,
}
export type GridOptions = { FirstDayOfWeek: number?, FixedWeeks: boolean? }
export type FocusAction = "left" | "right" | "up" | "down" | "pageUp" | "pageDown" | "home" | "end"
export type FocusOptions = { FirstDayOfWeek: number?, Min: Date?, Max: Date? }

local MIN_YEAR = 1
local MAX_YEAR = 9999
local floor = math.floor

local Calendar = {}

local DAYS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function isInt(n: any): boolean
	return type(n) == "number" and n == floor(n) and n > -math.huge and n < math.huge
end

local function isLeapYear(y: number): boolean
	return y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)
end
Calendar.isLeapYear = isLeapYear

local function daysInMonth(y: number, m: number): number
	if not isInt(m) or m < 1 or m > 12 then
		error(("Calendar.daysInMonth: month must be an integer 1..12, got %s"):format(tostring(m)), 2)
	end
	if m == 2 and isLeapYear(y) then
		return 29
	end
	return DAYS[m]
end
Calendar.daysInMonth = daysInMonth

local function isValid(y: any, m: any, d: any): boolean
	if not (isInt(y) and isInt(m) and isInt(d)) then
		return false
	end
	if y < MIN_YEAR or y > MAX_YEAR or m < 1 or m > 12 or d < 1 then
		return false
	end
	return d <= daysInMonth(y, m)
end
Calendar.isValid = isValid

local function rawDate(y: number, m: number, d: number): Date
	return table.freeze({ Year = y, Month = m, Day = d })
end

function Calendar.date(y: number, m: number, d: number): Date
	if not isValid(y, m, d) then
		error(
			("Calendar.date: %s-%s-%s is not a valid date (years %d..%d, proleptic Gregorian)"):format(
				tostring(y),
				tostring(m),
				tostring(d),
				MIN_YEAR,
				MAX_YEAR
			),
			2
		)
	end
	return rawDate(y, m, d)
end

Calendar.MIN_DATE = rawDate(MIN_YEAR, 1, 1)
Calendar.MAX_DATE = rawDate(MAX_YEAR, 12, 31)

-- Howard Hinnant's days_from_civil: days since 1970-01-01.
local function toOrdinal(d: Date): number
	local y, m = d.Year, d.Month
	if m <= 2 then
		y -= 1
	end
	local era = floor(y / 400)
	local yoe = y - era * 400
	local mp = (m + 9) % 12
	local doy = floor((153 * mp + 2) / 5) + d.Day - 1
	local doe = yoe * 365 + floor(yoe / 4) - floor(yoe / 100) + doy
	return era * 146097 + doe - 719468
end
Calendar.toOrdinal = toOrdinal

local MIN_ORD = toOrdinal(Calendar.MIN_DATE)
local MAX_ORD = toOrdinal(Calendar.MAX_DATE)

local function fromOrdinal(n: number): Date
	if not isInt(n) then
		error("Calendar.fromOrdinal: ordinal must be an integer", 2)
	end
	if n < MIN_ORD then
		return Calendar.MIN_DATE
	elseif n > MAX_ORD then
		return Calendar.MAX_DATE
	end
	local z = n + 719468
	local era = floor(z / 146097)
	local doe = z - era * 146097
	local yoe = floor((doe - floor(doe / 1460) + floor(doe / 36524) - floor(doe / 146096)) / 365)
	local y = yoe + era * 400
	local doy = doe - (365 * yoe + floor(yoe / 4) - floor(yoe / 100))
	local mp = floor((5 * doy + 2) / 153)
	local d = doy - floor((153 * mp + 2) / 5) + 1
	local m = if mp < 10 then mp + 3 else mp - 9
	if m <= 2 then
		y += 1
	end
	return rawDate(y, m, d)
end
Calendar.fromOrdinal = fromOrdinal

-- 1970-01-01 (ordinal 0) was a Thursday (4).
local function weekday(d: Date): number
	return (toOrdinal(d) + 4) % 7
end
Calendar.weekday = weekday

function Calendar.dayOfYear(d: Date): number
	return toOrdinal(d) - toOrdinal(rawDate(d.Year, 1, 1)) + 1
end

local function addDays(d: Date, n: number): Date
	return fromOrdinal(toOrdinal(d) + n)
end
Calendar.addDays = addDays

local function addMonths(d: Date, n: number): Date
	local total = d.Year * 12 + (d.Month - 1) + n
	local y = floor(total / 12)
	if y < MIN_YEAR then
		return Calendar.MIN_DATE
	elseif y > MAX_YEAR then
		return Calendar.MAX_DATE
	end
	local m = total % 12 + 1
	return rawDate(y, m, math.min(d.Day, daysInMonth(y, m)))
end
Calendar.addMonths = addMonths

function Calendar.addYears(d: Date, n: number): Date
	return addMonths(d, n * 12)
end

function Calendar.diffDays(a: Date, b: Date): number
	return toOrdinal(a) - toOrdinal(b)
end

local function compare(a: Date, b: Date): number
	if a.Year ~= b.Year then
		return if a.Year < b.Year then -1 else 1
	elseif a.Month ~= b.Month then
		return if a.Month < b.Month then -1 else 1
	elseif a.Day ~= b.Day then
		return if a.Day < b.Day then -1 else 1
	end
	return 0
end
Calendar.compare = compare

function Calendar.equals(a: Date, b: Date): boolean
	return compare(a, b) == 0
end
function Calendar.isBefore(a: Date, b: Date): boolean
	return compare(a, b) < 0
end
function Calendar.isAfter(a: Date, b: Date): boolean
	return compare(a, b) > 0
end

local function clamp(d: Date, min: Date?, max: Date?): Date
	if min and compare(d, min) < 0 then
		return min
	end
	if max and compare(d, max) > 0 then
		return max
	end
	return d
end
Calendar.clamp = clamp

local function isInRange(d: Date, min: Date?, max: Date?): boolean
	if min and compare(d, min) < 0 then
		return false
	end
	if max and compare(d, max) > 0 then
		return false
	end
	return true
end
Calendar.isInRange = isInRange

-- Month grid ----------------------------------------------------------------------------------------

local function checkFirstDay(fdow: any): number
	if fdow == nil then
		return 0
	end
	if not isInt(fdow) or fdow < 0 or fdow > 6 then
		error(("Calendar: FirstDayOfWeek must be an integer 0..6, got %s"):format(tostring(fdow)), 3)
	end
	return fdow
end

function Calendar.weekdayOrder(firstDayOfWeek: number?): { number }
	local f = checkFirstDay(firstDayOfWeek)
	local out = {}
	for i = 0, 6 do
		out[i + 1] = (f + i) % 7
	end
	return out
end

function Calendar.monthGrid(year: number, month: number, opts: GridOptions?): { { Cell } }
	if not isValid(year, month, 1) then
		error(("Calendar.monthGrid: invalid month %s-%s"):format(tostring(year), tostring(month)), 2)
	end
	local f = checkFirstDay(opts and opts.FirstDayOfWeek)
	local fixed = true
	if opts and opts.FixedWeeks == false then
		fixed = false
	end
	local first = rawDate(year, month, 1)
	local lead = (weekday(first) - f) % 7
	local dim = daysInMonth(year, month)
	local rows = if fixed then 6 else math.ceil((lead + dim) / 7)
	local startOrd = toOrdinal(first) - lead
	local grid: { { Cell } } = {}
	for r = 1, rows do
		local row: { Cell } = {}
		for c = 1, 7 do
			local ord = startOrd + (r - 1) * 7 + (c - 1)
			local d = fromOrdinal(ord)
			row[c] = table.freeze({
				Date = d,
				InMonth = ord >= toOrdinal(first) and ord < toOrdinal(first) + dim,
				Weekday = (ord + 4) % 7,
			})
		end
		grid[r] = row
	end
	return grid
end

-- Navigation -----------------------------------------------------------------------------------------

function Calendar.canGoToPrevMonth(year: number, month: number, min: Date?): boolean
	local prevEnd = addDays(rawDate(year, month, 1), -1)
	if year == MIN_YEAR and month == 1 then
		return false
	end
	return min == nil or compare(prevEnd, min) >= 0
end

function Calendar.canGoToNextMonth(year: number, month: number, max: Date?): boolean
	if year == MAX_YEAR and month == 12 then
		return false
	end
	local nextStart = addDays(rawDate(year, month, daysInMonth(year, month)), 1)
	return max == nil or compare(nextStart, max) <= 0
end

function Calendar.firstSelectableInMonth(
	year: number,
	month: number,
	min: Date?,
	max: Date?,
	isDisabled: ((Date) -> boolean)?
): Date?
	for day = 1, daysInMonth(year, month) do
		local d = rawDate(year, month, day)
		if isInRange(d, min, max) and not (isDisabled and isDisabled(d)) then
			return d
		end
	end
	return nil
end

function Calendar.moveFocus(date: Date, action: FocusAction, opts: FocusOptions?): Date
	local f = checkFirstDay(opts and opts.FirstDayOfWeek)
	local result: Date
	if action == "left" then
		result = addDays(date, -1)
	elseif action == "right" then
		result = addDays(date, 1)
	elseif action == "up" then
		result = addDays(date, -7)
	elseif action == "down" then
		result = addDays(date, 7)
	elseif action == "pageUp" then
		result = addMonths(date, -1)
	elseif action == "pageDown" then
		result = addMonths(date, 1)
	elseif action == "home" then
		result = addDays(date, -((weekday(date) - f) % 7))
	elseif action == "end" then
		result = addDays(date, 6 - ((weekday(date) - f) % 7))
	else
		error(("Calendar.moveFocus: unknown action %q"):format(tostring(action)), 2)
	end
	return clamp(result, opts and opts.Min, opts and opts.Max)
end

-- Locales / format / parse -----------------------------------------------------------------------------

Calendar.locales = {
	en = {
		Months = {
			"January", "February", "March", "April", "May", "June",
			"July", "August", "September", "October", "November", "December",
		},
		MonthsShort = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" },
		Weekdays = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" },
		WeekdaysShort = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },
		LongPattern = "MMMM D, YYYY",
		FirstDayOfWeek = 0,
	} :: Locale,
	ko = {
		Months = { "1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월" },
		MonthsShort = { "1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월" },
		Weekdays = { "일요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일" },
		WeekdaysShort = { "일", "월", "화", "수", "목", "금", "토" },
		LongPattern = "YYYY년 M월 D일",
		FirstDayOfWeek = 0,
	} :: Locale,
}

local function getLocale(key: string?): Locale
	local k = key or "en"
	local loc = (Calendar.locales :: { [string]: Locale })[k]
	if not loc then
		error(("Calendar: unknown locale %q"):format(tostring(k)), 3)
	end
	return loc
end

function Calendar.monthName(locale: string?, month: number, short: boolean?): string
	local loc = getLocale(locale)
	return (if short then loc.MonthsShort else loc.Months)[month]
end

function Calendar.weekdayName(locale: string?, wd: number, short: boolean?): string
	local loc = getLocale(locale)
	return (if short then loc.WeekdaysShort else loc.Weekdays)[wd + 1]
end

function Calendar.formatISO(d: Date): string
	return ("%04d-%02d-%02d"):format(d.Year, d.Month, d.Day)
end

-- token list ordered so that a longer token wins over its prefix
local TOKENS = { "YYYY", "MMMM", "MMM", "MM", "M", "DD", "D", "dddd", "ddd" }

function Calendar.format(d: Date, pattern: string, locale: string?): string
	local loc = getLocale(locale)
	local out = {}
	local i = 1
	local n = #pattern
	while i <= n do
		local ch = pattern:sub(i, i)
		if ch == "[" then
			local close = pattern:find("]", i + 1, true)
			if close then
				table.insert(out, pattern:sub(i + 1, close - 1))
				i = close + 1
				continue
			end
		end
		local matched = false
		for _, tok in TOKENS do
			if pattern:sub(i, i + #tok - 1) == tok then
				local text: string
				if tok == "YYYY" then
					text = ("%04d"):format(d.Year)
				elseif tok == "MMMM" then
					text = loc.Months[d.Month]
				elseif tok == "MMM" then
					text = loc.MonthsShort[d.Month]
				elseif tok == "MM" then
					text = ("%02d"):format(d.Month)
				elseif tok == "M" then
					text = tostring(d.Month)
				elseif tok == "DD" then
					text = ("%02d"):format(d.Day)
				elseif tok == "D" then
					text = tostring(d.Day)
				elseif tok == "dddd" then
					text = loc.Weekdays[weekday(d) + 1]
				else
					text = loc.WeekdaysShort[weekday(d) + 1]
				end
				table.insert(out, text)
				i += #tok
				matched = true
				break
			end
		end
		if not matched then
			table.insert(out, ch)
			i += 1
		end
	end
	return table.concat(out)
end

local function build(ys: string, ms: string, ds: string): (Date?, string?)
	local y, m, d = tonumber(ys), tonumber(ms), tonumber(ds)
	if y == nil or m == nil or d == nil then
		return nil, "not a number"
	end
	if y < MIN_YEAR or y > MAX_YEAR then
		return nil, ("year %d is outside %d..%d"):format(y, MIN_YEAR, MAX_YEAR)
	end
	if m < 1 or m > 12 then
		return nil, ("month %d is not between 1 and 12"):format(m)
	end
	if d < 1 or d > daysInMonth(y, m) then
		return nil, ("%d-%02d has no day %d"):format(y, m, d)
	end
	return rawDate(y, m, d), nil
end

function Calendar.parseISO(text: string): (Date?, string?)
	if type(text) ~= "string" then
		return nil, "expected a string"
	end
	local y, m, d = text:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
	if not (y and m and d) then
		return nil, "expected YYYY-MM-DD"
	end
	return build(y, m, d)
end

function Calendar.parseLocalized(text: string, locale: string?): (Date?, string?)
	if type(text) ~= "string" then
		return nil, "expected a string"
	end
	local loc = getLocale(locale)
	local s = text:match("^%s*(.-)%s*$") :: string
	if s == "" then
		return nil, "empty"
	end
	-- numeric: separators must match each other
	for _, sep in { "%-", "/", "%." } do
		local y, m, d = s:match("^(%d%d%d%d)%s*" .. sep .. "%s*(%d%d?)%s*" .. sep .. "%s*(%d%d?)%.?$")
		if y and m and d then
			return build(y, m, d)
		end
	end
	-- Korean
	local ky, km, kd = s:match("^(%d%d%d%d)년%s*(%d%d?)월%s*(%d%d?)일$")
	if ky and km and kd then
		return build(ky, km, kd)
	end
	-- named month, e.g. "October 5, 2026" (matches against the locale's month names)
	local mon, dd, yy = s:match("^(%a+)%.?%s+(%d%d?),?%s+(%d%d%d%d)$")
	if mon and dd and yy then
		local lower = mon:lower()
		for i = 1, 12 do
			if loc.Months[i]:lower() == lower or loc.MonthsShort[i]:lower() == lower then
				return build(yy, tostring(i), dd)
			end
		end
		return nil, ("unknown month name %q"):format(mon)
	end
	return nil, "unrecognized date format"
end

-- Ranges -----------------------------------------------------------------------------------------------

function Calendar.normalizeRange(a: Date, b: Date): (Date, Date)
	if compare(a, b) <= 0 then
		return a, b
	end
	return b, a
end

function Calendar.rangeContains(start: Date, stop: Date, d: Date): boolean
	local s, e = Calendar.normalizeRange(start, stop)
	return compare(d, s) >= 0 and compare(d, e) <= 0
end

-- Clock ------------------------------------------------------------------------------------------------

function Calendar.today(clock: (() -> number)?, offsetSeconds: number?): Date
	local t = (clock or os.time)()
	return fromOrdinal(floor((t + (offsetSeconds or 0)) / 86400))
end

return Calendar
