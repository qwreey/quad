--!strict
--[[
	M3 slider (the current form — androidx Compose material3 `Slider`, `SliderTokens`): a 16 px track split into two
	pieces around a 4 x 44 px bar handle, 6 px of empty space on each side of the handle, each piece rounded fully (8 px)
	at the track's outer end and 2 px at the end facing the handle; a 4 px stop indicator dot at the end of the inactive
	piece; discrete sliders add 4 px tick dots; a value-label pill above the handle while dragging or focused.
	The M2 look (thin track + round handle) is `Material.M2.Slider` (`../M2/Slider.luau`) — same props, same behaviour.

	    local volume = q.Source(30)
	    Slider({ Value = volume, Min = 0, Max = 100 })                                   -- continuous
	    Slider({ Value = level, Min = 0, Max = 10, Step = 1, OnChangeEnd = save })        -- discrete, with ticks
	    Slider({ Value = x, Min = 0, Max = 1, Format = function(v) return string.format("%d%%", v * 100) end })

	Props: `Behavior.SliderProps` (`./Behavior.luau` — value, pointer, keys and callbacks are documented there and shared
	with the M2 look): Value, Min, Max, Step, ShowTicks, KeyStep, Format, ShowLabel, Disabled, OnChange, OnChangeEnd,
	Theme, Modifier (Frame Modifier after the base — default size `UDim2.new(1, 0, 0, 44)`: width from the parent, height
	the handle), Hooks. Returns the host `Frame`.

	Look (tokens; `./Track.luau` holds the geometry and the asymmetric-rounding composition):
	  active piece + handle `Primary`, inactive piece `SecondaryContainer`, stop dot `Primary`, ticks `SecondaryContainer`
	  on the active piece / `Primary` on the inactive; disabled: active + handle onSurface @ 38 %, inactive onSurface @ 12 %.
	  The handle narrows to 2 px while pressed / dragged / focused (Pressed/FocusHandleWidth); gamepad / keyboard focus
	  also draws the kit focus ring (3 px `Secondary` UIStroke, 2 px outside the handle). Hover has no visual (M3 tokens:
	  hover handle width and color unchanged). Label: 44 px pill `InverseSurface` / `LabelLarge` `InverseOnSurface`,
	  12 px above the handle (`Bubble.M3`).
	Everything but the label and the focus ring is inside the host rectangle (`AutomaticSize` ancestors measure every
	descendant — `Ripple.luau` "BOUNDED"): the handle is exactly the host height and its center stops 8 px from each edge.
	Structure at rest (continuous): host > ActiveCap, ActiveBody, InactiveCap, InactiveBody (clip Frame > Fill + UICorner,
	3 each), StopEnd (Frame + UICorner), Handle (Frame + UICorner + FocusRing UIStroke) > Label (TextLabel + UICorner +
	UIPadding) = 20 descendants; discrete adds 2 per tick (dot + UICorner; the last tick is the stop dot, not drawn twice).
	M3 deviations: the gap is fixed at 6 px around the 4 px handle (Compose re-measures it for the 2 px pressed handle,
	1 px narrower); Min/Max/Step are static; no hover visual (as M3) — the M2 look keeps its halo.
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Tokens = require("./Tokens")
local Util = require("./Util")
local Style = require("./Button/Style")
local Behavior = require("@self/Behavior")
local Track = require("@self/Track")
local Bubble = require("@self/Bubble")
local D = q.Declaration

export type Props = Behavior.SliderProps

local baseModifier = D.Modifier.Frame():Size(UDim2.new(1, 0, 0, Track.HANDLE_H)):BackgroundTransparency(1):BorderSizePixel(0)

local function handleWidth(active: q.State<boolean>): q.State<UDim2>
	return active:Compute(function(self)
		return UDim2.fromOffset(if self:Get() then Track.HANDLE_W_ACTIVE else Track.HANDLE_W, Track.HANDLE_H)
	end)
end

local function Slider(props: Props)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local b = Behavior.single(props, { Name = "Slider", Inset = Track.INSET })
	local disabled, frac, width = b.Disabled, b.Frac, b.Width

	local activeColor = Style.disabledPick(disabled, R.Primary, R.OnSurface)
	local activeT = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)
	local inactiveColor = Style.disabledPick(disabled, R.SecondaryContainer, R.OnSurface)
	local inactiveT = Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency)

	-- piece edges and visibility (px lengths: active = (W - 16) f, inactive = (W - 16)(1 - f) at INSET = GAP = 8)
	local activeEdge: q.State<UDim> = frac:Compute(function(self)
		local h = Track.x(self:Get())
		return UDim.new(h.Scale, h.Offset - Track.GAP)
	end)
	local inactiveEdge: q.State<UDim> = frac:Compute(function(self)
		local h = Track.x(self:Get())
		return UDim.new(h.Scale, h.Offset + Track.GAP)
	end)
	local activeShown: q.State<boolean> = width:Compute(function(self, _prev, f)
		local w = self:Get()
		return w > 0 and Track.INSET + (w - 2 * Track.INSET) * f:Get() - Track.GAP > Track.OUTER
	end, frac)
	local inactiveShown: q.State<boolean> = width:Compute(function(self, _prev, f)
		local w = self:Get()
		return w > 0 and w - (Track.INSET + (w - 2 * Track.INSET) * f:Get()) - Track.GAP > Track.OUTER
	end, frac)

	local ticks = Track.ticks({
		Step = b.Step,
		Range = b.Range,
		Fracs = { frac },
		ActiveTo = frac,
		Width = width,
		SkipFirst = false,
		SkipLast = true,
		ShowTicks = props.ShowTicks,
		Disabled = disabled,
		Theme = theme,
	})

	local narrow: q.State<boolean> = b.Dragging:Compute(function(self, _prev, pressed, focused)
		return self:Get() or pressed:Get() or focused:Get()
	end, b.Pressed, b.Focused)
	local ringOn: q.State<boolean> = b.Focused:Compute(function(self, _prev, dis)
		return self:Get() and not dis:Get()
	end, disabled)
	local handlePosition: q.State<UDim2> = frac:Compute(function(self)
		local h = Track.x(self:Get())
		return UDim2.new(h.Scale, h.Offset, 0.5, 0)
	end)

	local label: Instance? = nil
	if props.ShowLabel ~= false then
		label = Bubble.build({
			Dragging = b.Dragging,
			Focused = b.Focused,
			Disabled = disabled,
			Value = b.Value,
			Format = b.Format,
			Theme = theme,
			Style = Bubble.M3,
			Position = UDim2.new(0.5, 0, 0, -12),
		})
	end

	local pieces: { Instance } = {}
	for _, p in Track.outerPiece({ Name = "Active", Outer = "Left", Edge = activeEdge, Visible = activeShown, Color = activeColor, Transparency = activeT }) do
		table.insert(pieces, p)
	end
	for _, p in Track.outerPiece({ Name = "Inactive", Outer = "Right", Edge = inactiveEdge, Visible = inactiveShown, Color = inactiveColor, Transparency = inactiveT }) do
		table.insert(pieces, p)
	end
	table.insert(pieces, Track.stop({ Name = "StopEnd", Outer = "Right", Visible = inactiveShown, Color = activeColor, Transparency = activeT }))

	return D.Frame {
		Name = "Slider",
		baseModifier,
		props.Modifier or q.None,
		b.InteractionHook,
		b.DragHook,
		b.KeyHook,
		Interactable = b.Interactable,
		Selectable = b.Interactable,
		q.Slot<<Instance>>(pieces),
		q.Slot<<Instance>>(ticks),
		D.Frame {
			Name = "Handle",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = handlePosition,
			Size = handleWidth(narrow):Apply(q.Animate(Tokens.Motion.options("Short2", "Standard"))),
			BackgroundColor3 = activeColor,
			BackgroundTransparency = activeT,
			BorderSizePixel = 0,
			ZIndex = 2,
			UICorner = Tokens.Shape.corner("Full"),
			D.UIStroke {
				Name = "FocusRing",
				Color = theme.Color.Secondary,
				Thickness = 3,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				BorderStrokePosition = Enum.BorderStrokePosition.Outer,
				BorderOffset = UDim.new(0, 2),
				Enabled = ringOn,
			},
			label or q.None,
		},
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return Slider
