--!strict
--[[
	Window — a draggable, resizable, collapsible window with a scrolling content area (Iris: Window).

		Window {
			Title: string | State<string>,
			Children: Slot<Instance>?,          -- the content (laid out top-down; use Layout.* / Text / Button inside)
			Position: Source<UDim2>?,           -- two-way: dragging the title bar writes it (default: an internal Source)
			Size: Source<Vector2>?,             -- pixels; two-way: the resize grip writes it (default 300 x 200)
			Open: Source<boolean>?,             -- the close button sets it false (unless OnCloseRequest is given); every `:Set(true)` shows the window AND brings it
			                                    -- to the front with the focus (also when it is already open — `:SetIfChanged(true)`
			                                    -- only syncs the state without raising)
			Focused: Source<boolean>?,          -- two-way: the window writes whether it is the focused one; set true to raise
			                                    -- and focus it, false to drop its focus (no window focused)
			AvailableSize: Source<Vector2>?,    -- output: the room the children get (visible content area minus padding)
			Collapsed: Source<boolean>?,        -- the arrow sets it; collapsed = a small icon (press: expand, drag: move)
			NoTitleBar / NoResize / NoMove / NoClose / NoCollapse: boolean?,   -- static flags
			OnCloseRequest: (() -> ())?,        -- given: the close button only calls it and leaves Open alone — the app decides
			                                    -- (ask in a dialog, then `Open:Set(false)`, destroy, `ForgetWindow`); nil: it closes
			MinSize: Vector2?,                  -- resize floor (default 2 x frame height square)
			Icon: string?,                      -- the collapsed icon's image (default: the title's first letter)
			Key: string?,                       -- the window's identity in its manager (unique; saved in the layout)
			Kind: string?,                      -- the window's type (default Key): the factory a layout loader calls
			Manager: WindowManager?,            -- z-order/focus group and decorations (default Manager.default)
			Style: Style?,
			Modifier: ModifierInto<Frame>?,           -- extra styling of the returned surface root (inline props still win)
		}

	SURFACE AND DECORATION [2026-10-20 user decision — the WindowManager is a compositor]: the returned root is the
	window's content SURFACE only (the scrolling content area). The frame (background, border), the title bar and the
	resize grip are DECORATION that the window's manager draws (Window/Decoration.luau, like Wayland's server-side
	decorations) as SIBLINGS of the root, in whatever parent you give the root: they follow its `Parent` (nil parent =
	nothing on screen) and are disposed with it. Put the root in a ScreenGui / a Frame container as before — the
	decoration instances appear next to it (`WindowDecoration` holding the TitleBar, `WindowResizeGrip`); never parent
	them yourself. Title, the No* flags and MinSize are hints the surface gives its compositor (same names, same
	meaning). Position / Size are the window's OUTER rectangle, title bar included (the root sits under the title bar
	and gets the rest).

	COLLAPSED [2026-10-20 user decision]: a collapsed floating window is a small square icon drawn by the compositor at
	`Position` (the outer top-left) — the `Icon` image, or the title's first letter on a rounded square. Pressing it
	expands the window; dragging it moves the window. There is no "title bar only" look any more.

	SAVING THE LAYOUT: give a window `Key` (its identity — unique among its manager's live windows, a duplicate raises)
	and optionally `Kind` (its type, default = the Key; two windows of one type get the same Kind and different Keys).
	The manager then exports / imports its Position, Size, Open and Collapsed as plain JSON-ready tables (Window/Manager
	header "LAYOUT"). A window without a Key works the same and is just left out of the layout.

	FILLING THE HEIGHT [2026-10-20, Studio-confirmed]: give one child `q.Elem "UIFlexItem" ({ FlexMode = Enum.UIFlexMode.Fill })`
	and it takes the height the other children leave (the content list is a UIListLayout): a 300 x 300 window gave a
	20 px-tall fill 258 px, and it follows a resize; when the window is smaller than the children it shrinks below its
	own Size instead of scrolling. `AvailableSize` (an output Source the window writes; named after ImGui's content region
	"avail" — Roblox's AbsoluteContentSize means the children's total, the opposite) is the room the children get — the
	content area's visible size (AbsoluteWindowSize: a shown scrollbar is left out) minus the window padding — for
	layouts that need a number; a container that sets the window's size (a future dock) moves both the same way.

	Returns the surface root Frame (named "Window"): root > Content (ScrollingFrame + UIListLayout + UIPadding). It is
	shown while the window is open and not collapsed. Closing keeps the instances and hides them — `Open:Set(true)`
	brings the window back with its state intact.

	Dragging uses Interaction.drag (global tracking only while a drag is active, closed on release / focus loss /
	destroy). Pressing anywhere in the window — a button, a text box or any other widget in it, or its decoration —
	focuses it (raises it to the front): the manager's one global press listener (Manager header "PRESS TO FRONT").
	Closing the focused window passes the focus to the topmost open one; opening it again brings it to the front with
	the focus — the window reports its `Open` state to the manager (collapsing hides the root but is not a close). A
	press on the window's empty area stops at an invisible full-cover `ClickSink` button in the decoration frame, right
	under the surface, instead of falling through to a widget of a window beneath. Staying on screen while dragging and
	when the container shrinks: Window/Decoration.luau header "STAYING ON SCREEN".
]]

local Quad = require("./Quad")
local q = Quad
local Frame = q.Elem "Frame"
local ScrollingFrame = q.Elem "ScrollingFrame"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local FrameModifier = q.Modifier "Frame"
local windowName = FrameModifier():Name("Window")
local Style = require("./Style")
local Util = require("./Util")
local Manager = require("@self/Manager")
local Compositor = require("@self/Compositor")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Slot<T> = Quad.Slot<T>
type Style = Style.Style

export type Manager = Manager.Manager
export type ManagerSlot = Manager.Slot
export type WindowLayout = Manager.WindowLayout
export type WindowState = Manager.WindowState

export type WindowProps = {
	read Title: string | State<string>,
	read Children: Slot<Instance>?,
	read Position: Source<UDim2>?,
	read Size: Source<Vector2>?,
	read Open: Source<boolean>?,
	read Focused: Source<boolean>?,
	read AvailableSize: Source<Vector2>?,
	read Collapsed: Source<boolean>?,
	read NoTitleBar: boolean?,
	read NoResize: boolean?,
	read NoMove: boolean?,
	read NoClose: boolean?,
	read NoCollapse: boolean?,
	read OnCloseRequest: (() -> ())?,
	read MinSize: Vector2?,
	read Icon: string?,
	read Key: string?,
	read Kind: string?,
	read Manager: Manager.Manager?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

local function Window(props: WindowProps): Frame
	local key, kind = props.Key, props.Kind
	if key ~= nil and type(key) ~= "string" then
		Util.fail("Window", `Key must be a string (the window's identity), got {typeof(key)}`)
	end
	if kind ~= nil and type(kind) ~= "string" then
		Util.fail("Window", `Kind must be a string (the window's type), got {typeof(kind)}`)
	end
	local onCloseRequest = props.OnCloseRequest
	if onCloseRequest ~= nil and type(onCloseRequest) ~= "function" then
		Util.fail("Window", `OnCloseRequest must be a function, got {typeof(onCloseRequest)}`)
	end
	local style = props.Style or Style.default
	local manager = props.Manager or Manager.default
	local slot = manager:Register()

	local position: Source<UDim2> = props.Position or q.Source(UDim2.fromOffset(60, 60))
	local size: Source<Vector2> = props.Size or q.Source(Vector2.new(300, 200))
	local open: Source<boolean> = props.Open or q.Source(true)
	local collapsed: Source<boolean> = props.Collapsed or q.Source(false)

	-- the compositor draws the frame, title bar and grip from these hints and answers where the surface goes
	local placement = Compositor.decorate(slot, {
		Style = style,
		Title = props.Title,
		Position = position,
		Size = size,
		Open = open,
		Collapsed = collapsed,
		NoTitleBar = props.NoTitleBar == true,
		NoResize = props.NoResize == true,
		NoMove = props.NoMove == true,
		NoClose = props.NoClose == true,
		NoCollapse = props.NoCollapse == true,
		OnCloseRequest = onCloseRequest,
		MinSize = props.MinSize,
		Icon = props.Icon,
		Key = props.Key,
		Kind = props.Kind,
	})

	-- [2026-10-15 user decision] the owner drives the window through the Sources it already holds, no handle:
	-- `open:Set(true)` raises (quad's `Set` re-emits an equal value, `SetIfChanged` does not). The install run of the
	-- Observer is skipped — a window open from the start does not steal the focus. Every later emission is reported
	-- to the compositor (open raises with the focus, closed passes the focus on): the window's open state, not its
	-- root's Visible, is what "closed" means to the manager.
	-- [2026-10-20 user decision] `Focused` is TWO-WAY like InputText's (one meaning for `Focused` across the kit, after a
	-- three-model naming review flagged the output-only / two-way split): the window writes its focus state, and a
	-- write from outside asks — true raises and focuses (`slot:Focus()`), false drops the focus (`slot:Blur()`). A
	-- `true` the Source already holds when the window is built is a request too (an explicit ask, unlike the default).
	local openInstalled = false
	local reportOpen = open:Observer(function(self)
		if not openInstalled then
			openInstalled = true
			return
		end
		Compositor.setOpen(slot, self:Get())
	end)
	local focusedOut = props.Focused
	-- the outside asks through `Focused` (runs before the mirror below; the mirror's own writes come back here as no-ops:
	-- true on the focused top window and false on an unfocused one change nothing). A closed window ignores a true —
	-- open it with `Open:Set(true)`, which focuses it.
	local focusRequest = if focusedOut
		then focusedOut:Observer(function(self)
			if self:Get() then
				if open:Get() then
					slot:Focus()
				end
			elseif slot.Focused:Get() then
				slot:Blur()
			end
		end)
		else q.None
	local focusedMirror = if focusedOut
		then slot.Focused:Observer(function(self)
			focusedOut:SetIfChanged(self:Get())
		end)
		else q.None

	-- `AvailableSize` (output): the content area's visible size minus the window padding (see the header)
	local availableOut = props.AvailableSize
	local visibleArea: Source<Vector2> = q.Source(Vector2.zero)
	local availableMirror = if availableOut
		then visibleArea
			:Compute(function(self, _prev, pad)
				local v, p = self:Get(), pad:Get()
				return Vector2.new(math.max(0, v.X - 2 * p.X), math.max(0, v.Y - 2 * p.Y))
			end, style.Metrics.WindowPadding)
			:Observer(function(self)
				availableOut:SetIfChanged(self:Get())
			end)
		else q.None

	return Frame({
		windowName,
		reportOpen,
		focusRequest,
		focusedMirror,
		availableMirror,
		props.Modifier or q.None,
		slot.Hook,
		Position = placement.Position,
		Size = placement.Size,
		ZIndex = slot.ZIndex,
		Visible = placement.Visible,
		Active = true,
		-- the decoration frame under the surface paints the window background (Window/Decoration.luau header)
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingFrame({
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Active = true,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = style.Metrics.ScrollbarSize,
			ScrollBarImageColor3 = style.Color.ScrollbarGrab,
			ScrollBarImageTransparency = style.Transparency.ScrollbarGrab,
			if availableOut then q.Out "ScrollingFrame" "AbsoluteWindowSize" (visibleArea) else q.None,
			UIPadding({
				PaddingLeft = Util.pxX(style.Metrics.WindowPadding),
				PaddingRight = Util.pxX(style.Metrics.WindowPadding),
				PaddingTop = Util.pxY(style.Metrics.WindowPadding),
				PaddingBottom = Util.pxY(style.Metrics.WindowPadding),
			}),
			UIListLayout({
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = Util.pxY(style.Metrics.ItemSpacing),
			}),
			props.Children or q.None,
		}),
		-- leaving the manager disposes the decoration too
		q.OnDestroyed(function()
			slot:Release()
		end),
	})
end

return {
	Window = Window,
	Manager = Manager,
}
