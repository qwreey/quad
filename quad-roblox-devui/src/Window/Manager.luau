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
	Supports up to 333 live windows below the default Overlay layer (the windows of a tab group or a split keep a chunk
	each — headers TABS, SPLITS). A drag's drop preview sits one value above the dragged (raised, so top) window's chunk
	or its unit's tabs and splitters [Window/Decoration.luau headers "DOCKED", "TABS"].

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
	its dock width (header DOCK), its tab group and split (the node tree: tabs and selection, splits and ratios, folded
	leaves; the unit's rectangle, and the window's own kept rectangle — headers TABS, SPLITS), and the stacking order
	of the keyed FLOATING units (the export order). Not saved: the title, the content, the focus, the stacking of the
	docked units.
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
	shown. Nothing is reparented: the manager keeps a `Unit` per group (the floating rectangle, Collapsed, the edge and
	dock width, and a tree of `Leaf` tab sets — one leaf for a tab group, more in a split, header SPLITS; a leaf holds
	its members in tab order — a live window or a pending key — and the selected one) and tells each window's
	decoration what it is in it (`GroupView`: the unit's rectangle, its leaf's box in it, whether it draws its leaf,
	its tab slot, the flags). The drawn window is the selected one when it is open (else the first open one); it is the
	focused window of the group (`Focused` / `slot.Focused`).
	- Forming: a drag of a window (or of a whole group, by its strip's empty area, all its tabs in order, or of a tab
	  torn out of one) released over another window's / group's title-bar row or centre, or over a held edge's band,
	  joins its group (made when it is a plain window: its rectangle, edge and Collapsed become the group's) — the
	  four 20% bands around the centre split instead [2026-10-21 user decision — docking stage 4, header SPLITS; they
	  were left empty in stage 3]. Eligible:
	  the same manager and the same container (the surface roots' parent), both with a title bar (NoTitleBar never joins
	  nor is joined), the target open and expanded (an icon is no target; a dragged icon never joins), the dragged one
	  movable. NoDock does not stop joining [2026-10-21 user decision — it is edge docking only]. The window on top
	  under the pointer decides: when it cannot be joined (a NoTitleBar window, an icon, a hand-made root) it covers
	  what is beneath and nothing joins. The joined window is selected and the group raised and focused.
	- The rectangle is the group's: while grouped nothing writes a window's Position / Size Sources, which keep the
	  rectangle it had before it joined (its KEPT rectangle; a window grouped by a load gets it from the layout's
	  `Windows[key].Position` / `Size`, or has none). Moving / resizing / docking the group changes only the group.
	- Shared: Collapsed (writing any window's collapses the whole group — the manager spreads it; a collapsed floating
	  group is the drawn window's icon; in a split a leaf folds instead — header SPLITS) and the edge. The dock width is shared only while the group is DOCKED: joining
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
	- Stacking: a group is one LUMP — its windows sit next to each other in `order` (tree and tab order, where its
	  topmost one was), keep a ZIndex chunk each (only the drawn ones' parts show) and the tabs and splitters take the
	  lump's top grip rank, so nothing of another window interleaves; raising any window raises the lump. `known` keeps
	  a group's keys together the same way (the saved `Floating` order is the groups' stacking).
	- Saving (Window/Layout.luau): a group is a node with several tabs (keyed members only, in tab order; the selected
	  one, or the first keyed open one); `Windows[key].Position` / `Size` carry a member's kept rectangle when it has
	  one and the node keeps two or more tabs (a node the keyless windows leave with one tab is a plain window). A layout's node of several tabs makes a group of the windows it names (each named window first leaves its
	  group); a pending key joins its group at its saved slot when its window registers, and an open one cannot bring
	  its group onto an edge another open window / group holds (the group floats — the same rule as one window). The
	  joining rules hold there too: a named NoTitleBar window, or one whose surface root sits (or is later put) in
	  another container than the group's, is placed as a plain window as if alone in its node (its own rectangle, else
	  the node's) and leaves the group; with fewer than two windows left there is no group. An import opens windows
	  without selecting or focusing them (header STACKING).

	SPLITS [2026-10-21 user decisions — docking stage 4, Dear ImGui's shape; the look and the drags are in
	Window/Decoration.luau header "SPLITS"]. A unit's tree is binary: a node is a LEAF (a tab set, as above) or a SPLIT
	(`Axis` "LeftRight" | "TopBottom", `Ratio` = the first child's share, two children), nested to any depth. The unit
	keeps one rectangle (floating, or the docked panel); each leaf's window draws its own frame and strip at its box in
	it (`GroupView.Box`).
	- Splitting: a drag released over a joinable window's leaf judges, from the top: its strip / title row = join as a
	  tab at the pointer (as TABS); in a split unit, the band 2 x FrameHeight inside the unit's OUTER edges = split the
	  whole unit (its root) on that side, the preview half the whole unit (the long overlay); else, inside the leaf, the
	  centre [0.2, 0.8]^2 = join as the last tab and the 20% bands = split THAT leaf in half on that side, the preview that
	  half. Only the root and the leaf are reached (Dear ImGui's outer and inner targets); an unsplit unit's root is its
	  leaf. The target keeps its rectangle and is cut in half (Ratio 0.5); a corner goes to the side it is deeper in. The
	  dragged window becomes a new leaf; a dragged unit (by its strip's empty area) goes in with its whole tree as that
	  side (joining as tabs, its windows all become tabs, tree and tab order). A held edge's band joins the docked unit's
	  leaf its focus was last in (else its first visible leaf) as a tab. Docked panels split in all four directions (a
	  top / bottom split stacks on the side).
	- Tab strips: in a split every leaf shows its strip, even with one open window. Dragging a tab tears that window
	  off (as TABS); dragging a strip's empty area moves the whole unit (a docked one undocks as a whole to its floating
	  rectangle: the pointer keeps its share of the unit's width and its height in the pressed leaf's row, that leaf's
	  top taken where it sits in the floating rectangle).
	- Splitters: one per split (the `WindowSplitter` of its second side's first visible leaf); dragging it sets Ratio,
	  kept so neither side goes below its floor — a leaf's floor is its windows' largest MinSize (a folded one: its row
	  along the fold); along a split's axis its floor is the sum of its sides', across it the larger. The unit's resize
	  floor is its tree's. A floating unit's and a docked panel's width are pixels (the seam is kept inside the floors
	  and rounded as it is drawn); a docked panel's height is the container's (the ratio is a share of it, kept inside
	  the floors only while dragging). Hidden while either side is a folded leaf, or with an open NoResize window in
	  the unit.
	- Folding: a leaf's collapse arrow folds only that leaf and its sibling takes the space — along a top / bottom
	  split it keeps its strip row, along a left | right split it is a bar FrameHeight wide holding the arrow. THE FOLD
	  RULE [2026-10-21 user decision, after review]: a leaf may be folded only while its sibling subtree (the other side
	  of its nearest split with a side still there) holds a visible UNFOLDED leaf to take the room — a pending key saved
	  open counts as there, so a load whose windows register one by one keeps its folds. Where the rule refuses, the
	  arrow is not offered and an app's true is written back to false; when it stops holding (the sibling closes, a
	  load, a leaf torn out) the fold clears and the leaf's windows' Collapsed become false, and of two folded sides the
	  second one opens (so both sides are never folded). A floating split unit never becomes an icon; a docked split
	  panel still collapses as a whole by its strip. The windows' `Collapsed` Sources: a window's Collapsed = its leaf
	  folded OR (docked) its panel collapsed; the leaves keep their folds while the panel is collapsed (expanding it
	  restores them; an app's true on a window of a collapsed panel is recorded as its leaf's fold). An app writing true folds
	  that window's leaf, false unfolds it and expands a collapsed panel. A leaf's windows share its fold.
	- Hiding and leaving: a leaf whose windows are all closed hides and its sibling takes the space; `Open:Set(true)`
	  brings it back at its slot (TABS); all leaves closed = the unit hidden. A leaf left without members (its last tab
	  torn out, imported elsewhere, a keyless window destroyed) leaves the tree: its sibling takes its parent's place. A
	  root left as one leaf is a tab group again (the folds dropped), and with one window it dissolves (TABS: that
	  window takes the unit's rectangle). A window that leaves a split is expanded (its Collapsed was its leaf's fold).
	- The unit's own parts (grip, dock strip and width handle) are drawn by its LEAD: the drawn window of the leaf at
	  its bottom-right corner (the last visible leaf). Focus: a press focuses the pressed leaf's drawn window, so only
	  that leaf's strip has the active colour; the strip rule (header DOCK) asks whether the focus was anywhere in the
	  unit before the press. One lump (TABS).
	- Saving (Window/Layout.luau header SPLITS): the node tree with keyed members only (a leaf without any is dropped,
	  a split left with one side is that side — `Layout.prune`, the one rule saving, loading and the live tree use), `Ratio`, `Collapsed = true` on a folded leaf inside a split, the
	  windows' own kept rectangles when the tree holds two or more keys. A floating split's group `Collapsed` is false.
	  Loading builds the tree of the windows that may be tabs (the eligibility of TABS; the others are placed plainly
	  and the rest of the tree still builds); a pending key joins its leaf at its saved slot. `ImportWindow` takes a
	  window out first; `ExportWindow` carries no tree.

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
	-- the leaf (tab set) of the unit it is in (headers TABS, SPLITS): nil = a plain window; View = what its decoration
	-- is told
	Leaf: Leaf?,
	View: Source<GroupView?>,
	-- its Position / Size Sources hold a rectangle of its own (false: grouped by a load that did not carry one — it
	-- leaves its group at the group's Size)
	KeptRect: boolean,
}

type SplitAxis = Layout.SplitAxis

-- one tab of a leaf: a live window, or a key whose window is not registered (pending)
type Member = { Key: string?, Entry: Entry? }

-- a LEAF of a unit's tree (header SPLITS): one tab set — its members in tab order and the selected one
type Leaf = {
	Tag: "Leaf",
	Members: { Member },
	Selected: Member,
	Fold: boolean, -- folded inside its split (header SPLITS; false for a leaf that is the whole unit)
	Unit: Unit,
	Parent: Split?,
}

-- a two-way split of a unit's tree: `Ratio` = the first child's share (left / top)
type Split = {
	Tag: "Split",
	Axis: SplitAxis,
	Ratio: number,
	Children: { Node },
	Parent: Split?,
}

type Node = Leaf | Split

-- a UNIT (headers TABS, SPLITS): windows sharing one rectangle and one edge — a tab group when its tree is one leaf, a
-- split unit otherwise. `Collapsed` is the whole group's while unsplit (icon / panel), the docked panel's while split
type Unit = {
	Root: Node,
	Position: UDim2, -- the unit's floating outer rectangle
	Size: Vector2,
	Collapsed: boolean,
	Side: Side?,
	Width: number,
	-- the leaf its focus was last in (a held edge joins it — header SPLITS); nil = none yet
	FocusLeaf: Leaf?,
}

-- where every visible leaf of a split unit goes (header SPLITS), computed when its views are written
type SplitInfo = {
	Interval: { number }, -- the split's extent along its axis: { f0, p0, f1, p1 } of the unit's length
	At: { number }, -- the seam: { f, p }
	Pixel: boolean, -- the axis length is known in pixels (else: a fraction of the docked panel's height)
	Min1: number, -- the children's floors along the axis
	Min2: number,
}
type SplitterInfo = { Split: Split, Box: { number }, Enabled: boolean }
type Arrangement = {
	Boxes: { [Leaf]: { number } }, -- { x0f, x0p, x1f, x1p, y0f, y0p, y1f, y1p } of the unit's rectangle
	Folds: { [Leaf]: Decoration.FoldSide },
	Splitters: { [Leaf]: SplitterInfo }, -- by the leaf whose drawn window draws it
	Infos: { [Split]: SplitInfo },
	Lead: Leaf?, -- the leaf at the unit's bottom-right corner: its drawn window draws the unit's own parts
}

-- a splitter drag in progress (header SPLITS): the split, its unit and the seam's range in window units (its start
-- and the floors of both sides)
type SplitDrag = { Split: Split, Unit: Unit, Start: number, Length: number, Min1: number, Min2: number }

-- the press the strip rule asks about (header DOCK): the window the last global press went to and whether its unit
-- had the focus before that press focused it
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

-- the leaves of a node in tree order (first child first)
local function leavesIn(node: Node, out: { Leaf })
	if node.Tag == "Leaf" then
		table.insert(out, node)
	else
		leavesIn(node.Children[1], out)
		leavesIn(node.Children[2], out)
	end
end

local function leavesOf(u: Unit): { Leaf }
	local out: { Leaf } = {}
	leavesIn(u.Root, out)
	return out
end

-- every member of a unit, in tree order then tab order
local function membersOf(u: Unit): { Member }
	local out: { Member } = {}
	for _, leaf in leavesOf(u) do
		for _, m in leaf.Members do
			table.insert(out, m)
		end
	end
	return out
end

local function isSplit(u: Unit): boolean
	return u.Root.Tag == "Split"
end

local function unitOf(e: Entry?): Unit?
	local leaf = if e ~= nil then e.Leaf else nil
	return if leaf ~= nil then leaf.Unit else nil
end

-- the window's Collapsed in its leaf (header SPLITS): the leaf's fold or the docked panel's in a split unit, the whole
-- group's otherwise
local function collapsedOf(leaf: Leaf): boolean
	local u = leaf.Unit
	if isSplit(u) then
		return leaf.Fold or (u.Side ~= nil and u.Collapsed)
	end
	return u.Collapsed
end

-- put `node` where `old` is in its unit's tree (its parent's child, or the root)
local function replaceNode(u: Unit, old: Node, node: Node)
	local parent = old.Parent
	node.Parent = parent
	if parent == nil then
		u.Root = node
	elseif parent.Children[1] == old then
		parent.Children[1] = node
	else
		parent.Children[2] = node
	end
end

-- the two sides of a live / saved node for Layout.prune (nil, nil = a leaf)
local function liveSides(node: Node): (Node?, Node?)
	if node.Tag == "Split" then
		return node.Children[1], node.Children[2]
	end
	return nil, nil
end
local function savedSides(node: Layout.Node): (Layout.Node?, Layout.Node?)
	if node.Split ~= nil then
		return node.Children[1], node.Children[2]
	end
	return nil, nil
end
-- a saved split keeping both its (pruned) sides
local function savedSplit(node: Layout.Node, first: Layout.Node, second: Layout.Node): Layout.Node
	local out: Layout.SplitNode = { Split = (node :: Layout.SplitNode).Split, Ratio = (node :: Layout.SplitNode).Ratio, Children = { first, second } }
	return out
end

-- a group's saved Collapsed as a unit holds it (header SPLITS): a floating split unit is never collapsed — its leaves
-- fold; a docked one's is its panel's. (`Unit.Collapsed` keeps this invariant; this reads it off saved data.)
local function groupCollapsed(collapsed: boolean, side: Side?, split: boolean): boolean
	return collapsed and (side ~= nil or not split)
end

-- every node of a tree belongs to `u` (a tree moved into another unit)
local function adoptTree(node: Node, u: Unit)
	if node.Tag == "Leaf" then
		node.Unit = u
	else
		adoptTree(node.Children[1], u)
		adoptTree(node.Children[2], u)
	end
end

-- the axis and order a drop side makes: Left / Top put the dropped node first
local function axisOf(at: Decoration.DropSide): (SplitAxis, boolean)
	if at == "Left" or at == "Right" then
		return "LeftRight", at == "Left"
	end
	return "TopBottom", at == "Top"
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

	-- TABS / SPLITS (headers TABS, SPLITS): the live units, the leaf of each pending key that is a tab of one, and each
	-- split unit's last arrangement (a splitter drag reads it)
	local units: { [Unit]: true } = {}
	local pendingLeaf: { [string]: Leaf } = {}
	local arranged: { [Unit]: Arrangement } = setmetatable({}, { __mode = "k" }) :: any
	-- > 0 while the manager writes a unit's shared facts into its windows (their Sync must not echo them back)
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

	-- ── units (headers TABS, SPLITS) ──────────────────────────────────────────────────────────────────────────────

	local function isOpenWindow(e: Entry?): boolean
		local h = if e ~= nil then e.Hints else nil
		return h ~= nil and h.Open:Get()
	end

	local function memberOf(leaf: Leaf, e: Entry): Member?
		for _, m in leaf.Members do
			if m.Entry == e then
				return m
			end
		end
		return nil
	end

	-- the window that draws the leaf: the selected one when it is live and open, else the first open one, else the
	-- selected (closed: the whole leaf is hidden), else any live one
	local function drawnOf(leaf: Leaf): Entry?
		local selected = leaf.Selected.Entry
		if isOpenWindow(selected) then
			return selected
		end
		for _, m in leaf.Members do
			if isOpenWindow(m.Entry) then
				return m.Entry
			end
		end
		if selected ~= nil then
			return selected
		end
		for _, m in leaf.Members do
			if m.Entry ~= nil then
				return m.Entry
			end
		end
		return nil
	end

	-- the window a press or a focus of `e` means: its leaf's drawn one
	local function faceOf(e: Entry): Entry
		local leaf = e.Leaf
		return if leaf ~= nil then drawnOf(leaf) or e else e
	end

	-- the neighbour that takes the selection when a tab closes or leaves: the next open window from `nextFrom`, else
	-- the previous open one from `prevFrom` down, else the member now there (the leaf stays hidden)
	local function neighbour(leaf: Leaf, nextFrom: number, prevFrom: number): Member
		for i = nextFrom, #leaf.Members do
			if isOpenWindow(leaf.Members[i].Entry) then
				return leaf.Members[i]
			end
		end
		for i = prevFrom, 1, -1 do
			if isOpenWindow(leaf.Members[i].Entry) then
				return leaf.Members[i]
			end
		end
		return leaf.Members[math.clamp(nextFrom, 1, #leaf.Members)]
	end

	local function leafOfKey(key: string): Leaf?
		local entry = live[key]
		if entry ~= nil then
			return entry.Leaf
		end
		return pendingLeaf[key]
	end

	local function unitOfKey(key: string): Unit?
		local leaf = leafOfKey(key)
		return if leaf ~= nil then leaf.Unit else nil
	end

	-- the resize floor of one window (header TABS: a leaf's is the largest of its windows' per axis)
	local function floorOf(e: Entry): Vector2
		local h = e.Hints :: Decoration.Hints
		local min = h.MinSize
		if min ~= nil then
			return min
		end
		local fh = h.Style.FrameHeight:Get() * 2
		return Vector2.new(fh, fh)
	end

	local function leafFloor(leaf: Leaf): Vector2
		local x, y = 0, 0
		for _, m in leaf.Members do
			local e = m.Entry
			if e ~= nil then
				local f = floorOf(e)
				x, y = math.max(x, f.X), math.max(y, f.Y)
			end
		end
		return Vector2.new(x, y)
	end

	-- ── the split layout (header SPLITS) ──────────────────────────────────────────────────────────────────────────

	local function hasOpen(leaf: Leaf): boolean
		for _, m in leaf.Members do
			if isOpenWindow(m.Entry) then
				return true
			end
		end
		return false
	end

	-- the node as it shows: a leaf with an open window; a split whose two sides both show (else the side that shows
	-- takes its place — a leaf whose windows are all closed is hidden and its sibling takes the space)
	local function visibleOf(node: Node): Node?
		if node.Tag == "Leaf" then
			return if hasOpen(node) then node else nil
		end
		local a, b = visibleOf(node.Children[1]), visibleOf(node.Children[2])
		if a ~= nil and b ~= nil then
			return node
		end
		return a or b
	end

	-- the first / last visible leaf of a visible node (the last one holds its bottom-right corner)
	local function edgeLeaf(node: Node, last: boolean): Leaf
		local cursor: Node = node
		while cursor.Tag == "Split" do
			cursor = visibleOf(cursor.Children[if last then 2 else 1]) :: Node
		end
		return cursor :: Leaf
	end

	-- a folded leaf keeps one title-bar row (its drawn window's FrameHeight)
	local function foldSize(leaf: Leaf): number
		local e = drawnOf(leaf)
		local h = if e ~= nil then e.Hints else nil
		return if h ~= nil then h.Style.FrameHeight:Get() else 0
	end

	-- the floor of a visible node: a leaf's is its windows' largest (a folded one: its row along the fold), a split's
	-- is the sum of its sides along its axis and the larger across
	local function minOf(node: Node, parentAxis: SplitAxis?): Vector2
		if node.Tag == "Leaf" then
			local f = leafFloor(node)
			if node.Fold and parentAxis ~= nil then
				local row = foldSize(node)
				return if parentAxis == "LeftRight" then Vector2.new(row, row) else Vector2.new(f.X, row)
			end
			return f
		end
		local a = minOf(visibleOf(node.Children[1]) :: Node, node.Axis)
		local b = minOf(visibleOf(node.Children[2]) :: Node, node.Axis)
		if node.Axis == "LeftRight" then
			return Vector2.new(a.X + b.X, math.max(a.Y, b.Y))
		end
		return Vector2.new(math.max(a.X, b.X), a.Y + b.Y)
	end

	-- a leaf that stands in its unit for the fold rule: an open window, or a pending key saved open (a load whose
	-- windows register one by one must not lose the folds it brought — the rest of the unit is on its way)
	local function stands(leaf: Leaf): boolean
		if hasOpen(leaf) then
			return true
		end
		for _, m in leaf.Members do
			local key = m.Key
			local waiting = if m.Entry == nil and key ~= nil then pending[key] else nil
			if waiting ~= nil and waiting.Open then
				return true
			end
		end
		return false
	end
	local function present(node: Node): boolean
		if node.Tag == "Leaf" then
			return stands(node)
		end
		return present(node.Children[1]) or present(node.Children[2])
	end

	-- a standing leaf of `node` that is not folded
	local function hasUnfolded(node: Node): boolean
		if node.Tag == "Leaf" then
			return stands(node) and not node.Fold
		end
		return hasUnfolded(node.Children[1]) or hasUnfolded(node.Children[2])
	end

	-- THE fold rule (header SPLITS — user decision): a leaf may be folded only while its sibling subtree (the other
	-- side of its nearest split that has a standing side there) holds a standing UNFOLDED leaf to take the room. A leaf
	-- with no standing sibling (the rest closed) has nothing to fold against
	local function canFold(leaf: Leaf): boolean
		local child: Node = leaf
		local parent = leaf.Parent
		while parent ~= nil do
			local other = if parent.Children[1] == child then parent.Children[2] else parent.Children[1]
			if present(other) then
				return hasUnfolded(other)
			end
			child = parent
			parent = parent.Parent
		end
		return false
	end

	-- the fold rule kept after any change (a sibling closed, a load, a leaf torn out, both sides folded): a visible
	-- leaf that may no longer be folded unfolds — the later side first (tree order backwards), so of two folded sides
	-- the second one opens. Returns whether a fold changed (its windows' Collapsed follow — spreadCollapsed)
	local function normalizeFolds(u: Unit): boolean
		local leaves = leavesOf(u)
		local changed = false
		for i = #leaves, 1, -1 do
			local leaf = leaves[i]
			if leaf.Fold and hasOpen(leaf) and not canFold(leaf) then
				leaf.Fold = false
				changed = true
			end
		end
		return changed
	end

	-- the unit's resize floor: its visible tree's (a unit of one leaf: its windows' largest)
	local function unitFloor(u: Unit): Vector2
		local root = visibleOf(u.Root)
		if root == nil then
			if u.Root.Tag == "Leaf" then
				return leafFloor(u.Root)
			end
			return Vector2.zero
		end
		return minOf(root, nil)
	end

	-- where every visible leaf, fold and splitter of a split unit goes. Boundaries are { f, p } pairs of the unit's
	-- rectangle (f = a fraction of its length, p = pixels): a floating unit's lengths and a docked one's width are
	-- pixels (f = 0, seams kept inside both sides' floors and rounded), a docked panel's height is the container's (f
	-- carries the ratio, p the folds)
	local function arrange(u: Unit): Arrangement
		local out: Arrangement = { Boxes = {}, Folds = {}, Splitters = {}, Infos = {}, Lead = nil }
		local root = visibleOf(u.Root)
		if root == nil then
			return out
		end
		local docked = u.Side ~= nil
		local lx = if docked then u.Width else u.Size.X
		local ly: number? = if docked then nil else u.Size.Y
		local function place(node: Node, x: { number }, y: { number })
			if node.Tag == "Leaf" then
				out.Boxes[node] = { x[1], x[2], x[3], x[4], y[1], y[2], y[3], y[4] }
				return
			end
			local c1 = visibleOf(node.Children[1]) :: Node
			local c2 = visibleOf(node.Children[2]) :: Node
			local alongX = node.Axis == "LeftRight"
			local iv = if alongX then x else y
			local pixel = alongX or ly ~= nil
			local fold1 = c1.Tag == "Leaf" and c1.Fold
			local fold2 = c2.Tag == "Leaf" and c2.Fold
			local m1, m2 = minOf(c1, node.Axis), minOf(c2, node.Axis)
			local min1 = if alongX then m1.X else m1.Y
			local min2 = if alongX then m2.X else m2.Y
			local mf, mp
			-- (never both: the fold rule — normalizeFolds — unfolds the second side first)
			if fold1 and c1.Tag == "Leaf" then
				mf, mp = iv[1], iv[2] + foldSize(c1)
			elseif fold2 and c2.Tag == "Leaf" then
				mf, mp = iv[3], iv[4] - foldSize(c2)
			elseif pixel then
				local a, b = iv[2], iv[4]
				local lo, hi = a + min1, b - min2
				local m = a + node.Ratio * (b - a)
				m = if hi < lo then lo else math.clamp(m, lo, hi)
				mf, mp = 0, math.round(m)
			else
				mf = iv[1] + node.Ratio * (iv[3] - iv[1])
				mp = iv[2] + node.Ratio * (iv[4] - iv[2])
			end
			if fold1 and c1.Tag == "Leaf" then
				out.Folds[c1] = if alongX then "Left" else "Top"
			end
			if fold2 and c2.Tag == "Leaf" then
				out.Folds[c2] = if alongX then "Right" else "Bottom"
			end
			out.Infos[node] = { Interval = table.clone(iv), At = { mf, mp }, Pixel = pixel, Min1 = min1, Min2 = min2 }
			-- the splitter: drawn by the second side's first leaf (one leaf per split). LeftRight: [seam, seam + t] over
			-- the second side's leading edge (its padding, not the first side's scrollbar); TopBottom: [seam - t, seam]
			-- over the first side's bottom (not the second side's tab row)
			local owner = edgeLeaf(c2, false)
			local ownerDrawn = drawnOf(owner)
			local t = if ownerDrawn ~= nil and ownerDrawn.Hints ~= nil
				then (ownerDrawn.Hints :: Decoration.Hints).Style.Metrics.WindowResizePadding:Get().X
				else 6
			local box = if alongX
				then { mf, mp, mf, mp + t, y[1], y[2], y[3], y[4] }
				else { x[1], x[2], x[3], x[4], mf, mp - t, mf, mp }
			out.Splitters[owner] = { Split = node, Box = box, Enabled = not fold1 and not fold2 }
			local first = { iv[1], iv[2], mf, mp }
			local second = { mf, mp, iv[3], iv[4] }
			if alongX then
				place(c1, first, y)
				place(c2, second, y)
			else
				place(c1, x, first)
				place(c2, x, second)
			end
		end
		place(root, { 0, 0, 0, lx }, if ly ~= nil then { 0, 0, 0, ly } else { 0, 0, 1, 0 })
		out.Lead = edgeLeaf(root, true)
		return out
	end

	-- every window of `u` takes its Collapsed (its leaf's fold, the panel's or the group's — no echo through Sync)
	local function spreadCollapsed(u: Unit)
		quiet += 1
		for _, leaf in leavesOf(u) do
			local c = collapsedOf(leaf)
			for _, m in leaf.Members do
				local e = m.Entry
				if e ~= nil then
					(e.Hints :: Decoration.Hints).Collapsed:SetIfChanged(c)
				end
			end
		end
		quiet -= 1
	end

	-- tell every window of `u` where its leaf is and what it is in it. Every window's view change re-judges the
	-- layout (its decoration's Changed): held back and flushed once, so a unit drag rebuilds the layout once per move
	local writeViews: (u: Unit) -> ()
	local function pushView(u: Unit)
		if not units[u] then
			return
		end
		batching += 1
		local ok, err = pcall(function()
			writeViews(u)
		end)
		batching -= 1
		if batching == 0 and layoutDirty then
			flushLayout()
		end
		if not ok then
			error(err, 0)
		end
	end
	writeViews = function(u: Unit)
		local split = isSplit(u)
		if split and normalizeFolds(u) then
			spreadCollapsed(u)
		end
		local arr: Arrangement? = if split then arrange(u) else nil
		if arr ~= nil then
			arranged[u] = arr
		else
			arranged[u] = nil
		end
		local top = 0
		local noMove, noResize, noDock = false, false, false
		for _, m in membersOf(u) do
			local e = m.Entry
			if e ~= nil then
				local h = e.Hints :: Decoration.Hints
				top = math.max(top, e.Rank:Get())
				noMove = noMove or h.NoMove
				noDock = noDock or h.NoDock
				if h.Open:Get() then
					noResize = noResize or h.NoResize
				end
			end
		end
		local panelCollapsed = split and u.Side ~= nil and u.Collapsed
		for _, leaf in leavesOf(u) do
			local drawn = drawnOf(leaf)
			local shown: { Entry } = {}
			local noCollapse = false
			for _, m in leaf.Members do
				local e = m.Entry
				if e ~= nil and isOpenWindow(e) then
					table.insert(shown, e)
					noCollapse = noCollapse or (e.Hints :: Decoration.Hints).NoCollapse
				end
			end
			local box: { number }? = nil
			local fold: Decoration.FoldSide? = nil
			local splitter: SplitterInfo? = nil
			local lead = not split
			if arr ~= nil then
				box = arr.Boxes[leaf]
				fold = arr.Folds[leaf]
				splitter = arr.Splitters[leaf]
				lead = arr.Lead == leaf
				-- (the arrow is not offered where the fold rule refuses a fold; a folded leaf keeps it to unfold)
				noCollapse = noCollapse or (not leaf.Fold and not canFold(leaf))
			end
			-- in a split every leaf shows its tab strip, even with one window (Dear ImGui)
			local tabbed = #shown >= (if split then 1 else 2)
			for _, m in leaf.Members do
				local e = m.Entry
				if e ~= nil then
					local at = table.find(shown, e)
					local isDrawn = e == drawn
					local nextView: GroupView = {
						Position = u.Position,
						Size = u.Size,
						Box = box,
						Drawn = isDrawn,
						Lead = isDrawn and lead,
						Tabbed = tabbed,
						TabIndex = if tabbed and at ~= nil then at - 1 else nil,
						TabCount = #shown,
						TabZ = top * SPAN,
						NoMove = noMove,
						NoResize = noResize,
						NoCollapse = noCollapse,
						NoDock = noDock,
						Split = split,
						Fold = fold,
						PanelCollapsed = panelCollapsed,
						Splitter = if isDrawn and splitter ~= nil
							then { Axis = splitter.Split.Axis, Box = splitter.Box, Enabled = splitter.Enabled and not noResize }
							else nil,
					}
					if not Layout.same(e.View:Get(), nextView) then
						e.View:Set(nextView)
					end
				end
			end
		end
	end

	-- the tree of `u` changed shape: a leaf that is the whole unit folds no more (the group's Collapsed is the whole
	-- group's again — a floating split unit was never collapsed), and every window takes its Collapsed
	local function restructured(u: Unit)
		local root = u.Root
		if root.Tag == "Leaf" then
			root.Fold = false
			root.Parent = nil
		end
		spreadCollapsed(u)
	end

	-- `e` takes `u`'s shared facts (its edge, its Collapsed, and the dock width while the unit is docked — a floating
	-- unit leaves each window the dock width it keeps) and joins `leaf` (no echo through Sync)
	local function adopt(e: Entry, leaf: Leaf)
		local u = leaf.Unit
		local h = e.Hints :: Decoration.Hints
		quiet += 1
		e.Leaf = leaf
		e.Side:SetIfChanged(u.Side)
		if u.Side ~= nil then
			e.DockWidth:SetIfChanged(u.Width)
		end
		h.Collapsed:SetIfChanged(collapsedOf(leaf))
		quiet -= 1
	end

	local function newLeaf(u: Unit, members: { Member }, selected: Member): Leaf
		return { Tag = "Leaf", Members = members, Selected = selected, Fold = false, Unit = u, Parent = nil }
	end

	-- a new unit of one window (a drag is about to join or split it): its rectangle, edge and Collapsed become the
	-- unit's
	local function newUnit(target: Entry): Leaf
		local h = target.Hints :: Decoration.Hints
		local m: Member = { Key = liveKey(target), Entry = target }
		local u: Unit = {
			Root = nil :: any,
			FocusLeaf = nil,
			Position = h.Position:Get(),
			Size = h.Size:Get(),
			Collapsed = h.Collapsed:Get(),
			Side = target.Side:Get(),
			Width = target.DockWidth:Get(),
		}
		local leaf = newLeaf(u, { m }, m)
		u.Root = leaf
		units[u] = true
		target.KeptRect = true
		target.Leaf = leaf
		return leaf
	end

	-- a unit left with one window (open or closed, live or pending) in one leaf is no unit: that window takes the
	-- unit's rectangle into its own Position / Size (it stays where it was) and its edge, and is a plain window again
	local function dissolveIfSmall(u: Unit): boolean
		local root = u.Root
		if root.Tag == "Split" or #root.Members >= 2 then
			return false
		end
		units[u] = nil
		arranged[u] = nil
		local m = root.Members[1]
		if m == nil then
			return true
		end
		local e = m.Entry
		if e ~= nil then
			local h = e.Hints :: Decoration.Hints
			quiet += 1
			e.Leaf = nil
			h.Position:SetIfChanged(u.Position)
			h.Size:SetIfChanged(u.Size)
			h.Collapsed:SetIfChanged(u.Collapsed)
			e.KeptRect = true
			e.View:Set(nil)
			quiet -= 1
		else
			local key = m.Key :: string
			pendingLeaf[key] = nil
			local waiting = pending[key]
			if waiting ~= nil then
				-- a fresh table: a state is never written in place (an import's own state tables stay what it read)
				local st = Layout.copyState(waiting)
				st.Position = Layout.positionOf(u.Position)
				st.Size = Layout.sizeOf(u.Size)
				st.Collapsed = u.Collapsed
				st.Dock = u.Side
				st.DockWidth = if u.Side ~= nil then u.Width else nil
				pending[key] = st
			end
		end
		return true
	end

	-- drop member `at` of `leaf` (it left, or its window went away for good); the selection moves to a neighbour. An
	-- emptied leaf leaves the tree (its sibling takes its parent's place — header SPLITS), a unit left with one window
	-- dissolves
	local function dropMember(leaf: Leaf, at: number)
		local m = table.remove(leaf.Members, at) :: Member
		if leaf.Selected == m and #leaf.Members > 0 then
			leaf.Selected = neighbour(leaf, at, at - 1)
		end
		local u = leaf.Unit
		if #leaf.Members == 0 and leaf.Parent ~= nil then
			-- (Layout.prune: the rule saving and loading use; a kept split keeps its table)
			local root = Layout.prune(u.Root, liveSides, function(n: Node): boolean
				return n.Tag == "Leaf" and #n.Members > 0
			end, function(n: Node, first: Node, second: Node): Node
				local split = n :: Split
				split.Children[1] = first
				split.Children[2] = second
				first.Parent = split
				second.Parent = split
				return split
			end) :: Node
			root.Parent = nil
			u.Root = root
			restructured(u)
		end
		if not dissolveIfSmall(u) then
			pushView(u)
		end
	end

	-- a live window leaves its leaf (a tab dragged out, ImportWindow / ImportLayout naming it). `float`: off the unit's
	-- edge too. Without a rectangle of its own it takes the unit's Size; out of a split it is expanded (its Collapsed
	-- was its leaf's fold)
	local function leave(e: Entry, float: boolean)
		local leaf = e.Leaf
		if leaf == nil then
			return
		end
		local u = leaf.Unit
		local m = memberOf(leaf, e) :: Member
		local at = table.find(leaf.Members, m) :: number
		local h = e.Hints :: Decoration.Hints
		quiet += 1
		e.Leaf = nil
		if not e.KeptRect then
			h.Size:SetIfChanged(u.Size)
			e.KeptRect = true
		end
		if float then
			e.Side:SetIfChanged(nil)
		end
		if isSplit(u) then
			h.Collapsed:SetIfChanged(false)
		end
		e.View:Set(nil)
		quiet -= 1
		dropMember(leaf, at)
	end

	-- a pending key leaves its leaf
	local function leavePending(key: string)
		local leaf = pendingLeaf[key]
		if leaf == nil then
			return
		end
		pendingLeaf[key] = nil
		for i, m in leaf.Members do
			if m.Entry == nil and m.Key == key then
				dropMember(leaf, i)
				return
			end
		end
	end

	-- the unit's edge (header DOCK: one unit per edge); every window of it follows — and takes the unit's dock width
	-- while it is docked (undocked, each keeps the width it had). A split unit that floats is expanded (only its panel
	-- collapses)
	local function setUnitSide(u: Unit, side: Side?, width: number?)
		u.Side = side
		if width ~= nil then
			u.Width = width
		end
		if side == nil and isSplit(u) then
			u.Collapsed = false
		end
		quiet += 1
		for _, m in membersOf(u) do
			local e = m.Entry
			if e ~= nil then
				if side ~= nil then
					e.DockWidth:SetIfChanged(u.Width)
				end
				e.Side:SetIfChanged(side)
			end
		end
		quiet -= 1
		if isSplit(u) then
			spreadCollapsed(u)
		end
	end

	-- the open window (or unit) docked on `side` other than `except` and its unit (header DOCK: one per edge)
	local function occupant(side: Side, except: Entry?): Entry?
		local exceptUnit = unitOf(except)
		for _, entry in order do
			local h = entry.Hints
			if entry ~= except and (exceptUnit == nil or unitOf(entry) ~= exceptUnit) and h ~= nil and entry.Side:Get() == side and h.Open:Get() then
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
		local leaf = pendingLeaf[key]
		if leaf ~= nil then
			-- a pending tab: its unit's shared facts
			local u = leaf.Unit
			local copy = Layout.copyState(st)
			copy.Collapsed = collapsedOf(leaf)
			copy.Dock = u.Side
			copy.DockWidth = if u.Side ~= nil then u.Width else nil
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

	-- a window of a unit gets its saved state: the unit's shared facts, its own kept rectangle when the state has
	-- one (header TABS — `Windows[key].Position` / `Size`), and its Open. The edge follows `apply`'s rule for the
	-- whole unit: an OPEN window cannot bring its unit onto an edge another open window / unit holds — the unit
	-- floats; a closed one keeps the edge remembered (header DOCK).
	local function applyMember(entry: Entry, state: WindowState, leaf: Leaf)
		local u = leaf.Unit
		local h = entry.Hints :: Decoration.Hints
		quiet += 1
		entry.Leaf = leaf
		local size, position = state.Size, state.Position
		if size ~= nil then
			h.Size:SetIfChanged(Layout.toSize(size))
		end
		if position ~= nil then
			h.Position:SetIfChanged(Layout.toPosition(position))
		end
		entry.KeptRect = size ~= nil
		local side = u.Side
		if side ~= nil then
			-- the width that fits this container is the unit's (exported as it shows)
			local deco = entry.Deco
			if deco ~= nil then
				u.Width = deco.FitDockWidth(u.Width)
			end
			entry.DockWidth:SetIfChanged(u.Width)
			if state.Open and occupant(side, entry) ~= nil then
				quiet -= 1
				setUnitSide(u, nil, nil)
				quiet += 1
			end
		end
		entry.Side:SetIfChanged(u.Side)
		h.Collapsed:SetIfChanged(collapsedOf(leaf))
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

	-- `e` may be a tab of a unit whose windows sit in `container` (nil = not known yet)
	local function groupable(e: Entry, container: Instance?): boolean
		local h, root = e.Hints, e.Root
		if h == nil or h.NoTitleBar then
			return false
		end
		local parent = if root ~= nil then root.Parent else nil
		return container == nil or parent == nil or parent == container
	end

	-- the unit saved on each edge: the open unit / window there (none when it has no Key), else the topmost known
	-- key whose state (or unit) remembers that edge; every other unit remembering an edge is saved as floating
	local function holders(): { [Side]: any }
		local out: { [Side]: any } = {}
		for _, side: Side in { "Left" :: Side, "Right" :: Side } do
			local holder = occupant(side, nil)
			if holder ~= nil then
				local u = unitOf(holder)
				if u ~= nil then
					out[side] = u
				else
					local key = liveKey(holder)
					if key ~= nil then
						out[side] = key
					end
				end
			else
				for i = #known, 1, -1 do
					local key = known[i]
					local u = unitOfKey(key)
					local dock = if u ~= nil then u.Side else stateOf(key).Dock
					if dock == side then
						out[side] = u or key
						break
					end
				end
			end
		end
		return out
	end

	-- a unit's tree as saved (header SPLITS): keyed members only (a leaf may come out empty — Layout.prune drops it); a
	-- leaf's Collapsed when it is folded (the caller drops it on a root leaf)
	local function savedTree(node: Node, openKey: { [string]: boolean }): Layout.Node
		if node.Tag == "Leaf" then
			local tabs: { string } = {}
			local firstOpen: string? = nil
			for _, m in node.Members do
				local key = m.Key
				if key ~= nil then
					table.insert(tabs, key)
					if firstOpen == nil and openKey[key] then
						firstOpen = key
					end
				end
			end
			local out: Layout.TabNode = { Tabs = tabs, Selected = node.Selected.Key or firstOpen or tabs[1] or "" }
			if node.Fold then
				out.Collapsed = true
			end
			return out
		end
		local out: Layout.SplitNode = {
			Split = node.Axis,
			Ratio = node.Ratio,
			Children = { savedTree(node.Children[1], openKey), savedTree(node.Children[2], openKey) },
		}
		return out
	end

	-- a unit as a saved group: its keyed windows (nil when it has none)
	local function savedUnit(u: Unit): Layout.Unit?
		local openKey: { [string]: boolean } = {}
		local windows: { [string]: Layout.WindowEntry } = {}
		local kept: { [string]: boolean } = {}
		for _, m in membersOf(u) do
			local key = m.Key
			if key ~= nil then
				local st = stateOf(key)
				openKey[key] = st.Open
				windows[key] = { Kind = st.Kind, Open = st.Open }
				local e = m.Entry
				kept[key] = if e ~= nil then e.KeptRect else (st.Position ~= nil and st.Size ~= nil)
			end
		end
		local node = Layout.prune(savedTree(u.Root, openKey), savedSides, function(leaf: Layout.Node): boolean
			return #(leaf :: Layout.TabNode).Tabs > 0
		end, savedSplit)
		if node == nil then
			return nil
		end
		if node.Split == nil then
			node.Collapsed = nil
		end
		local count = 0
		for _ in windows do
			count += 1
		end
		-- a tab's own rectangle (header TABS): only in a saved tree of several keys (a tree the keyless windows leave
		-- with one key loads as a plain window at the group's rectangle), and only a window that has one
		if count >= 2 then
			for key, w in windows do
				if kept[key] then
					local st = stateOf(key)
					w.Position = st.Position
					w.Size = st.Size
				end
			end
		end
		return {
			Node = node,
			Windows = windows,
			-- (the invariant of `Unit.Collapsed`: a floating split's is false)
			Collapsed = u.Collapsed,
			Position = Layout.positionOf(u.Position),
			Size = Layout.sizeOf(u.Size),
			Dock = u.Side,
			Width = if u.Side ~= nil then u.Width else nil,
		}
	end

	local function plainUnit(key: string): Layout.Unit
		local s = stateOf(key)
		return {
			Node = { Tabs = { key }, Selected = key },
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
		local saved: { Layout.Unit } = {}
		local byToken: { [any]: Layout.Unit } = {}
		local seen: { [Unit]: true } = {}
		for _, key in known do
			local u = unitOfKey(key)
			if u ~= nil then
				if not seen[u] then
					seen[u] = true
					local unit = savedUnit(u)
					if unit ~= nil then
						table.insert(saved, unit)
						byToken[u] = unit
					end
				end
			else
				local unit = plainUnit(key)
				table.insert(saved, unit)
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
		return Layout.build(saved, holderUnits)
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

	-- a unit stacks as one lump (headers TABS, SPLITS): its live windows sit together, in tree and tab order, where
	-- its topmost one is
	local function gatherOrder()
		if next(units) == nil then
			return
		end
		local topOf: { [Unit]: number } = {}
		for i, e in order do
			local u = unitOf(e)
			if u ~= nil then
				topOf[u] = i
			end
		end
		local out: { Entry } = {}
		for i, e in order do
			local u = unitOf(e)
			if u == nil then
				table.insert(out, e)
			elseif topOf[u] == i then
				for _, m in membersOf(u) do
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

	-- the same for the saved order: a unit's keys sit together where its topmost key is
	local function gatherKnown()
		local topOf: { [Unit]: number } = {}
		for i, key in known do
			local u = unitOfKey(key)
			if u ~= nil then
				topOf[u] = i
			end
		end
		if next(topOf) == nil then
			return
		end
		local out: { string } = {}
		for i, key in known do
			local u = unitOfKey(key)
			if u == nil then
				table.insert(out, key)
			elseif topOf[u] == i then
				for _, m in membersOf(u) do
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
		-- (the tabs' and splitters' ZIndex is the unit's top rank)
		for u in units do
			pushView(u)
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

	-- raise to the top with the focus. A window of a unit raises the whole unit; an OPEN window that is not its
	-- leaf's drawn one is selected first (an explicit ask for it: `Open:Set(true)`, `Focused:Set(true)`, its tab)
	local function focus(target: Entry)
		local entry = target
		local leaf = entry.Leaf
		local u = if leaf ~= nil then leaf.Unit else nil
		if leaf ~= nil and u ~= nil then
			if drawnOf(leaf) ~= entry and isOpenWindow(entry) then
				batch(function()
					leaf.Selected = memberOf(leaf, entry) :: Member
					pushView(u)
					layoutDirty = true
				end)
			end
			entry = drawnOf(leaf) or entry
			u.FocusLeaf = leaf
		end
		local topEntry = order[#order]
		local onTop = topEntry == entry or (u ~= nil and unitOf(topEntry) == u)
		if focusedId:Get() == entry.Id and onTop then
			return -- already focused AND on top (a newer registration may cover a focused window)
		end
		if table.find(order, entry) == nil then
			return -- released
		end
		local lump: { Entry } = {}
		if u ~= nil then
			for _, m in membersOf(u) do
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
		-- a keyed window raised: its key goes to the top of the saved order (header STACKING), a unit's keys together
		-- (its pending tabs' too)
		local keys: { string } = {}
		if u ~= nil then
			for _, m in membersOf(u) do
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

	-- the focused window went away (closed or released): the topmost window still open takes the focus (a leaf is one
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

	local function focusedEntry(): Entry?
		local id = focusedId:Get()
		for _, e in order do
			if e.Id == id then
				return e
			end
		end
		return nil
	end

	-- a press went to `entry`: remember whether its unit had the focus before (the strip rule), then focus it. A
	-- press on any part of a leaf (a tab included) focuses the leaf's drawn window: selecting a tab is the tab's own
	-- press
	local function pressed(entry: Entry)
		local target = faceOf(entry)
		local before = focusedEntry()
		local u = unitOf(target)
		local was = before == target or (u ~= nil and unitOf(before) == u)
		lastPress = { Entry = target, WasFocused = was }
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

	-- a tab whose surface root is put in another container than its unit's other windows (an import or a pending
	-- tab grouped it before its root had a parent, or the app moved it) leaves the unit as a plain window: its own
	-- kept rectangle, or the unit's (header TABS)
	local function leaveIfElsewhere(e: Entry)
		local u, root = unitOf(e), e.Root
		local container = if root ~= nil then root.Parent else nil
		if u == nil or container == nil then
			return
		end
		for _, m in membersOf(u) do
			local other = m.Entry
			local otherRoot = if other ~= nil then other.Root else nil
			local otherContainer = if otherRoot ~= nil then otherRoot.Parent else nil
			if other ~= e and otherContainer ~= nil and otherContainer ~= container then
				local h = e.Hints :: Decoration.Hints
				if not e.KeptRect then
					h.Position:SetIfChanged(u.Position)
				end
				leave(e, true)
				renumber()
				refresh()
				return
			end
		end
	end

	-- ── joining and splitting (headers TABS, SPLITS) ──────────────────────────────────────────────────────────────

	-- `e` may be joined by a drag from `container`: a decorated window with a title bar there, open, expanded (a
	-- folded leaf of a split counts: only a collapsed panel or an icon does not), its leaf's drawn one
	local function joinable(e: Entry, container: Instance): boolean
		local h, deco, root = e.Hints, e.Deco, e.Root
		if h == nil or deco == nil or root == nil or h.NoTitleBar or root.Parent ~= container then
			return false
		end
		if not h.Open:Get() then
			return false
		end
		local leaf = e.Leaf
		local u = if leaf ~= nil then leaf.Unit else nil
		if u ~= nil and isSplit(u) then
			if u.Side ~= nil and u.Collapsed then
				return false
			end
		elseif h.Collapsed:Get() then
			return false
		end
		return leaf == nil or drawnOf(leaf) == e
	end

	-- the on-screen rectangle of a unit: around its visible leaves' frames
	local function unitScreenRect(u: Unit): (Vector2?, Vector2?)
		local lo, hi = nil :: Vector2?, nil :: Vector2?
		for _, leaf in leavesOf(u) do
			local e = drawnOf(leaf)
			local deco = if e ~= nil then e.Deco else nil
			if e ~= nil and deco ~= nil and isOpenWindow(e) and deco.Frame.Visible then
				local p, s = deco.Frame.AbsolutePosition, deco.Frame.AbsoluteSize
				local q0, q1 = p, p + s
				lo = if lo ~= nil then Vector2.new(math.min(lo.X, q0.X), math.min(lo.Y, q0.Y)) else q0
				hi = if hi ~= nil then Vector2.new(math.max(hi.X, q1.X), math.max(hi.Y, q1.Y)) else q1
			end
		end
		return lo, hi
	end

	-- the band of a target's rectangle the point is in (the side nearest it among those closer than `band`), nil =
	-- none
	local function bandAt(p: Vector2, s: Vector2, x: number, y: number, bandX: number, bandY: number): Decoration.DropSide?
		local best: Decoration.DropSide? = nil
		local bestD = math.huge
		local function try(at: Decoration.DropSide, d: number, limit: number, length: number)
			-- (compared as a share of the band, so a corner goes to the side it is deeper in)
			if d >= 0 and d < limit and length > 0 and d / limit < bestD then
				best = at
				bestD = d / limit
			end
		end
		try("Left", x - p.X, bandX, s.X)
		try("Right", p.X + s.X - x, bandX, s.X)
		try("Top", y - p.Y, bandY, s.Y)
		try("Bottom", p.Y + s.Y - y, bandY, s.Y)
		return best
	end

	-- half of a rectangle (UDim2s in the container) on a side: the preview of a split
	local function half(position: UDim2, size: UDim2, at: Decoration.DropSide): (UDim2, UDim2)
		local hx = UDim.new(size.X.Scale / 2, math.round(size.X.Offset / 2))
		local hy = UDim.new(size.Y.Scale / 2, math.round(size.Y.Offset / 2))
		if at == "Left" then
			return position, UDim2.new(hx, size.Y)
		elseif at == "Right" then
			local x = UDim.new(position.X.Scale + hx.Scale, position.X.Offset + size.X.Offset - hx.Offset)
			return UDim2.new(x, position.Y), UDim2.new(UDim.new(size.X.Scale - hx.Scale, hx.Offset), size.Y)
		elseif at == "Top" then
			return position, UDim2.new(size.X, hy)
		end
		local y = UDim.new(position.Y.Scale + hy.Scale, position.Y.Offset + size.Y.Offset - hy.Offset)
		return UDim2.new(position.X, y), UDim2.new(size.X, UDim.new(size.Y.Scale - hy.Scale, hy.Offset))
	end

	-- what a drop on the joinable window `e` (its leaf's drawn one) at the pointer does (header SPLITS): its leaf's
	-- strip row joins as a tab where the pointer is; in a split unit, the band 2 x FrameHeight inside the unit's outer
	-- edges splits the whole unit on that side; else, inside its leaf, the centre joins as the last tab and the 20%
	-- bands split that leaf in half on that side (an unsplit unit: root = leaf)
	local function judgeOver(e: Entry, x: number, y: number): Decoration.Drop?
		local deco = e.Deco :: Decoration.Decoration
		local f = deco.Frame
		local leafPos, leafSize = deco.LeafRect()
		local p, s = f.AbsolutePosition, f.AbsoluteSize
		local inFrame = holds(f, x, y)
		local view = e.View:Get()
		local fold = if view ~= nil then view.Fold else nil
		local row = deco.RowHeight()
		if inFrame and fold ~= "Left" and fold ~= "Right" and y < p.Y + row then
			return { Target = e, Index = deco.InsertAt(x), Split = nil, Outer = false, Position = leafPos, Size = leafSize }
		end
		local u = unitOf(e)
		if u ~= nil and isSplit(u) then
			local lo, hi = unitScreenRect(u)
			if lo ~= nil and hi ~= nil then
				local band = 2 * row
				local outer = if x >= lo.X and x < hi.X and y >= lo.Y and y < hi.Y then bandAt(lo, hi - lo, x, y, band, band) else nil
				if outer ~= nil then
					local unitPos, unitSize = deco.UnitRect()
					local hp, hs = half(unitPos, unitSize, outer :: Decoration.DropSide)
					return { Target = e, Index = nil, Split = outer :: Decoration.DropSide, Outer = true, Position = hp, Size = hs }
				end
			end
		end
		if not inFrame or fold ~= nil then
			return nil
		end
		local fx, fy = (x - p.X) / s.X, (y - p.Y) / s.Y
		local lo, hi = Decoration.CENTRE_LO, Decoration.CENTRE_HI
		if fx >= lo and fx <= hi and fy >= lo and fy <= hi then
			return { Target = e, Index = nil, Split = nil, Outer = false, Position = leafPos, Size = leafSize }
		end
		local at = bandAt(p, s, x, y, s.X * lo, s.Y * lo)
		if at == nil then
			return nil
		end
		local hp, hs = half(leafPos, leafSize, at)
		return { Target = e, Index = nil, Split = at, Outer = false, Position = hp, Size = hs }
	end

	-- the window / unit under the pointer a drag of `entry` would join or split, and how (headers TABS, SPLITS)
	local function dropAt(entry: Entry, x: number, y: number): Decoration.Drop?
		local root = entry.Root
		local container = if root ~= nil then root.Parent else nil
		if container == nil then
			return nil
		end
		local own = unitOf(entry)
		-- the first window from the top with something on screen under the pointer decides (its drawn frame, tabs,
		-- icon, strip, splitter or surface; a leaf's hidden windows show nothing): only a joinable one is judged,
		-- anything else covers what is under it
		for i = #order, 1, -1 do
			local e = order[i]
			local eRoot = e.Root
			if e ~= entry and (own == nil or unitOf(e) ~= own) and eRoot ~= nil and eRoot.Parent == container then
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
					-- the window that judges: the hit window's leaf's drawn one (the hit may be an unselected tab); in a
					-- split, when its frame does not hold the pointer (a splitter over the neighbour's edge), the leaf
					-- whose frame does
					local face = faceOf(e)
					local u = unitOf(face)
					local faceDeco = face.Deco
					if u ~= nil and isSplit(u) and (faceDeco == nil or not holds(faceDeco.Frame, x, y)) then
						for _, leaf in leavesOf(u) do
							local d = drawnOf(leaf)
							local dd = if d ~= nil then d.Deco else nil
							if d ~= nil and dd ~= nil and isOpenWindow(d) and holds(dd.Frame, x, y) then
								face = d
								break
							end
						end
					end
					if face.Deco == nil or not joinable(face, container) then
						return nil
					end
					return judgeOver(face, x, y)
				end
			end
		end
		return nil
	end

	-- the unit holding `side` (header TABS: a held edge joins), when a drag of `entry` may join it: the leaf of its
	-- focused window, else its first visible leaf
	local function edgeJoin(entry: Entry, side: Side): Decoration.Drop?
		local root = entry.Root
		local container = if root ~= nil then root.Parent else nil
		local holder = occupant(side, entry)
		if holder == nil or container == nil then
			return nil
		end
		local target = faceOf(holder)
		local u = unitOf(holder)
		if u ~= nil then
			-- (the drag focused the dragged window: the unit's own focus is the leaf it was last in)
			local leaf = u.FocusLeaf
			if leaf ~= nil and leaf.Unit == u and hasOpen(leaf) and visibleOf(u.Root) ~= nil then
				target = drawnOf(leaf) or target
			else
				local shown = visibleOf(u.Root)
				if shown ~= nil then
					target = drawnOf(edgeLeaf(shown, false)) or target
				end
			end
		end
		if not joinable(target, container) then
			return nil
		end
		local position, size = (target.Deco :: Decoration.Decoration).LeafRect()
		return { Target = target, Index = nil, Split = nil, Outer = false, Position = position, Size = size }
	end

	-- the position in `leaf.Members` before the `index`-th shown (open, live) tab; nil or past the last = the end
	local function insertionPoint(leaf: Leaf, index: number?): number
		if index == nil then
			return #leaf.Members + 1
		end
		local shownAt = 0
		for i, m in leaf.Members do
			if isOpenWindow(m.Entry) then
				if shownAt == index then
					return i
				end
				shownAt += 1
			end
		end
		return #leaf.Members + 1
	end

	-- the dragged unit (when `entry` is in one) gives up its own unit; returns it (its tree is moved by the caller)
	local function takeUnit(entry: Entry): Unit?
		local from = unitOf(entry)
		if from ~= nil then
			units[from] = nil
			arranged[from] = nil
		end
		return from
	end

	-- `entry` (a window, or the whole unit it is in) joins the target's leaf as tabs (made when the target is plain):
	-- a split unit's windows all become tabs there, in tree and tab order
	local function joinTabs(entry: Entry, drop: Decoration.Drop)
		local target: Entry = drop.Target
		local from = takeUnit(entry)
		local moving: { Member }
		local selected: Member
		if from ~= nil then
			moving = membersOf(from)
			local face = faceOf(entry)
			selected = (entry.Leaf and memberOf(entry.Leaf, face)) or moving[1]
			for _, m in moving do
				local e = m.Entry
				if e ~= nil then
					e.Leaf = nil
				else
					pendingLeaf[m.Key :: string] = nil
				end
			end
		else
			local alone: Member = { Key = liveKey(entry), Entry = entry }
			selected = alone
			moving = { alone }
			entry.KeptRect = true
		end
		local leaf = target.Leaf or newUnit(target)
		local at = insertionPoint(leaf, drop.Index)
		for i, m in moving do
			table.insert(leaf.Members, at + i - 1, m)
		end
		for _, m in moving do
			local e = m.Entry
			if e ~= nil then
				adopt(e, leaf)
			else
				pendingLeaf[m.Key :: string] = leaf
			end
		end
		leaf.Selected = selected
		gatherKnown()
		renumber()
		local face = drawnOf(leaf)
		if face ~= nil then
			focus(face)
		end
		refresh()
	end

	-- `entry` (a window, or the whole unit it is in — its tree as one side) splits the target's leaf, or the target's
	-- whole unit for an outer band, in half on the drop's side (header SPLITS: the target keeps its rectangle, Ratio 0.5)
	local function splitInto(entry: Entry, drop: Decoration.Drop)
		local target: Entry = drop.Target
		local at = drop.Split :: Decoration.DropSide
		local targetLeaf = target.Leaf or newUnit(target)
		local u = targetLeaf.Unit
		local from = takeUnit(entry)
		local moving: Node
		if from ~= nil then
			moving = from.Root
			adoptTree(moving, u)
		else
			local alone: Member = { Key = liveKey(entry), Entry = entry }
			moving = newLeaf(u, { alone }, alone)
			entry.KeptRect = true
		end
		local beside: Node = if drop.Outer then u.Root else targetLeaf
		local axis, movingFirst = axisOf(at)
		local split: Split = {
			Tag = "Split",
			Axis = axis,
			Ratio = 0.5,
			Children = if movingFirst then { moving, beside } else { beside, moving },
			Parent = nil,
		}
		replaceNode(u, beside, split)
		beside.Parent = split
		moving.Parent = split
		-- (a split unit is expanded: the target was, and only a docked panel collapses)
		u.Collapsed = false
		local movedLeaves: { Leaf } = {}
		leavesIn(moving, movedLeaves)
		for _, leaf in movedLeaves do
			for _, m in leaf.Members do
				local e = m.Entry
				if e ~= nil then
					adopt(e, leaf)
				else
					pendingLeaf[m.Key :: string] = leaf
				end
			end
		end
		restructured(u)
		gatherKnown()
		renumber()
		focus(faceOf(entry))
		refresh()
	end

	local function join(entry: Entry, drop: Decoration.Drop)
		local target: Entry = drop.Target
		local own = unitOf(entry)
		if target == entry or (own ~= nil and unitOf(target) == own) or table.find(order, target) == nil then
			return
		end
		if drop.Split ~= nil then
			splitInto(entry, drop)
		else
			joinTabs(entry, drop)
		end
	end

	-- a splitter drag in progress (header SPLITS)
	local splitDrag: SplitDrag? = nil
	local function dragSplitter(entry: Entry, phase: "Begin" | "Move" | "End", delta: number)
		if phase == "End" then
			splitDrag = nil
			return
		end
		if phase == "Begin" then
			splitDrag = nil
			local leaf = entry.Leaf
			local u = if leaf ~= nil then leaf.Unit else nil
			local arr = if u ~= nil then arranged[u] else nil
			local sp = if arr ~= nil and leaf ~= nil then arr.Splitters[leaf] else nil
			if u == nil or arr == nil or sp == nil or not sp.Enabled then
				return
			end
			local info = arr.Infos[sp.Split]
			local iv, seam = info.Interval, info.At
			local length, start
			if info.Pixel then
				length = iv[4] - iv[2]
				start = seam[2] - iv[2]
			else
				local deco = entry.Deco
				local panel = if deco ~= nil then deco.PanelHeight() else 0
				length = (iv[3] - iv[1]) * panel + (iv[4] - iv[2])
				start = (seam[1] - iv[1]) * panel + (seam[2] - iv[2])
			end
			if length > 0 then
				splitDrag = { Split = sp.Split, Unit = u, Start = start, Length = length, Min1 = info.Min1, Min2 = info.Min2 }
			end
			return
		end
		local d = splitDrag
		if d == nil or not units[d.Unit] then
			return
		end
		local hi = d.Length - d.Min2
		local seam = d.Start + delta
		seam = if hi < d.Min1 then d.Min1 else math.clamp(seam, d.Min1, hi)
		local ratio = math.clamp(seam / d.Length, 0.01, 0.99)
		if ratio ~= d.Split.Ratio then
			-- (one layout build per move: the views and the Ratio in one batch)
			batch(function()
				d.Split.Ratio = ratio
				pushView(d.Unit)
				layoutDirty = true
			end)
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
				-- tree of several tabs becomes a unit (headers TABS, SPLITS) of the windows that may be tabs together
				for _, node in nodes do
					if #node.Keys == 1 then
						place(node.Keys[1], states[node.Keys[1]])
						continue
					end
					-- the unit's container: its first leaf's selected window's when on screen, else the first one's
					local first: Layout.Node = node.Node
					while first.Split ~= nil do
						first = first.Children[1]
					end
					local order_ = { (first :: Layout.TabNode).Selected }
					for _, key in node.Keys do
						table.insert(order_, key)
					end
					local container: Instance? = nil
					for _, key in order_ do
						local e = live[key]
						local root = if e ~= nil then e.Root else nil
						if e ~= nil and groupable(e, nil) and root ~= nil and root.Parent ~= nil then
							container = root.Parent
							break
						end
					end
					local tabbable: { [string]: true } = {}
					local count = 0
					local loose: { string } = {}
					for _, key in node.Keys do
						local e = live[key]
						if e == nil or groupable(e, container) then
							tabbable[key] = true
							count += 1
						else
							table.insert(loose, key)
						end
					end
					if count < 2 then
						for key in tabbable do
							table.insert(loose, key)
						end
						tabbable = {}
					end
					local unitCollapsed = groupCollapsed(node.Collapsed, node.Dock, node.Node.Split ~= nil)
					for _, key in loose do
						place(key, plainState(states[key], node.Position, node.Size, unitCollapsed, node.Dock, node.Width))
					end
					if count < 2 then
						continue
					end
					local fallback: Entry? = nil
					for key in tabbable do
						fallback = fallback or live[key]
					end
					local fh = if fallback ~= nil then fallback.Hints else nil
					local nodePosition, nodeSize = node.Position, node.Size
					local u: Unit = {
						Root = nil :: any,
						FocusLeaf = nil,
						-- (an edge unit without a floating rectangle: a window's own, or Window's default)
						Position = if nodePosition ~= nil
							then Layout.toPosition(nodePosition)
							elseif fh ~= nil then fh.Position:Get()
							else Layout.toPosition(Layout.DEFAULT_POSITION),
						Size = if nodeSize ~= nil
							then Layout.toSize(nodeSize)
							elseif fh ~= nil then fh.Size:Get()
							else Layout.toSize(Layout.DEFAULT_SIZE),
						Collapsed = unitCollapsed,
						Side = node.Dock,
						Width = node.Width or 0,
					}
					-- the saved tree with only the windows that may be tabs (Layout.prune — the rule saving uses: a leaf left
					-- without any is dropped, a split left with one side is that side)
					local kept = Layout.prune(node.Node, savedSides, function(leaf: Layout.Node): boolean
						for _, key in (leaf :: Layout.TabNode).Tabs do
							if tabbable[key] then
								return true
							end
						end
						return false
					end, savedSplit) :: Layout.Node
					local function grow(saved: Layout.Node): Node
						if saved.Split ~= nil then
							local x = grow(saved.Children[1])
							local y = grow(saved.Children[2])
							local split: Split = { Tag = "Split", Axis = saved.Split, Ratio = saved.Ratio, Children = { x, y }, Parent = nil }
							x.Parent = split
							y.Parent = split
							return split
						end
						local members: { Member } = {}
						local selected: Member? = nil
						for _, key in saved.Tabs do
							if tabbable[key] then
								local m: Member = { Key = key, Entry = live[key] }
								table.insert(members, m)
								if key == saved.Selected then
									selected = m
								end
							end
						end
						local leaf = newLeaf(u, members, selected or members[1])
						leaf.Fold = saved.Collapsed == true
						return leaf
					end
					u.Root = grow(kept)
					if u.Root.Tag == "Leaf" then
						u.Root.Fold = false
					end
					units[u] = true
					local all = membersOf(u)
					for _, leaf in leavesOf(u) do
						for _, m in leaf.Members do
							local e = m.Entry
							if e ~= nil then
								e.Leaf = leaf
							else
								pendingLeaf[m.Key :: string] = leaf
							end
						end
					end
					-- (applyMember keeps an open unit off an edge another open window / unit holds — header DOCK)
					for _, m in all do
						local e = m.Entry
						if e ~= nil then
							applyMember(e, states[m.Key :: string], e.Leaf :: Leaf)
						end
					end
					-- every window on the unit's (fitted) dock width
					if u.Side ~= nil then
						setUnitSide(u, u.Side, u.Width)
					end
					pushView(u)
					for _, m in all do
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
				Leaf = nil,
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
					-- forget it. A keyed tab stays a (pending) tab of its leaf; any other leaves it (header TABS).
					local key = entry.Key
					local g = entry.Leaf
					local stays = false
					local forgot = false
					if key ~= nil and live[key] == entry then
						live[key] = nil
						if forgetting[key] then
							-- (the layout is rebuilt below, once the member is out of its leaf: a forgotten key has no state)
							forgetting[key] = nil
							table.remove(known, table.find(known, key) :: number)
							forgot = true
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
						entry.Leaf = nil
						local m = memberOf(g, entry) :: Member
						if stays then
							m.Entry = nil
							pendingLeaf[key :: string] = g
							pushView(g.Unit)
						else
							dropMember(g, table.find(g.Members, m) :: number)
						end
						refresh()
					elseif forgot then
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
						-- takes its place in its leaf (header TABS).
						local waiting = pending[key]
						remember(key)
						live[key] = entry
						if waiting ~= nil then
							pending[key] = nil
							local g = pendingLeaf[key]
							if g ~= nil and hints.NoTitleBar then
								-- a window that cannot be a tab (header TABS) is placed as if alone in its node, and
								-- its tab is dropped
								local u = g.Unit
								local plain = plainState(waiting, Layout.positionOf(u.Position), Layout.sizeOf(u.Size), u.Collapsed, u.Side, u.Width)
								leavePending(key)
								apply(entry, plain)
							elseif g ~= nil then
								pendingLeaf[key] = nil
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
						-- it are saved; an unchanged layout emits nothing). A unit docks and undocks as one.
						Dock = function(side: Side, width: number)
							local u = unitOf(entry)
							if u ~= nil then
								setUnitSide(u, side, width)
								pushView(u)
							else
								entry.DockWidth:SetIfChanged(width)
								entry.Side:SetIfChanged(side)
							end
							settle(entry)
							refresh()
						end,
						Undock = function()
							local u = unitOf(entry)
							if u ~= nil then
								setUnitSide(u, nil, nil)
								pushView(u)
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
							local u = unitOf(entry)
							if u == nil then
								return
							end
							if position ~= nil then
								u.Position = position
							end
							if size ~= nil then
								u.Size = size
							end
							pushView(u)
						end,
						MinSize = function(): Vector2
							local u = unitOf(entry)
							if u == nil then
								return floorOf(entry)
							end
							return unitFloor(u)
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
							local g = entry.Leaf
							if g ~= nil and isOpenWindow(entry) then
								focus(entry)
							end
						end,
						MoveTab = function(index: number)
							local g = entry.Leaf
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
						-- this window's Collapsed or dock width changed by the app or its own parts (header SPLITS). The dock
						-- width is the unit's only while it is docked. Collapsed: unsplit, the whole group follows; in a split,
						-- true folds its leaf where the fold rule allows (else it is refused — written back, as the arrow is not
						-- offered there; it is recorded also while the panel is collapsed) and false unfolds it and expands a
						-- collapsed panel (the panel itself collapses by its strip: CollapseUnit)
						Sync = function(what: "Collapsed" | "DockWidth")
							local g = entry.Leaf
							if quiet > 0 or g == nil then
								return
							end
							local u = g.Unit
							if what == "DockWidth" then
								local w = entry.DockWidth:Get()
								if u.Side == nil or w == u.Width then
									return
								end
								u.Width = w
								quiet += 1
								for _, m in membersOf(u) do
									local e = m.Entry
									if e ~= nil and e ~= entry then
										e.DockWidth:SetIfChanged(w)
									end
								end
								quiet -= 1
								return
							end
							local c = hints.Collapsed:Get()
							local split = isSplit(u)
							if not split then
								if c == u.Collapsed then
									return
								end
								u.Collapsed = c
							elseif c then
								if g.Fold then
									return
								end
								if not canFold(g) then
									if not collapsedOf(g) then
										quiet += 1
										hints.Collapsed:Set(false)
										quiet -= 1
									end
									return
								end
								g.Fold = true
							else
								if not g.Fold and not u.Collapsed then
									return
								end
								g.Fold = false
								u.Collapsed = false
							end
							spreadCollapsed(u)
							if split then
								pushView(u)
							end
						end,
						CollapseUnit = function(c: boolean)
							local u = unitOf(entry)
							if u == nil then
								hints.Collapsed:Set(c)
								return
							end
							if u.Collapsed ~= c then
								-- (one layout build: pushView inside a batch, flushed once)
								batch(function()
									u.Collapsed = c
									spreadCollapsed(u)
									pushView(u)
									layoutDirty = true
								end)
							end
						end,
						Splitter = function(phase: "Begin" | "Move" | "End", delta: number)
							dragSplitter(entry, phase, delta)
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
					local g = entry.Leaf
					if g ~= nil then
						local u = g.Unit
						local m = memberOf(g, entry) :: Member
						if open then
							-- back in its leaf at its tab, selected (header TABS; an import selects nothing — its saved
							-- selection stands; a hidden leaf of a split shows again at its place); a unit whose edge another
							-- one took while all its windows were closed opens floating
							if importing == 0 then
								g.Selected = m
							end
							local at = u.Side
							if at ~= nil and occupant(at, entry) ~= nil then
								setUnitSide(u, nil, nil)
							end
						elseif g.Selected == m then
							local i = table.find(g.Members, m) :: number
							g.Selected = neighbour(g, i + 1, i - 1)
						end
						pushView(u)
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
