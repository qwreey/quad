--!strict
--[[
	M3 range slider: the M3 Slider look (`./init.luau`, `./Track.luau`) with TWO bar handles and THREE track pieces — an
	inactive piece from the start to the Start handle (rounded 8 outside, 2 at the handle), the active piece between the
	handles (rounded 2 at both ends), an inactive piece from the End handle to the end — plus a stop dot inside each outer
	end. The M2 look is `Material.M2.RangeSlider` (`../M2/RangeSlider.luau`) — same props, same behaviour.

	    local lo, hi = q.Source(20), q.Source(80)
	    RangeSlider({ Start = lo, End = hi, Min = 0, Max = 100 })                           -- continuous
	    RangeSlider({ Start = lo, End = hi, Min = 0, Max = 10, Step = 1, OnChangeEnd = save })  -- discrete, ticks

	Props: `Behavior.RangeSliderProps` (`./Behavior.luau`: Start, End, Min, Max, Step, ShowTicks, KeyStep, Format,
	ShowLabel, Disabled, OnChange(start, end), OnChangeEnd(start, end), Theme, Modifier, Hooks) and the M3 variants
	`Size`, `Orientation`, `TopToBottom` exactly as Slider (`./init.luau`; sizes `./Track.luau`). A vertical range slider is
	in the canon through MDC: `RangeSlider` extends `BaseSlider`, whose `android:orientation` it shares (Compose has no
	vertical RangeSlider). No `Centered` (not a range configuration in either) and no track icons (MDC: "Track icons can
	only be used when only 1 thumb is present"). Returns the host `Frame` (default size `UDim2.new(1, 0, 0, 44)`, like
	Slider).
	Behaviour (shared, see Behavior): a press grabs the NEAREST handle and drags it, a handle stops at the other, a drag
	that begins on a closed range picks its handle from the first movement; ONE selection stop, keys move the KEY handle
	(last dragged, Start at first), Return / KeypadEnter / gamepad ButtonX switch it.
	Look: as Slider; the dragged / key handle narrows to 2 px and draws above the other (ZIndex), the focus ring and the
	label are on the key handle. Hover has no visual (M3). Pieces hide as in Compose: an outer piece no longer than 8 px,
	the middle piece no longer than 2 px (handles together); a stop dot hides with its piece; ticks hide inside either
	handle's gap and at the two stop dots.
	Structure at rest (continuous): host > StartCap, StartBody, EndCap, EndBody (clip > Fill + UICorner, 3 each),
	Active (Frame + UICorner), StopStart, StopEnd (Frame + UICorner each), HandleStart / HandleEnd (Frame + UICorner +
	FocusRing UIStroke) > Label (TextLabel + UICorner + UIPadding) = 30 descendants; discrete adds 2 per inner tick.
	M3 deviations: as Slider; no minimum distance between the handles; both handles share one selection stop (M3 web
	focuses each thumb separately — a second stop would need its own D-pad pin).
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Tokens = require("../Tokens")
local Util = require("../Util")
local Style = require("../Button/Style")
local Behavior = require("./Behavior")
local Track = require("./Track")
local Bubble = require("./Bubble")
local D = q.Declaration

export type Props = {
	read Start: q.Source<number>?,
	read End: q.Source<number>?,
	read Min: number?,
	read Max: number?,
	read Step: number?,
	read ShowTicks: boolean?,
	read KeyStep: number?,
	read Format: ((value: number) -> string)?,
	read ShowLabel: boolean?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((startValue: number, endValue: number) -> ())?,
	read OnChangeEnd: ((startValue: number, endValue: number) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
	-- M3 variants (as Slider)
	read Size: Track.SizeName?,
	read Orientation: Track.Orientation?,
	read TopToBottom: boolean?,
}

local function RangeSlider(props: Props)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local g = Track.forLook("RangeSlider", props.Size, props.Orientation, props.TopToBottom)
	local r = Behavior.range(props, { Name = "RangeSlider", Inset = g.INSET, Vertical = g.Vertical, Flip = g.Flip })
	local disabled, width = r.Disabled, r.Length
	local fs, fe = r.FracStart, r.FracEnd
	local centerPx = g.centerPx
	local GAP, OUTER, INNER = g.GAP, g.OUTER, g.INNER

	local activeColor = Style.disabledPick(disabled, R.Primary, R.OnSurface)
	local activeT = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)
	local inactiveColor = Style.disabledPick(disabled, R.SecondaryContainer, R.OnSurface)
	local inactiveT = Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency)

	local function edge(f: q.State<number>, offset: number): q.State<UDim>
		return f:Compute(function(self)
			local h = g.x(self:Get())
			return UDim.new(h.Scale, h.Offset + offset)
		end)
	end
	local startShown: q.State<boolean> = width:Compute(function(self, _prev, f)
		local w = self:Get()
		return w > 0 and centerPx(w, f:Get()) - GAP > OUTER
	end, fs)
	local endShown: q.State<boolean> = width:Compute(function(self, _prev, f)
		local w = self:Get()
		return w > 0 and w - centerPx(w, f:Get()) - GAP > OUTER
	end, fe)
	local middleShown: q.State<boolean> = width:Compute(function(self, _prev, a, b)
		local w = self:Get()
		return w > 0 and centerPx(w, b:Get()) - centerPx(w, a:Get()) - 2 * GAP > INNER
	end, fs, fe)

	local pieces: { Instance } = {}
	for _, p in g.outerPiece({ Name = "Start", End = "Min", Edge = edge(fs, -GAP), Visible = startShown, Color = inactiveColor, Transparency = inactiveT }) do
		table.insert(pieces, p)
	end
	for _, p in g.outerPiece({ Name = "End", End = "Max", Edge = edge(fe, GAP), Visible = endShown, Color = inactiveColor, Transparency = inactiveT }) do
		table.insert(pieces, p)
	end
	table.insert(pieces, g.middlePiece({ Name = "Active", From = edge(fs, GAP), To = edge(fe, -GAP), Visible = middleShown, Color = activeColor, Transparency = activeT }))
	table.insert(pieces, g.stop({ Name = "StopStart", End = "Min", Visible = startShown, Color = activeColor, Transparency = activeT }))
	table.insert(pieces, g.stop({ Name = "StopEnd", End = "Max", Visible = endShown, Color = activeColor, Transparency = activeT }))

	local ticks = g.ticks({
		Step = r.Step,
		Range = r.Range,
		Fracs = { fs, fe },
		ActiveFrom = fs,
		ActiveTo = fe,
		Length = width,
		SkipFirst = true,
		SkipLast = true,
		ShowTicks = props.ShowTicks,
		Disabled = disabled,
		Theme = theme,
	})

	local function handle(h: Behavior.Which, f: q.State<number>, value: q.State<number>): Instance
		local s = r.handle(h)
		local narrow: q.State<boolean> = s.Dragged:Compute(function(self, _prev, focused)
			return self:Get() or focused:Get()
		end, s.Focused)
		local ringOn: q.State<boolean> = s.Focused:Compute(function(self, _prev, dis)
			return self:Get() and not dis:Get()
		end, disabled)
		local position: q.State<UDim2> = f:Compute(function(self)
			return g.point(g.x(self:Get()))
		end)
		local size: q.State<UDim2> = narrow:Compute(function(self)
			return g.handleSize(self:Get())
		end)
		-- the key / dragged handle draws above the other where they overlap
		local zIndex: q.State<number> = s.IsKey:Compute(function(self)
			return if self:Get() then 3 else 2
		end)
		local label: Instance? = nil
		if props.ShowLabel ~= false then
			local labelPosition, labelAnchor = Track.labelPlacement(g)
			label = Bubble.build({
				Dragging = s.Dragged,
				Focused = s.Focused,
				Disabled = disabled,
				Value = value,
				Format = r.Format,
				Theme = theme,
				Style = Bubble.M3,
				Position = labelPosition,
				AnchorPoint = labelAnchor,
			})
		end
		return D.Frame {
			Name = "Handle" .. h,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = size:Apply(q.Animate(Tokens.Motion.options("Short2", "Standard"))),
			BackgroundColor3 = activeColor,
			BackgroundTransparency = activeT,
			BorderSizePixel = 0,
			ZIndex = zIndex,
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
		}
	end

	return D.Frame {
		Name = "RangeSlider",
		D.Modifier.Frame():Size(g.hostSize()):BackgroundTransparency(1):BorderSizePixel(0),
		props.Modifier or q.None,
		r.InteractionHook,
		r.DragHook,
		r.KeyHook,
		Interactable = r.Interactable,
		Selectable = r.Interactable,
		MouseMoved = r.MouseMoved,
		q.Slot<<Instance>>(pieces),
		q.Slot<<Instance>>(ticks),
		handle("Start", fs, r.Start),
		handle("End", fe, r.End),
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return RangeSlider
