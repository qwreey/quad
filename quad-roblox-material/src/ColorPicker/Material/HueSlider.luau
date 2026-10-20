--!strict
--[[
	Hue slider, styled like the kit's Slider: a 16 px rainbow pill rail (one `UIGradient`), a 20 px circular handle
	with a white ring, filled with the CURRENT PURE HUE, inside a 40 px halo that carries the M3 state layer
	(hover / focus / dragged — `Interactive`, no ripple). The slider writes ONLY `model.setHue(h)`; the handle
	position and fill are Computes of the model, so they cannot disagree with the value.

	Input: `Interaction.drag` (press anywhere on the host jumps there and continues as a drag; three
	UserInputService connections only while dragging). The pointer maps onto the rail minus the handle radius on
	both sides (the handle CENTER travels from the first to the last rail pixel), read at event time from
	`AbsolutePosition/AbsoluteSize`. Keys / D-pad while the host holds selection: Left -1 %, Right +1 %,
	PageDown/PageUp +-10 %, Home/End = the ends (`KeyNav`). Only Left/Right are pinned to the host, so Up/Down still move the
	gamepad selection on to the neighbouring control (no D-pad trap) — they are not mapped to the hue.

	Instances at rest: host, rail (+UICorner, UIGradient), halo, state layer (3), handle (+UICorner, UIStroke) = 11.
	M3 deviations: no value bubble (the SV area and the preview already show the hue); hover lights the halo
	anywhere over the host, like Slider.
]]

local q = require("../../Quad")
local Tokens = require("../../Tokens")
local Theme = require("../../Theme")
local Util = require("../../Util")
local Interaction = require("../../Interaction")
local Interactive = require("../../Interactive")
local Ripple = require("../../Ripple")
local KeyNav = require("../../KeyNav")
local Model = require("./Model")
local Frame = q.Elem "Frame"
local UIGradient = q.Elem "UIGradient"
local UIStroke = q.Elem "UIStroke"

local INSET = 10 -- handle radius
local STEP = 0.01
local PAGE = 10

export type Props = {
	read Model: Model.Model,
	read Theme: Theme.Theme?,
	read OnGestureEnd: (() -> ())?,
	read Disabled: (boolean | q.State<boolean>)?,
	read LayoutOrder: number?,
}

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
	ColorSequenceKeypoint.new(1 / 6, Color3.new(1, 1, 0)),
	ColorSequenceKeypoint.new(2 / 6, Color3.new(0, 1, 0)),
	ColorSequenceKeypoint.new(3 / 6, Color3.new(0, 1, 1)),
	ColorSequenceKeypoint.new(4 / 6, Color3.new(0, 0, 1)),
	ColorSequenceKeypoint.new(5 / 6, Color3.new(1, 0, 1)),
	ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0)),
})

local function HueSlider(props: Props)
	local model = props.Model
	local theme = Theme.resolve(props.Theme)
	local corner = Tokens.Shape.corner("Full")
	local disabled = Util.asState(props.Disabled)
	local interactable: q.State<boolean> = Util.interactable(disabled)

	local host: GuiObject? = nil
	local function setFromX(x: number)
		local h = host
		-- (Disabled set while a drag is under way: the drag no longer writes)
		if h == nil or disabled:Get() then
			return
		end
		local width = h.AbsoluteSize.X - 2 * INSET
		if width <= 0 then
			return
		end
		local f = (x - Ripple.Config.PointerInset.X - h.AbsolutePosition.X - INSET) / width
		model.setHue(math.clamp(f, 0, 1))
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
		OnBegan = setFromX,
		OnMoved = function(x: number)
			setFromX(x)
		end,
		OnEnded = function(x: number, _y: number, cancelled: boolean)
			if not cancelled then
				setFromX(x)
				endGesture()
			end
		end,
	})
	local fx = Interactive.new({
		Theme = theme,
		Disabled = disabled,
		OnColor = theme.Color.Primary,
		Corner = corner,
		Ripple = false,
		Dragged = drag.Dragging,
	})
	local keys = KeyNav.hook(function(input: InputObject)
		if Util.peekBool(disabled) then
			return
		end
		local kc = input.KeyCode
		local h = model.hsv:Get().H
		if kc == Enum.KeyCode.Left or kc == Enum.KeyCode.DPadLeft then
			model.setHue(h - STEP)
		elseif kc == Enum.KeyCode.Right or kc == Enum.KeyCode.DPadRight then
			model.setHue(h + STEP)
		elseif kc == Enum.KeyCode.PageDown then
			model.setHue(h - PAGE * STEP)
		elseif kc == Enum.KeyCode.PageUp then
			model.setHue(h + PAGE * STEP)
		elseif kc == Enum.KeyCode.Home then
			model.setHue(0)
		elseif kc == Enum.KeyCode.End then
			model.setHue(1)
		end
	end, endGesture)
	local hostHook = Util.preHook(function(inst: GuiObject)
		host = inst
		inst.Destroying:Connect(function()
			host = nil
		end)
	end)

	local haloPos: q.State<UDim2> = model.hue:Compute(function(self)
		return UDim2.fromScale(self:Get(), 0.5)
	end)

	return Frame {
		Name = "HueSlider",
		LayoutOrder = props.LayoutOrder or 0,
		fx.Hook,
		drag.Hook,
		keys,
		hostHook,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
		Selectable = interactable,
		Interactable = interactable,
		Frame {
			Name = "Rail",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, INSET, 0.5, 0),
			Size = UDim2.new(1, -2 * INSET, 0, 16),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			UICorner = corner,
			UIGradient { Color = RAINBOW },
			Frame {
				Name = "Halo",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = haloPos,
				Size = UDim2.fromOffset(40, 40),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				fx.Layer,
				Frame {
					Name = "Handle",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(20, 20),
					BackgroundColor3 = model.hueColor,
					BorderSizePixel = 0,
					UICorner = corner,
					UIStroke {
						Name = "Ring",
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Thickness = 3,
						Color = Color3.new(1, 1, 1),
					},
				},
			},
		},
	}
end

return HueSlider
