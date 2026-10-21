--!strict
--[[
	Window decoration (internal, compositor side): what the WindowManager draws AROUND a window's surface — the frame
	(background, border, corner), the title bar and the resize grip — and the moving / resizing / staying-on-screen /
	edge-docking behaviour that goes with them. Wayland's server-side decorations: Window (the client) returns only its
	content surface, and the compositor (the manager) owns everything around it. Made by `Manager` through the
	Compositor port, never by Window directly.

	Instances (made here, placed by the manager as SIBLINGS of the surface root, in its parent):
		WindowDecoration (Frame, the outer rectangle: Position / Size, title bar included; the panel while docked)
			UICorner, UIStroke, ClickSink (TextButton, ZIndex 0), TitleBar (Window/TitleBar.luau)
		WindowIcon (TextButton, the collapsed floating window — see COLLAPSED = ICON)
			UICorner, UIStroke, Image (ImageLabel, only with an `Icon` hint)
		WindowDockStrip (TextButton, the docked window's strip at the screen edge — see DOCKED)
			Arrow (ImageLabel)
		WindowResizeGrip (ImageButton, anchored at the outer rectangle's bottom-right corner; floating only)
		WindowDockResize (TextButton, the docked panel's width handle along its inner edge; docked only)
		WindowTab (TextButton, this window's tab in its group's tab strip — see TABS)
			Title (TextLabel), CloseButton (ImageButton > Icon)
		WindowDockPreview (Frame, the drop preview while a drag is over an edge or a window it would join or split — see
			DOCKED, TABS and SPLITS)
		WindowFoldBar (TextButton, this window's leaf folded inside a left | right split — see SPLITS)
			Arrow (ImageLabel)
		WindowSplitter (TextButton, the seam of a split this window's leaf draws — see SPLITS)
	The grip and the dock handle are left out with NoResize, the preview with NoMove or NoTitleBar, the tab and the fold
	bar with NoTitleBar, the splitter with NoTitleBar or NoResize, the tab's close button with NoClose. The frame sits
	BELOW the surface (it paints the background the surface is drawn on) and the grip ABOVE it (it overlaps the
	content's corner): the manager gives each window three consecutive ZIndex ranks (frame, surface, grip). The icon,
	the strip, the dock handle and the fold bar take the grip's rank; a tab and a splitter take their unit's top rank
	(`GroupView.TabZ`, the grip rank of the unit's highest window); the preview takes the one above the higher of the
	two (the drag raised the window first, so it draws over every window).

	COLLAPSED = ICON [2026-10-20 user decision — one `Collapsed`, its look decided by where the window is]: a collapsed
	floating window shows only a small square icon (2 x FrameHeight) at its `Position` (the outer rectangle's top-left,
	so expanding opens the window right where the icon was). Its picture is the `Icon` hint (an image id), else the first
	letter of the title on a rounded square — no uploaded image needed. Pressing the icon expands the window
	(`Collapsed:Set(false)`); dragging it moves the window (writes `Position`, kept on screen like a title-bar drag with
	the icon as the window). Press and drag are told apart by a few pixels of movement (Window/PressOrDrag.luau). A
	gamepad / keyboard activation of the selected icon expands too. There is no "title bar only" collapsed look.
	Dragging the icon never docks.

	DOCKED [2026-10-20 user decisions — docking stage 2, edge docking]: the manager says which screen edge the window is
	docked on (`Control.Side`, nil = floating) and how wide its panel is (`Control.DockWidth`). A docked window is laid
	out from the edge of its container (the surface root's parent): a strip `FrameHeight` wide over the container's
	full height at the edge, then the panel (frame, title bar, surface) right inside it — `|strip|panel|` on the left,
	mirrored on the right. The panel's height is the container's (`UDim2` Y scale 1: the engine follows a resize; the
	surface gets the rest under the title bar, so `AvailableSize` follows too). The Position / Size Sources keep the
	FLOATING rectangle meanwhile and are not read for the layout (an app writing them moves nothing until the window
	floats again). Collapsed while docked = the panel is hidden and only the strip stays (no icon). The strip's arrow
	points to where the panel goes: `>` for a collapsed left dock, `<` for an expanded one, the other way round on the
	right (Style.Icons.RightTriangle turned 180 degrees). Pressing the strip, by the focus BEFORE the press
	(`Control.FocusedBeforePress` — the manager's global press focuses first, the strip's Activated comes after):
	collapsed -> expand, raise and focus; expanded without the focus -> raise and focus; expanded with the focus ->
	collapse. A gamepad / keyboard activation (no global press) uses the current focus. The width handle along the
	panel's inner edge sets the dock width, kept in [MinSize.X (default 2 x FrameHeight), half the container's width]
	(also when the container shrinks).
	Docking: while the title bar (or a tab — TABS) is dragged, a pointer within the strip width of the container's left
	or right edge shows a preview of the strip and panel (a decoration part in the window's container, input-less — drawn by the
	compositor like the strip, so it shows whichever Overlay the app mounts, or none [2026-10-21 user decision; it
	was a popup of the default Overlay and did not show where that layer was not mounted, e.g. a UI Labs story]),
	and releasing there docks the window (its Position goes back to
	where the drag began — the floating rectangle it keeps). The first dock width is the window's Size.X in the range
	above; docking again uses the dock width it keeps. Not offered when that edge is held by another open window or
	group (then the drag JOINS that group as a tab when it may — TABS), with NoDock (any window of a dragged group), or
	from the icon; NoMove has no drag at all.
	Undocking: dragging a docked window's title bar past the press-or-drag threshold makes it float again, at its kept
	Size, placed so the pointer holds the same spot of its title bar, and the drag goes on (NoMove: no undock).

	TABS [2026-10-21 user decisions — docking stage 3, tab groups]: the manager may put several windows in one GROUP —
	one rectangle, one decoration, one surface shown at a time. Nothing is reparented: every window of a group keeps
	its own decoration, and the manager tells each one through `Control.Group` (a `GroupView`, nil = a plain window)
	where the group is and whether it is the one DRAWN (the selected window: its frame, title bar / strip, grip, dock
	strip and icon show; the others' are hidden, and so is their surface). While grouped, the frame follows the group's
	rectangle (`GroupView.Position` / `Size`) and every move / resize writes the GROUP's rectangle (`Control.SetRect`),
	never the window's own Position / Size Sources, which keep the rectangle it had before it joined.
	The tab strip: with two or more OPEN windows in the group the drawn window's title bar becomes the strip (its title
	and close button hide — Window/TitleBar.luau "TAB STRIP"; with one open window the group looks like a plain window — except inside a split, header SPLITS).
	Each open window shows its own `WindowTab` over that row, all laid out by `tabSlots` (the one place that decides
	where the strip and its tabs sit): after the collapse arrow, as wide as `TAB_IDEAL` x FrameHeight each, shrinking
	evenly down to `TAB_MIN` x FrameHeight when they do not fit (title truncated), and leaving `TAB_GRAB` x FrameHeight
	at the strip's right end free (the empty area that drags the group). A tab is `Tab` / `TabHovered` and the
	selected one `TabActive`; its close button shows on the selected tab and on the hovered one (none with that
	window's NoClose) and asks that window's OnCloseRequest like the title bar's. Pressing a tab selects it (and the
	manager's press focuses the group); dragging it inside the strip row moves it among the tabs, and dragging it out of
	the row (above or below it, or past the group's sides) takes the window out of the group: it floats at its own
	kept Size (the group's when it has none), placed so the pointer holds the same spot of its title bar, and the drag
	goes on as a title-bar drag (it may dock or join elsewhere; NoMove: the tab only reorders).
	Joining: during a title-bar drag (a window, or a group by the strip's empty area) or a dragged-out tab the pointer
	is judged over the topmost OTHER window under it (`Control.DropAt`): only a window or group the manager's
	eligibility rules let it join is judged — anything else on top (a NoTitleBar window, an icon, a window of another
	container is not in the walk) covers what is beneath and nothing happens. On a joinable one:
	its title-bar / strip row -> joins as a tab where the pointer is among the tabs (`InsertAt`); else its centre
	(x and y in [0.2, 0.8] of its outer rectangle) -> joins as the last tab; the four 20% bands split it (SPLITS —
	[2026-10-21 user decision, docking stage 4]; they were empty in stage 3). The row wins over the top band. A
	screen-edge band held by an open group joins that group (`Control.EdgeJoin`). The preview then covers the target's
	whole outer rectangle (a leaf's, in a split); releasing there joins (`Control.Join` — the dragged window's Position
	goes back to where the drag began, its kept rectangle). A tab torn out and joined elsewhere in the same drag keeps
	the tear-off point as its kept Position (the drag began there — the same as a window undocked and docked again in
	one drag).

	SPLITS [2026-10-21 user decisions — docking stage 4, Dear ImGui's shape; the tree and its rules are Window/Manager
	header SPLITS]: in a split unit `GroupView.Box` places this window's leaf inside the unit's rectangle (each boundary
	a fraction of the unit's length plus pixels: a docked panel's height is the container's), and the frame, strip,
	tabs and surface follow that box; the unit's own rectangle (`UnitRect`) still holds the grip, and only the LEAD
	window (`GroupView.Lead`, the bottom-right leaf's) draws the grip, the dock strip and the width handle. Every leaf
	shows its tab strip, even with one open window. Dropping on a 20% band of a leaf splits that leaf in half on that
	side; on the band 2 x FrameHeight inside a split unit's outer edges, the whole unit (the strip row still wins); the
	preview covers the half the dropped window will take (`Drop.Position` / `Size`). The splitter (`WindowSplitter`,
	drawn by the second side's first leaf over the seam — over the second side's leading edge for a left | right split,
	over the first side's bottom for a top / bottom one, so it covers neither a scrollbar nor a tab row; the
	ResizeGrip look) moves the seam (`Control.Splitter`, in window units; the manager keeps both sides above their
	floors); it hides while a side is folded (at most one side is — the manager's fold rule). A folded leaf (`GroupView.Fold`, its window's Collapsed): along a top /
	bottom split its frame is just the strip row (the arrow points right, the surface hides); along a left | right split
	it is a bar FrameHeight wide (`WindowFoldBar`, the strip's look, its arrow pointing where the leaf opens, the title
	bar and tabs hidden) — pressing the bar unfolds it. In a split the window's Collapsed is its leaf's fold, so the
	icon never shows for a floating split, and a docked split panel collapses as a whole by its strip
	(`Control.CollapseUnit`; `GroupView.PanelCollapsed`). Dragging the strip's empty area moves the whole unit; off a
	docked panel the whole unit floats, the pointer keeping its share of the unit's width and its place in the pressed
	leaf.

	Why the background and border are decoration, not surface: they enclose the whole outer rectangle (title bar
	included), which only the compositor knows; a collapsed window swaps the whole frame for its icon, which only the
	compositor draws; and a group of surfaces (tabs) shares one frame. The surface stays transparent, and a
	press on its empty area falls through to the frame's ClickSink right under it (still this window's chunk).

	The surface's placement is answered here too (`Surface`): under the title bar, the rest of the frame, shown while
	open and not collapsed. Position / Size keep their meaning — the floating window's OUTER rectangle, title bar
	included (an app that sizes its content as `Size - <title allowance>` keeps working while it floats).

	STAYING ON SCREEN (Dear ImGui `ClampWindowPos`, imgui.cpp — `DisplayWindowPadding` 19 at the default size, applied
	with the title bar as the window's height when the window moves by its title bar only): the window's top-left is
	kept in [pad - width, W - pad] x [pad - band, H - pad] of its container (W x H = the container's size, pad =
	max(FrameHeight, DisplaySafeAreaPadding) — FrameHeight is 19 at the default size like ImGui's padding and scales
	with the style; band = the title bar height, or the window height without a title bar). With the title bar that
	is: at least `pad` pixels of the title bar stay inside horizontally and the whole title bar vertically (its top
	never goes above the container). A dock strip of another open window in the same container is a wall [2026-10-20
	user decision — floating windows never enter the strip]: on that side the window's edge stops at the strip
	(`Control.Insets`), the panel itself is not a wall (it covers). Applied (1) while dragging the title bar, (2) when
	the container SHRINKS (its AbsoluteSize gets smaller in either axis, not to zero) and (3) when a strip appears
	(`Reclamp`, called by the manager) — then an out-of-bounds window is brought back in by writing the Position
	Source. A position the program sets is otherwise left alone (also one outside the container), and a container
	that grows clamps nothing. A docked window is not clamped (it is laid out from the edge).
]]

local Quad = require("../Quad")
local q = Quad
local Frame = q.Elem "Frame"
local ImageButton = q.Elem "ImageButton"
local TextButton = q.Elem "TextButton"
local UIStroke = q.Elem "UIStroke"
local ImageLabel = q.Elem "ImageLabel"
local UICorner = q.Elem "UICorner"
local TextLabel = q.Elem "TextLabel"
local UIPadding = q.Elem "UIPadding"
local Input = require("../Input")
local Interaction = require("../Interaction")
local Style = require("../Style")
local Util = require("../Util")
local Visibility = require("../Visibility")
local Layout = require("./Layout")
local PressOrDrag = require("./PressOrDrag")
local TitleBar = require("./TitleBar")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style
type Side = Layout.Side

-- what a surface tells its compositor (Window's props of the same names)
export type Hints = {
	Style: Style,
	Title: string | State<string>,
	Position: Source<UDim2>,
	Size: Source<Vector2>,
	Open: Source<boolean>,
	Collapsed: Source<boolean>,
	NoTitleBar: boolean,
	NoResize: boolean,
	NoMove: boolean,
	NoClose: boolean,
	NoCollapse: boolean,
	NoDock: boolean, -- not docked by a drag (a layout may still dock it)
	OnCloseRequest: (() -> ())?, -- the close button asks the app instead of closing
	MinSize: Vector2?,
	Icon: string?,
	Key: string?, -- the window's identity in its manager (saved in the layout); nil = left out of the layout
	Kind: string?, -- the window's type (factory lookup on load); defaults to Key
}

-- where the compositor puts the surface root
export type Placement = {
	Position: State<UDim2>,
	Size: State<UDim2>,
	Visible: State<boolean>,
}

-- where a folded leaf sits in its split (header SPLITS): the side of the split's rectangle it keeps
export type FoldSide = "Left" | "Right" | "Top" | "Bottom"
-- the side of a target a drop splits off (header SPLITS)
export type DropSide = "Left" | "Right" | "Top" | "Bottom"

-- the splitter a window draws (header SPLITS): its box in the unit's rectangle (the same encoding as GroupView.Box)
export type SplitterView = {
	Axis: "LeftRight" | "TopBottom",
	Box: { number },
	Enabled: boolean, -- false while a side is folded (or a window of the unit has NoResize)
}

-- what the manager tells a window of a unit (headers TABS, SPLITS); nil = a plain window
export type GroupView = {
	Position: UDim2, -- the unit's floating outer rectangle
	Size: Vector2,
	-- this window's leaf in the unit's rectangle: { x0f, x0p, x1f, x1p, y0f, y0p, y1f, y1p } — each boundary a
	-- fraction f of the unit's length plus p pixels; nil = the whole unit (a tab group, or a hidden leaf)
	Box: { number }?,
	Drawn: boolean, -- this window draws its leaf (the selected one)
	Lead: boolean, -- this window draws the unit's own parts (grip, dock strip and handle, icon)
	Tabbed: boolean, -- the tab strip replaces the title bar (two or more open windows; any open window in a split)
	TabIndex: number?, -- this window's tab among the shown ones (0-based); nil = no tab (closed, or not tabbed)
	TabCount: number, -- the shown tabs
	TabZ: number, -- the ZIndex of the tabs and splitters (the unit's top grip rank)
	-- the flags (any window's NoMove; any open window's NoResize; the leaf's open windows' NoCollapse — and a leaf of
	-- a split with nothing to fold against; any window's NoDock)
	NoMove: boolean,
	NoResize: boolean,
	NoCollapse: boolean,
	NoDock: boolean,
	Split: boolean, -- the unit is split (its Collapsed is the docked panel's; a leaf folds)
	Fold: FoldSide?, -- this window's leaf is folded inside its split
	PanelCollapsed: boolean, -- (a split unit) its docked panel is collapsed
	Splitter: SplitterView?,
}

-- what a drag would do to a window or unit (Control.DropAt / EdgeJoin): `Index` = join as a tab before that shown tab
-- (nil = the last); `Split` = split off that side instead (`Outer`: of the whole unit, else of the target's leaf);
-- `Position` / `Size` = the preview's rectangle in the container
export type Drop = {
	Target: any,
	Index: number?,
	Split: DropSide?,
	Outer: boolean,
	Position: UDim2,
	Size: UDim2,
}

-- what a drag would do on release (an edge to dock on, or a group to join)
type Candidate = { Side: Side?, Drop: Drop? }

-- what the manager hands the decoration
export type Control = {
	BackZ: State<number>, -- the frame (below the surface)
	FrontZ: State<number>, -- the grip (above the surface)
	Focused: State<boolean>,
	Raise: () -> (),
	Changed: (() -> ())?, -- Position / Size / Open / Collapsed / the dock changed (the manager's Layout output; keyed windows)
	-- the dock (header DOCKED): the manager owns the side (one open window per side) and the width
	Side: State<Side?>, -- the edge this window is docked on; nil = floating (kept while closed)
	DockWidth: Source<number>,
	SideTaken: (side: Side) -> boolean, -- another open window holds that edge
	Dock: (side: Side, width: number) -> (),
	Undock: () -> (),
	Insets: () -> (number, number), -- the strip widths (left, right) that wall this floating window in its container
	FocusedBeforePress: () -> boolean, -- this window had the focus before the press now being released (strip rule)
	-- tab groups (header TABS)
	Group: State<GroupView?>,
	SetRect: (position: UDim2?, size: Vector2?) -> (), -- a grouped window: write the group's rectangle
	MinSize: () -> Vector2, -- the resize floor (a group's: the largest of its windows' per axis)
	DropAt: (x: number, y: number) -> Drop?, -- the window / group under the pointer a drag of this window would join
	EdgeJoin: (side: Side) -> Drop?, -- the group holding that edge, when a drag of this window may join it
	Join: (drop: Drop) -> (), -- join it (this window, or this window's whole group)
	SelectTab: () -> (),
	MoveTab: (index: number) -> (), -- move this window's tab to that shown slot (0-based)
	DetachTab: () -> (), -- take this window out of its group (it floats; header TABS)
	Sync: (what: "Collapsed" | "DockWidth") -> (), -- this window's Collapsed / dock width changed: the unit follows (header SPLITS)
	CollapseUnit: (collapsed: boolean) -> (), -- a split unit's docked panel collapses / expands (its strip)
	Splitter: (phase: "Begin" | "Move" | "End", delta: number) -> (), -- this window's splitter dragged (window units)
}

export type Decoration = {
	Parts: { Instance },
	Frame: Frame, -- the outer frame (WindowDecoration; a leaf's in a split unit)
	LeafRect: () -> (UDim2, UDim2), -- the frame's Position / Size in the container
	UnitRect: () -> (UDim2, UDim2), -- the whole unit's (= LeafRect unsplit)
	PanelHeight: () -> number, -- a docked panel's height in window units (0 when unknown)
	InsertAt: (x: number) -> number, -- the shown tab a drop at screen x would go before (count = after the last)
	RowHeight: () -> number, -- the title-bar / strip row's height in screen pixels
	Surface: Placement,
	SetParent: (parent: Instance?) -> (),
	Reclamp: () -> (), -- a strip appeared: bring this floating window out of it (the container-shrink path)
	FitDockWidth: (width: number) -> number, -- the dock width range for this window in its container now
	Destroy: () -> (),
}

local Decoration = {}

-- a tab's width in FrameHeights: as wide as TAB_IDEAL, shrinking evenly down to TAB_MIN when the tabs overflow the strip
-- (Dear ImGui's tabs size to their label; the kit has no text measuring, so a tab is as wide as a short title)
local TAB_IDEAL = 8
local TAB_MIN = 2
-- the strip's right end kept free of tabs (FrameHeights), so a group whose tabs would fill its strip can still be
-- grabbed by the strip's empty area (Studio: two tabs in a 280 px window left a 5 px sliver)
local TAB_GRAB = 2
-- the drop zones of a target's outer rectangle (header TABS): the centre joins, the bands around it are for splits
local CENTRE_LO, CENTRE_HI = 0.2, 0.8
Decoration.CENTRE_LO = CENTRE_LO
Decoration.CENTRE_HI = CENTRE_HI

-- a part destroyed by the engine (its parent went first) is no longer quad's: leave it alone (its Parent is locked)
local function alive(inst: Instance): boolean
	return q.Backend.isClaimed(inst)
end

-- AbsoluteSize is in screen pixels, Position offsets in the window's own units: an ancestor UIScale divides
local function scaleOf(f: GuiObject?, width: number): number
	if f == nil then
		return 1
	end
	local abs = f.AbsoluteSize
	return if width > 0 and abs.X > 0 then abs.X / width else 1
end

-- the container of a decoration part, when it has an on-screen rectangle
local function containerOf(f: GuiObject?): GuiBase2d?
	local container = if f then f.Parent else nil
	if container == nil or not Visibility.hasArea(container) then
		return nil
	end
	return container :: GuiBase2d
end

-- a part of the unit's extent along one axis (header SPLITS): from f0 x length + p0 to f1 x length + p1 after `origin`
-- (both ends rounded, so neighbouring leaves meet without a gap)
local function sub(origin: UDim, length: UDim, f0: number, p0: number, f1: number, p1: number): (UDim, UDim)
	local startOffset = math.round(origin.Offset + f0 * length.Offset + p0)
	local endOffset = math.round(origin.Offset + f1 * length.Offset + p1)
	return UDim.new(origin.Scale + f0 * length.Scale, startOffset), UDim.new((f1 - f0) * length.Scale, endOffset - startOffset)
end

function Decoration.new(hints: Hints, control: Control): Decoration
	local style = hints.Style
	local position = hints.Position
	local size = hints.Size
	local open = hints.Open
	local collapsed = hints.Collapsed
	local side = control.Side
	local dockWidth = control.DockWidth
	local stripWidth = style.FrameHeight
	local view = control.Group

	-- title bar height (0 without a title bar)
	local noHeight: State<number> = q.Source(0)
	local titleHeight: State<number> = if hints.NoTitleBar then noHeight else style.FrameHeight

	-- how far the Roblox top bar reaches into the container (window units): a docked panel starts below it, the strip
	-- keeps the full height [2026-10-20 user decision — the top bar's buttons sit there]. 0 for a container already
	-- under the bar (a ScreenGui without IgnoreGuiInset)
	local panelTop: Source<number> = q.Source(0)

	-- the floating outer rectangle the decoration is drawn at: the window's own, or its group's (header TABS)
	local rectPos: State<UDim2> = position:Compute(function(self, _prev, v)
		local g = v:Get()
		return if g ~= nil then g.Position else self:Get()
	end, view)
	local rectSize: State<Vector2> = size:Compute(function(self, _prev, v)
		local g = v:Get()
		return if g ~= nil then g.Size else self:Get()
	end, view)
	-- writes go to the group while grouped (the window's own Sources keep the rectangle it had before it joined)
	local function setPos(p: UDim2)
		if view:Get() ~= nil then
			control.SetRect(p, nil)
		else
			position:Set(p)
		end
	end
	local function setSize(s: Vector2)
		if view:Get() ~= nil then
			control.SetRect(nil, s)
		else
			size:Set(s)
		end
	end
	local function flagOf(name: "NoMove" | "NoResize" | "NoCollapse"): State<boolean>
		return view:Compute(function(self)
			local g = self:Get()
			if g == nil then
				return true
			end
			return not (if name == "NoMove" then g.NoMove elseif name == "NoResize" then g.NoResize else g.NoCollapse)
		end)
	end
	local canMove: State<boolean> = flagOf("NoMove")
	local canResize: State<boolean> = flagOf("NoResize")
	local canCollapse: State<boolean> = flagOf("NoCollapse")
	-- docking by a drag: this window's NoDock, or any of its group's
	local function noDock(): boolean
		local g = view:Get()
		return if g ~= nil then g.NoDock else hints.NoDock
	end
	local drawn: State<boolean> = view:Compute(function(self)
		local g = self:Get()
		return g == nil or g.Drawn
	end)
	-- this window draws the unit's own parts (the grip, the dock strip and handle, the icon — header SPLITS)
	local lead: State<boolean> = view:Compute(function(self)
		local g = self:Get()
		return g == nil or g.Lead
	end)
	local tabbed: State<boolean> = view:Compute(function(self)
		local g = self:Get()
		return g ~= nil and g.Tabbed
	end)
	-- its leaf folded inside a split (header SPLITS): Left / Right = a bar with the arrow, Top / Bottom = its strip row
	local fold: State<FoldSide?> = view:Compute(function(self): FoldSide?
		local g = self:Get()
		return if g ~= nil then g.Fold else nil
	end)
	local barFolded: State<boolean> = fold:Compute(function(self)
		local f = self:Get()
		return f == "Left" or f == "Right"
	end)
	local rowFolded: State<boolean> = fold:Compute(function(self)
		local f = self:Get()
		return f == "Top" or f == "Bottom"
	end)

	-- hidden behind its icon or its dock strip: a split unit's docked panel collapsed, else this window's Collapsed (in
	-- a split the window's Collapsed is its leaf's fold — header SPLITS)
	local iconic: State<boolean> = collapsed:Compute(function(self, _prev, v)
		local g = v:Get()
		if g ~= nil and g.Split then
			return g.PanelCollapsed
		end
		return self:Get()
	end, view)
	local function setIconic(value: boolean)
		local g = view:Get()
		if g ~= nil and g.Split then
			control.CollapseUnit(value)
		else
			collapsed:Set(value)
		end
	end
	local expanded: State<boolean> = iconic:Compute(function(self)
		return not self:Get()
	end)
	local docked: State<boolean> = side:Compute(function(self)
		return self:Get() ~= nil
	end)
	-- open and expanded (this window's own; a tab shows on it)
	local present: State<boolean> = open:Compute(function(self, _prev, isExpanded)
		return self:Get() and isExpanded:Get()
	end, expanded)
	-- ... and drawing its group (the frame, the surface)
	local shown: State<boolean> = present:Compute(function(self, _prev, isDrawn)
		return self:Get() and isDrawn:Get()
	end, drawn)
	local floatingShown: State<boolean> = shown:Compute(function(self, _prev, isDocked)
		return self:Get() and not isDocked:Get()
	end, docked)
	local dockedShown: State<boolean> = shown:Compute(function(self, _prev, isDocked)
		return self:Get() and isDocked:Get()
	end, docked)
	local stripShown: State<boolean> = open:Compute(function(self, _prev, isDocked, isLead)
		return self:Get() and isDocked:Get() and isLead:Get()
	end, docked, lead)

	-- the unit's outer rectangle in the container: its floating one, or the panel at its edge
	local unitPosition: State<UDim2> = rectPos:Compute(function(self, _prev, at, w, sw, top)
		local edge = at:Get()
		if edge == "Left" then
			return UDim2.fromOffset(sw:Get(), top:Get())
		elseif edge == "Right" then
			return UDim2.new(1, -(sw:Get() + w:Get()), 0, top:Get())
		end
		return self:Get()
	end, side, dockWidth, stripWidth, panelTop)
	local unitSize: State<UDim2> = rectSize:Compute(function(self, _prev, at, w, top)
		if at:Get() ~= nil then
			return UDim2.new(0, w:Get(), 1, -top:Get())
		end
		local s = self:Get()
		return UDim2.fromOffset(s.X, s.Y)
	end, side, dockWidth, panelTop)
	-- this window's frame: its leaf's box inside the unit's rectangle (header SPLITS), the whole unit otherwise
	local function boxRect(position: UDim2, extent: UDim2, box: { number }): (UDim2, UDim2)
		local x, w = sub(position.X, extent.X, box[1], box[2], box[3], box[4])
		local y, h = sub(position.Y, extent.Y, box[5], box[6], box[7], box[8])
		return UDim2.new(x, y), UDim2.new(w, h)
	end
	local framePosition: State<UDim2> = unitPosition:Compute(function(self, _prev, extent, v)
		local g = v:Get()
		local box = if g ~= nil then g.Box else nil
		if box == nil then
			return self:Get()
		end
		local p = boxRect(self:Get(), extent:Get(), box)
		return p
	end, unitSize, view)
	local frameSize: State<UDim2> = unitSize:Compute(function(self, _prev, at, v)
		local g = v:Get()
		local box = if g ~= nil then g.Box else nil
		if box == nil then
			return self:Get()
		end
		local _, s = boxRect(at:Get(), self:Get(), box)
		return s
	end, unitPosition, view)
	local iconShown: State<boolean> = open:Compute(function(self, _prev, isIconic, isDocked, isLead)
		return self:Get() and isIconic:Get() and not isDocked:Get() and isLead:Get()
	end, iconic, docked, lead)
	-- the surface: shown while its frame is, and its leaf is not folded
	local surfaceShown: State<boolean> = shown:Compute(function(self, _prev, f)
		return self:Get() and f:Get() == nil
	end, fold)
	local iconSide: State<number> = style.FrameHeight:Compute(function(self)
		return self:Get() * 2
	end)

	local surfacePosition: State<UDim2> = framePosition:Compute(function(self, _prev, titleH)
		local p = self:Get()
		return UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + titleH:Get())
	end, titleHeight)
	local surfaceSize: State<UDim2> = frameSize:Compute(function(self, _prev, titleH)
		local s = self:Get()
		if s.Y.Scale ~= 0 then
			return UDim2.new(s.X.Scale, s.X.Offset, s.Y.Scale, s.Y.Offset - titleH:Get())
		end
		return UDim2.fromOffset(s.X.Offset, math.max(0, s.Y.Offset - titleH:Get()))
	end, titleHeight)

	local gripPosition: State<UDim2> = rectPos:Compute(function(self, _prev, sz)
		local p, s = self:Get(), sz:Get()
		return UDim2.new(p.X.Scale, p.X.Offset + s.X, p.Y.Scale, p.Y.Offset + s.Y)
	end, rectSize)
	local gripSize: State<UDim2> = style.Metrics.TextSize:Compute(function(self, _prev, padding)
		local s = self:Get() + padding:Get().X
		return UDim2.fromOffset(s, s)
	end, style.Metrics.FramePadding)

	-- assigned right after the frame / icon are built; read only from event handlers
	local frame: Frame? = nil
	local iconButton: TextButton? = nil
	-- screen pixels per window unit, measured on the frame (a leaf's frame in a split: its own width)
	local function frameScale(): number
		return scaleOf(frame, frameSize:Get().X.Offset)
	end

	-- the width range of a dock panel (header DOCKED): [MinSize.X or 2 x FrameHeight (a group's: its largest), half the
	-- container's width]
	local function fitDockWidth(width: number): number
		local floor = control.MinSize().X
		local w = width
		local f = frame
		local container = containerOf(f)
		if container ~= nil and container.AbsoluteSize.X > 0 then
			local half = container.AbsoluteSize.X / frameScale() / 2
			w = math.min(w, half)
		end
		return math.round(math.max(floor, w))
	end

	-- the width a drag docks at: the window's floating width the first time, then the dock width it keeps (0 = never
	-- docked)
	local function dropWidth(): number
		local kept = dockWidth:Get()
		return fitDockWidth(if kept > 0 then kept else rectSize:Get().X)
	end

	-- keep the window reachable inside its container (header "STAYING ON SCREEN"); `pos` unchanged when it already is
	local function clampToContainer(pos: UDim2): UDim2
		if side:Get() ~= nil then
			return pos -- docked: laid out from the edge
		end
		-- a collapsed window is its icon: the icon is the whole window (its band too)
		local isIcon = iconic:Get()
		local f: GuiObject? = if isIcon then iconButton else frame
		local container = containerOf(f)
		if f == nil or container == nil then
			return pos
		end
		local area = container.AbsoluteSize
		if area.X <= 0 or area.Y <= 0 then
			return pos -- (a zero-sized container: minimised / not laid out yet — Dear ImGui skips it too)
		end
		local s = rectSize:Get()
		local titleH = titleHeight:Get()
		local iconW = iconSide:Get()
		local w = if isIcon then iconW else s.X
		local h = if isIcon then iconW else s.Y
		local scale = if isIcon then scaleOf(f, w) else frameScale()
		local cw, ch = area.X / scale, area.Y / scale
		local safe = style.Metrics.DisplaySafeAreaPadding:Get()
		local frameH = style.FrameHeight:Get()
		local padX, padY = math.max(frameH, safe.X), math.max(frameH, safe.Y)
		local band = if titleH > 0 and not isIcon then titleH else h
		local x = pos.X.Scale * cw + pos.X.Offset
		local y = pos.Y.Scale * ch + pos.Y.Offset
		-- a strip of another window's dock is a wall: the window's edge stops at it (header "STAYING ON SCREEN")
		local wallLeft, wallRight = control.Insets()
		local lo = if wallLeft > 0 then wallLeft else padX - w
		local hi = if wallRight > 0 then cw - wallRight - w else cw - padX
		if hi < lo then
			hi = lo
		end
		local cx = math.max(lo, math.min(hi, x))
		local cy = math.max(padY - band, math.min(ch - padY, y))
		if cx == x and cy == y then
			return pos
		end
		return UDim2.new(pos.X.Scale, pos.X.Offset + math.round(cx - x), pos.Y.Scale, pos.Y.Offset + math.round(cy - y))
	end

	local function reclamp()
		-- (a window of a unit that does not lead it leaves the shared rectangle to the one that does)
		if side:Get() ~= nil or not lead:Get() then
			return
		end
		local current = rectPos:Get()
		local inside = clampToContainer(current)
		if inside ~= current then
			setPos(inside)
		end
	end

	-- the top bar's reach into the container (window units; see panelTop)
	local function measureTop()
		local f = frame
		local container = containerOf(f)
		local bar = Input.topbarHeight()
		if container == nil or bar <= 0 then
			panelTop:SetIfChanged(0)
			return
		end
		-- AbsolutePosition is measured below the GUI inset, TopbarInset from the very top of the screen
		local top = container.AbsolutePosition.Y + Input.guiInset().Y
		panelTop:SetIfChanged(math.round(math.max(0, bar - top) / frameScale()))
	end
	local offTopbar = Input.onTopbarChanged(measureTop)

	-- ── the tab strip (header TABS): where the strip's tabs sit — the ONE place that lays the strip out ──────────
	local buttonSize: State<number> = TitleBar.buttonSize(style)
	-- (lead = where the first tab starts, after the frame padding and the collapse arrow; width = each tab's; window
	-- units, from the frame's left edge; the strip is the title-bar row at the top of the frame)
	local function tabSlots(): (number, number, number)
		local g = view:Get()
		local count = if g ~= nil then g.TabCount else 1
		local pad = style.Metrics.FramePadding:Get().X
		local lead = pad
		if not hints.NoCollapse and canCollapse:Get() then
			lead += buttonSize:Get() + 4
		end
		local stripW = frameSize:Get().X.Offset
		local frameH = style.FrameHeight:Get()
		local room = math.max(0, stripW - lead - pad - TAB_GRAB * frameH)
		local w = math.floor(math.max(TAB_MIN * frameH, math.min(TAB_IDEAL * frameH, room / math.max(1, count))))
		return lead, w, count
	end
	-- this window's tab: { X, Width } in the strip, nil = no tab
	local tabPlace: State<Vector2?> = view:Compute(function(self, _prev, _size, _frameH, _text, _pad): Vector2?
		local g = self:Get()
		local index = if g ~= nil and g.Tabbed then g.TabIndex else nil
		-- (a leaf folded to a bar shows no tabs)
		if index == nil or (g ~= nil and (g.Fold == "Left" or g.Fold == "Right")) then
			return nil
		end
		local lead, w = tabSlots()
		return Vector2.new(lead + index * w, w)
	end, frameSize, style.FrameHeight, style.Metrics.TextSize, style.Metrics.FramePadding)
	-- the pointer's x in window units from the frame's left edge
	local function stripX(x: number): number
		local f = frame
		local origin = if f ~= nil then f.AbsolutePosition.X else 0
		return (x - origin) / frameScale()
	end
	-- the shown tab a drop at screen x goes before (header TABS): by the tabs' middles; a window without a strip is
	-- one tab as wide as its title bar
	local function insertAt(x: number): number
		local rel = stripX(x)
		local g = view:Get()
		if g == nil or not g.Tabbed then
			return if rel < frameSize:Get().X.Offset / 2 then 0 else 1
		end
		local lead, w, count = tabSlots()
		local at = 0
		for i = 0, count - 1 do
			if rel > lead + i * w + w / 2 then
				at = i + 1
			end
		end
		return at
	end
	-- the shown slot under screen x (a tab dragged inside the row)
	local function slotAt(x: number): number
		local lead, w, count = tabSlots()
		return math.clamp(math.floor((stripX(x) - lead) / math.max(1, w)), 0, count - 1)
	end

	-- ── the drop preview (headers DOCKED and TABS): an edge's strip + panel, or the outer rectangle of a target ────
	local previewShown: Source<boolean> = q.Source(false)
	local previewAnchor: Source<Vector2> = q.Source(Vector2.zero)
	local previewPosition: Source<UDim2> = q.Source(UDim2.new())
	local previewSize: Source<UDim2> = q.Source(UDim2.new())
	local function showPreview(c: Candidate?)
		if c == nil then
			previewShown:SetIfChanged(false)
			return
		end
		local at, drop = c.Side, c.Drop
		if at ~= nil then
			previewAnchor:SetIfChanged(if at == "Right" then Vector2.new(1, 0) else Vector2.zero)
			previewPosition:SetIfChanged(if at == "Right" then UDim2.fromScale(1, 0) else UDim2.fromScale(0, 0))
			previewSize:SetIfChanged(UDim2.new(0, stripWidth:Get() + dropWidth(), 1, 0))
		elseif drop ~= nil then
			-- (a target's leaf, the half a split gives the dropped window, or half the whole unit — header SPLITS)
			previewAnchor:SetIfChanged(Vector2.zero)
			previewPosition:SetIfChanged(drop.Position)
			previewSize:SetIfChanged(drop.Size)
		end
		previewShown:SetIfChanged(true)
	end
	local function sameCandidate(a: Candidate?, b: Candidate?): boolean
		if a == nil or b == nil then
			return a == b
		end
		local da, db = a.Drop, b.Drop
		if da == nil or db == nil then
			return da == db and a.Side == b.Side
		end
		return da.Target == db.Target and da.Index == db.Index and da.Split == db.Split and da.Outer == db.Outer
	end

	-- the edge band the pointer is in (nil = none): within the strip width inside the container's left or right edge
	-- (a pointer outside the container — a Frame container smaller than the screen — is at no edge)
	local function edgeAt(x: number, y: number): Side?
		local container = containerOf(frame)
		if container == nil then
			return nil
		end
		local cp, cs = container.AbsolutePosition, container.AbsoluteSize
		if cs.X <= 0 or cs.Y <= 0 then
			return nil
		end
		if x < cp.X or x > cp.X + cs.X or y < cp.Y or y > cp.Y + cs.Y then
			return nil
		end
		local band = stripWidth:Get() * frameScale()
		return if x < cp.X + band then "Left" elseif x >= cp.X + cs.X - band then "Right" else nil
	end

	-- what releasing at the pointer would do: dock on a free edge, join the group holding an edge, or join the window
	-- / group under the pointer (headers DOCKED and TABS)
	local function judge(x: number, y: number): Candidate?
		local at = edgeAt(x, y)
		if at ~= nil then
			if not control.SideTaken(at) then
				if not noDock() then
					return { Side = at }
				end
			else
				local held = control.EdgeJoin(at)
				if held ~= nil then
					return { Drop = held }
				end
			end
		end
		local drop = control.DropAt(x, y)
		return if drop ~= nil then { Drop = drop } else nil
	end

	-- a drag of the floating window (its title bar, the group's strip, or a dragged-out tab): moves it, previews a drop
	local startPos = UDim2.new()
	local grabFraction, grabY = 0.5, 0
	local candidate: Candidate? = nil
	local function dragMove(x: number, y: number, dx: number, dy: number)
		setPos(clampToContainer(UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)))
		local c = judge(x, y)
		if not sameCandidate(c, candidate) then
			candidate = c
			showPreview(c)
		end
	end
	local function dragEnd(cancelled: boolean)
		local c = candidate
		candidate = nil
		showPreview(nil)
		if cancelled or c == nil or side:Get() ~= nil then
			return
		end
		local at, drop = c.Side, c.Drop
		if at ~= nil then
			if control.SideTaken(at) then
				return
			end
			-- the floating rectangle it keeps is where the drag began, not the edge it was dropped on
			local width = dropWidth()
			setPos(startPos)
			control.Dock(at, width)
		elseif drop ~= nil then
			-- (the same for a join: the window keeps the rectangle it had before it was dragged)
			setPos(startPos)
			control.Join(drop)
		end
	end

	-- the window comes off its edge or out of its group under the pointer: the same spot of its title bar (the same
	-- fraction of the width, the same height) stays under the press point, so the drag goes on from there. `scale` =
	-- screen pixels per window unit, measured before it left.
	local function placeUnder(pressX: number, pressY: number, scale: number)
		local container = containerOf(frame)
		local origin = if container then container.AbsolutePosition else Vector2.zero
		local s = rectSize:Get()
		local left = (pressX - origin.X) / scale - grabFraction * s.X
		local top = (pressY - grabY - origin.Y) / scale
		startPos = UDim2.fromOffset(math.round(left), math.round(top))
	end
	-- where on the frame the press was (for placeUnder). `whole`: a split unit comes off its edge as a whole — the
	-- pointer keeps its share of the unit's width and its place in the pressed leaf, that leaf's top taken in the
	-- floating rectangle (header SPLITS)
	local function grab(x: number, y: number, whole: boolean)
		local f = frame
		local g = view:Get()
		local box = if g ~= nil then g.Box else nil
		if f ~= nil and whole and box ~= nil then
			local fp = f.AbsolutePosition
			local scale = frameScale()
			local unitW = if side:Get() ~= nil then dockWidth:Get() else rectSize:Get().X
			local left = fp.X - (box[1] * unitW + box[2]) * scale
			grabFraction = if unitW > 0 then math.clamp((x - left) / (unitW * scale), 0, 1) else 0.5
			local float = rectSize:Get()
			grabY = math.max(0, y - fp.Y) + (box[5] * float.Y + box[6]) * scale
		elseif f ~= nil then
			local fp, fs = f.AbsolutePosition, f.AbsoluteSize
			grabFraction = if fs.X > 0 then math.clamp((x - fp.X) / fs.X, 0, 1) else 0.5
			grabY = math.max(0, y - fp.Y)
		end
	end

	-- title-bar drag (also the tab strip's empty area): moves a floating window (pixel deltas added to the Position
	-- offsets), docks it at an edge or joins it to a group, and takes a docked one off its edge (headers DOCKED, TABS)
	local titleDrag: Interaction.DragHandle? = nil
	if not hints.NoMove then
		local pressX, pressY = 0, 0
		titleDrag = Interaction.drag({
			-- a group with a NoMove window does not move (header TABS)
			Enabled = canMove,
			OnBegin = function(x, y)
				control.Raise()
				startPos = rectPos:Get()
				pressX, pressY = x, y
				candidate = nil
				if side:Get() ~= nil then
					grab(x, y, true)
				end
			end,
			OnMove = function(x, y, dx, dy)
				if side:Get() ~= nil then
					local t = PressOrDrag.THRESHOLD
					if dx * dx + dy * dy < t * t then
						return
					end
					local scale = frameScale()
					control.Undock()
					placeUnder(pressX, pressY, scale)
				end
				dragMove(x, y, dx, dy)
			end,
			OnEnd = function(_x, _y, _dx, _dy, cancelled)
				dragEnd(cancelled)
			end,
		})
	end

	-- the collapsed window's icon: press expands, drag moves (kept on screen with the icon as the window)
	local iconStart = UDim2.new()
	local iconMovable = not hints.NoMove
	local iconGesture = PressOrDrag.new({
		OnPress = function()
			collapsed:Set(false)
		end,
		OnDragBegin = if not iconMovable
			then nil
			else function()
				if not canMove:Get() then
					return
				end
				control.Raise()
				iconStart = rectPos:Get()
			end,
		OnDrag = if not iconMovable
			then nil
			else function(dx: number, dy: number)
				if not canMove:Get() then
					return
				end
				setPos(clampToContainer(UDim2.new(iconStart.X.Scale, iconStart.X.Offset + dx, iconStart.Y.Scale, iconStart.Y.Offset + dy)))
			end,
	})
	-- pressed > hovered > focused > idle (the title bar's colours at rest, the button's under the pointer)
	local function restLook(hover: Interaction.HoverHandle, pick: (token: string) -> State<any>): State<any>
		return hover.Hovered:Compute(function(self, _prev, isPressed, isFocused, idle, active, hovered, pressed)
			if isPressed:Get() then
				return pressed:Get()
			elseif self:Get() then
				return hovered:Get()
			elseif isFocused:Get() then
				return active:Get()
			end
			return idle:Get()
		end, hover.Pressed, control.Focused, pick("TitleBg"), pick("TitleBgActive"), pick("ButtonHovered"), pick("ButtonActive"))
	end
	local function colorOf(token: string): State<any>
		return style:ColorOf(token)
	end
	local function alphaOf(token: string): State<any>
		return style:AlphaOf(token)
	end
	local iconHover = Interaction.hover()
	local iconBg: State<Color3> = restLook(iconHover, colorOf)
	local iconAlpha: State<number> = restLook(iconHover, alphaOf)
	local iconBox: State<UDim2> = iconSide:Compute(function(self)
		return UDim2.fromOffset(self:Get(), self:Get())
	end)
	local letterSize: State<number> = iconSide:Compute(function(self)
		return math.floor(self:Get() * 0.5)
	end)
	-- the first letter of the title (skipping leading spaces; one UTF-8 character, upper-cased when ASCII)
	local function firstLetter(title: string): string
		local s = string.gsub(title, "^%s+", "")
		local nextAt = utf8.offset(s, 2)
		local first = if nextAt ~= nil then string.sub(s, 1, nextAt - 1) else s
		return string.upper(first)
	end
	local title = hints.Title
	local letter: string | State<string> = if type(title) == "string"
		then firstLetter(title)
		else (title :: State<string>):Compute(function(self)
			return firstLetter(self:Get())
		end)
	local iconImage = hints.Icon

	-- the dock strip (header DOCKED)
	local stripHover = Interaction.hover()
	local stripBg: State<Color3> = restLook(stripHover, colorOf)
	local stripAlpha: State<number> = restLook(stripHover, alphaOf)
	local stripAnchor: State<Vector2> = side:Compute(function(self)
		return if self:Get() == "Right" then Vector2.new(1, 0) else Vector2.new(0, 0)
	end)
	local stripPosition: State<UDim2> = side:Compute(function(self)
		return if self:Get() == "Right" then UDim2.fromScale(1, 0) else UDim2.fromScale(0, 0)
	end)
	local stripSize: State<UDim2> = stripWidth:Compute(function(self)
		return UDim2.new(0, self:Get(), 1, 0)
	end)
	-- the arrow points where the panel goes: right for a collapsed left dock and an expanded right one
	local arrowRotation: State<number> = side:Compute(function(self, _prev, isCollapsed)
		local pointsRight = (self:Get() == "Right") ~= isCollapsed:Get()
		return if pointsRight then 0 else 180
	end, iconic)
	local arrowSize: State<UDim2> = stripWidth:Compute(function(self)
		local s = math.floor(self:Get() * 0.6)
		return UDim2.fromOffset(s, s)
	end)
	local function pressStrip(wasFocused: boolean)
		if iconic:Get() then
			setIconic(false)
			control.Raise()
		elseif not wasFocused then
			control.Raise()
		else
			setIconic(true)
		end
	end

	-- resize grip (floating)
	local startSize = Vector2.new()
	local grip: Interaction.DragHandle? = nil
	local gripHover = Interaction.hover()
	local gripLook = Style.interactive(style, "ResizeGrip", gripHover.Hovered, gripHover.Pressed)
	-- the dock width handle (docked)
	local dockResize: Interaction.DragHandle? = nil
	local dockHover = Interaction.hover()
	local dockLook = Style.interactive(style, "ResizeGrip", dockHover.Hovered, dockHover.Pressed)
	if not hints.NoResize then
		grip = Interaction.drag({
			Enabled = canResize,
			OnBegin = function()
				control.Raise()
				startSize = rectSize:Get()
			end,
			OnMove = function(_x, _y, dx, dy)
				local floor = control.MinSize()
				setSize(Vector2.new(math.max(floor.X, startSize.X + dx), math.max(floor.Y, startSize.Y + dy)))
			end,
		})
		local startWidth, widthScale = 0, 1
		dockResize = Interaction.drag({
			Enabled = canResize,
			OnBegin = function()
				control.Raise()
				startWidth = dockWidth:Get()
				widthScale = frameScale()
			end,
			OnMove = function(_x, _y, dx, _dy)
				local delta = dx / widthScale
				local w = if side:Get() == "Right" then startWidth - delta else startWidth + delta
				dockWidth:SetIfChanged(fitDockWidth(w))
			end,
		})
	end
	local gripShown: State<boolean> = floatingShown:Compute(function(self, _prev, can, isLead)
		return self:Get() and can:Get() and isLead:Get()
	end, canResize, lead)
	local dockHandleShown: State<boolean> = dockedShown:Compute(function(self, _prev, can, isLead)
		return self:Get() and can:Get() and isLead:Get()
	end, canResize, lead)
	local dockHandleAnchor: State<Vector2> = side:Compute(function(self)
		return if self:Get() == "Right" then Vector2.new(1, 0) else Vector2.new(0, 0)
	end)
	-- right outside the panel's inner edge (not over the content's scrollbar)
	local dockHandlePosition: State<UDim2> = side:Compute(function(self, _prev, w, sw, top)
		local offset = sw:Get() + w:Get()
		return if self:Get() == "Right" then UDim2.new(1, -offset, 0, top:Get()) else UDim2.fromOffset(offset, top:Get())
	end, dockWidth, stripWidth, panelTop)
	local dockHandleSize: State<UDim2> = style.Metrics.WindowResizePadding:Compute(function(self, _prev, top)
		return UDim2.new(0, self:Get().X, 1, -top:Get())
	end, panelTop)

	-- the container shrinking brings an out-of-bounds window back in and a dock back into its width range (one
	-- connection, on the current container)
	local containerConn: RBXScriptConnection? = nil
	local movedConn: RBXScriptConnection? = nil
	local lastArea = Vector2.zero
	local function unwatch()
		local c, m = containerConn, movedConn
		containerConn = nil
		movedConn = nil
		if c then
			c:Disconnect()
		end
		if m then
			m:Disconnect()
		end
	end
	local function watchContainer()
		unwatch()
		measureTop()
		local container = containerOf(frame)
		if container == nil then
			return
		end
		local gui = container
		lastArea = gui.AbsoluteSize
		-- a dock width loaded from another screen size (or before the window had a container) is brought into range here
		if side:Get() ~= nil then
			dockWidth:SetIfChanged(fitDockWidth(dockWidth:Get()))
		end
		-- a container moved under (or out from under) the Roblox top bar moves a docked panel's top
		movedConn = gui:GetPropertyChangedSignal("AbsolutePosition"):Connect(measureTop)
		containerConn = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local area = gui.AbsoluteSize
			local shrank = area.X < lastArea.X or area.Y < lastArea.Y
			lastArea = area
			measureTop()
			if shrank and area.X > 0 and area.Y > 0 then
				if side:Get() ~= nil then
					local fitted = fitDockWidth(dockWidth:Get())
					if fitted < dockWidth:Get() then
						dockWidth:Set(fitted)
					end
				else
					reclamp()
				end
			end
		end)
	end

	local collapsedInstalled = false
	local built = Frame({
		Name = "WindowDecoration",
		Position = framePosition,
		Size = frameSize,
		ZIndex = control.BackZ,
		Visible = shown,
		Active = true,
		BackgroundColor3 = style.Color.WindowBg,
		BackgroundTransparency = style.Transparency.WindowBg,
		BorderSizePixel = 0,
		UICorner = style.Metrics.WindowRounding,
		UIStroke({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = style.Metrics.WindowBorderSize,
			Color = style.Color.Border,
			Transparency = style.Transparency.Border,
		}),
		-- a press on the window's empty area must not fall through to a window beneath: a plain Frame / ScrollingFrame
		-- passes a click on to the GuiButton under it (`Active` does not stop it), only a GuiButton sinks it. Direct
		-- child at ZIndex 0 (the frame lays nothing out), so the title bar stays above it; the surface, one rank
		-- above the frame, passes a press on its empty area down to this sink (user decision 2026-10-15).
		TextButton({
			Name = "ClickSink",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Selectable = false,
		}),
		if hints.NoTitleBar
			then q.None
			else TitleBar.new({
				Style = style,
				Title = hints.Title,
				Collapsed = collapsed,
				Open = open,
				Focused = control.Focused,
				NoCollapse = hints.NoCollapse,
				NoClose = hints.NoClose,
				OnCloseRequest = hints.OnCloseRequest,
				Drag = titleDrag,
				Tabbed = tabbed,
				CanCollapse = canCollapse,
				Shown = barFolded:Compute(function(self)
					return not self:Get()
				end),
				Folded = rowFolded,
			}),
		-- a grouped window's Collapsed and dock width are its unit's (the manager spreads a change to the others). Two
		-- effects: in a split an app writing an EQUAL Collapsed (true on a collapsed panel) is still a request for its
		-- leaf's fold, so the manager must know which one fired; the install run of the Collapsed one is skipped (it
		-- reports nothing — the manager wrote that value)
		q.Effect(function()
			if not collapsedInstalled then
				collapsedInstalled = true
				return
			end
			control.Sync("Collapsed")
		end, collapsed),
		q.Effect(function()
			control.Sync("DockWidth")
		end, dockWidth),
	})
	frame = built
	local icon = TextButton({
		iconHover.Hook,
		iconGesture.Hook,
		Name = "WindowIcon",
		Position = rectPos,
		Size = iconBox,
		ZIndex = control.FrontZ,
		Visible = iconShown,
		Active = true,
		AutoButtonColor = false,
		BackgroundColor3 = iconBg,
		BackgroundTransparency = iconAlpha,
		BorderSizePixel = 0,
		Text = if iconImage ~= nil then "" else letter,
		FontFace = style.Metrics.TextFont,
		TextSize = letterSize,
		TextColor3 = style.Color.Text,
		TextTransparency = style.Transparency.Text,
		-- a gamepad / keyboard activation of the selected icon (a pointer press is the gesture above)
		Activated = function(input: InputObject)
			local t = input.UserInputType
			if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
				collapsed:Set(false)
			end
		end,
		-- "a rounded square" whatever the density's WindowRounding (0 in Compact): a quarter of the side
		UICorner({ CornerRadius = UDim.new(0.25, 0) }),
		UIStroke({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = style.Metrics.WindowBorderSize,
			Color = style.Color.Border,
			Transparency = style.Transparency.Border,
		}),
		if iconImage ~= nil
			then ImageLabel({
				Name = "Image",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.7, 0.7),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = iconImage,
				ScaleType = Enum.ScaleType.Fit,
			})
			else q.None,
		-- the manager's Layout output (keyed windows only): any of the floating facts, the dock or the group changed
		if control.Changed ~= nil
			then q.Effect(function()
				(control.Changed :: () -> ())()
			end, position, size, open, collapsed, side, dockWidth, view)
			else q.None,
	})
	iconButton = icon
	local strip = TextButton({
		stripHover.Hook,
		-- hiding the strip (the window closed or floated) sends no MouseLeave: drop the hover look
		q.Effect(function()
			if not stripShown:Get() then
				stripHover.Reset()
			end
		end, stripShown),
		Name = "WindowDockStrip",
		AnchorPoint = stripAnchor,
		Position = stripPosition,
		Size = stripSize,
		ZIndex = control.FrontZ,
		Visible = stripShown,
		Active = true,
		AutoButtonColor = false,
		BackgroundColor3 = stripBg,
		BackgroundTransparency = stripAlpha,
		BorderSizePixel = 0,
		Text = "",
		Activated = function(input: InputObject)
			local t = input.UserInputType
			local pointer = t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
			-- a pointer press went through the manager's global press first (it focused the window): ask what the
			-- focus was before it; a gamepad / keyboard activation has no such press
			pressStrip(if pointer then control.FocusedBeforePress() else control.Focused:Get())
		end,
		ImageLabel({
			Name = "Arrow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = arrowSize,
			Rotation = arrowRotation,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = style.Icons.RightTriangle,
			ImageColor3 = style.Color.Text,
			ImageTransparency = style.Transparency.Text,
		}),
	})
	local parts: { Instance } = { built, icon, strip }
	if grip then
		table.insert(
			parts,
			ImageButton({
				gripHover.Hook,
				grip.Hook,
				Name = "WindowResizeGrip",
				AnchorPoint = Vector2.new(1, 1),
				Position = gripPosition,
				Size = gripSize,
				ZIndex = control.FrontZ,
				Visible = gripShown,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Image = style.Icons.ResizeGrip,
				ImageColor3 = gripLook.Color,
				ImageTransparency = gripLook.Transparency,
			})
		)
	end
	if dockResize then
		table.insert(
			parts,
			TextButton({
				dockHover.Hook,
				dockResize.Hook,
				Name = "WindowDockResize",
				AnchorPoint = dockHandleAnchor,
				Position = dockHandlePosition,
				Size = dockHandleSize,
				ZIndex = control.FrontZ,
				Visible = dockHandleShown,
				BackgroundColor3 = dockLook.Color,
				BackgroundTransparency = dockLook.Transparency,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
			})
		)
	end

	-- (a NoTitleBar window is never in a unit: no fold bar, no splitter — and a NoResize one draws no splitter)
	if not hints.NoTitleBar then
		-- a leaf folded in a left | right split (header SPLITS): a bar as wide as the strip row, its arrow pointing where the
		-- leaf opens; pressing it unfolds the leaf (the window's Collapsed false — the manager maps it to the leaf)
		local foldHover = Interaction.hover()
		local foldBg: State<Color3> = restLook(foldHover, colorOf)
		local foldAlpha: State<number> = restLook(foldHover, alphaOf)
		local foldShown: State<boolean> = shown:Compute(function(self, _prev, isBar)
			return self:Get() and isBar:Get()
		end, barFolded)
		local foldRotation: State<number> = fold:Compute(function(self)
			return if self:Get() == "Right" then 180 else 0
		end)
		table.insert(
			parts,
			TextButton({
				foldHover.Hook,
				q.Effect(function()
					if not foldShown:Get() then
						foldHover.Reset()
					end
				end, foldShown),
				Name = "WindowFoldBar",
				Position = framePosition,
				Size = frameSize,
				ZIndex = control.FrontZ,
				Visible = foldShown,
				Active = true,
				AutoButtonColor = false,
				BackgroundColor3 = foldBg,
				BackgroundTransparency = foldAlpha,
				BorderSizePixel = 0,
				Text = "",
				Activated = function()
					collapsed:Set(false)
				end,
				ImageLabel({
					Name = "Arrow",
					AnchorPoint = Vector2.new(0.5, 0.5),
					-- (in the middle of the top row, where the arrow sits in a strip)
					Position = stripWidth:Compute(function(self)
						return UDim2.new(0.5, 0, 0, math.floor(self:Get() / 2))
					end),
					Size = arrowSize,
					Rotation = foldRotation,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Image = style.Icons.RightTriangle,
					ImageColor3 = style.Color.Text,
					ImageTransparency = style.Transparency.Text,
				}),
			})
		)
		if not hints.NoResize then
			-- the splitter between two sides of a split (header SPLITS): drawn by the second side's first leaf, over the seam;
			-- dragging it moves the seam (the manager keeps both sides above their floors); hidden while a side is folded
			local splitterHover = Interaction.hover()
			local splitterLook = Style.interactive(style, "ResizeGrip", splitterHover.Hovered, splitterHover.Pressed)
			local splitterShown: State<boolean> = shown:Compute(function(self, _prev, v)
				local g = v:Get()
				local sp = if g ~= nil then g.Splitter else nil
				return self:Get() and sp ~= nil and sp.Enabled
			end, view)
			local splitterBox: State<{ number }?> = view:Compute(function(self): { number }?
				local g = self:Get()
				local sp = if g ~= nil then g.Splitter else nil
				return if sp ~= nil then sp.Box else nil
			end)
			local splitterPosition: State<UDim2> = unitPosition:Compute(function(self, _prev, extent, b)
				local box = b:Get()
				if box == nil then
					return self:Get()
				end
				local p = boxRect(self:Get(), extent:Get(), box)
				return p
			end, unitSize, splitterBox)
			local splitterSize: State<UDim2> = unitSize:Compute(function(self, _prev, at, b)
				local box = b:Get()
				if box == nil then
					return UDim2.new()
				end
				local _, sz = boxRect(at:Get(), self:Get(), box)
				return sz
			end, unitPosition, splitterBox)
			local splitterZ: State<number> = view:Compute(function(self, _prev, front)
				local g = self:Get()
				return if g ~= nil then g.TabZ else front:Get()
			end, control.FrontZ)
			local splitterAlongX = true
			local splitterDrag = Interaction.drag({
				Enabled = splitterShown,
				OnBegin = function()
					control.Raise()
					local g = view:Get()
					local sp = if g ~= nil then g.Splitter else nil
					splitterAlongX = sp == nil or sp.Axis == "LeftRight"
					control.Splitter("Begin", 0)
				end,
				OnMove = function(_x, _y, dx, dy)
					control.Splitter("Move", (if splitterAlongX then dx else dy) / frameScale())
				end,
				OnEnd = function()
					control.Splitter("End", 0)
				end,
			})
			table.insert(
				parts,
				TextButton({
					splitterHover.Hook,
					splitterDrag.Hook,
					q.Effect(function()
						if not splitterShown:Get() then
							splitterHover.Reset()
						end
					end, splitterShown),
					Name = "WindowSplitter",
					Position = splitterPosition,
					Size = splitterSize,
					ZIndex = splitterZ,
					Visible = splitterShown,
					Active = true,
					AutoButtonColor = false,
					BackgroundColor3 = splitterLook.Color,
					BackgroundTransparency = splitterLook.Transparency,
					BorderSizePixel = 0,
					Text = "",
				})
			)
		end
	end

	-- this window's tab in its group's strip (header TABS): press selects, drag inside the row reorders, drag out of
	-- the row takes the window out of the group and goes on as its title-bar drag
	if not hints.NoTitleBar then
		local tabHover = Interaction.hover()
		local tabLook = Style.interactive(style, "Tab", tabHover.Hovered, tabHover.Pressed)
		local tabColor: State<Color3> = drawn:Compute(function(self, _prev, normal, active)
			return if self:Get() then active:Get() else normal:Get()
		end, tabLook.Color, style.Color.TabActive)
		local tabAlpha: State<number> = drawn:Compute(function(self, _prev, normal, active)
			return if self:Get() then active:Get() else normal:Get()
		end, tabLook.Transparency, style.Transparency.TabActive)
		local tabShown: State<boolean> = present:Compute(function(self, _prev, place)
			return self:Get() and place:Get() ~= nil
		end, tabPlace)
		local tabPosition: State<UDim2> = framePosition:Compute(function(self, _prev, place)
			local p, t = self:Get(), place:Get()
			return UDim2.new(p.X.Scale, p.X.Offset + (if t ~= nil then t.X else 0), p.Y.Scale, p.Y.Offset)
		end, tabPlace)
		local tabSize: State<UDim2> = tabPlace:Compute(function(self, _prev, titleH)
			local t = self:Get()
			return UDim2.fromOffset(if t ~= nil then t.Y else 0, titleH:Get())
		end, titleHeight)
		local tabZ: State<number> = view:Compute(function(self, _prev, front)
			local g = self:Get()
			return if g ~= nil then g.TabZ else front:Get()
		end, control.FrontZ)
		local closeShown: State<boolean> = drawn:Compute(function(self, _prev, hovered)
			return self:Get() or hovered:Get()
		end, tabHover.Hovered)
		local sidePad: State<UDim> = Util.pxX(style.Metrics.FramePadding)
		local titleRight: State<UDim> = buttonSize:Compute(function(self)
			return UDim.new(0, if hints.NoClose then 0 else self:Get() + 2)
		end)

		local detached = false
		local tabPressX, tabPressY = 0, 0
		local tabGesture = PressOrDrag.new({
			OnPress = function()
				control.SelectTab()
			end,
			OnDragBegin = function(px: number, py: number)
				detached = false
				tabPressX, tabPressY = px, py
				control.SelectTab()
			end,
			OnDrag = function(dx: number, dy: number, x: number, y: number)
				if detached then
					dragMove(x, y, dx, dy)
					return
				end
				local f = frame
				if view:Get() == nil or f == nil then
					return -- (the group went away under the drag)
				end
				local p, s = f.AbsolutePosition, f.AbsoluteSize
				local inRow = y >= p.Y and y < p.Y + titleHeight:Get() * frameScale() and x >= p.X and x < p.X + s.X
				if inRow then
					control.MoveTab(slotAt(x))
					return
				end
				if hints.NoMove then
					return -- (it only reorders)
				end
				-- out of the row: the window leaves its group under the pointer and the drag goes on as its own
				local scale = frameScale()
				grab(tabPressX, tabPressY, false)
				control.DetachTab()
				placeUnder(tabPressX, tabPressY, scale)
				candidate = nil
				detached = true
				control.Raise()
				dragMove(x, y, dx, dy)
			end,
			OnDragEnd = function(cancelled: boolean)
				if detached then
					detached = false
					dragEnd(cancelled)
				end
			end,
		})
		table.insert(
			parts,
			TextButton({
				tabHover.Hook,
				tabGesture.Hook,
				-- hiding the tab (closed, collapsed, the strip gone) sends no MouseLeave: drop the hover look
				q.Effect(function()
					if not tabShown:Get() then
						tabHover.Reset()
					end
				end, tabShown),
				Name = "WindowTab",
				Position = tabPosition,
				Size = tabSize,
				ZIndex = tabZ,
				Visible = tabShown,
				Active = true,
				AutoButtonColor = false,
				BackgroundColor3 = tabColor,
				BackgroundTransparency = tabAlpha,
				BorderSizePixel = 0,
				Text = "",
				UICorner = style.Metrics.TabRounding,
				TextLabel({
					Name = "Title",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = hints.Title,
					FontFace = style.Metrics.TextFont,
					TextSize = style.Metrics.TextSize,
					TextColor3 = style.Color.Text,
					TextTransparency = style.Transparency.Text,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					UIPadding({ PaddingLeft = sidePad, PaddingRight = titleRight }),
				}),
				if hints.NoClose
					then q.None
					else TitleBar.button(style, style.Icons.Close, function()
						TitleBar.close(open, hints.OnCloseRequest)
					end, "Right", buttonSize, tabShown, closeShown),
			})
		)
	end

	-- the drop preview: a window a drag can move (header DOCKED: also NoDock — it can still join a group)
	if titleDrag ~= nil and not hints.NoTitleBar then
		table.insert(
			parts,
			Frame({
				Name = "WindowDockPreview",
				AnchorPoint = previewAnchor,
				Position = previewPosition,
				Size = previewSize,
				-- one above this window's (or its group's tabs') top: the drag raised it, so above every window
				ZIndex = control.FrontZ:Compute(function(self, _prev, v)
					local g = v:Get()
					return math.max(self:Get(), if g ~= nil then g.TabZ else 0) + 1
				end, view),
				Visible = previewShown,
				Active = false,
				BackgroundColor3 = style.Color.Header,
				BackgroundTransparency = style.Transparency.Header,
				BorderSizePixel = 0,
				UIStroke({
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Thickness = style.Metrics.WindowBorderSize,
					Color = style.Color.HeaderActive,
					Transparency = style.Transparency.HeaderActive,
				}),
			})
		)
	end

	return {
		Parts = parts,
		Frame = built,
		InsertAt = insertAt,
		RowHeight = function(): number
			return titleHeight:Get() * frameScale()
		end,
		Surface = { Position = surfacePosition, Size = surfaceSize, Visible = surfaceShown },
		LeafRect = function(): (UDim2, UDim2)
			return framePosition:Get(), frameSize:Get()
		end,
		UnitRect = function(): (UDim2, UDim2)
			return unitPosition:Get(), unitSize:Get()
		end,
		PanelHeight = function(): number
			local container = containerOf(frame)
			if container == nil then
				return 0
			end
			return math.max(0, container.AbsoluteSize.Y / frameScale() - panelTop:Get())
		end,
		SetParent = function(parent: Instance?)
			for _, part in parts do
				if alive(part) and part.Parent ~= parent then
					part.Parent = parent
				end
			end
			watchContainer()
		end,
		Reclamp = reclamp,
		FitDockWidth = fitDockWidth,
		Destroy = function()
			unwatch()
			offTopbar()
			showPreview(nil)
			for _, part in parts do
				if alive(part) then
					q.dispose(part)
				end
			end
		end,
	}
end

return Decoration
