--!strict
--[[
	Overlay — a popup layer for Combo / Menu / Tooltip / modal-ish popups (docs/how-to/09: one place at the screen
	root, opened from anywhere).

	The app puts `overlay.Layer` into its ScreenGui (once, as a sibling of the windows). The layer is a full-screen,
	transparent, NON-Active Frame with a high ZIndex: clicks fall through it except where a popup (or its click-outside
	catcher) is.

	USAGE
		local Overlay = require("./Overlay")
		local overlay = Overlay.new()            -- one per ScreenGui (the layer dies with it), or Overlay.getDefault()
		q.Elem "ScreenGui" { ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, windowsFrame, overlay.Layer }
		-- ZIndexBehavior = Sibling is REQUIRED: a ScreenGui made in code defaults to Global, where the layer's ZIndex
		-- does not lift its popups (their own ZIndex is 1) above a window's frame or surface (a window of rank r takes
		-- ZIndex 3r-2..3r)

		local popup = overlay:Open({
			Content = q.Elem "Frame" { ... },           -- a quad-made element; the overlay owns it from now on
			Position = Vector2.new(x, y),        -- absolute screen position (same space as AbsolutePosition)
			Anchor = Vector2.new(0, 0),          -- which point of Content sits at Position (default 0,0)
			CloseOnClickOutside = true,          -- default true; false for tooltips (no catcher, input falls through)
			OnClose = function() ... end,        -- optional; runs once when the popup closes by any path
		})
		popup:Close()                            -- idempotent; destroys Content
		popup.IsOpen                             -- State<boolean>
		overlay:CloseAll()                       -- close every popup (e.g. when the owning window closes)
		overlay.Count                            -- State<number> of open popups
		overlay.Alive                            -- State<boolean>: false once the layer was destroyed

	A popup with CloseOnClickOutside gets a transparent full-screen button behind its content; pressing it closes the
	popup (the press does not reach the UI underneath — standard modal-popup behaviour). Each popup is ONE entry
	(a Frame holding the catcher and the positioned content) in the layer's manual-CRUD Slot, so open/close never
	re-parents a static child; later popups draw above earlier ones.

	THE DEFAULT OVERLAY. Widgets that are not given an `Overlay` prop use `Overlay.getDefault()`, resolved when a popup
	OPENS (not when the widget is built). Nothing is created at require time: the first call makes the instance, and a
	later call after its layer was destroyed (detected synchronously: a mounted layer without a Parent is dead at once, even
under Deferred signals) (the ScreenGui was rebuilt, e.g. ResetOnSpawn) makes a fresh one — a dead
	layer is never handed out again, so rebuilding a UI never re-parents a destroyed instance (Quad0219). Put
	`Overlay.getDefault().Layer` into the ONE ScreenGui that shows popups (the layer is a single instance: two live
	ScreenGuis cannot both hold it — Quad0160); for several ScreenGuis create your own `Overlay.new()` per ScreenGui and pass
	it to the widgets (`Overlay = overlay`). The first `Open` on a layer that is not mounted (`Layer.Parent == nil`) warns
	once per overlay, with or without `q.debug` (the popup would be invisible and nothing else says so — user decision
	2026-10-20, a consumer lost time on it); with `q.debug` on, one line (once per overlay) also says when the ScreenGui
	above the layer is not `ZIndexBehavior = Sibling` (see below). Always create the ScreenGui with `ResetOnSpawn = false` (the layer is a
	quad-made instance, a respawn would destroy it behind quad's back).

	WHEN THE LAYER DIES every popup still open is closed on the spot: `IsOpen` goes false, `OnClose` runs once (so owners
	drop their Escape listeners and bookkeeping), `Count` goes to 0. Slot operations are skipped when the layer is dead OR the
	popup's entry is no longer parented to the layer (with Deferred signals a descendant's Destroying can run before the
	layer's OnDestroyed, so a close path must not rely on the dead flag alone). `Open` on a dead overlay raises.

	The window manager does not move focus for a press on an open popup that takes input or on its click-outside catcher
	(the internal Pointer rule; under a story host without PlayerGui, the internal PopupHits registry, which lists a popup
	while it is open if it has a catcher or holds a button / text box / Active object — a tooltip is not listed, a press
	through it raises the window behind). Opening and closing a popup makes hover looks re-judge what is on top.

	Positioning: `Position` is converted into layer space at open time (minus Layer.AbsolutePosition), so the layer may
	sit under a ScreenGui with or without GuiInset. Anchor the content with `Anchor` to open upward/leftward.
	STAYING ON SCREEN [2026-10-21 user decision — research/devui-popup-model-plan.md 3.1, like Wayland's xdg_positioner]:
	once the content has a size (and again whenever it or the layer is resized) the popup is kept inside the layer —
	given `AnchorRect` (the screen rectangle it is attached to: a menu title, a dropdown box, a zero-size rect at the
	mouse), an axis it overflows is FLIPPED to the other side of that rectangle when that overflows less (below ->
	above, right -> left); then it is SLID inside. Content larger than the layer is not shrunk here — a list that can
	scroll caps its own height (Combo, Menu). With no size yet (a layer not laid out, the spec mock) the requested place stays.

	WHEEL [2026-10-21 — devplorer U19 (b), Studio-measured there]: the engine scrolls a ScrollingFrame under the pointer
	even when a popup covers it (an Active root, even a transparent ScrollingFrame over it, did not stop it); only that
	frame's ScrollingEnabled = false did. So while the pointer is over a popup that takes input, the ScrollingFrames of
	the layer's ScreenGui outside the layer have ScrollingEnabled off; the ones turned off are turned back on when the
	pointer leaves or the last popup closes. A tooltip (takes no input) does not count.
]]

local Input = require("./Input")
local Pointer = require("./Pointer")
local PopupHits = require("./PopupHits")
local Quad = require("./Quad")
local Visibility = require("./Visibility")
local Util = require("./Util")
local q = Quad
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Slot<T> = Quad.Slot<T>

export type PopupOptions = {
	Content: Instance,
	Position: Vector2,
	Anchor: Vector2?,
	AnchorRect: Rect?,
	CloseOnClickOutside: boolean?,
	OnClose: (() -> ())?,
}

export type Popup = {
	IsOpen: State<boolean>,
	Close: (self: Popup) -> (),
	Holder: Frame,
}

export type Overlay = {
	Layer: Frame,
	Count: State<number>,
	Alive: State<boolean>,
	Open: (self: Overlay, options: PopupOptions) -> Popup,
	CloseAll: (self: Overlay) -> (),
}

local Overlay = {}

-- switch (default on): the first `Open` on an unmounted layer warns once per overlay. Specs that open popups on a bare
-- layer turn it off; nothing else should.
Overlay.warnUnmounted = true

-- synchronous death checks (weak keys) so `getDefault` never hands out an overlay whose layer was just destroyed
local deadChecks: { [any]: () -> boolean } = setmetatable({}, { __mode = "k" }) :: any

function Overlay.new(options: { ZIndex: number? }?): Overlay
	local zIndex = if options and options.ZIndex then options.ZIndex else 1000

	local slot: Slot<Instance> = q.Slot({} :: { Instance })
	local count: Source<number> = q.Source(0)
	local alive: Source<boolean> = q.Source(true)
	local dead = false
	local everMounted = false
	local layerRef: Frame? = nil
	-- synchronous liveness: with Deferred signals `Destroying`/OnDestroyed run after `Destroy()` returned, so a layer
	-- that was mounted and has no Parent now counts as dead at once (`oldGui:Destroy(); buildUi()` in one frame)
	local function isDead(): boolean
		if dead then
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
	-- open popups, newest last (CloseAll walks it; Close removes its own entry)
	local open: { Popup } = {}
	-- popups that take input (header WHEEL): their holder covers what the wheel must not reach
	local takesInput: { [Popup]: boolean } = setmetatable({}, { __mode = "k" }) :: any
	-- the ScrollingFrames turned off while the pointer is over a popup (only those are turned back on)
	local shielded: { ScrollingFrame } = {}
	local shieldOn = false
	local function setShield(on: boolean)
		if on == shieldOn then
			return
		end
		shieldOn = on
		if not on then
			for _, frame in shielded do
				if frame.Parent ~= nil then
					frame.ScrollingEnabled = true
				end
			end
			table.clear(shielded)
			return
		end
		local l = layerRef
		local gui: any = l and l.Parent
		while gui ~= nil and gui.ClassName ~= "ScreenGui" and gui.ClassName ~= "SurfaceGui" and gui.ClassName ~= "BillboardGui" do
			gui = gui.Parent
		end
		if gui == nil or l == nil then
			return
		end
		-- (a walk by GetChildren, skipping the layer: the spec mock has no GetDescendants)
		local function walk(node: Instance)
			for _, item: any in node:GetChildren() do
				if item ~= l then
					if item.ClassName == "ScrollingFrame" and item.ScrollingEnabled then
						item.ScrollingEnabled = false
						table.insert(shielded, item)
					end
					walk(item)
				end
			end
		end
		walk(gui)
	end
	local function refreshShield()
		local mouse = Pointer.mouse()
		for _, p in open do
			if takesInput[p] then
				local h = p.Holder :: GuiObject
				local at, size = h.AbsolutePosition, h.AbsoluteSize
				if at ~= nil and size ~= nil and mouse.X >= at.X and mouse.Y >= at.Y and mouse.X < at.X + size.X and mouse.Y < at.Y + size.Y then
					setShield(true)
					return
				end
			end
		end
		setShield(false)
	end
	local moveConn: RBXScriptConnection? = nil
	-- connected only while a popup is open
	local function watchPointer()
		if #open > 0 and moveConn == nil then
			moveConn = Input.service().InputChanged:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					refreshShield()
				end
			end)
		elseif #open == 0 then
			local c = moveConn
			moveConn = nil
			if c then
				c:Disconnect()
			end
			setShield(false)
		end
	end

	local layer = Frame({
		Name = "OverlayLayer",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = false,
		ZIndex = zIndex,
		slot,
		q.PreRef(nil :: Frame?):Callback(function(inst: Frame?)
			if inst ~= nil then
				inst:GetPropertyChangedSignal("Parent"):Connect(function()
					if inst.Parent ~= nil then
						everMounted = true
					end
				end)
			end
		end),
		q.OnDestroyed(function()
			dead = true
			alive:Set(false)
			-- close what is still open (newest first): OnClose runs, no Slot ops (dead), Count reaches 0
			local snapshot = table.clone(open)
			for i = #snapshot, 1, -1 do
				snapshot[i]:Close()
			end
		end),
	})

	-- `q.debug` only, once per overlay: the kit layers by ZIndex among SIBLINGS (a window of rank r takes ZIndex 3r-2..3r — frame, surface, grip — this layer 1000). A
	-- ScreenGui made in code is ZIndexBehavior Global, where a ZIndex is compared across the whole ScreenGui: a window
	-- frame of rank 2+ then draws over its window's content and over every popup (their ZIndex is 1). Nothing raises, so the
	-- first Open under such a ScreenGui says it (as the material kit's Overlay does).
	local zIndexChecked = false
	local unmountedWarned = false
	local function openPopup(self: Overlay, opts: PopupOptions): Popup
		if isDead() then
			Util.fail("Overlay:Open", "the overlay layer was destroyed")
		end
		-- not debug-gated (once per overlay, not per frame): an invisible popup is otherwise silent
		if Overlay.warnUnmounted and not unmountedWarned and layer.Parent == nil then
			unmountedWarned = true
			warn("Devui.Overlay:Open: the overlay layer is not mounted — the popup will not be visible. Put `overlay.Layer` (or `Devui.Overlay.getDefault().Layer`) into the ScreenGui that shows popups")
		end
		if q.debug and not zIndexChecked then
			-- by ClassName, not IsA("LayerCollector"): the spec mock has no class hierarchy
			local gui: any = layer.Parent
			while gui ~= nil and gui.ClassName ~= "ScreenGui" and gui.ClassName ~= "SurfaceGui" and gui.ClassName ~= "BillboardGui" do
				gui = gui.Parent
			end
			if gui ~= nil then
				zIndexChecked = true -- only once the layer is under a ScreenGui: an Open before that keeps the check
				-- (nil: the spec mock has no property defaults — a ScreenGui that was not given one reads nil there)
				local behavior = gui.ZIndexBehavior
				if behavior ~= nil and behavior ~= Enum.ZIndexBehavior.Sibling then
					print(`Devui.Overlay: the overlay layer is under {gui.ClassName} "{gui.Name}" with ZIndexBehavior = {behavior.Name} - set ZIndexBehavior = Enum.ZIndexBehavior.Sibling (a code-made ScreenGui defaults to Global: windows and popups are layered by sibling ZIndex and draw in the wrong order under Global)`)
				end
			end
		end
		local isOpen: Source<boolean> = q.Source(true)
		-- (`or`: engines always have it; the test mock has no layout engine until a spec sets AbsolutePosition)
		local origin: Vector2 = layer.AbsolutePosition or Vector2.new(0, 0)
		local pos = opts.Position - origin
		local requestAnchor = opts.Anchor or Vector2.new(0, 0)
		local rect = opts.AnchorRect
		local rectMin: Vector2? = if rect then rect.Min - origin else nil
		local rectMax: Vector2? = if rect then rect.Max - origin else nil
		local closeOutside = opts.CloseOnClickOutside ~= false
		local onClose = opts.OnClose

		local closeImpl: () -> () = function() end

		-- [2026-10-21 — devplorer U19 (a), Studio-confirmed there] a press on the content's empty area (a menu panel's
		-- padding: a Frame, even Active, does not stop a click) fell through to the catcher and closed the popup. A
		-- transparent button under the content takes it. Sized from the content's AbsoluteSize, not by scale: a scale
		-- child of the auto-sized holder would grow the holder to the layer
		local sink: Instance | typeof(q.None) = q.None
		if closeOutside and Visibility.isGuiObject(opts.Content) then
			local content = opts.Content :: GuiObject
			local sinkSize: Source<UDim2> = q.Source(UDim2.fromOffset(content.AbsoluteSize.X, content.AbsoluteSize.Y))
			content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				sinkSize:SetIfChanged(UDim2.fromOffset(content.AbsoluteSize.X, content.AbsoluteSize.Y))
			end)
			sink = TextButton({
				Name = "ClickSink",
				Size = sinkSize,
				ZIndex = 0,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
			})
		end

		local holder = Frame({
			Name = "PopupHolder",
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			AnchorPoint = opts.Anchor or Vector2.new(0, 0),
			Position = UDim2.fromOffset(pos.X, pos.Y),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			sink,
			opts.Content,
		})

		-- keep it on screen (header STAYING ON SCREEN): per axis, the requested top-left or its mirror about the anchor
		-- rectangle — whichever overflows the layer less — then clamped inside
		local function place()
			local size: Vector2? = holder.AbsoluteSize
			local room: Vector2? = layer.AbsoluteSize
			if size == nil or room == nil or size.X <= 0 or size.Y <= 0 or room.X <= 0 or room.Y <= 0 then
				return
			end
			local function axis(p: number, a: number, s: number, r: number, lo: number?, hi: number?): number
				local function over(t: number): number
					return math.max(0, -t) + math.max(0, t + s - r)
				end
				local t = p - a * s
				if lo ~= nil and hi ~= nil and over(t) > 0 then
					local mirrored = (lo + hi - p) - (1 - a) * s
					if over(mirrored) < over(t) then
						t = mirrored
					end
				end
				return math.clamp(t, 0, math.max(0, r - s))
			end
			local x = axis(pos.X, requestAnchor.X, size.X, room.X, rectMin and rectMin.X, rectMax and rectMax.X)
			local y = axis(pos.Y, requestAnchor.Y, size.Y, room.Y, rectMin and rectMin.Y, rectMax and rectMax.Y)
			holder.AnchorPoint = Vector2.zero
			holder.Position = UDim2.fromOffset(math.round(x), math.round(y))
		end
		holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
		local layerConn = layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)

		local entry = Frame({
			Name = "Popup",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = false,
			if closeOutside
				then TextButton({
					Name = "Catcher",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = "",
					Activated = function()
						closeImpl()
					end,
				})
				else q.None,
			holder,
		})

		local popup: Popup = {
			IsOpen = isOpen,
			Close = function(_self: Popup)
				closeImpl()
			end,
			Holder = holder,
		}
		-- the window manager does not move focus for a press on a popup that takes input (or on its click-outside
		-- catcher: the layer); a popup that takes no input (a tooltip) is not listed — a press goes through it
		local hits: PopupHits.Record? = if closeOutside
			then { Area = layer }
			elseif Pointer.containsTaker(opts.Content) then { Area = holder }
			else nil
		closeImpl = function()
			if not isOpen:Get() then
				return
			end
			isOpen:Set(false)
			layerConn:Disconnect()
			if hits then
				PopupHits.remove(hits)
			end
			Pointer.invalidate()
			local i = table.find(open, popup)
			if i then
				table.remove(open, i)
			end
			count:Set(#open)
			watchPointer()
			if shieldOn then
				refreshShield()
			end
			-- skip Slot ops when the layer is dead, or when the entry was already detached (Deferred signal ordering:
			-- descendants' Destroying may run before the layer's OnDestroyed)
			if not isDead() and entry.Parent == layer then
				-- A close can arrive from INSIDE another popup's removal: a menu row's / combo's OnDestroyed closes
				-- its own popup while the popup holding that row is being removed from this same Slot (synchronous
				-- signals: Immediate SignalBehavior, the test mock). The Slot refuses a CRUD there (`Quad0167`), so
				-- go through WhenIdle — now when the Slot is idle, right after that removal otherwise — and take the
				-- index when it runs.
				slot:WhenIdle(function(s)
					if isDead() then
						return
					end
					local index = s:IndexOf(entry)
					if index then
						s:Remove(index)
					end
				end)
			elseif entry.Parent ~= nil then
				-- dead layer: whatever is still parented to it goes with it
				entry:Destroy()
			end
			if onClose then
				onClose()
			end
		end
		slot:Add(entry)
		if hits then
			PopupHits.add(hits)
		end
		Pointer.invalidate()
		table.insert(open, popup)
		takesInput[popup] = hits ~= nil
		count:Set(#open)
		watchPointer()
		return popup
	end

	local function closeAll(_self: Overlay)
		-- Close mutates `open`: walk a copy, newest first
		local snapshot = table.clone(open)
		for i = #snapshot, 1, -1 do
			snapshot[i]:Close()
		end
	end

	layerRef = layer
	local overlay: Overlay = { Layer = layer, Count = count, Alive = alive, Open = openPopup, CloseAll = closeAll }
	Util.tagSurface(overlay) -- `:Open` / `:CloseAll` are public surface (a usage error blames the caller)
	deadChecks[overlay] = isDead
	return overlay
end

-- the shared overlay of widgets that were not given one; recreated when its layer is dead (see the header)
local defaultOverlay: Overlay? = nil

function Overlay.getDefault(): Overlay
	local current = defaultOverlay
	local check = if current ~= nil then deadChecks[current] else nil
	if current == nil or not current.Alive:Get() or (check ~= nil and check()) then
		current = Overlay.new()
		defaultOverlay = current
	end
	return current :: Overlay
end

return Overlay
