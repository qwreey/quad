--!strict
--[[
	Window — a draggable, resizable, collapsible window with a scrolling content area (Iris: Window).

		Window {
			Title: string | State<string>,
			Children: Slot<Instance>?,          -- the content (laid out top-down; use Layout.* / Text / Button inside)
			Position: Source<UDim2>?,           -- two-way: dragging the title bar writes it (default: an internal Source)
			Size: Source<Vector2>?,             -- pixels; two-way: the resize grip writes it (default 300 x 200)
			Open: Source<boolean>?,             -- the close button sets it false; every `:Set(true)` shows the window AND brings it
			                                    -- to the front with the focus (also when it is already open — `:SetIfChanged(true)`
			                                    -- only syncs the state without raising)
			Focused: Source<boolean>?,          -- output: the window writes whether it is the focused one (like Position on a drag)
			ContentSize: Source<Vector2>?,      -- output: the room the children get (visible content area minus padding)
			Collapsed: Source<boolean>?,        -- the arrow toggles it; collapsed = title bar only
			NoTitleBar / NoResize / NoMove / NoClose / NoCollapse: boolean?,   -- static flags
			MinSize: Vector2?,                  -- resize floor (default 2 x frame height square)
			Manager: WindowManager?,            -- z-order/focus group (default Manager.default)
			Style: Style?,
			Modifier: FrameModifier?,           -- extra root-frame styling (inline props still win)
		}

	FILLING THE HEIGHT [2026-10-20, Studio-confirmed]: give one child `D.UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill })`
	and it takes the height the other children leave (the content list is a UIListLayout): a 300 x 300 window gave a
	20 px-tall fill 258 px, and it follows a resize; when the window is smaller than the children it shrinks below its
	own Size instead of scrolling. `ContentSize` (an output Source, like `Focused`) is the room the children get — the
	content area's visible size (AbsoluteWindowSize: a shown scrollbar is left out) minus the window padding — for
	layouts that need a number; a container that sets the window's size (a future dock) moves both the same way.

	Returns the root Frame (place it in a ScreenGui / a Frame container: windows that share a container are layered
	by the manager). Structure (about eight GuiObjects): root > ClickSink, TitleBar (CollapseButton, Title, CloseButton), Content
	(ScrollingFrame + UIListLayout + UIPadding), ResizeGrip. Closing keeps the instance and hides it (Visible=false) —
	`Open:Set(true)` brings it back with its state intact.

	Dragging uses Interaction.drag (global tracking only while a drag is active, closed on release / focus loss /
	destroy). Pressing anywhere in the window — a button, a text box or any other widget in it included — focuses it
	(raises it to the front): the manager's one global press listener (Manager header "PRESS TO FRONT"). Closing the
	focused window passes the focus to the topmost open one; opening it again brings it to the front with the focus.
	A press on the window's empty area stops at an invisible full-cover `ClickSink` button (ZIndex 0) instead of falling
	through to a widget of a window beneath.

	STAYING ON SCREEN (Dear ImGui `ClampWindowPos`, imgui.cpp — `DisplayWindowPadding` 19 at the default size, applied
	with the title bar as the window's height when the window moves by its title bar only): the window's top-left is
	kept in [pad - width, W - pad] x [pad - band, H - pad] of its container (W x H = the container's size, pad =
	max(FrameHeight, DisplaySafeAreaPadding) — FrameHeight is 19 at the default size like ImGui's padding and scales
	with the style; band = the title bar height, or the window height without a title bar). With the title bar that
	is: at least `pad` pixels of the title bar stay inside horizontally and the whole title bar vertically (its top
	never goes above the container). Applied (1) while dragging the title bar and (2) when the container SHRINKS (its
	AbsoluteSize gets smaller in either axis, not to zero) — then an out-of-bounds window is brought back in by writing
	the Position Source. A position the program sets is otherwise left alone (also one outside the container), and a
	container that grows clamps nothing.
]]

local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
local windowName = D.Modifier.Frame():Name("Window")
local Interaction = require("./Interaction")
local Style = require("./Style")
local Util = require("./Util")
local Visibility = require("./Visibility")
local Manager = require("@self/Manager")
local TitleBar = require("@self/TitleBar")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Slot<T> = Quad.Slot<T>
type Style = Style.Style

export type Manager = Manager.Manager
export type ManagerSlot = Manager.Slot

export type WindowProps = {
	read Title: string | State<string>,
	read Children: Slot<Instance>?,
	read Position: Source<UDim2>?,
	read Size: Source<Vector2>?,
	read Open: Source<boolean>?,
	read Focused: Source<boolean>?,
	read ContentSize: Source<Vector2>?,
	read Collapsed: Source<boolean>?,
	read NoTitleBar: boolean?,
	read NoResize: boolean?,
	read NoMove: boolean?,
	read NoClose: boolean?,
	read NoCollapse: boolean?,
	read MinSize: Vector2?,
	read Manager: Manager.Manager?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

local function Window(props: WindowProps): Frame
	local style = props.Style or Style.default
	local manager = props.Manager or Manager.default
	local slot = manager:Register()

	local position: Source<UDim2> = props.Position or q.Source(UDim2.fromOffset(60, 60))
	local size: Source<Vector2> = props.Size or q.Source(Vector2.new(300, 200))
	local open: Source<boolean> = props.Open or q.Source(true)
	local collapsed: Source<boolean> = props.Collapsed or q.Source(false)
	local noTitleBar = props.NoTitleBar == true

	-- title bar height (0 without a title bar)
	local noHeight: State<number> = q.Source(0)
	local titleHeight: State<number> = if noTitleBar then noHeight else style.FrameHeight

	local rootSize: State<UDim2> = size:Compute(function(self, _prev, isCollapsed, titleH)
		local s = self:Get()
		if isCollapsed:Get() then
			return UDim2.fromOffset(s.X, titleH:Get())
		end
		return UDim2.fromOffset(s.X, s.Y)
	end, collapsed, titleHeight)

	local expanded: State<boolean> = collapsed:Compute(function(self)
		return not self:Get()
	end)
	local rootAlpha: State<number> = collapsed:Compute(function(self, _prev, alpha)
		return if self:Get() then 1 else alpha:Get()
	end, style.Transparency.WindowBg)

	local contentPos: State<UDim2> = titleHeight:Compute(function(self)
		return UDim2.fromOffset(0, self:Get())
	end)
	local contentSize: State<UDim2> = titleHeight:Compute(function(self)
		return UDim2.new(1, 0, 1, -self:Get())
	end)
	local gripSize: State<UDim2> = style.Metrics.TextSize:Compute(function(self, _prev, padding)
		local s = self:Get() + padding:Get().X
		return UDim2.fromOffset(s, s)
	end, style.Metrics.FramePadding)
	local gripVisible: State<boolean> = expanded

	-- assigned right after the root is built; read only from event handlers
	local root: Frame? = nil

	-- keep the window reachable inside its container (header "STAYING ON SCREEN"); `pos` unchanged when it already is
	local function clampToContainer(pos: UDim2): UDim2
		local r = root
		local container = if r then r.Parent else nil
		if r == nil or container == nil or not Visibility.hasArea(container) then
			return pos
		end
		local area = (container :: GuiBase2d).AbsoluteSize
		if area.X <= 0 or area.Y <= 0 then
			return pos -- (a zero-sized container: minimised / not laid out yet — Dear ImGui skips it too)
		end
		local s = size:Get()
		local titleH = titleHeight:Get()
		local w = s.X
		local h = if collapsed:Get() then titleH else s.Y
		-- AbsoluteSize is in screen pixels, Position offsets in the window's own units: an ancestor UIScale divides
		local abs = r.AbsoluteSize
		local scale = if w > 0 and abs.X > 0 then abs.X / w else 1
		local cw, ch = area.X / scale, area.Y / scale
		local safe = style.Metrics.DisplaySafeAreaPadding:Get()
		local frame = style.FrameHeight:Get()
		local padX, padY = math.max(frame, safe.X), math.max(frame, safe.Y)
		local band = if titleH > 0 then titleH else h
		local anchor = r.AnchorPoint or Vector2.zero -- (`or`: the spec mock has no property defaults)
		local x = pos.X.Scale * cw + pos.X.Offset - anchor.X * w
		local y = pos.Y.Scale * ch + pos.Y.Offset - anchor.Y * h
		local cx = math.max(padX - w, math.min(cw - padX, x))
		local cy = math.max(padY - band, math.min(ch - padY, y))
		if cx == x and cy == y then
			return pos
		end
		return UDim2.new(pos.X.Scale, pos.X.Offset + math.round(cx - x), pos.Y.Scale, pos.Y.Offset + math.round(cy - y))
	end

	-- title-bar drag moves the window (pixel deltas added to the Position offsets)
	local startPos = UDim2.new()
	local titleDrag: Interaction.DragHandle? = nil
	if not props.NoMove then
		titleDrag = Interaction.drag({
			OnBegin = function()
				slot:Focus()
				startPos = position:Get()
			end,
			OnMove = function(_x, _y, dx, dy)
				position:Set(clampToContainer(UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)))
			end,
		})
	end

	-- resize grip
	local startSize = Vector2.new()
	local minSize = props.MinSize
	local grip: Interaction.DragHandle? = nil
	local gripHover = Interaction.hover()
	local gripLook = Style.interactive(style, "ResizeGrip", gripHover.Hovered, gripHover.Pressed)
	if not props.NoResize then
		grip = Interaction.drag({
			OnBegin = function()
				slot:Focus()
				startSize = size:Get()
			end,
			OnMove = function(_x, _y, dx, dy)
				local floor = if minSize then minSize else Vector2.new(style.FrameHeight:Get() * 2, style.FrameHeight:Get() * 2)
				size:Set(Vector2.new(math.max(floor.X, startSize.X + dx), math.max(floor.Y, startSize.Y + dy)))
			end,
		})
	end

	local strokeThickness: State<number> = style.Metrics.WindowBorderSize

	-- the container shrinking brings an out-of-bounds window back in (one connection, on the current container)
	local containerConn: RBXScriptConnection? = nil
	local lastArea = Vector2.zero
	local function watchContainer()
		local c = containerConn
		if c then
			containerConn = nil
			c:Disconnect()
		end
		local r = root
		local container = if r then r.Parent else nil
		if container == nil or not Visibility.hasArea(container) then
			return
		end
		local gui = container :: GuiBase2d
		lastArea = gui.AbsoluteSize
		containerConn = gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local area = gui.AbsoluteSize
			local shrank = area.X < lastArea.X or area.Y < lastArea.Y
			lastArea = area
			if shrank and area.X > 0 and area.Y > 0 then
				local current = position:Get()
				local inside = clampToContainer(current)
				if inside ~= current then
					position:Set(inside)
				end
			end
		end)
	end

	-- [2026-10-15 user decision] the owner drives the window through the Sources it already holds, no handle:
	-- `open:Set(true)` raises (quad's `Set` re-emits an equal value, `SetIfChanged` does not), and `Focused` is an
	-- output Source. The install run of the Observer is skipped — a window open from the start does not steal the focus.
	local openInstalled = false
	local raiseOnOpen = open:Observer(function(self)
		if not openInstalled then
			openInstalled = true
			return
		end
		if self:Get() then
			slot:Focus()
		end
	end)
	local focusedOut = props.Focused
	local focusedMirror = if focusedOut
		then slot.Focused:Observer(function(self)
			focusedOut:SetIfChanged(self:Get())
		end)
		else q.None

	-- `ContentSize` (output): the content area's visible size minus the window padding (see the header)
	local contentOut = props.ContentSize
	local visibleArea: Source<Vector2> = q.Source(Vector2.zero)
	local contentMirror = if contentOut
		then visibleArea
			:Compute(function(self, _prev, pad)
				local v, p = self:Get(), pad:Get()
				return Vector2.new(math.max(0, v.X - 2 * p.X), math.max(0, v.Y - 2 * p.Y))
			end, style.Metrics.WindowPadding)
			:Observer(function(self)
				contentOut:SetIfChanged(self:Get())
			end)
		else q.None

	local built = D.Frame({
		windowName,
		raiseOnOpen,
		focusedMirror,
		contentMirror,
		props.Modifier or q.None,
		slot.Hook,
		Position = position,
		Size = rootSize,
		ZIndex = slot.ZIndex,
		Visible = open,
		Active = true,
		BackgroundColor3 = style.Color.WindowBg,
		BackgroundTransparency = rootAlpha,
		BorderSizePixel = 0,
		UICorner = style.Metrics.WindowRounding,
		D.UIStroke({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = strokeThickness,
			Color = style.Color.Border,
			Transparency = style.Transparency.Border,
		}),
		-- a press on the window's empty area must not fall through to a window beneath: a plain Frame / ScrollingFrame
		-- passes a click on to the GuiButton under it (`Active` does not stop it), only a GuiButton sinks it. Direct
		-- child at ZIndex 0 (the root lays nothing out), so every other child stays above it (user decision 2026-10-15).
		D.TextButton({
			Name = "ClickSink",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Selectable = false,
		}),
		if noTitleBar
			then q.None
			else TitleBar.new({
				Style = style,
				Title = props.Title,
				Collapsed = collapsed,
				Open = open,
				Focused = slot.Focused,
				NoCollapse = props.NoCollapse == true,
				NoClose = props.NoClose == true,
				Drag = titleDrag,
			}),
		D.ScrollingFrame({
			Name = "Content",
			Position = contentPos,
			Size = contentSize,
			Visible = expanded,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = true,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = style.Metrics.ScrollbarSize,
			ScrollBarImageColor3 = style.Color.ScrollbarGrab,
			ScrollBarImageTransparency = style.Transparency.ScrollbarGrab,
			if contentOut then q.Out("AbsoluteWindowSize", visibleArea) else q.None,
			D.UIPadding({
				PaddingLeft = Util.pxX(style.Metrics.WindowPadding),
				PaddingRight = Util.pxX(style.Metrics.WindowPadding),
				PaddingTop = Util.pxY(style.Metrics.WindowPadding),
				PaddingBottom = Util.pxY(style.Metrics.WindowPadding),
			}),
			D.UIListLayout({
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = Util.pxY(style.Metrics.ItemSpacing),
			}),
			props.Children or q.None,
		}),
		q.OnDestroyed(function()
			slot:Release()
			local c = containerConn
			if c then
				containerConn = nil
				c:Disconnect()
			end
		end),
		if grip
			then D.ImageButton({
				gripHover.Hook,
				grip.Hook,
				Name = "ResizeGrip",
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.fromScale(1, 1),
				Size = gripSize,
				ZIndex = 2,
				Visible = gripVisible,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Image = style.Icons.ResizeGrip,
				ImageColor3 = gripLook.Color,
				ImageTransparency = gripLook.Transparency,
			})
			else q.None,
	})
	root = built
	built:GetPropertyChangedSignal("Parent"):Connect(watchContainer)
	watchContainer()
	return built
end

return {
	Window = Window,
	Manager = Manager,
}
