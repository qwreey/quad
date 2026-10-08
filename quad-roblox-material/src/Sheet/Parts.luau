--!strict
--[[
	Sheet parts shared by the bottom sheets, side sheets and navigation drawers: the motion table, the corner square-off
	patch, the drag handle and the in-tree scrim.

	MOTION — Compose drives these surfaces with motion-scheme SPRINGS (BottomSheet.kt 135-137, BottomSheetScaffold.kt
	257-259, NavigationDrawer.kt 352-355 / 501-502: show / open = DefaultSpatial, hide / close = FastEffects, a released
	drag settles with DefaultSpatial; StandardMotionTokens.kt 20-27: DefaultSpatial damping 0.9 / stiffness 700, FastEffects
	1.0 / 3800). The kit tweens instead (Tokens/Motion.luau); each spring maps to the token duration closest to its 1 %
	settling time — DefaultSpatial (decay rate 0.9 x sqrt(700) = 23.8 /s -> ln 100 / 23.8 = 0.19 s) = Short4 0.2 s,
	FastEffects (critically damped, sqrt(3800) = 61.6 rad/s -> 0.11 s) = Short2 0.1 s — with the Standard easing.
	  Sheet     Show 0.2 · Hide 0.1 · Settle 0.2         (bottom sheets)
	  Drawer    Show 0.2 · Hide 0.1 · Settle 0.2         (ModalNavigationDrawer)
	  Dismissible drawer settle 0.256 Standard          (DismissibleNavigationDrawer does not set a drag motion: DrawerState's
	                                                     AnchoredDraggableDefaultAnimationSpec, TweenSpec 256 ms, NavigationDrawer.kt 1354)
	  Side      every kind 0.275 Emphasized              (MDC m3_side_sheet_enter_from_right / exit_to_right: 275 ms,
	                                                     motionEasingEmphasizedInterpolator — material-components-android@60ff094
	                                                     lib/java/com/google/android/material/sidesheet/res/anim/)
	  Scrim     Short4 Linear                            the fade of the in-tree scrims (the kit Overlay scrim's; Compose fades the
	                                                     modal sheet's scrim with DefaultEffects 1.0 / 1600 ~ 0.17 s)

	Parts.patch(side, radius, color) -> Frame   a UICorner has ONE radius, but a docked sheet is rounded on its open side
	    only (the bottom sheet's top corners — Compose CornerExtraLargeTop; the modal drawer's end corners — CornerLargeEnd;
	    the modal side sheet's inner corners). The surface keeps the full radius and this opaque square of the same color
	    covers the corners on the docked side: `radius` deep along that edge, the full length of it. Same color, so the two
	    read as one surface (the kit's earlier two-piece trick — Slider/Track.luau cap/body, Button/Split.luau faces — needs
	    clips because those surfaces can be translucent; a sheet surface is always opaque). It is drawn below the content
	    (the content holders carry ZIndex 2).
	Parts.dragHandle(opts) -> TextButton   Compose BottomSheetDefaults.DragHandle (SheetDefaults.kt 571-589): a 32 x 4 pill
	    (SheetBottomTokens DockedDragHandleWidth / Height, shape extraLarge = full on 4 px), onSurfaceVariant, 22 px above and
	    below (DragHandleVerticalPadding, 788-789) — the clickable is the padded 32 x 48 box (the handle's `clickable` comes
	    before the padding in the modifier chain), so the state layer / ripple fill that box. Centered at the top.
	    RIPPLE — canon has one: the sheets wrap the handle in `Modifier.clickable { ... }` (BottomSheet.kt 364-372,
	    BottomSheetScaffold.kt 392-405), the overload without an `indication` argument, which takes `LocalIndication`
	    (foundation Clickable.kt 199-210, `useLocalIndication = true`), and MaterialTheme provides the ripple there
	    (MaterialTheme.kt 109) — a bounded ripple and hover / focus state layer on the rectangular 32 x 48 box. So the kit's
	    `Interactive` (corner 0) is the canon look, not a stray effect.
	    DRAG vs CLICK — the sheet's `anchoredDraggable` sits on the Surface, the handle's `clickable` on a child: once the drag
	    passes the touch slop it consumes the pointer and the clickable cancels its press (the ripple fades, no click on
	    release). `opts.Dragging` (the slide's Dragging State) does that here: when it turns true the handle's press is
	    cancelled (`fx.CancelPress`). And a pointer click counts only for a press that BEGAN on the handle and was not
	    cancelled: the engine fires `Activated` on mouse-up over a GuiButton that still holds an unfinished earlier press —
	    pressed there, released elsewhere — even when the current press began somewhere else (Studio 2026-10-08, Util.luau
	    "INPUT RULE" and the QA file), so a drag released off the handle would otherwise leave a click armed for a later
	    unrelated release over it. Gamepad / keyboard activation is not filtered.
	Parts.scrim(opts) -> TextButton   a full-size Scrim (Scrim.kt 50-79: the scrim color, a tap dismisses), not Selectable.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local MotionTokens = require("../Tokens/Motion")
local Theme = require("../Theme")
local Util = require("../Util")
local Interactive = require("../Interactive")
local D = q.Declaration

export type Motion = { Time: number, Style: Enum.EasingStyle, Direction: Enum.EasingDirection }

local function motion(duration: MotionTokens.DurationName?, easing: MotionTokens.EasingName, time: number?): Motion
	local o = Tokens.Motion.options(duration or "Short4", easing)
	return { Time = time or o.Time, Style = o.Style, Direction = o.Direction }
end

export type MotionSet = { Show: Motion, Hide: Motion, Settle: Motion }

local Motion = {
	Sheet = { Show = motion("Short4", "Standard"), Hide = motion("Short2", "Standard"), Settle = motion("Short4", "Standard") } :: MotionSet,
	Drawer = { Show = motion("Short4", "Standard"), Hide = motion("Short2", "Standard"), Settle = motion("Short4", "Standard") } :: MotionSet,
	DismissibleSettle = motion(nil, "Standard", 0.256),
	Side = motion(nil, "Emphasized", 0.275),
	Scrim = motion("Short4", "Linear"),
}

-- the motion of one request kind (Anchored.Kind: "Show" | "Hide" | "Settle")
local function pick(set: MotionSet, kind: string): Motion
	if kind == "Show" then
		return set.Show
	elseif kind == "Hide" then
		return set.Hide
	end
	return set.Settle
end

export type Side = "Bottom" | "Left" | "Right"

local function patch(side: Side, radius: number, color: any): Frame
	local size: UDim2
	local position: UDim2
	local anchor: Vector2
	if side == "Bottom" then
		size, position, anchor = UDim2.new(1, 0, 0, radius), UDim2.fromScale(0, 1), Vector2.new(0, 1)
	elseif side == "Left" then
		size, position, anchor = UDim2.new(0, radius, 1, 0), UDim2.fromScale(0, 0), Vector2.new(0, 0)
	else
		size, position, anchor = UDim2.new(0, radius, 1, 0), UDim2.fromScale(1, 0), Vector2.new(1, 0)
	end
	return D.Frame {
		Name = "CornerPatch",
		Size = size,
		Position = position,
		AnchorPoint = anchor,
		BorderSizePixel = 0,
		BackgroundColor3 = color,
	}
end

export type HandleOptions = {
	Theme: Theme.Theme,
	OnClick: () -> (),
	-- the slide's Dragging State: the handle's press is cancelled when a drag takes over
	Dragging: q.State<boolean>?,
	Hooks: { any }?,
}

local HANDLE_WIDTH = 32 -- SheetBottomTokens.DockedDragHandleWidth
local HANDLE_HEIGHT = 4 -- SheetBottomTokens.DockedDragHandleHeight
local HANDLE_PADDING = 22 -- DragHandleVerticalPadding
local HANDLE_BOX = HANDLE_HEIGHT + 2 * HANDLE_PADDING -- 48

local function isPointer(input: InputObject?): boolean
	if input == nil then
		return false
	end
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
end

local function dragHandle(o: HandleOptions): TextButton
	local theme = o.Theme
	-- a press began on the handle and has not been cancelled (pointer leaving, a drag taking over)
	local armed = false
	local fx = Interactive.new({
		Theme = theme,
		OnColor = theme.Color.OnSurface,
		Corner = UDim.new(0, 0),
		OnPress = function()
			armed = true
		end,
		OnRelease = function(cancelled: boolean)
			if cancelled then
				armed = false
			end
		end,
	})
	local dragging = o.Dragging
	local cancelOnDrag: any = q.None
	if dragging ~= nil then
		cancelOnDrag = q.Effect(function()
			if dragging:Get() then
				fx.CancelPress()
			end
			return nil :: any
		end, dragging)
	end
	return D.TextButton {
		Name = "DragHandle",
		Size = UDim2.fromOffset(HANDLE_WIDTH, HANDLE_BOX),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 2,
		fx.Hook,
		cancelOnDrag,
		Activated = function(input: InputObject?)
			local ok = armed or not isPointer(input)
			armed = false
			if ok then
				o.OnClick()
			end
		end,
		fx.Layer,
		D.Frame {
			Name = "Bar",
			Size = UDim2.fromOffset(HANDLE_WIDTH, HANDLE_HEIGHT),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.OnSurfaceVariant,
			UICorner = Tokens.Shape.corner("Full"),
		},
		table.unpack(Util.hooks(o.Hooks)),
	}
end

export type ScrimOptions = {
	Theme: Theme.Theme,
	Transparency: any,
	Visible: (boolean | q.State<boolean>)?,
	ZIndex: number?,
	OnClick: () -> (),
	Hooks: { any }?,
}

local function scrim(o: ScrimOptions): TextButton
	return D.TextButton {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Selectable = false,
		BackgroundColor3 = o.Theme.Color.Scrim,
		BackgroundTransparency = o.Transparency,
		Visible = Util.visible(o.Visible),
		ZIndex = o.ZIndex or 1,
		Activated = function()
			o.OnClick()
		end,
		table.unpack(Util.hooks(o.Hooks)),
	}
end

return {
	Motion = Motion,
	pick = pick,
	patch = patch,
	dragHandle = dragHandle,
	scrim = scrim,
	HandleBox = HANDLE_BOX,
	ScrimOpacity = 0.32, -- ScrimTokens.ContainerOpacity
}
