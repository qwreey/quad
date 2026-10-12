--!strict
--[[
	Window — a draggable, resizable, collapsible window with a scrolling content area (Iris: Window).

		Window {
			Title: string | State<string>,
			Children: Slot<Instance>?,          -- the content (laid out top-down; use Layout.* / Text / Button inside)
			Position: Source<UDim2>?,           -- two-way: dragging the title bar writes it (default: an internal Source)
			Size: Source<Vector2>?,             -- pixels; two-way: the resize grip writes it (default 300 x 200)
			Open: Source<boolean>?,             -- the close button sets it false; setting it true shows the window again
			Collapsed: Source<boolean>?,        -- the arrow toggles it; collapsed = title bar only
			NoTitleBar / NoResize / NoMove / NoClose / NoCollapse: boolean?,   -- static flags
			MinSize: Vector2?,                  -- resize floor (default 2 x frame height square)
			Manager: WindowManager?,            -- z-order/focus group (default Manager.default)
			Style: Style?,
			Modifier: FrameModifier?,           -- extra root-frame styling (inline props still win)
		}

	Returns the root Frame (place it in a ScreenGui / a Frame container: windows that share a container are layered
	by the manager). Structure (about seven GuiObjects): root > TitleBar (CollapseButton, Title, CloseButton), Content
	(ScrollingFrame + UIListLayout + UIPadding), ResizeGrip. Closing keeps the instance and hides it (Visible=false) —
	`Open:Set(true)` brings it back with its state intact.

	Dragging uses Interaction.drag (global tracking only while a drag is active, closed on release / focus loss /
	destroy). Pressing anywhere in the window focuses it (raises it to the front).
]]

local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
local windowName = D.Modifier.Frame():Name("Window")
local Interaction = require("./Interaction")
local Style = require("./Style")
local Util = require("./Util")
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
				position:Set(UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy))
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

	return D.Frame({
		windowName,
		props.Modifier or q.None,
		Interaction.pointerDown(function()
			slot:Focus()
		end),
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
			Interaction.pointerDown(function()
				slot:Focus()
			end),
			props.Children or q.None,
		}),
		q.OnDestroyed(function()
			slot:Release()
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
end

return {
	Window = Window,
	Manager = Manager,
}
