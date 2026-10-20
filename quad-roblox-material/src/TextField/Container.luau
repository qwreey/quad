--!strict
--[[
	TextField container: the floating label and the 56 px container (Filled: rounded fill + state layer + active indicator,
	clipped so only the TOP corners show; Outlined: the outline, cut open where the label floats). Row / slots are built by
	Field.luau and handed in; the container only seats them.

	Floating label (BodyLarge 16 -> BodySmall 12): one TextLabel whose Position and TextSize are two animated derivations of
	`floated = focused or non-empty` (Motion Short4/Standard).

	OUTLINED NOTCH (a field with a label): the outline is CUT where the label floats — nothing is painted over it, so the
	field can sit on any backdrop (a photo, a tinted surface). Canon: Compose `OutlinedTextField.kt` `Modifier.outlineCutout`
	(androidx-main: `clipRect(left, .., right, .., ClipOp.Difference)` around the border, `left = label x - 4.dp`,
	`right = label x + label width + 4.dp`, `OutlinedTextFieldInnerPadding = 4.dp`; the floated label's x is the start
	content padding, `TextFieldPadding` 16.dp — also behind a leading icon — and its vertical center is the container's top
	edge, `internal/TextFieldImpl.kt` `endY = -(label height / 2)`); MDC `TextInputLayout.openCutout` / `CutoutDrawable`.
	The engine has no "difference" clip, so the outline is drawn THREE times, each copy (a transparent Frame + UICorner +
	UIStroke, `BorderStrokePosition = Inner`: the border is inside the 56 px like Compose's, 1 -> 2 px grows inward) inside
	its own `ClipsDescendants` window (Studio 2026-10-13: a clipping Frame cuts a descendant's UIStroke cleanly at its
	edge):
	    OutlineBottom   everything below the top band (y >= Band): both sides and the bottom line. Its box is the field's
	                    own rectangle.
	    OutlineStart    the band left of the cut (x < 12): the top-left corner. Static.
	    OutlineEnd      the band right of the cut: the top line and the top-right corner. Anchored to the field's RIGHT
	                    edge; only its WIDTH changes (rest: it starts at 12 and meets OutlineStart — the line is whole;
	                    floated: it starts at 16 + label width + 4).
	The boxes never move and never resize: each is anchored in its window to an edge that does not move (OutlineEnd's box to
	the window's right edge, which is the field's), so opening the notch tweens ONE Size and the line cannot shiver. The two
	band boxes are not the field's size — only their visible corner matters: OutlineStart's is 32 x 32, OutlineEnd's is
	`BoxSpan` wide (its left end is always outside its window; a field wider than `BoxSpan` would show it — not a real
	field). The windows reach `Margin` px outside the field so a fractional clip edge (an ancestor UIScale) never shaves
	the outline's outer pixel row. The seam between the band and OutlineBottom is at y = Band, below the corner arcs, where
	both sides are straight.
	The label's floated width is MEASURED (`AbsoluteSize` in local units, `Ripple.localScale`): exact while the label sits
	floated (TextSize 12), estimated as `width * 12 / 16` while it rests (within 1 px), ignored while the TextSize tween
	runs; rounded up to a whole unit (a UDim Offset is an integer). Until the first measurement the notch snaps instead of animating, and a field that is BORN floated
	(created with a value) hides OutlineEnd until then, so no frame shows the line through the label.
	A label WIDER than the field: the cut is held at the field's right edge (the UISizeConstraint in OutlineEnd); the
	label itself still overflows the field (canon constrains the label to the field's inner width — not done here).
	Deviation (mid-tween frames only): the cut is `(label width + 8) x progress` — it opens from nothing. Compose's is
	`label width x progress + 8` (8 px wide from the first frame, gone on the last), MDC's opens whole at once.
	A field WITHOUT a label has no notch: one UICorner + UIStroke on the container, as before.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Util = require("../Util")
local Ripple = require("../Ripple")
local StateLayer = require("../StateLayer")
local Style = require("../Button/Style")
local Text = require("../Text")
local Ctx = require("./Ctx")
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"
local UISizeConstraint = q.Elem "UISizeConstraint"
local UIStroke = q.Elem "UIStroke"

local Corner = Tokens.Shape.corner("ExtraSmall")
local DisabledOutlineTransparency = 1 - Tokens.State.Opacity.DisabledContainer
local DisabledIndicatorTransparency = 1 - Tokens.State.Opacity.DisabledContent
local DisabledFillTransparency = 0.96 -- M3: disabled filled container = onSurface @ 4 %

local RestSize = 16 -- BodyLarge
local FloatedSize = 12 -- BodySmall
-- Outlined notch (local units; see the header)
local FloatX = 16 -- the floated label's x: the start content padding (TextFieldPadding)
local CutPad = 4 -- OutlinedTextFieldInnerPadding: the cut reaches this far past the label on both sides
local CutStart = FloatX - CutPad
local FloatY = -FloatedSize // 2 -- the floated label's 12 px box centered on the container's top edge
local Band = 2 * Corner.Offset -- the top band the two upper windows cover (below the corner arcs)
local Margin = 2 -- how far the windows reach outside the field
local BoxSpan = 4096 -- OutlineEnd's box width

local bodyLarge = Text.Label("BodyLarge")
local motion = Tokens.Motion.options("Short4", "Standard")

-- what the label measured for the notch (Outlined with a label)
export type Notch = {
	Width: q.Source<number>, -- the FLOATED label's width, local units (0 until measured / for an empty label)
	Measured: q.Source<boolean>,
}

-- label -> Notch: see "MEASURED" in the header
local function measure(notch: Notch)
	return Util.preHook(function(inst: GuiObject)
		local lab = inst :: TextLabel
		lab:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local k = Ripple.localScale(lab)
			local w = if k > 0 then lab.AbsoluteSize.X / k else lab.AbsoluteSize.X
			local size = lab.TextSize
			if size == RestSize then
				w *= FloatedSize / RestSize
			elseif size ~= FloatedSize then
				return -- the TextSize tween is running: the box is between the two sizes
			end
			-- whole units, rounded up: a UDim Offset is an integer (the engine truncates a fraction), and a cut that is a
			-- fraction short would leave less than CutPad after the label
			notch.Width:SetIfChanged(math.ceil(w - 1e-3))
			if w > 0 then
				notch.Measured:SetIfChanged(true) -- after the width: the write above still snapped
			end
		end)
	end)
end

-- returns the label and, for an Outlined field, what it measures for the notch
local function label(c: Ctx.Ctx, inset: number): (Instance?, Notch?)
	local props = c.Props
	if not c.HasLabel then
		return nil, nil
	end
	local filled = c.Filled
	local floated = c.Floated
	-- resting label: its 16 px text box centered on the container (a single-line field) or on the first line (multi-line,
	-- whose text starts 16 px down). The label's LineHeight is forced to 1 (below), so its auto-sized box IS the text size
	-- and these offsets do not depend on how the engine spreads BodyLarge's 1.5 line height around one line. (The first
	-- version put the resting label at y = 16, assuming a 24 px line box; the auto-sized box was the 16 px text, so the
	-- label sat 4 px above the container's center — Studio QA 2026-10-07.)
	local restY = if c.Multi then 16 else c.Height // 2 - 8
	local labelPos: q.State<UDim2> = floated:Compute(function(self)
		if not self:Get() then
			return UDim2.fromOffset(inset, restY)
		end
		return if filled then UDim2.fromOffset(inset, 7) else UDim2.fromOffset(FloatX, FloatY)
	end)
	local labelSize: q.State<number> = floated:Compute(function(self)
		return if self:Get() then FloatedSize else RestSize
	end)
	local text = Util.asStringState(props.Label)
	local notch: Notch? = nil
	if not filled then
		-- an empty label has nothing to measure (and nothing to cut)
		notch = { Width = q.Source(0), Measured = q.Source(text:Get() == "") }
	end
	return TextLabel {
		Name = "Label",
		bodyLarge,
		if notch ~= nil then measure(notch) else q.None,
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Position = labelPos:Apply(Style.animation()),
		TextSize = labelSize:Apply(Style.animation()),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LineHeight = 1, -- one line: the box is exactly the text size (see restY)
		Text = text,
		TextColor3 = c.Colors.Label,
		TextTransparency = c.ContentTransparency,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = false,
	},
		notch
end

export type Seats = {
	Hook: any, -- the Interaction hook (array part)
	Selectable: (boolean | q.State<boolean>)?,
	Row: Instance,
	Label: Instance?,
	Notch: Notch?, -- from `label` (Outlined with a label)
	Leading: Instance?,
	Trailing: Instance?,
	ErrorMark: Instance?,
}

type StrokeLook = { Thickness: any, Color: any, Transparency: any }

local function outlineStroke(look: StrokeLook): Instance
	return UIStroke {
		Name = "Outline",
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = look.Thickness,
		Color = look.Color,
		Transparency = look.Transparency,
	}
end

-- one copy of the outline (see the header): a transparent rounded Frame with the stroke
local function outlineBox(look: StrokeLook, anchor: Vector2, position: UDim2, size: UDim2): Instance
	return Frame {
		Name = "Box",
		AnchorPoint = anchor,
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UICorner = Corner,
		outlineStroke(look),
	}
end

-- the three clip windows of the notched outline (see OUTLINED NOTCH in the header)
local function notchedOutline(c: Ctx.Ctx, notch: Notch, look: StrokeLook): (Instance, Instance, Instance)
	local height = c.Height
	local floated = c.Floated
	local topLeft = Vector2.new(0, 0)
	-- OutlineEnd starts at `start` (field x): the cut's right end while floated, the cut's left end (no cut) otherwise
	local endSize: q.State<UDim2> = floated:Compute(function(self, _prev, w)
		local lw: number = w:Get()
		local start = if self:Get() and lw > 0 then FloatX + lw + CutPad else CutStart
		return UDim2.new(1, Margin - start, 0, Margin + Band)
	end, notch.Width)
	-- born floated and not measured yet: no line through the label for a frame
	local endVisible: q.State<boolean> = floated:Compute(function(self, _prev, m)
		return m:Get() or not self:Get()
	end, notch.Measured)
	local bottom = Frame {
		Name = "OutlineBottom",
		Position = UDim2.fromOffset(-Margin, Band),
		Size = UDim2.new(1, 2 * Margin, 0, height - Band + Margin),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		outlineBox(look, topLeft, UDim2.fromOffset(Margin, -Band), UDim2.new(1, -2 * Margin, 0, height)),
	}
	local startWindow = Frame {
		Name = "OutlineStart",
		Position = UDim2.fromOffset(-Margin, -Margin),
		Size = UDim2.fromOffset(Margin + CutStart, Margin + Band),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		outlineBox(look, topLeft, UDim2.fromOffset(Margin, Margin), UDim2.fromOffset(32, 32)),
	}
	local endWindow = Frame {
		Name = "OutlineEnd",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, Margin, 0, -Margin),
		Size = endSize:Apply(q.Animate({
			Time = motion.Time,
			Style = motion.Style,
			Direction = motion.Direction,
			CanAnimate = notch.Measured,
		})),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = endVisible,
		-- a label wider than the field: the window's width would go negative (a negative-size window draws mirrored,
		-- past the field's right edge — Studio 2026-10-13). A UISizeConstraint holds it at 0: the cut then reaches the
		-- field's right edge, as Compose's does (`right.coerceAtMost(size.width)`).
		UISizeConstraint {},
		outlineBox(look, Vector2.new(1, 0), UDim2.new(1, -Margin, 0, Margin), UDim2.fromOffset(BoxSpan, 32)),
	}
	return bottom, startWindow, endWindow
end

local function container(c: Ctx.Ctx, seats: Seats): Frame
	local R = c.Theme.Raw
	local disabled = c.Disabled
	local height = c.Height
	local filled = c.Filled
	local thickness: q.State<number> = c.Focused:Compute(function(self)
		return if self:Get() then 2 else 1
	end)
	local fillColor = Style.disabledPick(disabled, R.SurfaceContainerHighest, R.OnSurface)
	local fillTransparency = Style.disabledNumber(disabled, 0, DisabledFillTransparency)

	local layer: Instance? = nil
	local indicator: Instance? = nil
	-- Outlined: either ONE stroke on the container (no label) or the three windows of the notched outline
	local stroke: Instance? = nil
	local outlineBottom: Instance?, outlineStart: Instance?, outlineEnd: Instance? = nil, nil, nil
	if filled then
		layer = StateLayer.new({
			Color = c.Theme.Color.OnSurface,
			Corner = Corner,
			Hovered = c.Hovered,
			Pressed = q.Source(false),
			Focused = q.Source(false),
			Disabled = disabled,
		})
		local indicatorHeight: q.State<UDim2> = thickness:Compute(function(self)
			return UDim2.new(1, 0, 0, self:Get())
		end)
		indicator = Frame {
			Name = "Indicator",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = indicatorHeight:Apply(Style.animation()),
			BackgroundColor3 = c.Colors.Line,
			BackgroundTransparency = Style.disabledNumber(disabled, 0, DisabledIndicatorTransparency),
			BorderSizePixel = 0,
		}
	else
		-- one animated State each, shared by every copy of the outline
		local look: StrokeLook = {
			Thickness = thickness:Apply(Style.animation()),
			Color = c.Colors.Line,
			Transparency = Style.disabledNumber(disabled, 0, DisabledOutlineTransparency),
		}
		local notch = seats.Notch
		if notch ~= nil then
			outlineBottom, outlineStart, outlineEnd = notchedOutline(c, notch, look)
		else
			stroke = outlineStroke(look)
		end
	end

	-- Filled: M3 rounds only the TOP corners. UICorner rounds all four, so the rounded fill is drawn Corner px taller than
	-- its clipping parent (the Container) and the rounded bottom is cut away (the Tabs indicator trick). The state layer
	-- lives inside the fill so it is cut the same way. Outlined without a label keeps one UICorner + UIStroke on the
	-- Container itself; with a label the Container draws nothing (the outline copies carry their own corners).
	local fill: Instance? = nil
	if filled then
		fill = Frame {
			Name = "Fill",
			Size = UDim2.new(1, 0, 0, height + Corner.Offset),
			BackgroundColor3 = fillColor,
			BackgroundTransparency = fillTransparency,
			BorderSizePixel = 0,
			UICorner = Corner,
			layer or q.None,
		}
	end
	return Frame {
		Name = "Container",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = filled,
		LayoutOrder = 1,
		Selectable = seats.Selectable,
		seats.Hook,
		UICorner = if stroke ~= nil then Corner else nil,
		stroke or q.None,
		outlineBottom or q.None,
		outlineStart or q.None,
		outlineEnd or q.None,
		fill or q.None,
		indicator or q.None,
		seats.Row,
		seats.Label or q.None,
		seats.Leading or q.None,
		seats.Trailing or q.None,
		seats.ErrorMark or q.None,
	}
end

return { label = label, container = container }
