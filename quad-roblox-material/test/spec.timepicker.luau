--!strict
-- TimePicker (Dial / Input / Modal): structure and Compose dimensions, instance counts, Value round trip, OnChange
-- user-only, 12 h / 24 h, the AM/PM toggle, dial tap / drag / keys, text-input validation, the modal's OK / Cancel and
-- mode toggle, dispose, ripples bounded (no partial Scale, no AutomaticSize anywhere).
local H = require("./support/harness")
local ClickSink = require("./support/clicksink")
local Q = require("../src/Quad")
local q = H.attach(Q)
q.debug = true
local D = q.Declaration
local Tokens = require("../src/Tokens")
local Overlay = require("../src/Overlay")
local Icons = require("../src/Icons")
local Util = require("../src/Util")
local TimePicker = require("../src/TimePicker")
local Bounded = require("./support/bounded")
local Clock = TimePicker.Clock

type Time = TimePicker.Time
local UIS = H.UserInputService
local L = Tokens.Color.Light

local function uisConns(): number
	local u = UIS :: any
	return #u.InputChanged.connections + #u.InputEnded.connections + #u.WindowFocusReleased.connections + #u.InputBegan.connections
end
local baseConns = uisConns()

local function hm(t: Time?): string
	return if t then Clock.pad2(t.Hour) .. ":" .. Clock.pad2(t.Minute) else "nil"
end
local function named(root: any, name: string): { any }
	return H.findAll(root, function(c: any)
		return c.Name == name
	end)
end
local function own(inst: any, className: string): any
	for _, c in inst:GetChildren() do
		if c.ClassName == className then
			return c
		end
	end
	return nil
end
local function click(inst: any)
	H.fire(inst, "Activated", H.input({}), 1)
end
local function key(code: EnumItem)
	(UIS :: any).InputBegan:Fire(H.input({ UserInputType = Enum.UserInputType.Keyboard, KeyCode = code }), false)
end
local function label(btn: any): string
	return H.find(btn, "Label").Text
end
local function faceOf(root: any): any
	return H.find(root, "ClockFace")
end
-- the dial at screen (100, 50), 256 px; a point at `deg` clockwise from 12 o'clock, `r` px from the center
local OX, OY = 100, 50
local function layout(face: any, k: number?)
	local s = 256 * (k or 1)
	H.setAbs(face, OX, OY, s, s)
end
local function at(deg: number, r: number, k: number?): Vector3
	local s = 256 * (k or 1)
	local a = math.rad(deg)
	return Vector3.new(OX + s / 2 + r * (k or 1) * math.sin(a), OY + s / 2 - r * (k or 1) * math.cos(a), 0)
end
local function tap(face: any, p: Vector3)
	H.fire(face, "InputBegan", H.input({ Position = p }))
	;(UIS :: any).InputEnded:Fire(H.input({ Position = p }), false)
end
local function dragPath(face: any, points: { Vector3 })
	H.fire(face, "InputBegan", H.input({ Position = points[1] }))
	for i = 2, #points do
		(UIS :: any).InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = points[i] }), false)
	end
	;(UIS :: any).InputEnded:Fire(H.input({ Position = points[#points] }), false)
end
-- the hand's angle in [0, 360) (the Rotation itself is unwrapped: it takes the short way round)
local function handRotation(root: any): number
	local r = H.find(root, "Hand").Rotation % 360
	return if math.abs(r - math.round(r)) < 1e-4 then math.round(r) % 360 else r
end
local function handleY(root: any): number
	return H.find(root, "Handle").Position.Y.Offset
end

-- every descendant: Offset-only or full-cover, and nothing auto-sized (the ripple BOUNDED rule — Ripple.luau "NOT SCALE")
local function assertNoPartialScale(root: any, labelText: string)
	local sized: { any } = (H :: any).findAll(root, function(x: any): boolean
		return x.Size ~= nil and typeof(x.Size) == "UDim2"
	end)
	for _, c in sized do
		local p, z = c.Position or UDim2.new(), c.Size or UDim2.new()
		local full = p == UDim2.fromScale(0, 0) and z == UDim2.fromScale(1, 1)
		local offsetOnly = p.X.Scale == 0 and p.Y.Scale == 0 and z.X.Scale == 0 and z.Y.Scale == 0
		assert(full or offsetOnly, `{labelText}: {c.Name} has a partial Scale: {tostring(p)} {tostring(z)}`)
		assert(c.AutomaticSize == nil or c.AutomaticSize == Enum.AutomaticSize.None, `{labelText}: {c.Name} is auto-sized`)
	end
end

H.section("Dial (Vertical, 12 h): Compose dimensions, numbers, selector, instance count", function()
	local value = q.Source(Clock.time(9, 30))
	local root = TimePicker.Dial({ Value = value })
	assert(root.Name == "TimePickerDial" and root.Size == UDim2.fromOffset(272, 396), tostring(root.Size))
	local hour = H.find(root, "HourSelector")
	local minute = H.find(root, "MinuteSelector")
	assert(hour.Size == UDim2.fromOffset(96, 80) and hour.Position == UDim2.fromOffset(0, 0))
	assert(minute.Position == UDim2.fromOffset(120, 0), tostring(minute.Position))
	assert(H.find(root, "Separator").Position == UDim2.fromOffset(96, -4) and H.find(root, "Separator").Text == ":")
	assert(label(hour) == "09" and label(minute) == "30", label(hour) .. ":" .. label(minute))
	assert(hour.BackgroundColor3 == L.PrimaryContainer and minute.BackgroundColor3 == L.SurfaceContainerHighest, "hour box selected")
	assert(H.find(hour, "Label").TextColor3 == L.OnPrimaryContainer)
	local toggle = H.find(root, "PeriodToggle")
	assert(toggle.Size == UDim2.fromOffset(52, 80) and toggle.Position == UDim2.fromOffset(220, 0))
	local am, pm = H.find(toggle, "AM"), H.find(toggle, "PM")
	assert(am.Size == UDim2.fromOffset(52, 38) and pm.Position == UDim2.fromOffset(0, 42), tostring(pm.Position))
	assert(am.BackgroundColor3 == L.PrimaryContainer and pm.BackgroundColor3 == L.SurfaceContainerLowest, "AM checked")
	assert(own(am, "UICorner").CornerRadius == UDim.new(0, 12) and own(pm, "UICorner").CornerRadius == UDim.new(0, 19), "checked 12, unchecked full")
	assert(H.find(am, "Label").FontFace.Weight == Enum.FontWeight.Bold and H.find(pm, "Label").FontFace.Weight == Enum.FontWeight.Medium)
	local face = faceOf(root)
	assert(face.Size == UDim2.fromOffset(256, 256) and face.Position == UDim2.fromOffset(8, 116), tostring(face.Position))
	assert(face.BackgroundColor3 == L.SurfaceContainerHighest)
	local hours = H.find(face, "Hours")
	local nums = named(hours, "Number")
	assert(#nums == 12 and nums[1].Text == "12" and nums[1].Position == UDim2.fromOffset(104, 3), "12 at the top")
	assert(nums[4].Text == "3" and nums[4].Position == UDim2.fromOffset(205, 104))
	assert(nums[1].TextColor3 == L.OnSurface and nums[1].TextTransparency == 0)
	local minutes = named(H.find(face, "Minutes"), "Number")
	assert(#minutes == 12 and minutes[2].Text == "5" and minutes[1].TextTransparency == 1, "minute face hidden")
	-- the hand: 9 o'clock = 270 deg, outer ring
	assert(handRotation(root) == 270, tostring(handRotation(root)))
	assert(H.find(root, "Handle").ClassName == "CanvasGroup" and handleY(root) == 3, tostring(handleY(root)))
	assert(H.find(root, "Handle").BackgroundColor3 == L.Primary and H.find(root, "Line").Size == UDim2.fromOffset(2, 77))
	assert(H.find(root, "Dot").Size == UDim2.fromOffset(8, 8))
	local mirror = H.find(root, "Mirror")
	assert((mirror.Rotation + H.find(root, "Hand").Rotation) == 0 and mirror.Position == UDim2.fromOffset(-104, -3), "the copy lies over the dial")
	assert(H.find(H.find(mirror, "Hours"), "Number").TextColor3 == L.OnPrimary)
	print(`[timepicker] Dial vertical 12 h: {H.countDescendants(root) + 1} instances`)
	H.resetOutput()
	assert(H.countDescendants(root) + 1 == 90, tostring(H.countDescendants(root) + 1))
	q.dispose(root)
	H.assertNoDebugOutput("dial structure")
end)

H.section("Dial 24 h and Horizontal: inner ring, no toggle, sizes", function()
	local value = q.Source(Clock.time(15, 0))
	local root = TimePicker.Dial({ Value = value, Is24Hour = true })
	assert(root.Size == UDim2.fromOffset(256, 396) and H.find(root, "PeriodToggle") == nil)
	assert(H.find(root, "HourSelector").Position == UDim2.fromOffset(20, 0))
	assert(label(H.find(root, "HourSelector")) == "15")
	local nums = named(H.find(faceOf(root), "Hours"), "Number")
	assert(#nums == 24 and nums[1].Text == "0" and nums[13].Text == "12" and nums[13].Position == UDim2.fromOffset(104, 35), "inner ring 12 at the top")
	assert(handRotation(root) == 90 and handleY(root) == 35, "15 h on the inner ring: " .. handRotation(root) .. " " .. handleY(root))
	print(`[timepicker] Dial vertical 24 h: {H.countDescendants(root) + 1} instances`)
	H.resetOutput()
	assert(H.countDescendants(root) + 1 == 101, tostring(H.countDescendants(root) + 1))
	q.dispose(root)
	local wide = TimePicker.Dial({ Value = value, LayoutType = "Horizontal" })
	assert(wide.Size == UDim2.fromOffset(508, 256))
	assert(H.find(wide, "HourSelector").Position == UDim2.fromOffset(0, 61), tostring(H.find(wide, "HourSelector").Position))
	local toggle = H.find(wide, "PeriodToggle")
	assert(toggle.Size == UDim2.fromOffset(216, 38) and toggle.Position == UDim2.fromOffset(0, 157))
	assert(H.find(toggle, "PM").Position == UDim2.fromOffset(110, 0) and H.find(toggle, "PM").Size == UDim2.fromOffset(106, 38))
	assert(faceOf(wide).Position == UDim2.fromOffset(252, 0))
	q.dispose(wide)
	H.assertNoDebugOutput("24 h / horizontal")
end)

H.section("Dial: outside write snaps, user tap writes + OnChange + animates, hour tap switches to minutes", function()
	local value = q.Source(Clock.time(9, 30))
	local changes: { string } = {}
	local root = TimePicker.Dial({ Value = value, OnChange = function(t: Time)
		table.insert(changes, hm(t))
	end })
	local face = faceOf(root)
	layout(face)
	-- outside write: shown at once, hand snapped (no tween), no OnChange
	H.mock.resetTweenLog()
	value:Set(Clock.time(4, 10))
	assert(label(H.find(root, "HourSelector")) == "04" and handRotation(root) == 120, "snapped: " .. handRotation(root))
	assert(#changes == 0, "no OnChange for a programmatic write")
	-- tap on 2 o'clock: hour 2, animated, OnChange once
	tap(face, at(61, 101))
	assert(hm(value:Get()) == "02:10" and changes[1] == "02:10" and #changes == 1, hm(value:Get()))
	assert(handRotation(root) == 120, "the hand animates (tween pending)")
	H.finishTweens()
	assert(handRotation(root) == 60, "tween landed on 2 o'clock: " .. handRotation(root))
	-- 100 ms later the dial switches to minutes; the hand animates to 10 min = 60 deg (already there)
	assert(H.find(root, "MinuteSelector").BackgroundColor3 ~= L.PrimaryContainer)
	H.advance(0.11)
	H.finishTweens()
	assert(H.find(root, "MinuteSelector").BackgroundColor3 == L.PrimaryContainer, "minute mode after 100 ms")
	assert(named(H.find(face, "Minutes"), "Number")[1].TextTransparency == 0 and named(H.find(face, "Hours"), "Number")[1].TextTransparency == 1)
	-- minute tap snaps to five: 37 min -> 35
	tap(face, at(37 * 6 + 1, 101))
	H.finishTweens()
	assert(hm(value:Get()) == "02:35" and handRotation(root) == 210, hm(value:Get()) .. " " .. handRotation(root))
	-- the minute box click goes back to hours; the hand animates the short way (210 -> 60 = -150)
	click(H.find(root, "HourSelector"))
	H.finishTweens()
	assert(handRotation(root) == 60, tostring(handRotation(root)))
	assert(#changes == 2)
	q.dispose(root)
	H.advance(0.2)
	H.assertNoDebugOutput("tap")
end)

H.section("Dial: drag follows the pointer, keeps every minute; 24 h inner ring by distance; release -> minutes", function()
	local value = q.Source(Clock.time(3, 0))
	local changes = 0
	local root = TimePicker.Dial({ Value = value, Is24Hour = true, OnChange = function()
		changes += 1
	end })
	local face = faceOf(root)
	layout(face, 0.5) -- scaled to half (an ancestor UIScale): the radii scale with it
	H.fire(face, "InputBegan", H.input({ Position = at(90, 101, 0.5) }))
	-- within the 8 px slop: nothing
	;(UIS :: any).InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = at(92, 101, 0.5) }), false)
	assert(hm(value:Get()) == "03:00" and changes == 0)
	-- a drag to 7 o'clock on the inner ring (closer than 74 px of 256): 19 h, the hand exactly under the pointer
	;(UIS :: any).InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = at(212, 60, 0.5) }), false)
	assert(hm(value:Get()) == "19:00", hm(value:Get()))
	assert(handRotation(root) == 212 and handleY(root) == 35, "follows the pointer: " .. handRotation(root))
	-- back out to the outer ring
	;(UIS :: any).InputChanged:Fire(H.input({ UserInputType = Enum.UserInputType.MouseMovement, Position = at(212, 101, 0.5) }), false)
	assert(hm(value:Get()) == "07:00" and handleY(root) == 3)
	;(UIS :: any).InputEnded:Fire(H.input({ Position = at(212, 101, 0.5) }), false)
	H.finishTweens()
	assert(H.find(root, "MinuteSelector").BackgroundColor3 == L.PrimaryContainer, "release switches to minutes")
	assert(handRotation(root) == 0, "the hand animates onto 0 minutes: " .. handRotation(root))
	-- a minute drag keeps every minute (no snap to five)
	dragPath(face, { at(0, 101, 0.5), at(20, 101, 0.5), at(6 * 23 + 1, 101, 0.5) })
	assert(hm(value:Get()) == "07:23", hm(value:Get()))
	assert(uisConns() == baseConns, "drag connections closed")
	q.dispose(root)
	H.assertNoDebugOutput("drag")
end)

H.section("Dial keys: Right / Left step the focus ring (24 h outer -> inner), snapping", function()
	local value = q.Source(Clock.time(11, 7))
	local root = TimePicker.Dial({ Value = value, Is24Hour = true })
	local face = faceOf(root)
	assert(face.Selectable == true and face.NextSelectionLeft == face and face.NextSelectionRight == face, "pinned horizontally")
	H.fire(face, "SelectionGained")
	assert(H.find(face, "FocusRing").Enabled == true, "focus ring while selected")
	key(Enum.KeyCode.Right)
	assert(hm(value:Get()) == "12:07" and handleY(root) == 35, "11 -> 12 on the inner ring")
	key(Enum.KeyCode.Left)
	key(Enum.KeyCode.Left)
	assert(hm(value:Get()) == "10:07")
	click(H.find(root, "MinuteSelector"))
	key(Enum.KeyCode.Right)
	assert(hm(value:Get()) == "10:10", "minutes: from the closest five (5) to the next (10)")
	H.fire(face, "SelectionLost")
	assert(H.find(face, "FocusRing").Enabled == false)
	q.dispose(root)
	H.assertNoDebugOutput("keys")
end)

H.section("AM / PM toggle: moves the hour by 12, OnChange, morphs the shape", function()
	local value = q.Source(Clock.time(7, 45))
	local changes: { string } = {}
	local root = TimePicker.Dial({ Value = value, OnChange = function(t: Time)
		table.insert(changes, hm(t))
	end })
	local pm = H.find(root, "PM")
	click(pm)
	H.finishTweens()
	assert(hm(value:Get()) == "19:45" and changes[1] == "19:45", hm(value:Get()))
	assert(pm.BackgroundColor3 == L.PrimaryContainer and own(pm, "UICorner").CornerRadius == UDim.new(0, 12))
	assert(label(H.find(root, "HourSelector")) == "07", "display stays 07")
	click(pm)
	assert(#changes == 1, "clicking the checked one changes nothing")
	-- pressing the unchecked AM morphs it to 12 while held
	local am = H.find(root, "AM")
	H.fire(am, "InputBegan", H.input({}))
	H.finishTweens()
	assert(own(am, "UICorner").CornerRadius == UDim.new(0, 12), "pressed shape")
	click(am)
	assert(hm(value:Get()) == "07:45" and #changes == 2)
	q.dispose(root)
	H.advance(1)
	H.assertNoDebugOutput("period")
end)

H.section("Input (12 h): layout, typing rules, errors, auto-advance, OnChange user-only", function()
	local value = q.Source(Clock.time(9, 5))
	local changes: { string } = {}
	local root = TimePicker.Input({ Value = value, OnChange = function(t: Time)
		table.insert(changes, hm(t))
	end })
	assert(root.Name == "TimePickerInput" and root.Size == UDim2.fromOffset(272, 111), tostring(root.Size))
	local hourF, minuteF = H.find(root, "HourField"), H.find(root, "MinuteField")
	assert(hourF.Size == UDim2.fromOffset(96, 72) and minuteF.Position == UDim2.fromOffset(120, 0))
	assert(H.find(root, "PeriodToggle").Size == UDim2.fromOffset(52, 72) and H.find(root, "PeriodToggle").Position == UDim2.fromOffset(220, 0))
	assert(H.find(H.find(root, "PeriodToggle"), "PM").Size == UDim2.fromOffset(52, 34))
	assert(hourF.Text == "09" and minuteF.Text == "05")
	local hs, ms = H.find(root, "HourSupport"), H.find(root, "MinuteSupport")
	assert(hs.Text == "Hour" and ms.Text == "Minute" and hs.Position == UDim2.fromOffset(0, 79) and hs.TextColor3 == L.OnSurfaceVariant)
	assert(H.find(hourF, "Outline").Enabled == true and H.find(minuteF, "Outline").Enabled == false, "the hour field is the edited one")
	print(`[timepicker] Input 12 h: {H.countDescendants(root) + 1} instances`)
	H.resetOutput()
	assert(H.countDescendants(root) + 1 == 24, tostring(H.countDescendants(root) + 1))
	-- focus: the edited field turns primaryContainer, 2 px
	hourF:CaptureFocus()
	H.finishTweens()
	assert(hourF.BackgroundColor3 == L.PrimaryContainer and H.find(hourF, "Outline").Thickness == 2 and hourF.TextColor3 == L.OnPrimaryContainer)
	-- a letter is reverted
	hourF.Text = "0a"
	assert(hourF.Text == "09" and hm(value:Get()) == "09:05")
	-- "1": valid (1 AM), no auto-advance for 1 (12 h digits 2..9 only)
	hourF.Text = "1"
	assert(hm(value:Get()) == "01:05" and changes[1] == "01:05" and H.find(hourF, "Outline").Enabled == true)
	-- "13": invalid in 12 h — error, Value keeps 01:05
	hourF.Text = "13"
	H.finishTweens()
	assert(hm(value:Get()) == "01:05" and hs.Text == "Hour must be 1\u{2013}12" and hs.TextColor3 == L.Error, hs.Text)
	assert(hourF.BackgroundColor3 == L.ErrorContainer and hourF.TextColor3 == L.Error and H.find(hourF, "Outline").Color == L.Error)
	-- a third digit replaces the field
	hourF.Text = "136"
	-- "6" is valid and a 12 h digit 2..9: on to the minute field (it takes the focus); the hour field now shows the
	-- time selector's text "06"
	assert(hm(value:Get()) == "06:05" and hs.Text == "Hour" and hourF.Text == "06", hourF.Text)
	assert(H.find(minuteF, "Outline").Enabled == true and minuteF:IsFocused(), "auto-advanced")
	H.finishTweens()
	assert(hourF.Text == "06" and hourF.BackgroundColor3 == L.SurfaceContainerHighest, "the other field shows the selector text")
	-- minutes
	minuteF.Text = "75"
	assert(ms.Text == "Minute must be 0\u{2013}59" and hm(value:Get()) == "06:05")
	minuteF.Text = "42"
	assert(hm(value:Get()) == "06:42" and ms.Text == "Minute")
	minuteF.Text = ""
	assert(hm(value:Get()) == "06:00", "empty minute = 0")
	-- the PM toggle (input sizes) moves the hour; the text follows
	click(H.find(root, "PM"))
	assert(hm(value:Get()) == "18:00" and hourF.Text == "06")
	-- 12 typed in PM = noon
	hourF:CaptureFocus()
	hourF.Text = "12"
	assert(hm(value:Get()) == "12:00", hm(value:Get()))
	-- an outside write rewrites the texts, no OnChange
	local n = #changes
	value:Set(Clock.time(23, 59))
	assert(hourF.Text == "11" and minuteF.Text == "59" and #changes == n)
	q.dispose(root)
	H.assertNoDebugOutput("input 12 h")
end)

H.section("Input (24 h): no toggle, 0..23, two digits advance, Enter advances", function()
	local value = q.Source(Clock.time(0, 0))
	local root = TimePicker.Input({ Value = value, Is24Hour = true, Locale = "ko" })
	assert(root.Size == UDim2.fromOffset(216, 111) and H.find(root, "PeriodToggle") == nil)
	local hourF, minuteF = H.find(root, "HourField"), H.find(root, "MinuteField")
	local hs = H.find(root, "HourSupport")
	assert(hs.Text == "시간" and H.find(root, "MinuteSupport").Text == "분")
	hourF:CaptureFocus()
	hourF.Text = "2"
	assert(hm(value:Get()) == "02:00" and not minuteF:IsFocused(), "24 h: one digit does not advance")
	hourF.Text = "24"
	assert(hs.Text == "시간은 0~23이어야 함" and hm(value:Get()) == "02:00")
	hourF.Text = "23"
	assert(hm(value:Get()) == "23:00" and minuteF:IsFocused(), "two valid digits advance")
	minuteF:ReleaseFocus()
	hourF:CaptureFocus()
	hourF.Text = "7"
	hourF:ReleaseFocus()
	assert(not minuteF:IsFocused())
	hourF:CaptureFocus()
	H.fire(hourF, "FocusLost", true, nil)
	assert(minuteF:IsFocused(), "Enter in the hour field moves on")
	q.dispose(root)
	H.assertNoDebugOutput("input 24 h")
end)

local function setupModal(w: number?, h: number?)
	local overlay = Overlay.new()
	local screen = D.Frame { overlay.Layer }
	if w ~= nil and h ~= nil then
		H.setAbs(overlay.Layer, 0, 0, w, h)
	end
	return overlay, screen
end
local function buttonByLabel(root: any, text: string): any
	for _, b in named(root, "Button") do
		if label(b) == text then
			return b
		end
	end
	error("no button " .. text)
end

H.section("Modal: draft / OK commits / Cancel discards; title, sizes, mode toggle, OK gating", function()
	local overlay, screen = setupModal()
	local value = q.Source(Clock.time(8, 15))
	local confirmed: { string } = {}
	local cancelled = 0
	local handle = TimePicker.Modal.open({
		Overlay = overlay,
		Value = value,
		OnConfirm = function(t: Time)
			table.insert(confirmed, hm(t))
		end,
		OnCancel = function()
			cancelled += 1
		end,
	})
	local card = H.find(screen, "TimePickerModal")
	assert((card :: any).Active == true, "the card keeps 3D input out")
	ClickSink.assertClickSink(card, "the time picker card (a click / dial drag on it must not reach the scrim)")
	assert(card ~= nil and card.ClassName == "CanvasGroup" and card.Size == UDim2.fromOffset(320, 528), tostring(card and card.Size))
	assert(card.BackgroundColor3 == L.SurfaceContainerHigh and own(card, "UICorner").CornerRadius == UDim.new(0, 28))
	local title = H.find(card, "Title")
	assert(title.Text == "Select Time" and title.Position == UDim2.fromOffset(24, 24))
	local picker, input = H.find(card, "TimePicker"), H.find(card, "TimeInput")
	assert(picker.Visible == true and input.Visible == false and picker.Position == UDim2.fromOffset(24, 60))
	local actions = H.find(card, "Actions")
	assert(actions.Position == UDim2.fromOffset(24, 456) and actions.Size == UDim2.fromOffset(272, 48), tostring(actions.Position))
	local toggle = H.find(card, "ModeToggle")
	assert(H.find(toggle, "Icon").Image == "rbxassetid://6034818398", "keyboard icon in picker mode")
	H.finishTweens()
	assert(card.GroupTransparency == 0)
	-- edit the draft on the dial: the committed value is untouched
	local face = faceOf(card)
	layout(face)
	tap(face, at(90, 101))
	assert(label(H.find(card, "HourSelector")) == "03" and hm(value:Get()) == "08:15", "draft only")
	-- switch to the input: smaller card, other title, schedule icon, the hour field takes the focus
	click(toggle)
	assert(card.Size == UDim2.fromOffset(320, 243) and title.Text == "Enter Time", tostring(card.Size))
	assert(input.Visible == true and picker.Visible == false and input.Position == UDim2.fromOffset(24, 60))
	assert(actions.Position == UDim2.fromOffset(24, 171))
	assert(H.find(toggle, "Icon").Image == "rbxassetid://6031260808", "schedule icon in input mode")
	local hourF = H.find(card, "HourField")
	assert(hourF.Text == "03" and hourF:IsFocused(), "synced and focused")
	-- invalid text disables OK
	local ok = buttonByLabel(card, "OK")
	hourF.Text = "13"
	assert(ok.Interactable == false, "OK disabled while invalid")
	click(ok)
	assert(handle.IsOpen:Get() == true)
	hourF.Text = "4"
	assert(ok.Interactable == true)
	-- Cancel discards
	click(buttonByLabel(card, "Cancel"))
	assert(not handle.IsOpen:Get() and cancelled == 1 and #confirmed == 0 and hm(value:Get()) == "08:15")
	H.advance(0.5)
	assert(H.find(screen, "TimePickerModal") == nil and overlay.Count:Get() == 0)
	-- second dialog, 24 h, starting in the input: OK commits
	local h2 = TimePicker.Modal.open({ Overlay = overlay, Value = value, Is24Hour = true, DisplayMode = "Input", OnConfirm = function(t: Time)
		table.insert(confirmed, hm(t))
	end })
	local card2 = H.find(screen, "TimePickerModal")
	assert(card2.Size == UDim2.fromOffset(264, 243), tostring(card2.Size))
	local f2 = H.find(card2, "HourField")
	assert(f2.Text == "08" and f2:IsFocused(), "fresh draft from the committed value, focused")
	f2.Text = "21"
	click(buttonByLabel(card2, "OK"))
	assert(hm(value:Get()) == "21:15" and confirmed[1] == "21:15" and cancelled == 1 and not h2.IsOpen:Get())
	H.advance(0.5)
	assert(overlay.Count:Get() == 0 and #screen:GetChildren() == 1)
	q.dispose(screen)
	H.assertNoDebugOutput("modal")
end)

H.section("Modal: landscape layer -> Horizontal dial (556 x 332); short layer -> input only; scrim cancels; ko", function()
	local overlay, screen = setupModal(1280, 720)
	local cancelled = 0
	TimePicker.Modal.open({ Overlay = overlay, Initial = Clock.time(13, 5), Locale = "ko", OnCancel = function()
		cancelled += 1
	end })
	local card = H.find(screen, "TimePickerModal")
	assert(card.Size == UDim2.fromOffset(556, 332), tostring(card.Size))
	assert(H.find(card, "TimePicker").Size == UDim2.fromOffset(508, 256) and H.find(card, "TimePicker").Position == UDim2.fromOffset(24, 16))
	assert(H.find(card, "Actions").Position == UDim2.fromOffset(24, 276))
	assert(H.find(card, "Title").Text == "시간 선택" and label(H.find(card, "PM")) == "오후")
	assert(label(H.find(card, "HourSelector")) == "01")
	click(H.find(screen, "Scrim"))
	assert(cancelled == 1)
	H.advance(0.5)
	-- a layer at most 300 tall: no dial, no toggle (TimePickerDialogDefaults.MinHeightForTimePicker)
	H.setAbs(overlay.Layer, 0, 0, 800, 280)
	TimePicker.Modal.open({ Overlay = overlay, Initial = Clock.time(6, 0) })
	local card2 = H.find(screen, "TimePickerModal")
	assert(card2.Size == UDim2.fromOffset(320, 243) and H.find(card2, "TimeInput").Visible == true)
	assert(H.find(card2, "ModeToggle").Visible == false)
	assert(own(card2, "UIScale").Scale < 1, "fits the short layer")
	H.find(card2, "HourField"):ReleaseFocus()
	click(buttonByLabel(card2, "Cancel"))
	H.advance(0.5)
	q.dispose(screen)
	H.assertNoDebugOutput("modal landscape")
end)

H.section("Modal: default value is the time now at UtcOffset; icons overridden away -> glyph toggle", function()
	local overlay, screen = setupModal()
	Icons.override({ keyboard = false })
	TimePicker.Modal.open({ Overlay = overlay, UtcOffset = 0 })
	local card = H.find(screen, "TimePickerModal")
	local toggle = H.find(card, "ModeToggle")
	assert(toggle.ClassName == "TextButton" and toggle.Text == "\u{2328}", "glyph fallback: " .. toggle.ClassName)
	local now = Clock.now(nil, 0)
	local shown = tonumber(label(H.find(card, "MinuteSelector")))
	assert(shown == now.Minute or shown == (now.Minute + 1) % 60, "starts at the current time")
	Icons.override(Icons.Defaults :: any)
	q.dispose(screen)
	H.advance(1)
	H.assertNoDebugOutput("modal now")
end)

H.section("Hooks / Modifier on the hosts; ripples bounded; dispose leaves nothing", function()
	local seen: { any } = {}
	local function hooks(): Util.Hooks
		return { Util.preHook(function(inst: GuiObject)
			table.insert(seen, inst)
		end) }
	end
	local value = q.Source(Clock.time(10, 10))
	local dial = TimePicker.Dial({ Value = value, Hooks = hooks(), Modifier = D.Modifier.Frame():Position(UDim2.fromOffset(5, 6)) })
	local input = TimePicker.Input({ Value = value, Hooks = hooks() })
	assert(seen[1] == dial and seen[2] == input, "Hooks reached the hosts")
	assert(dial.Position == UDim2.fromOffset(5, 6))
	-- press every interactive part: the ripples stay Offset-only (the hosts are fixed-size, nothing auto-sized)
	for _, root in { dial, input } do
		local buttons: { any } = (H :: any).findAll(root, function(x: any): boolean
			return x.ClassName == "TextButton"
		end)
		for _, b in buttons do
			H.setAbs(b, 10, 10, (b.Size :: UDim2).X.Offset, (b.Size :: UDim2).Y.Offset)
			local sl = H.find(b, "StateLayer")
			if sl ~= nil then
				H.setAbs(sl, 10, 10, (b.Size :: UDim2).X.Offset, (b.Size :: UDim2).Y.Offset)
			end
			H.fire(b, "InputBegan", H.input({ Position = Vector3.new(30, 25, 0) }))
			-- through full cover (0.45 s): below a ripple group nothing has any Scale (Ripple.luau "FULL COVER")
			for _ = 1, 32 do
				H.advance(1 / 60)
				assertNoPartialScale(root, b.Name)
				if H.find(b, "Ripple") ~= nil then
					Bounded.assertNoScale(b, b.Name)
				end
			end
			H.fire(b, "InputEnded", H.input({}))
		end
	end
	H.advance(1)
	H.finishTweens()
	q.dispose(dial)
	q.dispose(input)
	H.advance(1)
	assert(uisConns() == baseConns, `input connections: {uisConns()} vs {baseConns}`)
	assert(H.pendingTimers() == 0, `pending timers: {H.pendingTimers()}`)
	H.assertNoDebugOutput("hooks / ripple / dispose")
end)

H.done()
