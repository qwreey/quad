--!strict
--[[
	Classic saturation/value field: a square tinted by the current pure hue, the white->transparent /
	transparent->black overlay image, and a ring cursor with a color disc inside. The field writes ONLY
	`model.setSV(s, v)` (one atomic write); the hue tint, the cursor position, the ring grey and the disc color
	are Computes of the model.

	Motion: the cursor follows the pointer with a 0.09 s Quad tween; on press the ring grows 16 -> 26 px (0.12 s)
	and the disc shrinks inset -4 -> -6 (0.14 s); release reverses both in 0.12 s.
	Drag math maps the pointer onto the 4 px PADDED area (the original divided by the whole field while the
	cursor is placed inside the padding, so it lagged the pointer by up to 4 px at the edges).
	Instances at rest: field (+UICorner, UIPadding), overlay (+UICorner), ring (+UICorner), disc (+UICorner) = 9.
]]

local q = require("../../Quad")
local Anim = require("./Anim")
local FakeCursor = require("./FakeCursor")
local Interaction = require("../../Interaction")
local Model = require("./Model")
local D = q.Declaration

local PAD = 4
local IMG_OVERLAY = "rbxassetid://6411042282"

export type Props = {
	read Model: Model.Model,
	read Fake: FakeCursor.FakeCursor,
	read LayoutOrder: number?,
}

local function SVField(props: Props)
	local model = props.Model
	local fake = props.Fake
	local fieldRef = q.PreRef(nil :: Frame?)

	local function apply(x: number, y: number)
		local field = fieldRef.Value
		if field == nil then
			return
		end
		local size = field.AbsoluteSize
		local w, h = size.X - 2 * PAD, size.Y - 2 * PAD
		if w <= 0 or h <= 0 then
			return
		end
		local pos = field.AbsolutePosition
		local s = math.clamp((x - pos.X - PAD) / w, 0, 1)
		local y01 = math.clamp((y - pos.Y - PAD) / h, 0, 1)
		model.setSV(s, 1 - y01)
	end

	local drag = Interaction.drag({
		OnBegan = function(x: number, y: number)
			apply(x, y)
		end,
		OnMoved = function(x: number, y: number)
			local field = fieldRef.Value
			if field then
				fake:Update(x, y, field.AbsolutePosition, field.AbsoluteSize)
			end
			apply(x, y)
		end,
		OnEnded = function(x: number, y: number, cancelled: boolean)
			fake:Hide()
			if not cancelled then
				apply(x, y)
			end
		end,
	})
	local dragging = drag.Dragging

	local cursorPos = model.hsv
		:Compute(function(self)
			local c = self:Get()
			return UDim2.fromScale(c.S, 1 - c.V)
		end)
		:Apply(Anim.quad(0.09))
	local ringSize = dragging:Compute(function(self)
		return Anim.tween(if self:Get() then UDim2.fromOffset(26, 26) else UDim2.fromOffset(16, 16), 0.12)
	end)
	local discSize = dragging:Compute(function(self)
		local down = self:Get()
		return Anim.tween(if down then UDim2.new(1, -6, 1, -6) else UDim2.new(1, -4, 1, -4), if down then 0.14 else 0.12)
	end)

	return D.Frame {
		Name = "SaturationBrightnessPicker",
		drag.Hook,
		fieldRef,
		FakeCursor.hideSystemCursor(dragging),
		BackgroundColor3 = model.hueColor,
		BorderSizePixel = 0,
		Active = true,
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		LayoutOrder = props.LayoutOrder or 0,
		UICorner = 10,
		UIPadding = UDim.new(0, PAD),

		D.ImageLabel {
			Name = "Overlay",
			BackgroundTransparency = 1,
			Image = IMG_OVERLAY,
			Position = UDim2.fromOffset(-PAD, -PAD),
			Size = UDim2.new(1, 2 * PAD, 1, 2 * PAD),
			UICorner = 8,
		},
		D.Frame {
			Name = "Cursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = model.ringGray,
			BorderSizePixel = 0,
			Position = cursorPos,
			Size = ringSize,
			UICorner = UDim.new(0.5, 0),

			D.Frame {
				Name = "Disc",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = model.color,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = discSize,
				UICorner = UDim.new(0.5, 0),
			},
		},
	}
end

return SVField
