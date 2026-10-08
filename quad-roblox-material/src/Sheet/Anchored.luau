--!strict
--[[
	Anchored: the state core every sliding surface of the kit shares — the bottom sheets, the side sheets and the navigation
	drawers. It is the kit's form of Compose's AnchoredDraggableState (androidx/androidx@40ff481
	compose/foundation/foundation/src/commonMain/kotlin/androidx/compose/foundation/gestures/AnchoredDraggable.kt): a
	settled value (`Current`, Compose `settledValue` / the sheet's `currentValue`), a `Target` (the value an animation or a
	released drag is heading to), a set of enabled values and an optional veto (`Confirm`, Compose `confirmValueChange`).

	The public state objects (`SheetState` in Sheet/State.luau, `DrawerState` in NavigationDrawer/State.luau) wrap one record
	each; the component that shows the state ATTACHES a driver (Sheet/Slide.luau) which owns the anchors and the motion.
	Without a driver a request just settles at once (Compose: `animateTo` a value with no anchor updates the value only).

	    local rec = Anchored.new("Hidden", { Hidden = true, Expanded = true }, confirm)
	    Anchored.bind(publicState, rec)          -- the public object -> its record (weak keys)
	    Anchored.go(rec, "Expanded", "Show")     -- set Target, let the driver animate (or settle at once)
	    local detach = Anchored.attach(rec, driver, who)   -- the latest component drives the state

	Pure helpers (no engine):
	  Anchored.closest(anchors, pos, searchUpwards?)       Compose DraggableAnchors.closestAnchor (both overloads, AnchoredDraggable.kt
	                                                       1622-1649 — ties go to the LATER anchor, `<=`)
	  Anchored.computeTarget(anchors, offset, velocity, positionalThreshold, velocityThreshold)
	                                                       Compose `DraggableAnchors.computeTarget` (AnchoredDraggable.kt 1485-1515):
	                                                       not moving -> closest; |velocity| >= the velocity threshold -> the next
	                                                       anchor in the direction of motion; else the next anchor only once the
	                                                       offset is `positionalThreshold(distance)` past the anchor it started from
	  Anchored.tracker() -> Tracker                        pointer velocity on two axes: `Add(x, y)` per pointer event, `Velocity()`
	                                                       at release (px / s). The slope between the oldest and the newest sample
	                                                       of the last 100 ms (Compose VelocityTracker's horizon), 0 when the pointer
	                                                       rested more than 40 ms before the release (its AssumePointerMoveStopped)
	  Anchored.clock                                       the time source of the tracker (`os.clock`; the specs swap in the
	                                                       harness' virtual clock)
	Anchors are `{ Value: string, Pos: number }` in the DRAG AXIS' pointer space (a pointer delta adds to an offset directly).
]]

local q = require("../Quad")

export type Kind = "Show" | "Hide" | "Settle"
export type Anchor = { Value: string, Pos: number }

export type Driver = {
	HasAnchor: (value: string) -> boolean,
	Go: (value: string, kind: Kind) -> (),
	Snap: (value: string) -> (),
}

export type Rec = {
	Target: q.Source<string>,
	Current: q.Source<string>,
	Enabled: { [string]: boolean },
	Confirm: ((value: string) -> boolean)?,
	Driver: Driver?,
}

export type Tracker = {
	Reset: () -> (),
	Add: (x: number, y: number) -> (),
	Velocity: () -> (number, number),
}

local Anchored = {}

Anchored.clock = os.clock

local records: { [any]: Rec } = setmetatable({}, { __mode = "k" }) :: any

function Anchored.new(initial: string, enabled: { [string]: boolean }, confirm: ((value: string) -> boolean)?): Rec
	return {
		Target = q.Source(initial),
		Current = q.Source(initial),
		Enabled = enabled,
		Confirm = confirm,
		Driver = nil,
	}
end

function Anchored.bind(public: any, rec: Rec)
	records[public] = rec
end

function Anchored.recOf(public: any, who: string): Rec
	local rec = records[public]
	if rec == nil then
		error(`{who}: expected a state made by Material.SheetState / Material.DrawerState (got {typeof(public)})`, 3)
	end
	return rec
end

-- the confirm veto (Compose confirmValueChange): no veto -> true
function Anchored.confirm(rec: Rec, value: string): boolean
	local c = rec.Confirm
	return c == nil or c(value)
end

-- set the target and let the attached driver animate there; without a driver the value settles at once
function Anchored.go(rec: Rec, value: string, kind: Kind)
	rec.Target:Set(value)
	local d = rec.Driver
	if d ~= nil then
		d.Go(value, kind)
	else
		rec.Current:Set(value)
	end
end

function Anchored.snap(rec: Rec, value: string)
	rec.Target:Set(value)
	local d = rec.Driver
	if d ~= nil then
		d.Snap(value)
	else
		rec.Current:Set(value)
	end
end

-- ONE driver per state (Compose: one state per sheet): the component built last takes the state over — a rebuild (a
-- `Slot:Single` builds the new element before it removes the old one) or a modal sheet reopened with the same state;
-- the old driver stops writing it. The returned detach settles the value (only while that driver is still the one).
function Anchored.attach(rec: Rec, driver: Driver, _who: string): () -> ()
	rec.Driver = driver
	return function()
		if rec.Driver == driver then
			rec.Driver = nil
			rec.Current:Set(rec.Target:Get())
		end
	end
end

function Anchored.closest(anchors: { Anchor }, pos: number, searchUpwards: boolean?): Anchor?
	local best: Anchor? = nil
	local bestDistance = math.huge
	for _, a in anchors do
		local d: number
		if searchUpwards == nil then
			d = math.abs(pos - a.Pos)
		else
			local delta = if searchUpwards then a.Pos - pos else pos - a.Pos
			d = if delta < 0 then math.huge else delta
		end
		if d <= bestDistance then
			best, bestDistance = a, d
		end
	end
	return best
end

function Anchored.computeTarget(
	anchors: { Anchor },
	offset: number,
	velocity: number,
	positionalThreshold: (distance: number) -> number,
	velocityThreshold: number
): string?
	if #anchors == 0 then
		return nil
	end
	local moving = math.abs(velocity) > 0
	local forward = moving and velocity > 0
	if not moving then
		return (Anchored.closest(anchors, offset) :: Anchor).Value
	end
	if math.abs(velocity) >= math.abs(velocityThreshold) then
		local hit = Anchored.closest(anchors, offset, forward) or Anchored.closest(anchors, offset)
		return (hit :: Anchor).Value
	end
	local left = Anchored.closest(anchors, offset, false) or Anchored.closest(anchors, offset)
	local right = Anchored.closest(anchors, offset, true) or Anchored.closest(anchors, offset)
	local l, r = left :: Anchor, right :: Anchor
	local distance = math.abs(l.Pos - r.Pos)
	local threshold = math.abs(positionalThreshold(distance))
	local from = if forward then l.Pos else r.Pos
	if math.abs(from - offset) >= threshold then
		return if forward then r.Value else l.Value
	end
	return if forward then l.Value else r.Value
end

local HORIZON = 0.1 -- Compose VelocityTracker HorizonMilliseconds (100)
local STOPPED = 0.04 -- Compose AssumePointerMoveStoppedMilliseconds (40)

function Anchored.tracker(): Tracker
	local ts: { number } = {}
	local xs: { number } = {}
	local ys: { number } = {}
	local function reset()
		table.clear(ts)
		table.clear(xs)
		table.clear(ys)
	end
	local function add(x: number, y: number)
		local now = Anchored.clock()
		table.insert(ts, now)
		table.insert(xs, x)
		table.insert(ys, y)
		-- drop samples older than the horizon (keep the newest one at least)
		while #ts > 1 and now - ts[1] > HORIZON do
			table.remove(ts, 1)
			table.remove(xs, 1)
			table.remove(ys, 1)
		end
	end
	local function velocity(): (number, number)
		local n = #ts
		if n < 2 then
			return 0, 0
		end
		if Anchored.clock() - ts[n] > STOPPED then
			return 0, 0
		end
		local dt = ts[n] - ts[1]
		if dt <= 0 then
			return 0, 0
		end
		return (xs[n] - xs[1]) / dt, (ys[n] - ys[1]) / dt
	end
	return { Reset = reset, Add = add, Velocity = velocity }
end

return Anchored
