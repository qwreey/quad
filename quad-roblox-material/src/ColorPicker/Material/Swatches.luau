--!strict
--[[
	Swatch rows: the PRESETS (`Swatches`, static — known at construction) and the RECENT colors
	(`model.recent`, a Source the caller may own to persist it).

	One swatch = ONE `ImageButton` (circle, `UICorner`; its own image is the selected check — the `Icons` check image, or
	a `TextButton` whose text is the check glyph when that image is overridden away) + ONE `UIStroke`: no state layer, no
	ripple. The stroke IS the
	state: selected (the swatch equals the current color, compared as 8-bit bytes) 3 px Primary; focused (gamepad /
	keyboard selection) 3 px Secondary; hovered 2 px Outline; idle 1 px OutlineVariant — thickness and color are
	animated Computes of three States. A click does `model.setColor(color)` (hue-preserving) and `model.remember()`.
	That is 3 instances per swatch instead of the 6 a kit-standard `Interactive` button would cost.

	The recent row is the one dynamic part, so it is a `Slot:List` keyed by the color's hex string: a color that
	moves to the front of the list keeps its swatch (the update function returns `ctx.Prev`), and at rest with no
	recents the row owns zero instances. Presets and recents wrap (`UIListLayout.Wraps`), rows grow
	(`AutomaticSize.Y`).

	Instances at rest: container + layout, [label + wrapping row (+layout) + 3 per preset] (+ the recent label and row,
	which exist but are hidden while the list is empty).
	M3 deviations: 32 px swatches (M3 asks 48 px touch targets for chips; the 8 px gap and a Preset count of 8 keep
	them reachable, but this is denser than spec); the engine's default selection box is replaced by the stroke.
]]

local q = require("../../Quad")
local Tokens = require("../../Tokens")
local Theme = require("../../Theme")
local Interaction = require("../../Interaction")
local Style = require("../../Button/Style")
local Text = require("../../Text")
local Icons = require("../../Icons")
local ColorModel = require("../ColorModel")
local Model = require("./Model")
local D = q.Declaration

export type Props = {
	read Model: Model.Model,
	read Theme: Theme.Theme?,
	read Swatches: { Color3 }?,
	read LayoutOrder: number?,
}

local labelStyle = Text.Label("LabelMedium")

-- a small, friendly default set: the M3 baseline hues plus black / white
local Defaults: { Color3 } = {
	Color3.fromRGB(0xB3, 0x26, 0x1E),
	Color3.fromRGB(0xE6, 0x7E, 0x22),
	Color3.fromRGB(0xF9, 0xC7, 0x2D),
	Color3.fromRGB(0x2E, 0x7D, 0x32),
	Color3.fromRGB(0x00, 0x7C, 0x91),
	Color3.fromRGB(0x67, 0x50, 0xA4),
	Color3.fromRGB(0x21, 0x21, 0x21),
	Color3.fromRGB(0xFF, 0xFF, 0xFF),
}

local SIZE = 32
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

local function hexKey(c: Color3): string
	return ColorModel.rgbToHex(c.R, c.G, c.B, true)
end

local function swatch(model: Model.Model, theme: Theme.Theme, color: Color3, order: q.State<number>?): GuiButton
	local R = theme.Raw
	local bytes = Color3.fromRGB(ColorModel.toByte(color.R), ColorModel.toByte(color.G), ColorModel.toByte(color.B))
	local selected: q.State<boolean> = model.color:Compute(function(self)
		return Model.sameBytes(self:Get(), bytes)
	end)
	local ix = Interaction.new()
	local thickness: q.State<number> = selected:Compute(function(self, _prev, hovered, focused)
		if self:Get() or focused:Get() then
			return 3
		end
		return if hovered:Get() then 2 else 1
	end, ix.Hovered, ix.Focused)
	local picked: q.State<Color3> = selected:Compute(function(self, _prev, hovered, focused, primary, secondary, outline, variant)
		if self:Get() then
			return primary:Get()
		elseif focused:Get() then
			return secondary:Get()
		elseif hovered:Get() then
			return outline:Get()
		end
		return variant:Get()
	end, ix.Hovered, ix.Focused, R.Primary, R.Secondary, R.Outline, R.OutlineVariant)
	-- the selected swatch shows a check ON the swatch itself (the button's own image / text: no extra instance) so the
	-- selection is not carried by the ring color alone; the check contrasts with the swatch (luminance split)
	local contrast = if 0.299 * color.R + 0.587 * color.G + 0.114 * color.B > 0.55 then BLACK else WHITE
	local function activated()
		model.setColor(color)
		model.remember()
	end
	local ring = D.UIStroke {
		Name = "Ring",
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = thickness:Apply(Style.animation()),
		Color = picked:Apply(Style.animation()),
	}
	local checkAsset = Icons.asset("check")
	if checkAsset ~= nil then
		-- the Material check image (Icons default) fitted to the 32 px circle: its 24 dp grid keeps the ink in the middle
		-- ~3/4 (about 23 px), inside the round corner
		local checkTransparency: q.State<number> = selected:Compute(function(self)
			return if self:Get() then 0 else 1
		end)
		return D.ImageButton {
			Name = "Swatch",
			ix.Hook,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(SIZE, SIZE),
			LayoutOrder = order or 0,
			BackgroundColor3 = color,
			Image = checkAsset,
			ScaleType = Enum.ScaleType.Fit,
			ImageColor3 = contrast,
			ImageTransparency = checkTransparency,
			UICorner = Tokens.Shape.corner("Full"),
			Activated = activated,
			ring,
		}
	end
	-- glyph fallback (the check image overridden away — Icons.luau)
	local selectedText: q.State<string> = selected:Compute(function(self)
		return if self:Get() then Icons.glyph("check") else ""
	end)
	return D.TextButton {
		Name = "Swatch",
		ix.Hook,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(SIZE, SIZE),
		LayoutOrder = order or 0,
		BackgroundColor3 = color,
		Text = selectedText,
		TextSize = 18,
		TextColor3 = contrast,
		UICorner = Tokens.Shape.corner("Full"),
		Activated = activated,
		ring,
	}
end

type RecentCtx = {
	Item: Color3 | q.KeyGone,
	Index: number,
	Offset: q.State<number>,
	Prev: q.SlotItem<Instance>?,
	UserData: q.Source<number>?,
}

local function Swatches(props: Props)
	local model = props.Model
	local theme = Theme.resolve(props.Theme)
	local presets = props.Swatches or Defaults

	local presetSwatches: { Instance } = {}
	for _, c in presets do
		table.insert(presetSwatches, swatch(model, theme, c))
	end

	local recentSlot = q.Slot<<Instance>>()
	recentSlot:List(model.recent, function(ctx: RecentCtx): (any, q.Source<number>?)
		if ctx.Item == q.KeyGone then
			return nil, nil
		end
		local prev, order = ctx.Prev, ctx.UserData
		if prev ~= nil and order ~= nil then
			order:SetIfChanged(ctx.Index) -- the list order is expressed through LayoutOrder (no physical reordering)
			return prev, order
		end
		local orderSrc = q.Source(ctx.Index)
		return swatch(model, theme, ctx.Item :: Color3, orderSrc), orderSrc
	end, function(c: Color3): string
		return hexKey(c)
	end)
	local hasRecent: q.State<boolean> = model.recent:Compute(function(self)
		return #self:Get() > 0
	end)

	local function label(text: string, order: number, visible: (q.State<boolean>)?)
		return D.TextLabel {
			Name = `{text}Label`,
			labelStyle,
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = text,
			TextColor3 = theme.Color.OnSurfaceVariant,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = order,
			Visible = visible or true,
		}
	end
	local function wrap(name: string, order: number, visible: (q.State<boolean>)?, content: q.Slot<Instance>)
		return D.Frame {
			Name = name,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = order,
			Visible = visible or true,
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				Wraps = true,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			},
			content,
		}
	end

	return D.Frame {
		Name = "Swatches",
		LayoutOrder = props.LayoutOrder or 0,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		},
		label("Swatches", 1),
		wrap("Presets", 2, nil, q.Slot<<Instance>>(presetSwatches)),
		label("Recent", 3, hasRecent),
		wrap("Recent", 4, hasRecent, recentSlot),
	}
end

return {
	Swatches = Swatches,
	Defaults = Defaults,
}
