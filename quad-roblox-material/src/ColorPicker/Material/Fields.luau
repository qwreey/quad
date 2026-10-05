--!strict
--[[
	Channel editing: a two-segment toggle (RGB | HSV) and three compact number boxes whose labels, texts and ranges
	follow the mode. RGB = bytes 0..255; HSV = degrees 0..360 / percent 0..100 (`ColorModel.Scale.Degrees`).

	A box needs no hand synchronization (the idea of the Classic port's EditBox, restyled):
	  shown text = focused ? buffer : model text            (a Compute of three things)
	  buffer     = what the engine currently holds           (`q.OnChange("Text")` echo)
	  typing     -> buffer, and when the text parses AND differs from what the model shows, `model.typeField` commits it
	                LIVE (invalid or empty text is simply not committed)
	  FocusLost  -> final commit of an edited buffer, `model.remember()`, then `focused = false`: the box flips back to
	                the model's text, so an invalid / empty entry reverts and a clamped one shows its clamp.
	"Differs from the model text" stops the echo of the model's own rounded display (H = 0.4812 shown as "173") from
	being parsed back and quantizing the color.
	Keys: Tab (the `\t` character a TextBox receives) moves focus box 1 -> 2 -> 3 -> 1; the mouse wheel is +-1.
	The toggle's selection state lives in `model.mode` (a Source), so the labels and ranges are Computes of it.

	Instances at rest: wrapper (+UIListLayout) = 2; toggle host (+UICorner, UIStroke) + 2 x TextButton (+UICorner) = 7;
	row (+UIListLayout) + 3 x [box Frame (+UICorner, UIStroke, UIFlexItem) + label + TextBox] = 20 -> 29 total.
	M3 deviations: dense 40 px fields (M3 text fields are 56 px; the kit's own TextField is used for hex);
	toggle segments show hover/focus as a tinted background instead of a separate state-layer instance and rely on the
	engine's default selection box for gamepad focus.
]]

local q = require("../../Quad")
local Tokens = require("../../Tokens")
local Theme = require("../../Theme")
local Interaction = require("../../Interaction")
local Style = require("../../Button/Style")
local Text = require("../../Text")
local Model = require("./Model")
local D = q.Declaration

export type Props = {
	read Model: Model.Model,
	read Theme: Theme.Theme?,
	read LayoutOrder: number?,
}

local labelStyle = Text.Label("LabelMedium")
local toggleStyle = Text.Button("LabelLarge")
local boxStyle = Text.Box("BodyMedium")

local function Segment(model: Model.Model, theme: Theme.Theme, mode: Model.Mode, position: number)
	local R = theme.Raw
	local selected: q.State<boolean> = model.mode:Compute(function(self)
		return self:Get() == mode
	end)
	local ix = Interaction.new()
	-- selected = secondary container; otherwise the onSurface state layer (hover .08 / focus .10 / press .10)
	local fill = Style.choose(selected, R.SecondaryContainer, R.OnSurface):Apply(Style.animation())
	local fillTransparency: q.State<number> = selected:Compute(function(self, _prev, hovered, focused, pressed)
		if self:Get() then
			return 0
		end
		return 1
			- Tokens.State.layerOpacity({
				Hovered = hovered:Get(),
				Focused = focused:Get(),
				Pressed = pressed:Get(),
			})
	end, ix.Hovered, ix.Focused, ix.Pressed)
	local textColor = Style.choose(selected, R.OnSecondaryContainer, R.OnSurface):Apply(Style.animation())
	return D.TextButton {
		Name = `Mode{mode}`,
		ix.Hook,
		toggleStyle,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(position * 0.5, 0),
		Size = UDim2.fromScale(0.5, 1),
		Text = mode,
		TextColor3 = textColor,
		BackgroundColor3 = fill,
		BackgroundTransparency = fillTransparency:Apply(Style.animation()),
		UICorner = Tokens.Shape.corner("Full"),
		Activated = function()
			model.mode:SetIfChanged(mode)
		end,
	}
end

local function Toggle(model: Model.Model, theme: Theme.Theme)
	return D.Frame {
		Name = "ModeToggle",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		UICorner = Tokens.Shape.corner("Full"),
		D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.Color.Outline,
			Thickness = 1,
		},
		Segment(model, theme, "RGB", 0),
		Segment(model, theme, "HSV", 1),
	}
end

local function NumberBox(model: Model.Model, theme: Theme.Theme, i: number, refs: { q.PreRef<TextBox?> })
	local R = theme.Raw
	local modelText = model.fieldText(i)
	local focused = q.Source(false)
	local buffer = q.Source("")
	local shown: q.State<string> = focused:Compute(function(self, _prev, m, b)
		return if self:Get() then b:Get() else m:Get()
	end, modelText, buffer)
	local outline = Style.choose(focused, R.Primary, R.Outline):Apply(Style.animation())
	local thickness = Style.select(focused, 2, 1):Apply(Style.animation())

	local function tab()
		local cur, nxt = refs[i].Value, refs[i % 3 + 1].Value
		if cur and nxt then
			cur:ReleaseFocus(false)
			nxt:CaptureFocus()
			nxt.SelectionStart = 1
			nxt.CursorPosition = #nxt.Text + 1
		end
	end

	return D.Frame {
		Name = `Box{i}`,
		Size = UDim2.fromScale(0, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = i,
		UICorner = Tokens.Shape.corner("ExtraSmall"),
		D.UIFlexItem { FlexMode = Enum.UIFlexMode.Fill },
		D.UIStroke {
			Name = "Outline",
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = outline,
			Thickness = thickness,
		},
		D.TextLabel {
			Name = "Label",
			labelStyle,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(0, 14, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = model.fieldLabel(i),
			TextColor3 = theme.Color.OnSurfaceVariant,
		},
		D.TextBox {
			Name = `Channel{i}`,
			boxStyle,
			refs[i],
			q.OnChange("Text", function(v: string)
				if string.find(v, "\t", 1, true) then
					-- Tab arrives as a character: drop it (republish so the bound Text loses it) and move on
					buffer:Set((string.gsub(v, "\t", "")))
					tab()
					return
				end
				buffer:SetIfChanged(v)
				if focused:Get() and v ~= modelText:Get() then
					model.typeField(i, v)
				end
			end),
			Position = UDim2.fromOffset(26, 0),
			Size = UDim2.new(1, -34, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Text = shown,
			TextColor3 = theme.Color.OnSurface,
			TextXAlignment = Enum.TextXAlignment.Left,
			Focused = function()
				focused:SetIfChanged(true)
			end,
			FocusLost = function()
				local b = buffer:Get()
				if b ~= modelText:Get() then
					model.typeField(i, b)
					model.remember()
				end
				focused:SetIfChanged(false)
			end,
			MouseWheelForward = function()
				model.nudgeField(i, 1)
			end,
			MouseWheelBackward = function()
				model.nudgeField(i, -1)
			end,
		},
	}
end

local function Row(model: Model.Model, theme: Theme.Theme)
	local refs: { q.PreRef<TextBox?> } = {
		q.PreRef(nil :: TextBox?),
		q.PreRef(nil :: TextBox?),
		q.PreRef(nil :: TextBox?),
	}
	return D.Frame {
		Name = "ChannelRow",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		D.UIListLayout {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		},
		NumberBox(model, theme, 1, refs),
		NumberBox(model, theme, 2, refs),
		NumberBox(model, theme, 3, refs),
	}
end

local function Fields(props: Props)
	local theme = Theme.resolve(props.Theme)
	return D.Frame {
		Name = "Channels",
		LayoutOrder = props.LayoutOrder or 0,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		D.UIListLayout {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		},
		Toggle(props.Model, theme),
		Row(props.Model, theme),
	}
end

return Fields
