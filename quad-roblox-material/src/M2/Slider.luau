--!strict
--[[
	M2 slider (`Material.M2.Slider`) — the thin-track look: 4 px active/inactive track, 20 px round handle with a 40 px
	halo (state layer), a 28 px value-label pill above the handle while dragging or focused, 2 px tick marks for discrete
	sliders. Until 2026-10-07 this was the kit's `Slider` (the 2022 "classic" M3 form); the default `Slider` is now the M3
	look (`../Slider/init.luau`). Same props and behaviour — both build on `../Slider/Behavior.luau` (value, pointer,
	keys, callbacks); this file only draws.

	    M2.Slider({ Value = volume, Min = 0, Max = 100 })
	    M2.Slider({ Value = level, Min = 0, Max = 10, Step = 1 })

	Props: `Behavior.SliderProps` (Value, Min, Max, Step, ShowTicks, KeyStep, Format, ShowLabel, Disabled, OnChange,
	OnChangeEnd, Theme, Modifier, Hooks). Default size `UDim2.new(1, 0, 0, 40)`. Returns the host `Frame` (named "M2Slider").

	Geometry: the rail spans the host minus 10 px on both sides (the handle radius), so the handle CENTER travels from the
	rail start to its end (`Inset = 10`). Hover lights the halo anywhere over the host; dragging shows the dragged layer.
	Colors: active track + handle `Primary`, inactive `SurfaceVariant`, ticks `OnPrimary` / `OnSurfaceVariant` @ 38 %;
	disabled onSurface @ 38 % / 12 %. Label: `Bubble.M2` (28 px `Primary` pill, `LabelMedium` `OnPrimary`, 4 px above).
	Structure at rest (continuous): host > Rail > Inactive + Active (each Frame + UICorner), Halo > state layer (3) +
	Handle (Frame + UICorner) + Label (TextLabel + UICorner + UIPadding) = 14 descendants; discrete adds one 2 px
	Frame per tick (Step + 1).
	Note: the 40 px halo reaches 10 px past the host's left / right edge at Min / Max (the label pill reaches above) — a
	static overhang (no size change while interacting), kept from the classic look.
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
local D = q.Declaration

export type Props = Behavior.SliderProps

local INSET = 10 -- handle radius: rail margin on both sides
local BAR = 4

local baseModifier = D.Modifier.Frame():Size(UDim2.new(1, 0, 0, 40)):BackgroundTransparency(1):BorderSizePixel(0)

local function Slider(props: Props)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local b = Behavior.single(props, { Name = "M2.Slider", Inset = INSET })
	local disabled, frac = b.Disabled, b.Frac
	local corner = Tokens.Shape.corner("Full")

	local activeColor = Style.disabledPick(disabled, R.Primary, R.OnSurface)
	local activeT = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)

	local layer = StateLayer.new({
		Color = theme.Color.Primary,
		Corner = corner,
		Hovered = b.Hovered,
		Pressed = b.Pressed,
		Focused = b.Focused,
		Dragged = b.Dragging,
		Disabled = disabled,
		FocusRing = theme.Color.Secondary,
	})

	local ticks = Ticks.build({ Frac = frac, Range = b.Range, Step = b.Step, ShowTicks = props.ShowTicks, Disabled = disabled, Theme = theme })

	local label: Instance? = nil
	if props.ShowLabel ~= false then
		label = Bubble.build({
			Dragging = b.Dragging,
			Focused = b.Focused,
			Disabled = disabled,
			Value = b.Value,
			Format = b.Format,
			Theme = theme,
			Style = Bubble.M2,
			Position = UDim2.new(0.5, 0, 0, INSET - 4),
		})
	end

	local activeSize: q.State<UDim2> = frac:Compute(function(self)
		return UDim2.new(self:Get(), 0, 0, BAR)
	end)
	local haloPosition: q.State<UDim2> = frac:Compute(function(self)
		return UDim2.fromScale(self:Get(), 0.5)
	end)

	return D.Frame {
		Name = "M2Slider",
		baseModifier,
		props.Modifier or q.None,
		b.InteractionHook,
		b.DragHook,
		b.KeyHook,
		Interactable = b.Interactable,
		Selectable = b.Interactable,
		D.Frame {
			Name = "Rail",
			Position = UDim2.fromOffset(INSET, 0),
			Size = UDim2.new(1, -2 * INSET, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.Frame {
				Name = "Inactive",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, 0, 0, BAR),
				BackgroundColor3 = Style.disabledPick(disabled, R.SurfaceVariant, R.OnSurface),
				BackgroundTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency),
				BorderSizePixel = 0,
				UICorner = corner,
			},
			D.Frame {
				Name = "Active",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = activeSize,
				BackgroundColor3 = activeColor,
				BackgroundTransparency = activeT,
				BorderSizePixel = 0,
				UICorner = corner,
			},
			q.Slot<<Instance>>(ticks),
			D.Frame {
				Name = "Halo",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = haloPosition,
				Size = UDim2.fromOffset(40, 40),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				layer,
				D.Frame {
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
			},
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return Slider
