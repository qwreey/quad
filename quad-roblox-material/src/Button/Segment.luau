--!strict
--[[
	Internal to the kit: ONE cell of a row of connected buttons — a half of `SplitButton` (`./Split.luau`), a cell of
	`ButtonGroup` (`./Group.luau`). A cell is a pill whose corners on the side(s) facing a neighbour are small and morph
	(rest -> pressed, -> selected), exactly Compose's `shapeByInteraction` (SplitButton.kt / ToggleButton.kt: pressed wins
	over selected, selected over rest). The two callers differ in tokens and in what "selected" paints (Split: an overlay;
	the group: the container and content colors themselves), so the COLORS arrive computed — this module draws.

	    Segment.new({ Name = "Leading", Side = "Leading", ..., Content = { label }, Pad = { 16, 12 } }) -> TextButton

	Options
	  Name, LayoutOrder        the cell host (a TextButton)
	  Side                     "Leading" (outer side at the start) | "Trailing" (outer side at the end) | "Middle" (no
	                           outer side: all four corners are inner corners)
	  Theme, Disabled          Disabled: State<boolean> — no input, no state layer (the disabled COLORS are the caller's)
	  Selected                 State<boolean>? — only the SHAPE reads it here (inner corners -> InnerSelected)
	  Height, Between, MinWidth, Outer, Inner, InnerPressed, InnerSelected   px (Between: the gap to a neighbour)
	  Width                    State<number>? — the cell's width in local px when > 0 (a group that shares a fixed width);
	                           nil or 0 = max(MinWidth, the content's measured width)
	  ContainerColor           the faces' BackgroundColor3 (nil = none), ContainerTransparency (nil = opaque with a color,
	                           1 without)
	  ContentColor             the state layers' and ripples' color (the content's own color is set by the caller on the
	                           instances it passes in `Content`)
	  Stroke                   { Color, Transparency }? — a 1 px INNER outline on every face
	  Shadow                   number? — the rest elevation level (+1 hovered, 0 disabled): a UIShadow on every face
	  Overlay                  State<number>? — the transparency of a ContentColor overlay on every face (Split's Selected)
	  Content, Pad             children of the content frame after its UIPadding; left / right padding
	  Optical                  shift the content by Compose's optical centering (HorizontalCenterOptically.kt)
	  OnClick

	ASYMMETRIC SHAPE (a UICorner has ONE radius): a Leading / Trailing cell draws its container as two FACES, both the
	cell's full rectangle, one rounded `Outer` and one rounded at the inner radius, each inside a rectangle clip that
	shows only its own side (outer side [0, W/2] of a leading cell, inner side [W/2, W]; mirrored for a trailing cell) —
	the same composition as the M3 slider track (`../Slider/Track.luau` "ASYMMETRIC ROUNDING"), so a translucent
	(disabled) container has no seam. Each face carries its own state layer and its own ripple (`Ripple.luau`) with the
	face's corner: the two ripples start at the same press point in the same full-rectangle geometry, so the visible
	halves of the two discs meet exactly at the clip line. The outline is a 1 px Inner UIStroke on each face (an outer
	stroke would be cut by the clips). A MIDDLE cell has one radius on all four corners: ONE face, no clip (unless it
	casts a shadow — below).
	ELEVATED SHADOW: each FACE carries its own UIShadow (`Elevation.Shadow`), so each cell casts the shadow of its own
	shape (a UIShadow follows its parent's one UICorner, so the two faces give the two radii) and the two shadows of a
	cell meet at the split line like the faces do. For that the clips of a shadowed cell are OPEN: by the shadow's reach
	(2 x blur + spread + y-offset of the hovered level = 15) above, below and on an outer side, and by the `Between` gap
	on a side that faces a neighbour (further in, the shadow would be drawn over the neighbour's container); the faces
	sit at the same place as before. A shadowed Middle cell gets one such clip (open by the gap on both sides). Cells
	without a shadow keep the clips at the cell's rectangle. (Engine facts, Studio 2026-10-13: a UIShadow is drawn for a
	transparent parent too, as a FILLED shape; ClipsDescendants of an ancestor cuts a UIShadow.)
	Every size that feeds the layout below the row is Offset (no Scale fraction under an auto-sized ancestor —
	`Ripple.luau` "NOT SCALE"; the overlay is a full-cover Scale leaf under an Offset-sized face, which is fine): the
	cell's width is read from the content frame's AbsoluteSize in local units (divided by the UIScale product,
	`Ripple.localScale`); the cell is not auto-sized itself.

	Structure: TextButton > [OuterClip > Face (UICorner, StateLayer > UICorner), InnerClip > Face (same)] or
	[Face] / [Clip > Face] for a Middle cell, FocusRing (Frame + UICorner + UIStroke), Content (UIPadding + ...).
	The focus ring is one rounded rectangle: at `Outer` for a Leading / Trailing cell (its inner corners are rounder in
	the ring than in the shape), at the animated inner radius for a Middle cell.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Interaction = require("../Interaction")
local Interactive = require("../Interactive")
local Ripple = require("../Ripple")
local StateLayer = require("../StateLayer")
local Elevation = require("../Elevation")
local Style = require("./Style")
local D = q.Declaration

export type Side = "Leading" | "Trailing" | "Middle"

export type Stroke = { Color: Theme.Animated, Transparency: Theme.Animated }

export type Options = {
	Name: string,
	Side: Side,
	LayoutOrder: number,
	Theme: Theme.Theme,
	Disabled: q.State<boolean>,
	Selected: q.State<boolean>?,
	Height: number,
	Between: number,
	MinWidth: number,
	Outer: number,
	Inner: number,
	InnerPressed: number,
	InnerSelected: number,
	Width: q.State<number>?,
	ContainerColor: Theme.Animated?,
	ContainerTransparency: Theme.Animated?,
	ContentColor: Theme.Animated,
	Stroke: Stroke?,
	Shadow: number?,
	Overlay: q.State<number>?,
	Content: { Instance },
	Pad: { number },
	Optical: boolean,
	OnClick: (() -> ())?,
}

local OPTICAL = 0.11 -- CenterOpticallyCoefficient

type From = "Start" | "Split" | "All"

local function animation()
	return q.Animate(Tokens.Motion.options("Short4", "Standard"))
end

local function new(o: Options): TextButton
	local theme, disabled = o.Theme, o.Disabled
	local side = o.Side
	local leading = side == "Leading"
	local middle = side == "Middle"
	local height, outer, between = o.Height, o.Outer, o.Between
	local contentColor = o.ContentColor
	local fixedWidth = o.Width

	-- the measured content width (local units) -> the cell's width
	local contentWidth = q.Source(0)
	-- false until the content has been measured once: the first layout places the content, it does not slide it there
	local measured = q.Source(false)
	local measure = Util.preHook(function(inst: GuiObject)
		local function read()
			local k = Ripple.localScale(inst)
			contentWidth:SetIfChanged(if k > 0 then inst.AbsoluteSize.X / k else inst.AbsoluteSize.X)
			if inst.AbsoluteSize.X > 0 then
				measured:SetIfChanged(true) -- after the width: the write above still snapped
			end
		end
		read()
		inst:GetPropertyChangedSignal("AbsoluteSize"):Connect(read)
	end)
	local minWidth = o.MinWidth
	-- a shared fixed width wins when it is known (> 0); `noFixed` stands in when the caller gave none
	local noFixed: q.State<number> = q.Source(0)
	local width: q.State<number> = contentWidth:Compute(function(self, _prev, fixed)
		local f: number = fixed:Get()
		if f > 0 then
			return f
		end
		return math.max(minWidth, math.ceil(self:Get() - 1e-3))
	end, fixedWidth or noFixed)

	local pressedSrc = q.Source(false)
	local selected = o.Selected
	-- the inner radius now (pressed > selected > rest) and its animated form
	local innerTarget: q.State<number> = pressedSrc:Compute(function(self, _prev, sel)
		if self:Get() then
			return o.InnerPressed
		end
		return if sel:Get() then o.InnerSelected else o.Inner
	end, selected or q.Source(false))
	local innerCornerRaw: q.State<UDim> = innerTarget:Compute(function(self)
		return UDim.new(0, self:Get())
	end)
	local innerCorner = innerCornerRaw:Apply(animation())
	local rippleOuter: Ripple.Ripple? = if middle then nil else Ripple.new({ Color = contentColor, Corner = UDim.new(0, outer) })
	local rippleInner = Ripple.new({ Color = contentColor, Corner = innerCorner })

	local ix = Interaction.new({
		Disabled = disabled,
		OnHost = function(inst: GuiObject)
			inst.SelectionImageObject = Interactive.noSelectionImage()
		end,
		OnPressBegan = function(position: Vector2?)
			pressedSrc:Set(true)
			if rippleOuter then
				rippleOuter:Press(position)
			end
			rippleInner:Press(position)
		end,
		OnPressEnded = function(_cancelled: boolean)
			pressedSrc:Set(false)
			if rippleOuter then
				rippleOuter:Release()
			end
			rippleInner:Release()
		end,
	})

	local containerColor = o.ContainerColor
	local containerT = o.ContainerTransparency
	local overlayT = o.Overlay

	local faceSize: q.State<UDim2> = width:Compute(function(self)
		return UDim2.fromOffset(self:Get(), height)
	end)
	-- the split line between the two clips
	local function splitAt(w: number): number
		return math.floor(w / 2)
	end

	-- Shadow (header "ELEVATED SHADOW"): the level of this cell (rest, + 1 hovered, 0 disabled) and how far its clips
	-- open for the shadow. 0 = no shadow: the clips are the cell's rectangle.
	local shadowLevel: q.State<number>? = nil
	local reach = 0
	local restLevel = o.Shadow
	if restLevel ~= nil then
		local rest = restLevel
		shadowLevel = ix.Hovered:Compute(function(self, _prev, dis)
			if dis:Get() then
				return 0
			end
			return if self:Get() then rest + 1 else rest
		end, disabled)
		local highest = Tokens.Elevation.levelOf(rest + 1)
		reach = 2 * highest.BlurRadius + highest.Spread + math.abs(highest.OffsetY)
	end
	local openInner = math.min(reach, between)
	-- a clip's left edge and width in the cell's coordinates: its side of the split line (or the whole cell), opened by
	-- `reach` on an outer side and by the gap on a side that faces a neighbour
	local function clipSpan(w: number, from: From): (number, number)
		if from == "All" then
			return 0 - openInner, w + 2 * openInner
		end
		local m = splitAt(w)
		local outerSide = (from == "Start") == leading
		local open = if outerSide then reach else openInner
		if from == "Start" then
			return 0 - open, m + open
		end
		return m, w - m + open
	end

	local function face(name: string, corner: UDim | Theme.Animated, ripple: Ripple.Ripple, clipFrom: From): Frame
		local stroke: Instance? = nil
		local strokeSpec = o.Stroke
		if strokeSpec ~= nil then
			stroke = D.UIStroke {
				Name = "Outline",
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				BorderStrokePosition = Enum.BorderStrokePosition.Inner,
				Thickness = 1,
				Color = strokeSpec.Color,
				Transparency = strokeSpec.Transparency,
			}
		end
		local overlay: Instance? = nil
		local ot = overlayT
		if ot ~= nil then
			overlay = D.Frame {
				Name = "Selected",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = contentColor,
				BackgroundTransparency = ot:Apply(Style.animation()),
				BorderSizePixel = 0,
				UICorner = corner,
			}
		end
		local level = shadowLevel
		local shadow: Instance? = if level ~= nil then Elevation.Shadow({ Level = level, Theme = theme }) else nil
		-- the face is the cell's full rectangle: shifted back by its clip's origin
		local clipped = clipFrom ~= "All" or reach > 0
		local position: q.State<UDim2> = width:Compute(function(self)
			if not clipped then
				return UDim2.fromOffset(0, 0)
			end
			local x0 = clipSpan(self:Get(), clipFrom)
			return UDim2.fromOffset(0 - x0, reach)
		end)
		return D.Frame {
			Name = name,
			Position = position,
			Size = faceSize,
			BackgroundColor3 = containerColor,
			BackgroundTransparency = containerT or (if containerColor ~= nil then 0 else 1),
			BorderSizePixel = 0,
			UICorner = corner,
			shadow or q.None,
			stroke or q.None,
			StateLayer.new({
				Color = contentColor,
				Corner = corner,
				Hovered = ix.Hovered,
				Pressed = ix.Pressed,
				Focused = ix.Focused,
				Disabled = disabled,
				Ripple = ripple,
			}),
			overlay or q.None,
		}
	end

	local function clip(name: string, from: From, child: Frame): Frame
		local position: q.State<UDim2> = width:Compute(function(self)
			local x0 = clipSpan(self:Get(), from)
			return UDim2.fromOffset(x0, 0 - reach)
		end)
		local size: q.State<UDim2> = width:Compute(function(self)
			local _x0, span = clipSpan(self:Get(), from)
			return UDim2.fromOffset(span, height + 2 * reach)
		end)
		return D.Frame {
			Name = name,
			Position = position,
			Size = size,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			child,
		}
	end

	local first: Instance
	local second: Instance? = nil
	if rippleOuter ~= nil then
		-- leading: outer side first (left), inner side at the split; trailing: inner side first, outer at the split
		local outerFrom: From = if leading then "Start" else "Split"
		local innerFrom: From = if leading then "Split" else "Start"
		first = clip("OuterClip", outerFrom, face("Face", UDim.new(0, outer), rippleOuter, outerFrom))
		second = clip("InnerClip", innerFrom, face("Face", innerCorner, rippleInner, innerFrom))
	else
		local only = face("Face", innerCorner, rippleInner, "All")
		first = if reach > 0 then clip("Clip", "All", only) else only
	end

	local ringOn: q.State<boolean> = ix.Focused:Compute(function(self, _prev, dis)
		return self:Get() and not dis:Get()
	end, disabled)
	local ring = D.Frame {
		Name = "FocusRing",
		Size = faceSize,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		UICorner = if middle then innerCorner else UDim.new(0, outer),
		D.UIStroke {
			Name = "Ring",
			Color = theme.Color.Secondary,
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			BorderStrokePosition = Enum.BorderStrokePosition.Outer,
			BorderOffset = UDim.new(0, 2),
			Enabled = ringOn,
		},
	}

	-- content: centered in the cell (it is narrower than the cell at the minimum width, or in a fixed width), plus the
	-- optical shift
	local contentPosition: q.State<UDim2> = width:Compute(function(self, _prev, cw, inner)
		local shift = if o.Optical then math.floor(OPTICAL * (inner:Get() - outer) + 0.5) else 0
		return UDim2.fromOffset(math.floor((self:Get() - cw:Get()) / 2) + shift, 0)
	end, contentWidth, innerTarget)
	local contentMotion = Tokens.Motion.options("Short4", "Standard")
	local content = D.Frame {
		Name = "Content",
		measure,
		-- a shared fixed width follows its container (a window being resized): the content is placed, not slid
		Position = if fixedWidth ~= nil
			then contentPosition
			else contentPosition:Apply(q.Animate({
				Time = contentMotion.Time,
				Style = contentMotion.Style,
				Direction = contentMotion.Direction,
				CanAnimate = measured,
			})),
		Size = UDim2.fromOffset(0, height),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIPadding { PaddingLeft = UDim.new(0, o.Pad[1]), PaddingRight = UDim.new(0, o.Pad[2]) },
		table.unpack(o.Content),
	}

	local host = D.TextButton {
		Name = o.Name,
		Size = faceSize,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = o.LayoutOrder,
		ix.Hook,
		Interactable = Util.interactable(disabled),
		Activated = function()
			if o.OnClick and not disabled:Get() then
				o.OnClick()
			end
		end,
		first,
		second or q.None,
		ring,
		content,
	}
	return host
end

return {
	new = new,
}
