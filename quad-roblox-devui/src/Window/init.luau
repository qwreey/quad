--!strict
--[[
	Window — a draggable, resizable, collapsible window with a scrolling content area (Iris: Window).

		Window {
			Title: string | State<string>,
			Children: Slot<Instance>?,          -- the content (laid out top-down; use Layout.* / Text / Button inside)
			MenuBar: Instance?,                 -- a bar right under the title bar, outside the padding (see MENU BAR)
			Position: Source<UDim2>?,           -- two-way: dragging the title bar writes it (default: an internal Source)
			Size: Source<Vector2>?,             -- pixels; two-way: the resize grip writes it (default 300 x 200)
			Open: Source<boolean>?,             -- the close button sets it false (unless OnCloseRequest is given); every `:Set(true)` shows the window AND brings it
			                                    -- to the front with the focus (also when it is already open — `:SetIfChanged(true)`
			                                    -- only syncs the state without raising; a layout import that opens it does
			                                    -- not raise it — Manager header STACKING)
			Focused: Source<boolean>?,          -- two-way: the window writes whether it is the focused one; set true to raise
			                                    -- and focus it, false to drop its focus (no window focused)
			AvailableSize: Source<Vector2>?,    -- output: the room the children get (visible content area minus padding)
			Collapsed: Source<boolean>?,        -- the arrow sets it; collapsed = a small icon (press: expand, drag: move)
			NoTitleBar / NoResize / NoMove / NoClose / NoCollapse: boolean?,   -- static flags
			NoDock: boolean?,                   -- static: dragging the title bar to a screen edge does not dock it (a layout may;
			                                    -- it still joins tab groups)
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

	DOCKED AT A SCREEN EDGE [2026-10-20 user decisions — docking stage 2]: drag the title bar until the pointer is at the
	left or right edge of the container (a preview shows) and release: the window docks there — a strip over the
	container's full height at the edge (`WindowDockStrip`, floating windows of that container never enter it) and the
	panel right inside it, as wide as the dock width and as tall as the container (below the Roblox top bar when the
	container reaches under it). One open window or tab group per edge (a drag to a held edge joins its group). Pressing the strip expands a collapsed panel (and focuses
	it), focuses an expanded one without the focus, and collapses the focused one (`Collapsed`: the panel hides, the
	strip stays). A handle on the panel's inner edge (`WindowDockResize`) sets the width; dragging the title bar off the
	edge makes the window float again. While docked, `Position` / `Size` keep the FLOATING rectangle (an app writing
	them moves nothing until it floats); the real size is `AvailableSize` (or the surface root's AbsoluteSize). Closing
	keeps the edge: `Open:Set(true)` docks it there again, or opens it floating when another window took that edge.
	`NoDock` stops the drag from docking (a layout may still dock it); `NoMove` stops docking and undocking by drag.
	Rules in Window/Decoration.luau header "DOCKED" and Window/Manager header "DOCK".

	TAB GROUPS [2026-10-21 user decisions — docking stage 3]: drag a window's title bar onto another window of the same
	manager and container — its title bar (where among the tabs) or its centre (the last tab), a preview shows — and
	release: both become one GROUP, one rectangle with a tab strip in the title bar's place (`WindowTab` per window,
	shown while two or more are open; in a split always — SPLITS below), only the selected window's surface shown. Press a tab to select it, drag it
	along the strip to reorder, drag it out of the strip to take the window out (it floats at its own size under the
	pointer and the drag goes on). While grouped, `Position` / `Size` keep the window's own rectangle from before it
	joined (the group's rectangle is the manager's); closing a tab hides it and keeps its slot (`Open:Set(true)` brings
	it back there, selected); `Collapsed` is the whole group's (the selected window's icon). NoTitleBar windows never
	group; NoDock does not stop grouping. Rules in Window/Manager header "TABS" and Window/Decoration.luau "TABS".

	SPLITS [2026-10-21 user decisions — docking stage 4]: release over the 20% band along one side of another window (or
	of one leaf of a split) and that window is cut in half there, the dropped one taking the half the preview shows;
	over the band 2 x frame height inside a split's outer edge, the whole split is cut. Every part (LEAF) of a split
	shows its tab strip, even with one window; the splitter between two parts (`WindowSplitter`) moves the seam; a
	part's collapse arrow folds only that part (a strip row or a thin bar — `WindowFoldBar`) and its neighbour takes the
	room, so a window's `Collapsed` in a split is its part's fold (or its docked panel's collapse). Dragging a strip's
	empty area moves the whole split; dragging a tab out takes that window out (a split left with one part is a tab
	group again). Rules in Window/Manager header "SPLITS" and Window/Decoration.luau "SPLITS".

	SAVING THE LAYOUT: give a window `Key` (its identity — unique among its manager's live windows, a duplicate raises)
	and optionally `Kind` (its type, default = the Key; two windows of one type get the same Kind and different Keys).
	The manager then exports / imports its Position, Size, Open and Collapsed, its edge and its tab group and split as plain
	JSON-ready tables (Window/Manager header "LAYOUT"). A window without a Key works the same and is just left out of the layout.

	FILLING THE HEIGHT [2026-10-20, Studio-confirmed]: give one child `q.Elem "UIFlexItem" ({ FlexMode = Enum.UIFlexMode.Fill })`
	and it takes the height the other children leave (the content list is a UIListLayout): a 300 x 300 window gave a
	20 px-tall fill 258 px, and it follows a resize; when the window is smaller than the children it shrinks below its
	own Size instead of scrolling. `AvailableSize` (an output Source the window writes; named after ImGui's content region
	"avail" — Roblox's AbsoluteContentSize means the children's total, the opposite) is the room the children get — the
	content area's visible size (AbsoluteWindowSize: a shown scrollbar is left out) minus the window padding — for
	layouts that need a number; a docked panel (sized by its edge, not by `Size`) moves both the same way.

	MENU BAR [2026-10-21 user decision — devplorer U21; the name `MenuBar` after a three-model review]: `MenuBar = an
	element` (usually `Devui.MenuBar({ ... })`, which is built for this slot but works anywhere; any GuiObject fits — a
	row of icon buttons too) is put at the top of the surface, outside the window padding, full width (its own Size
	decides; `Devui.MenuBar` is the full width and its rows' height) and not scrolling. The content starts under it:
	the window follows the bar's AbsoluteSize, so the content area and `AvailableSize` lose its height by themselves. In
	a tab group each window's bar comes with its surface, so the selected tab's bar shows.

	Returns the surface root Frame (named "Window"): root > [MenuBar] + Content (ScrollingFrame + UIListLayout + UIPadding). It is
	shown while the window is open and not collapsed. Closing keeps the instances and hides them — `Open:Set(true)`
	brings the window back with its state intact.

	Dragging uses Interaction.drag (global tracking only while a drag is active, closed on release / focus loss /
	destroy). Pressing anywhere in the window — a button, a text box or any other widget in it, or its decoration —
	focuses it (raises it to the front): the manager's one global press listener (Manager header "PRESS TO FRONT").
	Closing the focused window passes the focus to the topmost open one; opening it again brings it to the front with
	the focus (not when a layout import opens it) — the window reports its `Open` state to the manager (collapsing hides the root but is not a close). A
	press on the window's empty area stops at an invisible full-cover `ClickSink` button in the decoration frame, right
	under the surface, instead of falling through to a widget of a window beneath. Staying on screen while dragging and
	when the container shrinks: Window/Decoration.luau header "STAYING ON SCREEN".
]]

local Quad = require("./Quad")
local q = Quad
local Frame = q.Elem "Frame"
local ScrollingFrame = q.Elem "ScrollingFrame"
local TextButton = q.Elem "TextButton"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local FrameModifier = q.Modifier "Frame"
local windowName = FrameModifier():Name("Window")
local Style = require("./Style")
local Util = require("./Util")
local Visibility = require("./Visibility")
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
	read MenuBar: Instance?,
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
	read NoDock: boolean?,
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
		NoDock = props.NoDock == true,
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

	-- [2026-10-21 user decision — devplorer U21; name by a three-model review] the menu bar: drawn at the top of the
	-- surface, outside the window padding, full width and not scrolling; the content starts under it, so the content
	-- area (and `AvailableSize`, which is measured from it) loses its height by itself. In a tab group each window's
	-- bar comes with its surface (the selected tab's shows)
	local menuBar = props.MenuBar
	local barHeight: Source<number> = q.Source(0)
	if menuBar ~= nil then
		if not Visibility.isGuiObject(menuBar) then
			Util.fail("Window", `MenuBar must be a GuiObject (e.g. Devui.MenuBar(...)), got {menuBar.ClassName}`)
		end
		local bar = menuBar :: GuiObject
		bar.Position = UDim2.fromOffset(0, 0)
		barHeight:Set(bar.AbsoluteSize.Y)
		bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			barHeight:SetIfChanged(bar.AbsoluteSize.Y)
		end)
	end
	local contentPosition: State<UDim2> = barHeight:Compute(function(self)
		return UDim2.fromOffset(0, self:Get())
	end)
	local contentSize: State<UDim2> = barHeight:Compute(function(self)
		return UDim2.new(1, 0, 1, -self:Get())
	end)

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
		menuBar or q.None,
		ScrollingFrame({
			Name = "Content",
			-- a shown scrollbar takes its width from the content instead of covering it (AvailableSize already leaves it out)
			VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
			Position = contentPosition,
			Size = contentSize,
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
		-- [2026-10-21 user decision] a small side's veil (Manager header SPLITS "SMALL SIDE"): it eats the press so
		-- nothing unseen under it is clicked — the press focuses this window, which swaps the sides. Inside the root
		-- (under every decoration part, so the seam's splitter stays on top)
		TextButton({
			Name = "WindowDim",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
			Visible = placement.Dimmed,
			Active = true,
			AutoButtonColor = false,
			Text = "",
			BackgroundColor3 = style.Color.NavWindowingDimBg,
			-- (a seam drag's preview fades it in or out: strength 0..1 over the token's own transparency)
			BackgroundTransparency = placement.DimStrength:Compute(function(self, _prev, full)
				return 1 - (1 - full:Get()) * self:Get()
			end, style.Transparency.NavWindowingDimBg),
			BorderSizePixel = 0,
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
