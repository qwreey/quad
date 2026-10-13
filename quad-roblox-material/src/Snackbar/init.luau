--!strict
--[[
	M3 snackbar: a short message at the bottom center, one at a time, the rest queued.

	    local bar = Snackbar.new({ Overlay = overlay })                     -- a host bound to an Overlay (default: Overlay.default())
	    local top = Snackbar.new({ Overlay = overlay, Position = "Top" })   -- the same host, placed at the top center
	    local item = bar:Show({ Text = "Message archived", Action = { Label = "Undo", OnClick = undo }, Duration = 6, Close = true })
	    item.Close()                                                       -- manual dismiss (queued items just leave the queue)
	    Snackbar.show({ Text = "Saved" })                                  -- the shared default host (lazy; rebuilt when its overlay died)
	    bar:Destroy()                                                      -- closes the current one, drops the queue, cancels timers

	ShowOptions (all `read`):
	  Text      string                                 the message
	  Action    { Label: string, OnClick: () -> () }?  one text action (inversePrimary); click runs OnClick, then dismisses
	  Close     boolean?                               a trailing close button (the `Icons` close image — Material close;
	                                                   the text glyph when it is overridden away)
	  Duration  (number | State<number>)?              seconds visible, default 4 (10 when there is an Action — M3: a
	                                                   snackbar with an action must stay long enough to be reached); read
	                                                   when the item becomes visible; math.huge = until dismissed. The
	                                                   countdown PAUSES while the pointer is over the snackbar or one of
	                                                   its buttons holds gamepad/keyboard selection, and resumes with the
	                                                   remaining time
	  OnDismiss ((reason: DismissReason) -> ())?       once, when the item starts leaving (or leaves the queue):
	                                                   "Timeout" | "Action" | "Close" | "Manual" | "Destroyed"
	  Width     number?                                default 344 (M3)
	Host options: Overlay (default `Overlay.default()`), Theme, Position ("Bottom" | "Top", default "Bottom"), Offset
	                    (default 16: the gap between the snackbar and the edge it sits at — the layer's bottom edge, or its
	                    top edge with Position = "Top"; named `BottomOffset` until 2026-10-13), Clock (() -> seconds, default `os.clock`:
	                    only used to measure how much of a paused countdown is left; inject one to replay/test with a virtual clock).
	POSITION (user decision 2026-10-13): M3 shows the snackbar at the bottom, but where it sits is the caller's in canon —
	Compose's Snackbar is drawn wherever its `SnackbarHost` composable is placed (androidx/androidx@40ff481 compose/
	material3/.../SnackbarHost.kt 215-239: the host takes a `modifier` and draws its current snackbar in place; Scaffold.kt
	246-254 is what puts a Scaffold's host at the bottom) — so a host may be placed at the top: Position = "Top" is the "Bottom" host
	mirrored (same width, same gap, same times; it slides DOWN into place — View.luau). Still one at a time with the rest
	queued, per host: stacking several is not a snackbar. Two hosts on one Overlay (a bottom and a top one) are two queues.
	The top gap is measured from the LAYER's top: under a ScreenGui with the default insets that is below the Roblox top bar
	(`IgnoreGuiInset = false` / ScreenInsets CoreUISafeInsets); with the inset ignored the snackbar is under the top bar's
	icons — raise Offset. `Scaffold` is not adapted: it places its SnackbarHost layer for the bottom (above the FAB /
	bottom bar) and that layer starts at the scaffold's top, so a "Top" host in it draws over the top app bar.
	Item (the kit-wide handle shape — closures WITHOUT self): Close(result?) (the result is ignored: a snackbar has none;
	`Dismiss()` is an alias), IsOpen State<boolean> (queued or on screen; false once dismissed), Visible State<boolean>
	(currently on screen, including the exit), Done State<boolean> (the inverse of IsOpen).
	Host: :Show, :Destroy, Pending State<number> (queued, not yet visible).

	Files: this file = the queue (one visible item, the rest waiting), the timers and the Overlay handle; `View.luau` = the
	card (CanvasGroup, message, action, close `GlyphButton`; see its header for the structure, motion and touch targets).
	The next queued item opens after the previous one is destroyed (observed through the overlay handle Closing State),
	never on top of it.
	Timers: ONE task.delay per visible item with a finite Duration (re-armed with the remaining time after a hover/selection
	pause, measured with the host `Clock`, default os.clock); it is cancelled on any dismiss, on Destroy and when the item instance is destroyed.
	Layer death: the host is bound to its Overlay layer. When that layer is destroyed the Overlay finalizes the visible item's
	handle (OnClose "Destroyed"): the item reports "Destroyed", Visible goes false, nothing stays current, queued items are
	dropped ("Destroyed") and `Show` on that host errors loudly (build a new host; `Snackbar.default()` does that itself).
	CanvasGroup lifetime: the group (needed for the fade) stays a CanvasGroup for the snackbar's whole life — an offscreen
	texture composited every frame while it is up. Fine for one short-lived snackbar; swapping to a plain Frame once the enter
	animation ends is possible but not done (it would also lose the exit fade).
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Util = require("./Util")
local Overlay = require("./Overlay")
local View = require("@self/View")

export type DismissReason = "Timeout" | "Action" | "Close" | "Manual" | "Destroyed"

export type Action = View.Action

export type ShowOptions = {
	read Text: string,
	read Action: Action?,
	read Close: boolean?,
	read Duration: (number | q.State<number>)?,
	read OnDismiss: ((reason: DismissReason) -> ())?,
	read Width: number?,
}

export type Item = {
	Close: (result: unknown?) -> (),
	Dismiss: () -> (),
	read IsOpen: q.State<boolean>,
	read Visible: q.State<boolean>,
	read Done: q.State<boolean>,
}

export type Position = View.Position

export type Options = {
	Overlay: Overlay.Overlay?,
	Theme: Theme.Theme?,
	Position: Position?,
	Offset: number?,
	Clock: (() -> number)?,
}

export type Host = {
	read Pending: q.State<number>,
	Show: (self: Host, opts: ShowOptions) -> Item,
	Destroy: (self: Host) -> (),
}

type Entry = {
	Opts: ShowOptions,
	Phase: "Queued" | "Shown" | "Done",
	Handle: Overlay.Handle?,
	Timer: thread?,
	Watch: q.Observer?,
	Visible: q.Source<boolean>,
	Done: q.Source<boolean>,
	Reason: DismissReason?,
	Hover: boolean,
	Focus: number,
	Remaining: number?,
	StartedAt: number,
}

local function new(o: Options?): Host
	local opts: Options = o or {}
	local overlay = opts.Overlay or Overlay.default()
	local theme = Theme.resolve(opts.Theme)
	local offset = opts.Offset or 16
	local place: Position = opts.Position or "Bottom"
	if place ~= "Bottom" and place ~= "Top" then
		error(`Snackbar.new: Position must be "Bottom" or "Top" (got {tostring(place)})`, 2)
	end
	local clock: () -> number = opts.Clock or os.clock

	local queue: { Entry } = {}
	local current: Entry? = nil
	local destroyed = false
	local pending = q.Source(0)

	local function setPending()
		pending:Set(#queue)
	end

	local function cancelTimer(e: Entry)
		local t = e.Timer
		if t ~= nil then
			e.Timer = nil
			task.cancel(t)
		end
	end

	local dismiss: (e: Entry, reason: DismissReason) -> ()

	local function startTimer(e: Entry)
		local rem = e.Remaining
		if rem == nil or rem >= math.huge or e.Phase ~= "Shown" or e.Timer ~= nil then
			return
		end
		e.StartedAt = clock()
		e.Timer = task.delay(rem, function()
			e.Timer = nil
			dismiss(e, "Timeout")
		end)
	end

	-- pause the countdown while the pointer is over the card or a button holds selection; resume with what is left
	local function refreshHold(e: Entry)
		if e.Phase ~= "Shown" then
			return
		end
		if e.Hover or e.Focus > 0 then
			if e.Timer ~= nil then
				local rem = e.Remaining
				if rem ~= nil then
					e.Remaining = math.max(0, rem - (clock() - e.StartedAt))
				end
				cancelTimer(e)
			end
		else
			startTimer(e)
		end
	end

	local function unwatch(e: Entry)
		local w = e.Watch
		if w ~= nil then
			e.Watch = nil
			w:Unsubscribe()
		end
	end

	local function finish(e: Entry, reason: DismissReason)
		if e.Phase == "Done" then
			return
		end
		e.Phase = "Done"
		e.Reason = reason
		cancelTimer(e)
		e.Done:Set(true)
		local cb = e.Opts.OnDismiss
		if cb then
			cb(reason)
		end
	end

	local showNext: () -> ()

	local function dropQueue()
		local waiting = queue
		queue = {}
		setPending()
		for _, w in waiting do
			finish(w, "Destroyed")
		end
	end

	dismiss = function(e: Entry, reason: DismissReason)
		if e.Phase == "Queued" then
			local i = table.find(queue, e)
			if i ~= nil then
				table.remove(queue, i)
				setPending()
			end
			finish(e, reason)
		elseif e.Phase == "Shown" then
			-- finish() runs from the overlay OnClose (start of closing); remember the reason first
			e.Reason = reason
			cancelTimer(e)
			local h = e.Handle
			if h ~= nil then
				h.Close()
			end
		end
	end

	local function build(e: Entry, h: Overlay.Handle): Instance
		return View.build({
			Text = e.Opts.Text,
			Action = e.Opts.Action,
			Close = e.Opts.Close,
			Width = e.Opts.Width,
			Theme = theme,
			Position = place,
			Offset = offset,
			Closing = h.Closing,
			OnHover = function(over: boolean)
				e.Hover = over
				refreshHold(e)
			end,
			OnFocus = function(delta: number)
				e.Focus = math.max(0, e.Focus + delta)
				refreshHold(e)
			end,
			OnAction = function()
				dismiss(e, "Action")
			end,
			OnClose = function()
				dismiss(e, "Close")
			end,
			OnDestroyed = function()
				-- the item dying without a dismiss (overlay layer destroyed): no timer, no observer, no stuck host
				cancelTimer(e)
				if e.Phase == "Done" then
					-- normal removal after a dismiss: the Closing observer is about to fire and opens the next item;
					-- if it never does (the layer died during the exit) the deferred unwatch drops it
					task.defer(function()
						unwatch(e)
					end)
					return
				end
				unwatch(e)
				if current == e then
					current = nil
				end
				finish(e, "Destroyed")
			end,
		})
	end

	local function display(e: Entry)
		e.Phase = "Shown"
		local seenClosing = false
		local handle = overlay:Open({
			Content = function(h: Overlay.Handle): Instance
				e.Handle = h
				return build(e, h)
			end,
			OnClose = function(closeReason: Overlay.CloseReason)
				-- the item starts leaving: report why (a Timeout/Manual dismiss recorded it already)
				local reason: DismissReason = e.Reason or (if closeReason == "Destroyed" then "Destroyed" else "Manual")
				finish(e, reason)
				if closeReason == "Destroyed" then
					-- the layer died under the item: no exit phase will ever run, so release the host right here
					unwatch(e)
					e.Visible:Set(false)
					if current == e then
						current = nil
					end
					task.defer(showNext)
				end
			end,
		})
		e.Handle = handle
		e.Visible:Set(true)
		-- when the overlay has removed the item (Closing goes true -> false), open the next one
		local watch = handle.Closing:Observer(function(target)
			if target:Get() then
				seenClosing = true
			elseif seenClosing then
				seenClosing = false
				unwatch(e)
				e.Visible:Set(false)
				if current == e then
					current = nil
				end
				task.defer(showNext)
			end
		end)
		e.Watch = watch
		watch:Subscribe()

		local d = e.Opts.Duration
		local seconds = if e.Opts.Action ~= nil then 10 else 4
		if type(d) == "number" then
			seconds = d
		elseif d ~= nil then
			seconds = d:Get()
		end
		e.Remaining = seconds
		if not (e.Hover or e.Focus > 0) then
			startTimer(e)
		end
	end

	showNext = function()
		if destroyed or current ~= nil then
			return
		end
		if not overlay.Alive:Get() then
			dropQueue() -- the layer is gone: nothing can be shown any more
			return
		end
		local e = table.remove(queue, 1)
		if e == nil then
			return
		end
		setPending()
		current = e
		display(e)
	end

	local host: Host
	host = {
		Pending = pending,
		Show = function(_self: Host, so: ShowOptions): Item
			if destroyed then
				error("Snackbar:Show: the host was destroyed", 2)
			end
			if not overlay.Alive:Get() then
				error("Snackbar:Show: the host's overlay layer was destroyed — build a new host (Snackbar.default() does)", 2)
			end
			local e: Entry = {
				Opts = so,
				Phase = "Queued",
				Visible = q.Source(false),
				Done = q.Source(false),
				Hover = false,
				Focus = 0,
				StartedAt = 0,
			}
			table.insert(queue, e)
			setPending()
			showNext()
			local function close(_result: unknown?)
				dismiss(e, "Manual")
			end
			return {
				Close = close,
				Dismiss = function()
					dismiss(e, "Manual")
				end,
				IsOpen = Util.negate(e.Done),
				Visible = e.Visible,
				Done = e.Done,
			}
		end,
		Destroy = function(_self: Host)
			if destroyed then
				return
			end
			destroyed = true
			dropQueue()
			local cur = current
			if cur ~= nil then
				cancelTimer(cur)
				unwatch(cur)
				cur.Reason = "Destroyed"
				local h = cur.Handle
				if h ~= nil then
					h.Close()
				end
				cur.Visible:Set(false)
			end
			current = nil
		end,
	}
	return host
end

local defaultHost: Host? = nil
local defaultHostOverlay: Overlay.Overlay? = nil

-- The shared host follows `Overlay.default()`: when that overlay was rebuilt (its layer died) the old host is destroyed
-- and a fresh one bound to the new overlay takes its place.
local function default(): Host
	local ov = Overlay.default()
	local h = defaultHost
	if h == nil or defaultHostOverlay ~= ov then
		if h ~= nil then
			h:Destroy()
		end
		h = new({ Overlay = ov })
		defaultHost = h
		defaultHostOverlay = ov
	end
	return h :: Host
end

local function show(opts: ShowOptions): Item
	return default():Show(opts)
end

return {
	new = new,
	default = default,
	show = show,
}
