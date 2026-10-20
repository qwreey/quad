--!strict
-- Pure spec for ListReorder/Geometry (plain `luau`, no engine). The rules are the ListReorder header's ("Giving way",
-- "Edge scroll"); the numbers are local units unless a name says px.
local G = require("../src/ListReorder/Geometry")
type Box = G.Box

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
local function near(a: number, b: number, msg: string)
	check(math.abs(a - b) < 1e-9, ("%s (got %s, want %s)"):format(msg, tostring(a), tostring(b)))
end
local function list(t: { number }): string
	local parts = {}
	for _, v in t do
		table.insert(parts, tostring(v))
	end
	return table.concat(parts, ",")
end
-- rows of the given heights stacked from 0 with `gap` between them
local function rows(heights: { number }, gap: number): { Box }
	local out: { Box } = {}
	local y = 0
	for _, h in heights do
		table.insert(out, { top = y, height = h })
		y += h + gap
	end
	return out
end

-- slots: equal heights — every place's top is the row's own top
local equal = rows({ 56, 56, 56, 56 }, 0)
eq(list(G.slots(equal, 2, 56)), "0,56,112,168", "equal heights, lifted from 2")
eq(list(G.slots(equal, 1, 56)), "0,56,112,168", "equal heights, lifted from 1")
-- mixed heights: above the lifted row the others' tops, below it their bottoms less its height
local mixed = rows({ 56, 72, 88, 56 }, 0) -- tops 0, 56, 128, 216
eq(list(G.slots(mixed, 2, 72)), "0,56,144,200", "mixed, lifted the 72 at 2")
eq(list(G.slots(mixed, 1, 56)), "0,72,160,216", "mixed, lifted the first 56")
eq(list(G.slots(mixed, 4, 56)), "0,56,128,216", "mixed, lifted the last row: every place is a top")
-- a gap is part of the others' tops (and of their bottoms through the next top)
local gapped = rows({ 40, 40, 40 }, 8) -- tops 0, 48, 96
eq(list(G.slots(gapped, 1, 40)), "0,48,96", "gap 8, lifted from 1")

-- target: the nearest resting top; the current place wins ties
local s = G.slots(equal, 2, 56) -- 0, 56, 112, 168
eq(G.target(s, 2, 56), 2, "at rest")
eq(G.target(s, 2, 56 + 27), 2, "27 below: still 2")
eq(G.target(s, 2, 56 + 29), 3, "29 below: past the middle -> 3")
eq(G.target(s, 2, 56 - 29), 1, "29 above -> 1")
eq(G.target(s, 2, 84), 2, "exactly between 2 and 3, current 2: tie keeps 2")
eq(G.target(s, 3, 84), 3, "exactly between 2 and 3, current 3: tie keeps 3")
eq(G.target(s, 2, -500), 1, "far above -> first")
eq(G.target(s, 2, 9000), 4, "far below -> last")
-- mixed heights: a function of the position alone (no flip back after a swap)
local sm = G.slots(mixed, 2, 72) -- 0, 56, 144, 200
for _, current in { 1, 2, 3, 4 } do
	eq(G.target(sm, current, 120), 3, "mixed, top 120 from place " .. current)
	eq(G.target(sm, current, 90), 2, "mixed, top 90 from place " .. current)
end

-- giveWay: dragged from 2 to 4 — rows 3 and 4 step up; from 4 to 2 — rows 2 and 3 step down; others stay
eq(G.giveWay(1, 2, 4, 60), 0, "2->4: row 1 stays")
eq(G.giveWay(3, 2, 4, 60), -60, "2->4: row 3 up")
eq(G.giveWay(4, 2, 4, 60), -60, "2->4: row 4 up")
eq(G.giveWay(5, 2, 4, 60), 0, "2->4: row 5 stays")
eq(G.giveWay(1, 4, 2, 60), 0, "4->2: row 1 stays")
eq(G.giveWay(2, 4, 2, 60), 60, "4->2: row 2 down")
eq(G.giveWay(3, 4, 2, 60), 60, "4->2: row 3 down")
eq(G.giveWay(5, 4, 2, 60), 0, "4->2: row 5 stays")
eq(G.giveWay(1, 3, 3, 60), 0, "not moved: nobody gives way")
eq(G.giveWay(4, 3, 3, 60), 0, "not moved: nobody gives way (below)")

-- range: between the first row's top and the last row's bottom
local lo, hi = G.range(mixed, mixed[2])
eq(lo, -56, "range lo of the second row")
eq(hi, 272 - 128, "range hi of the second row")
lo, hi = G.range(mixed, mixed[1])
eq(lo, 0, "first row cannot go up")
eq(hi, 272 - 56, "first row down to the end")
lo, hi = G.range(mixed, mixed[4])
eq(lo, -216, "last row up to the start")
eq(hi, 0, "last row cannot go down")
-- a single row taller than its list span would invert the bounds: no movement at all
lo, hi = G.range({ { top = 0, height = 10 } }, { top = 0, height = 30 })
eq(lo, 0, "inverted range: lo 0")
eq(hi, 0, "inverted range: hi 0")

-- follow: pointer travel less the list's own travel, in local units, clamped
eq(G.follow(100, 0, 1, -500, 500), 100, "follow the pointer")
eq(G.follow(100, -40, 1, -500, 500), 140, "the list scrolled up 40 px: the row stays under the pointer")
eq(G.follow(100, 0, 2, -500, 500), 50, "UIScale 2: half the px")
eq(G.follow(1000, 0, 1, -50, 200), 200, "clamped high")
eq(G.follow(-1000, 0, 1, -50, 200), -50, "clamped low")

-- stack: tops in a new order, from the first top, gap between
eq(list(G.stack(rows({ 88, 56, 72 }, 0), 0, 0)), "0,88,144", "stack no gap")
eq(list(G.stack(rows({ 40, 40, 40 }, 0), 10, 8)), "10,58,106", "stack from 10 with gap 8")
eq(list(G.stack({}, 0, 0)), "", "stack nothing")

-- reveal: px to bring [top, bottom] into the window
eq(G.reveal(120, 160, 100, 300), 0, "inside")
eq(G.reveal(80, 120, 100, 300), -20, "above: scroll up 20")
eq(G.reveal(280, 330, 100, 300), 30, "below: scroll down 30")
eq(G.reveal(80, 330, 100, 300), -20, "taller than the window: the top wins")

-- overflow: only in the drag direction
eq(G.overflow(80, 120, 100, 300, -5), -20, "dragging up, out above")
eq(G.overflow(80, 120, 100, 300, 5), 0, "dragging down, out above: no scroll")
eq(G.overflow(280, 330, 100, 300, 5), 30, "dragging down, out below")
eq(G.overflow(280, 330, 100, 300, -5), 0, "dragging up, out below: no scroll")
eq(G.overflow(280, 330, 100, 300, 0), 0, "not travelled: no scroll")

-- scrollAmount: ItemTouchHelper's curve
local dt = 1 / 60
-- fully out (ratio 1) after SCROLL_ACCEL seconds: the max per 60 Hz frame
near(G.scrollAmount(60, 56, G.SCROLL_ACCEL, dt, 1), G.SCROLL_MAX, "max speed down")
near(G.scrollAmount(-60, 56, G.SCROLL_ACCEL * 3, dt, 1), -G.SCROLL_MAX, "max speed up (elapsed capped)")
near(G.scrollAmount(60, 56, G.SCROLL_ACCEL, dt, 2), 2 * G.SCROLL_MAX, "UIScale 2 doubles the px")
near(G.scrollAmount(60, 56, G.SCROLL_ACCEL, 2 * dt, 1), 2 * G.SCROLL_MAX, "a 30 Hz frame scrolls twice as far")
-- at least 1 px from the first frame on, with the overflow's sign
eq(G.scrollAmount(1, 56, dt, dt, 1), 1, "slow start: 1 px down")
eq(G.scrollAmount(-1, 56, dt, dt, 1), -1, "slow start: 1 px up")
-- half out, half the acceleration time
local half = G.scrollAmount(28, 56, G.SCROLL_ACCEL / 2, dt, 1)
near(half, math.max(G.SCROLL_MAX * ((0.5 - 1) ^ 5 + 1) * 0.5 ^ 5, 1), "half out, half time")
-- a row shorter than 1 px does not divide by zero
near(G.scrollAmount(5, 0, G.SCROLL_ACCEL, dt, 1), G.SCROLL_MAX, "zero-height row: ratio capped at 1")

-- canvasY: clamped inside the canvas
eq(G.canvasY(100, 50, 1000, 300), 150, "plain move")
eq(G.canvasY(100, -500, 1000, 300), 0, "not above the top")
eq(G.canvasY(650, 100, 1000, 300), 700, "not past the end")
eq(G.canvasY(0, 40, 200, 300), 0, "canvas shorter than the window: stays at 0")

print(("listgeometry: %d checks, %d failed"):format(count, failed))
if failed > 0 then
	error("spec.pure.listgeometry failed")
end
