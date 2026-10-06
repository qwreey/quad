--!strict
--[[
	Classic hue slider: a 14 px rainbow pill with a 20 px handle, and the "preview bubble" that pops above the
	handle while it is dragged. The slider writes ONLY `model.setHue`; the handle position, the handle fill, the
	bubble color are Computes of the model.

	Motion (original timings): handle follows the hue with a 0.12 s Quad tween; on press the bubble's UIScale
	0 -> 1 in 0.36 s Exponential (Visible flips on at once) and the handle fill fades out in 0.18 s; on release
	the bubble shrinks in 0.28 s and is hidden only when that tween COMPLETES naturally (a new press cancels
	it, exactly like the original's `Completed` guard), the fill fades back in 0.42 s.

	Instances at rest: slider (+UICorner, UIPadding, UIGradient), shadow, handle (+UICorner), fill (+UICorner),
	bubble holder (+UIScale, shadow, bubble image, color disc (+UICorner)) = 15. The original used 11 + a PreviewShadow + fake cursor
	(inside the slider); here the fake cursor is shared (FakeCursor.luau) and lives in the window.
	Drag math maps the pointer onto the PADDED track (the original divided by the full width, so the handle
	drifted up to 5 px from the pointer near the ends).
]]

local q = require("../../Quad")
local Anim = require("./Anim")
local FakeCursor = require("./FakeCursor")
local Interaction = require("../../Interaction")
local Model = require("./Model")
local D = q.Declaration

local PAD = 5
local IMG_HANDLE_SHADOW = "rbxassetid://2584395459"
local IMG_BUBBLE = "rbxassetid://11729301118"
local IMG_BUBBLE_SHADOW = "rbxassetid://11729416602"

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
	ColorSequenceKeypoint.new(1 / 6, Color3.new(1, 1, 0)),
	ColorSequenceKeypoint.new(2 / 6, Color3.new(0, 1, 0)),
	ColorSequenceKeypoint.new(3 / 6, Color3.new(0, 1, 1)),
	ColorSequenceKeypoint.new(4 / 6, Color3.new(0, 0, 1)),
	ColorSequenceKeypoint.new(5 / 6, Color3.new(1, 0, 1)),
	ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0)),
})

export type Props = {
	read Model: Model.Model,
	read Fake: FakeCursor.FakeCursor,
	read LayoutOrder: number?,
}

local function HueSlider(props: Props)
	local model = props.Model
	local fake = props.Fake
	local sliderRef = q.PreRef(nil :: Frame?)

	local function ratio(x: number): number
		local slider = sliderRef.Value
		if slider == nil then
			return 0
		end
		local width = slider.AbsoluteSize.X - 2 * PAD
		if width <= 0 then
			return 0
		end
		return math.clamp((x - slider.AbsolutePosition.X - PAD) / width, 0, 1)
	end

	local bubbleVisible = q.Source(false)
	local drag = Interaction.drag({
		OnBegan = function(x: number, _y: number)
			bubbleVisible:Set(true)
			model.setHue(ratio(x))
		end,
		OnMoved = function(x: number, y: number)
			local slider = sliderRef.Value
			if slider then
				fake:Update(x, y, slider.AbsolutePosition, slider.AbsoluteSize)
			end
			model.setHue(ratio(x))
		end,
		OnEnded = function(x: number, _y: number, cancelled: boolean)
			fake:Hide()
			if not cancelled then
				model.setHue(ratio(x)) -- the release position counts (the original did one last update)
			end
		end,
	})
	local dragging = drag.Dragging

	local handlePos = model.hue
		:Compute(function(self)
			return UDim2.fromScale(self:Get(), 0.5)
		end)
		:Apply(Anim.quad(0.12))
	local shadowPos = model.hue
		:Compute(function(self)
			return UDim2.new(self:Get(), 0, 0.5, 1)
		end)
		:Apply(Anim.quad(0.12))
	local fillTransparency = dragging:Compute(function(self)
		local down = self:Get()
		return Anim.tween(if down then 1 else 0, if down then 0.18 else 0.42)
	end)
	local bubbleScale = dragging:Compute(function(self)
		local down = self:Get()
		return Anim.tween(if down then 1 else 0, if down then 0.36 else 0.28, if down then Enum.EasingStyle.Exponential else nil, function()
			if not dragging:Get() then
				bubbleVisible:SetIfChanged(false)
			end
		end)
	end)

	return D.Frame {
		Name = "HuePicker",
		drag.Hook,
		sliderRef,
		FakeCursor.hideSystemCursor(dragging),
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Active = true,
		LayoutOrder = props.LayoutOrder or 0,
		UICorner = UDim.new(0.5, 0),
		D.UIPadding { PaddingLeft = UDim.new(0, PAD), PaddingRight = UDim.new(0, PAD) },
		D.UIGradient { Color = RAINBOW },

		D.ImageLabel {
			Name = "HandleShadow",
			Image = IMG_HANDLE_SHADOW,
			ImageTransparency = 0.3,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = shadowPos,
			Size = UDim2.fromOffset(24, 23),
			ZIndex = 1,
		},
		D.Frame {
			Name = "Handle",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = handlePos,
			Size = UDim2.fromOffset(20, 20),
			UICorner = UDim.new(0.5, 0),
			-- above its shadow sibling explicitly (equal ZIndex leaves the sibling order to the engine) — the preview
			-- bubble is the handle's descendant, so the handle shadow must never paint over it either
			ZIndex = 2,

			D.Frame {
				Name = "Fill",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = model.hueColor,
				BackgroundTransparency = fillTransparency,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				UICorner = UDim.new(0.5, 0),
			},
			-- the bubble is a transparent holder (Visible + UIScale) with the shadow and the bubble image as SIBLINGS: under
			-- ZIndexBehavior Sibling a child always draws ABOVE its parent, so the shadow as a child of the bubble image (the
			-- first port) painted over the bubble; here the shadow is the earlier sibling with the lower ZIndex
			D.Frame {
				Name = "PreviewBubble",
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromOffset(32, 68),
				Visible = bubbleVisible,
				UIScale = bubbleScale,

				D.ImageLabel {
					Name = "BubbleShadow",
					Image = IMG_BUBBLE_SHADOW,
					ImageColor3 = Color3.fromRGB(95, 95, 95),
					ImageTransparency = 0.7,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1, 14, 1, 14),
					ZIndex = 1,
				},
				D.ImageLabel {
					Name = "BubbleImage",
					Image = IMG_BUBBLE,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,

					D.Frame {
						Name = "BubbleColor",
						BackgroundColor3 = model.hueColor,
						BorderSizePixel = 0,
						Position = UDim2.fromOffset(5, 5),
						Size = UDim2.fromOffset(22, 22),
						UICorner = UDim.new(0.5, 0),
					},
				},
			},
		},
	}
end

return HueSlider
