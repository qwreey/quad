--!strict
--[[
	ListReorder: drag-to-reorder for `ListData` (List.luau) — internal; the public surface is `ListData`'s `OnReorder`.

	    ListData({ Items = rows, Key = ..., Render = ..., OnReorder = function(from, to)
	        local list = table.clone(rows:Get())
	        table.insert(list, to, table.remove(list, from))      -- `to` is the place AFTER the move
	        rows:Set(list)                                        -- or: send (from, to) to the server, set `rows` on its answer
	    end })

	With `OnReorder` every row gets a drag handle at its end. Pressing the handle lifts the row; the row follows the pointer
	(vertically, kept inside the list) while the other rows give way; releasing calls `OnReorder(from, to)` when the place
	changed. THE LIST NEVER EDITS `Items`: the owner does (a server may decide the order). Until `Items` next changes the
	rows stay where they were dropped — for as long as the owner's `Reordering` State is true, else at most `HOLD`
	seconds; then they glide back. `Render` gets the row's `dragged` State as its third argument (give it to
	`ListItem`'s `Dragged`: the content takes the dragged colors).

	SOURCES (read 2026-10-13; m3.material.io/components/lists is script-rendered and returned no text — "site not compared")
	  Compose material3 has no reorderable list component. What it does have is the DRAGGED state of a list item:
	    androidx/androidx@b6bfe62 compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/
	      tokens/ReorderListTokens.kt 22-47   ItemContainerColor TertiaryContainer, ItemShape CornerLarge, every content
	                                         color OnTertiaryContainer, ItemDropZoneColor SurfaceContainerLow
	      tokens/ListTokens.kt 84-85         ItemDraggedContainerElevation = Level4
	      ListItemDefaults.kt 231-240, 518, 530-533   those tokens are the defaults of `draggedContainerColor`,
	                                         `draggedShape`, `elevation(draggedElevation)`
	      ListItem.kt 1505, 1575-1576, 1592  the elevation animates (MotionScheme FastSpatial) and a raised item gets zIndex 1
	  Behaviour:
	    androidx/androidx@b6bfe62 compose/foundation/foundation/integration-tests/foundation-demos/src/main/java/androidx/
	      compose/foundation/demos/LazyColumnDragAndDropDemo.kt
	        158-170   swap rule: the dragged item's MIDDLE inside another item's range
	        184-194   edge scroll: by how far the dragged item sticks out of the viewport, only in the drag direction
	        140-152   release / cancel: the item springs to its slot (spring StiffnessMediumLow); 232: the other items
	                  move with `animateItem` (foundation/lazy/LazyItemScope.kt 99-102: the same spring)
	        202-212   pick-up: `detectDragGesturesAfterLongPress` on the whole list (no handle)
	        66-68     it MOVES THE DATA on every swap (`onMove` during the drag)
	    androidx/androidx@b6bfe62 recyclerview/recyclerview/src/main/java/androidx/recyclerview/widget/
	      ItemTouchHelper.java 743-805, 2146-2168   edge scroll per frame: speed = max * ((r - 1)^5 + 1) * (t / 2000 ms)^5,
	                                         r = part of the view out of bounds, at least 1 px; only in the drag direction
	      res/values/dimens.xml 21           max = item_touch_helper_max_drag_scroll_per_frame 20dp
	      ItemTouchHelper.java 1643-1645     `isLongPressDragEnabled` (default: long press anywhere on the item), "you may
	                                         want to disable this if you want to start dragging on a custom view touch using
	                                         startDrag" — the handle form
	      ItemTouchHelper.java 1370, 2113-2121   the recover animation lasts the ItemAnimator's move duration (250 ms —
	                                         RecyclerView.java 14325 `mMoveDuration`), 200 ms without one
	      ItemTouchUIUtilImpl.java 44-51     the dragged view is raised above every other child
	  NOT FOUND: an M3 guideline text for reorder (site unreadable); the handle icon (`drag_handle` is the Material icon
	  the M3 list guidelines show — taken from memory of the page, not re-read); a material-components-android reorder
	  demo (catalog/java/io/material/catalog/listitem @60ff094 has swipe / expandable / segmented lists, no drag);
	  any keyboard / gamepad rule for reordering.

	WHAT THE KIT DOES WITH THEM
	  Lifted look     the row's `Lift` frame: TertiaryContainer fill, CornerLarge, elevation level 4 (tokens above), animated
	                  with Short4 / Standard like every kit elevation; the handle glyph turns OnTertiaryContainer (the
	                  trailing icon's dragged color). The CONTENT colors are the row's own business — the row is the
	                  caller's instance — so `Render(item, index, dragged)` hands the row its `dragged: State<boolean>`
	                  (lifted by the pointer OR engaged by a key) and `ListItem({ Dragged = dragged })` does the rest
	                  (List.luau: every content role OnTertiaryContainer; disabled > dragged > selected, as
	                  ListItemDefaults.kt 751-835). No drop-zone fill (ItemDropZoneColor): the gap is the affordance, as
	                  in both sources.
	  Pick-up         the HANDLE only, at once, mouse and touch (ItemTouchHelper's `startDrag` form). No long press on
	                  the row body: a press on a clickable row stops at the row's own GuiButton (Util.luau "INPUT RULE") and
	                  its click cannot be cancelled from outside the row.
	  Giving way      a row jumps to the SLOT WHOSE RESTING TOP IS NEAREST to the dragged row's top. With equal heights
	                  that is Compose's middle rule (half a row); with mixed heights the middle rule flips back and forth
	                  (after a swap the taller neighbour covers the middle again), the nearest-slot rule is a function of
	                  the position alone. The others tween (Medium1 0.25 s / Standard — the RecyclerView move duration).
	  Data            unlike the Compose demo nothing is moved during the drag: `OnReorder(from, to)` once, at release
	                  (`from ~= to`; `to` counts places after the move, so `table.insert(t, to, table.remove(t, from))`).
	  After release   the row settles into the gap and the list WAITS for `Items`: the next change of `Items` (inside the
	                  callback, or later — a server answer) re-seats every row from where it IS on screen to where the new
	                  order puts it, in the same frame as the LayoutOrder change (below), so nothing jumps. How long it
	                  waits (user decision 2026-10-13):
	                    * `Reordering: State<boolean>?` — the owner's "an answer is on its way". While it is true the
	                      rows wait, with no time limit. When it turns false and `Items` has not changed, the move was
	                      REFUSED: the rows glide back.
	                    * Without the prop, or while it has not been true since the release: `HOLD` (1 s — a kit choice,
	                      no source), then the rows glide back. `Reordering` is looked at when the callback returns AND
	                      whenever it changes during the wait, so an owner that raises it a moment after the callback
	                      (an async hop) still gets the unlimited wait; a `false` that was never preceded by a `true`
	                      since the release is not a refusal (a derived State may re-emit false) — only the HOLD ends
	                      that wait. Why not "false at return = refused at once": that would break the owner who raises
	                      it late, and an owner who wants an immediate refusal has the signal below.
	                    * Setting `Items` to the unchanged order is "refused" too: the rows glide back at once.
	                  No new drag (or key move) starts while waiting. A key move displaces nothing, so it only waits
	                  when `Reordering` is true after the callback (the answer then animates like a drop).
	  Cancel          Escape / gamepad B, window focus lost, the row or the list destroyed, `Items` changing mid-drag: back
	                  to the resting places, no callback.
	  Edge scroll     the nearest ancestor ScrollingFrame scrolls while the lifted row sticks out of its window in the drag
	                  direction — ItemTouchHelper's speed curve, one Heartbeat connection while a drag runs under a
	                  ScrollingFrame, none otherwise.
	  Keys            (kit convention, no source — KeyNav "Engage", like the color picker's SV area) the handle is a
	                  selection stop; ButtonA / Return engages it (the row looks lifted), Up / Down then call `OnReorder(i,
	                  i -+ 1)` at once, ButtonA / ButtonB / Return / Escape disengage. Unengaged, the D-pad walks on.
	                  A row moved by a key is scrolled into view when the new order arrives: the selection does not
	                  change, so the engine does not scroll for it (Studio 2026-10-13: two Up presses took the engaged
	                  row out of a 240 px ScrollingFrame's window).

	HOW (the engine constraints behind the shape)
	  * Rows are laid out by the List's UIListLayout (`LayoutOrder` = index), which ignores a child's Position. So every
	    row is a HOST Frame (the layout's child) holding a `Lift` Frame whose Position offset is what moves.
	      ReorderRow (Frame, LayoutOrder = index, ZIndex 2 while it is the moving row)
	        Lift (Frame: fill / UICorner / UIShadow of the lifted look, Position = the offset)
	          UIListLayout (horizontal) + UIPadding (8 at the end)
	          Body (Frame, UIFlexItem Fill)   <- the instance `Render` returned
	          DragHandle (GlyphButton 40: `Icons` "dragHandle")
	    Per row: 12 instances around the rendered one with the text glyph (host, Lift, UICorner, UIShadow, UIListLayout,
	    UIPadding, Body, UIFlexItem, handle + its state layer 3), 14 with an icon image.
	  * The host is AutomaticSize Y at rest (the engine sizes it from the row). AutomaticSize measures a child WHERE IT IS,
	    so a moved Lift would resize its host and push the rows below: for the length of a session (press .. settled) every
	    host is FROZEN to its measured height (`AbsoluteSize / UIScale product`, rounded) and thawed afterwards.
	  * Nothing here has a Scale Y under an automatic height (Ripple.luau "NOT SCALE"): the handle is centred by the Lift's
	    horizontal UIListLayout, not by a Scale position.
	  * Heights and places are MEASURED at press (`AbsolutePosition` / `AbsoluteSize` of the hosts relative to the list,
	    divided by `Ripple.localScale`) — one / two / three-line rows and rows with a divider may be mixed.
	  * Re-seating (the `Items` observer): for every row, `seen = old top + the Lift's offset right now` (read from the
	    instance, so a tween under way counts), `new top` = the heights stacked in the new order; the offset is snapped to
	    `seen - new top` and tweened to 0. The LayoutOrder writes (Slot:List) and these Position writes happen in one
	    synchronous wave, before the engine lays out — whichever runs first. A changed row SET (a key added / removed)
	    ends the session at once, offsets snapped to 0.
	  * The pointer is followed by DELTAS (`(y - y0) / scale`), and the list's own movement since the press (an edge
	    scroll moves it) is subtracted, read from its AbsolutePosition — no assumption about CanvasPosition units.
	  * Offsets are integers (UDim): under a fractional UIScale the frozen heights round, the rows may sit a pixel off
	    during a session.

	STUDIO (quad-test, Play Client, SignalBehavior Immediate, UIScale 1, 2026-10-13 — positions logged every frame from a
	RenderStep bound after `Last`): at the release frame every row is drawn where it was the frame before (0 px), with
	`Items` set in the callback, 0.1 s later (the dropped row mid-tween: 178 -> 177), 0.4 s and 2 s later; the thaw to
	automatic height moves nothing; the largest step of a giving-way row is one tween frame (18 px of 72). Edge scroll:
	`CanvasPosition` writes work while LockScroll holds `ScrollingEnabled` false, the row stays under the pointer (0 px)
	while the canvas runs, the canvas stops at its end and `ScrollingEnabled` comes back. A press on the handle does not
	click a clickable row. Enter / Down / Up / Enter on a selected handle: engaged look, one place per key, selection
	stays on the handle; unengaged Down walks to the next handle. Seen, not changed: a lifted row at the edge of a
	ScrollingFrame loses its shadow there (a UIShadow is cut by an ancestor's clip). NOT verified: touch (no touch input
	through the tooling), a UIScale other than 1, Deferred signals.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local Interaction = require("./Interaction")
local Input = require("./Input")
local KeyNav = require("./KeyNav")
local Overlay = require("./Overlay")
local Ripple = require("./Ripple")
local Elevation = require("./Elevation")
local GlyphButton = require("./GlyphButton")
local Icons = require("./Icons")
local Style = require("./Button/Style")
local Frame = q.Elem "Frame"
local UICorner = q.Elem "UICorner"
local UIFlexItem = q.Elem "UIFlexItem"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"

local RunService = game:GetService("RunService")

export type Config = {
	Items: q.State<{ any }>,
	Key: (item: any) -> string | number,
	Render: (item: q.State<any>, index: q.State<number>, dragged: q.State<boolean>) -> Instance,
	OnReorder: (from: number, to: number) -> (),
	Reordering: q.State<boolean>?,
	Gap: number?,
	Theme: Theme.Theme?,
}

export type Reorder = {
	-- the keyed row slot (the List host's content) and the array-part values the List host needs
	Slot: q.Slot<Instance>,
	Hooks: Util.Hooks,
}

-- seconds the dropped arrangement waits for `Items` before the rows go back (header "After release")
local HOLD = 1
local MOVE = Tokens.Motion.options("Medium1", "Standard")
local LIFT = Tokens.Motion.options("Short4", "Standard")
local LIFT_LEVEL = 4
local HANDLE = 40
local END_PADDING = 8 -- + the 8 px around the 24 px glyph in the 40 px handle = M3's 16 px trailing space
-- ItemTouchHelper: 20 dp per frame (a 60 Hz frame) at most, reached after 2 s out of bounds
local SCROLL_MAX = 20
local SCROLL_ACCEL = 2

type Pos = { Offset: number, Time: number }
type Phase = "Idle" | "Dragging" | "Pending" | "Settling"

type Row = {
	key: any,
	index: q.Source<number>,
	pos: q.Source<Pos>,
	frozen: q.Source<number>, -- the host's fixed height during a session, -1 = automatic
	held: q.Source<boolean>, -- lifted by a pointer
	engaged: q.Source<boolean>, -- lifted by ButtonA / Return (KeyNav "Engage")
	raised: q.Source<boolean>, -- drawn above the other rows
	lifted: q.State<boolean>, -- held or engaged: the lifted look, and what `Render` gets as `dragged`
	host: GuiObject?,
	lift: GuiObject?,
	tracker: Interaction.Drag?,
	-- the session's geometry, local units relative to the list host
	top: number,
	height: number,
	shift: number, -- the offset the Lift is at / heading to
	moved: boolean, -- its offset was written this session
}

type RowUD = { item: q.Source<any>, index: q.Source<number>, row: Row }
type RowCtx = {
	Item: any,
	Index: number,
	Offset: q.State<number>,
	Prev: q.SlotItem<Instance>?,
	UserData: RowUD?,
}

local function findScroller(inst: Instance): ScrollingFrame?
	local p: Instance? = inst.Parent
	while p ~= nil and p.ClassName ~= "ScrollingFrame" do
		p = p.Parent
	end
	return p :: ScrollingFrame?
end

local function new(cfg: Config): Reorder
	local theme = Theme.resolve(cfg.Theme)
	local gap = cfg.Gap or 0
	local rows: { [Row]: true } = {}
	local listHost: GuiObject? = nil
	local destroyed = false

	-- the session: from the press (or a key move) until every row rests where the layout puts it
	local phase: Phase = "Idle"
	local order: { Row } = {} -- the session's rows in layout order
	local slots: { number } = {} -- the dragged row's resting top at each place
	local dragged: Row? = nil
	local from, to = 0, 0
	local scale = 1
	local startY, lastY, startListY = 0, 0, 0
	local owner: Row? = nil -- the row whose press holds the gesture
	local timer: thread? = nil
	local escapeConn: RBXScriptConnection? = nil
	local stepConn: RBXScriptConnection? = nil
	local releaseHold: (() -> ())? = nil
	local reordering = cfg.Reordering
	local answerComing = false -- `Reordering` has been true since the release: its turning false is a refusal
	local reveal: Row? = nil -- the row a key moved: scrolled into view when the new order arrives
	local scroller: ScrollingFrame? = nil
	local scrollTime = 0

	local function cancelTimer()
		local th = timer
		if th ~= nil then
			timer = nil
			task.cancel(th)
		end
	end

	local function after(time: number, fn: () -> ())
		cancelTimer()
		local th: thread
		th = task.delay(time, function()
			if timer == th then
				timer = nil
			end
			fn()
		end)
		timer = th
	end

	local function setPos(row: Row, offset: number, time: number)
		row.shift = offset
		row.moved = true
		row.pos:Set({ Offset = offset, Time = time })
	end

	-- the Lift's offset on screen now (a tween under way is somewhere between its ends)
	local function offsetNow(row: Row): number
		local lift = row.lift
		if lift == nil then
			return 0
		end
		return lift.Position.Y.Offset
	end

	local function measure(): boolean
		local host = listHost
		if host == nil then
			return false
		end
		local k = Ripple.localScale(host)
		scale = if k > 0 then k else 1
		local list: { Row } = {}
		for row in rows do
			if row.host ~= nil then
				table.insert(list, row)
			end
		end
		table.sort(list, function(a: Row, b: Row): boolean
			return a.index:Get() < b.index:Get()
		end)
		local base = host.AbsolutePosition.Y
		for _, row in list do
			local h = row.host :: GuiObject
			row.top = (h.AbsolutePosition.Y - base) / scale
			row.height = h.AbsoluteSize.Y / scale
			row.shift = 0
			row.moved = false
		end
		order = list
		return #list > 0
	end

	local function freeze()
		for _, row in order do
			row.frozen:Set(math.round(row.height))
		end
	end

	-- end of a session: every row rests on its layout place, the hosts are automatic again
	local function finish()
		cancelTimer()
		phase = "Idle"
		reveal = nil
		local list = order
		local d = dragged
		order = {}
		dragged = nil
		for _, row in list do
			if row.moved then
				row.shift = 0
				row.moved = false
				row.pos:Set({ Offset = 0, Time = 0 })
			end
			row.frozen:Set(-1)
		end
		if d ~= nil then
			d.raised:Set(false)
		end
	end

	-- every displaced row glides to its layout place
	local function settle()
		cancelTimer()
		if destroyed then
			return
		end
		phase = "Settling"
		for _, row in order do
			if row.shift ~= 0 then
				setPos(row, 0, MOVE.Time)
			end
		end
		after(MOVE.Time, finish)
	end

	-- the wait after a release (phase "Pending"): armed with the HOLD timer; `Reordering` true makes it unlimited
	local function armWait()
		answerComing = false
		after(HOLD, settle)
	end
	local function lookAtReordering()
		local state = reordering
		if destroyed or phase ~= "Pending" or state == nil then
			return
		end
		if state:Get() then
			answerComing = true
			cancelTimer()
		elseif answerComing then
			answerComing = false
			settle() -- the answer came and `Items` is what it was: refused
		end
	end

	-- a row moved by a key keeps the selection, so the engine does not scroll to it: bring its new place into the
	-- nearest ScrollingFrame's window (`row.top` is already the place in the new order)
	local function show(row: Row)
		local host = listHost
		local sf = if host ~= nil then findScroller(host) else nil
		if host == nil or sf == nil then
			return
		end
		local top = host.AbsolutePosition.Y + row.top * scale
		local bottom = top + row.height * scale
		local windowTop = sf.AbsolutePosition.Y
		local windowBottom = windowTop + sf.AbsoluteWindowSize.Y
		local delta = 0
		if top < windowTop then
			delta = top - windowTop
		elseif bottom > windowBottom then
			delta = bottom - windowBottom
		end
		if delta ~= 0 then
			local canvas = sf.CanvasPosition
			local max = math.max(sf.AbsoluteCanvasSize.Y - sf.AbsoluteWindowSize.Y, 0)
			sf.CanvasPosition = Vector2.new(canvas.X, math.clamp(canvas.Y + delta, 0, max))
		end
	end

	local function targetOf(top: number): number
		local best = to
		local bestDistance = math.abs(top - slots[to])
		for place, slotTop in slots do
			local distance = math.abs(top - slotTop)
			if distance < bestDistance then
				best, bestDistance = place, distance
			end
		end
		return best
	end

	local function shiftOthers()
		local d = order[from]
		local step = d.height + gap
		for i, row in order do
			if i ~= from then
				local offset = 0
				if from < to and i > from and i <= to then
					offset = -step
				elseif to < from and i >= to and i < from then
					offset = step
				end
				if row.shift ~= offset then
					setPos(row, offset, MOVE.Time)
				end
			end
		end
	end

	-- the dragged row under the pointer (kept inside the list), the others out of its way
	local function place()
		local d, host = dragged, listHost
		if phase ~= "Dragging" or d == nil or host == nil then
			return
		end
		local last = order[#order]
		local lo = order[1].top - d.top
		local hi = last.top + last.height - (d.top + d.height)
		if lo > hi then
			lo, hi = 0, 0
		end
		-- the list's own movement since the press (an edge scroll) is taken back out: the row stays under the pointer
		local delta = math.clamp((lastY - startY) / scale - (host.AbsolutePosition.Y - startListY) / scale, lo, hi)
		if delta ~= d.shift or not d.moved then
			d.shift = delta
			d.moved = true
			d.pos:Set({ Offset = delta, Time = 0 })
		end
		local target = targetOf(d.top + delta)
		if target ~= to then
			to = target
			shiftOthers()
		end
	end

	-- ItemTouchHelper.scrollIfNecessary / interpolateOutOfBoundsScroll, once per frame while a drag runs in a ScrollingFrame
	local function step(dt: number)
		local d, host, sf = dragged, listHost, scroller
		if phase ~= "Dragging" or d == nil or host == nil or sf == nil then
			return
		end
		local top = host.AbsolutePosition.Y + (d.top + d.shift) * scale
		local bottom = top + d.height * scale
		local windowTop = sf.AbsolutePosition.Y
		local windowBottom = windowTop + sf.AbsoluteWindowSize.Y
		local travelled = lastY - startY
		local out = 0
		if travelled < 0 and top < windowTop then
			out = top - windowTop
		elseif travelled > 0 and bottom > windowBottom then
			out = bottom - windowBottom
		end
		if out == 0 then
			scrollTime = 0
		else
			scrollTime += dt
			local ratio = math.min(1, math.abs(out) / math.max(d.height * scale, 1))
			local cap = (ratio - 1) ^ 5 + 1
			local time = math.min(1, scrollTime / SCROLL_ACCEL)
			local amount = math.max(SCROLL_MAX * scale * cap * time ^ 5 * dt * 60, 1) * math.sign(out)
			local canvas = sf.CanvasPosition
			local max = math.max(sf.AbsoluteCanvasSize.Y - sf.AbsoluteWindowSize.Y, 0)
			local y = math.clamp(canvas.Y + amount, 0, max)
			if y ~= canvas.Y then
				sf.CanvasPosition = Vector2.new(canvas.X, y)
			end
		end
		place()
	end

	local function closeInput()
		local e = escapeConn
		if e ~= nil then
			escapeConn = nil
			e:Disconnect()
		end
		local s = stepConn
		if s ~= nil then
			stepConn = nil
			s:Disconnect()
		end
		scroller = nil
		local release = releaseHold
		if release ~= nil then
			releaseHold = nil
			if destroyed then
				release()
			else
				-- one frame later: the Escape that cancelled the drag must not also close a surrounding dialog
				task.defer(release)
			end
		end
	end

	local function cancelDrag()
		local d = dragged
		if phase ~= "Dragging" or d == nil then
			return
		end
		local tracker = d.tracker
		if tracker ~= nil then
			tracker:Cancel()
		end
	end

	local function began(row: Row, y: number): boolean
		if destroyed or phase == "Dragging" or phase == "Pending" then
			return false
		end
		if phase == "Settling" then
			finish()
		end
		local host = listHost
		if host == nil or not measure() then
			return false
		end
		local at = table.find(order, row)
		if at == nil then
			order = {}
			return false
		end
		phase = "Dragging"
		dragged = row
		from, to = at, at
		startY, lastY = y, y
		startListY = host.AbsolutePosition.Y
		-- where the row would rest at each place: above it the others' own tops, below it their bottoms less its height
		slots = table.create(#order, 0)
		for i, other in order do
			slots[i] = if i > at then other.top + other.height - row.height else other.top
		end
		freeze()
		row.raised:Set(true)
		row.held:Set(true)
		releaseHold = Overlay.holdDismiss()
		escapeConn = Input.service().InputBegan:Connect(function(input: InputObject)
			local kc = input.KeyCode
			if kc == Enum.KeyCode.Escape or kc == Enum.KeyCode.ButtonB then
				cancelDrag()
			end
		end)
		scroller = findScroller(host)
		scrollTime = 0
		if scroller ~= nil then
			stepConn = RunService.Heartbeat:Connect(step)
		end
		return true
	end

	local function ended(row: Row, cancelled: boolean)
		if phase ~= "Dragging" or dragged ~= row then
			return
		end
		closeInput()
		row.held:Set(false)
		if destroyed then
			phase = "Idle"
			return
		end
		if cancelled or to == from then
			settle()
			return
		end
		-- dropped on another place: the row settles into the gap and the arrangement waits for `Items`
		phase = "Pending"
		setPos(row, slots[to] - row.top, MOVE.Time)
		-- armed BEFORE the callback: a callback that throws still lets the rows go back
		armWait()
		cfg.OnReorder(from, to)
		lookAtReordering()
	end

	-- `Items` changed (the Observer below): the session's rows move from where they are to where the new order puts them
	local function onItems()
		if destroyed or phase == "Idle" then
			return
		end
		cancelDrag()
		if phase == "Dragging" then
			local d = dragged
			if d ~= nil then
				ended(d, true)
			end
		end
		if phase == "Idle" then
			return
		end
		local items = cfg.Items:Get()
		local n = #order
		if #items ~= n then
			finish()
			return
		end
		local placeOf: { [any]: number } = {}
		for i, item in items do
			placeOf[cfg.Key(item)] = i
		end
		local next: { Row } = {}
		for _, row in order do
			local i = placeOf[row.key]
			if i == nil or next[i] ~= nil then
				finish()
				return
			end
			next[i] = row
		end
		local y = order[1].top
		for _, row in next do
			local seen = row.top + offsetNow(row)
			row.top = y
			y += row.height + gap
			local offset = seen - row.top
			if math.abs(offset) >= 0.5 then
				row.shift = offset
				row.moved = true
				row.pos:Set({ Offset = offset, Time = 0 })
				setPos(row, 0, MOVE.Time)
			elseif row.moved then
				row.shift = 0
				row.pos:Set({ Offset = 0, Time = 0 })
			end
		end
		order = next
		from, to = 0, 0
		phase = "Settling"
		after(MOVE.Time, finish)
		local moved = reveal
		if moved ~= nil then
			reveal = nil
			show(moved)
		end
	end

	-- a session that can no longer be trusted (a row appeared or left): end it where the layout is
	local function abort()
		if phase == "Idle" then
			return
		end
		cancelDrag()
		if phase == "Dragging" then
			closeInput()
			local d = dragged
			if d ~= nil then
				d.held:Set(false)
			end
		end
		owner = nil
		finish()
	end

	-- one place up / down from the engaged handle; an `Items` change inside the callback animates like a drop
	local function keyMove(row: Row, direction: number)
		if destroyed or phase == "Dragging" or phase == "Pending" then
			return
		end
		local i = row.index:Get()
		local j = i + direction
		if j < 1 or j > #cfg.Items:Get() then
			return
		end
		if phase == "Settling" then
			finish()
		end
		if measure() then
			freeze()
			dragged = row
			reveal = row
			row.raised:Set(true)
			phase = "Pending"
			armWait()
		end
		cfg.OnReorder(i, j)
		lookAtReordering()
		if phase == "Pending" and not answerComing then
			finish() -- nothing is displaced, so there is nothing to wait in: a later `Items` change just re-seats the rows
		end
	end

	local function destroy()
		if destroyed then
			return
		end
		destroyed = true
		cancelTimer()
		cancelDrag()
		closeInput()
		phase = "Idle"
		order = {}
		dragged = nil
		owner = nil
	end

	local function newRow(key: any, index: q.Source<number>): Row
		local held = q.Source(false)
		local engaged = q.Source(false)
		local lifted: q.State<boolean> = held:Compute(function(self, _prev, e)
			return self:Get() or e:Get()
		end, engaged)
		return {
			key = key,
			index = index,
			pos = q.Source({ Offset = 0, Time = 0 } :: Pos),
			frozen = q.Source(-1),
			held = held,
			engaged = engaged,
			raised = q.Source(false),
			lifted = lifted,
			host = nil,
			lift = nil,
			tracker = nil,
			top = 0,
			height = 0,
			shift = 0,
			moved = false,
		}
	end

	-- the host around the row `Render` returned (header "HOW")
	local function wrap(row: Row, content: Instance): Instance
		local tracker = Interaction.drag({
			OnBegan = function(_x: number, y: number)
				if owner == nil and began(row, y) then
					owner = row
				end
			end,
			OnMoved = function(_x: number, y: number)
				if owner == row then
					lastY = y
					place()
				end
			end,
			OnEnded = function(_x: number, _y: number, cancelled: boolean)
				if owner == row then
					owner = nil
					ended(row, cancelled)
				end
			end,
			-- a list inside a ScrollingFrame must not also be scrolled by the finger that drags a row
			LockScroll = true,
		})
		row.tracker = tracker
		local keys = KeyNav.hook(function(input: InputObject)
			local kc = input.KeyCode
			if kc == Enum.KeyCode.Up or kc == Enum.KeyCode.DPadUp then
				keyMove(row, -1)
			elseif kc == Enum.KeyCode.Down or kc == Enum.KeyCode.DPadDown then
				keyMove(row, 1)
			end
		end, nil, { Pin = "Engage", Engaged = row.engaged })

		local lifted = row.lifted
		local level: q.State<number> = lifted:Compute(function(self)
			return if self:Get() then LIFT_LEVEL else 0
		end)
		local fill: q.State<number> = lifted:Compute(function(self)
			return if self:Get() then 0 else 1
		end)
		local corner: q.State<UDim> = lifted:Compute(function(self)
			return if self:Get() then Tokens.Shape.corner("Large") else UDim.new(0, 0)
		end)
		local position: q.State<any> = row.pos:Compute(function(self)
			local p = self:Get()
			return q.Tween({
				Value = UDim2.fromOffset(0, p.Offset),
				Time = p.Time,
				Style = MOVE.Style,
				Direction = MOVE.Direction,
				-- a snap must land even on the recorded target (it ends a tween under way)
				Dedup = p.Time > 0,
			})
		end)
		local size: q.State<UDim2> = row.frozen:Compute(function(self)
			return UDim2.new(1, 0, 0, math.max(self:Get(), 0))
		end)
		local automatic: q.State<Enum.AutomaticSize> = row.frozen:Compute(function(self)
			return if self:Get() < 0 then Enum.AutomaticSize.Y else Enum.AutomaticSize.None
		end)
		-- above the other rows while it moves (a session) and while it is lifted (engaged by a key: its shadow)
		local zIndex: q.State<number> = row.raised:Compute(function(self, _prev, l)
			return if self:Get() or l:Get() then 2 else 1
		end, lifted)

		local asset = Icons.asset("dragHandle")
		-- the trailing icon of a dragged item is OnTertiaryContainer (ReorderListTokens.ItemTrailingIconColor)
		local glyphColor = Style.animated(Style.choose(lifted, theme.Raw.OnTertiaryContainer, theme.Raw.OnSurfaceVariant))
		local handle = GlyphButton.new({
			Name = "DragHandle",
			Asset = asset,
			Color = glyphColor,
			Glyph = Icons.glyph("dragHandle"),
			Size = HANDLE,
			TextSize = 24,
			LayoutOrder = 2,
			Theme = theme,
			OnClick = function() end,
			Hooks = { tracker.Hook, keys },
		})

		local host = Frame {
			Name = "ReorderRow",
			Size = size,
			AutomaticSize = automatic,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = row.index,
			ZIndex = zIndex,
			Util.preHook(function(inst: GuiObject)
				row.host = inst
			end),
			Frame {
				Name = "Lift",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Position = position,
				BackgroundColor3 = theme.Color.TertiaryContainer,
				BackgroundTransparency = fill:Apply(q.Animate(LIFT)),
				BorderSizePixel = 0,
				Util.preHook(function(inst: GuiObject)
					row.lift = inst
				end),
				UICorner { CornerRadius = corner:Apply(q.Animate(LIFT)) },
				Elevation.Shadow({ Level = level, Theme = theme }),
				UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				},
				UIPadding { PaddingRight = UDim.new(0, END_PADDING) },
				Frame {
					Name = "Body",
					Size = UDim2.fromScale(0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					LayoutOrder = 1,
					UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
					content,
				},
				handle,
			},
		}
		return host
	end

	local slot = q.Slot<<Instance>>()
	slot:List(cfg.Items, function(ctx: RowCtx): (any, RowUD?)
		local ud = ctx.UserData
		if ctx.Item == q.KeyGone then
			if ud ~= nil then
				rows[ud.row] = nil
				abort()
			end
			return nil, ud
		end
		local prev = ctx.Prev
		if prev and ud then
			ud.item:SetIfChanged(ctx.Item)
			ud.index:SetIfChanged(ctx.Index)
			return prev, ud
		end
		abort()
		local item = q.Source(ctx.Item)
		local index = q.Source(ctx.Index)
		local row = newRow(cfg.Key(ctx.Item), index)
		local host = wrap(row, cfg.Render(item, index, row.lifted))
		rows[row] = true
		return host, { item = item, index = index, row = row }
	end, function(item: any): any
		return cfg.Key(item)
	end)

	local hooks: Util.Hooks = {
		Util.preHook(function(inst: GuiObject)
			listHost = inst
			inst.Destroying:Connect(destroy)
		end),
		cfg.Items:Observer(function()
			onItems()
		end),
	}
	if reordering ~= nil then
		table.insert(
			hooks,
			reordering:Observer(function()
				lookAtReordering()
			end)
		)
	end

	return { Slot = slot, Hooks = hooks }
end

return { new = new, HOLD = HOLD }
