--!strict
--[[
	PlotLines / PlotHistogram (Iris: PlotLines / PlotHistogram).

		PlotLines     { Values: State<{ number }>, Min: number?, Max: number?, Height: number?, Text: string | State<string>?,
		                Style: Style?, Modifier: FrameModifier? }
		PlotHistogram { same }

	`Values` is the whole series, oldest first (replace the array to update: `values:Set(newArray)`; in-place edits are not
	seen). Only the LAST `Plot.MaxPoints` (200) values are drawn — older ones are dropped, so a rolling graph can be fed an
	ever-growing array without growing the instance count. `Min` / `Max` default to the data range of the drawn values
	(a flat series is padded to a 1-unit range); `Height` defaults to 80 px; `Text` is an optional centred overlay label.

	HISTOGRAM: one bar Frame per value inside a bottom-aligned horizontal UIListLayout; bar width is 1/n of the plot
	(scale), height the value's fraction of the range. Bars are keyed by INDEX through Slot:List, so growing/shrinking the
	series only creates/destroys bars at the end; a bar's size is a Compute over (the series, min, max).

	LINES: one thin Frame per segment between consecutive points, keyed by the segment's index (also Slot:List); each is
	positioned by its centre and rotated by atan2 of the pixel delta (one geometry Compute per segment, three cheap
	projections of it for Position / Size / Rotation). That needs the plot's pixel size, which the widget
	reads with `q.Out("AbsoluteSize", ...)` — until the engine has laid the frame out (size 0) segments collapse to
	zero length and appear on the first layout pass. Segments are 1 px thick, PlotLines token colour. UDim offsets are whole pixels, so segment centres/lengths are
	rounded to the pixel (the rotation is exact).

	No per-frame work beyond the Compute nodes that depend on `Values`; the widget never polls.
]]

local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
local Style = require("./Style")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type PlotProps = {
	read Values: State<{ number }>,
	read Min: number?,
	read Max: number?,
	read Height: number?,
	read Text: (string | State<string>)?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

local MAX_POINTS = 200

type Geo = { Position: UDim2, Length: UDim2, Rotation: number }
local ZERO_GEO: Geo = { Position = UDim2.fromOffset(0, 0), Length = UDim2.fromOffset(0, 1), Rotation = 0 }

type SegmentCtx = {
	Item: number | Quad.KeyGone,
	Index: number,
	Offset: State<number>,
	Prev: Quad.SlotItem<Instance>?,
	UserData: nil,
}

-- the drawn tail of the series (a fresh array only when it has to be cut)
local function tail(values: State<{ number }>): State<{ number }>
	local out: State<{ number }> = values:Compute(function(self)
		local all = self:Get()
		local n = #all
		if n <= MAX_POINTS then
			return all
		end
		return table.move(all, n - MAX_POINTS + 1, n, 1, {})
	end)
	return out
end

local function bound(visible: State<{ number }>, fixed: number?, pickMax: boolean): State<number>
	if fixed ~= nil then
		return q.Source(fixed)
	end
	local out: State<number> = visible:Compute(function(self)
		local all = self:Get()
		local best = all[1] or 0
		for i = 2, #all do
			local v = all[i]
			if pickMax then
				if v > best then
					best = v
				end
			elseif v < best then
				best = v
			end
		end
		return best
	end)
	return out
end

-- fraction of `v` inside [lo, hi] (0 at lo); a degenerate range is padded to 1 unit
local function fraction(v: number, lo: number, hi: number): number
	local range = hi - lo
	if range <= 0 then
		range = 1
	end
	return math.clamp((v - lo) / range, 0, 1)
end

local function overlay(props: PlotProps, style: Style): TextLabel | typeof(q.None)
	if props.Text == nil then
		return q.None
	end
	return D.TextLabel({
		Name = "Overlay",
		Size = UDim2.fromScale(1, 1),
		Text = props.Text,
		FontFace = style.Metrics.TextFont,
		TextSize = style.Metrics.TextSize,
		TextColor3 = style.Color.Text,
		TextTransparency = style.Transparency.Text,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
	})
end

local Plot = {}
Plot.MaxPoints = MAX_POINTS

function Plot.PlotHistogram(props: PlotProps): Frame
	local style = props.Style or Style.default
	local visible = tail(props.Values)
	local lo = bound(visible, props.Min, false)
	local hi = bound(visible, props.Max, true)
	-- bars are `n` wide: the count is its own State so a growing series re-sizes every bar once
	local count: State<number> = visible:Compute(function(self)
		return math.max(#self:Get(), 1)
	end)
	local bars = q.Slot<<Instance>>()
	bars:List(visible, function(ctx: SegmentCtx): (any, nil)
		if ctx.Item == q.KeyGone then
			return nil, nil
		end
		if ctx.Prev then
			return ctx.Prev, nil
		end
		local index = ctx.Index
		local size: State<UDim2> = visible:Compute(function(self, _prev, low, high, n)
			local v = self:Get()[index] or lo:Get()
			return UDim2.new(1 / n:Get(), -1, fraction(v, low:Get(), high:Get()), 0)
		end, lo, hi, count)
		return D.Frame({
			Name = "Bar",
			LayoutOrder = index,
			Size = size,
			BackgroundColor3 = style.Color.PlotHistogram,
			BackgroundTransparency = style.Transparency.PlotHistogram,
			BorderSizePixel = 0,
		}),
			nil
	end, function(_item: number, i: number): any
		return i
	end)
	return D.Frame({
		props.Modifier or q.None,
		Name = "PlotHistogram",
		Size = UDim2.new(1, 0, 0, props.Height or 80),
		BackgroundColor3 = style.Color.FrameBg,
		BackgroundTransparency = style.Transparency.FrameBg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		UICorner = style.Metrics.FrameRounding,
		D.UIListLayout({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 0),
		}),
		bars,
		overlay(props, style),
	})
end

function Plot.PlotLines(props: PlotProps): Frame
	local style = props.Style or Style.default
	local visible = tail(props.Values)
	local lo = bound(visible, props.Min, false)
	local hi = bound(visible, props.Max, true)
	local pixels: Source<Vector2> = q.Source(Vector2.new(0, 0))

	-- position / length / rotation of segment i in plot pixels, y pointing down (computed ONCE per segment and update)
	local function geometry(vs: { number }, i: number, low: number, high: number, size: Vector2): Geo
		local a, b = vs[i], vs[i + 1]
		if a == nil or b == nil then
			return ZERO_GEO
		end
		local n = #vs
		local x1 = (i - 1) / (n - 1) * size.X
		local x2 = i / (n - 1) * size.X
		local y1 = (1 - fraction(a, low, high)) * size.Y
		local y2 = (1 - fraction(b, low, high)) * size.Y
		local dx, dy = x2 - x1, y2 - y1
		return {
			Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
			Length = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), 1),
			Rotation = math.deg(math.atan2(dy, dx)),
		}
	end

	local segments = q.Slot<<Instance>>()
	segments:List(visible, function(ctx: SegmentCtx): (any, nil)
		if ctx.Item == q.KeyGone then
			return nil, nil
		end
		if ctx.Index >= #visible:Get() then
			-- the last point has no segment after it (also destroys the one a shrunk series leaves behind)
			return nil, nil
		end
		if ctx.Prev then
			return ctx.Prev, nil
		end
		local i = ctx.Index
		local geo: State<Geo> = visible:Compute(function(self, _prev, low, high, size)
			return geometry(self:Get(), i, low:Get(), high:Get(), size:Get())
		end, lo, hi, pixels)
		local position: State<UDim2> = geo:Compute(function(self)
			return self:Get().Position
		end)
		local length: State<UDim2> = geo:Compute(function(self)
			return self:Get().Length
		end)
		local rotation: State<number> = geo:Compute(function(self)
			return self:Get().Rotation
		end)
		return D.Frame({
			Name = "Segment",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = position,
			Size = length,
			Rotation = rotation,
			BackgroundColor3 = style.Color.PlotLines,
			BackgroundTransparency = style.Transparency.PlotLines,
			BorderSizePixel = 0,
		}),
			nil
	end, function(_item: number, i: number): any
		return i
	end)
	return D.Frame({
		props.Modifier or q.None,
		Name = "PlotLines",
		Size = UDim2.new(1, 0, 0, props.Height or 80),
		BackgroundColor3 = style.Color.FrameBg,
		BackgroundTransparency = style.Transparency.FrameBg,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		UICorner = style.Metrics.FrameRounding,
		q.Out("AbsoluteSize", pixels),
		segments,
		overlay(props, style),
	})
end

return Plot
