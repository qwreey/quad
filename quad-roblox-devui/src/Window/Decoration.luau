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
		WindowDockPreview (Frame, the edge-dock preview while a title-bar drag is at an edge — see DOCKED)
	The grip and the dock handle are left out with NoResize, the preview with NoMove or NoDock. The frame sits BELOW the surface (it paints the background
	the surface is drawn on) and the grip ABOVE it (it overlaps the content's corner): the manager gives each window
	three consecutive ZIndex ranks (frame, surface, grip). The icon, the strip and the dock handle take the grip's rank;
	the preview takes the one above it (the drag raised the window first, so it draws over every window).

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
	Docking: while the title bar is dragged, a pointer within the strip width of the container's left or right edge
	shows a preview of the strip and panel (a decoration part in the window's container, input-less — drawn by the
	compositor like the strip, so it shows whichever Overlay the app mounts, or none [2026-10-21 user decision; it
	was a popup of the default Overlay and did not show where that layer was not mounted, e.g. a UI Labs story]),
	and releasing there docks the window (its Position goes back to
	where the drag began — the floating rectangle it keeps). The first dock width is the window's Size.X in the range
	above; docking again uses the dock width it keeps. Not offered when that edge is held by another open window, with NoDock or NoMove, or from the icon.
	Undocking: dragging a docked window's title bar past the press-or-drag threshold makes it float again, at its kept
	Size, placed so the pointer holds the same spot of its title bar, and the drag goes on (NoMove: no undock).

	Why the background and border are decoration, not surface: they enclose the whole outer rectangle (title bar
	included), which only the compositor knows; a collapsed window swaps the whole frame for its icon, which only the
	compositor draws; and a future group of surfaces (tabs) shares one frame. The surface stays transparent, and a
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
local Input = require("../Input")
local Interaction = require("../Interaction")
local Style = require("../Style")
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
}

export type Decoration = {
	Parts: { Instance },
	Surface: Placement,
	SetParent: (parent: Instance?) -> (),
	Reclamp: () -> (), -- a strip appeared: bring this floating window out of it (the container-shrink path)
	FitDockWidth: (width: number) -> number, -- the dock width range for this window in its container now
	Destroy: () -> (),
}

local Decoration = {}

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

function Decoration.new(hints: Hints, control: Control): Decoration
	local style = hints.Style
	local position = hints.Position
	local size = hints.Size
	local open = hints.Open
	local collapsed = hints.Collapsed
	local side = control.Side
	local dockWidth = control.DockWidth
	local stripWidth = style.FrameHeight

	-- title bar height (0 without a title bar)
	local noHeight: State<number> = q.Source(0)
	local titleHeight: State<number> = if hints.NoTitleBar then noHeight else style.FrameHeight

	-- how far the Roblox top bar reaches into the container (window units): a docked panel starts below it, the strip
	-- keeps the full height [2026-10-20 user decision — the top bar's buttons sit there]. 0 for a container already
	-- under the bar (a ScreenGui without IgnoreGuiInset)
	local panelTop: Source<number> = q.Source(0)

	local expanded: State<boolean> = collapsed:Compute(function(self)
		return not self:Get()
	end)
	local docked: State<boolean> = side:Compute(function(self)
		return self:Get() ~= nil
	end)
	local shown: State<boolean> = open:Compute(function(self, _prev, isExpanded)
		return self:Get() and isExpanded:Get()
	end, expanded)
	local floatingShown: State<boolean> = shown:Compute(function(self, _prev, isDocked)
		return self:Get() and not isDocked:Get()
	end, docked)
	local dockedShown: State<boolean> = shown:Compute(function(self, _prev, isDocked)
		return self:Get() and isDocked:Get()
	end, docked)
	local stripShown: State<boolean> = open:Compute(function(self, _prev, isDocked)
		return self:Get() and isDocked:Get()
	end, docked)

	local framePosition: State<UDim2> = position:Compute(function(self, _prev, at, w, sw, top)
		local edge = at:Get()
		if edge == "Left" then
			return UDim2.fromOffset(sw:Get(), top:Get())
		elseif edge == "Right" then
			return UDim2.new(1, -(sw:Get() + w:Get()), 0, top:Get())
		end
		return self:Get()
	end, side, dockWidth, stripWidth, panelTop)
	local frameSize: State<UDim2> = size:Compute(function(self, _prev, at, w, top)
		if at:Get() ~= nil then
			return UDim2.new(0, w:Get(), 1, -top:Get())
		end
		local s = self:Get()
		return UDim2.fromOffset(s.X, s.Y)
	end, side, dockWidth, panelTop)
	local iconShown: State<boolean> = open:Compute(function(self, _prev, isCollapsed, isDocked)
		return self:Get() and isCollapsed:Get() and not isDocked:Get()
	end, collapsed, docked)
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

	local gripPosition: State<UDim2> = position:Compute(function(self, _prev, sz)
		local p, s = self:Get(), sz:Get()
		return UDim2.new(p.X.Scale, p.X.Offset + s.X, p.Y.Scale, p.Y.Offset + s.Y)
	end, size)
	local gripSize: State<UDim2> = style.Metrics.TextSize:Compute(function(self, _prev, padding)
		local s = self:Get() + padding:Get().X
		return UDim2.fromOffset(s, s)
	end, style.Metrics.FramePadding)

	-- assigned right after the frame / icon are built; read only from event handlers
	local frame: Frame? = nil
	local iconButton: TextButton? = nil

	-- the width range of a dock panel (header DOCKED): [MinSize.X or 2 x FrameHeight, half the container's width]
	local function fitDockWidth(width: number): number
		local minSize = hints.MinSize
		local floor = if minSize then minSize.X else style.FrameHeight:Get() * 2
		local w = width
		local f = frame
		local container = containerOf(f)
		if container ~= nil and container.AbsoluteSize.X > 0 then
			local current = if side:Get() ~= nil then dockWidth:Get() else size:Get().X
			local half = container.AbsoluteSize.X / scaleOf(f, current) / 2
			w = math.min(w, half)
		end
		return math.round(math.max(floor, w))
	end

	-- the width a drag docks at: the window's floating width the first time, then the dock width it keeps (0 = never
	-- docked)
	local function dropWidth(): number
		local kept = dockWidth:Get()
		return fitDockWidth(if kept > 0 then kept else size:Get().X)
	end

	-- keep the window reachable inside its container (header "STAYING ON SCREEN"); `pos` unchanged when it already is
	local function clampToContainer(pos: UDim2): UDim2
		if side:Get() ~= nil then
			return pos -- docked: laid out from the edge
		end
		-- a collapsed window is its icon: the icon is the whole window (its band too)
		local isIcon = collapsed:Get()
		local f: GuiObject? = if isIcon then iconButton else frame
		local container = containerOf(f)
		if f == nil or container == nil then
			return pos
		end
		local area = container.AbsoluteSize
		if area.X <= 0 or area.Y <= 0 then
			return pos -- (a zero-sized container: minimised / not laid out yet — Dear ImGui skips it too)
		end
		local s = size:Get()
		local titleH = titleHeight:Get()
		local iconW = iconSide:Get()
		local w = if isIcon then iconW else s.X
		local h = if isIcon then iconW else s.Y
		local scale = scaleOf(f, w)
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
		if side:Get() ~= nil then
			return
		end
		local current = position:Get()
		local inside = clampToContainer(current)
		if inside ~= current then
			position:Set(inside)
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
		local current = if side:Get() ~= nil then dockWidth:Get() else size:Get().X
		panelTop:SetIfChanged(math.round(math.max(0, bar - top) / scaleOf(f, current)))
	end
	local offTopbar = Input.onTopbarChanged(measureTop)

	-- ── the edge-dock preview (header DOCKED): the edge a drag would dock on, and the strip + panel width there ────
	local previewSide: Source<Side?> = q.Source(nil :: Side?)
	local previewWidth: Source<number> = q.Source(0)
	local function closePreview()
		previewSide:SetIfChanged(nil)
	end
	local function openPreview(at: Side)
		previewWidth:SetIfChanged(stripWidth:Get() + dropWidth())
		previewSide:SetIfChanged(at)
	end

	-- title-bar drag: moves a floating window (pixel deltas added to the Position offsets), docks it at an edge, and
	-- takes a docked one off its edge (header DOCKED)
	local startPos = UDim2.new()
	local grabFraction, grabY = 0.5, 0
	local candidate: Side? = nil
	local titleDrag: Interaction.DragHandle? = nil

	-- the edge the pointer is at (nil = none, or not offered): within the strip width inside the container's left or
	-- right edge (a pointer outside the container — a Frame container smaller than the screen — docks nothing)
	local function edgeAt(x: number, y: number): Side?
		if hints.NoDock then
			return nil
		end
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
		local band = stripWidth:Get() * scaleOf(frame, size:Get().X)
		local at: Side? = if x < cp.X + band then "Left" elseif x >= cp.X + cs.X - band then "Right" else nil
		if at ~= nil and control.SideTaken(at) then
			return nil
		end
		return at
	end

	-- a docked window comes off its edge under the pointer: the same spot of its title bar (the same fraction of the
	-- width, the same height) stays under the press point, so the drag goes on from there
	local function undock(pressX: number, pressY: number)
		local f = frame
		local container = containerOf(f)
		local origin = if container then container.AbsolutePosition else Vector2.zero
		local scale = scaleOf(f, dockWidth:Get())
		local s = size:Get()
		local left = (pressX - origin.X) / scale - grabFraction * s.X
		local top = (pressY - grabY - origin.Y) / scale
		startPos = UDim2.fromOffset(math.round(left), math.round(top))
		control.Undock()
	end

	if not hints.NoMove then
		local pressX, pressY = 0, 0
		titleDrag = Interaction.drag({
			OnBegin = function(x, y)
				control.Raise()
				startPos = position:Get()
				pressX, pressY = x, y
				candidate = nil
				local f = frame
				if side:Get() ~= nil and f ~= nil then
					local fp, fs = f.AbsolutePosition, f.AbsoluteSize
					grabFraction = if fs.X > 0 then math.clamp((x - fp.X) / fs.X, 0, 1) else 0.5
					grabY = math.max(0, y - fp.Y)
				end
			end,
			OnMove = function(x, y, dx, dy)
				if side:Get() ~= nil then
					local t = PressOrDrag.THRESHOLD
					if dx * dx + dy * dy < t * t then
						return
					end
					undock(pressX, pressY)
				end
				position:Set(clampToContainer(UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)))
				local at = edgeAt(x, y)
				if at ~= candidate then
					closePreview()
					candidate = at
					if at ~= nil then
						openPreview(at)
					end
				end
			end,
			OnEnd = function(_x, _y, _dx, _dy, cancelled)
				local at = candidate
				candidate = nil
				closePreview()
				if cancelled or at == nil or side:Get() ~= nil or control.SideTaken(at) then
					return
				end
				-- the floating rectangle it keeps is where the drag began, not the edge it was dropped on
				local width = dropWidth()
				position:Set(startPos)
				control.Dock(at, width)
			end,
		})
	end

	-- the collapsed window's icon: press expands, drag moves (kept on screen with the icon as the window)
	local iconStart = UDim2.new()
	local iconGesture = PressOrDrag.new({
		OnPress = function()
			collapsed:Set(false)
		end,
		OnDragBegin = if hints.NoMove
			then nil
			else function()
				control.Raise()
				iconStart = position:Get()
			end,
		OnDrag = if hints.NoMove
			then nil
			else function(dx: number, dy: number)
				position:Set(clampToContainer(UDim2.new(iconStart.X.Scale, iconStart.X.Offset + dx, iconStart.Y.Scale, iconStart.Y.Offset + dy)))
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
	end, collapsed)
	local arrowSize: State<UDim2> = stripWidth:Compute(function(self)
		local s = math.floor(self:Get() * 0.6)
		return UDim2.fromOffset(s, s)
	end)
	local function pressStrip(wasFocused: boolean)
		if collapsed:Get() then
			collapsed:Set(false)
			control.Raise()
		elseif not wasFocused then
			control.Raise()
		else
			collapsed:Set(true)
		end
	end

	-- resize grip (floating)
	local startSize = Vector2.new()
	local minSize = hints.MinSize
	local grip: Interaction.DragHandle? = nil
	local gripHover = Interaction.hover()
	local gripLook = Style.interactive(style, "ResizeGrip", gripHover.Hovered, gripHover.Pressed)
	-- the dock width handle (docked)
	local dockResize: Interaction.DragHandle? = nil
	local dockHover = Interaction.hover()
	local dockLook = Style.interactive(style, "ResizeGrip", dockHover.Hovered, dockHover.Pressed)
	if not hints.NoResize then
		grip = Interaction.drag({
			OnBegin = function()
				control.Raise()
				startSize = size:Get()
			end,
			OnMove = function(_x, _y, dx, dy)
				local floor = if minSize then minSize else Vector2.new(style.FrameHeight:Get() * 2, style.FrameHeight:Get() * 2)
				size:Set(Vector2.new(math.max(floor.X, startSize.X + dx), math.max(floor.Y, startSize.Y + dy)))
			end,
		})
		local startWidth, widthScale = 0, 1
		dockResize = Interaction.drag({
			OnBegin = function()
				control.Raise()
				startWidth = dockWidth:Get()
				widthScale = scaleOf(frame, startWidth)
			end,
			OnMove = function(_x, _y, dx, _dy)
				local delta = dx / widthScale
				local w = if side:Get() == "Right" then startWidth - delta else startWidth + delta
				dockWidth:SetIfChanged(fitDockWidth(w))
			end,
		})
	end
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
			}),
	})
	frame = built
	local icon = TextButton({
		iconHover.Hook,
		iconGesture.Hook,
		Name = "WindowIcon",
		Position = position,
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
		-- the manager's Layout output (keyed windows only): any of the floating facts or the dock changed
		if control.Changed ~= nil
			then q.Effect(function()
				(control.Changed :: () -> ())()
			end, position, size, open, collapsed, side, dockWidth)
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
				Visible = floatingShown,
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
				Visible = dockedShown,
				BackgroundColor3 = dockLook.Color,
				BackgroundTransparency = dockLook.Transparency,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
			})
		)
	end
	-- the edge-dock preview: only a window a drag can dock
	if titleDrag ~= nil and not hints.NoDock then
		table.insert(
			parts,
			Frame({
				Name = "WindowDockPreview",
				AnchorPoint = previewSide:Compute(function(self)
					return if self:Get() == "Right" then Vector2.new(1, 0) else Vector2.new(0, 0)
				end),
				Position = previewSide:Compute(function(self)
					return if self:Get() == "Right" then UDim2.fromScale(1, 0) else UDim2.fromScale(0, 0)
				end),
				Size = previewWidth:Compute(function(self)
					return UDim2.new(0, self:Get(), 1, 0)
				end),
				-- one above this window's grip: the drag raised it to the top, so above every window
				ZIndex = control.FrontZ:Compute(function(self)
					return self:Get() + 1
				end),
				Visible = previewSide:Compute(function(self)
					return self:Get() ~= nil
				end),
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
		Surface = { Position = surfacePosition, Size = surfaceSize, Visible = shown },
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
			closePreview()
			for _, part in parts do
				if alive(part) then
					q.dispose(part)
				end
			end
		end,
	}
end

return Decoration
