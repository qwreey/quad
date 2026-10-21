--!strict
--[[
	Buttons (Iris: Button / SmallButton).

		Button      { Text: (string | State<string>)?, Icon: (string | State<string>)?, OnClick: (() -> ())?, Size: UDim2 | State<UDim2>?,
		              Disabled: (boolean | State<boolean>)?, Toggled: (boolean | State<boolean>)?, Hooks: { any }?,
		              Style: Style?, Modifier: ModifierInto<TextButton>? }
		SmallButton { same }                 no vertical padding (inline with text)

	`Hooks` is a list of hook values (`Tooltip` handle `.Hook`, `Interaction.pointerDown(fn)`, `q.OnRendered(...)`, a Ref ...)
	appended at the END of the element's array part — the escape hatch for what a leaf widget has no prop for:
		Devui.Button { Text = "Save", Hooks = { saveTip.Hook } }
	`Disabled`: no `OnClick`, resting colours whatever the pointer does, dimmed text.
	`Toggled` [2026-10-20 user decision; name chosen over `Checked`/`Active`/`Selected` by a three-model review —
	`GuiObject.Active` and `GuiButton.Selected` are engine properties]: while true the button shows its pressed look
	(the `ButtonActive` tokens) — a toggle button or filter chip. The button never writes it: `OnClick` flips your Source.
	A disabled button shows its resting look either way.
	`Icon` [2026-10-21 user decision — devplorer U22; name by a three-model review]: an image id drawn TextSize square in
	the text colour (dimmed with it); with `Text` the icon comes first, then the text; alone it is a square icon button
	(even padding on every side). The icon is an ImageLabel inside the button, not the button's own image — a
	button's image fills the whole button and ignores its UIPadding (devplorer, Studio). Give `Text`, `Icon` or both.

	One TextButton (+ UICorner / UIStroke / UIPadding helpers). Background colour/transparency follow
	Button / ButtonHovered / ButtonActive tokens via Interaction.hover(); size defaults to auto (text + FramePadding).
	`OnClick` fires on Activated (mouse, touch, gamepad). A caller `Size` turns auto-sizing off.
]]

local Quad = require("./Quad")
local q = Quad
local ImageLabel = q.Elem "ImageLabel"
local TextButton = q.Elem "TextButton"
local TextLabel = q.Elem "TextLabel"
local UIListLayout = q.Elem "UIListLayout"
local UIPadding = q.Elem "UIPadding"
local TextButtonModifier = q.Modifier "TextButton"
local buttonName = TextButtonModifier():Name("Button")
local smallButtonName = TextButtonModifier():Name("SmallButton")
local Common = require("./Common")
local Interaction = require("./Interaction")
local Style = require("./Style")
local Util = require("./Util")

type State<T> = Quad.State<T>
type Style = Style.Style

export type ButtonProps = {
	read Text: (string | State<string>)?,
	read Icon: (string | State<string>)?,
	read OnClick: (() -> ())?,
	read Size: (UDim2 | State<UDim2>)?,
	read Disabled: (boolean | State<boolean>)?,
	read Toggled: (boolean | State<boolean>)?,
	read Hooks: { any }?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<TextButton>?,
}

-- `trailing`: an element after the text (MenuButton's ▾ — internal, not a prop)
local function button(props: ButtonProps, small: boolean, trailing: Instance?): TextButton
	local style = props.Style or Style.default
	local hover = Interaction.hover()
	local enabled = Common.enabled(props.Disabled)
	-- `Toggled`: the pressed look also while toggled on (the hook and the hover state stay the real ones)
	local toggled = props.Toggled
	local lookHover: Interaction.HoverHandle = hover
	if toggled ~= nil then
		local on: State<boolean> = if type(toggled) == "boolean" then q.Source(toggled) else toggled
		local pressedOrOn: State<boolean> = hover.Pressed:Compute(function(self, _prev, isOn)
			return self:Get() or isOn:Get()
		end, on)
		lookHover = { Hovered = hover.Hovered, Pressed = pressedOrOn, Hook = hover.Hook, Reset = hover.Reset }
	end
	local look = Common.look(style, "Button", lookHover, enabled)
	local textLook = Common.textLook(style, enabled)
	local framePadX, framePadY = Common.padXY(style.Metrics.FramePadding)
	local padX: State<UDim> | UDim = framePadX
	local padY: State<UDim> | UDim = if small then UDim.new(0, 0) else framePadY
	local onClick = props.OnClick
	local text, icon = props.Text, props.Icon
	if text == nil and icon == nil then
		Util.fail(if small then "SmallButton" else "Button", "give Text, Icon or both")
	end
	-- with an icon (or a trailing element) the button's own text is empty: icon, text and trailing are laid out inside
	local inner: { any } = {}
	local listed = icon ~= nil or trailing ~= nil
	if listed then
		table.insert(
			inner,
			UIListLayout({
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = Util.pxX(style.Metrics.ItemInnerSpacing),
			})
		)
	end
	if icon ~= nil then
		local side: State<UDim2> = style.Metrics.TextSize:Compute(function(self)
			return UDim2.fromOffset(self:Get(), self:Get())
		end)
		table.insert(
			inner,
			ImageLabel({
				Name = "Icon",
				LayoutOrder = 1,
				Size = side,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = icon,
				ImageColor3 = textLook.Color,
				ImageTransparency = textLook.Transparency,
			})
		)
	end
	if listed then
		if text ~= nil then
			table.insert(
				inner,
				TextLabel({
					Name = "Label",
					LayoutOrder = 2,
					AutomaticSize = Enum.AutomaticSize.XY,
					Size = UDim2.fromOffset(0, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Text = text,
					FontFace = style.Metrics.TextFont,
					TextSize = style.Metrics.TextSize,
					TextColor3 = textLook.Color,
					TextTransparency = textLook.Transparency,
				})
			)
		end
		if trailing ~= nil then
			table.insert(inner, trailing)
		end
		if text == nil and trailing == nil then
			padX = padY -- (a square icon button: the same padding on every side)
		end
	end
	return TextButton({
		if small then smallButtonName else buttonName,
		props.Modifier or q.None,
		hover.Hook,
		Text = if listed then "" else text :: string | State<string>,
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
		UIPadding({ PaddingLeft = padX, PaddingRight = padX, PaddingTop = padY, PaddingBottom = padY }),
		Common.stroke(style),
		q.Slot(inner :: { Instance }),
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

-- (internal: MenuButton's one-piece form — a button with a trailing element)
Button.withTrailing = button

return Button
