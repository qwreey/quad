--!strict
--[[
	M2 range slider (`Material.M2.RangeSlider`) — the M2 Slider look (`./Slider.luau`: 4 px track, 20 px round handles
	with 40 px halos, 28 px label pills, 2 px ticks) with TWO handles; the active track runs between them. Until
	2026-10-07 this was the kit's `RangeSlider`; the default is now the M3 look (`../Slider/Range.luau`). Same props and
	behaviour — both build on `../Slider/Behavior.luau`; this file only draws.

	    M2.RangeSlider({ Start = lo, End = hi, Min = 0, Max = 100 })

	Props: `Behavior.RangeSliderProps`. Default size `UDim2.new(1, 0, 0, 40)`. Returns the host `Frame` ("M2RangeSlider").
	Look per handle: hover lights the halo of the handle nearest the pointer, the dragged handle shows the dragged layer
	and its label, the focus ring and the label are on the key handle, the key handle draws above the other.
	Structure at rest (continuous): host > Rail > Inactive + Active (each Frame + UICorner), two Halos (`HaloStart`,
	`HaloEnd`) > state layer (3) + Handle (Frame + UICorner) + Label (TextLabel + UICorner + UIPadding) = 23 descendants;
	discrete adds one 2 px Frame per tick (Step + 1), active between the handles.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Tokens = require("../Tokens")
local Util = require("../Util")
local StateLayer = require("../StateLayer")
local Style = require("../Button/Style")
local Behavior = require("../Slider/Behavior")
local Bubble = require("../Slider/Bubble")
local Ticks = require("./SliderTicks")
local Frame = q.Elem "Frame"
local FrameModifier = q.Modifier "Frame"
local rangeName = FrameModifier():Name("M2RangeSlider")

export type Props = Behavior.RangeSliderProps

local INSET = 10 -- handle radius: rail margin on both sides (as M2 Slider)
local BAR = 4

local baseModifier = FrameModifier():Size(UDim2.new(1, 0, 0, 40)):BackgroundTransparency(1):BorderSizePixel(0)

local function RangeSlider(props: Props)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local r = Behavior.range(props, { Name = "M2.RangeSlider", Inset = INSET })
	local disabled = r.Disabled
	local fs, fe = r.FracStart, r.FracEnd
	local corner = Tokens.Shape.corner("Full")

	local activeColor = Style.disabledPick(disabled, R.Primary, R.OnSurface)
	local activeT = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)

	local ticks = Ticks.build({
		Frac = fe,
		FracLow = fs,
		Range = r.Range,
		Step = r.Step,
		ShowTicks = props.ShowTicks,
		Disabled = disabled,
		Theme = theme,
	})

	local activePosition: q.State<UDim2> = fs:Compute(function(self)
		return UDim2.fromScale(self:Get(), 0.5)
	end)
	local activeSize: q.State<UDim2> = fs:Compute(function(self, _prev, e)
		return UDim2.new(math.max(0, e:Get() - self:Get()), 0, 0, BAR)
	end, fe)

	local function halo(h: Behavior.Which, frac: q.State<number>, value: q.State<number>): Instance
		local s = r.handle(h)
		local layer = StateLayer.new({
			Color = theme.Color.Primary,
			Corner = corner,
			Hovered = s.Hovered,
			Pressed = q.Source(false),
			Focused = s.Focused,
			Dragged = s.Dragged,
			Disabled = disabled,
			FocusRing = theme.Color.Secondary,
		})
		local label: Instance? = nil
		if props.ShowLabel ~= false then
			label = Bubble.build({
				Dragging = s.Dragged,
				Focused = s.Focused,
				Disabled = disabled,
				Value = value,
				Format = r.Format,
				Theme = theme,
				Style = Bubble.M2,
				Position = UDim2.new(0.5, 0, 0, INSET - 4),
			})
		end
		local position: q.State<UDim2> = frac:Compute(function(self)
			return UDim2.fromScale(self:Get(), 0.5)
		end)
		local zIndex: q.State<number> = s.IsKey:Compute(function(self)
			return if self:Get() then 2 else 1
		end)
		return Frame {
			Name = "Halo" .. h,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = zIndex,
			layer,
			Frame {
				Name = "Handle",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(20, 20),
				BackgroundColor3 = activeColor,
				BackgroundTransparency = activeT,
				BorderSizePixel = 0,
				UICorner = corner,
			},
			label or q.None,
		}
	end

	return Frame {
		rangeName,
		baseModifier,
		props.Modifier or q.None,
		r.InteractionHook,
		r.DragHook,
		r.KeyHook,
		Interactable = r.Interactable,
		Selectable = r.Interactable,
		MouseMoved = r.MouseMoved,
		Frame {
			Name = "Rail",
			Position = UDim2.fromOffset(INSET, 0),
			Size = UDim2.new(1, -2 * INSET, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Frame {
				Name = "Inactive",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, 0, 0, BAR),
				BackgroundColor3 = Style.disabledPick(disabled, R.SurfaceVariant, R.OnSurface),
				BackgroundTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency),
				BorderSizePixel = 0,
				UICorner = corner,
			},
			Frame {
				Name = "Active",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = activePosition,
				Size = activeSize,
				BackgroundColor3 = activeColor,
				BackgroundTransparency = activeT,
				BorderSizePixel = 0,
				UICorner = corner,
			},
			q.Slot<<Instance>>(ticks),
			halo("Start", fs, r.Start),
			halo("End", fe, r.End),
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return RangeSlider
