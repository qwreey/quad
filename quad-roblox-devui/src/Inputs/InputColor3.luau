--!strict
--[[
	InputColor3 (Iris: InputColor3) — a swatch, R / G / B drag fields (0-255) and a hex box for a Color3 Source.

		InputColor3 {
			Text: string | State<string>?,         trailing label
			Value: Source<Color3>?,                two-way; an internal Source (white) when omitted
			OnChange: ((c: Color3) -> ())?,        after Value changed through the UI
			Disabled: (boolean | State<boolean>)?,
			Style: Style?, Modifier: FrameModifier?,
		}

	Swatch (Frame, UICorner + UIStroke) | R | G | B (DragNum fields: drag, or click to type, 0-255 integers) | hex box
	("#rrggbb"; also accepts "rgb" / "rrggbb" / "#rgb"; invalid text reverts on Enter / focus loss). No popup picker —
	this is the compact inline form. Returns a row Frame.
]]

local Quad = require("../Quad")
local q = Quad
local D = q.Declaration
local inputColor3Name = D.Modifier.Frame():Name("InputColor3")
local Common = require("../Common")
local Interaction = require("../Interaction")
local InputVector = require("./InputVector")
local NumberFormat = require("./NumberFormat")
local Style = require("../Style")
local Util = require("../Util")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type InputColor3Props = {
	read Text: (string | State<string>)?,
	read Value: Source<Color3>?,
	read OnChange: ((c: Color3) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
}

local function byte(x: number): number
	return math.floor(x * 255 + 0.5)
end

local function hexField(style: Style, value: Source<Color3>, enabled: State<boolean>, onChange: ((Color3) -> ())?): TextBox
	local refresh: Source<number> = q.Source(0)
	local shown: State<string> = value:Compute(function(self, _prev, _tick)
		local c = self:Get()
		return NumberFormat.toHex(byte(c.R), byte(c.G), byte(c.B))
	end, refresh)
	local boxRef: Quad.Ref<TextBox?> = q.Ref<<TextBox?>>(nil)
	local hover = Interaction.hover()
	local look = Common.fieldLook(style, hover, enabled)
	local textLook = Common.textLook(style, enabled)
	local padX: State<UDim> = Util.pxX(style.Metrics.FramePadding)
	return D.TextBox({
		boxRef,
		hover.Hook,
		Name = "Hex",
		LayoutOrder = 5,
		Text = shown,
		TextEditable = enabled,
		ClearTextOnFocus = false,
		FontFace = style.Metrics.TextFont,
		TextSize = style.Metrics.TextSize,
		TextColor3 = textLook.Color,
		TextTransparency = textLook.Transparency,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = look.Color,
		BackgroundTransparency = look.Transparency,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = Common.frameHeight(style),
		FocusLost = function(_enterPressed: boolean, _input: InputObject)
			local box = boxRef.Value
			if box ~= nil then
				local r, g, b = NumberFormat.parseHex(box.Text)
				if r ~= nil and g ~= nil and b ~= nil then
					local c = Color3.fromRGB(r, g, b)
					if c ~= value:Get() then
						value:Set(c)
						if onChange then
							onChange(c)
						end
					end
				end
			end
			-- canonical text back into the box (also reverts invalid input)
			refresh:Set(refresh:Get() + 1)
		end,
		UICorner = style.Metrics.FrameRounding,
		D.UIPadding({ PaddingLeft = padX, PaddingRight = padX }),
		Common.stroke(style),
	})
end

local function InputColor3(props: InputColor3Props): Frame
	local style = props.Style or Style.default
	local value: Source<Color3> = props.Value or q.Source(Color3.new(1, 1, 1))
	local enabled = Common.enabled(props.Disabled)
	local o: InputVector.FieldOptions =
		{ Drag = true, Min = 0, Max = 255, Step = 1, Speed = 1, Enabled = enabled, Style = style }
	local swatchSize: State<UDim2> = style.FrameHeight:Compute(function(self)
		return UDim2.fromOffset(self:Get(), self:Get())
	end)
	return D.Frame({
		inputColor3Name,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Common.rowLayout(style),
		D.Frame({
			Name = "Swatch",
			LayoutOrder = 0,
			Size = swatchSize,
			BackgroundColor3 = value,
			BorderSizePixel = 0,
			UICorner = style.Metrics.FrameRounding,
			Common.stroke(style),
		}),
		InputVector.component<<Color3>>(value, function(c: Color3)
			return byte(c.R)
		end, function(c: Color3, n: number)
			return Color3.fromRGB(n, byte(c.G), byte(c.B))
		end, props.OnChange, o, 1, "R"),
		InputVector.component<<Color3>>(value, function(c: Color3)
			return byte(c.G)
		end, function(c: Color3, n: number)
			return Color3.fromRGB(byte(c.R), n, byte(c.B))
		end, props.OnChange, o, 2, "G"),
		InputVector.component<<Color3>>(value, function(c: Color3)
			return byte(c.B)
		end, function(c: Color3, n: number)
			return Color3.fromRGB(byte(c.R), byte(c.G), n)
		end, props.OnChange, o, 3, "B"),
		hexField(style, value, enabled, props.OnChange),
		if props.Text then Common.label(style, props.Text, enabled, 6) else q.None,
	})
end

return InputColor3
