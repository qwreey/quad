--!strict
--[[
	Window decoration (internal, compositor side): what the WindowManager draws AROUND a window's surface — the frame
	(background, border, corner), the title bar and the resize grip — and the moving / resizing / staying-on-screen
	behaviour that goes with them. Wayland's server-side decorations: Window (the client) returns only its content
	surface, and the compositor (the manager) owns everything around it. Made by `Manager` through the Compositor port,
	never by Window directly.

	Instances (made here, placed by the manager as SIBLINGS of the surface root, in its parent):
		WindowDecoration (Frame, the outer rectangle: Position / Size, title bar included)
			UICorner, UIStroke, ClickSink (TextButton, ZIndex 0), TitleBar (Window/TitleBar.luau)
		WindowIcon (TextButton, the collapsed window — see COLLAPSED = ICON)
			UICorner, UIStroke, Image (ImageLabel, only with an `Icon` hint)
		WindowResizeGrip (ImageButton, anchored at the outer rectangle's bottom-right corner)
	The frame sits BELOW the surface (it paints the background the surface is drawn on) and the grip ABOVE it (it
	overlaps the content's corner): the manager gives each window three consecutive ZIndex ranks (frame, surface, grip).
	The icon takes the grip's rank (it is shown only while the frame, the surface and the grip are hidden).

	COLLAPSED = ICON [2026-10-20 user decision — one `Collapsed`, its look decided by where the window is]: a collapsed
	floating window shows only a small square icon (2 x FrameHeight) at its `Position` (the outer rectangle's top-left,
	so expanding opens the window right where the icon was). Its picture is the `Icon` hint (an image id), else the first
	letter of the title on a rounded square — no uploaded image needed. Pressing the icon expands the window
	(`Collapsed:Set(false)`); dragging it moves the window (writes `Position`, kept on screen like a title-bar drag with
	the icon as the window). Press and drag are told apart by a few pixels of movement (Window/PressOrDrag.luau). A
	gamepad / keyboard activation of the selected icon expands too. There is no "title bar only" collapsed look.

	Why the background and border are decoration, not surface: they enclose the whole outer rectangle (title bar
	included), which only the compositor knows; a collapsed window swaps the whole frame for its icon, which only the
	compositor draws; and a future group of surfaces (tabs) shares one frame. The surface stays transparent, and a
	press on its empty area falls through to the frame's ClickSink right under it (still this window's chunk).

	The surface's placement is answered here too (`Surface`): under the title bar, the rest of Size, shown while open and
	not collapsed. Position / Size keep their meaning — the floating window's OUTER rectangle, title bar included (an
	app that sizes its content as `Size - <title allowance>` keeps working).

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

local Quad = require("../Quad")
local q = Quad
local Frame = q.Elem "Frame"
local ImageButton = q.Elem "ImageButton"
local TextButton = q.Elem "TextButton"
local UIStroke = q.Elem "UIStroke"
local ImageLabel = q.Elem "ImageLabel"
local UICorner = q.Elem "UICorner"
local Interaction = require("../Interaction")
local Style = require("../Style")
local Visibility = require("../Visibility")
local PressOrDrag = require("./PressOrDrag")
local TitleBar = require("./TitleBar")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

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
	Changed: (() -> ())?, -- Position / Size / Open / Collapsed changed (the manager's Layout output; keyed windows)
}

export type Decoration = {
	Parts: { Instance },
	Surface: Placement,
	SetParent: (parent: Instance?) -> (),
	Destroy: () -> (),
}

local Decoration = {}

-- a part destroyed by the engine (its parent went first) is no longer quad's: leave it alone (its Parent is locked)
local function alive(inst: Instance): boolean
	return q.Backend.isClaimed(inst)
end

function Decoration.new(hints: Hints, control: Control): Decoration
	local style = hints.Style
	local position = hints.Position
	local size = hints.Size
	local open = hints.Open
	local collapsed = hints.Collapsed

	-- title bar height (0 without a title bar)
	local noHeight: State<number> = q.Source(0)
	local titleHeight: State<number> = if hints.NoTitleBar then noHeight else style.FrameHeight

	local expanded: State<boolean> = collapsed:Compute(function(self)
		return not self:Get()
	end)
	local shown: State<boolean> = open:Compute(function(self, _prev, isExpanded)
		return self:Get() and isExpanded:Get()
	end, expanded)

	local frameSize: State<UDim2> = size:Compute(function(self)
		local s = self:Get()
		return UDim2.fromOffset(s.X, s.Y)
	end)
	local iconShown: State<boolean> = open:Compute(function(self, _prev, isCollapsed)
		return self:Get() and isCollapsed:Get()
	end, collapsed)
	local iconSide: State<number> = style.FrameHeight:Compute(function(self)
		return self:Get() * 2
	end)

	local surfacePosition: State<UDim2> = position:Compute(function(self, _prev, titleH)
		local p = self:Get()
		return UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + titleH:Get())
	end, titleHeight)
	local surfaceSize: State<UDim2> = size:Compute(function(self, _prev, titleH)
		local s = self:Get()
		return UDim2.fromOffset(s.X, math.max(0, s.Y - titleH:Get()))
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

	-- keep the window reachable inside its container (header "STAYING ON SCREEN"); `pos` unchanged when it already is
	local function clampToContainer(pos: UDim2): UDim2
		-- a collapsed window is its icon: the icon is the whole window (its band too)
		local isIcon = collapsed:Get()
		local f: GuiObject? = if isIcon then iconButton else frame
		local container = if f then f.Parent else nil
		if f == nil or container == nil or not Visibility.hasArea(container) then
			return pos
		end
		local area = (container :: GuiBase2d).AbsoluteSize
		if area.X <= 0 or area.Y <= 0 then
			return pos -- (a zero-sized container: minimised / not laid out yet — Dear ImGui skips it too)
		end
		local s = size:Get()
		local titleH = titleHeight:Get()
		local side = iconSide:Get()
		local w = if isIcon then side else s.X
		local h = if isIcon then side else s.Y
		-- AbsoluteSize is in screen pixels, Position offsets in the window's own units: an ancestor UIScale divides
		local abs = f.AbsoluteSize
		local scale = if w > 0 and abs.X > 0 then abs.X / w else 1
		local cw, ch = area.X / scale, area.Y / scale
		local safe = style.Metrics.DisplaySafeAreaPadding:Get()
		local frameH = style.FrameHeight:Get()
		local padX, padY = math.max(frameH, safe.X), math.max(frameH, safe.Y)
		local band = if titleH > 0 and not isIcon then titleH else h
		local x = pos.X.Scale * cw + pos.X.Offset
		local y = pos.Y.Scale * ch + pos.Y.Offset
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
	if not hints.NoMove then
		titleDrag = Interaction.drag({
			OnBegin = function()
				control.Raise()
				startPos = position:Get()
			end,
			OnMove = function(_x, _y, dx, dy)
				position:Set(clampToContainer(UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)))
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
	local iconHover = Interaction.hover()
	-- pressed > hovered > focused > idle (the title bar's colours at rest, the button's under the pointer)
	local function iconLook(pick: (token: string) -> State<any>): State<any>
		return iconHover.Hovered:Compute(function(self, _prev, isPressed, isFocused, idle, active, hovered, pressed)
			if isPressed:Get() then
				return pressed:Get()
			elseif self:Get() then
				return hovered:Get()
			elseif isFocused:Get() then
				return active:Get()
			end
			return idle:Get()
		end, iconHover.Pressed, control.Focused, pick("TitleBg"), pick("TitleBgActive"), pick("ButtonHovered"), pick("ButtonActive"))
	end
	local iconBg: State<Color3> = iconLook(function(token)
		return style:ColorOf(token)
	end)
	local iconAlpha: State<number> = iconLook(function(token)
		return style:AlphaOf(token)
	end)
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

	-- resize grip
	local startSize = Vector2.new()
	local minSize = hints.MinSize
	local grip: Interaction.DragHandle? = nil
	local gripHover = Interaction.hover()
	local gripLook = Style.interactive(style, "ResizeGrip", gripHover.Hovered, gripHover.Pressed)
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
	end

	-- the container shrinking brings an out-of-bounds window back in (one connection, on the current container)
	local containerConn: RBXScriptConnection? = nil
	local lastArea = Vector2.zero
	local function unwatch()
		local c = containerConn
		if c then
			containerConn = nil
			c:Disconnect()
		end
	end
	local function watchContainer()
		unwatch()
		local f = frame
		local container = if f then f.Parent else nil
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

	local built = Frame({
		Name = "WindowDecoration",
		Position = position,
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
		-- the manager's Layout output (keyed windows only): any of the four floating facts changed
		if control.Changed ~= nil
			then q.Effect(function()
				(control.Changed :: () -> ())()
			end, position, size, open, collapsed)
			else q.None,
	})
	iconButton = icon
	local parts: { Instance } = { built, icon }
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
				Visible = shown,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Image = style.Icons.ResizeGrip,
				ImageColor3 = gripLook.Color,
				ImageTransparency = gripLook.Transparency,
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
		Destroy = function()
			unwatch()
			for _, part in parts do
				if alive(part) then
					q.dispose(part)
				end
			end
		end,
	}
end

return Decoration
