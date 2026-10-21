--!strict
--[[
	ColorPicker3 / OpenColorPicker — the full colour picker (Dear ImGui's ColorPicker3; `InputColor3` is its ColorEdit3).
	[2026-10-21 user decisions with the devplorer candidate list: live apply while dragging, Cancel restores the colour
	it had when opened, the dialog is a public surface of its own besides InputColor3's swatch; names by a three-model
	review, audit/naming-devui-2026-10-21d/.]

		ColorPicker3 {
			Value: Source<Color3>?,                 two-way; an internal Source (white) when omitted
			OnChange: ((c: Color3) -> ())?,         after every change made in the picker (not outside writes)
			Style: Style?, Modifier: ModifierInto<Frame>?,
		}                                           -> Frame
		    [saturation / value square][hue bar][new | original]  over an InputColor3 row (R / G / B, #hex).
		    Clicking the original swatch puts that colour back.

		OpenColorPicker {
			Title: (string | State<string>)?,       default "Color"
			Value: Source<Color3>,                  written live while the user drags
			OnChange: ((c: Color3) -> ())?,
			OnResult: ((ok: boolean, c: Color3) -> ())?,   once: OK -> true; Cancel / Escape / Close -> false (after the
			                                        colour it had when opened is put back)
			Window: Instance?, Modal: DialogModal?, Overlay?, Style?,
		}                                           -> DialogHandle  (Modal defaults to "Global" without a Window)

	THE STATE is one HSV (Devui.ColorModel's header: black and grey have no hue, so a Color3-only state snaps the hue to
	red at the black edge). `Value` follows it through one Effect, as the material kit's picker does: an outside write
	is pulled in keeping the hue (and the saturation at black), our own write ends its echo when both sides match.
	Applying is live — a costly consumer (a property set across the network) can wrap its own reaction in q.Throttle.
]]

local ColorModel = require("./ColorModel")
local Common = require("./Common")
local Dialog = require("./Dialog")
local Interaction = require("./Interaction")
local InputColor3 = require("./Inputs/InputColor3")
local Quad = require("./Quad")
local Button = require("./Button")
local Style = require("./Style")
local Util = require("./Util")

local q = Quad
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local UIGradient = q.Elem "UIGradient"
local UIListLayout = q.Elem "UIListLayout"
local UIStroke = q.Elem "UIStroke"
local FrameModifier = q.Modifier "Frame"
local rootName = FrameModifier():Name("ColorPicker3")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style
type HSV = ColorModel.HSV

export type ColorPicker3Props = {
	read Value: Source<Color3>?,
	read OnChange: ((c: Color3) -> ())?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
}

export type OpenColorPickerProps = {
	read Title: (string | State<string>)?,
	read Value: Source<Color3>,
	read OnChange: ((c: Color3) -> ())?,
	read OnResult: ((ok: boolean, c: Color3) -> ())?,
	read Window: Instance?,
	read Modal: Dialog.DialogModal?,
	read Overlay: any?,
	read Style: Style?,
}

local ColorPicker = {}

local function sameColor(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) < 1e-9 and math.abs(a.G - b.G) < 1e-9 and math.abs(a.B - b.B) < 1e-9
end

-- the hue bar's rainbow, top (hue 0) to bottom (hue 1)
local HUE_SEQUENCE = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
	ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
	ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
	ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
	ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
	ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
	ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
})

local function fraction(at: number, origin: number, size: number): number
	if size <= 0 then
		return 0
	end
	return math.clamp((at - origin) / size, 0, 1)
end

function ColorPicker.ColorPicker3(props: ColorPicker3Props): Frame
	local style = props.Style or Style.default
	local value: Source<Color3> = props.Value or q.Source(Color3.new(1, 1, 1))
	local onChange = props.OnChange
	local original = value:Get()

	local hsv: Source<HSV> = q.Source(ColorModel.fromColor3(original, nil))
	local color: State<Color3> = hsv:Compute(function(self)
		return ColorModel.toColor3(self:Get())
	end)
	local function commit(nextHsv: HSV)
		if ColorModel.equalsHSV(hsv:Get(), nextHsv) then
			return
		end
		hsv:Set(nextHsv)
		if onChange then
			onChange(color:Get())
		end
	end
	-- Value <-> hsv (header THE STATE): an outside write is pulled in keeping the hue; a picker change is pushed out
	local lastSeen = value:Get()
	local sync = q.Effect(function()
		local outside = value:Get()
		local mine = color:Get()
		if sameColor(outside, mine) then
			lastSeen = outside
			return
		end
		if outside ~= lastSeen then
			lastSeen = outside
			local current = hsv:Get()
			local pulled = ColorModel.fromColor3(outside, current)
			if not ColorModel.equalsHSV(current, pulled) then
				hsv:Set(pulled)
			end
		else
			value:SetIfChanged(mine)
			lastSeen = mine
		end
	end, hsv, color, value)

	local side: State<number> = style.FrameHeight:Compute(function(self)
		return math.floor(self:Get() * 8 + 0.5)
	end)
	local squareSize: State<UDim2> = side:Compute(function(self)
		return UDim2.fromOffset(self:Get(), self:Get())
	end)
	local barSize: State<UDim2> = side:Compute(function(self, _prev, frameHeight)
		return UDim2.fromOffset(frameHeight:Get(), self:Get())
	end, style.FrameHeight)
	local swatchSize: State<UDim2> = style.FrameHeight:Compute(function(self)
		return UDim2.fromOffset(self:Get() * 2, self:Get() * 2)
	end)
	local hueColor: State<Color3> = hsv:Compute(function(self)
		return Color3.fromHSV(self:Get().H, 1, 1)
	end)
	local cursorAt: State<UDim2> = hsv:Compute(function(self)
		local c = self:Get()
		return UDim2.fromScale(c.S, 1 - c.V)
	end)
	local hueAt: State<UDim2> = hsv:Compute(function(self)
		return UDim2.new(0, -2, self:Get().H, 0)
	end)

	-- the square: S left -> right, V bottom -> top
	local squareRef = q.Ref(nil :: Frame?)
	local function setSV(x: number, y: number)
		local sq = squareRef.Value
		if sq == nil then
			return
		end
		local current = hsv:Get()
		local s = fraction(x, sq.AbsolutePosition.X, sq.AbsoluteSize.X)
		local v = 1 - fraction(y, sq.AbsolutePosition.Y, sq.AbsoluteSize.Y)
		commit(ColorModel.newHSV(current.H, s, v))
	end
	local svDrag = Interaction.drag({
		OnBegin = setSV,
		OnMove = function(x, y, _dx, _dy)
			setSV(x, y)
		end,
	})
	local barRef = q.Ref(nil :: Frame?)
	local function setHue(_x: number, y: number)
		local bar = barRef.Value
		if bar == nil then
			return
		end
		local current = hsv:Get()
		commit(ColorModel.newHSV(fraction(y, bar.AbsolutePosition.Y, bar.AbsoluteSize.Y), current.S, current.V))
	end
	local hueDrag = Interaction.drag({
		OnBegin = setHue,
		OnMove = function(x, y, _dx, _dy)
			setHue(x, y)
		end,
	})

	local spacing: State<UDim> = Util.pxX(style.Metrics.ItemInnerSpacing)
	return Frame({
		rootName,
		props.Modifier or q.None,
		sync,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UIListLayout({
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = Util.pxY(style.Metrics.ItemSpacing),
		}),
		Frame({
			Name = "PickerRow",
			LayoutOrder = 1,
			AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			UIListLayout({
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = spacing,
			}),
			Frame({
				Name = "SVSquare",
				squareRef,
				svDrag.Hook,
				LayoutOrder = 1,
				Size = squareSize,
				BackgroundColor3 = hueColor,
				BorderSizePixel = 0,
				Active = true,
				-- white -> clear left to right (saturation), then clear -> black top to bottom (value)
				Frame({
					Name = "Saturation",
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					UIGradient({ Transparency = NumberSequence.new(0, 1) }),
				}),
				Frame({
					Name = "Value",
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(0, 0, 0),
					BorderSizePixel = 0,
					UIGradient({ Rotation = 90, Transparency = NumberSequence.new(1, 0) }),
				}),
				Frame({
					Name = "Cursor",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = cursorAt,
					Size = UDim2.fromOffset(9, 9),
					ZIndex = 2,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					UICorner = UDim.new(1, 0),
					UIStroke({ Color = Color3.new(1, 1, 1), Thickness = 2 }),
				}),
				Common.stroke(style),
			}),
			Frame({
				Name = "HueBar",
				barRef,
				hueDrag.Hook,
				LayoutOrder = 2,
				Size = barSize,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Active = true,
				UIGradient({ Rotation = 90, Color = HUE_SEQUENCE }),
				Frame({
					Name = "Marker",
					AnchorPoint = Vector2.new(0, 0.5),
					Position = hueAt,
					Size = UDim2.new(1, 4, 0, 3),
					ZIndex = 2,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					UIStroke({ Color = Color3.new(1, 1, 1), Thickness = 1 }),
				}),
				Common.stroke(style),
			}),
			Frame({
				Name = "Preview",
				LayoutOrder = 3,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIListLayout({
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Frame({
					Name = "Current",
					LayoutOrder = 1,
					Size = swatchSize,
					BackgroundColor3 = color,
					BorderSizePixel = 0,
				}),
				TextButton({
					Name = "Original",
					LayoutOrder = 2,
					Size = swatchSize,
					BackgroundColor3 = original,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = "",
					Activated = function()
						commit(ColorModel.fromColor3(original, hsv:Get()))
					end,
				}),
			}),
		}),
		InputColor3({
			Value = value,
			OnChange = onChange,
			NoPicker = true,
			Style = style,
			Modifier = FrameModifier():LayoutOrder(2),
		}),
	})
end

function ColorPicker.OpenColorPicker(props: OpenColorPickerProps): Dialog.DialogHandle
	local style = props.Style or Style.default
	local value = props.Value
	local original = value:Get()
	local answered = false
	local onResult = props.OnResult
	local handle: Dialog.DialogHandle
	local function answer(ok: boolean)
		if answered then
			return
		end
		answered = true
		if not ok then
			value:Set(original)
			if props.OnChange then
				props.OnChange(original)
			end
		end
		if onResult then
			onResult(ok, value:Get())
		end
		handle:Close()
	end
	handle = Dialog.OpenDialog({
		Title = props.Title or "Color",
		Window = props.Window,
		Modal = props.Modal or (if props.Window == nil then "Global" else "Window"),
		Overlay = props.Overlay,
		Style = style,
		-- Escape, :Close() and the window closing: a cancel
		OnClose = function()
			answer(false)
		end,
		Children = q.Slot<<Instance>>({
			ColorPicker.ColorPicker3({
				Value = value,
				OnChange = props.OnChange,
				Style = style,
				Modifier = FrameModifier():LayoutOrder(1),
			}),
			Frame({
				Name = "PickerButtons",
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				UIListLayout({
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = Util.pxX(style.Metrics.ItemSpacing),
				}),
				Button.Button({
					Text = "OK",
					Style = style,
					Modifier = q.Modifier "TextButton"():Name("OkButton"):LayoutOrder(1),
					OnClick = function()
						answer(true)
					end,
				}),
				Button.Button({
					Text = "Cancel",
					Style = style,
					Modifier = q.Modifier "TextButton"():Name("CancelButton"):LayoutOrder(2),
					OnClick = function()
						answer(false)
					end,
				}),
			}),
		}),
	})
	return handle
end

return ColorPicker
