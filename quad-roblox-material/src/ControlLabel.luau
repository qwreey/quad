--!strict
--[[
	ControlLabel (internal): the `Label` text of a selection control (Checkbox / Radio) — the HTML `<label for>` of the
	kit. The text is a child of the control's own host button, so the WHOLE row (the 48 px control + the text) is one
	hit and hover area: hovering the text lights the control's state layer and a click / tap on it activates the control
	(the control's Interaction hook and `Activated` sit on that host). A press that starts on the text ripples from the
	center of the control's state layer (Ripple.luau: a press outside the layer starts at its center).

	    host modifier  `ControlLabel.host`        host Size (0, 48) + AutomaticSize X (applied AFTER the control's base,
	                                              BEFORE the caller's Modifier)
	    target         `ControlLabel.TargetPosition`  the 40 px Target frame centered at (24, 24) by OFFSET — on an
	                                              auto-sized host a scale position would depend on the width it decides
	    text           `ControlLabel.new(text, theme, disabled)` -> TextLabel at x = 48, 48 high, BodyLarge, onSurface
	                                              (onSurface @ 38 % disabled)
	Cost: +1 instance (the TextLabel). Every child is placed by offset, so the host's automatic width is the text's end.
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Text = require("./Text")
local Style = require("./Button/Style")
local D = q.Declaration

local Slot = 48

local host = D.Modifier.TextButton():Size(UDim2.fromOffset(0, Slot)):AutomaticSize(Enum.AutomaticSize.X)
local textStyle = Text.Label("BodyLarge")

local function new(text: string | q.State<string>, theme: Theme.Theme, disabled: q.State<boolean>): TextLabel
	return D.TextLabel {
		Name = "Label",
		textStyle,
		Position = UDim2.fromOffset(Slot, 0),
		Size = UDim2.fromOffset(0, Slot),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = theme.Color.OnSurface,
		TextTransparency = Style.disabledNumber(disabled, 0, Style.DisabledContentTransparency),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}
end

return {
	host = host,
	new = new,
	TargetPosition = UDim2.fromOffset(Slot / 2, Slot / 2),
	Slot = Slot,
}
