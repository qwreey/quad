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
	Supports up to 333 live windows below the default Overlay layer (a tab group's windows keep a chunk each — header
	TABS). A drag's drop preview sits one value above the dragged (raised, so top) window's chunk or its group's tabs
	[Window/Decoration.luau headers "DOCKED", "TABS"].

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
	its dock width (header DOCK), its tab group (the node's tabs and selection, the group's rectangle, and the window's
	own kept rectangle — header TABS), and the stacking order of the keyed FLOATING groups (the export order). Not
	saved: the title, the content, the focus, the stacking of the docked groups.
		manager:ExportLayout() -> WindowLayout          every known key (live or pending): floating bottom first, docked
		                                                on its edge (`Left` / `Right`)
		manager:ImportLayout(layout, factories?)          put the windows where the layout says (rules below)
		manager:ExportWindow(key) -> WindowState?         one window's state (nil = an unknown key; no group membership —
		                                                other keys are involved, only ExportLayout carries it)
		manager:ImportWindow(key, state)                  one window: the same rules, no factory, no stacking (a
		                                                grouped window leaves its group first)
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
	differs. Per window the manager keeps the edge (`Side`, nil = floating) and the dock width; one OPEN window — or
	tab group, whose windows share the edge and width — per edge per manager (a drag to a held edge does not dock: it
	joins that group as a tab when it may, header TABS). Closing a docked window hides its panel and
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

	TABS [2026-10-21 user decisions — docking stage 3, tab groups; the look and the drags are in Window/Decoration.luau
	header "TABS"]. A GROUP is several windows sharing one rectangle and one decoration, only the selected one's surface
	shown. Nothing is reparented: the manager keeps a `Group` per group (its members in tab order — a live window or a
	pending key —, the selected one, the floating rectangle, Collapsed, the edge and dock width) and tells each window's
	decoration what it is in it (`GroupView`: the group's rectangle, whether it draws the group, its tab slot, the
	group's flags). The drawn window is the selected one when it is open (else the first open one); it is the focused
	window of the group (`Focused` / `slot.Focused`).
	- Forming: a drag of a window (or of a whole group, by its strip's empty area, all its tabs in order, or of a tab
	  torn out of one) released over another window's / group's title-bar row or centre, or over a held edge's band,
	  joins its group (made when it is a plain window: its rectangle, edge and Collapsed become the group's). Eligible:
	  the same manager and the same container (the surface roots' parent), both with a title bar (NoTitleBar never joins
	  nor is joined), the target open and expanded (an icon is no target; a dragged icon never joins), the dragged one
	  movable. NoDock does not stop joining [2026-10-21 user decision — it is edge docking only]. The window on top
	  under the pointer decides: when it cannot be joined (a NoTitleBar window, an icon, a hand-made root) it covers
	  what is beneath and nothing joins. The joined window is selected and the group raised and focused.
	- The rectangle is the group's: while grouped nothing writes a window's Position / Size Sources, which keep the
	  rectangle it had before it joined (its KEPT rectangle; a window grouped by a load gets it from the layout's
	  `Windows[key].Position` / `Size`, or has none). Moving / resizing / docking the group changes only the group.
	- Shared: Collapsed (writing any window's collapses the whole group — the manager spreads it; a collapsed floating
	  group is the drawn window's icon) and the edge. The dock width is shared only while the group is DOCKED: joining
	  a floating group leaves each window the dock width it keeps (header DOCK: docking again uses it), a floating group
	  docked by a drag takes its drawn window's drop width and then every window follows, and a window leaving a docked
	  group keeps the group's width. An import that docks a group stores the width that fits the container. Flags: a NoMove window stops the group's drag,
	  an OPEN NoResize window hides its grip, an OPEN NoCollapse window hides its collapse arrow; the resize floor is the
	  largest MinSize per axis.
	- Closing a tab hides it and keeps its slot (the window stays a member; the layout keeps it with `Open = false`); the
	  selection moves to the next open tab, else the previous one; a group whose windows are all closed is hidden.
	  `Open:Set(true)` brings the window back at its slot, selected, the group raised and focused; `Focused:Set(true)`
	  on an open hidden tab selects it too. A press on any part of a group focuses its drawn window (the tab's own press
	  selects).
	- Leaving: a tab torn out floats at its kept Size (the group's when it has none); `ImportWindow` takes a window out
	  first; a keyless window destroyed (or a forgotten key's) leaves; a keyed window destroyed stays a PENDING tab of
	  its group (rebuilding the UI brings it back to its tab). A group left with one member (open or closed, live or
	  pending) is no group: that window takes the group's rectangle into its own Position / Size and stays in place.
	- Stacking: a group is one LUMP — its windows sit next to each other in `order` (tab order, where its topmost one
	  was), keep a ZIndex chunk each (only the drawn one's parts show) and the tabs take the lump's top grip rank, so
	  nothing of another window interleaves; raising any window raises the lump. `known` keeps a group's keys together
	  the same way (the saved `Floating` order is the groups' stacking).
	- Saving (Window/Layout.luau): a group is a node with several tabs (keyed members only, in tab order; the selected
	  one, or the first keyed open one); `Windows[key].Position` / `Size` carry a member's kept rectangle when it has
	  one and the node keeps two or more tabs (a node the keyless windows leave with one tab is a plain window). A layout's node of several tabs makes a group of the windows it names (each named window first leaves its
	  group); a pending key joins its group at its saved slot when its window registers, and an open one cannot bring
	  its group onto an edge another open window / group holds (the group floats — the same rule as one window). The
	  joining rules hold there too: a named NoTitleBar window, or one whose surface root sits (or is later put) in
	  another container than the group's, is placed as a plain window as if alone in its node (its own rectangle, else
	  the node's) and leaves the group; with fewer than two windows left there is no group. An import opens windows
	  without selecting or focusing them (header STACKING).

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
	window is closed or released, the topmost window still open is focused (and raised); none left = `Focused` 0. A
	group counts as one window (its drawn one): closing the focused tab leaves the focus with the group when another
	of its tabs is open.
	"Open" is the window's own state, told by Window through the Compositor port (`Open`), NOT its root's `Visible`:
	the surface root is also hidden while collapsed (and while another surface of its tab group is shown), and
	that must not pass the focus on. Still open = open AND its container on screen (shown, ancestors shown, in a
	placed LayerCollector). An undecorated window (a hand-made root) keeps the older rule: its root's `Visible` going
	false is a close, and "still open" = its root on screen. A closed window keeps its slot; when it is opened again
	it comes to the front WITH the focus (Dear ImGui focuses an appearing window — user decision 2026-10-15), except
	when a layout import opens it (header STACKING: an import moves nothing to the front). A window
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
type GroupView = Decoration.GroupView

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
	-- the tab group (header TABS): nil = a plain window; View = what its decoration is told
	Group: Group?,
	View: Source<GroupView?>,
	-- its Position / Size Sources hold a rectangle of its own (false: grouped by a load that did not carry one — it
	-- leaves its group at the group's Size)
	KeptRect: boolean,
}

-- one tab of a group: a live window, or a key whose window is not registered (pending)
type Member = { Key: string?, Entry: Entry? }

-- a tab group (header TABS): one rectangle, one edge, one Collapsed for all its windows
type Group = {
	Members: { Member }, -- tab order
	Selected: Member,
	Position: UDim2, -- the group's floating outer rectangle
	Size: Vector2,
	Collapsed: boolean,
	Side: Side?,
	Width: number,
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

local function sameView(a: GroupView?, b: GroupView?): boolean
	if a == nil or b == nil then
		return a == b
	end
	for k, v in a :: any do
		if (b :: any)[k] ~= v then
			return false
		end
	end
	for k in b :: any do
		if (a :: any)[k] == nil then
			return false
		end
	end
	return true
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

	-- TABS (header TABS): the live groups, and the group of each pending key that is a tab of one
	local groups: { [Group]: true } = {}
	local pendingGroup: { [string]: Group } = {}
	-- > 0 while the manager writes a group's shared facts into its windows (their Sync must not echo them back)
	local quiet = 0
	-- > 0 while an import writes states: opening a window then neither selects nor focuses it (header STACKING: an
	-- import moves nothing to the front)
	local importing = 0
	-- the Layout output's flush (`refresh`, defined below): pushView holds the output back while it writes the views
	local flushLayout: () -> ()

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

	-- ── groups (header TABS) ──────────────────────────────────────────────────────────────────────────────────────

	local function isOpenWindow(e: Entry?): boolean
		local h = if e ~= nil then e.Hints else nil
		return h ~= nil and h.Open:Get()
	end

	local function memberOf(g: Group, e: Entry): Member?
		for _, m in g.Members do
			if m.Entry == e then
				return m
			end
		end
		return nil
	end

	-- the window that draws the group: the selected one when it is live and open, else the first open one, else the
	-- selected (closed: the whole group is hidden), else any live one
	local function drawnOf(g: Group): Entry?
		local selected = g.Selected.Entry
		if isOpenWindow(selected) then
			return selected
		end
		for _, m in g.Members do
			if isOpenWindow(m.Entry) then
				return m.Entry
			end
		end
		if selected ~= nil then
			return selected
		end
		for _, m in g.Members do
			if m.Entry ~= nil then
				return m.Entry
			end
		end
		return nil
	end

	-- the window a press or a focus of `e` means: its group's drawn one
	local function faceOf(e: Entry): Entry
		local g = e.Group
		return if g ~= nil then drawnOf(g) or e else e
	end

	-- the neighbour that takes the selection when a tab closes or leaves: the next open window from `nextFrom`, else
	-- the previous open one from `prevFrom` down, else the member now there (the group stays hidden)
	local function neighbour(g: Group, nextFrom: number, prevFrom: number): Member
		for i = nextFrom, #g.Members do
			if isOpenWindow(g.Members[i].Entry) then
				return g.Members[i]
			end
		end
		for i = prevFrom, 1, -1 do
			if isOpenWindow(g.Members[i].Entry) then
				return g.Members[i]
			end
		end
		return g.Members[math.clamp(nextFrom, 1, #g.Members)]
	end

	local function groupOfKey(key: string): Group?
		local entry = live[key]
		if entry ~= nil then
			return entry.Group
		end
		return pendingGroup[key]
	end

	-- the resize floor of one window (header TABS: a group's is the largest of its windows' per axis)
	local function floorOf(e: Entry): Vector2
		local h = e.Hints :: Decoration.Hints
		local min = h.MinSize
		if min ~= nil then
			return min
		end
		local fh = h.Style.FrameHeight:Get() * 2
		return Vector2.new(fh, fh)
	end

	-- tell every window of `g` where the group is and what it is in it. Every window's view change re-judges the
	-- layout (its decoration's Changed): held back and flushed once, so a group drag rebuilds the layout once per move
	local writeViews: (g: Group) -> ()
	local function pushView(g: Group)
		if not groups[g] then
			return
		end
		batching += 1
		local ok, err = pcall(function()
			writeViews(g)
		end)
		batching -= 1
		if batching == 0 and layoutDirty then
			flushLayout()
		end
		if not ok then
			error(err, 0)
		end
	end
	writeViews = function(g: Group)
		local drawn = drawnOf(g)
		local shown: { Entry } = {}
		local top = 0
		local noMove, noResize, noCollapse, noDock = false, false, false, false
		for _, m in g.Members do
			local e = m.Entry
			if e ~= nil then
				local h = e.Hints :: Decoration.Hints
				top = math.max(top, e.Rank:Get())
				noMove = noMove or h.NoMove
				noDock = noDock or h.NoDock
				if h.Open:Get() then
					table.insert(shown, e)
					noResize = noResize or h.NoResize
					noCollapse = noCollapse or h.NoCollapse
				end
			end
		end
		local tabbed = #shown >= 2
		for _, m in g.Members do
			local e = m.Entry
			if e ~= nil then
				local at = table.find(shown, e)
				local nextView: GroupView = {
					Position = g.Position,
					Size = g.Size,
					Drawn = e == drawn,
					Tabbed = tabbed,
					TabIndex = if tabbed and at ~= nil then at - 1 else nil,
					TabCount = #shown,
					TabZ = top * SPAN,
					NoMove = noMove,
					NoResize = noResize,
					NoCollapse = noCollapse,
					NoDock = noDock,
				}
				if not sameView(e.View:Get(), nextView) then
					e.View:Set(nextView)
				end
			end
		end
	end

	-- `e` takes `g`'s shared facts (its edge, Collapsed, and the dock width while the group is docked — a floating
	-- group leaves each window the dock width it keeps) and joins it (no echo through Sync)
	local function adopt(e: Entry, g: Group)
		local h = e.Hints :: Decoration.Hints
		quiet += 1
		e.Group = g
		e.Side:SetIfChanged(g.Side)
		if g.Side ~= nil then
			e.DockWidth:SetIfChanged(g.Width)
		end
		h.Collapsed:SetIfChanged(g.Collapsed)
		quiet -= 1
	end

	-- a new group of one window (a drag is about to join it): its rectangle, edge and Collapsed become the group's
	local function newGroup(target: Entry): Group
		local h = target.Hints :: Decoration.Hints
		local m: Member = { Key = liveKey(target), Entry = target }
		local g: Group = {
			Members = { m },
			Selected = m,
			Position = h.Position:Get(),
			Size = h.Size:Get(),
			Collapsed = h.Collapsed:Get(),
			Side = target.Side:Get(),
			Width = target.DockWidth:Get(),
		}
		groups[g] = true
		target.KeptRect = true
		target.Group = g
		return g
	end

	-- a group left with one window (open or closed, live or pending) is no group: that window takes the group's
	-- rectangle into its own Position / Size (it stays where it was) and its edge, and is a plain window again
	local function dissolveIfSmall(g: Group): boolean
		if #g.Members >= 2 then
			return false
		end
		groups[g] = nil
		local m = g.Members[1]
		if m == nil then
			return true
		end
		local e = m.Entry
		if e ~= nil then
			local h = e.Hints :: Decoration.Hints
			quiet += 1
			e.Group = nil
			h.Position:SetIfChanged(g.Position)
			h.Size:SetIfChanged(g.Size)
			e.KeptRect = true
			e.View:Set(nil)
			quiet -= 1
		else
			local key = m.Key :: string
			pendingGroup[key] = nil
			local waiting = pending[key]
			if waiting ~= nil then
				-- a fresh table: a state is never written in place (an import's own state tables stay what it read)
				local st = Layout.copyState(waiting)
				st.Position = Layout.positionOf(g.Position)
				st.Size = Layout.sizeOf(g.Size)
				st.Collapsed = g.Collapsed
				st.Dock = g.Side
				st.DockWidth = if g.Side ~= nil then g.Width else nil
				pending[key] = st
			end
		end
		return true
	end

	-- drop member `at` of `g` (it left, or its window went away for good); the selection moves to a neighbour
	local function dropMember(g: Group, at: number)
		local m = table.remove(g.Members, at) :: Member
		if g.Selected == m and #g.Members > 0 then
			g.Selected = neighbour(g, at, at - 1)
		end
		if not dissolveIfSmall(g) then
			pushView(g)
		end
	end

	-- a live window leaves its group (a tab dragged out, ImportWindow / ImportLayout naming it). `float`: off the
	-- group's edge too. Without a rectangle of its own it takes the group's Size.
	local function leave(e: Entry, float: boolean)
		local g = e.Group
		if g == nil then
			return
		end
		local m = memberOf(g, e) :: Member
		local at = table.find(g.Members, m) :: number
		local h = e.Hints :: Decoration.Hints
		quiet += 1
		e.Group = nil
		if not e.KeptRect then
			h.Size:SetIfChanged(g.Size)
			e.KeptRect = true
		end
		if float then
			e.Side:SetIfChanged(nil)
		end
		e.View:Set(nil)
		quiet -= 1
		dropMember(g, at)
	end

	-- a pending key leaves its group
	local function leavePending(key: string)
		local g = pendingGroup[key]
		if g == nil then
			return
		end
		pendingGroup[key] = nil
		for i, m in g.Members do
			if m.Entry == nil and m.Key == key then
				dropMember(g, i)
				return
			end
		end
	end

	-- the group's edge (header DOCK: one group per edge); every window of it follows — and takes the group's dock
	-- width while it is docked (undocked, each keeps the width it had)
	local function setGroupSide(g: Group, side: Side?, width: number?)
		g.Side = side
		if width ~= nil then
			g.Width = width
		end
		quiet += 1
		for _, m in g.Members do
			local e = m.Entry
			if e ~= nil then
				if side ~= nil then
					e.DockWidth:SetIfChanged(g.Width)
				end
				e.Side:SetIfChanged(side)
			end
		end
		quiet -= 1
	end

	-- the open window (or group) docked on `side` other than `except` and its group (header DOCK: one per edge)
	local function occupant(side: Side, except: Entry?): Entry?
		local exceptGroup = if except ~= nil then except.Group else nil
		for _, entry in order do
			local h = entry.Hints
			if entry ~= except and (exceptGroup == nil or entry.Group ~= exceptGroup) and h ~= nil and entry.Side:Get() == side and h.Open:Get() then
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
		if entry ~= nil then
			return snapshot(entry)
		end
		local st = pending[key]
		local g = pendingGroup[key]
		if g ~= nil then
			-- a pending tab: its group's shared facts
			local copy = Layout.copyState(st)
			copy.Collapsed = g.Collapsed
			copy.Dock = g.Side
			copy.DockWidth = if g.Side ~= nil then g.Width else nil
			return copy
		end
		return st
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

	-- a window of a group gets its saved state: the group's shared facts, its own kept rectangle when the state has
	-- one (header TABS — `Windows[key].Position` / `Size`), and its Open. The edge follows `apply`'s rule for the
	-- whole group: an OPEN window cannot bring its group onto an edge another open window / group holds — the group
	-- floats; a closed one keeps the edge remembered (header DOCK).
	local function applyMember(entry: Entry, state: WindowState, g: Group)
		local h = entry.Hints :: Decoration.Hints
		quiet += 1
		entry.Group = g
		h.Collapsed:SetIfChanged(g.Collapsed)
		local size, position = state.Size, state.Position
		if size ~= nil then
			h.Size:SetIfChanged(Layout.toSize(size))
		end
		if position ~= nil then
			h.Position:SetIfChanged(Layout.toPosition(position))
		end
		entry.KeptRect = size ~= nil
		local side = g.Side
		if side ~= nil then
			-- the width that fits this container is the group's (exported as it shows)
			local deco = entry.Deco
			if deco ~= nil then
				g.Width = deco.FitDockWidth(g.Width)
			end
			entry.DockWidth:SetIfChanged(g.Width)
			if state.Open and occupant(side, entry) ~= nil then
				setGroupSide(g, nil, nil)
			end
		end
		entry.Side:SetIfChanged(g.Side)
		quiet -= 1
		h.Open:SetIfChanged(state.Open)
	end

	-- a window of a layout node (or a pending tab) that cannot be a tab (header TABS: NoTitleBar, another container)
	-- is placed as if alone in its node: its own rectangle when it has one, else the node's, and the node's edge
	local function plainState(st: WindowState, position: { number }?, size: { number }?, collapsed: boolean, side: Side?, width: number?): WindowState
		local out = Layout.copyState(st)
		out.Position = if st.Position ~= nil then table.clone(st.Position) elseif position ~= nil then table.clone(position) else nil
		out.Size = if st.Size ~= nil then table.clone(st.Size) elseif size ~= nil then table.clone(size) else nil
		out.Collapsed = collapsed
		out.Dock = side
		out.DockWidth = if side ~= nil then width else nil
		return out
	end

	-- `e` may be a tab of a group whose windows sit in `container` (nil = not known yet)
	local function groupable(e: Entry, container: Instance?): boolean
		local h, root = e.Hints, e.Root
		if h == nil or h.NoTitleBar then
			return false
		end
		local parent = if root ~= nil then root.Parent else nil
		return container == nil or parent == nil or parent == container
	end

	-- the unit saved on each edge: the open group / window there (none when it has no Key), else the topmost known
	-- key whose state (or group) remembers that edge; every other unit remembering an edge is saved as floating
	local function holders(): { [Side]: any }
		local out: { [Side]: any } = {}
		for _, side: Side in { "Left" :: Side, "Right" :: Side } do
			local holder = occupant(side, nil)
			if holder ~= nil then
				local g = holder.Group
				if g ~= nil then
					out[side] = g
				else
					local key = liveKey(holder)
					if key ~= nil then
						out[side] = key
					end
				end
			else
				for i = #known, 1, -1 do
					local key = known[i]
					local g = groupOfKey(key)
					local dock = if g ~= nil then g.Side else stateOf(key).Dock
					if dock == side then
						out[side] = g or key
						break
					end
				end
			end
		end
		return out
	end

	-- a group as a saved unit: its keyed windows in tab order (nil when it has none)
	local function unitOfGroup(g: Group): Layout.Unit?
		local tabs: { string } = {}
		local windows: { [string]: Layout.WindowEntry } = {}
		local kept: { [string]: boolean } = {}
		local firstOpen: string? = nil
		for _, m in g.Members do
			local key = m.Key
			if key ~= nil then
				table.insert(tabs, key)
				local st = stateOf(key)
				local w: Layout.WindowEntry = { Kind = st.Kind, Open = st.Open }
				local e = m.Entry
				kept[key] = if e ~= nil then e.KeptRect else (st.Position ~= nil and st.Size ~= nil)
				windows[key] = w
				if firstOpen == nil and st.Open then
					firstOpen = key
				end
			end
		end
		if #tabs == 0 then
			return nil
		end
		-- a tab's own rectangle (header TABS): only in a saved node of several tabs (a node the keyless windows leave
		-- with one tab loads as a plain window at the node's rectangle), and only a window that has one
		if #tabs >= 2 then
			for key, w in windows do
				if kept[key] then
					local st = stateOf(key)
					w.Position = st.Position
					w.Size = st.Size
				end
			end
		end
		return {
			Tabs = tabs,
			Selected = g.Selected.Key or firstOpen or tabs[1],
			Windows = windows,
			Collapsed = g.Collapsed,
			Position = Layout.positionOf(g.Position),
			Size = Layout.sizeOf(g.Size),
			Dock = g.Side,
			Width = if g.Side ~= nil then g.Width else nil,
		}
	end

	local function unitOfKey(key: string): Layout.Unit
		local s = stateOf(key)
		return {
			Tabs = { key },
			Selected = key,
			Windows = { [key] = { Kind = s.Kind, Open = s.Open } },
			Collapsed = s.Collapsed,
			Position = s.Position,
			Size = s.Size,
			Dock = s.Dock,
			Width = s.DockWidth,
		}
	end

	local function build(): WindowLayout
		local tokens = holders()
		local units: { Layout.Unit } = {}
		local byToken: { [any]: Layout.Unit } = {}
		local seen: { [Group]: true } = {}
		for _, key in known do
			local g = groupOfKey(key)
			if g ~= nil then
				if not seen[g] then
					seen[g] = true
					local unit = unitOfGroup(g)
					if unit ~= nil then
						table.insert(units, unit)
						byToken[g] = unit
					end
				end
			else
				local unit = unitOfKey(key)
				table.insert(units, unit)
				byToken[key] = unit
			end
		end
		local holderUnits: { [Side]: Layout.Unit } = {}
		for side, token in tokens do
			local unit = byToken[token]
			if unit ~= nil then
				holderUnits[side] = unit
			end
		end
		return Layout.build(units, holderUnits)
	end

	local function refresh()
		if batching > 0 then
			layoutDirty = true
			return
		end
		layoutDirty = false
		local nextLayout = build()
		if not Layout.same(nextLayout, layoutOut:Get()) then
			layoutOut:Set(Layout.freeze(nextLayout))
		end
	end

	flushLayout = refresh

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

	-- an import's batch: opening a window there neither selects nor focuses it (header STACKING)
	local function importBatch(body: () -> ())
		importing += 1
		local ok, err = pcall(batch, body)
		importing -= 1
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

	-- a group stacks as one lump (header TABS): its live windows sit together, in tab order, where its topmost one is
	local function gatherOrder()
		if next(groups) == nil then
			return
		end
		local topOf: { [Group]: number } = {}
		for i, e in order do
			local g = e.Group
			if g ~= nil then
				topOf[g] = i
			end
		end
		local out: { Entry } = {}
		for i, e in order do
			local g = e.Group
			if g == nil then
				table.insert(out, e)
			elseif topOf[g] == i then
				for _, m in g.Members do
					if m.Entry ~= nil then
						table.insert(out, m.Entry)
					end
				end
			end
		end
		for i, e in out do
			order[i] = e
		end
	end

	-- the same for the saved order: a group's keys sit together where its topmost key is
	local function gatherKnown()
		local topOf: { [Group]: number } = {}
		for i, key in known do
			local g = groupOfKey(key)
			if g ~= nil then
				topOf[g] = i
			end
		end
		if next(topOf) == nil then
			return
		end
		local out: { string } = {}
		for i, key in known do
			local g = groupOfKey(key)
			if g == nil then
				table.insert(out, key)
			elseif topOf[g] == i then
				for _, m in g.Members do
					local k = m.Key
					if k ~= nil and (live[k] ~= nil or pending[k] ~= nil) then
						table.insert(out, k)
					end
				end
			end
		end
		known = out
	end

	local function renumber()
		gatherOrder()
		for i, entry in order do
			entry.Rank:SetIfChanged(i)
		end
		-- (the tabs' ZIndex is the group's top rank)
		for g in groups do
			pushView(g)
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

	-- raise to the top with the focus. A window of a group raises the whole group; an OPEN window that is not the
	-- group's drawn one is selected first (an explicit ask for it: `Open:Set(true)`, `Focused:Set(true)`, its tab)
	local function focus(target: Entry)
		local entry = target
		local g = entry.Group
		if g ~= nil then
			if drawnOf(g) ~= entry and isOpenWindow(entry) then
				g.Selected = memberOf(g, entry) :: Member
				pushView(g)
				refresh()
			end
			entry = drawnOf(g) or entry
		end
		local topEntry = order[#order]
		local onTop = topEntry == entry or (g ~= nil and topEntry ~= nil and topEntry.Group == g)
		if focusedId:Get() == entry.Id and onTop then
			return -- already focused AND on top (a newer registration may cover a focused window)
		end
		if table.find(order, entry) == nil then
			return -- released
		end
		local lump: { Entry } = {}
		if g ~= nil then
			for _, m in g.Members do
				if m.Entry ~= nil then
					table.insert(lump, m.Entry)
				end
			end
		else
			lump = { entry }
		end
		for _, e in lump do
			local at = table.find(order, e)
			if at ~= nil then
				table.remove(order, at)
			end
		end
		for _, e in lump do
			table.insert(order, e)
		end
		renumber()
		-- a keyed window raised: its key goes to the top of the saved order (header STACKING), a group's keys together
		-- (its pending tabs' too)
		local keys: { string } = {}
		if g ~= nil then
			for _, m in g.Members do
				local key = m.Key
				if key ~= nil and table.find(known, key) ~= nil then
					table.insert(keys, key)
				end
			end
		else
			local key = liveKey(entry)
			if key ~= nil then
				table.insert(keys, key)
			end
		end
		local n = #keys
		local already = n > 0 and #known >= n
		if already then
			for i = 1, n do
				if known[#known - n + i] ~= keys[i] then
					already = false
					break
				end
			end
		end
		if n > 0 and not already then
			for _, key in keys do
				table.remove(known, table.find(known, key) :: number)
			end
			for _, key in keys do
				table.insert(known, key)
			end
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

	-- the focused window went away (closed or released): the topmost window still open takes the focus (a group is one
	-- window: its drawn one)
	local function succeed()
		for i = #order, 1, -1 do
			local target = faceOf(order[i])
			if isOpen(target) then
				focus(target)
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

	-- a press went to `entry`: remember whether it had the focus before (the strip rule), then focus it. A press on
	-- any part of a group (a tab included) focuses the group's drawn window: selecting a tab is the tab's own press
	local function pressed(entry: Entry)
		local target = faceOf(entry)
		lastPress = { Entry = target, WasFocused = focusedId:Get() == target.Id }
		focus(target)
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

	-- a tab whose surface root is put in another container than its group's other windows (an import or a pending
	-- tab grouped it before its root had a parent, or the app moved it) leaves the group as a plain window: its own
	-- kept rectangle, or the group's (header TABS)
	local function leaveIfElsewhere(e: Entry)
		local g, root = e.Group, e.Root
		local container = if root ~= nil then root.Parent else nil
		if g == nil or container == nil then
			return
		end
		for _, m in g.Members do
			local other = m.Entry
			local otherRoot = if other ~= nil then other.Root else nil
			local otherContainer = if otherRoot ~= nil then otherRoot.Parent else nil
			if other ~= e and otherContainer ~= nil and otherContainer ~= container then
				local h = e.Hints :: Decoration.Hints
				if not e.KeptRect then
					h.Position:SetIfChanged(g.Position)
				end
				leave(e, true)
				renumber()
				refresh()
				return
			end
		end
	end

	-- ── joining (header TABS) ─────────────────────────────────────────────────────────────────────────────────────

	-- `e` may be joined by a drag from `container`: a decorated window with a title bar there, open, expanded, drawn
	local function joinable(e: Entry, container: Instance): boolean
		local h, deco, root = e.Hints, e.Deco, e.Root
		if h == nil or deco == nil or root == nil or h.NoTitleBar or root.Parent ~= container then
			return false
		end
		if not h.Open:Get() or h.Collapsed:Get() then
			return false
		end
		local g = e.Group
		return g == nil or drawnOf(g) == e
	end

	-- the window / group under the pointer a drag of `entry` would join, and how (header TABS)
	local function dropAt(entry: Entry, x: number, y: number): Decoration.Drop?
		local root = entry.Root
		local container = if root ~= nil then root.Parent else nil
		if container == nil then
			return nil
		end
		local own = entry.Group
		-- the first window from the top with something on screen under the pointer decides (its drawn frame, tabs,
		-- icon, strip or surface; a group's hidden windows show nothing): only a joinable one is judged, anything else
		-- covers what is under it
		for i = #order, 1, -1 do
			local e = order[i]
			local eRoot = e.Root
			if e ~= entry and (own == nil or e.Group ~= own) and eRoot ~= nil and eRoot.Parent == container then
				local hit = holds(eRoot, x, y)
				local deco = e.Deco
				if not hit and deco ~= nil then
					for _, part in deco.Parts do
						if holds(part, x, y) then
							hit = true
							break
						end
					end
				end
				if hit then
					if deco == nil or not joinable(e, container) or not holds(deco.Frame, x, y) then
						return nil
					end
					local f = deco.Frame
					local p, s = f.AbsolutePosition, f.AbsoluteSize
					if y < p.Y + deco.RowHeight() then
						return { Target = e, Index = deco.InsertAt(x), Frame = f }
					end
					local fx, fy = (x - p.X) / s.X, (y - p.Y) / s.Y
					local lo, hi = Decoration.CENTRE_LO, Decoration.CENTRE_HI
					if fx >= lo and fx <= hi and fy >= lo and fy <= hi then
						return { Target = e, Index = nil, Frame = f }
					end
					return nil -- a band: kept for splits
				end
			end
		end
		return nil
	end

	-- the group holding `side` (header TABS: a held edge joins), when a drag of `entry` may join it
	local function edgeJoin(entry: Entry, side: Side): Decoration.Drop?
		local root = entry.Root
		local container = if root ~= nil then root.Parent else nil
		local holder = occupant(side, entry)
		if holder == nil or container == nil then
			return nil
		end
		local target = faceOf(holder)
		if not joinable(target, container) then
			return nil
		end
		return { Target = target, Index = nil, Frame = (target.Deco :: Decoration.Decoration).Frame }
	end

	-- the position in `g.Members` before the `index`-th shown (open, live) tab; nil or past the last = the end
	local function insertionPoint(g: Group, index: number?): number
		if index == nil then
			return #g.Members + 1
		end
		local shownAt = 0
		for i, m in g.Members do
			if isOpenWindow(m.Entry) then
				if shownAt == index then
					return i
				end
				shownAt += 1
			end
		end
		return #g.Members + 1
	end

	-- `entry` (a window, or the whole group it draws) joins the target's group (made when the target is plain)
	local function join(entry: Entry, drop: Decoration.Drop)
		local target: Entry = drop.Target
		local from = entry.Group
		if target == entry or (from ~= nil and target.Group == from) or table.find(order, target) == nil then
			return
		end
		local moving: { Member }
		local selected: Member
		if from ~= nil then
			-- a whole group joins with all its tabs in order
			moving = from.Members
			selected = memberOf(from, faceOf(entry)) or from.Selected
			groups[from] = nil
			for _, m in moving do
				local e = m.Entry
				if e ~= nil then
					e.Group = nil
				else
					pendingGroup[m.Key :: string] = nil
				end
			end
		else
			local alone: Member = { Key = liveKey(entry), Entry = entry }
			selected = alone
			moving = { alone }
			entry.KeptRect = true
		end
		local g = target.Group or newGroup(target)
		local at = insertionPoint(g, drop.Index)
		for i, m in moving do
			table.insert(g.Members, at + i - 1, m)
		end
		for _, m in moving do
			local e = m.Entry
			if e ~= nil then
				adopt(e, g)
			else
				pendingGroup[m.Key :: string] = g
			end
		end
		g.Selected = selected
		gatherKnown()
		renumber()
		local face = drawnOf(g)
		if face ~= nil then
			focus(face)
		end
		refresh()
	end

	local focusedOut: State<number> = focusedId
	local layoutState: State<WindowLayout> = layoutOut
	local manager: Manager = {
		Focused = focusedOut,
		Layout = layoutState,
		ExportLayout = function(_self: Manager): WindowLayout
			layoutUsed = true
			noticeKeyless()
			return build()
		end,
		ImportLayout = function(_self: Manager, layout: WindowLayout, factories: { [string]: (key: string) -> () }?)
			local keys, states, nodes = Layout.read("WindowManager:ImportLayout", layout)
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
			importBatch(function()
				-- every named key leaves the group it is in: the layout says where it goes (a group left with one
				-- window it does not name becomes that plain window, where it was). First, before any of this layout's
				-- states is stored: a group dissolving here writes the window it leaves behind, never a state this
				-- import hands in.
				for _, key in keys do
					local entry = live[key]
					if entry ~= nil then
						leave(entry, false)
					else
						leavePending(key)
					end
				end
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
				-- one key placed as a plain window (a node of one tab, or a window that cannot be a tab)
				local function place(key: string, state: WindowState)
					local entry = live[key]
					if entry ~= nil then
						apply(entry, state)
					else
						pending[key] = state
					end
				end
				-- a window already on screen moves to its saved place (one an app Source destroyed meanwhile waits); a
				-- node of several tabs becomes a group (header TABS) of the windows that may be tabs together
				for _, node in nodes do
					if #node.Tabs == 1 then
						place(node.Tabs[1], states[node.Tabs[1]])
						continue
					end
					-- the group's container: its selected window's when on screen, else the first one's
					local container: Instance? = nil
					local order_ = { node.Selected }
					for _, key in node.Tabs do
						table.insert(order_, key)
					end
					for _, key in order_ do
						local e = live[key]
						local root = if e ~= nil then e.Root else nil
						if e ~= nil and groupable(e, nil) and root ~= nil and root.Parent ~= nil then
							container = root.Parent
							break
						end
					end
					local tabs: { string } = {}
					local loose: { string } = {}
					for _, key in node.Tabs do
						local e = live[key]
						if e == nil or groupable(e, container) then
							table.insert(tabs, key)
						else
							table.insert(loose, key)
						end
					end
					if #tabs < 2 then
						for _, key in tabs do
							table.insert(loose, key)
						end
						tabs = {}
					end
					for _, key in loose do
						place(key, plainState(states[key], node.Position, node.Size, node.Collapsed, node.Dock, node.Width))
					end
					if #tabs == 0 then
						continue
					end
					local fallback: Entry? = nil
					for _, key in tabs do
						fallback = fallback or live[key]
					end
					local fh = if fallback ~= nil then fallback.Hints else nil
					local nodePosition, nodeSize = node.Position, node.Size
					local g: Group = {
						Members = {},
						Selected = nil :: any,
						-- (an edge group without a floating rectangle: a window's own, or Window's default)
						Position = if nodePosition ~= nil
							then Layout.toPosition(nodePosition)
							elseif fh ~= nil then fh.Position:Get()
							else Layout.toPosition(Layout.DEFAULT_POSITION),
						Size = if nodeSize ~= nil
							then Layout.toSize(nodeSize)
							elseif fh ~= nil then fh.Size:Get()
							else Layout.toSize(Layout.DEFAULT_SIZE),
						Collapsed = node.Collapsed,
						Side = node.Dock,
						Width = node.Width or 0,
					}
					local selected: Member? = nil
					for _, key in tabs do
						local m: Member = { Key = key, Entry = live[key] }
						table.insert(g.Members, m)
						if key == node.Selected then
							selected = m
						end
					end
					g.Selected = selected or g.Members[1]
					groups[g] = true
					for _, m in g.Members do
						local e = m.Entry
						if e ~= nil then
							e.Group = g
						else
							pendingGroup[m.Key :: string] = g
						end
					end
					-- (applyMember keeps an open group off an edge another open window / group holds — header DOCK)
					for _, m in g.Members do
						local e = m.Entry
						if e ~= nil then
							applyMember(e, states[m.Key :: string], g)
						end
					end
					-- every window on the group's (fitted) dock width
					if g.Side ~= nil then
						setGroupSide(g, g.Side, g.Width)
					end
					pushView(g)
					for _, m in g.Members do
						if m.Entry ~= nil then
							settle(m.Entry)
						end
					end
				end
				-- the stacking after the moves and before the factories (a window a factory makes takes its place by
				-- `known` as it registers, so a factory that throws leaves the order applied)
				stackAs(keys)
				gatherKnown()
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
			if pending[key] ~= nil then
				return Layout.copyState(stateOf(key))
			end
			return nil
		end,
		ImportWindow = function(_self: Manager, key: string, state: WindowState)
			if type(key) ~= "string" then
				Util.fail("WindowManager:ImportWindow", `key must be a string, got {typeof(key)}`)
			end
			local copy = Layout.readState("WindowManager:ImportWindow", state)
			layoutUsed = true
			noticeKeyless()
			importBatch(function()
				forgetting[key] = nil
				local entry = live[key]
				-- a window's own state knows no group: a grouped window leaves its group first (header TABS), and
				-- out of its lump (its ZIndex no longer between its old group's)
				if entry ~= nil then
					leave(entry, false)
					renumber()
					apply(entry, copy)
				else
					leavePending(key)
					remember(key)
					pending[key] = copy
				end
				gatherKnown()
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
				leavePending(key)
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
				Group = nil,
				View = q.Source(nil :: GroupView?),
				KeptRect = true,
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
				leaveIfElsewhere(entry)
				settle(entry)
				parentConn = root:GetPropertyChangedSignal("Parent"):Connect(function()
					deco.SetParent(root.Parent)
					leaveIfElsewhere(entry) -- a tab put in another container than its group's is no tab (header TABS)
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
					-- forget it. A keyed tab stays a (pending) tab of its group; any other leaves it (header TABS).
					local key = entry.Key
					local g = entry.Group
					local stays = false
					if key ~= nil and live[key] == entry then
						live[key] = nil
						if forgetting[key] then
							forgetting[key] = nil
							table.remove(known, table.find(known, key) :: number)
							refresh()
						else
							local st = snapshot(entry)
							if g ~= nil and not entry.KeptRect then
								st.Position = nil
								st.Size = nil
							end
							pending[key] = st
							stays = g ~= nil
						end
					end
					if g ~= nil then
						entry.Group = nil
						local m = memberOf(g, entry) :: Member
						if stays then
							m.Entry = nil
							pendingGroup[key :: string] = g
							pushView(g)
						else
							dropMember(g, table.find(g.Members, m) :: number)
						end
						refresh()
					end
					renumber()
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
						-- initial state: written into its Sources before anything is built from them. A pending tab
						-- takes its place in its group (header TABS).
						local waiting = pending[key]
						remember(key)
						live[key] = entry
						if waiting ~= nil then
							pending[key] = nil
							local g = pendingGroup[key]
							if g ~= nil and hints.NoTitleBar then
								-- a window that cannot be a tab (header TABS) is placed as if alone in its node, and
								-- its tab is dropped
								local plain = plainState(waiting, Layout.positionOf(g.Position), Layout.sizeOf(g.Size), g.Collapsed, g.Side, g.Width)
								leavePending(key)
								apply(entry, plain)
							elseif g ~= nil then
								pendingGroup[key] = nil
								for _, m in g.Members do
									if m.Entry == nil and m.Key == key then
										m.Entry = entry
										break
									end
								end
								applyMember(entry, waiting, g)
							else
								apply(entry, waiting)
							end
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
						-- it are saved; an unchanged layout emits nothing). A group docks and undocks as one.
						Dock = function(side: Side, width: number)
							local g = entry.Group
							if g ~= nil then
								setGroupSide(g, side, width)
								pushView(g)
							else
								entry.DockWidth:SetIfChanged(width)
								entry.Side:SetIfChanged(side)
							end
							settle(entry)
							refresh()
						end,
						Undock = function()
							local g = entry.Group
							if g ~= nil then
								setGroupSide(g, nil, nil)
								pushView(g)
							else
								entry.Side:SetIfChanged(nil)
							end
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
						Group = entry.View,
						SetRect = function(position: UDim2?, size: Vector2?)
							local g = entry.Group
							if g == nil then
								return
							end
							if position ~= nil then
								g.Position = position
							end
							if size ~= nil then
								g.Size = size
							end
							pushView(g)
						end,
						MinSize = function(): Vector2
							local g = entry.Group
							if g == nil then
								return floorOf(entry)
							end
							local x, y = 0, 0
							for _, m in g.Members do
								local e = m.Entry
								if e ~= nil then
									local f = floorOf(e)
									x, y = math.max(x, f.X), math.max(y, f.Y)
								end
							end
							return Vector2.new(x, y)
						end,
						DropAt = function(x: number, y: number): Decoration.Drop?
							return dropAt(entry, x, y)
						end,
						EdgeJoin = function(side: Side): Decoration.Drop?
							return edgeJoin(entry, side)
						end,
						Join = function(drop: Decoration.Drop)
							join(entry, drop)
						end,
						SelectTab = function()
							local g = entry.Group
							if g ~= nil and isOpenWindow(entry) then
								focus(entry)
							end
						end,
						MoveTab = function(index: number)
							local g = entry.Group
							if g == nil then
								return
							end
							local m = memberOf(g, entry) :: Member
							local from = table.find(g.Members, m) :: number
							table.remove(g.Members, from)
							local at = insertionPoint(g, index)
							table.insert(g.Members, at, m)
							if at ~= from then
								gatherKnown()
								renumber()
								refresh()
							end
						end,
						DetachTab = function()
							leave(entry, true)
							renumber()
							refresh()
						end,
						Sync = function()
							local g = entry.Group
							if quiet > 0 or g == nil then
								return
							end
							-- (the dock width is the group's only while it is docked)
							local docked = g.Side ~= nil
							local c = hints.Collapsed:Get()
							local w = if docked then entry.DockWidth:Get() else g.Width
							if c == g.Collapsed and w == g.Width then
								return
							end
							g.Collapsed = c
							g.Width = w
							quiet += 1
							for _, m in g.Members do
								local e = m.Entry
								if e ~= nil and e ~= entry then
									(e.Hints :: Decoration.Hints).Collapsed:SetIfChanged(c)
									if docked then
										e.DockWidth:SetIfChanged(w)
									end
								end
							end
							quiet -= 1
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
					local g = entry.Group
					if g ~= nil then
						local m = memberOf(g, entry) :: Member
						if open then
							-- back in its group at its tab, selected (header TABS; an import selects nothing — its saved
							-- selection stands); a group whose edge another one took while all its windows were closed opens
							-- floating
							if importing == 0 then
								g.Selected = m
							end
							local at = g.Side
							if at ~= nil and occupant(at, entry) ~= nil then
								setGroupSide(g, nil, nil)
							end
						elseif g.Selected == m then
							local i = table.find(g.Members, m) :: number
							g.Selected = neighbour(g, i + 1, i - 1)
						end
						pushView(g)
					end
					if open then
						-- a docked window opening again goes back to its edge, unless another open window took it meanwhile: then it
						-- opens floating, at its kept Position / Size (header DOCK)
						local at = entry.Side:Get()
						if at ~= nil and occupant(at, entry) ~= nil then
							entry.Side:Set(nil)
						end
						settle(entry)
						-- opened (or asked again with `Open:Set(true)`): to the front with the focus — not when an import
						-- opened it (header STACKING: an import moves nothing to the front)
						if importing == 0 then
							focus(entry)
						end
					elseif focusedId:Get() == id then
						-- a closed tab leaves the focus with its group when another of its windows is open
						local face = if g ~= nil then drawnOf(g) else nil
						if face ~= nil and isOpenWindow(face) then
							focus(face)
						else
							succeed()
						end
					end
					if wasDocked or g ~= nil then
						refresh() -- an edge freed or taken again (see Dock above), or a group's selection moved
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
