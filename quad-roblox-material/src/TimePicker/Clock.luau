--!strict
--[[
Clock: pure time-of-day math for the Material 3 time picker. No engine, no quad, no globals except the standard
library (`os.time` only inside `Clock.now`, and only when no clock is injected). Covered by test/spec.pure.clock.luau.

CANON (Google's code — every rule below cites it; "TimePicker.kt" = androidx/androidx@40ff481
compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/TimePicker.kt)
  * state: `TimePickerState` (1487-1551) — `hour` 0..23 and `minute` 0..59 are always valid; `hourInput` /
    `minuteInput` may hold an invalid typed value; `is24hour`; `selection` Hour | Minute. `isPm = hour >= 12` (1553),
    `isValidHour` (1563-1571): 24 h 0..23, 12 h AM 0..11, 12 h PM 12..23. `hourForDisplay` (1890-1897).
  * dial: Hours = 12, 1, ..., 11 / Minutes = 0, 5, ..., 55 / ExtraHours = 12, 13, ..., 23 (4055-4058); in 24 h the outer
    ring shows `Hours % 12` = 0..11 and the INNER ring 12..23 (ClockFace 3270-3414: 3313-3318, 3365-3409); labels are
    `value.toLocalString()` with minDigits 1 (3506) — "0", "5", not "00" (MDC TimePickerClockPresenter writes "00").
    Radii: outer 101 dp, inner 69 dp of the 256 dp dial (4038-4041); the selector sits on the inner ring only while a
    24 h PM hour is being picked (selectorPos 1937-1956). A press closer than MaxDistance 74 dp (4051, scaled with the
    dial) to the center picks the inner ring (moveSelector 1899-1908).
  * angles: Compose turns a pointer into an angle with `atan(y - cy, x - cx)` and two `toHour` / `toMinute` passes
    (toHour / toMinute 1859-1869, rotateTo 1803-1825); both reduce to "the nearest hour / minute clockwise from 12 o'clock" — the form
    used here (`dialAngle`, `nearestHourIndex`, `nearestMinute`). A TAP snaps the angle first: hours to the hour,
    minutes to a multiple of FIVE (onTap 1910-1935); a DRAG keeps every minute.
  * keyboard on the dial (ClockText onKeyEvent 3570-3594): Down / Right move to the next number of the ring, Up / Left
    to the previous one; in 24 h the outer ring continues into the inner one (focus loop 3336-3354, 3396-3401).
  * text input (TimeInputTransformation 3655-3744): digits only, at most two (a third digit typed into a full field
    replaces it), empty = hour 0 (12 in a 12 h PM state) / minute 0; a typed 12 h hour is mapped into the current
    period (12 -> 0 / 12), auto-advance to the minute field after two digits or a 12 h digit 2..9.
  * period toggle (PeriodToggleImpl 2770-2928): AM/PM moves the hour by 12 only while the hour input is valid.

VALUE
  Time = { Hour: number (0-23), Minute: number (0-59) }   -- frozen; compare with Clock.equals
  time(h, m): Time            validates (integers in range), errors with a clear message
  isValid(h, m): boolean      equals(a, b): boolean
  now(clock?, offsetSeconds?): Time   the time of day at UTC + offsetSeconds (`clock` returns unix seconds, default
                                      os.time); the module never reads the machine time zone (like Calendar.today)

HOURS
  isPm(hour): boolean                          hour >= 12
  hourForDisplay(hour, is24): number           24 h: hour; 12 h: 12 for 0 and 12, else hour % 12
  isValidHour(hour, is24, pm): boolean         the TimePickerState rule above
  withPeriod(t, pm): Time                      the same clock hour in AM (pm = false) or PM
  pad2(n): string                              "07" (the time selectors and the input fields)
  format(t, is24, am?, pm?): string            "07:05" / "7:05 PM" (12 h: "AM"/"PM" unless given)

DIAL
  OUTER_RATIO, INNER_RATIO, MAX_DISTANCE_RATIO   101/256, 69/256, 74/256
  dialAngle(dx, dy): number                    radians clockwise from 12 o'clock in [0, 2pi) (screen y grows down)
  nearestHourIndex(phi): 0..11                 nearestMinute(phi): 0..59      nearestFiveMinutes(phi): 0, 5, .., 55
  hourAt(index, is24, inner, pm): number       the hour a ring position means (24 h: inner = 12..23; 12 h: the period)
  handDegrees(selection, t): number            the hand's angle in degrees clockwise from 12 o'clock
  onInnerRing(selection, t, is24): boolean     the selector on the 69 dp ring
  faceValues(face, is24): ({number}, {number}?)  outer ring values (index 0 = 12 o'clock) and the 24 h inner ring
  labelText(value): string                     the dial number as Compose draws it
  labelOffset(index, count, radius, size, box): (x, y)   CircularLayout's top-left of a `box` cell (rounded)
  stepDial(t, selection, is24, dir): Time      the next (+1) / previous (-1) number of the focus ring
  shortestDegrees(current, target): number     `target` (mod 360) moved to the representative nearest `current`

TEXT INPUT
  editField(old, new): (text: string?, inserted: boolean)   the transformation: nil = reject (revert to `old`)
  hourFromTyped(value, is24, pm): number       the typed number mapped to an hour 0..23 (may be invalid)
]]

export type Time = { read Hour: number, read Minute: number }
export type Selection = "Hour" | "Minute"

local OUTER_RATIO = 101 / 256
local INNER_RATIO = 69 / 256
local MAX_DISTANCE_RATIO = 74 / 256
local TAU = math.pi * 2

local function isInt(n: number): boolean
	return n == math.floor(n)
end

local function isValid(h: number, m: number): boolean
	return type(h) == "number" and type(m) == "number" and isInt(h) and isInt(m) and h >= 0 and h <= 23 and m >= 0 and m <= 59
end

local function time(h: number, m: number): Time
	if not isValid(h, m) then
		error(`Clock.time: {tostring(h)}:{tostring(m)} is not a time of day (hour 0..23, minute 0..59, integers)`, 2)
	end
	return table.freeze({ Hour = h, Minute = m })
end

local function equals(a: Time, b: Time): boolean
	return a.Hour == b.Hour and a.Minute == b.Minute
end

local function now(clock: (() -> number)?, offsetSeconds: number?): Time
	local t = (if clock then clock() else os.time()) + (offsetSeconds or 0)
	local s = t % 86400
	return time(math.floor(s / 3600), math.floor((s % 3600) / 60))
end

-- ── hours ────────────────────────────────────────────────────────────────
local function isPm(hour: number): boolean
	return hour >= 12
end

local function hourForDisplay(hour: number, is24: boolean): number
	if is24 then
		return hour % 24
	elseif hour % 12 == 0 then
		return 12
	elseif hour >= 12 then
		return hour - 12
	end
	return hour
end

local function isValidHour(hour: number, is24: boolean, pm: boolean): boolean
	if not isInt(hour) then
		return false
	elseif is24 then
		return hour >= 0 and hour <= 23
	elseif pm then
		return hour >= 12 and hour <= 23
	end
	return hour >= 0 and hour <= 11
end

local function withPeriod(t: Time, pm: boolean): Time
	if pm and t.Hour < 12 then
		return time(t.Hour + 12, t.Minute)
	elseif not pm and t.Hour >= 12 then
		return time(t.Hour - 12, t.Minute)
	end
	return t
end

local function pad2(n: number): string
	return string.format("%02d", n)
end

local function format(t: Time, is24: boolean, am: string?, pm: string?): string
	if is24 then
		return `{pad2(t.Hour)}:{pad2(t.Minute)}`
	end
	local period = if isPm(t.Hour) then (pm or "PM") else (am or "AM")
	return `{hourForDisplay(t.Hour, false)}:{pad2(t.Minute)} {period}`
end

-- ── dial ─────────────────────────────────────────────────────────────────
local function dialAngle(dx: number, dy: number): number
	-- math.atan2 measures from +x toward +y; with screen y down that is clockwise from 3 o'clock
	local a = math.atan2(dy, dx) + math.pi / 2
	a = a % TAU
	if a < 0 then
		a += TAU
	end
	return a
end

local function nearestHourIndex(phi: number): number
	return math.floor(phi / (TAU / 12) + 0.5) % 12
end

local function nearestMinute(phi: number): number
	return math.floor(phi / (TAU / 60) + 0.5) % 60
end

local function nearestFiveMinutes(phi: number): number
	return (math.floor(phi / (TAU / 12) + 0.5) % 12) * 5
end

local function hourAt(index: number, is24: boolean, inner: boolean, pm: boolean): number
	if is24 then
		return index + (if inner then 12 else 0)
	end
	return index + (if pm then 12 else 0)
end

local function handDegrees(selection: Selection, t: Time): number
	if selection == "Minute" then
		return t.Minute * 6
	end
	return (t.Hour % 12) * 30
end

local function onInnerRing(selection: Selection, t: Time, is24: boolean): boolean
	return is24 and selection == "Hour" and t.Hour >= 12
end

local HOURS = table.freeze({ 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 })
local HOURS24_OUTER = table.freeze({ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 })
local HOURS24_INNER = table.freeze({ 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 })
local MINUTES = table.freeze({ 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55 })

local function faceValues(face: Selection, is24: boolean): ({ number }, { number }?)
	if face == "Minute" then
		return MINUTES, nil
	elseif is24 then
		return HOURS24_OUTER, HOURS24_INNER
	end
	return HOURS, nil
end

local function labelText(value: number): string
	return tostring(value)
end

-- Compose CircularLayout (TimePicker.kt 3935-3974): cell i of `count` centered on the circle of `radius` around the
-- center of a `size` square; the cell's top-left, rounded like `roundToInt`
local function labelOffset(index: number, count: number, radius: number, size: number, box: number): (number, number)
	local theta = TAU / count * index - math.pi / 2
	local x = radius * math.cos(theta) + size / 2 - box / 2
	local y = radius * math.sin(theta) + size / 2 - box / 2
	return math.floor(x + 0.5), math.floor(y + 0.5)
end

local function stepDial(t: Time, selection: Selection, is24: boolean, dir: number): Time
	if selection == "Minute" then
		-- the focused number is the five-minute number closest to the minute (ClockText isTheSelectedValue 3507-3518)
		local closest = (math.floor(t.Minute / 5 + 0.5) * 5) % 60
		return time(t.Hour, (closest + 5 * dir) % 60)
	elseif is24 then
		return time((t.Hour + dir) % 24, t.Minute)
	end
	local base = if t.Hour >= 12 then 12 else 0
	return time(base + ((t.Hour % 12) + dir) % 12, t.Minute)
end

local function shortestDegrees(current: number, target: number): number
	local diff = (target - current) % 360
	if diff > 180 then
		diff -= 360
	end
	return current + diff
end

-- ── text input ───────────────────────────────────────────────────────────
local function editField(old: string, new: string): (string?, boolean)
	if new == "" then
		return "", false
	end
	if string.find(new, "%D") ~= nil then
		return nil, false
	end
	local inserted = #new > #old
	local text = new
	if #old == 2 and #new == 3 then
		-- a third digit typed into a full field replaces it with that digit (the cursor decides which one it is:
		-- whatever was not there before)
		local i = 1
		while i <= #old and string.sub(old, i, i) == string.sub(new, i, i) do
			i += 1
		end
		text = string.sub(new, i, i)
	end
	if #text > 2 then
		return nil, false
	end
	return text, inserted
end

local function hourFromTyped(value: number, is24: boolean, pm: boolean): number
	if is24 then
		return value
	elseif value == 12 then
		return if pm then 12 else 0
	elseif pm then
		return value + 12
	end
	return value
end

return {
	OUTER_RATIO = OUTER_RATIO,
	INNER_RATIO = INNER_RATIO,
	MAX_DISTANCE_RATIO = MAX_DISTANCE_RATIO,
	time = time,
	isValid = isValid,
	equals = equals,
	now = now,
	isPm = isPm,
	hourForDisplay = hourForDisplay,
	isValidHour = isValidHour,
	withPeriod = withPeriod,
	pad2 = pad2,
	format = format,
	dialAngle = dialAngle,
	nearestHourIndex = nearestHourIndex,
	nearestMinute = nearestMinute,
	nearestFiveMinutes = nearestFiveMinutes,
	hourAt = hourAt,
	handDegrees = handDegrees,
	onInnerRing = onInnerRing,
	faceValues = faceValues,
	labelText = labelText,
	labelOffset = labelOffset,
	stepDial = stepDial,
	shortestDegrees = shortestDegrees,
	editField = editField,
	hourFromTyped = hourFromTyped,
}
