--!strict
--[[
	M3 slider (the current form — androidx Compose material3 `Slider`, `SliderTokens`; the M3 Expressive configurations of
	material-components-android `BaseSlider`): a track split into pieces around a 4 px bar handle, 6 px of empty space on
	each side of the handle, each piece rounded fully at the track's outer end and 2 px at the end facing the handle; a
	4 px stop indicator dot at the end of the inactive piece; discrete sliders add 4 px tick dots; a value-label pill
	next to the handle while dragging or focused.
	The M2 look (thin track + round handle) is `Material.M2.Slider` (`../M2/Slider.luau`) — the shared props, the same
	behaviour, none of the M3 variants below (M2 has none).

	    local volume = q.Source(30)
	    Slider({ Value = volume, Min = 0, Max = 100 })                                   -- standard, continuous
	    Slider({ Value = level, Min = 0, Max = 10, Step = 1, OnChangeEnd = save })        -- discrete, with ticks
	    Slider({ Value = x, Min = 0, Max = 1, Format = function(v) return string.format("%d%%", v * 100) end })
	    Slider({ Value = ratio, Min = 0, Max = 10000, Step = 1, KeyStep = 100, Unit = { Scale = 0.01, Suffix = "%" } })
	        -- the value stays an INTEGER (0..10000), the label reads "37.25%" (`../Unit.luau`)
	    Slider({ Value = pan, Min = -50, Max = 50, Centered = true })                     -- centered
	    Slider({ Value = volume, Min = 0, Max = 100, Orientation = "Vertical", Modifier = q.Modifier "Frame" ():Size(UDim2.fromOffset(44, 200)) })
	    Slider({ Value = volume, Min = 0, Max = 100, Size = "M", TrackIconActiveStart = "rbxassetid://123" })  -- inset icon

	Props: the shared `Behavior.SliderProps` (`./Behavior.luau` — value, pointer, keys and callbacks are documented there
	and shared with the M2 look): Value, Min, Max, Step, ShowTicks, KeyStep, Format, Unit, ShowLabel, Disabled, OnChange,
	OnChangeEnd, Theme, Modifier (Frame Modifier after the base — default size: the parent's length along the axis, the
	handle height across, `UDim2.new(1, 0, 0, 44)` for the default), Hooks; and the M3 variants (all static):
	  Size          "XS" | "S" | "M" | "L" | "XL"   default "XS" — track / outer corner / handle height / inset icon:
	                16/8/44/–, 24/8/44/–, 40/12/44/24, 56/16/68/24, 96/28/108/32 (`./Track.luau` header, MDC
	                `Widget.Material3Expressive.Slider.*` and tokens md.comp.slider.<size>)
	  Orientation   "Horizontal" | "Vertical"   default "Horizontal". Vertical (MDC `android:orientation`, Compose
	                `VerticalSlider`): the track is a column, the handle HANDLE_H wide x 4 tall (Compose
	                VerticalThumbSize = (HandleHeight, HandleWidth)), Min at the BOTTOM (MDC's vertical slider); the
	                value label sits LEFT of the handle; Up/Down move it (Left/Right walk the selection on).
	  TopToBottom   boolean?   Vertical only: Min at the TOP instead (Compose `VerticalSlider(topToBottom = true)`, its
	                default — this kit defaults to the bottom, user decision 2026-10-08); an error on a horizontal slider
	  Centered      boolean?   the centered slider (MDC `app:centered` / `setCentered`, Compose `SliderDefaults.CenteredTrack`):
	                the active track runs from the middle of the track — (Min + Max) / 2, fixed, there is no API for
	                another origin — to the handle, on either side; an own `Value` starts at the middle. Stop dots at
	                both ends, no dot at the middle. An error together with the track icons below.
	  TrackIconActiveStart / TrackIconActiveEnd / TrackIconInactiveStart / TrackIconInactiveEnd   string?
	                the INSET ICONS (MDC `app:trackIconActiveStart` .. `trackIconInactiveEnd`, standard slider only,
	                sizes M / L / XL — an error otherwise): an icon prop value (`Icons.resolve`: an Icons name, an
	                image URL, or text drawn as a glyph) drawn INSIDE a track piece, 10 px from the piece's end
	                (Start = the end toward Min, End = toward Max; MDC `m3_slider_track_icon_padding` 10dp), icon size
	                24 / 24 / 32; hidden while its piece is shorter than icon + 20 (MDC `calculateTrackIconBounds`).
	                Color: the color of a tick on that piece — SecondaryContainer on the active piece, Primary on the
	                inactive (Compose SliderSamples.kt `SliderWithTrackIconsSample`: activeTickColor / inactiveTickColor;
	                MDC leaves the icon untinted by default).
	Returns the host `Frame`.

	Look (tokens; `./Track.luau` holds the geometry and the asymmetric-rounding composition):
	  active piece + handle `Primary`, inactive piece `SecondaryContainer`, stop dot `Primary`, ticks `SecondaryContainer`
	  on the active piece / `Primary` on the inactive; disabled: active + handle onSurface @ 38 %, inactive onSurface @ 12 %.
	  The handle narrows to 2 px while pressed / dragged / focused (Pressed/FocusHandleWidth); gamepad / keyboard focus
	  also draws the kit focus ring (3 px `Secondary` UIStroke, 2 px outside the handle). Hover has no visual (M3 tokens:
	  hover handle width and color unchanged). Label: 32 px pill `InverseSurface` / `LabelLarge` (Regular) `InverseOnSurface`,
	  12 px above the handle (`Bubble.M3`) — left of it on a vertical slider.
	CENTERED geometry (Compose `SliderDefaults.drawTrack` with isCentered, Slider.kt 2402~2620; MDC `getActiveRange` /
	`drawInactiveTracks` / `drawActiveTracks`, BaseSlider.java 2804~2935): with the value above the middle the Min-side
	inactive piece ends 6 px before the middle, the active piece runs from the middle (inner corner 2) to 8 px before the
	handle, the Max-side inactive piece starts 8 px after the handle; mirrored below the middle; at the middle both
	inactive pieces stop 8 px from the handle and there is no active piece. Ticks: none within 6 px of the middle
	(Compose `tickCenterGap`), none at the two stop dots.
	Everything but the label and the focus ring is inside the host rectangle (`AutomaticSize` ancestors measure every
	descendant — `Ripple.luau` "BOUNDED"): the handle is exactly the host's thickness and its center stops one outer
	radius from each end.
	Structure at rest (standard, continuous, XS): host > ActiveCap, ActiveBody, InactiveCap, InactiveBody (clip Frame >
	Fill + UICorner, 3 each), StopEnd (Frame + UICorner), Handle (Frame + UICorner + FocusRing UIStroke) > Label
	(TextLabel + UICorner + UIPadding) = 20 descendants; discrete adds 2 per tick (dot + UICorner; the last tick is the stop
	dot, not drawn twice); each inset icon +1 (ImageLabel or TextLabel). Centered: StartCap, StartBody, EndCap, EndBody
	(3 each), Active (Frame + UICorner), StopStart, StopEnd (2 each), Handle (3) > Label (3) = 24. The size and the
	orientation change no count.
	M3 deviations: the gap is fixed at 6 px around the 4 px handle (Compose re-measures it for the 2 px pressed handle,
	1 px narrower); Min/Max/Step and the variants are static; no hover visual (as M3) — the M2 look keeps its halo. A
	centered slider hides an outer piece no longer than its outer radius and the active piece no longer than 2 px (the
	standard / range rule; Compose's centered track instead shrinks the corners of a short piece). The stop dot at the Max
	end hides while an inactive-end inset icon is shown (MDC draws both on the same spot; Compose's icon sample draws no
	stop dot) — see the 10th-QA notes. No right-to-left layout.
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Tokens = require("./Tokens")
local Util = require("./Util")
local Style = require("./Button/Style")
local IconView = require("./IconView")
local Behavior = require("@self/Behavior")
local Unit = require("./Unit")
local Track = require("@self/Track")
local Bubble = require("@self/Bubble")
local Frame = q.Elem "Frame"
local UIStroke = q.Elem "UIStroke"
local FrameModifier = q.Modifier "Frame"
local sliderName = FrameModifier():Name("Slider")

export type Size = Track.SizeName
export type Orientation = Track.Orientation

export type Props = {
	read Value: q.Source<number>?,
	read Min: number?,
	read Max: number?,
	read Step: number?,
	read ShowTicks: boolean?,
	read KeyStep: number?,
	read Format: ((value: number) -> string)?,
	read Unit: Unit.Unit?,
	read ShowLabel: boolean?,
	read Disabled: (boolean | q.State<boolean>)?,
	read OnChange: ((value: number) -> ())?,
	read OnChangeEnd: ((value: number) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.ModifierInto<Frame>?,
	read Hooks: Util.Hooks?,
	-- M3 variants
	read Size: Size?,
	read Orientation: Orientation?,
	read TopToBottom: boolean?,
	read Centered: boolean?,
	read TrackIconActiveStart: string?,
	read TrackIconActiveEnd: string?,
	read TrackIconInactiveStart: string?,
	read TrackIconInactiveEnd: string?,
}

local ICON_PADDING = 10 -- MDC m3_slider_track_icon_padding

local function px(u: UDim, length: number): number
	return u.Scale * length + u.Offset
end
local function plus(u: UDim, offset: number): UDim
	return UDim.new(u.Scale, u.Offset + offset)
end

local function Slider(props: Props)
	local theme = Theme.resolve(props.Theme)
	local R = theme.Raw
	local g = Track.forLook("Slider", props.Size, props.Orientation, props.TopToBottom)
	local centered = props.Centered == true
	local iconProps: { [string]: string? } = {
		ActiveStart = props.TrackIconActiveStart,
		ActiveEnd = props.TrackIconActiveEnd,
		InactiveStart = props.TrackIconInactiveStart,
		InactiveEnd = props.TrackIconInactiveEnd,
	}
	local hasIcons = next(iconProps) ~= nil
	if hasIcons and centered then
		Util.fail("Slider", "track icons are for the standard slider (not Centered)")
	end
	if hasIcons and g.ICON == nil then
		Util.fail("Slider", `track icons need Size "M", "L" or "XL" (got {props.Size or "XS"})`)
	end
	local b = Behavior.single(props, { Name = "Slider", Inset = g.INSET, Vertical = g.Vertical, Flip = g.Flip, Centered = centered })
	local disabled, frac, length = b.Disabled, b.Frac, b.Length
	local OUTER, INNER, GAP, SPACE, INSET = g.OUTER, g.INNER, g.GAP, g.SPACE, g.INSET

	local activeColor = Style.disabledPick(disabled, R.Primary, R.OnSurface)
	local activeT = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency)
	local inactiveColor = Style.disabledPick(disabled, R.SecondaryContainer, R.OnSurface)
	local inactiveT = Style.disabledNumber(disabled, 0, Style.DisabledContainerTransparency)

	local pieces: { Instance } = {}
	local function add(list: { Instance })
		for _, p in list do
			table.insert(pieces, p)
		end
	end

	local ticks: { Instance }
	local inactiveEndIconShown: q.State<boolean>? = nil
	if not centered then
		-- STANDARD: active piece from the Min end to 8 px before the handle, inactive from 8 px after it to the Max end
		local activeEdge: q.State<UDim> = frac:Compute(function(self)
			return plus(g.x(self:Get()), -GAP)
		end)
		local inactiveEdge: q.State<UDim> = frac:Compute(function(self)
			return plus(g.x(self:Get()), GAP)
		end)
		-- piece lengths in px (0 before layout)
		local activeRun: q.State<number> = length:Compute(function(self, _prev, f)
			local l = self:Get()
			return if l > 0 then g.centerPx(l, f:Get()) - GAP else 0
		end, frac)
		local inactiveRun: q.State<number> = length:Compute(function(self, _prev, f)
			local l = self:Get()
			return if l > 0 then l - g.centerPx(l, f:Get()) - GAP else 0
		end, frac)
		-- Compose (Slider.kt drawTrack, enableCornerShrinking): a continuous slider draws a piece for any length > 0 and
		-- the rounded rect shrinks its corners with it; a stepped one hides it once it is no longer than the outer
		-- radius (threshold += cornerSize). The stop dot is drawn with its piece: here only while the piece covers its center (INSET).
		local shrinks = b.Step == nil
		local activeShown: q.State<boolean> = activeRun:Compute(function(self)
			return self:Get() > (if shrinks then 0 else OUTER)
		end)
		local inactiveShown: q.State<boolean> = inactiveRun:Compute(function(self)
			return self:Get() > (if shrinks then 0 else OUTER)
		end)
		local inactiveCoversStop: q.State<boolean> = inactiveRun:Compute(function(self)
			return self:Get() > (if shrinks then INSET else OUTER)
		end)
		add(g.outerPiece({ Name = "Active", End = "Min", Edge = activeEdge, Visible = activeShown, Run = activeRun, Color = activeColor, Transparency = activeT }))
		add(g.outerPiece({ Name = "Inactive", End = "Max", Edge = inactiveEdge, Visible = inactiveShown, Run = inactiveRun, Color = inactiveColor, Transparency = inactiveT }))

		-- inset icons (MDC calculateTrackIconBounds: shown while the piece is at least icon + 2 x 10 long)
		if hasIcons then
			local size = g.ICON :: number
			local half = size / 2
			local function iconFor(key: string, piece: "Active" | "Inactive", side: "Start" | "End")
				local value = iconProps[key]
				if value == nil then
					return
				end
				-- the piece in px from the Min end: active [0, c - GAP], inactive [c + GAP, L]
				local center: q.State<UDim> = frac:Compute(function(self)
					local x = g.x(self:Get())
					if piece == "Active" then
						return if side == "Start" then UDim.new(0, ICON_PADDING + half) else plus(x, -GAP - ICON_PADDING - half)
					end
					return if side == "Start" then plus(x, GAP + ICON_PADDING + half) else UDim.new(1, -ICON_PADDING - half)
				end)
				local shown: q.State<boolean> = length:Compute(function(self, _prev, f)
					local l = self:Get()
					if l <= 0 then
						return false
					end
					local c = g.centerPx(l, f:Get())
					local pieceLength = if piece == "Active" then c - GAP else l - c - GAP
					return pieceLength >= size + 2 * ICON_PADDING
				end, frac)
				if key == "InactiveEnd" then
					inactiveEndIconShown = shown
				end
				local color, transparency
				if piece == "Active" then
					color, transparency = g.onActive(disabled, theme)
				else
					color, transparency = g.onInactive(disabled, theme)
				end
				local position: q.State<UDim2> = center:Compute(function(self)
					return g.point(self:Get())
				end)
				local view = IconView.new({
					Name = "TrackIcon" .. key,
					Icon = value,
					Size = size,
					Color = color,
					Transparency = transparency,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = position,
					Visible = shown,
				})
				table.insert(pieces, view)
			end
			iconFor("ActiveStart", "Active", "Start")
			iconFor("ActiveEnd", "Active", "End")
			iconFor("InactiveStart", "Inactive", "Start")
			iconFor("InactiveEnd", "Inactive", "End")
		end

		local stopShown = inactiveCoversStop
		local iconOnStop = inactiveEndIconShown
		if iconOnStop ~= nil then
			stopShown = inactiveCoversStop:Compute(function(self, _prev, icon)
				return self:Get() and not icon:Get()
			end, iconOnStop)
		end
		table.insert(pieces, g.stop({ Name = "StopEnd", End = "Max", Visible = stopShown, Color = activeColor, Transparency = activeT }))

		ticks = g.ticks({
			Step = b.Step,
			Range = b.Range,
			Fracs = { frac },
			ActiveTo = frac,
			Length = length,
			SkipFirst = false,
			SkipLast = true,
			ShowTicks = props.ShowTicks,
			Disabled = disabled,
			Theme = theme,
		})
	else
		-- CENTERED (Compose drawTrack isCentered): the active piece joins the middle and the handle; the inactive piece
		-- on the active side stops SPACE (6) before the middle, the other one GAP (8) after the handle
		local mid = g.x(0.5)
		local function minEdge(f: number): UDim
			if f > 0.5 then
				return plus(mid, -SPACE)
			end
			return plus(g.x(f), -GAP)
		end
		local function maxEdge(f: number): UDim
			if f < 0.5 then
				return plus(mid, SPACE)
			end
			return plus(g.x(f), GAP)
		end
		local function activeFrom(f: number): UDim
			return if f < 0.5 then plus(g.x(f), GAP) else mid
		end
		local function activeTo(f: number): UDim
			return if f > 0.5 then plus(g.x(f), -GAP) else mid
		end
		-- piece lengths in px (0 before layout); continuous: any length > 0 (corners shrink with it, Compose
		-- enableCornerShrinking), stepped: hidden at or below the outer / inner radius
		local shrinks = b.Step == nil
		local startRun: q.State<number> = length:Compute(function(self, _prev, f)
			local l = self:Get()
			return if l > 0 then px(minEdge(f:Get()), l) else 0
		end, frac)
		local endRun: q.State<number> = length:Compute(function(self, _prev, f)
			local l = self:Get()
			return if l > 0 then l - px(maxEdge(f:Get()), l) else 0
		end, frac)
		local startShown: q.State<boolean> = startRun:Compute(function(self)
			return self:Get() > (if shrinks then 0 else OUTER)
		end)
		local endShown: q.State<boolean> = endRun:Compute(function(self)
			return self:Get() > (if shrinks then 0 else OUTER)
		end)
		local startCoversStop: q.State<boolean> = startRun:Compute(function(self)
			return self:Get() > (if shrinks then INSET else OUTER)
		end)
		local endCoversStop: q.State<boolean> = endRun:Compute(function(self)
			return self:Get() > (if shrinks then INSET else OUTER)
		end)
		local middleRun: q.State<number> = length:Compute(function(self, _prev, f)
			local l = self:Get()
			local v = f:Get()
			return if l > 0 then px(activeTo(v), l) - px(activeFrom(v), l) else 0
		end, frac)
		local middleShown: q.State<boolean> = middleRun:Compute(function(self)
			return self:Get() > (if shrinks then 0 else INNER)
		end)
		local minEdgeS: q.State<UDim> = frac:Compute(function(self)
			return minEdge(self:Get())
		end)
		local maxEdgeS: q.State<UDim> = frac:Compute(function(self)
			return maxEdge(self:Get())
		end)
		local fromS: q.State<UDim> = frac:Compute(function(self)
			return activeFrom(self:Get())
		end)
		local toS: q.State<UDim> = frac:Compute(function(self)
			return activeTo(self:Get())
		end)
		add(g.outerPiece({ Name = "Start", End = "Min", Edge = minEdgeS, Visible = startShown, Run = startRun, Color = inactiveColor, Transparency = inactiveT }))
		add(g.outerPiece({ Name = "End", End = "Max", Edge = maxEdgeS, Visible = endShown, Run = endRun, Color = inactiveColor, Transparency = inactiveT }))
		table.insert(pieces, g.middlePiece({ Name = "Active", From = fromS, To = toS, Visible = middleShown, Run = middleRun, Color = activeColor, Transparency = activeT }))
		table.insert(pieces, g.stop({ Name = "StopStart", End = "Min", Visible = startCoversStop, Color = activeColor, Transparency = activeT }))
		table.insert(pieces, g.stop({ Name = "StopEnd", End = "Max", Visible = endCoversStop, Color = activeColor, Transparency = activeT }))
		local tickFrom: q.State<number> = frac:Compute(function(self)
			return math.min(self:Get(), 0.5)
		end)
		local tickTo: q.State<number> = frac:Compute(function(self)
			return math.max(self:Get(), 0.5)
		end)
		ticks = g.ticks({
			Step = b.Step,
			Range = b.Range,
			Fracs = { frac },
			ActiveFrom = tickFrom,
			ActiveTo = tickTo,
			Length = length,
			SkipFirst = true,
			SkipLast = true,
			CenterGap = SPACE,
			ShowTicks = props.ShowTicks,
			Disabled = disabled,
			Theme = theme,
		})
	end

	local narrow: q.State<boolean> = b.Dragging:Compute(function(self, _prev, pressed, focused)
		return self:Get() or pressed:Get() or focused:Get()
	end, b.Pressed, b.Focused)
	local ringOn: q.State<boolean> = b.Focused:Compute(function(self, _prev, dis)
		return self:Get() and not dis:Get()
	end, disabled)
	local handlePosition: q.State<UDim2> = frac:Compute(function(self)
		return g.point(g.x(self:Get()))
	end)
	local handleSize: q.State<UDim2> = narrow:Compute(function(self)
		return g.handleSize(self:Get())
	end)

	local label: Instance? = nil
	if props.ShowLabel ~= false then
		local position, anchor = Track.labelPlacement(g)
		label = Bubble.build({
			Dragging = b.Dragging,
			Focused = b.Focused,
			Disabled = disabled,
			Value = b.Value,
			Format = b.Format,
			Theme = theme,
			Style = Bubble.M3,
			Position = position,
			AnchorPoint = anchor,
		})
	end

	return Frame {
		sliderName,
		FrameModifier():Size(g.hostSize()):BackgroundTransparency(1):BorderSizePixel(0),
		props.Modifier or q.None,
		b.InteractionHook,
		b.DragHook,
		b.KeyHook,
		Interactable = b.Interactable,
		Selectable = b.Interactable,
		q.Slot<<Instance>>(pieces),
		q.Slot<<Instance>>(ticks),
		Frame {
			Name = "Handle",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = handlePosition,
			Size = handleSize:Apply(q.Animate(Tokens.Motion.options("Short2", "Standard"))),
			BackgroundColor3 = activeColor,
			BackgroundTransparency = activeT,
			BorderSizePixel = 0,
			ZIndex = 2,
			UICorner = Tokens.Shape.corner("Full"),
			UIStroke {
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
