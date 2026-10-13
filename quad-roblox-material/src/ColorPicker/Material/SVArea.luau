--!strict
--[[
	Saturation / value area, M3 flavor: a rounded rectangle tinted by the current pure hue, a white -> transparent
	horizontal gradient and a transparent -> black vertical gradient laid over it (two `UIGradient` Frames, no
	image asset), and a circular thumb: the CURRENT color inside a ring whose grey follows `cursorRingGray`
	(black near the white corner so it never disappears). The area writes ONLY `model.setSV(s, v)` (one atomic
	write); the tint, the thumb position, ring and fill are Computes of the model.

	Input: `Interaction.drag` (three UserInputService connections only while a drag runs, closed on release /
	focus loss / destroy). Press anywhere jumps the thumb there and continues as a drag; the position maps onto the
	WHOLE area (the thumb center reaches every edge). Keys / D-pad: selecting the area does NOT trap the D-pad
	(a gamepad can walk on past it); ButtonA / Return ENGAGES it — then the outline thickens, all four directions are
	pinned to the area and the arrows move S/V by 2 %, PageUp/PageDown move V by 20 % — and ButtonA / ButtonB / Return /
	Escape release it again. While engaged, B / Escape never dismiss a surrounding dialog (`KeyNav`, `Overlay.holdDismiss`).
	Motion: the thumb never animates its position (it IS the pointer); its size tweens (20 px idle, 24 px focused,
	28 px while dragging, Motion Short2), and the area's outline thickens + takes the focus-ring color on focus.

	Instances at rest: area (+UICorner, UIStroke), 2 gradient overlays (+UICorner, UIGradient each), thumb
	(+UICorner, UIStroke) = 12 including the area.
	M3 deviations: no drop shadow under the thumb (the ring grey carries the contrast); hover has no state layer
	(the pointer is the affordance).
]]

local q = require("../../Quad")
local Tokens = require("../../Tokens")
local Theme = require("../../Theme")
local Interaction = require("../../Interaction")
local Ripple = require("../../Ripple")
local Style = require("../../Button/Style")
local Util = require("../../Util")
local KeyNav = require("../../KeyNav")
local Model = require("./Model")
local D = q.Declaration

local KEY_STEP = 0.02
local PAGE = 10

export type Props = {
	read Model: Model.Model,
	read Theme: Theme.Theme?,
	read Height: number?,
	read OnGestureEnd: (() -> ())?,
	read Disabled: (boolean | q.State<boolean>)?,
	read LayoutOrder: number?,
}

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local toRight = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
local toDown = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })

local function SVArea(props: Props)
	local model = props.Model
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local corner = Tokens.Shape.corner("Medium")
	local disabled = Util.asState(props.Disabled)
	local interactable: q.State<boolean> = Util.interactable(disabled)

	local host: GuiObject? = nil
	local function apply(x: number, y: number)
		local h = host
		-- (Disabled set while a drag is under way: the drag no longer writes)
		if h == nil or disabled:Get() then
			return
		end
		local size = h.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		local pos = h.AbsolutePosition
		local inset = Ripple.Config.PointerInset
		local s = math.clamp((x - inset.X - pos.X) / size.X, 0, 1)
		local y01 = math.clamp((y - inset.Y - pos.Y) / size.Y, 0, 1)
		model.setSV(s, 1 - y01)
	end
	local function endGesture()
		model.remember()
		if props.OnGestureEnd then
			props.OnGestureEnd()
		end
	end

	local drag = Interaction.drag({
		Disabled = disabled,
		LockScroll = true,
		OnBegan = apply,
		OnMoved = function(x: number, y: number)
			apply(x, y)
		end,
		OnEnded = function(x: number, y: number, cancelled: boolean)
			if not cancelled then
				apply(x, y)
				endGesture()
			end
		end,
	})
	local ix = Interaction.new({ Disabled = disabled })

	local engaged = q.Source(false)
	local keys = KeyNav.hook(function(input: InputObject)
		if Util.peekBool(disabled) then
			return
		end
		local kc = input.KeyCode
		if kc == Enum.KeyCode.Left or kc == Enum.KeyCode.DPadLeft then
			model.nudgeSV(-KEY_STEP, 0)
		elseif kc == Enum.KeyCode.Right or kc == Enum.KeyCode.DPadRight then
			model.nudgeSV(KEY_STEP, 0)
		elseif kc == Enum.KeyCode.Up or kc == Enum.KeyCode.DPadUp then
			model.nudgeSV(0, KEY_STEP)
		elseif kc == Enum.KeyCode.Down or kc == Enum.KeyCode.DPadDown then
			model.nudgeSV(0, -KEY_STEP)
		elseif kc == Enum.KeyCode.PageUp then
			model.nudgeSV(0, PAGE * KEY_STEP)
		elseif kc == Enum.KeyCode.PageDown then
			model.nudgeSV(0, -PAGE * KEY_STEP)
		end
	end, endGesture, { Pin = "Engage", Engaged = engaged })
	local hostHook = Util.preHook(function(inst: GuiObject)
		host = inst
	end)

	local thumbPos: q.State<UDim2> = model.hsv:Compute(function(self)
		local c = self:Get()
		return UDim2.fromScale(c.S, 1 - c.V)
	end)
	local thumbSize: q.State<number> = drag.Dragging:Compute(function(self, _prev, focused)
		return if self:Get() then 28 elseif focused:Get() then 24 else 20
	end, ix.Focused)
	local thumbPx: q.State<UDim2> = thumbSize:Compute(function(self)
		local n = self:Get()
		return UDim2.fromOffset(n, n)
	end)
	local ringColor: q.State<Color3> = model.ringGray
	local outline = Style.choose(ix.Focused, R.Secondary, R.OutlineVariant):Apply(Style.animation())
	local outlineThickness = ix.Focused
		:Compute(function(self, _prev, eng)
			return if eng:Get() then 5 elseif self:Get() then 3 else 1
		end, engaged)
		:Apply(Style.animation())

	return D.Frame {
		Name = "SVArea",
		LayoutOrder = props.LayoutOrder or 0,
		drag.Hook,
		ix.Hook,
		keys,
		hostHook,
		Size = UDim2.new(1, 0, 0, props.Height or 160),
		BackgroundColor3 = model.hueColor,
		BorderSizePixel = 0,
		Active = true,
		Selectable = interactable,
		UICorner = corner,
		D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = outline,
			Thickness = outlineThickness,
		},
		D.Frame {
			Name = "WhiteOverlay",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = WHITE,
			BorderSizePixel = 0,
			UICorner = corner,
			D.UIGradient { Transparency = toRight },
		},
		D.Frame {
			Name = "BlackOverlay",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = BLACK,
			BorderSizePixel = 0,
			UICorner = corner,
			D.UIGradient { Transparency = toDown, Rotation = 90 },
		},
		D.Frame {
			Name = "Thumb",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = thumbPos,
			Size = thumbPx:Apply(q.Animate(Tokens.Motion.options("Short2", "Standard"))),
			BackgroundColor3 = model.color,
			BorderSizePixel = 0,
			UICorner = Tokens.Shape.corner("Full"),
			D.UIStroke {
				Name = "Ring",
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 3,
				Color = ringColor,
			},
		},
	}
end

return SVArea
