--!strict
--[[
	Geometry: the arithmetic of drag-to-reorder (internal to ListReorder) — pure: no engine, no quad, no globals except
	the standard library, so `test/spec.pure.listgeometry.luau` runs it under the plain `luau` CLI.

	Every length is in the list's LOCAL units (screen pixels divided by the UIScale product), except where a name says
	px. A row is a `Box`: its resting `top` relative to the list host and its `height`; `order` is the session's rows in
	layout order (index = place). Rules and sources are in the ListReorder header (init.luau "Giving way", "Edge scroll",
	"HOW").

	  slots(order, at, height)        where a row of `height` lifted from place `at` would rest at every place: above it
	                                  the others' own tops, below it their bottoms less its height
	  target(slots, current, top)     the place whose resting top is nearest `top` (ties keep `current`)
	  giveWay(i, from, to, step)      the offset of the row at place `i` (not `from`) while the dragged row is taken from
	                                  `from` to `to`: one `step` (the dragged height + gap) toward the gap, else 0
	  range(order, dragged)           the dragged row's offset bounds: it stays between the first row's top and the last
	                                  row's bottom (0, 0 when the list is shorter than the row)
	  follow(pointer, list, scale, lo, hi)
	                                  the dragged row's offset: the pointer's travel less the list's own travel (an edge
	                                  scroll moves it), both px since the press, clamped to the range
	  stack(order, top, gap)          the tops of `order`'s rows stacked from `top` (the places of a new order)
	  reveal(top, bottom, windowTop, windowBottom)
	                                  px to scroll so that [top, bottom] is inside the window (0 when it is)
	  overflow(top, bottom, windowTop, windowBottom, travelled)
	                                  px the row sticks out of the window IN THE DRAG DIRECTION (sign of `travelled`), else 0
	  scrollAmount(out, rowPx, elapsed, dt, scale)
	                                  px to scroll this frame for an overflow `out` (ItemTouchHelper's curve: at least 1 px,
	                                  at most SCROLL_MAX per 60 Hz frame, reached after SCROLL_ACCEL s out of bounds)
	  canvasY(y, delta, canvasHeight, windowHeight)
	                                  a ScrollingFrame's CanvasPosition.Y moved by `delta`, kept inside the canvas
]]

export type Box = { read top: number, read height: number }

-- ItemTouchHelper: 20 dp per frame (a 60 Hz frame) at most, reached after 2 s out of bounds
local SCROLL_MAX = 20
local SCROLL_ACCEL = 2

local function slots(order: { read [number]: Box }, at: number, height: number): { number }
	local out = table.create(#order, 0)
	for i, other in order do
		out[i] = if i > at then other.top + other.height - height else other.top
	end
	return out
end

local function target(slotTops: { number }, current: number, top: number): number
	local best = current
	local bestDistance = math.abs(top - slotTops[current])
	for place, slotTop in slotTops do
		local distance = math.abs(top - slotTop)
		if distance < bestDistance then
			best, bestDistance = place, distance
		end
	end
	return best
end

local function giveWay(i: number, from: number, to: number, step: number): number
	if from < to and i > from and i <= to then
		return -step
	elseif to < from and i >= to and i < from then
		return step
	end
	return 0
end

local function range(order: { read [number]: Box }, dragged: Box): (number, number)
	local last = order[#order]
	local lo = order[1].top - dragged.top
	local hi = last.top + last.height - (dragged.top + dragged.height)
	if lo > hi then
		return 0, 0
	end
	return lo, hi
end

local function follow(pointer: number, list: number, scale: number, lo: number, hi: number): number
	return math.clamp(pointer / scale - list / scale, lo, hi)
end

local function stack(order: { read [number]: Box }, top: number, gap: number): { number }
	local tops = table.create(#order, 0)
	local y = top
	for i, row in order do
		tops[i] = y
		y += row.height + gap
	end
	return tops
end

local function reveal(top: number, bottom: number, windowTop: number, windowBottom: number): number
	if top < windowTop then
		return top - windowTop
	elseif bottom > windowBottom then
		return bottom - windowBottom
	end
	return 0
end

local function overflow(top: number, bottom: number, windowTop: number, windowBottom: number, travelled: number): number
	if travelled < 0 and top < windowTop then
		return top - windowTop
	elseif travelled > 0 and bottom > windowBottom then
		return bottom - windowBottom
	end
	return 0
end

local function scrollAmount(out: number, rowPx: number, elapsed: number, dt: number, scale: number): number
	local ratio = math.min(1, math.abs(out) / math.max(rowPx, 1))
	local cap = (ratio - 1) ^ 5 + 1
	local time = math.min(1, elapsed / SCROLL_ACCEL)
	return math.max(SCROLL_MAX * scale * cap * time ^ 5 * dt * 60, 1) * math.sign(out)
end

local function canvasY(y: number, delta: number, canvasHeight: number, windowHeight: number): number
	return math.clamp(y + delta, 0, math.max(canvasHeight - windowHeight, 0))
end

return {
	slots = slots,
	target = target,
	giveWay = giveWay,
	range = range,
	follow = follow,
	stack = stack,
	reveal = reveal,
	overflow = overflow,
	scrollAmount = scrollAmount,
	canvasY = canvasY,
	SCROLL_MAX = SCROLL_MAX,
	SCROLL_ACCEL = SCROLL_ACCEL,
}
