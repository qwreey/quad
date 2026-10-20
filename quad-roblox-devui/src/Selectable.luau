--!strict
--[[
	Selectable (Iris: Selectable) — a full-width, text-only row that highlights on hover and while selected.

		Selectable          { Text: string | State<string>, Selected: Source<boolean>?,   -- toggle: a click flips it
		                      OnClick: (() -> ())?, Disabled: (boolean | State<boolean>)?, Hooks: { any }?,
		                      Style: Style?, Modifier: ModifierInto<TextButton>? }
		SelectableOption<T> { Text, Value: Source<T>, Option: T, OnClick?, Disabled?, Hooks?, Style?, Modifier? }
		                      group mode (exactly like RadioButton): the row is selected while `Value:Get() == Option`, a
		                      click sets `Value` to `Option`; several rows share one `Value` Source

	Call it with the type argument — `SelectableOption<<string>>{ Value = pick, Option = "a" }` — the solver cannot infer `T`
	from a `Source<T>` argument.

	Two functions (not one with optional fields) because `Value: Source<T>?` next to `Option: T?` does not infer under the
	new solver (T gets an impossible lower bound `T | nil`). Without `Selected` the toggle row keeps its own boolean.
	One TextButton (+ UICorner / UIPadding). Colour = Header / HeaderHovered / HeaderActive tokens; the row is
	transparent unless selected, hovered or pressed. `OnClick` fires after the Source has been updated. A disabled row
	ignores clicks, shows no hover look and dims its text. `Hooks`: see Button.
]]

local Quad = require("./Quad")
local q = Quad
local TextButton = q.Elem "TextButton"
local UIPadding = q.Elem "UIPadding"
local TextButtonModifier = q.Modifier "TextButton"
local selectableName = TextButtonModifier():Name("Selectable")
local Common = require("./Common")
local Interaction = require("./Interaction")
local Style = require("./Style")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type SelectableProps = {
	read Text: string | State<string>,
	read Selected: Source<boolean>?,
	read OnClick: (() -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Hooks: { any }?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<TextButton>?,
}

export type SelectableOptionProps<T> = {
	read Text: string | State<string>,
	read Value: Source<T>,
	read Option: T,
	read OnClick: (() -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Hooks: { any }?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<TextButton>?,
}

type RowProps = {
	read Text: string | State<string>,
	read OnClick: (() -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Hooks: { any }?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<TextButton>?,
}

-- the shared row: `selected` highlights it, `toggle` is the click action
local function row(
	props: RowProps,
	selected: State<boolean>,
	toggle: () -> ()
): TextButton
	local style = props.Style or Style.default
	local onClick = props.OnClick
	local enabled = Common.enabled(props.Disabled)
	local hover = Interaction.hover()
	local look = Common.headerLook(style, hover, selected)
	local textLook = Common.textLook(style, enabled)
	-- a disabled row shows only the selected highlight: hover / press never show
	local alpha: State<number> = enabled:Compute(function(self, _prev, shown, selectedNow, rest)
		if self:Get() then
			return shown:Get()
		end
		return if selectedNow:Get() then rest:Get() else 1
	end, look.Transparency, selected, style.Transparency.Header)
	local padX, padY = Common.padXY(style.Metrics.FramePadding)
	return TextButton({
		selectableName,
		props.Modifier or q.None,
		hover.Hook,
		Text = props.Text,
		FontFace = style.Metrics.TextFont,
		TextSize = style.Metrics.TextSize,
		TextColor3 = textLook.Color,
		TextTransparency = textLook.Transparency,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = look.Color,
		BackgroundTransparency = alpha,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Activated = function()
			if not enabled:Get() then
				return
			end
			toggle()
			if onClick then
				onClick()
			end
		end,
		UICorner = style.Metrics.FrameRounding,
		UIPadding({ PaddingLeft = padX, PaddingRight = padX, PaddingTop = padY, PaddingBottom = padY }),
		table.unpack(Common.hooks(props.Hooks)),
	})
end

local Selectable = {}

function Selectable.Selectable(props: SelectableProps): TextButton
	local flag: Source<boolean> = props.Selected or q.Source(false)
	return row(props, flag, function()
		flag:Set(not flag:Get())
	end)
end

function Selectable.SelectableOption<T>(props: SelectableOptionProps<T>): TextButton
	local value, mine = props.Value, props.Option
	local isMine: State<boolean> = value:Compute(function(self)
		return self:Get() == mine
	end)
	return row(props, isMine, function()
		value:SetIfChanged(mine)
	end)
end

return Selectable
