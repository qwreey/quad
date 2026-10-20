--!strict
local H = require("./support/harness")
local ClickSink = require("./support/clicksink")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local Frame = q.Elem "Frame"
local Tokens = require("../src/Tokens")
local Overlay = require("../src/Overlay")
local Interactive = require("../src/Interactive")
local DatePicker = require("../src/DatePicker")
local Calendar = require("../src/DatePicker/Calendar")
local IconsModule = require("../src/Icons")
local Bounded = require("./support/bounded")
local Docked = DatePicker.Docked
local RangeDocked = DatePicker.RangeDocked
local Modal = DatePicker.Modal

local UIS = H.UserInputService
local GuiService = H.GuiService
local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections + #u.InputBegan.connections
end
local baseConns = uisConns()
local L = Tokens.Color.Light

type Date = Calendar.Date
local function date(y: number, m: number, d: number): Date
	return Calendar.date(y, m, d)
end
local function iso(d: Date?): string
	return if d then Calendar.formatISO(d) else "nil"
end

local function named(root: any, name: string): { any }
	return H.findAll(root, function(c: any)
		return c.Name == name
	end)
end
local function days(root: any): { any }
	return named(root, "Day")
end
local function buttonLabel(btn: any): string
	return H.find(btn, "Label").Text
end
-- the month/year toggle: first "Button" in the body
local function headerButton(root: any): any
	return named(root, "Button")[1]
end
-- the month-year text + the year-menu arrow: the trailing icon image read back as its glyph ("▼" / "▲"), or (an arrow
-- image overridden away) the glyph inside the label text
local function header(root: any): string
	local btn = headerButton(root)
	local text = buttonLabel(btn)
	local icon = H.find(btn, "Icon")
	if icon ~= nil then
		local glyph = if icon.Image == IconsModule.asset("arrowUp")
			then "\u{25B2}"
			elseif icon.Image == IconsModule.asset("arrowDown") then "\u{25BC}"
			else "?"
		return text .. " " .. glyph
	end
	return text
end
local function click(inst: any)
	H.fire(inst, "Activated", H.input({}), 1)
end
local function key(code: EnumItem)
	(UIS :: any).InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = code }), false)
end
local function visibleTexts(root: any): { string }
	local out = {}
	for _, c in days(root) do
		if c.Visible then
			table.insert(out, c.Text)
		end
	end
	return out
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local TODAY = date(2026, 2, 12)

-- ── mount ───────────────────────────────────────────────────────────────────
H.section("mount 2026-02, Sunday first: layout, header, fixed 6x7 grid", function()
	local value = q.Source<<Date?>>(nil)
	local root = Docked({ Value = value, Today = TODAY })
	assert(root.Name == "DockedDatePicker" and root.Size == UDim2.fromOffset(360, 396))
	assert(root.BackgroundColor3 == L.SurfaceContainerHigh)
	assert(header(root) == "February 2026 \u{25BC}", header(root))
	local wd = named(root, "Weekday")
	local letters = {}
	for _, w in wd do
		table.insert(letters, w.Text)
	end
	assert(table.concat(letters, "") == "SMTWTFS", table.concat(letters, ""))
	local cells = days(root)
	assert(#cells == 42, "always 42 cells (fixed six rows), got " .. #cells)
	assert(cells[1].Text == "1" and cells[1].Visible, "Feb 1 2026 is a Sunday: first cell")
	assert(cells[28].Text == "28" and cells[28].Visible and not cells[29].Visible, "28 days visible, the rest hidden")
	assert(#visibleTexts(root) == 28)
	assert(cells[1].Size == UDim2.fromOffset(40, 40) and cells[1].Position == UDim2.fromOffset(4, 4))
	assert(cells[8].Position == UDim2.fromOffset(4, 52) and cells[7].Position == UDim2.fromOffset(292, 4), "48 px slots, chip centred")
	-- today: outlined, not filled
	local ring = H.find(cells[12], "Ring")
	assert(ring.Transparency == 0 and ring.Thickness == 1 and ring.Color == L.Outline, "today outline")
	assert(cells[12].BackgroundTransparency == 1 and cells[12].TextColor3 == L.Primary)
	assert(H.find(cells[13], "Ring").Transparency == 1, "other days no outline")
	assert(cells[3].TextColor3 == L.OnSurface and cells[3].TextTransparency == 0)
	assert(cells[1].SelectionImageObject == Interactive.noSelectionImage(), "day chips share the Interactive no-selection image")
	local count = H.countDescendants(root)
	print("DatePicker.Docked descendants at rest: " .. count .. " (+1 host = " .. (count + 1) .. ")")
	H.resetOutput()
	assert(count < 260, "instance budget, got " .. count)
	q.dispose(root)
	H.assertNoDebugOutput("mount")
end)

H.section("Monday first: weekday header order and the grid offset", function()
	local root = Docked({ Value = q.Source<<Date?>>(nil), Today = TODAY, FirstDayOfWeek = 1 })
	local letters = {}
	for _, w in named(root, "Weekday") do
		table.insert(letters, w.Text)
	end
	assert(table.concat(letters, "") == "MTWTFSS", table.concat(letters, ""))
	local cells = days(root)
	for i = 1, 6 do
		assert(not cells[i].Visible, "Jan 26..31 hidden, cell " .. i)
	end
	assert(cells[7].Text == "1" and cells[7].Visible and cells[7].Position == UDim2.fromOffset(292, 4), "Feb 1 is a Sunday = last column")
	assert(cells[34].Text == "28" and cells[34].Visible and not cells[35].Visible)
	q.dispose(root)
	H.assertNoDebugOutput("monday")
end)

H.section("leap year February: 29 days in 2024, 28 in 2100", function()
	local v = q.Source<<Date?>>(date(2024, 2, 10))
	local root = Docked({ Value = v, Today = date(2024, 2, 10) })
	assert(header(root) == "February 2024 \u{25BC}" and #visibleTexts(root) == 29)
	v:Set(date(2100, 2, 1))
	assert(header(root) == "February 2100 \u{25BC}" and #visibleTexts(root) == 28)
	q.dispose(root)
	H.assertNoDebugOutput("leap")
end)

H.section("R2-8 prev / next month arrows pick up Icons.override assets (icon-size image, no label)", function()
	local Icons = require("../src/Icons")
	Icons.override({ chevronLeft = "rbxassetid://31", chevronRight = "rbxassetid://32" })
	local root = Docked({ Value = q.Source<<Date?>>(date(2026, 12, 15)), Today = TODAY })
	local prev, nxt = H.find(root, "Prev"), H.find(root, "Next")
	local pi, ni = H.find(prev, "Icon"), H.find(nxt, "Icon")
	assert(pi.Image == "rbxassetid://31" and ni.Image == "rbxassetid://32" and pi.Size == UDim2.fromOffset(24, 24))
	assert(H.find(prev, "Label") == nil)
	Icons.override({ chevronLeft = false, chevronRight = false })
	q.dispose(root)
	H.assertNoDebugOutput("datepicker icon override")
end)

-- ── navigation ──────────────────────────────────────────────────────────────
H.section("navigation across a year boundary keeps the same 42 cell instances", function()
	local value = q.Source<<Date?>>(date(2026, 12, 15))
	local root = Docked({ Value = value, Today = TODAY })
	assert(header(root) == "December 2026 \u{25BC}")
	local before = days(root)
	local nextBtn, prevBtn = H.find(root, "Next"), H.find(root, "Prev")
	click(nextBtn)
	assert(header(root) == "January 2027 \u{25BC}", header(root))
	local after = days(root)
	assert(#after == 42)
	for i = 1, 42 do
		assert(before[i] == after[i], "cell " .. i .. " is the same Instance after navigation")
	end
	-- Jan 1 2027 is a Friday: column 6 of row 1
	assert(after[6].Text == "1" and after[6].Visible and not after[5].Visible)
	assert(#visibleTexts(root) == 31)
	click(prevBtn)
	click(prevBtn)
	assert(header(root) == "November 2026 \u{25BC}")
	for i = 1, 42 do
		assert(days(root)[i] == before[i])
	end
	assert(H.countDescendants(root) == H.countDescendants(root))
	q.dispose(root)
	H.assertNoDebugOutput("navigation")
end)

H.section("Min / Max stop prev / next and disable days", function()
	local value = q.Source<<Date?>>(nil)
	local root = Docked({ Value = value, Today = TODAY, Min = date(2026, 2, 10), Max = date(2026, 3, 20) })
	local prev, nxt = H.find(root, "Prev"), H.find(root, "Next")
	assert(prev.Interactable == false and nxt.Interactable == true, "Feb is the first allowed month")
	local cells = days(root)
	assert(cells[9].Interactable == false and cells[9].TextTransparency == 1 - Tokens.State.Opacity.DisabledContent, "Feb 9 disabled")
	assert(cells[10].Interactable == true and cells[10].TextTransparency == 0, "Feb 10 allowed")
	click(cells[9])
	assert(value:Get() == nil, "clicking a disabled day does nothing")
	click(prev)
	assert(header(root) == "February 2026 \u{25BC}", "prev at the bound does nothing")
	click(nxt)
	assert(header(root) == "March 2026 \u{25BC}")
	assert(nxt.Interactable == false and prev.Interactable == true, "Mar is the last allowed month")
	cells = days(root)
	-- March 2026 starts on a Sunday: cell 20 = Mar 20 allowed, cell 21 disabled
	assert(cells[20].Interactable == true and cells[21].Interactable == false)
	click(nxt)
	assert(header(root) == "March 2026 \u{25BC}")
	q.dispose(root)
	H.assertNoDebugOutput("min max")
end)

H.section("IsDisabled disables arbitrary days (weekends)", function()
	local value = q.Source<<Date?>>(nil)
	local root = Docked({
		Value = value,
		Today = TODAY,
		IsDisabled = function(d: Date): boolean
			local w = Calendar.weekday(d)
			return w == 0 or w == 6
		end,
	})
	local cells = days(root)
	assert(cells[1].Interactable == false and cells[7].Interactable == false and cells[2].Interactable == true)
	click(cells[1])
	assert(value:Get() == nil)
	click(cells[3])
	assert(iso(value:Get()) == "2026-02-03")
	q.dispose(root)
	H.assertNoDebugOutput("isdisabled")
end)

-- ── selection ───────────────────────────────────────────────────────────────
H.section("selection round trip: click -> Value, external Value -> UI and visible month", function()
	local value = q.Source<<Date?>>(nil)
	local picked: { string } = {}
	local root = Docked({
		Value = value,
		Today = TODAY,
		OnChange = function(d: Date)
			table.insert(picked, iso(d))
		end,
	})
	local cells = days(root)
	click(cells[14])
	assert(iso(value:Get()) == "2026-02-14" and picked[1] == "2026-02-14")
	H.finishTweens()
	assert(cells[14].BackgroundColor3 == L.Primary and cells[14].BackgroundTransparency == 0, "selected = filled primary")
	assert(cells[14].TextColor3 == L.OnPrimary)
	assert(cells[13].BackgroundTransparency == 1)
	-- external set in the same month
	value:Set(date(2026, 2, 20))
	H.finishTweens()
	assert(cells[14].BackgroundTransparency == 1 and cells[20].BackgroundTransparency == 0)
	-- external set in another month moves the view
	value:Set(date(2026, 7, 4))
	assert(header(root) == "July 2026 \u{25BC}", header(root))
	H.finishTweens()
	-- July 2026 starts on Wednesday: Jul 4 is cell 7
	assert(days(root)[7].Text == "4" and days(root)[7].BackgroundTransparency == 0)
	-- the user navigates elsewhere; the value does not drag the view back
	click(H.find(root, "Next"))
	assert(header(root) == "August 2026 \u{25BC}")
	-- clearing the value deselects
	value:Set(nil)
	H.finishTweens()
	for _, c in days(root) do
		assert(c.BackgroundTransparency == 1)
	end
	-- opens on the Value's month when there is one
	local root2 = Docked({ Value = q.Source<<Date?>>(date(1999, 12, 31)), Today = TODAY })
	assert(header(root2) == "December 1999 \u{25BC}")
	q.dispose(root)
	q.dispose(root2)
	H.assertNoDebugOutput("selection")
end)

H.section("today defaults from the UTC offset, not the machine time zone", function()
	local clockNow = Calendar.today(function()
		return 1767225600 -- 2026-01-01 00:00:00 UTC
	end, 0)
	assert(iso(clockNow) == "2026-01-01")
	assert(iso(Calendar.today(function()
		return 1767225600
	end, 9 * 3600)) == "2026-01-01")
	assert(iso(Calendar.today(function()
		return 1767225600 - 1
	end, 9 * 3600)) == "2026-01-01" and iso(Calendar.today(function()
		return 1767225600 - 1
	end, 0)) == "2025-12-31", "the offset moves the calendar day")
	local root = Docked({ Value = q.Source<<Date?>>(nil), UtcOffset = 9 * 3600 })
	local utc = Calendar.today(nil, 0)
	local kst = Calendar.today(nil, 9 * 3600)
	local want = string.format("%s %d", Calendar.monthName("en", kst.Month), kst.Year)
	assert(header(root) == want .. " \u{25BC}", header(root) .. " vs " .. want .. " (utc " .. iso(utc) .. ")")
	q.dispose(root)
	H.assertNoDebugOutput("today")
end)

-- ── header arrow (10th QA) ──────────────────────────────────────────────────
H.section("header: the year-menu arrow is the month-year Button's TRAILING icon image (arrowDown / arrowUp); glyphs in the label without the images", function()
	local root = Docked({ Value = q.Source<<Date?>>(nil), Today = TODAY })
	local btn = headerButton(root)
	local icon = H.find(btn, "Icon")
	local label = H.find(btn, "Label")
	assert(icon ~= nil and icon.ClassName == "ImageLabel", "an image, not a glyph")
	assert(icon.Image == IconsModule.Defaults.arrowDown and label.Text == "February 2026", "arrow_drop_down; the label is the text alone")
	assert(icon.Size == UDim2.fromOffset(18, 18) and icon.LayoutOrder > label.LayoutOrder, "18 px, after the label")
	local pad: any = nil
	for _, c in H.find(btn, "Content"):GetChildren() do
		if c.ClassName == "UIPadding" then
			pad = c
		end
	end
	assert(pad.PaddingLeft == UDim.new(0, 16) and pad.PaddingRight == UDim.new(0, 12), "Text button with a trailing icon: 16 / 12")
	click(btn)
	assert(icon.Image == IconsModule.Defaults.arrowUp, "year grid open: arrow_drop_up (Compose rotates ArrowDropDown 180)")
	q.dispose(root)
	-- an arrow image overridden away: the glyphs return to the label, no icon
	IconsModule.override({ arrowUp = false })
	local plain = Docked({ Value = q.Source<<Date?>>(nil), Today = TODAY })
	assert(H.find(headerButton(plain), "Icon") == nil and header(plain) == "February 2026 \u{25BC}")
	click(headerButton(plain))
	assert(header(plain) == "February 2026 \u{25B2}")
	q.dispose(plain)
	IconsModule.override({ arrowUp = IconsModule.Defaults.arrowUp })
	H.assertNoDebugOutput("header arrow")
end)

-- Studio QA 2026-10-08, 10th follow-up: held until the ripple filled it, the month-year button (auto width, trailing icon)
-- jumped to the full width of the picker — the disc took Size Scale 1 at full cover. Nothing below the ripple group may
-- have a Scale, through the expand and after full cover (Ripple.luau "NOT SCALE", "FULL COVER").
H.section("header: the month-year button's ripple never puts a Scale below its group, through full cover (docked)", function()
	local root = Docked({ Value = q.Source<<Date?>>(nil), Today = TODAY })
	local btn = headerButton(root)
	assert(btn.AutomaticSize == Enum.AutomaticSize.X and H.find(btn, "Icon") ~= nil, "auto width with the trailing icon")
	Bounded.pressBounded(btn, 137.5, 40, "docked header")
	q.dispose(root)
	H.assertNoDebugOutput("header ripple")
end)

-- ── year grid ───────────────────────────────────────────────────────────────
H.section("year grid: toggles with the label, 3 columns, selects a year, keeps the month", function()
	local value = q.Source<<Date?>>(date(2026, 2, 10))
	local root = Docked({ Value = value, Today = TODAY, Min = date(2020, 6, 1), Max = date(2031, 3, 1) })
	local years = H.find(root, "Years")
	local month = H.find(root, "Month")
	assert(years.Visible == false and month.Visible == true)
	assert(#named(years, "Year") == 12, "2020..2031 = 12 chips, got " .. #named(years, "Year"))
	click(headerButton(root))
	assert(years.Visible == true and month.Visible == false and header(root) == "February 2026 \u{25B2}")
	assert(H.find(root, "Prev").Visible == false and H.find(root, "Next").Visible == false, "arrows hidden in year mode")
	local chips = named(years, "Year")
	assert(chips[1].Text == "2020" and chips[1].Position == UDim2.fromOffset(20, 8), chips[1].Text)
	assert(chips[2].Position == UDim2.fromOffset(132, 8) and chips[4].Position == UDim2.fromOffset(20, 60), "3 columns of 112")
	assert(years.CanvasSize == UDim2.fromOffset(0, 4 * 52))
	H.finishTweens()
	local selected = chips[7] -- 2026
	assert(selected.Text == "2026" and selected.BackgroundTransparency == 0 and selected.BackgroundColor3 == L.Primary, "visible year filled")
	click(chips[10]) -- 2029
	assert(years.Visible == false and month.Visible == true)
	assert(header(root) == "February 2029 \u{25BC}", header(root))
	assert(iso(value:Get()) == "2026-02-10", "choosing a year does not change the value")
	H.finishTweens()
	-- the picked year is filled, the current year (2026) is only outlined
	chips = named(years, "Year")
	assert(chips[10].BackgroundTransparency == 0 and H.find(chips[10], "Ring").Transparency == 1)
	assert(chips[7].BackgroundTransparency == 1 and H.find(chips[7], "Ring").Transparency == 0 and chips[7].TextColor3 == L.Primary, "this year outlined")
	-- year pick clamped into the allowed months: 2031 with Max 2031-03 and month Feb ok; 2020 with Min June -> June
	click(headerButton(root))
	click(named(years, "Year")[1])
	assert(header(root) == "June 2020 \u{25BC}", "year 2020 starts at the first allowed month: " .. header(root))
	q.dispose(root)
	H.assertNoDebugOutput("years")
end)

H.section("year grid is windowed: an unbounded picker builds a few chips, not 201", function()
	local root = Docked({ Value = q.Source<<Date?>>(date(2026, 2, 10)), Today = TODAY })
	local years = H.find(root, "Years")
	local n = #named(years, "Year")
	print("year chips for the open range 1926..2126: " .. n)
	H.resetOutput()
	assert(n > 0 and n <= 27, "windowed: " .. n)
	assert(years.CanvasSize == UDim2.fromOffset(0, 67 * 52), "201 years = 67 rows: " .. tostring(years.CanvasSize))
	-- scroll to 2100: row (2100-1926)//3 = 58 -> y = 58*52
	years.CanvasPosition = Vector2.new(0, 58 * 52)
	local texts: { [string]: boolean } = {}
	for _, c in named(years, "Year") do
		texts[c.Text] = true
	end
	assert(texts["2100"] and not texts["2026"], "window follows the scroll")
	assert(#named(years, "Year") <= 27)
	-- opening centers the visible year
	click(headerButton(root))
	assert(near(years.CanvasPosition.Y, math.clamp(((2026 - 1926) // 3) * 52 - (328 - 52) / 2, 0, 67 * 52 - 328)), tostring(years.CanvasPosition))
	local texts2: { [string]: boolean } = {}
	for _, c in named(years, "Year") do
		texts2[c.Text] = true
	end
	assert(texts2["2026"], "visible year is in the window after re-centering")
	q.dispose(root)
	H.assertNoDebugOutput("year window")
end)

-- ── locale ──────────────────────────────────────────────────────────────────
H.section("Korean locale: header, weekday letters, headline-free docked", function()
	local root = Docked({ Value = q.Source<<Date?>>(nil), Today = TODAY, Locale = "ko" })
	assert(header(root) == "2026년 2월 \u{25BC}", header(root))
	local letters = {}
	for _, w in named(root, "Weekday") do
		table.insert(letters, w.Text)
	end
	assert(table.concat(letters, "") == "일월화수목금토", table.concat(letters, ""))
	q.dispose(root)
	local ok = pcall(function()
		return Docked({ Value = q.Source<<Date?>>(nil), Locale = "xx" :: any })
	end)
	assert(not ok, "unknown locale errors")
	H.resetOutput()
	H.assertNoDebugOutput("ko")
end)

H.section("hidden out-of-month cells are not selectable (the engine never lands on them)", function()
	local root = Docked({ Value = q.Source<<Date?>>(nil), Today = TODAY })
	local cells = days(root)
	assert(cells[10].Selectable == true, "in-month cell selectable")
	assert(cells[42].Visible == false and cells[42].Selectable == false, "hidden cell: Selectable = false")
	q.dispose(root)
	H.assertNoDebugOutput("hidden selectable")
end)

-- ── keyboard ────────────────────────────────────────────────────────────────
H.section("keyboard: connection only while a cell is focused; arrows, page, home/end, Enter", function()
	local value = q.Source<<Date?>>(nil)
	local root = Docked({ Value = value, Today = TODAY, Min = date(2026, 1, 20), Max = date(2026, 4, 10), IsDisabled = function(d: Date): boolean
		return d.Month == 2 and d.Day == 12
	end })
	local cells = days(root)
	assert(uisConns() == baseConns, "no global connection before focus")
	H.fire(cells[10], "SelectionGained") -- Feb 10
	assert(uisConns() == baseConns + 1, "one connection while focused")
	key(Enum.KeyCode.Right)
	assert(GuiService.SelectedObject == cells[11], "right -> Feb 11")
	key(Enum.KeyCode.Right) -- Feb 12 is disabled: skipped to Feb 13
	assert(GuiService.SelectedObject == cells[13], "disabled Feb 12 skipped")
	key(Enum.KeyCode.Down)
	assert(GuiService.SelectedObject == cells[20], "down = +7 days")
	key(Enum.KeyCode.Home) -- Sunday of that week (Feb 15)
	assert(GuiService.SelectedObject == cells[15], "home -> week start")
	key(Enum.KeyCode.End)
	assert(GuiService.SelectedObject == cells[21], "end -> week end (Feb 21)")
	-- Enter: the engine activates the selected cell (Studio 2026-10-13); the key handler itself must NOT pick as well
	-- (it did — one press picked twice: Docked OnChange twice, a range closed on its first day)
	local before = iso(value:Get())
	key(Enum.KeyCode.Return)
	assert(iso(value:Get()) == before, "the Return key alone picks nothing (the engine's Activated does): " .. iso(value:Get()))
	click(GuiService.SelectedObject)
	assert(iso(value:Get()) == "2026-02-21", iso(value:Get()))
	-- page down moves the visible month and the engine selection
	key(Enum.KeyCode.PageDown)
	assert(header(root) == "March 2026 \u{25BC}", header(root))
	assert(GuiService.SelectedObject == days(root)[21], "Mar 21 is cell 21 (March starts on Sunday)")
	key(Enum.KeyCode.PageDown)
	assert(header(root) == "April 2026 \u{25BC}")
	key(Enum.KeyCode.PageDown) -- clamped at Max (Apr 10): moving to May is not allowed
	assert(header(root) == "April 2026 \u{25BC}")
	-- `processed` is not consulted (the engine marks nav keys processed while a cell holds selection): the key moves focus
	local before = GuiService.SelectedObject
	;(UIS :: any).InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Left }), true)
	assert(GuiService.SelectedObject ~= before, "processed key still delivered")
	-- cells do NOT pin NextSelection*: the gamepad D-pad is the engine's geometric selection and may leave the grid
	local free: any = GuiService.SelectedObject
	assert(free.NextSelectionLeft == nil and free.NextSelectionRight == nil and free.NextSelectionUp == nil and free.NextSelectionDown == nil)
	-- D-pad presses are not ours (the engine moves selection); L1/R1 page the previous / next month (gamepad)
	local before2 = GuiService.SelectedObject
	;(UIS :: any).InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Gamepad1, KeyCode = Enum.KeyCode.DPadDown }), false)
	assert(GuiService.SelectedObject == before2, "D-pad is left to the engine")
	local hdr = header(root)
	;(UIS :: any).InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Gamepad1, KeyCode = Enum.KeyCode.ButtonL1 }), false)
	assert(header(root) ~= hdr, "L1 pages to the previous month")
	;(UIS :: any).InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Gamepad1, KeyCode = Enum.KeyCode.ButtonR1 }), false)
	assert(header(root) == hdr, "R1 pages forward again: " .. header(root))
	-- non-keyboard input is ignored
	;(UIS :: any).InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.MouseButton1 }), false)
	-- (the engine fires Lost on the cell that held selection — the last one we focused — when selection moves on)
	H.fire(cells[10], "SelectionLost")
	assert(uisConns() == baseConns, "closed on blur")
	H.fire(cells[1], "SelectionGained")
	assert(uisConns() == baseConns + 1)
	q.dispose(root)
	assert(uisConns() == baseConns, "closed when the picker dies: " .. (uisConns() - baseConns))
	GuiService.SelectedObject = nil
	H.assertNoDebugOutput("keyboard")
end)

H.section("hover / press feedback is the chip's own background", function()
	local root = Docked({ Value = q.Source<<Date?>>(nil), Today = TODAY })
	local c = days(root)[3]
	H.fire(c, "MouseEnter")
	H.finishTweens()
	assert(near(c.BackgroundTransparency, 1 - Tokens.State.Opacity.Hover) and c.BackgroundColor3 == L.OnSurface)
	H.fire(c, "MouseLeave")
	H.finishTweens()
	assert(c.BackgroundTransparency == 1)
	H.fire(c, "SelectionGained")
	H.finishTweens()
	assert(near(c.BackgroundTransparency, 1 - Tokens.State.Opacity.Focus))
	local ring = H.find(c, "Ring")
	assert(ring.Transparency == 0 and ring.Thickness == 2 and ring.Color == L.Secondary, "focus ring")
	H.fire(c, "SelectionLost")
	assert(H.find(c, "Ring").Transparency == 1)
	q.dispose(root)
	GuiService.SelectedObject = nil
	H.assertNoDebugOutput("hover")
end)

-- ── range ───────────────────────────────────────────────────────────────────
H.section("RangeDocked: first click starts, second completes (normalized), third restarts", function()
	local s, e = q.Source<<Date?>>(nil), q.Source<<Date?>>(nil)
	local calls: { string } = {}
	local root = RangeDocked({
		Start = s,
		End = e,
		Today = TODAY,
		OnChange = function(a: Date, b: Date?)
			table.insert(calls, iso(a) .. ".." .. iso(b))
		end,
	})
	local cells = days(root)
	click(cells[10])
	assert(iso(s:Get()) == "2026-02-10" and e:Get() == nil and calls[1] == "2026-02-10..nil")
	click(cells[5]) -- earlier day: swapped
	assert(iso(s:Get()) == "2026-02-05" and iso(e:Get()) == "2026-02-10" and calls[2] == "2026-02-05..2026-02-10")
	H.finishTweens()
	assert(cells[5].BackgroundColor3 == L.Primary and cells[5].BackgroundTransparency == 0, "start filled")
	assert(cells[10].BackgroundColor3 == L.Primary and cells[10].BackgroundTransparency == 0, "end filled")
	for i = 6, 9 do
		assert(cells[i].BackgroundColor3 == L.SecondaryContainer and cells[i].BackgroundTransparency == 0, "band " .. i)
		assert(cells[i].Size == UDim2.fromOffset(48, 40), "in-range chip widens to the slot: " .. tostring(cells[i].Size))
		assert(H.find(cells[i], "_quad_round").CornerRadius == UDim.new(0, 0), "squared")
		assert(cells[i].TextColor3 == L.OnSecondaryContainer)
	end
	assert(cells[4].BackgroundTransparency == 1 and cells[11].BackgroundTransparency == 1)
	assert(cells[5].Size == UDim2.fromOffset(40, 40))
	-- the half bands join the end circles to the strip: start center -> slot right edge, slot left edge -> end center,
	-- under the chips (chip ZIndex 2)
	local bs, be = H.find(root, "BandStart"), H.find(root, "BandEnd")
	assert(bs.Visible == true and be.Visible == true and bs.BackgroundColor3 == L.SecondaryContainer)
	assert(bs.Size == UDim2.fromOffset(24, 40) and be.Size == UDim2.fromOffset(24, 40))
	assert(cells[5].ZIndex == 2 and bs.ZIndex == 1)
	-- start chip spans x [p+4, p+44] of its slot: the band starts at its center p+24 and meets the next slot at p+48
	assert(bs.Position.X.Offset == cells[5].Position.X.Offset + 20 and bs.Position.Y.Offset == cells[5].Position.Y.Offset)
	assert(bs.Position.X.Offset + 24 == cells[6].Position.X.Offset, "start half band meets the strip")
	assert(be.Position.X.Offset + 24 == cells[10].Position.X.Offset + 20, "end half band ends at the end circle's center")
	assert(be.Position.X.Offset == cells[9].Position.X.Offset + 48, "end half band starts where the strip ends")
	click(cells[20]) -- complete range -> restart
	assert(iso(s:Get()) == "2026-02-20" and e:Get() == nil)
	H.finishTweens()
	assert(cells[6].BackgroundTransparency == 1 and cells[20].BackgroundTransparency == 0)
	assert(bs.Visible == false and be.Visible == false, "incomplete range: no half bands")
	-- same day twice = single-day range
	click(cells[20])
	assert(iso(s:Get()) == "2026-02-20" and iso(e:Get()) == "2026-02-20")
	assert(bs.Visible == false and be.Visible == false, "one-day range: one circle, no half bands")
	q.dispose(root)
	H.assertNoDebugOutput("range")
end)

-- Studio QA 2026-10-08: completing a range flashed a translucent dark shape over every in-range day, which then faded
-- into the band. The idle chip's container color is the onSurface state-layer color at transparency 1; the old chip
-- tweened BackgroundColor3 (onSurface -> secondaryContainer) and BackgroundTransparency (1 -> 0) TOGETHER, so mid-way
-- the cell was a half-opaque near-black blend. Canon (Compose DatePicker.kt `dayContainerColor` / `dayContentColor`,
-- DateRangePicker.kt `drawRangeBackground`): an in-range day has no container, the band is drawn unanimated and its
-- content color is not animated; the END date's container does not animate either (`animateChecked = startDateSelected`).
-- The mock does not interpolate, so the frames are sampled here from each in-flight tween's (from, to) — any easing
-- stays inside that segment.
H.section("RangeDocked: completing / clearing a range shows no dark fill on the in-range and end days", function()
	H.finishTweens()
	local s, e = q.Source<<Date?>>(nil), q.Source<<Date?>>(nil)
	local root = RangeDocked({ Start = s, End = e, Today = TODAY })
	local cells = days(root)
	local surface = L.SurfaceContainerHigh
	local props = { "BackgroundColor3", "BackgroundTransparency", "TextColor3" }
	local function lerp(a: any, b: any, t: number): any
		if typeof(a) == "number" then
			return a + (b - a) * t
		end
		return (a :: Color3):Lerp(b, t)
	end
	-- the value of `prop` on `inst` at fraction `t` of whatever tween is playing on it now (the current value if none)
	local function sample(inst: any, prop: string, t: number): any
		for _, entry in H.tweenLog() do
			if entry.inst == inst and entry.tween.PlaybackState == "Playing" and entry.props[prop] ~= nil then
				return lerp(inst[prop], entry.props[prop], t)
			end
		end
		return inst[prop]
	end
	local function playing(inst: any): { string }
		local out = {}
		for _, entry in H.tweenLog() do
			if entry.inst == inst and entry.tween.PlaybackState == "Playing" then
				for _, p in props do
					if entry.props[p] ~= nil then
						table.insert(out, p)
					end
				end
			end
		end
		return out
	end
	local function luma(c: Color3): number
		return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
	end
	-- the chip's fill composited over the picker surface, at fraction t of the transition
	local function shown(inst: any, t: number): number
		local a = 1 - sample(inst, "BackgroundTransparency", t)
		return luma(surface:Lerp(sample(inst, "BackgroundColor3", t), a))
	end
	local function checkFrames(label: string, cell: any, final: Color3?)
		local floor = math.min(luma(surface), if final then luma(final) else luma(surface))
		for i = 0, 10 do
			local t = i / 10
			local seen = shown(cell, t)
			assert(seen >= floor - 1e-3, `{label}: frame {t} is darker than both ends ({seen} < {floor})`)
		end
	end

	click(cells[5]) -- start: the first circle (it animates, as Compose's start date)
	H.finishTweens()
	H.fire(cells[10], "MouseEnter") -- a hover tween is still in flight on the end day when it is tapped
	assert(#playing(cells[10]) > 0)
	click(cells[10]) -- complete
	for i = 6, 9 do
		checkFrames("in-range " .. i, cells[i], L.SecondaryContainer)
		assert(#playing(cells[i]) == 0, `in-range day {i} snaps (no tween on {table.concat(playing(cells[i]), ", ")})`)
		assert(cells[i].BackgroundColor3 == L.SecondaryContainer and cells[i].BackgroundTransparency == 0)
		assert(cells[i].TextColor3 == L.OnSecondaryContainer)
	end
	assert(#playing(cells[10]) == 0, "the end date's circle snaps (Compose animateChecked = startDateSelected)")
	assert(cells[10].BackgroundColor3 == L.Primary and cells[10].BackgroundTransparency == 0)
	H.fire(cells[10], "MouseLeave")
	H.finishTweens()
	click(cells[20]) -- restart: the old range clears at once, the new start animates
	for i = 6, 9 do
		checkFrames("cleared " .. i, cells[i], nil)
		assert(#playing(cells[i]) == 0 and cells[i].BackgroundTransparency == 1, "cleared in-range day " .. i)
	end
	assert(#playing(cells[5]) == 0 and #playing(cells[10]) == 0, "old ends clear at once")
	assert(cells[5].BackgroundTransparency == 1 and cells[10].BackgroundTransparency == 1)
	assert(#playing(cells[20]) > 0, "the new start's circle still animates")
	H.finishTweens()
	-- hover feedback on an idle day still animates after a range was cleared through it
	H.fire(cells[7], "MouseEnter")
	assert(#playing(cells[7]) > 0, "hover layer still tweens")
	H.finishTweens()
	q.dispose(root)
	H.assertNoDebugOutput("range frames")
end)

-- ── modal ───────────────────────────────────────────────────────────────────
local function setupModal()
	local overlay = Overlay.new()
	local screen = Frame { overlay.Layer }
	return overlay, screen
end

local function buttonByLabel(root: any, label: string): any
	for _, b in named(root, "Button") do
		if buttonLabel(b) == label then
			return b
		end
	end
	error("no button " .. label)
end

H.section("modal: draft / OK commits / Cancel discards, headline in the locale", function()
	local overlay, screen = setupModal()
	local value = q.Source<<Date?>>(date(2026, 10, 5))
	local confirmed: { string } = {}
	local cancelled = 0
	local handle = Modal.open({
		Overlay = overlay,
		Value = value,
		Today = TODAY,
		OnConfirm = function(d: Date)
			table.insert(confirmed, iso(d))
		end,
		OnCancel = function()
			cancelled += 1
		end,
	})
	local card = H.find(screen, "DatePickerModal")
	assert((card :: any).Active == true, "the card keeps 3D input out")
	ClickSink.assertClickSink(card, "the date picker card (a click on it must not reach the scrim)")
	assert(card ~= nil and card.ClassName == "CanvasGroup" and card.Size == UDim2.fromOffset(360, 569))
	assert(H.find(screen, "Scrim") ~= nil and overlay.Count:Get() == 1)
	assert(H.find(card, "Headline").Text == "Mon, Oct 5", H.find(card, "Headline").Text)
	assert(H.find(card, "Supporting").Text == "Select date")
	assert(header(card) == "October 2026 \u{25BC}")
	-- enter animation: snapped hidden, then animates in
	H.finishTweens()
	assert(card.GroupTransparency == 0, "faded in: " .. card.GroupTransparency)
	-- pick another date in the draft: the committed Value is untouched
	local cells = days(card)
	-- Oct 2026 starts on Thursday: Oct 21 = cell 4 + 20 = 25
	assert(cells[25].Text == "21")
	click(cells[25])
	assert(H.find(card, "Headline").Text == "Wed, Oct 21")
	assert(iso(value:Get()) == "2026-10-05", "draft only")
	-- Cancel discards
	click(buttonByLabel(card, "Cancel"))
	assert(not handle.IsOpen:Get() and cancelled == 1 and #confirmed == 0 and iso(value:Get()) == "2026-10-05")
	H.finishTweens()
	assert(card.GroupTransparency == 1, "fades out while the overlay keeps it mounted")
	assert(H.find(screen, "DatePickerModal") ~= nil)
	H.advance(0.5)
	assert(H.find(screen, "DatePickerModal") == nil and overlay.Count:Get() == 0, "removed after the exit")
	-- second dialog: OK commits
	local h2 = Modal.open({ Overlay = overlay, Value = value, Today = TODAY, OnConfirm = function(d: Date)
		table.insert(confirmed, iso(d))
	end, OnCancel = function()
		cancelled += 1
	end })
	local card2 = H.find(screen, "DatePickerModal")
	assert(H.find(card2, "Headline").Text == "Mon, Oct 5", "a fresh draft starts from the committed value")
	click(days(card2)[25])
	click(buttonByLabel(card2, "OK"))
	assert(iso(value:Get()) == "2026-10-21" and confirmed[1] == "2026-10-21" and cancelled == 1, "OK commits, no cancel callback")
	assert(not h2.IsOpen:Get())
	H.advance(0.5)
	assert(overlay.Count:Get() == 0 and #screen:GetChildren() == 1)
	q.dispose(screen)
	H.assertNoDebugOutput("modal commit")
end)

H.section("modal: scrim click cancels; OK disabled with nothing picked; Korean headline", function()
	local overlay, screen = setupModal()
	local cancelled = 0
	Modal.open({ Overlay = overlay, Locale = "ko", Today = TODAY, Initial = nil, OnCancel = function()
		cancelled += 1
	end })
	local card = H.find(screen, "DatePickerModal")
	assert(H.find(card, "Headline").Text == "\u{2013}" and H.find(card, "Supporting").Text == "날짜 선택")
	local ok = buttonByLabel(card, "확인")
	assert(ok.Interactable == false, "OK disabled without a pick")
	H.fire(ok, "Activated", H.input({}), 1)
	assert(overlay.Count:Get() == 1, "disabled OK does nothing")
	click(days(card)[10]) -- Feb 10 2026 (Tuesday)
	assert(H.find(card, "Headline").Text == "2월 10일 (화)", H.find(card, "Headline").Text)
	assert(ok.Interactable == true)
	click(H.find(screen, "Scrim"))
	assert(cancelled == 1)
	H.advance(0.5)
	assert(overlay.Count:Get() == 0)
	q.dispose(screen)
	H.assertNoDebugOutput("modal scrim")
end)

H.section("modal input mode: parsing, errors, range, draft sync, OK gating", function()
	local overlay, screen = setupModal()
	local value = q.Source<<Date?>>(date(2026, 2, 10))
	Modal.open({ Overlay = overlay, Value = value, Today = TODAY, Min = date(2026, 1, 1), Max = date(2026, 12, 31), IsDisabled = function(d: Date): boolean
		return d.Month == 5 and d.Day == 5
	end })
	local card = H.find(screen, "DatePickerModal")
	local panel = H.find(card, "DateInput")
	local field = H.find(panel, "Input")
	local body = H.find(card, "DatePickerBody")
	local toggle = H.find(card, "ModeToggle")
	-- the toggle draws the Material edit / date_range images (Icons defaults; glyph fallback in spec.icons)
	assert(panel.Visible == false and body.Visible == true and H.find(toggle, "Icon").Image == "rbxassetid://6034328955")
	click(toggle)
	assert(panel.Visible == true and body.Visible == false and H.find(toggle, "Icon").Image == "rbxassetid://6022668894")
	assert(H.find(card, "Supporting").Text == "Enter date" or #named(card, "Supporting") == 2)
	assert(field.Text == "2026-02-10", "field shows the draft: " .. field.Text)
	local support = H.find(panel, "Supporting")
	assert(support.Text == "", "no hint under the field: Compose's supporting text is the error only")
	local ok = buttonByLabel(card, "OK")
	assert(ok.Interactable == true)
	-- invalid text
	field.Text = "2025-02-29"
	assert(support.Text:find("Invalid") ~= nil, support.Text)
	assert(ok.Interactable == false, "OK disabled while invalid")
	assert(H.find(card, "Headline").Text == "Tue, Feb 10", "draft keeps the last valid date")
	field.Text = "not a date"
	assert(support.Text:find("Invalid") ~= nil)
	-- out of range
	field.Text = "2027-01-01"
	assert(support.Text == "Date is out of range" and ok.Interactable == false)
	-- disabled date
	field.Text = "2026-05-05"
	assert(support.Text == "Date is not available")
	-- valid, localized spelling
	field.Text = " 2026/3/9 "
	assert(support.Text == "" and ok.Interactable == true)
	assert(H.find(card, "Headline").Text == "Mon, Mar 9", H.find(card, "Headline").Text)
	field.Text = "Oct 5, 2026"
	assert(H.find(card, "Headline").Text == "Mon, Oct 5")
	-- empty -> nothing picked
	field.Text = ""
	assert(H.find(card, "Headline").Text == "\u{2013}" and ok.Interactable == false and support.Text == "")
	field.Text = "2026-08-15"
	assert(ok.Interactable == true)
	-- back to the calendar: it follows the draft
	click(toggle)
	assert(panel.Visible == false and body.Visible == true)
	assert(header(card) == "August 2026 \u{25BC}", header(card))
	-- the committed value is still the old one until OK
	assert(iso(value:Get()) == "2026-02-10")
	click(ok)
	assert(iso(value:Get()) == "2026-08-15")
	-- error colors / focus ring state
	H.advance(0.5)
	q.dispose(screen)
	H.assertNoDebugOutput("modal input")
end)

H.section("modal starts in input mode; field focus ring and error color follow the state", function()
	local overlay, screen = setupModal()
	Modal.open({ Overlay = overlay, Initial = date(2026, 2, 3), Today = TODAY, StartInInput = true, Locale = "ko" })
	local card = H.find(screen, "DatePickerModal")
	local field = H.find(H.find(card, "DateInput"), "Input")
	assert(field.Text == "2026-02-03" and H.find(card, "DateInput").Visible == true and H.find(card, "Supporting").Text == "날짜 입력")
	local outline = H.find(H.find(card, "DateField"), "Outline")
	H.finishTweens()
	assert(outline.Color == L.Outline and outline.Thickness == 1)
	H.fire(field, "Focused")
	H.finishTweens()
	assert(outline.Color == L.Primary and outline.Thickness == 2, "focused")
	field.Text = "2026-99-99"
	H.finishTweens()
	assert(outline.Color == L.Error, "error outline")
	assert(H.find(H.find(card, "DateInput"), "Supporting").Text:find("올바른") ~= nil)
	H.fire(field, "FocusLost")
	field.Text = "2026.2.4"
	H.finishTweens()
	assert(outline.Color == L.Outline and outline.Thickness == 1)
	q.dispose(screen)
	H.assertNoDebugOutput("modal input start")
end)

-- the playing tween on `inst` that writes TextTransparency: its target and its time (mock TweenInfo: args[1])
local function fade(inst: any): (number?, number?)
	for _, entry in H.tweenLog() do
		if entry.inst == inst and entry.tween.PlaybackState == "Playing" and entry.props.TextTransparency ~= nil then
			return entry.props.TextTransparency, entry.info.args[1]
		end
	end
	return nil, nil
end

H.section("modal input mode: the kit's Outlined TextField, the format placeholder fades with focus (Compose DateInput)", function()
	local overlay, screen = setupModal()
	Modal.open({ Overlay = overlay, Today = TODAY, StartInInput = true, Locale = "ko" })
	local panel = H.find(H.find(screen, "DatePickerModal"), "DateInput")
	local host = H.find(panel, "DateField")
	assert(H.countDescendants(panel) == 26, "panel descendants: " .. H.countDescendants(panel))
	-- Compose InputTextFieldPadding: start 24, end 24, top 10
	assert(host.ClassName == "Frame" and host.Position == UDim2.fromOffset(24, 10) and host.Size == UDim2.fromOffset(312, 0))
	assert(#named(host, "OutlineBottom") == 1 and H.find(host, "Label").Text == "날짜", "Outlined, the label in the outline")
	local box = H.find(host, "Input")
	local ph = H.find(host, "Placeholder")
	assert(box.ClassName == "TextBox" and box.Text == "" and box.PlaceholderText ~= "YYYY-MM-DD", "no engine placeholder")
	assert(ph.Parent == box and ph.Text == "YYYY-MM-DD" and ph.TextTransparency == 1, "empty, label at rest: placeholder out")
	H.fire(box, "Focused")
	local target, time = fade(ph)
	assert(target == 0 and time == Tokens.Motion.Duration.Medium1, "focus: fades in (SlowEffects)")
	H.finishTweens()
	H.fire(box, "FocusLost", false, H.input({}))
	target, time = fade(ph)
	assert(target == 1 and time == Tokens.Motion.Duration.Short2, "blur while empty: fades out (FastEffects)")
	H.finishTweens()
	-- the supporting row: error text only, but it stays mounted (a fixed 20 px) while empty, so the field keeps its
	-- height when an error appears (Compose: 32 dp under the container either way)
	local support = H.find(host, "Supporting")
	assert(support.Text == "" and support.Size == UDim2.new(1, 0, 0, 20), "empty: no hint, row kept")
	box.Text = "2026"
	assert(not ph.Visible, "typing hides it")
	assert(support.Parent == host and support.Size == UDim2.new(1, 0, 0, 20), "same row, same height")
	assert(support.Text:find("올바른") ~= nil, "the error text")
	box.Text = "2026-02-03"
	assert(support.Text == "", "valid: empty again")
	q.dispose(screen)
	H.assertNoDebugOutput("modal input placeholder")
end)

H.section("modal: Overlay empty after close, default overlay works, dispose mid-exit", function()
	local screen = Frame { Overlay.default().Layer }
	local handle = Modal.open({ Today = TODAY })
	assert(H.find(screen, "DatePickerModal") ~= nil)
	handle.Close()
	handle.Close() -- idempotent
	H.advance(0.5)
	assert(H.find(screen, "DatePickerModal") == nil and Overlay.default().Count:Get() == 0)
	local overlay, screen2 = setupModal()
	local h2 = Modal.open({ Overlay = overlay, Today = TODAY })
	h2.Close()
	q.dispose(screen2) -- layer dies during the exit phase
	assert(H.pendingTimers() == 0)
	H.advance(1)
	q.dispose(screen)
	H.assertNoDebugOutput("modal overlay")
end)

-- the selection trap is a SelectionGroup entry whose four directions Stop (GuiService:AddSelectionParent is deprecated)
local function trapped(root: any): boolean
	local e = H.find(root, "OverlayEntry")
	return e ~= nil
		and e.SelectionGroup == true
		and e.SelectionBehaviorUp == Enum.SelectionBehavior.Stop
		and e.SelectionBehaviorDown == Enum.SelectionBehavior.Stop
		and e.SelectionBehaviorLeft == Enum.SelectionBehavior.Stop
		and e.SelectionBehaviorRight == Enum.SelectionBehavior.Stop
end

H.section("D5 modal: Escape / B dismiss like Cancel; the selection starts on Cancel and is trapped", function()
	local overlay, screen = setupModal()
	;(H.UserInputService :: any).GetLastInputType = function() return Enum.UserInputType.Gamepad1 end
	local cancelled, confirmed = 0, 0
	local handle = Modal.open({
		Overlay = overlay,
		Today = TODAY,
		OnConfirm = function()
			confirmed += 1
		end,
		OnCancel = function()
			cancelled += 1
		end,
	})
	local card = H.find(screen, "DatePickerModal")
	assert(H.GuiService.SelectedObject == buttonByLabel(card, "Cancel"), "initial selection: Cancel")
	assert(trapped(screen))
	H.UserInputService.InputBegan:Fire(H.input({ KeyCode = Enum.KeyCode.Escape, UserInputType = Enum.UserInputType.Keyboard }), false)
	assert(not handle.IsOpen:Get() and cancelled == 1 and confirmed == 0, "Escape = Cancel")
	assert(not trapped(screen))
	H.advance(0.5)
	;(H.UserInputService :: any).GetLastInputType = nil
	H.GuiService.SelectedObject = nil
	q.dispose(screen)
	H.assertNoDebugOutput("modal escape")
end)

H.section("D3 modal: the card scales down to fit a small layer, and keeps full size on a roomy or unmeasured one", function()
	local overlay, screen = setupModal()
	H.setAbs(overlay.Layer, 0, 0, 328, 400)
	Modal.open({ Overlay = overlay, Today = TODAY })
	local card = H.find(screen, "DatePickerModal")
	local function scaleOf(c: any): any
		return H.findAll(c, function(x: any)
			return x.ClassName == "UIScale"
		end)[1]
	end
	local scale = scaleOf(card)
	H.finishTweens()
	local want = math.min(1, (328 - 32) / 360, (400 - 32) / 569)
	assert(math.abs(scale.Scale - want) < 1e-6, "fit factor " .. want .. " got " .. scale.Scale)
	local roomy, screen2 = setupModal()
	H.setAbs(roomy.Layer, 0, 0, 1280, 720)
	Modal.open({ Overlay = roomy, Today = TODAY })
	H.finishTweens()
	assert(scaleOf(H.find(screen2, "DatePickerModal")).Scale == 1, "roomy: 1")
	local blind, screen3 = setupModal()
	Modal.open({ Overlay = blind, Today = TODAY })
	H.finishTweens()
	assert(scaleOf(H.find(screen3, "DatePickerModal")).Scale == 1, "unmeasured: 1")
	q.dispose(screen)
	q.dispose(screen2)
	q.dispose(screen3)
	H.assertNoDebugOutput("modal fit")
end)

-- ── lifecycle ──────────────────────────────────────────────────────────────
H.section("dispose: nothing left behind (connections back to baseline, instances destroyed)", function()
	local value = q.Source<<Date?>>(date(2026, 2, 10))
	local root = Docked({ Value = value, Today = TODAY })
	local cells = days(root)
	local btn = H.find(root, "Next")
	H.fire(cells[3], "SelectionGained")
	click(btn)
	q.dispose(root)
	assert(uisConns() == baseConns)
	assert(H.isDestroyed(root) and H.isDestroyed(cells[1]) and H.isDestroyed(btn))
	-- the Source outlives the picker without errors
	value:Set(date(2026, 3, 1))
	GuiService.SelectedObject = nil
	H.assertNoDebugOutput("dispose")
end)

H.section("theme: dark scheme recolors the cells (selected stays primary of the scheme)", function()
	local Theme = require("../src/Theme")
	local theme = Theme.new({ Scheme = "dark" })
	local value = q.Source<<Date?>>(date(2026, 2, 14))
	local root = Docked({ Value = value, Today = TODAY, Theme = theme })
	local Dk = Tokens.Color.Dark
	assert(root.BackgroundColor3 == Dk.SurfaceContainerHigh)
	local c = days(root)[14]
	assert(c.BackgroundColor3 == Dk.Primary and c.TextColor3 == Dk.OnPrimary)
	theme:SetScheme("light")
	H.finishTweens()
	assert(c.BackgroundColor3 == L.Primary and c.TextColor3 == L.OnPrimary)
	q.dispose(root)
	H.assertNoDebugOutput("theme")
end)

H.done()
