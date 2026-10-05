--!strict
-- Pure spec for DatePicker/Calendar (plain `luau`, no engine).
local C = require("../src/DatePicker/Calendar")
type Date = C.Date

local count, failed = 0, 0
local function check(cond: boolean, msg: string)
	count += 1
	if not cond then
		failed += 1
		print("FAIL: " .. msg)
	end
end
local function eq(a: any, b: any, msg: string)
	check(a == b, ("%s (got %s, want %s)"):format(msg, tostring(a), tostring(b)))
end
local function iso(d: Date?): string
	return if d then C.formatISO(d) else "nil"
end
local function d(y: number, m: number, dd: number): Date
	return C.date(y, m, dd)
end
local function throws(f: () -> any, msg: string)
	local ok = pcall(f)
	check(not ok, msg .. " should throw")
end

-- leap years
for y, want in { [1900] = false, [2000] = true, [2024] = true, [2100] = false, [2400] = true, [2023] = false, [1600] = true, [4] = true } do
	eq(C.isLeapYear(y), want, "leap " .. y)
end

-- daysInMonth
local normal = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
for m = 1, 12 do
	eq(C.daysInMonth(2023, m), normal[m], "dim 2023-" .. m)
	eq(C.daysInMonth(2024, m), if m == 2 then 29 else normal[m], "dim 2024-" .. m)
end
throws(function() return C.daysInMonth(2024, 13) end, "dim month 13")
throws(function() return C.daysInMonth(2024, 0) end, "dim month 0")

-- validation
check(C.isValid(2024, 2, 29), "2024-02-29 valid")
check(not C.isValid(2025, 2, 29), "2025-02-29 invalid")
check(not C.isValid(1900, 2, 29), "1900-02-29 invalid")
check(not C.isValid(2025, 4, 31), "04-31 invalid")
check(not C.isValid(2025, 1, 0), "day 0 invalid")
check(not C.isValid(0, 1, 1), "year 0 invalid")
check(not C.isValid(10000, 1, 1), "year 10000 invalid")
check(not C.isValid(2025.5, 1, 1), "fractional year invalid")
check(not C.isValid(2025, 1, 1.5), "fractional day invalid")
throws(function() return C.date(2025, 2, 29) end, "date(2025,2,29)")
local ok, err = pcall(C.date, 2025, 2, 30)
check(not ok and string.find(tostring(err), "not a valid date", 1, true) ~= nil, "date error message")
check(table.isfrozen(d(2026, 10, 5)), "date frozen")

-- weekday anchors
local anchors: { { number } } = {
	{ 2000, 1, 1, 6 }, { 1970, 1, 1, 4 }, { 2026, 10, 5, 1 }, { 1900, 1, 1, 1 },
	{ 9999, 12, 31, 5 }, { 1, 1, 1, 1 }, { 2024, 2, 29, 4 }, { 2000, 2, 29, 2 },
}
for _, a in anchors do
	eq(C.weekday(d(a[1], a[2], a[3])), a[4], ("weekday %d-%d-%d"):format(a[1], a[2], a[3]))
end

-- dayOfYear
eq(C.dayOfYear(d(2024, 12, 31)), 366, "doy leap end")
eq(C.dayOfYear(d(2023, 12, 31)), 365, "doy end")
eq(C.dayOfYear(d(2024, 3, 1)), 61, "doy mar 1 leap")
eq(C.dayOfYear(d(2023, 3, 1)), 60, "doy mar 1")
eq(C.dayOfYear(d(2023, 1, 1)), 1, "doy jan 1")

-- ordinal anchors
eq(C.toOrdinal(d(1970, 1, 1)), 0, "ordinal epoch")
eq(C.toOrdinal(d(1970, 1, 2)), 1, "ordinal +1")
eq(C.toOrdinal(d(1969, 12, 31)), -1, "ordinal -1")
eq(C.toOrdinal(d(2000, 3, 1)), 11017, "ordinal 2000-03-01")

-- brute force: 1600-01-01 .. 2400-12-31, day by day, independent calendar walker
do
	local start = d(1600, 1, 1)
	local ord0 = C.toOrdinal(start)
	local y, m, dd = 1600, 1, 1
	local wd = C.weekday(start)
	local n = 0
	local bad = 0
	while not (y == 2401 and m == 1 and dd == 1) do
		local cur = d(y, m, dd)
		local o = C.toOrdinal(cur)
		if o ~= ord0 + n then bad += 1 end
		local back = C.fromOrdinal(o)
		if back.Year ~= y or back.Month ~= m or back.Day ~= dd then bad += 1 end
		if C.weekday(cur) ~= wd then bad += 1 end
		-- advance
		n += 1
		wd = (wd + 1) % 7
		dd += 1
		if dd > C.daysInMonth(y, m) then
			dd = 1
			m += 1
			if m > 12 then
				m = 1
				y += 1
			end
		end
	end
	eq(bad, 0, "brute force 1600..2400 mismatches")
	eq(n, 292560, "days 1600-01-01..2400-12-31 (2 x 146097 + 366)")
end

-- addDays
eq(iso(C.addDays(d(2024, 2, 28), 1)), "2024-02-29", "addDays leap")
eq(iso(C.addDays(d(2023, 2, 28), 1)), "2023-03-01", "addDays non-leap")
eq(iso(C.addDays(d(2026, 12, 31), 1)), "2027-01-01", "addDays year roll")
eq(iso(C.addDays(d(2026, 1, 1), -1)), "2025-12-31", "addDays back")
eq(iso(C.addDays(d(2026, 10, 5), 0)), "2026-10-05", "addDays 0")
eq(iso(C.addDays(d(2026, 10, 5), 365)), "2027-10-05", "addDays 365")
eq(iso(C.addDays(d(1, 1, 1), -5)), "0001-01-01", "addDays clamps at min")
eq(iso(C.addDays(d(9999, 12, 31), 5)), "9999-12-31", "addDays clamps at max")

-- addMonths / addYears
eq(iso(C.addMonths(d(2023, 1, 31), 1)), "2023-02-28", "Jan31+1m")
eq(iso(C.addMonths(d(2024, 1, 31), 1)), "2024-02-29", "Jan31+1m leap")
eq(iso(C.addMonths(d(2024, 3, 31), -1)), "2024-02-29", "Mar31-1m leap")
eq(iso(C.addMonths(d(2024, 10, 31), 1)), "2024-11-30", "Oct31+1m")
eq(iso(C.addMonths(d(2024, 11, 15), 3)), "2025-02-15", "Nov15+3m")
eq(iso(C.addMonths(d(2024, 1, 15), -1)), "2023-12-15", "Jan-1m")
eq(iso(C.addMonths(d(2024, 1, 15), -13)), "2022-12-15", "-13m")
eq(iso(C.addMonths(d(2024, 1, 31), 12)), "2025-01-31", "+12m")
eq(iso(C.addMonths(d(2024, 5, 5), 0)), "2024-05-05", "+0m")
eq(iso(C.addMonths(d(9999, 12, 5), 1)), "9999-12-31", "addMonths clamps max")
eq(iso(C.addMonths(d(1, 1, 5), -1)), "0001-01-01", "addMonths clamps min")
eq(iso(C.addYears(d(2024, 2, 29), 1)), "2025-02-28", "Feb29+1y")
eq(iso(C.addYears(d(2024, 2, 29), 4)), "2028-02-29", "Feb29+4y")
eq(iso(C.addYears(d(2024, 2, 29), -4)), "2020-02-29", "Feb29-4y")
eq(iso(C.addYears(d(2024, 2, 29), 100)), "2124-02-29", "Feb29+100y (2124 leap)")
eq(iso(C.addYears(d(2000, 2, 29), 100)), "2100-02-28", "2000 Feb29+100y (2100 not leap)")

-- diff / compare
eq(C.diffDays(d(2026, 10, 5), d(2026, 10, 1)), 4, "diffDays")
eq(C.diffDays(d(2026, 10, 1), d(2026, 10, 5)), -4, "diffDays neg")
eq(C.diffDays(d(2025, 1, 1), d(2024, 1, 1)), 366, "diffDays leap year")
eq(C.compare(d(2026, 10, 5), d(2026, 10, 5)), 0, "cmp eq")
eq(C.compare(d(2026, 10, 4), d(2026, 10, 5)), -1, "cmp day")
eq(C.compare(d(2026, 11, 1), d(2026, 10, 5)), 1, "cmp month")
eq(C.compare(d(2025, 12, 31), d(2026, 1, 1)), -1, "cmp year")
check(C.equals(d(2026, 1, 1), d(2026, 1, 1)), "equals")
check(C.isBefore(d(2026, 1, 1), d(2026, 1, 2)), "isBefore")
check(C.isAfter(d(2026, 1, 2), d(2026, 1, 1)), "isAfter")
check(not C.isBefore(d(2026, 1, 1), d(2026, 1, 1)), "isBefore eq")

-- clamp / range
local lo, hi = d(2026, 10, 10), d(2026, 10, 20)
eq(iso(C.clamp(d(2026, 10, 5), lo, hi)), "2026-10-10", "clamp low")
eq(iso(C.clamp(d(2026, 10, 25), lo, hi)), "2026-10-20", "clamp high")
eq(iso(C.clamp(d(2026, 10, 15), lo, hi)), "2026-10-15", "clamp mid")
eq(iso(C.clamp(d(2026, 10, 5), nil, hi)), "2026-10-05", "clamp open low")
eq(iso(C.clamp(d(2026, 10, 25), lo, nil)), "2026-10-25", "clamp open high")
check(C.isInRange(lo, lo, hi) and C.isInRange(hi, lo, hi), "range inclusive")
check(not C.isInRange(d(2026, 10, 9), lo, hi), "range below")
check(not C.isInRange(d(2026, 10, 21), lo, hi), "range above")
check(C.isInRange(d(2000, 1, 1), nil, nil), "range open")

-- weekdayOrder
eq(table.concat(C.weekdayOrder(), ","), "0,1,2,3,4,5,6", "order default")
eq(table.concat(C.weekdayOrder(1), ","), "1,2,3,4,5,6,0", "order monday")
eq(table.concat(C.weekdayOrder(6), ","), "6,0,1,2,3,4,5", "order saturday")
throws(function() return C.weekdayOrder(7) end, "order 7")

-- monthGrid
local function gridCheck(y: number, m: number, fdow: number, fixed: boolean)
	local grid = C.monthGrid(y, m, { FirstDayOfWeek = fdow, FixedWeeks = fixed })
	local label = ("grid %d-%d fdow=%d fixed=%s"):format(y, m, fdow, tostring(fixed))
	local dim = C.daysInMonth(y, m)
	local lead = (C.weekday(d(y, m, 1)) - fdow) % 7
	local rows = if fixed then 6 else math.ceil((lead + dim) / 7)
	eq(#grid, rows, label .. " rows")
	local inMonth = 0
	local prev: Date? = nil
	for _, row in grid do
		eq(#row, 7, label .. " cols")
		for c, cell in row do
			eq(cell.Weekday, C.weekdayOrder(fdow)[c], label .. " column weekday")
			eq(cell.Weekday, C.weekday(cell.Date), label .. " cell weekday")
			eq(cell.InMonth, cell.Date.Year == y and cell.Date.Month == m, label .. " InMonth")
			if cell.InMonth then
				inMonth += 1
			end
			if prev then
				eq(C.diffDays(cell.Date, prev), 1, label .. " consecutive")
			end
			prev = cell.Date
		end
	end
	eq(inMonth, dim, label .. " in-month count")
	eq(grid[1][lead + 1].Date.Day, 1, label .. " first cell")
end
for fdow = 0, 6 do
	-- every start weekday: Feb/Mar/Nov 2026 etc. plus whole year scans
	for y = 2023, 2026 do
		for m = 1, 12 do
			gridCheck(y, m, fdow, true)
			gridCheck(y, m, fdow, false)
		end
	end
end
-- every weekday as first-of-month gets covered above; assert explicitly
do
	local seen: { [number]: boolean } = {}
	for m = 1, 12 do
		seen[C.weekday(d(2026, m, 1))] = true
		seen[C.weekday(d(2025, m, 1))] = true
	end
	local all = true
	for w = 0, 6 do
		if not seen[w] then all = false end
	end
	check(all, "all weekdays occur as month start")
end
eq(#C.monthGrid(2026, 2, { FirstDayOfWeek = 0, FixedWeeks = false }), 4, "Feb 2026 Sun-start unfixed = 4 rows")
eq(#C.monthGrid(2026, 2), 6, "Feb 2026 default = 6 rows")
eq(#C.monthGrid(2026, 2, { FirstDayOfWeek = 1, FixedWeeks = false }), 5, "Feb 2026 Mon-start unfixed = 5 rows")
eq(#C.monthGrid(2026, 8, { FixedWeeks = false }), 6, "Aug 2026 (Sat start, 31d) = 6 rows")
do
	local g = C.monthGrid(2026, 10, { FirstDayOfWeek = 1 })
	eq(iso(g[1][1].Date), "2026-09-28", "Oct 2026 Monday grid starts 09-28")
	check(not g[1][1].InMonth, "09-28 outside")
	eq(iso(g[1][4].Date), "2026-10-01", "Oct 1 is Thursday col 4")
	eq(iso(g[6][7].Date), "2026-11-08", "last cell")
end
do
	local g = C.monthGrid(1, 1, { FirstDayOfWeek = 0 })
	eq(iso(g[1][1].Date), "0001-01-01", "edge clamp first cell")
	g = C.monthGrid(9999, 12)
	eq(iso(g[6][7].Date), "9999-12-31", "edge clamp last cell")
end
throws(function() return C.monthGrid(2026, 13) end, "monthGrid month 13")
throws(function() return C.monthGrid(2026, 1, { FirstDayOfWeek = 9 }) end, "monthGrid fdow 9")

-- navigation
check(C.canGoToPrevMonth(2026, 10, nil), "prev open")
check(C.canGoToPrevMonth(2026, 10, d(2026, 9, 30)), "prev: Sep ends on min")
check(not C.canGoToPrevMonth(2026, 10, d(2026, 10, 1)), "prev: min is Oct 1")
check(not C.canGoToPrevMonth(2026, 10, d(2026, 10, 15)), "prev: min mid Oct")
check(C.canGoToPrevMonth(2026, 10, d(2026, 9, 15)), "prev: min mid Sep")
check(not C.canGoToPrevMonth(1, 1, nil), "prev at year 1")
check(C.canGoToNextMonth(2026, 10, nil), "next open")
check(C.canGoToNextMonth(2026, 10, d(2026, 11, 1)), "next: Nov 1 is max")
check(not C.canGoToNextMonth(2026, 10, d(2026, 10, 31)), "next: max Oct 31")
check(C.canGoToNextMonth(2026, 12, d(2027, 1, 20)), "next across year")
check(not C.canGoToNextMonth(9999, 12, nil), "next at year 9999")
eq(iso(C.firstSelectableInMonth(2026, 10, nil, nil)), "2026-10-01", "first selectable open")
eq(iso(C.firstSelectableInMonth(2026, 10, d(2026, 10, 12), nil)), "2026-10-12", "first selectable min")
eq(iso(C.firstSelectableInMonth(2026, 10, d(2026, 10, 12), d(2026, 10, 12))), "2026-10-12", "single day")
eq(iso(C.firstSelectableInMonth(2026, 10, d(2026, 11, 1), nil)), "nil", "none after min")
eq(iso(C.firstSelectableInMonth(2026, 10, nil, d(2026, 9, 30))), "nil", "none before max")
eq(iso(C.firstSelectableInMonth(2026, 10, nil, nil, function(x: Date) return C.weekday(x) == 4 or C.weekday(x) == 5 end)), "2026-10-03", "skips disabled (Thu,Fri)")
eq(iso(C.firstSelectableInMonth(2026, 10, nil, nil, function() return true end)), "nil", "all disabled")

local t = d(2026, 10, 7) -- Wednesday
eq(iso(C.moveFocus(t, "left")), "2026-10-06", "left")
eq(iso(C.moveFocus(t, "right")), "2026-10-08", "right")
eq(iso(C.moveFocus(t, "up")), "2026-09-30", "up")
eq(iso(C.moveFocus(t, "down")), "2026-10-14", "down")
eq(iso(C.moveFocus(t, "pageUp")), "2026-09-07", "pageUp")
eq(iso(C.moveFocus(t, "pageDown")), "2026-11-07", "pageDown")
eq(iso(C.moveFocus(d(2026, 1, 31), "pageDown")), "2026-02-28", "pageDown clamps day")
eq(iso(C.moveFocus(t, "home")), "2026-10-04", "home Sun-start")
eq(iso(C.moveFocus(t, "end")), "2026-10-10", "end Sun-start")
eq(iso(C.moveFocus(t, "home", { FirstDayOfWeek = 1 })), "2026-10-05", "home Mon-start")
eq(iso(C.moveFocus(t, "end", { FirstDayOfWeek = 1 })), "2026-10-11", "end Mon-start")
eq(iso(C.moveFocus(d(2026, 10, 5), "home", { FirstDayOfWeek = 1 })), "2026-10-05", "home on first day")
eq(iso(C.moveFocus(d(2026, 10, 4), "home", { FirstDayOfWeek = 1 })), "2026-09-28", "home Sunday Mon-start")
eq(iso(C.moveFocus(d(2026, 10, 4), "end", { FirstDayOfWeek = 1 })), "2026-10-04", "end on last day")
local bounds: C.FocusOptions = { Min = d(2026, 10, 3), Max = d(2026, 10, 20) }
eq(iso(C.moveFocus(d(2026, 10, 3), "left", bounds)), "2026-10-03", "left clamped at min")
eq(iso(C.moveFocus(d(2026, 10, 5), "up", bounds)), "2026-10-03", "up clamped at min")
eq(iso(C.moveFocus(d(2026, 10, 20), "right", bounds)), "2026-10-20", "right clamped at max")
eq(iso(C.moveFocus(d(2026, 10, 18), "pageDown", bounds)), "2026-10-20", "page clamped at max")
eq(iso(C.moveFocus(d(2026, 10, 5), "home", { Min = d(2026, 10, 5) })), "2026-10-05", "home clamped (Sun-start, min Mon)")
throws(function() return C.moveFocus(t, "bogus" :: any) end, "unknown action")

-- ISO parse / format
eq(C.formatISO(d(2026, 10, 5)), "2026-10-05", "formatISO")
eq(C.formatISO(d(5, 1, 2)), "0005-01-02", "formatISO pad")
do
	local p, why = C.parseISO("2026-10-05")
	eq(iso(p), "2026-10-05", "parseISO ok")
	check(why == nil, "parseISO no reason")
	for _, bad in { "2025-02-29", "2026-13-01", "2026-00-10", "2026-10-32", "2026-1-5", "20261005", "", "abc", "2026-10-05x", " 2026-10-05", "0000-01-01" } do
		local r, reason = C.parseISO(bad)
		check(r == nil and reason ~= nil, "parseISO rejects '" .. bad .. "'")
	end
	local _, reason = C.parseISO("2025-02-29")
	check(reason ~= nil and string.find(reason, "no day 29", 1, true) ~= nil, "parseISO reason text")
	-- round trip over a span
	local cur = d(1999, 12, 1)
	local bad = 0
	for _ = 1, 2000 do
		local back = C.parseISO(C.formatISO(cur))
		if not back or not C.equals(back, cur) then bad += 1 end
		cur = C.addDays(cur, 1)
	end
	eq(bad, 0, "ISO round trip")
end

-- format
local fd = d(2026, 10, 5)
eq(C.format(fd, "YYYY-MM-DD"), "2026-10-05", "fmt iso")
eq(C.format(fd, "M/D/YYYY"), "10/5/2026", "fmt M/D")
eq(C.format(fd, "MMM D"), "Oct 5", "fmt MMM")
eq(C.format(fd, "MMMM D, YYYY"), "October 5, 2026", "fmt MMMM")
eq(C.format(fd, "dddd"), "Monday", "fmt dddd")
eq(C.format(fd, "ddd, MMM D"), "Mon, Oct 5", "fmt ddd")
eq(C.format(fd, "DD.MM.YY"), "05.10.YY", "fmt: YY is not a token, passes through")
eq(C.format(fd, "[Day] D"), "Day 5", "fmt escape")
eq(C.format(fd, "[unclosed D"), "[unclosed 5", "fmt unclosed bracket literal")
eq(C.format(fd, "YYYY년 M월 D일", "ko"), "2026년 10월 5일", "fmt ko long")
eq(C.format(fd, "dddd", "ko"), "월요일", "fmt ko dddd")
eq(C.format(fd, "ddd", "ko"), "월", "fmt ko ddd")
eq(C.format(fd, "MMMM", "ko"), "10월", "fmt ko month")
eq(C.format(fd, C.locales.ko.LongPattern, "ko"), "2026년 10월 5일", "ko LongPattern")
eq(C.format(fd, C.locales.en.LongPattern), "October 5, 2026", "en LongPattern")
eq(C.format(d(7, 3, 9), "YYYY-MM-DD"), "0007-03-09", "fmt pad year")
throws(function() return C.format(fd, "D", "xx") end, "unknown locale")
for wd = 0, 6 do
	eq(C.weekdayName("ko", wd, true), ({ "일", "월", "화", "수", "목", "금", "토" })[wd + 1], "ko wd " .. wd)
end
eq(C.monthName("ko", 12), "12월", "ko month 12")
eq(C.monthName("en", 2, true), "Feb", "en month short")

-- parseLocalized
do
	local good: { { string } } = {
		{ "2026-10-05", "en" }, { "2026/10/05", "en" }, { "2026.10.05", "en" }, { "2026.10.5.", "ko" },
		{ "  2026-10-5  ", "en" }, { "2026/1/5", "en" }, { "2026 . 10 . 05", "en" },
		{ "2026년 10월 5일", "ko" }, { "2026년10월5일", "ko" }, { "2026년 10월 05일", "en" },
		{ "October 5, 2026", "en" }, { "Oct 5, 2026", "en" }, { "oct. 5 2026", "en" },
	}
	for _, g in good do
		local r, why = C.parseLocalized(g[1], g[2])
		local want = if g[1]:find("1/5", 1, true) then "2026-01-05" else "2026-10-05"
		eq(iso(r), want, ("parseLocalized '%s' (%s) %s"):format(g[1], g[2], tostring(why)))
	end
	local bad: { string } = {
		"2025-02-29", "2025/02/29", "2025년 2월 29일", "2026-13-01", "2026-10-00", "", "   ", "hello",
		"2026-10/05", "10/5/2026", "2026년 13월 1일", "Foo 5, 2026", "February 30, 2026", "0000-01-01", "2026-10-05-1",
	}
	for _, b in bad do
		local r, why = C.parseLocalized(b, "en")
		check(r == nil and why ~= nil, "parseLocalized rejects '" .. b .. "'")
	end
	local _, why = C.parseLocalized("2025-02-29", "en")
	check(why ~= nil and string.find(why, "2025-02", 1, true) ~= nil, "reject reason names month")
	-- format -> parseLocalized round trips
	local cur = d(2023, 12, 20)
	local badc = 0
	for _ = 1, 400 do
		for _, loc in { "en", "ko" } do
			local text = C.format(cur, (C.locales :: { [string]: C.Locale })[loc].LongPattern, loc)
			local back = C.parseLocalized(text, loc)
			if not back or not C.equals(back, cur) then badc += 1 end
		end
		cur = C.addDays(cur, 1)
	end
	eq(badc, 0, "localized round trip")
end

-- ranges
do
	local a, b = d(2026, 10, 9), d(2026, 10, 2)
	local s, e = C.normalizeRange(a, b)
	eq(iso(s), "2026-10-02", "normalize start")
	eq(iso(e), "2026-10-09", "normalize end")
	s, e = C.normalizeRange(b, a)
	eq(iso(s) .. iso(e), "2026-10-022026-10-09", "normalize already ordered")
	check(C.rangeContains(b, a, d(2026, 10, 2)), "range contains start")
	check(C.rangeContains(b, a, d(2026, 10, 9)), "range contains end")
	check(C.rangeContains(a, b, d(2026, 10, 5)), "range contains (reversed args)")
	check(not C.rangeContains(b, a, d(2026, 10, 10)), "range excludes after")
	check(not C.rangeContains(b, a, d(2026, 10, 1)), "range excludes before")
	check(C.rangeContains(b, b, b), "single-day range")
end

-- today
eq(iso(C.today(function() return 0 end)), "1970-01-01", "today epoch")
eq(iso(C.today(function() return 86399 end)), "1970-01-01", "today end of day")
eq(iso(C.today(function() return 86400 end)), "1970-01-02", "today next day")
eq(iso(C.today(function() return -1 end)), "1969-12-31", "today negative")
eq(iso(C.today(function() return 1759622400 end)), "2025-10-05", "today 2025-10-05T00:00Z")
eq(iso(C.today(function() return 1759622400 - 1 end)), "2025-10-04", "today 1s before")
eq(iso(C.today(function() return 1759622400 - 1 end, 9 * 3600)), "2025-10-05", "today KST offset")
eq(iso(C.today(function() return 1759622400 end, -5 * 3600)), "2025-10-04", "today negative offset")
check(C.isValid(C.today().Year, C.today().Month, C.today().Day), "today() default valid")

print(("calendar spec: %d checks, %d failed"):format(count, failed))
if failed > 0 then
	error("calendar spec failed")
end
