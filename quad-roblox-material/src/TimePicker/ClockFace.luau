--!strict
--[[
	ClockFace: the M3 clock dial (TimePicker.kt = androidx/androidx@40ff481 compose/material3/material3/src/commonMain/
	kotlin/androidx/compose/material3/TimePicker.kt — `ClockFace` 3270-3414, `drawSelector` 3416-3480, `ClockText`
	3482-3653, `ClockDialNode` 3159-3268, `AnalogTimePickerState` 1721-1888).

	GEOMETRY (TimePickerTokens.kt; constants 4038-4058): a 256 x 256 circle in surfaceContainerHighest (ClockDialColor,
	ClockDialShape CornerFull); 12 numbers on the 101 px ring (outer), in 24 h hour mode 12 more on the 69 px ring (inner);
	each number a 48 x 48 cell (MinimumInteractiveSize) in BodyLarge onSurface. The SELECTOR: a 48 px primary circle
	(ClockDialSelectorHandleContainerSize) on the ring, a 2 px primary line from the center to its edge
	(ClockDialSelectorTrackContainerWidth), an 8 px primary dot in the center (ClockDialSelectorCenterContainerSize). Where
	a number lies under the circle it is drawn in onPrimary (ClockDialSelectedLabelTextColor) — Compose does it with
	blend modes (Clear / Xor / DstOver); here the circle is a `CanvasGroup` (it clips its children to its UICorner, as the
	ripple does) holding a COPY of both number faces in onPrimary, moved so the copy lies exactly over the dial's own
	numbers: the part of a number under the circle shows in onPrimary, exactly, also for a hand between two numbers.

	THE HAND: one dial-sized `Hand` frame whose `Rotation` is the selector angle (degrees clockwise from 12 o'clock);
	the line and the circle are its children, laid out pointing up, so the engine rotates them around the dial center.
	Inside the circle the number copy (`Mirror`) has `Rotation = -angle` around the same center, so it does not turn.
	The angle is kept unwrapped: every new target takes the shortest way round from the current one (Compose
	`endValueForAnimation` 1782-1795). Motion: Compose animates the angle with the DefaultSpatial spring (damping 0.9,
	stiffness 700 — StandardMotionTokens) and cross-fades the hour / minute numbers with DefaultEffects (1.0 / 1600);
	the kit maps springs to Motion Short4 / Standard (as Button/Split.luau does) — angle, ring length and the fade.

	INPUT (ClockDialNode): a tap snaps (hours to the hour, minutes to a multiple of five — onTap 1910-1935), animates
	the hand there and, in hour mode, switches to minutes 100 ms later (autoSwitchToMinute; Compose turns it off for a
	keyboard or an accessibility service — the kit has neither notion, it is always on for a pointer). A drag (past 8 px)
	makes the hand follow the pointer exactly while the value takes the nearest hour / minute (rotateTo), in 24 h hour
	mode the pointer's distance picks the ring (closer than 74 px of 256 = inner, moveSelector 1899-1908); releasing
	switches to minutes and animates the hand to the value (onGestureEnd). A write from OUTSIDE (the Value Source, the
	text input of the modal) snaps the hand (AnalogTimePickerState's `hourInput` setter makes a new Animatable).
	A change of hour / minute mode animates the hand to the other value (ClockDialNode.updateNode -> animateToCurrent).

	KEYS (KeyNav, Pin "Horizontal"): the dial is ONE selectable; Right / Left step to the next / previous number of the
	focus ring (Compose's ClockText focus order: Down / Right = next, Up / Left = previous, 24 h outer ring continues
	into the inner one — Clock.stepDial) and select it at once; Up / Down are left to the engine so a gamepad can walk
	out of the dial (Compose loops focus inside and leaves with Tab). Focus: a 3 px secondary ring around the dial while
	it holds the selection.

	Instances (12 h): Dial + UICorner + UIStroke (focus ring) + Hours face (1 + 12) + Minutes face (1 + 12) + Hand +
	Line + Handle (CanvasGroup + UICorner) + Mirror (1 + Hours 13 + Minutes 13) + Dot (+ UICorner) = 62; 24 h + 24
	(the inner ring and its copy) = 86. Nothing is created or destroyed afterwards (the numbers are persistent; a
	change of mode only fades them).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Text = require("../Text")
local Util = require("../Util")
local Interaction = require("../Interaction")
local Interactive = require("../Interactive")
local KeyNav = require("../KeyNav")
local Ripple = require("../Ripple")
local Clock = require("./Clock")
local Model = require("./Model")
local CanvasGroup = q.Elem "CanvasGroup"
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local UIStroke = q.Elem "UIStroke"

type State<T> = q.State<T>
type Time = Clock.Time
type Selection = Clock.Selection

export type Options = {
	Theme: Theme.Theme,
	Model: Model.Model,
	Position: UDim2?,
}

local SIZE = 256 -- ClockDialContainerSize
local CENTER = SIZE / 2
local HANDLE = 48 -- ClockDialSelectorHandleContainerSize
local CELL = 48 -- MinimumInteractiveSize
local TRACK = 2 -- ClockDialSelectorTrackContainerWidth
local DOT = 8 -- ClockDialSelectorCenterContainerSize
local OUTER_R = SIZE * Clock.OUTER_RATIO -- 101
local INNER_R = SIZE * Clock.INNER_RATIO -- 69
local SLOP = 8 -- the drag threshold (Android's touch slop, 8 dp)
local AUTO_SWITCH_DELAY = 0.1 -- onTap: delay(100) before the hour -> minute switch

local labelStyle = Text.Label("BodyLarge")
local motion = Tokens.Motion.options("Short4", "Standard")

type Hand = { Rot: number, Len: number, Animate: boolean }

local function tween<T>(value: T, animate: boolean): q.Tween<T>
	return q.Tween({ Value = value, Time = if animate then motion.Time else 0, Style = motion.Style, Direction = motion.Direction })
end

-- one ring of numbers: 48 x 48 cells centered on the circle of `radius`
local function ring(values: { number }, radius: number, color: Color3 | Theme.Animated, transparency: Theme.Animated): { Instance }
	local out: { Instance } = {}
	for i, v in values do
		local x, y = Clock.labelOffset(i - 1, #values, radius, SIZE, CELL)
		table.insert(
			out,
			TextLabel {
				Name = "Number",
				labelStyle,
				Size = UDim2.fromOffset(CELL, CELL),
				Position = UDim2.fromOffset(x, y),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = Clock.labelText(v),
				TextColor3 = color,
				TextTransparency = transparency,
			}
		)
	end
	return out
end

local function face(name: string, kind: Selection, is24: boolean, color: Color3 | Theme.Animated, transparency: Theme.Animated): Frame
	local outer, inner = Clock.faceValues(kind, is24)
	local cells = ring(outer, OUTER_R, color, transparency)
	if inner ~= nil then
		for _, c in ring(inner, INNER_R, color, transparency) do
			table.insert(cells, c)
		end
	end
	return Frame {
		Name = name,
		Size = UDim2.fromOffset(SIZE, SIZE),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		table.unpack(cells),
	}
end

local function new(o: Options): Frame
	local theme = o.Theme
	local model = o.Model
	local is24 = model.Is24Hour

	local function target(animate: boolean, from: number): Hand
		local t = model.Value:Get()
		local sel = model.Selection:Get()
		local deg = Clock.handDegrees(sel, t)
		return {
			Rot = Clock.shortestDegrees(from, deg),
			Len = if Clock.onInnerRing(sel, t, is24) then INNER_R else OUTER_R,
			Animate = animate,
		}
	end
	local hand = q.Source<<Hand>>(target(false, 0))

	-- user flows set `animateNext` around their writes; anything else (an outside write) snaps
	local animateNext = false
	local dragging = false
	local alive = true
	local function syncHand(animate: boolean)
		hand:Set(target(animate, hand:Get().Rot))
	end
	local follow = q.Effect(function()
		model.Value:Get()
		model.Selection:Get()
		if not dragging then
			syncHand(animateNext)
		end
	end, model.Value, model.Selection)
	local function user(fn: () -> ())
		animateNext = true
		fn()
		animateNext = false
	end

	local hourT: State<number> = model.Selection:Compute(function(self)
		return if self:Get() == "Hour" then 0 else 1
	end)
	local minuteT: State<number> = model.Selection:Compute(function(self)
		return if self:Get() == "Minute" then 0 else 1
	end)
	local fade = q.Animate(motion)
	local hourFade, minuteFade = hourT:Apply(fade), minuteT:Apply(fade)

	local handRotation: State<q.Tween<number>> = hand:Compute(function(self)
		local h = self:Get()
		return tween(h.Rot, h.Animate)
	end)
	local mirrorRotation: State<q.Tween<number>> = hand:Compute(function(self)
		local h = self:Get()
		return tween(-h.Rot, h.Animate)
	end)
	local handlePosition: State<q.Tween<UDim2>> = hand:Compute(function(self)
		local h = self:Get()
		return tween(UDim2.fromOffset(CENTER - HANDLE / 2, CENTER - h.Len - HANDLE / 2), h.Animate)
	end)
	local mirrorPosition: State<q.Tween<UDim2>> = hand:Compute(function(self)
		local h = self:Get()
		return tween(UDim2.fromOffset(HANDLE / 2 - CENTER, h.Len + HANDLE / 2 - CENTER), h.Animate)
	end)
	local linePosition: State<q.Tween<UDim2>> = hand:Compute(function(self)
		local h = self:Get()
		return tween(UDim2.fromOffset(CENTER - TRACK / 2, CENTER - (h.Len - HANDLE / 2)), h.Animate)
	end)
	local lineSize: State<q.Tween<UDim2>> = hand:Compute(function(self)
		local h = self:Get()
		return tween(UDim2.fromOffset(TRACK, h.Len - HANDLE / 2), h.Animate)
	end)

	-- pointer -> dial geometry (screen pixels; the dial may be scaled by an ancestor UIScale — distances are compared
	-- against the scaled radius, angles are scale-free)
	local host: GuiObject? = nil
	local function geometry(x: number, y: number): (number, boolean)
		local h = host :: GuiObject
		local inset = Ripple.Config.PointerInset
		local size = h.AbsoluteSize
		local cx = h.AbsolutePosition.X + size.X / 2
		local cy = h.AbsolutePosition.Y + size.Y / 2
		local dx, dy = x - inset.X - cx, y - inset.Y - cy
		local scale = if size.X > 0 then size.X / SIZE else 1
		local inner = math.sqrt(dx * dx + dy * dy) < SIZE * Clock.MAX_DISTANCE_RATIO * scale
		return Clock.dialAngle(dx, dy), inner
	end

	-- the value a pointer angle means now (24 h hour mode: the ring by distance; 12 h: the current period)
	local function pick(phi: number, inner: boolean, snapFive: boolean): Time
		local t = model.Value:Get()
		if model.Selection:Get() == "Minute" then
			return Clock.time(t.Hour, if snapFive then Clock.nearestFiveMinutes(phi) else Clock.nearestMinute(phi))
		end
		local idx = Clock.nearestHourIndex(phi)
		return Clock.time(Clock.hourAt(idx, is24, inner, t.Hour >= 12), t.Minute)
	end

	local function switchToMinute()
		if alive and model.Selection:Get() == "Hour" then
			user(function()
				model.Selection:Set("Minute")
			end)
		end
	end

	local pressX, pressY = 0, 0
	local moved = false
	local drag = Interaction.drag({
		OnBegan = function(x: number, y: number)
			pressX, pressY = x, y
			moved = false
		end,
		OnMoved = function(x: number, y: number)
			if host == nil then
				return
			end
			if not moved then
				local dx, dy = x - pressX, y - pressY
				if dx * dx + dy * dy <= SLOP * SLOP then
					return
				end
				moved = true
				dragging = true
			end
			local phi, inner = geometry(x, y)
			model:SetTime(pick(phi, inner, false))
			-- the hand follows the pointer itself (not the rounded value); the ring follows the value
			local t = model.Value:Get()
			local cur = hand:Get()
			hand:Set({
				Rot = Clock.shortestDegrees(cur.Rot, math.deg(phi)),
				Len = if Clock.onInnerRing(model.Selection:Get(), t, is24) then INNER_R else OUTER_R,
				Animate = false,
			})
		end,
		OnEnded = function(x: number, y: number, cancelled: boolean)
			if host == nil then
				return
			end
			if moved then
				moved = false
				dragging = false
				-- onDragEnd: switch to minutes, then animate the hand onto the value
				user(function()
					if model.Selection:Get() == "Hour" then
						model.Selection:Set("Minute")
					end
					syncHand(true)
				end)
				return
			end
			if cancelled then
				return
			end
			local phi, inner = geometry(x, y)
			local wasHour = model.Selection:Get() == "Hour"
			user(function()
				model:SetTime(pick(phi, inner, true))
				syncHand(true)
			end)
			if wasHour then
				task.delay(AUTO_SWITCH_DELAY, switchToMinute)
			end
		end,
	})

	local ix = Interaction.new({
		OnHost = function(inst: GuiObject)
			inst.SelectionImageObject = Interactive.noSelectionImage()
		end,
	})
	local keys = KeyNav.hook(function(input: InputObject)
		local kc = input.KeyCode
		local dir = 0
		if kc == Enum.KeyCode.Right or kc == Enum.KeyCode.DPadRight then
			dir = 1
		elseif kc == Enum.KeyCode.Left or kc == Enum.KeyCode.DPadLeft then
			dir = -1
		end
		if dir ~= 0 then
			-- Compose's keyboard click on a number uses SnapSpec: the hand jumps
			model:SetTime(Clock.stepDial(model.Value:Get(), model.Selection:Get(), is24, dir))
		end
	end, nil, { Pin = "Horizontal" })

	local primary = theme.Color.Primary
	local onPrimary = theme.Color.OnPrimary
	local onSurface = theme.Color.OnSurface

	return Frame {
		Name = "ClockFace",
		Size = UDim2.fromOffset(SIZE, SIZE),
		Position = o.Position or UDim2.new(),
		BackgroundColor3 = theme.Color.SurfaceContainerHighest,
		BorderSizePixel = 0,
		Selectable = true,
		UICorner = Tokens.Shape.corner("Full"),
		follow,
		drag.Hook,
		ix.Hook,
		keys,
		Util.preHook(function(inst: GuiObject)
			host = inst
			inst.Destroying:Connect(function()
				alive = false
			end)
		end),
		UIStroke {
			Name = "FocusRing",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 3,
			Color = theme.Color.Secondary,
			Enabled = ix.Focused,
		},
		face("Hours", "Hour", is24, onSurface, hourFade),
		face("Minutes", "Minute", is24, onSurface, minuteFade),
		Frame {
			Name = "Hand",
			Size = UDim2.fromOffset(SIZE, SIZE),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Rotation = handRotation,
			Frame {
				Name = "Line",
				Position = linePosition,
				Size = lineSize,
				BackgroundColor3 = primary,
				BorderSizePixel = 0,
			},
			CanvasGroup {
				Name = "Handle",
				Position = handlePosition,
				Size = UDim2.fromOffset(HANDLE, HANDLE),
				BackgroundColor3 = primary,
				BorderSizePixel = 0,
				UICorner = Tokens.Shape.corner("Full"),
				Frame {
					Name = "Mirror",
					Position = mirrorPosition,
					Size = UDim2.fromOffset(SIZE, SIZE),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Rotation = mirrorRotation,
					face("Hours", "Hour", is24, onPrimary, hourFade),
					face("Minutes", "Minute", is24, onPrimary, minuteFade),
				},
			},
			Frame {
				Name = "Dot",
				Position = UDim2.fromOffset(CENTER - DOT / 2, CENTER - DOT / 2),
				Size = UDim2.fromOffset(DOT, DOT),
				BackgroundColor3 = primary,
				BorderSizePixel = 0,
				UICorner = Tokens.Shape.corner("Full"),
			},
		},
	}
end

return { new = new, Size = SIZE }
