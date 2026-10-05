--!strict
--[[
	The "fake mouse cursor" of a drag and the system-cursor toggle that goes with it.

	While a slider/field is dragged the real cursor is hidden (`MouseIconEnabled = false`) so the finger/pointer
	can leave the control without the arrow covering the color. When the pointer is more than 10 px outside the
	control a black arrow image takes its place. The original built one such arrow inside EACH control (copy-
	pasted, 2 x ~45 lines); here one arrow lives in the window and both controls share it.

	  local fake = FakeCursor.new()
	  fake.Element        place it in the WINDOW frame (its parent supplies the origin for the offset math)
	  fake:Update(x, y, areaPos, areaSize)   pointer in screen px, the control's absolute rect
	  fake:Hide()
	  FakeCursor.hideSystemCursor(dragging)  an Effect (array part): system cursor off while `dragging`, restored
	                                         to the value it found when it ends or when the element dies (cleanup `dying`)
]]

local q = require("../../Quad")
local Anim = require("./Anim")
local D = q.Declaration

local UserInputService = game:GetService("UserInputService")

local ARROW = "rbxassetid://4030329127"
local MARGIN = 10 -- px outside the control before the arrow shows

export type FakeCursor = {
	read Element: ImageLabel,
	Update: (self: FakeCursor, x: number, y: number, areaPos: Vector2, areaSize: Vector2) -> (),
	Hide: (self: FakeCursor) -> (),
}

local function new(): FakeCursor
	local pos = q.Source(UDim2.new())
	local shown = q.Source(false)
	local position = pos:Apply(Anim.quad(0.07))
	-- appears slowly (0.64 s), disappears quickly (0.18 s)
	local transparency = shown:Compute(function(self)
		local on = self:Get()
		return Anim.tween(if on then 0 else 1, if on then 0.64 else 0.18)
	end)
	local element = D.ImageLabel {
		Name = "FakeCursor",
		Image = ARROW,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = transparency,
		Size = UDim2.fromOffset(16, 16),
		Position = position,
		ZIndex = 100,
	}
	local self: FakeCursor
	self = {
		Element = element,
		Update = function(_: FakeCursor, x: number, y: number, areaPos: Vector2, areaSize: Vector2)
			if not UserInputService.MouseEnabled then
				shown:SetIfChanged(false)
				return
			end
			local outside = x < areaPos.X - MARGIN
				or x > areaPos.X + areaSize.X + MARGIN
				or y < areaPos.Y - MARGIN
				or y > areaPos.Y + areaSize.Y + MARGIN
			shown:SetIfChanged(outside)
			local parent = element.Parent :: GuiObject?
			if parent then
				local origin = parent.AbsolutePosition
				pos:Set(UDim2.fromOffset(x - origin.X, y - origin.Y))
			end
		end,
		Hide = function(_: FakeCursor)
			shown:SetIfChanged(false)
		end,
	}
	return self
end

-- Hides the system cursor only while `dragging`, and restores the value it FOUND (not a blind `true`): a game that had
-- already hidden the cursor (a custom cursor, a first-person camera) keeps it hidden after the drag. An Effect that did
-- not hide anything has no cleanup, so it never touches the setting.
local function hideSystemCursor(dragging: q.State<boolean>)
	return q.Effect(function()
		if not dragging:Get() then
			return nil :: any
		end
		local prior = UserInputService.MouseIconEnabled
		UserInputService.MouseIconEnabled = false
		return function(_dying: boolean)
			UserInputService.MouseIconEnabled = prior
		end
	end, dragging)
end

return {
	new = new,
	hideSystemCursor = hideSystemCursor,
}
