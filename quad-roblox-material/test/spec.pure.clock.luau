--!strict
-- Pure spec for TimePicker/Clock (plain `luau`, no engine). The expectations are Compose material3's (Clock.luau header).
local C = require("../src/TimePicker/Clock")
type Time = C.Time

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
local function throws(f: () -> any, msg: string)
	local ok = pcall(f)
	check(not ok, msg .. " should throw")
end
local function hm(t: Time): string
	return C.pad2(t.Hour) .. ":" .. C.pad2(t.Minute)
end
local PI = math.pi

-- construction / validation
local t = C.time(9, 30)
eq(t.Hour, 9, "hour")
eq(t.Minute, 30, "minute")
check(table.isfrozen(t), "frozen")
check(C.equals(t, C.time(9, 30)) and not C.equals(t, C.time(9, 31)), "equals")
throws(function() return C.time(24, 0) end, "hour 24")
throws(function() return C.time(-1, 0) end, "hour -1")
throws(function() return C.time(1, 60) end, "minute 60")
throws(function() return C.time(1.5, 0) end, "fractional hour")
check(C.isValid(0, 0) and C.isValid(23, 59) and not C.isValid(23, 60), "isValid")

-- now (UTC + offset; never the machine zone)
eq(hm(C.now(function() return 0 end)), "00:00", "epoch UTC")
eq(hm(C.now(function() return 0 end, 9 * 3600)), "09:00", "epoch KST")
eq(hm(C.now(function() return 86400 * 3 + 3600 * 23 + 60 * 59 + 30 end)), "23:59", "end of a day")
eq(hm(C.now(function() return 3600 end, -2 * 3600)), "23:00", "negative offset wraps to the previous day")

-- hours (TimePickerState.isPm / hourForDisplay / isValidHour)
check(not C.isPm(11) and C.isPm(12) and C.isPm(23), "isPm")
for h, want in { [0] = 12, [1] = 1, [11] = 11, [12] = 12, [13] = 1, [23] = 11 } do
	eq(C.hourForDisplay(h, false), want, "12 h display " .. h)
end
eq(C.hourForDisplay(0, true), 0, "24 h display 0")
eq(C.hourForDisplay(17, true), 17, "24 h display 17")
check(C.isValidHour(0, false, false) and C.isValidHour(11, false, false) and not C.isValidHour(12, false, false), "12 h AM 0..11")
check(C.isValidHour(12, false, true) and C.isValidHour(23, false, true) and not C.isValidHour(11, false, true), "12 h PM 12..23")
check(C.isValidHour(0, true, false) and C.isValidHour(23, true, true) and not C.isValidHour(24, true, false), "24 h 0..23")
eq(hm(C.withPeriod(C.time(7, 5), true)), "19:05", "to PM")
eq(hm(C.withPeriod(C.time(19, 5), false)), "07:05", "to AM")
eq(hm(C.withPeriod(C.time(0, 0), true)), "12:00", "midnight to PM = noon")
eq(C.format(C.time(7, 5), false), "7:05 AM", "format 12 h")
eq(C.format(C.time(0, 5), false, "오전", "오후"), "12:05 오전", "format 12 h midnight, own texts")
eq(C.format(C.time(19, 5), true), "19:05", "format 24 h")
eq(C.pad2(7), "07", "pad2")

-- dial angles: clockwise from 12 o'clock, screen y down
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end
check(near(C.dialAngle(0, -10), 0), "12 o'clock = 0")
check(near(C.dialAngle(10, 0), PI / 2), "3 o'clock = pi/2")
check(near(C.dialAngle(0, 10), PI), "6 o'clock = pi")
check(near(C.dialAngle(-10, 0), 3 * PI / 2), "9 o'clock = 3pi/2")
eq(C.nearestHourIndex(C.dialAngle(10, 0)), 3, "3 o'clock -> 3")
eq(C.nearestHourIndex(C.dialAngle(0, -10)), 0, "12 o'clock -> index 0")
eq(C.nearestHourIndex(2 * PI - 0.01), 0, "just before 12 -> 0")
eq(C.nearestHourIndex(PI / 12 - 0.001), 0, "just under half an hour -> 0")
eq(C.nearestHourIndex(PI / 12 + 0.001), 1, "just over half an hour -> 1")
eq(C.nearestMinute(PI / 2), 15, "3 o'clock = 15 min")
eq(C.nearestMinute(2 * PI * 37 / 60 + 0.01), 37, "drag keeps every minute")
eq(C.nearestFiveMinutes(2 * PI * 37 / 60 + 0.01), 35, "tap snaps to five (37 -> 35)")
eq(C.nearestFiveMinutes(2 * PI * 38 / 60), 40, "tap snaps to five (38 -> 40)")
eq(C.nearestFiveMinutes(2 * PI * 58 / 60), 0, "tap snaps to five (58 -> 0)")
-- ring position -> hour (24 h: inner ring = 12..23; 12 h: the current period)
eq(C.hourAt(0, true, false, false), 0, "24 h outer top = 0")
eq(C.hourAt(0, true, true, false), 12, "24 h inner top = 12")
eq(C.hourAt(5, true, true, false), 17, "24 h inner 5 = 17")
eq(C.hourAt(0, false, false, true), 12, "12 h PM top = 12 (noon)")
eq(C.hourAt(3, false, true, false), 3, "12 h ignores the ring")
-- the hand
eq(C.handDegrees("Hour", C.time(15, 40)), 90, "hand 15 h = 90 deg")
eq(C.handDegrees("Minute", C.time(15, 40)), 240, "hand 40 min = 240 deg")
check(C.onInnerRing("Hour", C.time(15, 0), true) and not C.onInnerRing("Hour", C.time(3, 0), true), "24 h PM hour on the inner ring")
check(not C.onInnerRing("Minute", C.time(15, 0), true) and not C.onInnerRing("Hour", C.time(15, 0), false), "inner ring only for 24 h hours")
eq(C.shortestDegrees(350, 10), 370, "shortest way forward across 12")
eq(C.shortestDegrees(10, 350), -10, "shortest way back across 12")
eq(C.shortestDegrees(720, 90), 810, "unwrapped turns kept")
eq(C.shortestDegrees(0, 180), 180, "half a turn goes forward")

-- faces and labels (Compose: "12, 1..11", 24 h outer "0..11" + inner "12..23", minutes "0, 5..55")
local outer, inner = C.faceValues("Hour", false)
eq(outer[1], 12, "12 h top")
eq(inner, nil, "12 h no inner ring")
local o24, i24 = C.faceValues("Hour", true)
eq(o24[1], 0, "24 h outer top 0")
eq(i24 and i24[1], 12, "24 h inner top 12")
eq(i24 and i24[12], 23, "24 h inner last 23")
local m = C.faceValues("Minute", true)
eq(#m, 12, "12 minute numbers")
eq(m[2], 5, "minute 5")
eq(C.labelText(0), "0", "minDigits 1 (Compose toLocalString)")
-- CircularLayout: 101 px ring of a 256 dial, 48 px cells
local x, y = C.labelOffset(0, 12, 101, 256, 48)
eq(x, 104, "top cell x")
eq(y, 3, "top cell y")
x, y = C.labelOffset(3, 12, 101, 256, 48)
eq(x, 205, "3 o'clock cell x")
eq(y, 104, "3 o'clock cell y")
x, y = C.labelOffset(6, 12, 69, 256, 48)
eq(x, 104, "inner 6 o'clock x")
eq(y, 173, "inner 6 o'clock y")

-- keyboard focus ring
eq(hm(C.stepDial(C.time(9, 7), "Minute", false, 1)), "09:10", "minute next from the closest five (7 -> 5 -> 10)")
eq(hm(C.stepDial(C.time(9, 58), "Minute", false, 1)), "09:05", "minute next wraps (58 -> 0 -> 5)")
eq(hm(C.stepDial(C.time(9, 0), "Minute", false, -1)), "09:55", "minute previous wraps")
eq(hm(C.stepDial(C.time(11, 0), "Hour", false, 1)), "00:00", "12 h AM 11 -> 12 (stays AM)")
eq(hm(C.stepDial(C.time(23, 0), "Hour", false, 1)), "12:00", "12 h PM 11 -> 12 (stays PM)")
eq(hm(C.stepDial(C.time(12, 0), "Hour", false, -1)), "23:00", "12 h PM 12 -> 11")
eq(hm(C.stepDial(C.time(11, 0), "Hour", true, 1)), "12:00", "24 h outer 11 -> inner 12")
eq(hm(C.stepDial(C.time(23, 0), "Hour", true, 1)), "00:00", "24 h inner 23 -> outer 0")

-- text input (TimeInputTransformation)
local function edit(old: string, new: string): string
	local text, _ = C.editField(old, new)
	return if text == nil then "<reject>" else text
end
eq(edit("", "7"), "7", "one digit")
eq(edit("0", "07"), "07", "two digits")
eq(edit("07", "071"), "1", "third digit at the end replaces the field")
eq(edit("07", "107"), "1", "third digit at the start replaces the field")
eq(edit("07", "017"), "1", "third digit in the middle replaces the field")
eq(edit("07", "0a"), "<reject>", "non-digit")
eq(edit("07", " 7"), "<reject>", "space")
eq(edit("", "123"), "<reject>", "pasted three digits")
eq(edit("07", ""), "", "empty")
local _, ins = C.editField("1", "12")
check(ins, "typing inserts")
local _, ins2 = C.editField("12", "1")
check(not ins2, "deleting does not")
eq(C.hourFromTyped(7, false, false), 7, "12 h AM 7")
eq(C.hourFromTyped(7, false, true), 19, "12 h PM 7 -> 19")
eq(C.hourFromTyped(12, false, false), 0, "12 h AM 12 -> 0")
eq(C.hourFromTyped(12, false, true), 12, "12 h PM 12 -> 12")
eq(C.hourFromTyped(13, false, false), 13, "12 h 13 stays (invalid)")
eq(C.hourFromTyped(13, true, false), 13, "24 h 13")

print(("clock: %d checks, %d failed"):format(count, failed))
if failed > 0 then
	error("spec.pure.clock failed")
end
