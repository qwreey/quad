--!strict
--[[
	Buttons (Iris: Button / SmallButton).

		Button      { Text: string | State<string>, OnClick: (() -> ())?, Size: UDim2 | State<UDim2>?,
		              Disabled: (boolean | State<boolean>)?, Hooks: { any }?, Style: Style?, Modifier: TextButtonModifier? }
		SmallButton { same }                 no vertical padding (inline with text)

	`Hooks` is a list of hook values (`Tooltip` handle `.Hook`, `Interaction.pointerDown(fn)`, `q.OnRendered(...)`, a Ref ...)
	appended at the END of the element's array part — the escape hatch for what a leaf widget has no prop for:
		Devui.Button { Text = "Save", Hooks = { saveTip.Hook } }
	`Disabled`: no `OnClick`, resting colours whatever the pointer does, dimmed text.

	One TextButton (+ UICorner / UIStroke / UIPadding helpers). Background colour/transparency follow
	Button / ButtonHovered / ButtonActive tokens via Interaction.hover(); size defaults to auto (text + FramePadding).
	`OnClick` fires on Activated (mouse, touch, gamepad). A caller `Size` turns auto-sizing off.
]]

local Quad = require("./Quad")
local q = Quad
local D = q.Declaration
local Common = require("./Common")
local Interaction = require("./Interaction")
local Style = require("./Style")

type State<T> = Quad.State<T>
type Style = Style.Style

export type ButtonProps = {
	read Text: string | State<string>,
	read OnClick: (() -> ())?,
	read Size: (UDim2 | State<UDim2>)?,
	read Disabled: (boolean | State<boolean>)?,
	read Hooks: { any }?,
	read Style: Style?,
	read Modifier: Quad.TextButtonModifier?,
}

local function button(props: ButtonProps, small: boolean): TextButton
	local style = props.Style or Style.default
	local hover = Interaction.hover()
	local enabled = Common.enabled(props.Disabled)
	local look = Common.look(style, "Button", hover, enabled)
	local textLook = Common.textLook(style, enabled)
	local padX, framePadY = Common.padXY(style.Metrics.FramePadding)
	local padY: State<UDim> | UDim = if small then UDim.new(0, 0) else framePadY
	local onClick = props.OnClick
	return D.TextButton({
		props.Modifier or q.None,
		hover.Hook,
		Name = if small then "SmallButton" else "Button",
		Text = props.Text,
		FontFace = style.Metrics.TextFont,
		TextSize = style.Metrics.TextSize,
		TextColor3 = textLook.Color,
		TextTransparency = textLook.Transparency,
		BackgroundColor3 = look.Color,
		BackgroundTransparency = look.Transparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		AutomaticSize = if props.Size then Enum.AutomaticSize.None else Enum.AutomaticSize.XY,
		Size = props.Size or UDim2.fromOffset(0, 0),
		Activated = if onClick
			then function()
				if enabled:Get() then
					onClick()
				end
			end
			else q.None,
		UICorner = style.Metrics.FrameRounding,
		D.UIPadding({ PaddingLeft = padX, PaddingRight = padX, PaddingTop = padY, PaddingBottom = padY }),
		Common.stroke(style),
		table.unpack(Common.hooks(props.Hooks)),
	})
end

local Button = {}

function Button.Button(props: ButtonProps): TextButton
	return button(props, false)
end

function Button.SmallButton(props: ButtonProps): TextButton
	return button(props, true)
end

return Button
