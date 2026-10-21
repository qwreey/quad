--!strict
--[[
	WindowManager — the COMPOSITOR of a group of windows: z-order, focus (focus-on-press, "bring to front") and every
	window's decoration. A window (Window) returns only its content SURFACE; the frame, title bar and resize grip around
	it are made here (Window/Decoration.luau, Wayland's server-side decorations) and placed as siblings of the surface
	root, in whatever parent the app gave it (they follow its `Parent`; nil parent = no decoration on screen; the
	surface root's destruction disposes them). The app's placement of the root is never changed.

	Windows hosted as siblings in one container are layered by ZIndex. This needs `ScreenGui.ZIndexBehavior = Sibling`,
	which is the default only for a ScreenGui inserted in Studio: one made in code (`q.Elem "ScreenGui"`, `Instance.new`) is
	Global unless you set it, and under Global a window ranked above another draws over its own content (a ZIndex is
	then compared across the whole ScreenGui, and the content's is 1). The manager keeps the windows in stacking order
	(bottom first) and gives each window a CHUNK of three consecutive ZIndex values by its RANK r in that list (1..n):
	3r - 2 = the decoration frame (below the surface), 3r - 1 = the surface root (`slot.ZIndex`), 3r = the resize grip
	(above the surface). `Focus` moves the window to the end and renumbers, so the ZIndex never grows past 3 x the
	number of live windows (an ever-increasing counter would climb above the Overlay layer's ZIndex 1000 after enough
	focus switches and draw windows over popups). The window that was focused last is `Focused` (its title bar draws in
	the "active" colour). A window releases its slot when it is destroyed (Window does it), so ranks stay compact.
	Supports up to 333 live windows below the default Overlay layer. A title-bar drag at a screen edge shows its preview
	one value above the dragged (raised, so top) window's chunk [Window/Decoration.luau header "DOCKED"].

	USAGE
		local Manager = require("./Manager")
		local manager = Manager.new()                  -- or Manager.default (shared, used when props.Manager is nil)
		local slot = manager:Register()                -- one per window
		slot.ZIndex   : State<number>                  -- bind to the window root's ZIndex (the middle of its chunk)
		slot.Focused  : State<boolean>                 -- is this the focused window
		slot.Hook     : GuiHook                        -- put in the window ROOT's array part (press-to-front, see below)
		slot:Focus()                                   -- raise to front + focus (idempotent when already focused)
		slot:Blur()                                    -- drop the focus if this window has it (no window focused; the
		                                               -- order is kept) — the false side of Window's two-way `Focused`
		slot:Release()                                 -- leave the manager (idempotent); the others close ranks
		manager.Focused : State<number>                -- id of the focused window (0 = none)
	Window also talks to its slot through the internal Compositor port (Window/Compositor.luau): it hands over its
	hints (Title, the No* flags, MinSize, Position / Size / Open / Collapsed) and gets the surface's placement back,
	and it reports its open state. A hand-made root with only `slot.Hook` is an UNDECORATED window (no frame, no title
	bar; see FOCUS SUCCESSION).

	A newly registered window starts on top but does NOT steal focus (the first press focuses it).

	LAYOUT [2026-10-20 user decision — devui does not store anything: it hands out and takes back plain JSON-ready
	tables, the app keeps them; format in Window/Layout.luau]. A window with a `Key` (its IDENTITY, unique among this
	manager's live windows — a second one raises) is part of the layout; its `Kind` (its TYPE, default = the Key) is
	saved with it so a loader can make it again. A window without a Key behaves the same and is only left out of the
	layout (with `q.debug`, one notice per manager once the app uses the layout API). What is saved per window: Open,
	Collapsed, Position and Size (the floating outer rectangle, also for a docked window), the edge it is docked on and
	its dock width (header DOCK), and the stacking order of the keyed FLOATING windows (the export order). Not saved:
	the title, the content, the focus, the stacking of the docked windows.
		manager:ExportLayout() -> WindowLayout          every known key (live or pending): floating bottom first, docked
		                                                on its edge (`Left` / `Right`)
		manager:ImportLayout(layout, factories?)          put the windows where the layout says (rules below)
		manager:ExportWindow(key) -> WindowState?         one window's state (nil = an unknown key)
		manager:ImportWindow(key, state)                  one window: the same rules, no factory, no stacking
		manager:ForgetWindow(key)                         drop a key from the layout (rules below)
		manager.Layout : State<WindowLayout>              re-emitted when the layout changes (frozen tables; an Observer
		                                                  on it is the app's auto-save — debounce it, a drag writes on
		                                                  every move)
	Import rules (one API, callable at any time): a key whose window is registered moves there at once (the state is
	written into the window's own Position / Size / Open / Collapsed Sources — the app's Sources change); a key with no
	window yet is PENDING and becomes that window's initial state the moment a window with that Key registers. Windows
	the layout does not name are left as they are. Pending keys are exported again unchanged (an unknown key is never
	dropped: a session without some window keeps its place). `factories` maps a Kind to `function(key)` = "make the
	window of this identity exist" (the app builds it and puts it where it wants; devui never parents a root): it is
	called once per key that was OPEN when saved and is not registered yet; a Kind missing from the map stays pending.
	A keyed window that is destroyed leaves its last state pending (an app rebuilding its UI gets its windows back,
	and the Layout output does not change). `ForgetWindow(key)` [2026-10-20 user decision — an app that really closes a
	window (a File > Exit item) must be able to say so] drops a pending key at once, and a live one the moment its
	window goes away (so "forget, then destroy" and "destroy, then forget" are the same); importing that key again
	before then cancels it. An unknown key is a no-op.
	STACKING [2026-10-20 user decision — a small window restored under a big one would have to be dug out]: the keys are
	kept bottom first (`known`); raising a keyed window moves its key to the top, and a keyed window that registers
	takes its place among the other keyed windows by that order (an app that imports first and then builds its windows
	in any order gets them stacked as saved). Windows without a Key keep their own slots. An import restacks the
	windows it names into the layout's order — its docked keys first, then the `Floating` order, so the docked windows
	start UNDER the floating ones [2026-10-20 user decision — their strip is never covered, so the docked windows'
	stacking is not saved]; a known key it does not name rides with the named key it was above (or stays at the bottom).
	A docked window raised at run time still moves its key to the top of `known`; that place only ever orders `Floating`
	(where a docked key is not). The focus is not saved: an import moves nothing to the front by itself.

	DOCK [2026-10-20 user decisions — docking stage 2, edge docking; the look and the drag rules are in
	Window/Decoration.luau header "DOCKED"]. A docked window is still one window of `order`: the same ZIndex chunk, the
	same raise / focus / succession rules (expanding it raises and focuses it, a press brings it to the front, a press on
	another window brings that one up — a panel covers floating windows, nothing is pushed aside). Only its placement
	differs. Per window the manager keeps the edge (`Side`, nil = floating) and the dock width; one OPEN window per edge
	per manager (a second edge drag shows no preview and does not dock). Closing a docked window hides its panel and
	strip and frees the edge, but the window keeps the edge and width: `Open:Set(true)` docks it there again, or floats
	it (its kept Position / Size) when another open window took that edge meanwhile. A layout state with a `Dock` docks
	the window the same way (an open one floats when the edge is held; a closed one keeps the edge remembered); a
	pending key docks when its window registers. A docked window's strip walls the floating windows of the same
	container (the parent of its surface root): their staying-on-screen stops at it, and a strip that appears (dock,
	reopen, import) brings the ones already over it out (the container-shrink path), as does a floating window placed
	over a strip (an import, a reopen that floats it, a move into the container). Saving: the edge group holds the
	open window docked there, else the topmost known key that remembers that edge (closed or pending); any other key
	remembering an edge is saved in `Floating`, so a saved layout never has two windows on one edge. A window without a
	Key docks the same and is only left out of the layout. Strip press rule: the strip asks whether its window had the
	focus BEFORE the press — the manager's global press (PRESS TO FRONT) focuses first and records that (`lastPress`,
	read once by the strip's Activated); a gamepad / keyboard activation (no global press) reads the current focus.

	PRESS TO FRONT. A press stops at the first GuiButton / TextBox under the pointer (engine rule): the window frame
	behind a button, a checkbox or a text box never sees an InputBegan. So the manager listens to ONE global press
	(`UserInputService.InputBegan`, mouse button 1 / touch — through `Input.service()`, opened while at least one root is
	hooked and closed when the last one leaves; `Input.use` moves it to the new service) and finds the window the press
	went to. `gameProcessedEvent` is NOT filtered: a press on a widget is exactly the case that needs it. It focuses on
	PRESS, not release, like the title bar and Dear ImGui (devui has no drag-and-drop between windows that would need
	release-time focus).
	Hit test (the internal Pointer rule, shared with hover and tooltips): walk `PlayerGui:GetGuiObjectsAtPosition` from
	the top; the first object inside a hooked window root OR inside one of its decoration instances focuses that
	window, and an object that TAKES THE CLICK before that (a button, a text box or an Active object outside every
	window: an open popup's row or click-outside catcher, a HUD button of another ScreenGui) means the press is not the
	window's — nothing changes. Objects that take no input (a tooltip, a transparent layer) are passed through, as the
	engine passes the press. A window that is hidden or detached from the tree is never in that list.
	Without a PlayerGui (a story host renders into a plugin widget) it falls back to rectangles: an open popup that
	takes input (the internal PopupHits registry) changes nothing, else the highest-rank window on screen whose root
	or decoration AbsolutePosition / AbsoluteSize rectangle holds the point is focused.

	FOCUS SUCCESSION (Dear ImGui: closing the focused window gives focus to the topmost remaining one). When the focused
	window is closed or released, the topmost window still open is focused (and raised); none left = `Focused` 0.
	"Open" is the window's own state, told by Window through the Compositor port (`Open`), NOT its root's `Visible`:
	the surface root is also hidden while collapsed (and, later, while another surface of its group is shown), and
	that must not pass the focus on. Still open = open AND its container on screen (shown, ancestors shown, in a
	placed LayerCollector). An undecorated window (a hand-made root) keeps the older rule: its root's `Visible` going
	false is a close, and "still open" = its root on screen. A closed window keeps its slot; when it is opened again
	it comes to the front WITH the focus (Dear ImGui focuses an appearing window — user decision 2026-10-15). A window
	that is open from the start does not steal the focus (the line above).
]]

local GlobalInput = require("../GlobalInput")
local Input = require("../Input")
local Pointer = require("../Pointer")
local PopupHits = require("../PopupHits")
local Quad = require("../Quad")
local q = Quad
local Types = require("../Types")
local Visibility = require("../Visibility")
local Util = require("../Util")
local Compositor = require("./Compositor")
local Decoration = require("./Decoration")
local Layout = require("./Layout")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>

export type Slot = {
	Id: number,
	ZIndex: State<number>,
	Focused: State<boolean>,
	Hook: Types.GuiHook,
	Focus: (self: Slot) -> (),
	Blur: (self: Slot) -> (),
	Release: (self: Slot) -> (),
}

export type WindowLayout = Layout.WindowLayout
export type WindowState = Layout.WindowState
type Side = Layout.Side

export type Manager = {
	Focused: State<number>,
	Layout: State<WindowLayout>,
	Register: (self: Manager) -> Slot,
	ExportLayout: (self: Manager) -> WindowLayout,
	ImportLayout: (self: Manager, layout: WindowLayout, factories: { [string]: (key: string) -> () }?) -> (),
	ExportWindow: (self: Manager, key: string) -> WindowState?,
	ImportWindow: (self: Manager, key: string, state: WindowState) -> (),
	ForgetWindow: (self: Manager, key: string) -> (),
}

type Entry = {
	Id: number,
	Rank: Source<number>, -- 1..n, bottom first
	Root: GuiObject?,
	Open: State<boolean>?, -- the surface's open state (decorated windows only; nil = the root's Visible decides)
	Deco: Decoration.Decoration?,
	Hints: Decoration.Hints?, -- decorated windows: the Sources a layout is read from and written into
	Key: string?, -- decorated windows with a Key: their identity in the layout
	Kind: string,
	-- the edge dock (header DOCK): the side it is docked on (nil = floating; kept while closed) and its panel width
	Side: Source<Side?>,
	DockWidth: Source<number>,
}

-- the press the strip rule asks about (header DOCK): the window the last global press went to and whether it had
-- the focus before that press focused it
type PressRecord = { Entry: Entry, WasFocused: boolean }

-- ZIndex values per window (decoration frame, surface, resize grip): see the header
local SPAN = 3

local Manager = {}

local function isPrimaryDown(input: InputObject): boolean
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
end

-- the point is in gui's on-screen rectangle
local function holds(gui: Instance, x: number, y: number): boolean
	if not Visibility.isGuiObject(gui) then
		return false
	end
	local g = gui :: GuiObject
	local p, s = g.AbsolutePosition, g.AbsoluteSize
	return x >= p.X and y >= p.Y and x < p.X + s.X and y < p.Y + s.Y and Visibility.isOnScreen(g)
end

function Manager.new(): Manager
	local nextId = 0
	local focusedId: Source<number> = q.Source(0)
	-- live windows, bottom first; Rank = position
	local order: { Entry } = {}
	-- entries whose root is hooked (the global press listener is open while this is > 0)
	local hooked = 0
	local offPress: (() -> ())? = nil

	-- LAYOUT (header "LAYOUT"): every key this manager knows, bottom first (header STACKING; the export order); a
	-- known key is either live (a registered window holds it) or pending (its state waits for that window)
	local known: { string } = {}
	local live: { [string]: Entry } = {}
	local pending: { [string]: WindowState } = {}
	-- live keys asked to be forgotten: dropped instead of left pending when their window goes away
	local forgetting: { [string]: true } = {}
	local layoutOut: Source<WindowLayout> = q.Source(Layout.freeze(Layout.empty()))
	local batching = 0
	local layoutDirty = false
	-- the q.debug notice about windows without a Key: once per manager, after the app used the layout API
	local layoutUsed = false
	local keylessNoticed = false
	local keyless: { [Entry]: string } = {} -- decorated windows without a Key -> their title (for the notice)

	local function remember(key: string)
		if live[key] == nil and pending[key] == nil then
			table.insert(known, key)
		end
	end

	local function liveKey(entry: Entry): string?
		local key = entry.Key
		return if key ~= nil and live[key] == entry then key else nil
	end

	-- the press the strip rule asks about (header DOCK); nil = the last press went to no window
	local lastPress: PressRecord? = nil

	-- the open window docked on `side` other than `except` (header DOCK: one open window per edge)
	local function occupant(side: Side, except: Entry?): Entry?
		for _, entry in order do
			local h = entry.Hints
			if entry ~= except and h ~= nil and entry.Side:Get() == side and h.Open:Get() then
				return entry
			end
		end
		return nil
	end

	-- the windows sharing `entry`'s container (the parent of its surface root), other than itself
	local function neighbours(entry: Entry): { Entry }
		local root = entry.Root
		local container = if root then root.Parent else nil
		local out: { Entry } = {}
		if container == nil then
			return out
		end
		for _, other in order do
			local otherRoot = other.Root
			if other ~= entry and otherRoot ~= nil and otherRoot.Parent == container then
				table.insert(out, other)
			end
		end
		return out
	end

	-- `entry` was just placed (docked, floated, opened, moved to a container, imported): no floating window may sit
	-- over a strip (header DOCK). A docked open window brings the floating windows of its container out of its strip;
	-- a floating one is brought out of the strips already there itself (the same path as a shrinking container).
	local function settle(entry: Entry)
		local h = entry.Hints
		if h == nil then
			return
		end
		-- (a closed window is left where it is: it is settled when it opens, and a hidden move would make an
		-- imported layout export differently)
		if not h.Open:Get() then
			return
		end
		if entry.Side:Get() == nil then
			local deco = entry.Deco
			if deco ~= nil then
				deco.Reclamp()
			end
			return
		end
		for _, other in neighbours(entry) do
			local deco, oh = other.Deco, other.Hints
			if deco ~= nil and oh ~= nil and oh.Open:Get() then
				deco.Reclamp()
			end
		end
	end

	-- the strip widths (left, right) that wall a floating `entry` in its container (the docked windows' own FrameHeight)
	local function insets(entry: Entry): (number, number)
		local left, right = 0, 0
		for _, other in neighbours(entry) do
			local h = other.Hints
			if h ~= nil and h.Open:Get() then
				local at = other.Side:Get()
				if at == "Left" then
					left = math.max(left, h.Style.FrameHeight:Get())
				elseif at == "Right" then
					right = math.max(right, h.Style.FrameHeight:Get())
				end
			end
		end
		return left, right
	end

	local function snapshot(entry: Entry): WindowState
		local h = entry.Hints :: Decoration.Hints
		local side = entry.Side:Get()
		return {
			Kind = entry.Kind,
			Open = h.Open:Get(),
			Collapsed = h.Collapsed:Get(),
			Position = Layout.positionOf(h.Position:Get()),
			Size = Layout.sizeOf(h.Size:Get()),
			Dock = side,
			DockWidth = if side ~= nil then entry.DockWidth:Get() else nil,
		}
	end

	local function stateOf(key: string): WindowState
		local entry = live[key]
		return if entry ~= nil then snapshot(entry) else pending[key]
	end

	-- write a saved state into a window's own Sources (the app's Sources change; the window follows them). The
	-- window's Kind is its own: a saved Kind never renames a live window.
	-- A state without a floating rectangle (an edge group of a layout saved without one) leaves Position / Size alone.
	-- A docked state docks the window, except that an OPEN window cannot take an edge another open window holds — it
	-- floats; a closed one keeps the edge remembered (header DOCK).
	local function apply(entry: Entry, state: WindowState)
		local h = entry.Hints :: Decoration.Hints
		h.Collapsed:SetIfChanged(state.Collapsed)
		local size, position = state.Size, state.Position
		if size ~= nil then
			h.Size:SetIfChanged(Layout.toSize(size))
		end
		if position ~= nil then
			h.Position:SetIfChanged(Layout.toPosition(position))
		end
		local side = state.Dock
		if side ~= nil then
			local width = state.DockWidth :: number
			local deco = entry.Deco
			entry.DockWidth:SetIfChanged(if deco ~= nil then deco.FitDockWidth(width) else width)
			if state.Open and occupant(side, entry) ~= nil then
				side = nil
			end
		end
		entry.Side:SetIfChanged(side)
		h.Open:SetIfChanged(state.Open)
		settle(entry)
	end

	-- the key saved on each edge: the open window there (none when it has no Key), else the topmost known key whose
	-- state remembers that edge (a closed or pending one); every other key remembering an edge is saved as floating
	local function holders(): { [Side]: string }
		local out: { [Side]: string } = {}
		for _, side: Side in { "Left" :: Side, "Right" :: Side } do
			local holder = occupant(side, nil)
			if holder ~= nil then
				local key = liveKey(holder)
				if key ~= nil then
					out[side] = key
				end
			else
				for i = #known, 1, -1 do
					if stateOf(known[i]).Dock == side then
						out[side] = known[i]
						break
					end
				end
			end
		end
		return out
	end

	local function refresh()
		if batching > 0 then
			layoutDirty = true
			return
		end
		layoutDirty = false
		local nextLayout = Layout.build(known, stateOf, holders())
		if not Layout.same(nextLayout, layoutOut:Get()) then
			layoutOut:Set(Layout.freeze(nextLayout))
		end
	end

	-- run `body` with the Layout output held back, then emit once (also when body throws: the error goes on)
	local function batch(body: () -> ())
		batching += 1
		local ok, err = pcall(body)
		batching -= 1
		if batching == 0 and layoutDirty then
			refresh()
		end
		if not ok then
			error(err, 0)
		end
	end

	local function noticeKeyless()
		if not q.debug or keylessNoticed or not layoutUsed then
			return
		end
		local _, title = next(keyless)
		if title ~= nil then
			keylessNoticed = true
			print(`Devui.WindowManager: a window without Key ("{title}") is left out of the layout — give each window you want saved a Key (its identity in the manager)`)
		end
	end

	local function renumber()
		for i, entry in order do
			entry.Rank:SetIfChanged(i)
		end
		-- what is on top under a still pointer may have changed (hover looks re-judge)
		Pointer.invalidate()
	end


	-- put the keyed live windows in `known`'s order, each in one of the slots the keyed windows hold now (header
	-- STACKING: the windows without a Key keep theirs)
	local function restack()
		local at: { [string]: number } = {}
		for i, key in known do
			at[key] = i
		end
		local slots: { number } = {}
		local keyed: { Entry } = {}
		for i, entry in order do
			if liveKey(entry) ~= nil then
				table.insert(slots, i)
				table.insert(keyed, entry)
			end
		end
		table.sort(keyed, function(x: Entry, y: Entry): boolean
			return at[x.Key :: string] < at[y.Key :: string]
		end)
		for j, i in slots do
			order[i] = keyed[j]
		end
		renumber()
	end

	-- `layoutKeys` (an import, bottom first) become the order of the keys they name; every other known key rides with
	-- the named key just below it (or stays at the bottom when none is)
	local function stackAs(layoutKeys: { string })
		local named: { [string]: true } = {}
		for _, key in layoutKeys do
			named[key] = true
		end
		local bottom: { string } = {}
		local above: { [string]: { string } } = {}
		local under: string? = nil
		for _, key in known do
			if named[key] then
				under = key
			elseif under == nil then
				table.insert(bottom, key)
			else
				local riders = above[under] or {}
				above[under] = riders
				table.insert(riders, key)
			end
		end
		local out = bottom
		for _, key in layoutKeys do
			table.insert(out, key)
			for _, rider in above[key] or {} do
				table.insert(out, rider)
			end
		end
		known = out
	end

	local function focus(entry: Entry)
		if focusedId:Get() == entry.Id and order[#order] == entry then
			return -- already focused AND on top (a newer registration may cover a focused window)
		end
		local at = table.find(order, entry)
		if at == nil then
			return -- released
		end
		table.remove(order, at)
		table.insert(order, entry)
		renumber()
		-- a keyed window raised: its key goes to the top of the saved order (header STACKING)
		local key = liveKey(entry)
		if key ~= nil and known[#known] ~= key then
			table.remove(known, table.find(known, key) :: number)
			table.insert(known, key)
			refresh()
		end
		focusedId:SetIfChanged(entry.Id) -- (a focused window that was only covered: the rank changed, the focus did not)
	end

	-- still open (header FOCUS SUCCESSION)
	local function isOpen(entry: Entry): boolean
		local root = entry.Root
		if root == nil then
			return false
		end
		local open = entry.Open
		if open == nil then
			return Visibility.isOnScreen(root)
		end
		local container = root.Parent
		return open:Get() and container ~= nil and Visibility.isOnScreen(container)
	end

	-- the focused window went away (closed or released): the topmost window still open takes the focus
	local function succeed()
		for i = #order, 1, -1 do
			if isOpen(order[i]) then
				focus(order[i])
				return
			end
		end
		focusedId:Set(0)
	end

	-- the window whose root or decoration instance is `inst`
	local function ownerOf(inst: Instance): Entry?
		for _, entry in order do
			if entry.Root == inst then
				return entry
			end
			local deco = entry.Deco
			if deco ~= nil and table.find(deco.Parts, inst) ~= nil then
				return entry
			end
		end
		return nil
	end

	-- the innermost window whose root or decoration is o or above it
	local function windowOf(o: Instance): Entry?
		local cursor: Instance? = o
		while cursor ~= nil do
			local entry = ownerOf(cursor)
			if entry ~= nil then
				return entry
			end
			cursor = cursor.Parent
		end
		return nil
	end

	-- a press went to `entry`: remember whether it had the focus before (the strip rule), then focus it
	local function pressed(entry: Entry)
		lastPress = { Entry = entry, WasFocused = focusedId:Get() == entry.Id }
		focus(entry)
	end

	local function onPress(input: InputObject)
		if not isPrimaryDown(input) then
			return
		end
		lastPress = nil
		local x, y = input.Position.X, input.Position.Y
		local list = nil
		for i = #order, 1, -1 do
			local root = order[i].Root
			if root ~= nil then
				list = Pointer.objectsAt(root, x, y)
				if list ~= nil then
					break
				end
			end
		end
		if list ~= nil then
			for _, o in list do
				local entry = windowOf(o)
				if entry ~= nil then
					pressed(entry)
					return
				elseif Pointer.takesClick(o) then
					return -- the press went to something that is not a window (a popup, another ScreenGui's button)
				end
			end
			return
		end
		-- no PlayerGui (a story host): rectangles
		if PopupHits.covers(x, y) then
			return
		end
		for i = #order, 1, -1 do
			local entry = order[i]
			local root = entry.Root
			if root ~= nil then
				local hit = holds(root, x, y)
				local deco = entry.Deco
				if not hit and deco ~= nil then
					for _, part in deco.Parts do
						if holds(part, x, y) then
							hit = true
							break
						end
					end
				end
				if hit then
					pressed(entry)
					return
				end
			end
		end
	end

	local function hook(delta: number)
		hooked += delta
		local off = offPress
		if hooked > 0 and off == nil then
			offPress = GlobalInput.connect(Input.service(), "InputBegan", onPress)
		elseif hooked == 0 and off ~= nil then
			offPress = nil
			off()
		end
	end

	local focusedOut: State<number> = focusedId
	local layoutState: State<WindowLayout> = layoutOut
	local manager: Manager = {
		Focused = focusedOut,
		Layout = layoutState,
		ExportLayout = function(_self: Manager): WindowLayout
			layoutUsed = true
			noticeKeyless()
			return Layout.build(known, stateOf, holders())
		end,
		ImportLayout = function(_self: Manager, layout: WindowLayout, factories: { [string]: (key: string) -> () }?)
			local keys, states = Layout.read("WindowManager:ImportLayout", layout)
			if factories ~= nil and type(factories) ~= "table" then
				Util.fail("WindowManager:ImportLayout", `factories must be a table \{ [Kind] = function(key) }, got {typeof(factories)}`)
			end
			-- check every entry up front: a bad one must fail whether or not this layout happens to need it
			if factories ~= nil then
				for kind, make in factories do
					if type(kind) ~= "string" or type(make) ~= "function" then
						Util.fail("WindowManager:ImportLayout", `factories must map a Kind string to a function(key), got [{typeof(kind)}] = {typeof(make)}`)
					end
				end
			end
			layoutUsed = true
			noticeKeyless()
			batch(function()
				-- any key without a window waits for it (known and pending together: an app Source that throws in the
				-- loop below leaves no known key without a state)
				for _, key in keys do
					remember(key)
					forgetting[key] = nil -- imported again: no longer forgotten (header LAYOUT)
					if live[key] == nil then
						pending[key] = states[key]
					end
				end
				-- an edge may change hands in one import (A goes left, B leaves it): every named window first lets go of an
				-- edge it will not keep, so the order of the keys never decides who gets one
				for _, key in keys do
					local entry = live[key]
					if entry ~= nil and entry.Side:Get() ~= states[key].Dock then
						entry.Side:SetIfChanged(nil)
					end
				end
				-- a window already on screen moves to its saved place (one an app Source destroyed meanwhile waits)
				for _, key in keys do
					local entry = live[key]
					if entry ~= nil then
						apply(entry, states[key])
					else
						pending[key] = states[key]
					end
				end
				-- the stacking after the moves (opening a closed window above raised it) and before the factories (a
				-- window a factory makes takes its place by `known` as it registers, so a factory that throws leaves
				-- the order applied)
				stackAs(keys)
				restack()
				layoutDirty = true
				-- "make the window of this identity exist": only for keys open when saved, never for a registered one;
				-- a Kind missing from the map stays pending (its window may come later)
				if factories ~= nil then
					for _, key in keys do
						local state = states[key]
						local make = factories[state.Kind]
						if state.Open and live[key] == nil and make ~= nil then
							make(key)
						end
					end
				end
			end)
		end,
		ExportWindow = function(_self: Manager, key: string): WindowState?
			if type(key) ~= "string" then
				Util.fail("WindowManager:ExportWindow", `key must be a string, got {typeof(key)}`)
			end
			layoutUsed = true
			noticeKeyless()
			local entry = live[key]
			if entry ~= nil then
				return snapshot(entry)
			end
			local waiting = pending[key]
			return if waiting ~= nil then Layout.copyState(waiting) else nil
		end,
		ImportWindow = function(_self: Manager, key: string, state: WindowState)
			if type(key) ~= "string" then
				Util.fail("WindowManager:ImportWindow", `key must be a string, got {typeof(key)}`)
			end
			local copy = Layout.readState("WindowManager:ImportWindow", state)
			layoutUsed = true
			noticeKeyless()
			batch(function()
				forgetting[key] = nil
				local entry = live[key]
				if entry ~= nil then
					apply(entry, copy)
				else
					remember(key)
					pending[key] = copy
				end
				layoutDirty = true
			end)
		end,
		ForgetWindow = function(_self: Manager, key: string)
			if type(key) ~= "string" then
				Util.fail("WindowManager:ForgetWindow", `key must be a string, got {typeof(key)}`)
			end
			layoutUsed = true
			noticeKeyless()
			if live[key] ~= nil then
				forgetting[key] = true -- dropped when its window goes away (Release)
			elseif pending[key] ~= nil then
				pending[key] = nil
				table.remove(known, table.find(known, key) :: number)
				refresh()
			end
		end,
		Register = function(_self: Manager): Slot
			nextId += 1
			local id = nextId
			local rank: Source<number> = q.Source(#order + 1)
			local entry: Entry = {
				Id = id,
				Rank = rank,
				Root = nil,
				Open = nil,
				Deco = nil,
				Hints = nil,
				Key = nil,
				Kind = "",
				Side = q.Source(nil :: Side?),
				DockWidth = q.Source(0),
			}
			table.insert(order, entry)
			local isFocused: State<boolean> = focusedId:Compute(function(self)
				return self:Get() == id
			end)
			local surfaceZ: State<number> = rank:Compute(function(self)
				return (self:Get() - 1) * SPAN + 2
			end)
			local visibleConn: RBXScriptConnection? = nil
			local parentConn: RBXScriptConnection? = nil

			-- the decoration follows the surface root's parent (it is placed as the root's sibling)
			local function follow()
				local root, deco = entry.Root, entry.Deco
				if root == nil or deco == nil or parentConn ~= nil then
					return
				end
				deco.SetParent(root.Parent)
				settle(entry)
				parentConn = root:GetPropertyChangedSignal("Parent"):Connect(function()
					deco.SetParent(root.Parent)
					settle(entry) -- moved to another container: a docked window walls that one now, a floating one meets its strips
				end)
			end

			local rootHook: Types.GuiHook = q.PostRef(nil :: GuiObject?)
			local slot: Slot
			rootHook:Callback(function(inst)
				if inst == nil or entry.Root ~= nil or table.find(order, entry) == nil then
					return
				end
				entry.Root = inst
				Compositor.bindRoot(inst, slot)
				hook(1)
				visibleConn = inst:GetPropertyChangedSignal("Visible"):Connect(function()
					Pointer.invalidate()
					if entry.Open ~= nil then
						return -- a decorated surface: its open state comes through the Compositor port
					end
					if inst.Visible then
						focus(entry) -- shown again: to the front with the focus (Dear ImGui focuses an appearing window)
					elseif focusedId:Get() == id then
						succeed()
					end
				end)
				follow()
			end)

			slot = {
				Id = id,
				ZIndex = surfaceZ,
				Focused = isFocused,
				Hook = rootHook,
				Focus = function(_slot: Slot)
					focus(entry)
				end,
				Blur = function(_slot: Slot)
					if focusedId:Get() == id then
						focusedId:Set(0)
					end
				end,
				Release = function(_slot: Slot)
					local at = table.find(order, entry)
					if at == nil then
						return
					end
					table.remove(order, at)
					renumber()
					Compositor.unbind(slot, entry.Root)
					if entry.Root ~= nil then
						entry.Root = nil
						local vc, pc = visibleConn, parentConn
						visibleConn = nil
						parentConn = nil
						if vc then
							vc:Disconnect()
						end
						if pc then
							pc:Disconnect()
						end
						hook(-1)
					end
					-- a keyed window that goes away leaves its last state pending (an app tearing its UI down and building
					-- it again gets its windows back where they were; the Layout output does not change, except when a
					-- docked window leaves its edge to another key that remembers it — below) — unless the app asked to
					-- forget it
					local key = entry.Key
					if key ~= nil and live[key] == entry then
						live[key] = nil
						if forgetting[key] then
							forgetting[key] = nil
							table.remove(known, table.find(known, key) :: number)
							refresh()
						else
							pending[key] = snapshot(entry)
						end
					end
					keyless[entry] = nil
					local record = lastPress
					if record ~= nil and record.Entry == entry then
						lastPress = nil
					end
					local deco = entry.Deco
					if deco ~= nil then
						entry.Deco = nil
						deco.Destroy()
					end
					if entry.Side:Get() ~= nil then
						refresh() -- a docked window left its edge: who is saved on that edge may change (header DOCK)
					end
					if focusedId:Get() == id then
						succeed()
					end
				end,
			}

			Compositor.bind(slot, {
				decorate = function(hints: Decoration.Hints): Decoration.Placement
					local key = hints.Key
					if key ~= nil then
						if live[key] ~= nil then
							slot:Release()
							return Util.fail(
								"Window",
								`Key "{key}" is already used by another window of this WindowManager (Key is the window's identity; give two windows of one type the same Kind and different Keys)`
							)
						end
						entry.Key = key
						entry.Kind = hints.Kind or key
						entry.Hints = hints
						-- a state waiting for this key (ImportLayout / ImportWindow before the window existed) is its
						-- initial state: written into its Sources before anything is built from them
						local waiting = pending[key]
						remember(key)
						live[key] = entry
						if waiting ~= nil then
							pending[key] = nil
							apply(entry, waiting)
						end
						-- its place among the keyed windows (header STACKING)
						restack()
					else
						entry.Hints = hints
						keyless[entry] = if type(hints.Title) == "string" then hints.Title else hints.Title:Get()
						noticeKeyless()
					end
					local backZ: State<number> = rank:Compute(function(self)
						return (self:Get() - 1) * SPAN + 1
					end)
					local frontZ: State<number> = rank:Compute(function(self)
						return self:Get() * SPAN
					end)
					local deco = Decoration.new(hints, {
						BackZ = backZ,
						FrontZ = frontZ,
						Focused = isFocused,
						Raise = function()
							focus(entry)
						end,
						Changed = if key ~= nil then refresh else nil,
						Side = entry.Side,
						DockWidth = entry.DockWidth,
						SideTaken = function(side: Side): boolean
							return occupant(side, entry) ~= nil
						end,
						-- (refresh also for a window without a Key: who holds an edge decides where the keyed windows that remember
						-- it are saved; an unchanged layout emits nothing)
						Dock = function(side: Side, width: number)
							entry.DockWidth:SetIfChanged(width)
							entry.Side:SetIfChanged(side)
							settle(entry)
							refresh()
						end,
						Undock = function()
							entry.Side:SetIfChanged(nil)
							refresh()
						end,
						Insets = function(): (number, number)
							return insets(entry)
						end,
						FocusedBeforePress = function(): boolean
							local record = lastPress
							lastPress = nil
							if record ~= nil and record.Entry == entry then
								return record.WasFocused
							end
							return isFocused:Get()
						end,
					})
					entry.Deco = deco
					entry.Open = hints.Open
					follow()
					if key ~= nil then
						refresh()
					end
					return deco.Surface
				end,
				setOpen = function(open: boolean)
					Pointer.invalidate()
					local wasDocked = entry.Side:Get() ~= nil
					if open then
						-- a docked window opening again goes back to its edge, unless another open window took it meanwhile: then it
						-- opens floating, at its kept Position / Size (header DOCK)
						local at = entry.Side:Get()
						if at ~= nil and occupant(at, entry) ~= nil then
							entry.Side:Set(nil)
						end
						settle(entry)
						focus(entry) -- opened (or asked again with `Open:Set(true)`): to the front with the focus
					elseif focusedId:Get() == id then
						succeed()
					end
					if wasDocked then
						refresh() -- an edge freed or taken again (see Dock above)
					end
				end,
				parts = function(): { Instance }
					local deco = entry.Deco
					return if deco ~= nil then table.clone(deco.Parts) else {}
				end,
			})
			return slot
		end,
	}
	-- the methods are public surface: a usage error inside them blames the app's calling line
	Util.tagSurface(manager)
	return manager
end

Manager.default = Manager.new()

return Manager
