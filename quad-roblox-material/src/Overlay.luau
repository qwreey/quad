--!strict
--[[
	Overlay: one layer for everything that floats above the app — menus, dialogs, snackbars, tooltips.
	Follows docs/how-to/09 ("떠 있는 것 열고 닫기"): the layer is a screen-root Frame with a Slot; anything deep in
	the tree opens something by holding the `Overlay` (or calling `Overlay.default()`), and each opened thing
	is a fresh element added to the Slot and removed (destroyed) when closed.

	    -- app root, once:
	    local overlay = Overlay.new()                    -- or Overlay.default()
	    local screen = D.ScreenGui { ResetOnSpawn = false, DisplayOrder = 10, App(), overlay.Layer }
	    -- anywhere:
	    local handle = overlay:Open({
	        Content = function(h) return MyDialog({ OnDone = function() h.Close() end }) end,  -- or an Instance
	        Scrim = true,                                -- dim + block the app behind (M3 scrim @ 0.32)
	        Dismissable = true,                          -- click on the scrim closes (default true with Scrim)
	        DismissOnEscape = true,                      -- Escape / gamepad B closes the top-most such entry
	        TrapSelection = true,                        -- gamepad selection stays inside while open
	        OnClose = function(reason) ... end,
	    })
	    handle.Close()                                   -- idempotent, closures without self

	Overlay.new(opts) -> Overlay             opts.Theme (scrim color), opts.ZIndex (layer, default 100)
	Overlay.default() -> Overlay             the shared default overlay, built LAZILY and SELF-HEALING: when its layer
	                                         was destroyed (the ScreenGui it was mounted in died) the next call builds a
	                                         fresh one, so a long-lived singleton can never go stale. Death is detected
	                                         SYNCHRONOUSLY (a layer that was mounted and now has no Parent counts as dead
	                                         at once), so `oldGui:Destroy(); buildUi()` in one frame gets a fresh overlay
	                                         even under Deferred signals, where `Destroying` handlers run later. Mount
	                                         `Overlay.default().Layer` once at the app root (call it again after a
	                                         ScreenGui rebuild and mount the new layer). Components fall back to it when
	                                         no `Overlay` is passed. There is NO eager instance: requiring the module
	                                         builds nothing.
	  .Layer   Frame        full-screen, transparent, NOT input-sinking by itself (clicks pass through to the
	                        app while nothing with a scrim is open). Mount it as the LAST child of a ScreenGui
	                        with a high `DisplayOrder`, or as the last sibling of the app root.
	  .Count   State<number>  how many things are currently open (closing ones included until removed)
	  .Alive   State<boolean> false once the layer was destroyed; an overlay never revives
	  :Open(opts) -> Handle   ERRORS (loudly) when the overlay is not alive — a dead layer cannot show anything, and a
	                          silent no-op would look like "my dialog never appears"
	      opts.Content      Instance | (handle: Handle) -> Instance  — the thing to show. A builder gets the
	                        handle so the content can close itself; an Instance must be a fresh element
	                        (it is seated in the overlay and destroyed on close)
	      opts.Scrim        boolean   default false. The scrim is a button but NOT `Selectable` (a gamepad never lands on it)
	      opts.ScrimOpacity number    default 0.32 (M3 scrim)
	      opts.Dismissable  boolean   click on the scrim closes it (default = Scrim)
	      opts.DismissOnEscape boolean  default false. Escape / gamepad B closes the TOP-MOST entry that is modal (has a
	                        Scrim) or has this flag; if that entry did not ask for it, Escape does nothing (a
	                        non-dismissable modal on top shields a dismissable one below). ONE shared
	                        `UserInputService.InputBegan` connection (via `Input.service()`) serves every overlay and exists only while such an
	                        entry is open. Escape is ignored when the engine already processed the key or a TextBox
	                        has focus (typing must not dismiss); ButtonB is always honored.
	      opts.OnEscape     (() -> ())?  with `DismissOnEscape`: Escape / gamepad B on this entry (when it is the top-most) calls this
	                        INSTEAD of closing it — the entry decides (a modal bottom sheet steps back from Expanded to
	                        PartiallyExpanded first, Compose ModalBottomSheet's back handler; it closes the handle itself
	                        when it is done). The entry keeps its place in the Escape stack, so it still shields entries below.
	      opts.TrapSelection boolean  default false. While open the gamepad selection is confined to the entry: the entry
	                        frame is a `SelectionGroup` whose `SelectionBehaviorUp/Down/Left/Right` are `Stop` (the
	                        current mechanism; `GuiService:AddSelectionParent` is deprecated), the group is released when the
	                        entry starts closing, and the previously selected object is restored then (if it is still alive).
	      opts.InitialSelection GuiObject | () -> GuiObject?  moved to on open when the LAST input was a gamepad (`GetLastInputType`) (a function is
	                        called right after the entry is mounted — use it for content the builder creates)
	      opts.ExitTime     number    seconds the closing phase lasts before the content is destroyed
	                        (default 0.2 = Motion Short4). Content may animate out while `handle.Closing` is
	                        true; the scrim fades over the same time. 0 = destroy immediately. The content stays
	                        MOUNTED AND CLICKABLE for that time (the overlay does not block it): a handler in the
	                        content that must not run for a second tap, or after a dismissal, checks
	                        `handle.IsOpen:Get()` first — the kit's own menus, dialogs, pickers and snackbars do.
	      opts.OnClose      (reason: CloseReason, result: unknown?) -> ()  called once, at the start of closing (the very last
	                        step: state is consistent even if it throws). reason = "Close" (handle.Close) | "Scrim" |
	                        "Escape" | "Destroyed" (the layer died: nothing animates, the handle is finalized on the spot);
	                        result = what `handle.Close(result)` was given (nil for every other reason)
	  Handle (the kit-wide handle shape — closures WITHOUT self, so `handle.Close(x)`): .IsOpen State<boolean> (false from
	          the first `Close`), .Closing State<boolean> (true from `Close` until the content is destroyed),
	          .Close(result?) (idempotent; the first call wins)
	  Layer death (its `Destroying`, or already at `Open`/close time once a mounted layer lost its Parent) finalizes EVERY live handle: IsOpen false, Closing false, Count 0, OnClose once with "Destroyed",
	  exit timers cancelled, its Escape / selection registrations dropped.

	Overlay.holdDismiss() -> release   suppress Escape/B dismissal until `release()` runs (idempotent). For a child that
	                        uses B itself (the color picker's engaged SV area).
Overlay.onEscape(fn) -> release    put an IN-TREE consumer of Escape / gamepad B on the same shared stack the entries use
	                        (top-most wins): while registered, Escape / B calls `fn` when nothing opened later sits above it,
	                        and a dialog opened on top of it gets the key first. For things that are not overlay entries but
	                        close on Escape — the modal / dismissible navigation drawers (Compose closes them on Escape).
	                        `release()` is idempotent.

	Open animation (docs/how-to/09): the scrim mounts fully transparent and fades in from its own PostRef —
	the first property write snaps, the second one tweens. Content is expected to do the same with
	`handle`-independent hooks (`Util.postHook`) if it wants an enter motion; the overlay does not wrap or
	transform content.

	Not here: stacking rules beyond "every Open is a separate entry; later entries draw above earlier ones".
]]

local q = require("./Quad")
local Tokens = require("./Tokens")
local Theme = require("./Theme")
local Util = require("./Util")
local D = q.Declaration

local Input = require("./Input")
local GuiService = game:GetService("GuiService")

export type CloseReason = "Close" | "Scrim" | "Escape" | "Destroyed"

export type OnCloseFn = (reason: CloseReason, result: unknown?) -> ()

export type Handle = {
	read IsOpen: q.State<boolean>,
	read Closing: q.State<boolean>,
	Close: (result: unknown?) -> (),
}

export type OpenOptions = {
	Content: Instance | (handle: Handle) -> Instance,
	Scrim: boolean?,
	ScrimOpacity: number?,
	Dismissable: boolean?,
	DismissOnEscape: boolean?,
	TrapSelection: boolean?,
	InitialSelection: (GuiObject | () -> GuiObject?)?,
	OnEscape: (() -> ())?,
	ExitTime: number?,
	OnClose: OnCloseFn?,
}

export type Options = { Theme: Theme.Theme?, ZIndex: number? }

export type Overlay = {
	read Layer: Frame,
	read Count: q.State<number>,
	read Alive: q.State<boolean>,
	Open: (self: Overlay, opts: OpenOptions) -> Handle,
}

-- Escape / gamepad B: ONE shared connection for every overlay, alive only while the stack is not empty. Engine
-- signals run their handlers in an unspecified order, so per-entry handlers could not agree on who is on top.
type StackEntry = { Escape: boolean, Dismiss: () -> () }
local stack: { StackEntry } = {}
local escConn: RBXScriptConnection? = nil
local holds = 0

local function onDismissKey(input: InputObject, processed: boolean)
	local kc = input.KeyCode
	if kc == Enum.KeyCode.Escape then
		if processed or Input.service():GetFocusedTextBox() ~= nil then
			return
		end
	elseif kc ~= Enum.KeyCode.ButtonB then
		return
	end
	if holds > 0 then
		return
	end
	local top = stack[#stack]
	if top ~= nil and top.Escape then
		top.Dismiss()
	end
end

local function pushEntry(e: StackEntry)
	table.insert(stack, e)
	if escConn == nil then
		escConn = Input.service().InputBegan:Connect(onDismissKey)
	end
end

local function popEntry(e: StackEntry)
	local i = table.find(stack, e)
	if i ~= nil then
		table.remove(stack, i)
	end
	if #stack == 0 and escConn ~= nil then
		escConn:Disconnect()
		escConn = nil
	end
end

local function isInside(inst: Instance, ancestor: Instance): boolean
	local p: Instance? = inst
	while p ~= nil do
		if p == ancestor then
			return true
		end
		p = p.Parent
	end
	return false
end

-- synchronous death checks of every overlay (weak keys): `default()` must not hand out an overlay whose layer lost its
-- Parent but whose `Destroying` handler has not run yet (Deferred signals)
local deadChecks: { [any]: () -> boolean } = setmetatable({}, { __mode = "k" }) :: any

local function lastInputIsGamepad(): boolean
	-- the fake service of the test harness may lack it: missing = not a gamepad
	local service = Input.service()
	local f: ((any) -> Enum.UserInputType)? = (service :: any).GetLastInputType
	if f == nil then
		return false
	end
	return string.sub(f(service).Name, 1, 7) == "Gamepad"
end

-- an in-tree Escape / B consumer on the shared stack (see the header)
local function onEscape(fn: () -> ()): () -> ()
	local e: StackEntry = { Escape = true, Dismiss = fn }
	pushEntry(e)
	local released = false
	return function()
		if not released then
			released = true
			popEntry(e)
		end
	end
end

local function holdDismiss(): () -> ()
	holds += 1
	local released = false
	return function()
		if not released then
			released = true
			holds -= 1
		end
	end
end

local function new(o: Options?): Overlay
	local opts: Options = o or {}
	local theme = Theme.resolve(opts.Theme)
	local slot = q.Slot({} :: { Instance })
	local alive = q.Source(true)
	local count = q.Source(0)
	local timers: { [thread]: true } = {}
	local live: { [() -> ()]: true } = {} -- per open entry: its "layer died" finalizer, until the entry is removed
	local everMounted = false
	local layerRef: Frame? = nil
	-- synchronous liveness: the Destroying flag, or a layer that was mounted and has no Parent now
	local function isDead(): boolean
		if not alive:Get() then
			return true
		end
		local l = layerRef
		if l ~= nil then
			if l.Parent ~= nil then
				everMounted = true
			elseif everMounted then
				return true
			end
		end
		return false
	end

	local layer = D.Frame {
		Name = "Overlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = opts.ZIndex or 100,
		Util.preHook(function(inst: GuiObject)
			inst:GetPropertyChangedSignal("Parent"):Connect(function()
				if inst.Parent ~= nil then
					everMounted = true
				end
			end)
			inst.Destroying:Connect(function()
				alive:Set(false)
				for t in timers do
					task.cancel(t)
				end
				table.clear(timers)
				-- finalize every live handle (the entries are being destroyed with the layer: nothing animates)
				local pendingErr: any = nil
				local failed = false
				for fin in table.clone(live) do
					local ok, err = pcall(fin)
					if not ok and not failed then
						failed, pendingErr = true, err
					end
				end
				table.clear(live)
				count:Set(0)
				if failed then
					error(pendingErr, 0)
				end
			end)
		end),
		slot,
	}

	layerRef = layer
	-- `q.debug` only, once per overlay (user decision 2026-10-13): a ScreenGui made in code is ZIndexBehavior Global,
	-- and under Global a CanvasGroup neither clips its children nor fades them with GroupTransparency — a dialog's
	-- content is drawn outside its card and only the card's background fades (measured in Studio). Nothing raises, so
	-- the first Open says it.
	local zIndexChecked = false
	local function open(_self: Overlay, oo: OpenOptions): Handle
		if isDead() then
			error("Overlay:Open: the overlay layer was destroyed — build a new Overlay (Overlay.default() rebuilds itself)", 2)
		end
		if q.debug and not zIndexChecked then
			-- by ClassName, not IsA("LayerCollector"): the spec mock has no class hierarchy (test/support/harness)
			local gui: any = layer.Parent
			while gui ~= nil and gui.ClassName ~= "ScreenGui" and gui.ClassName ~= "SurfaceGui" and gui.ClassName ~= "BillboardGui" do
				gui = gui.Parent
			end
			if gui ~= nil then
				zIndexChecked = true -- only once the layer is under a ScreenGui: an Open before that keeps the check
			end
			if gui ~= nil and gui.ZIndexBehavior ~= Enum.ZIndexBehavior.Sibling then
				print(`Material.Overlay: the overlay layer is under {gui.ClassName} "{gui.Name}" with ZIndexBehavior = {gui.ZIndexBehavior.Name} - set ZIndexBehavior = Enum.ZIndexBehavior.Sibling (a code-made ScreenGui defaults to Global: CanvasGroup surfaces - dialogs, pickers - then neither clip nor fade their content)`)
			end
		end
		local isOpen = q.Source(true)
		local closing = q.Source(false)
		local closed = false
		local entry: Frame? = nil
		local scrimTransparency: q.Source<number>? = nil
		local exitTime = if oo.ExitTime ~= nil then oo.ExitTime else Tokens.Motion.Duration.Short4
		local stackEntry: StackEntry? = nil
		-- selection trap: the entry is a SelectionGroup whose four directions Stop while `trapped` is true
		local trapped = q.Source(oo.TrapSelection == true)
		local trapping = oo.TrapSelection == true
		local trapBehavior: q.State<Enum.SelectionBehavior> = trapped:Compute(function(self)
			return if self:Get() then Enum.SelectionBehavior.Stop else Enum.SelectionBehavior.Escape
		end)
		local previousSelection: GuiObject? = nil
		local finalize: () -> ()
		local exitThread: thread? = nil
		local releaseInputRegistrations: () -> ()

		local function remove()
			live[finalize] = nil
			releaseInputRegistrations()
			local e = entry
			if e ~= nil then
				if not isDead() and e.Parent == layer then
					local idx = slot:IndexOf(e)
					if idx ~= nil then
						slot:Remove(idx)
					end
				end
				count:Set(math.max(0, count:Get() - 1))
			end
			entry = nil
			closing:Set(false)
		end

		-- drop the Escape stack entry and the selection confinement (idempotent; runs at the start of closing)
		function releaseInputRegistrations()
			local se = stackEntry
			if se ~= nil then
				stackEntry = nil
				popEntry(se)
			end
			if trapping then
				trapping = false
				trapped:Set(false)
				local prev = previousSelection
				previousSelection = nil
				local current = GuiService.SelectedObject
				local e = entry
				if prev ~= nil and prev.Parent ~= nil and (current == nil or (e ~= nil and isInside(current, e))) then
					GuiService.SelectedObject = prev
				end
			end
		end

		local function close(reason: CloseReason, result: unknown?)
			if closed then
				return
			end
			closed = true
			isOpen:Set(false)
			releaseInputRegistrations()
			closing:Set(true)
			if scrimTransparency then
				scrimTransparency:Set(1)
			end
			-- removal is scheduled BEFORE OnClose runs: a throwing OnClose cannot wedge the entry
			if exitTime > 0 then
				local th: thread
				th = task.delay(exitTime, function()
					timers[th] = nil
					exitThread = nil
					remove()
				end)
				timers[th] = true
				exitThread = th
			else
				remove()
			end
			if oo.OnClose then
				oo.OnClose(reason, result)
			end
		end

		-- the layer died: every state flips at once, nothing animates (the entry is destroyed with the layer)
		finalize = function()
			live[finalize] = nil
			local e = entry
			entry = nil
			-- anything still parented to the (dead) layer goes with it
			if e ~= nil and e.Parent ~= nil then
				e:Destroy()
			end
			releaseInputRegistrations()
			if closed then
				closing:Set(false)
				return
			end
			closed = true
			isOpen:Set(false)
			releaseInputRegistrations()
			closing:Set(false)
			if oo.OnClose then
				oo.OnClose("Destroyed")
			end
		end

		local handle: Handle
		handle = {
			IsOpen = isOpen,
			Closing = closing,
			Close = function(result: unknown?)
				close("Close", result)
			end,
		}

		local content: Instance
		if type(oo.Content) == "function" then
			content = oo.Content(handle)
		else
			content = oo.Content
		end
		if closed then
			-- the builder closed the handle while building: nothing is seated or registered
			local th = exitThread
			if th ~= nil then
				task.cancel(th)
				timers[th] = nil
				exitThread = nil
			end
			content:Destroy()
			closing:Set(false)
			return handle
		end

		local scrim: Instance? = nil
		if oo.Scrim == true then
			local fade = Tokens.Motion.options("Short4", "Linear")
			local target = 1 - (oo.ScrimOpacity or 0.32)
			local src = q.Source(1)
			scrimTransparency = src
			local dismissable = if oo.Dismissable ~= nil then oo.Dismissable else true
			scrim = D.TextButton {
				Name = "Scrim",
				Size = UDim2.fromScale(1, 1),
				Text = "",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Selectable = false,
				BackgroundColor3 = theme.Color.Scrim,
				BackgroundTransparency = src:Apply(q.Animate(fade)),
				Activated = function()
					if dismissable then
						close("Scrim", nil)
					end
				end,
				-- mounted snapped (fully transparent), then faded in: the second write tweens
				Util.postHook(function()
					src:Set(target)
				end),
			}
		end

		local e = D.Frame {
			Name = "OverlayEntry",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			SelectionGroup = if trapping then trapped else nil,
			SelectionBehaviorUp = if trapping then trapBehavior else nil,
			SelectionBehaviorDown = if trapping then trapBehavior else nil,
			SelectionBehaviorLeft = if trapping then trapBehavior else nil,
			SelectionBehaviorRight = if trapping then trapBehavior else nil,
			scrim or q.None,
			content,
		}
		entry = e
		live[finalize] = true
		count:Set(count:Get() + 1)
		slot:Add(e)

		if oo.Scrim == true or oo.DismissOnEscape == true then
			local onEsc = oo.OnEscape
			local se: StackEntry = {
				Escape = oo.DismissOnEscape == true,
				Dismiss = function()
					if onEsc ~= nil then
						onEsc()
					else
						close("Escape", nil)
					end
				end,
			}
			stackEntry = se
			pushEntry(se)
		end
		if trapping then
			previousSelection = GuiService.SelectedObject
		end
		local initial = oo.InitialSelection
		if initial ~= nil and lastInputIsGamepad() then
			local target: GuiObject? = if type(initial) == "function" then initial() else initial
			if target ~= nil then
				GuiService.SelectedObject = target
			end
		end
		return handle
	end

	local overlay: Overlay = { Layer = layer, Count = count, Alive = alive, Open = open }
	deadChecks[overlay] = isDead
	return overlay
end

local defaultOverlay: Overlay? = nil

local function default(): Overlay
	local d = defaultOverlay
	local check = if d ~= nil then deadChecks[d] else nil
	if d == nil or not d.Alive:Get() or (check ~= nil and check()) then
		d = new()
		defaultOverlay = d
	end
	return d :: Overlay
end

return {
	new = new,
	default = default,
	holdDismiss = holdDismiss,
	onEscape = onEscape,
}
