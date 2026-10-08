--!strict
--[[
	Slide: the driver that puts an anchored state (Sheet/Anchored.luau) on screen — the offset of a sliding surface along
	one axis, its tweens, the drag gesture and the settle back to an anchor. Shared by the bottom sheets, the side sheets
	and the navigation drawers; each of them only says where its anchors are, how long each kind of motion takes and how
	a released drag picks its target (Compose and MDC differ there).

	    local slide = Slide.new({
	        Rec = rec, Axis = "Y", Who = "ModalBottomSheet",
	        Anchors = function() return { { Value = "Hidden", Pos = full }, ... } end,   -- nil = not laid out yet
	        Motion = function(kind) return Motion.Show end,                               -- per Anchored.Kind
	        Release = function(anchors, offset, velocity, cross) return "Expanded" end,  -- target of a released drag
	        CanDrag = function() return true end,
	        OnGo = function(value, kind) end,         -- optional: a request started (the modal sheet closes on Hidden)
	        Initial = 0,                              -- the offset before anything is laid out
	    })
	    Position = slide.Pos:Compute(function(self) local p = self:Get(); return q.Tween({ Value = ..p.Offset.., Time = p.Time, ... }) end)
	    slide.Hook()                                -- a fresh drag hook for one element (array part); several elements may share the gesture
	    slide.Relayout()                            -- the anchors moved (a size changed): the surface follows
	    slide.Detach()                              -- hand the state back now (it settles at its target); the motion under way
	                                                -- finishes on screen (a closing modal sheet, so the same state can open again)
	    slide.Destroy()                             -- cancel the settle timer, detach from the state

	Pos: State<{ Offset, Time, Style, Direction }> — Time 0 while a finger drags (the property snaps), the motion of the
	request otherwise (a `q.Tween` of that time; Time 0 also snaps the first layout). `Dragging: State<boolean>`.

	Requests: `Driver.Go(value, kind)` (from Anchored.go) moves the offset to the value's anchor with that kind's motion and
	schedules ONE settle timer (the motion's time) that writes `Current` — Compose's settledValue changes when the animation
	ends. A request for a value with no anchor yet (the surface is not laid out) keeps the offset and settles after the same
	time; the next `Relayout` puts the surface on the anchor. `Driver.Snap(value)` jumps and settles at once.

	Drag: `Interaction.drag` trackers (one per element given `Hook()`, one gesture at a time across them; `LockScroll`, so
	an ancestor ScrollingFrame does not scroll along). Give `Hook()` to the elements a press actually reaches: a press stops
	at the first GuiButton under the pointer (Util.luau "INPUT RULE"), so on a surface with an ClickSink that is the sink,
	never the surface Frame — plus the handle / scrim buttons. Each pointer move
	adds the axis delta to the offset, coerced into the anchors' range (Compose `newOffsetForDelta`). At release the
	component's `Release` picks the target from the offset and the pointer velocity (Anchored.tracker); a vetoed target
	(`Confirm`) settles back to the current value. A press that moved less than the touch slop (8 px — Android
	ViewConfiguration touch slop, 8 dp) is not a drag: `Moved()` stays false so a click on a handle / scrim still counts;
	past the slop `Moved()` is true while the drag lasts and for 0.25 s after its release (the click that the same press
	delivers on release is ignored by the caller — the engine's Activated and the input-ended signal come in either order).
]]

local q = require("../Quad")
local Interaction = require("../Interaction")
local Anchored = require("./Anchored")

export type Motion = { Time: number, Style: Enum.EasingStyle, Direction: Enum.EasingDirection }
export type Pos = { Offset: number, Time: number, Style: Enum.EasingStyle, Direction: Enum.EasingDirection }

export type Config = {
	Rec: Anchored.Rec,
	Axis: "X" | "Y",
	Who: string,
	Anchors: () -> { Anchored.Anchor }?,
	Motion: (kind: Anchored.Kind) -> Motion,
	Release: (anchors: { Anchored.Anchor }, offset: number, velocity: number, cross: number) -> string?,
	CanDrag: () -> boolean,
	OnGo: ((value: string, kind: Anchored.Kind) -> ())?,
	Initial: number,
}

export type Slide = {
	read Pos: q.State<Pos>,
	read Dragging: q.State<boolean>,
	Hook: () -> Interaction.Hook,
	Relayout: () -> (),
	Moved: () -> boolean,
	Offset: () -> number,
	Detach: () -> (),
	Destroy: () -> (),
}

local TOUCH_SLOP = 8
local CLICK_SUPPRESS = 0.25 -- seconds after a real drag during which a click is the drag's own release

local function anchorOf(anchors: { Anchored.Anchor }?, value: string): number?
	if anchors == nil then
		return nil
	end
	for _, a in anchors do
		if a.Value == value then
			return a.Pos
		end
	end
	return nil
end

local function new(cfg: Config): Slide
	local rec = cfg.Rec
	local snapStyle = Enum.EasingStyle.Linear
	local snapDirection = Enum.EasingDirection.Out
	local pos = q.Source({ Offset = cfg.Initial, Time = 0, Style = snapStyle, Direction = snapDirection } :: Pos)
	local dragging = q.Source(false)
	local offset = cfg.Initial
	local settleThread: thread? = nil
	local lastKind: Anchored.Kind = "Settle"
	local driver: Anchored.Driver
	local destroyed = false

	local function set(o: number, motion: Motion?)
		offset = o
		if motion == nil then
			pos:Set({ Offset = o, Time = 0, Style = snapStyle, Direction = snapDirection })
		else
			pos:Set({ Offset = o, Time = motion.Time, Style = motion.Style, Direction = motion.Direction })
		end
	end

	local function cancelSettle()
		local th = settleThread
		if th ~= nil then
			settleThread = nil
			task.cancel(th)
		end
	end

	local function scheduleSettle(value: string, time: number)
		cancelSettle()
		if time <= 0 then
			if rec.Driver == driver then
				rec.Current:Set(value)
			end
			return
		end
		local th: thread
		th = task.delay(time, function()
			if settleThread == th then
				settleThread = nil
			end
			-- a detached driver (the modal closed and the state was handed on) no longer writes the state
			if rec.Driver == driver and rec.Target:Get() == value then
				rec.Current:Set(value)
			end
		end)
		settleThread = th
	end

	local function go(value: string, kind: Anchored.Kind)
		if destroyed then
			return
		end
		lastKind = kind
		local motion = cfg.Motion(kind)
		local target = anchorOf(cfg.Anchors(), value)
		if target ~= nil and not dragging:Get() then
			set(target, motion)
		end
		scheduleSettle(value, motion.Time)
		if cfg.OnGo then
			cfg.OnGo(value, kind)
		end
	end

	local function snap(value: string)
		if destroyed then
			return
		end
		cancelSettle()
		local target = anchorOf(cfg.Anchors(), value)
		if target ~= nil then
			set(target, nil)
		end
		if rec.Driver == driver then
			rec.Current:Set(value)
		end
	end

	driver = {
		HasAnchor = function(value: string): boolean
			return anchorOf(cfg.Anchors(), value) ~= nil
		end,
		Go = go,
		Snap = snap,
	}
	local detach = Anchored.attach(rec, driver, cfg.Who)

	local function relayout()
		if destroyed then
			return
		end
		local anchors = cfg.Anchors()
		if anchors == nil or #anchors == 0 then
			return
		end
		if dragging:Get() then
			local lo, hi = math.huge, -math.huge
			for _, a in anchors do
				lo = math.min(lo, a.Pos)
				hi = math.max(hi, a.Pos)
			end
			set(math.clamp(offset, lo, hi), nil)
			return
		end
		local target = anchorOf(anchors, rec.Target:Get())
		if target == nil then
			return
		end
		if settleThread ~= nil then
			-- a motion is under way: re-aim it at the moved anchor
			set(target, cfg.Motion(lastKind))
		else
			set(target, nil)
		end
	end

	-- the drag gesture (shared by every element that got a hook)
	local tracker = Anchored.tracker()
	local active = false
	local moved = false
	local movedUntil = -math.huge
	local startX, startY = 0, 0
	local lastX, lastY = 0, 0
	local startOffset = 0
	local isY = cfg.Axis == "Y"

	local function began(x: number, y: number)
		if active or destroyed or not cfg.CanDrag() then
			return
		end
		local anchors = cfg.Anchors()
		if anchors == nil or #anchors == 0 then
			return
		end
		active = true
		moved = false
		startX, startY = x, y
		lastX, lastY = x, y
		startOffset = offset
		tracker.Reset()
		tracker.Add(x, y)
	end

	local function movedTo(x: number, y: number)
		if not active then
			return
		end
		lastX, lastY = x, y
		tracker.Add(x, y)
		local delta = if isY then y - startY else x - startX
		if not moved then
			if math.abs(delta) < TOUCH_SLOP then
				return
			end
			moved = true
			cancelSettle()
			dragging:Set(true)
		end
		local anchors = cfg.Anchors()
		if anchors == nil or #anchors == 0 then
			return
		end
		local lo, hi = math.huge, -math.huge
		for _, a in anchors do
			lo = math.min(lo, a.Pos)
			hi = math.max(hi, a.Pos)
		end
		set(math.clamp(startOffset + delta, lo, hi), nil)
	end

	local function ended(x: number, y: number, cancelled: boolean)
		if not active then
			return
		end
		active = false
		if x ~= lastX or y ~= lastY then
			tracker.Add(x, y)
		end
		if not moved then
			return
		end
		moved = false
		movedUntil = Anchored.clock() + CLICK_SUPPRESS
		dragging:Set(false)
		local vx, vy = tracker.Velocity()
		if cancelled then
			vx, vy = 0, 0
		end
		local anchors = cfg.Anchors()
		if anchors == nil or #anchors == 0 then
			return
		end
		local velocity = if isY then vy else vx
		local cross = if isY then vx else vy
		local target = cfg.Release(anchors, offset, velocity, cross) or rec.Current:Get()
		if target ~= rec.Current:Get() and not Anchored.confirm(rec, target) then
			target = rec.Current:Get()
		end
		rec.Target:Set(target)
		go(target, "Settle")
	end

	local trackers: { Interaction.Drag } = {}
	local function hook(): Interaction.Hook
		local d = Interaction.drag({
			OnBegan = began,
			OnMoved = function(x: number, y: number)
				movedTo(x, y)
			end,
			OnEnded = ended,
			-- a sheet inside a scrolling page (the gallery's mock screens) must not scroll the page while it is dragged
			LockScroll = true,
		})
		table.insert(trackers, d)
		return d.Hook
	end

	local function destroy()
		if destroyed then
			return
		end
		destroyed = true
		cancelSettle()
		for _, d in trackers do
			d:Cancel()
		end
		active = false
		detach()
	end

	return {
		Pos = pos,
		Dragging = dragging,
		Hook = hook,
		Relayout = relayout,
		Moved = function(): boolean
			return moved or Anchored.clock() <= movedUntil
		end,
		Offset = function(): number
			return offset
		end,
		Detach = detach,
		Destroy = destroy,
	}
end

return { new = new }
