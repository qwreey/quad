--!strict
--[[
	Parts shared by the dial picker and the text input (TimePicker.kt = androidx/androidx@40ff481
	compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/TimePicker.kt).

	Parts.selector(o) -> TextButton     Compose `TimeSelector` (3060-3157): the hour / minute box of the dial picker's
	  header (96 x 80, TimeSelectorContainerWidth / Height; shape CornerSmall 8; DisplayLarge text "07" —
	  `toLocalString(minDigits = 2)`). Selected: primaryContainer / onPrimaryContainer, else surfaceContainerHighest /
	  onSurface (TimePickerTokens.kt TimeSelector*); an INVALID value (the text input's unselected field):
	  errorContainer / onErrorContainer. Click = select it. State layer + ripple in the content color (`Interactive`).
	  Instances: host + UICorner + state layer 3 + Label = 6.

	Parts.separator(o) -> TextLabel     Compose `DisplaySeparator` (3037-3058): ":" centered in a 24-wide box, onSurface
	  (TimeFieldSeparatorColor), the text style of the row (DisplayLarge in the picker, DisplayMedium in the input),
	  shifted up 4 (`offset(y = -4.dp)`), line height trimmed (LineHeight 1 here).

	Parts.periodToggle(o) -> Frame      the AM / PM toggle with ComposeMaterial3Flags.isUpdatedTimepickerToggleEnabled
	  (default TRUE — ComposeMaterial3Flags.kt 119-127): two separate `ToggleButton`s (ToggleItem 2978-3035) with a 4 dp
	  gap (PeriodTogglePaddingSmall; Vertical/HorizontalPeriodToggle 2542-2691), AM first. Shapes (ToggleButtonShapes):
	  CircleShape at rest, RoundedCornerShape(12) checked and while pressed — the radius animates. Colors
	  (defaultTimePickerColors 643-682 with the flag): checked primaryContainer / onPrimaryContainer, unchecked
	  surfaceContainerLowest / onSurfaceVariant; label TitleMedium, BOLD while checked (PeriodToggleImpl 2864-2891). A
	  click moves the hour by 12 only while the hour input is valid (`Model:SetPeriod`). Sizes: vertical 52 x 80 (dial
	  picker, PeriodSelectorVertical*), horizontal 216 x 38 (PeriodSelectorHorizontal*), the text input's 52 x 72
	  (TimeInputTokens PeriodSelectorContainer*). Instances: container + per item (host + UICorner + state layer 3 +
	  Label) = 13.
	  Not drawn (the flag's legacy look): the 1 dp outline around both and the divider between them.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Text = require("../Text")
local Typography = require("../Tokens/Typography")
local Interactive = require("../Interactive")
local Interaction = require("../Interaction")
local StateLayer = require("../StateLayer")
local Ripple = require("../Ripple")
local Model = require("./Model")
local Strings = require("./Strings")
local Frame = q.Elem "Frame"
local TextButton = q.Elem "TextButton"
local TextLabel = q.Elem "TextLabel"

type State<T> = q.State<T>

local function animation()
	return q.Animate(Tokens.Motion.options("Short4", "Standard"))
end

export type SelectorOptions = {
	Name: string,
	Theme: Theme.Theme,
	Selected: State<boolean>,
	Text: State<string>,
	Error: State<boolean>?,
	Size: Vector2,
	Position: UDim2,
	Role: Text.Role,
	OnClick: () -> (),
}

local function selector(o: SelectorOptions): TextButton
	local theme = o.Theme
	local raw = theme.Raw
	local err: State<boolean> = o.Error or q.Source(false)
	local container: State<Color3> = o.Selected:Compute(function(self, _prev, e, errC, sel, rest)
		if e:Get() then
			return errC:Get()
		end
		return if self:Get() then sel:Get() else rest:Get()
	end, err, raw.ErrorContainer, raw.PrimaryContainer, raw.SurfaceContainerHighest)
	local content: State<Color3> = o.Selected:Compute(function(self, _prev, e, errC, sel, rest)
		if e:Get() then
			return errC:Get()
		end
		return if self:Get() then sel:Get() else rest:Get()
	end, err, raw.OnErrorContainer, raw.OnPrimaryContainer, raw.OnSurface)
	local contentAnimated = content:Apply(animation())
	local corner = Tokens.Shape.corner("Small")
	local fx = Interactive.new({ Theme = theme, OnColor = contentAnimated, Corner = corner })
	return TextButton {
		Name = o.Name,
		fx.Hook,
		fx.Layer,
		Size = UDim2.fromOffset(o.Size.X, o.Size.Y),
		Position = o.Position,
		BackgroundColor3 = container:Apply(animation()),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		UICorner = corner,
		Activated = function()
			o.OnClick()
		end,
		TextLabel {
			Name = "Label",
			Text.Label(o.Role),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = o.Text,
			TextColor3 = contentAnimated,
		},
	}
end

export type SeparatorOptions = {
	Theme: Theme.Theme,
	Role: Text.Role,
	Height: number,
	Position: UDim2,
}

local function separator(o: SeparatorOptions): TextLabel
	return TextLabel {
		Name = "Separator",
		Text.Label(o.Role),
		LineHeight = 1,
		Size = UDim2.fromOffset(24, o.Height),
		Position = o.Position + UDim2.fromOffset(0, -4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = ":",
		TextColor3 = o.Theme.Color.OnSurface,
	}
end

export type ToggleOptions = {
	Theme: Theme.Theme,
	Model: Model.Model,
	Locale: string,
	Horizontal: boolean,
	Size: Vector2,
	Position: UDim2,
}

local GAP = 4 -- PeriodTogglePaddingSmall
local CHECKED_RADIUS = 12 -- RoundedCornerShape(12.dp)
local boldFont = Font.new(Typography.FontFamily, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local labelFont = Typography.font("TitleMedium")

local function periodToggle(o: ToggleOptions): Frame
	local theme = o.Theme
	local raw = theme.Raw
	local strings = Strings.get(o.Locale)
	local model = o.Model
	local itemW = if o.Horizontal then math.floor((o.Size.X - GAP) / 2) else o.Size.X
	local itemH = if o.Horizontal then o.Size.Y else math.floor((o.Size.Y - GAP) / 2)
	local fullRadius = math.min(itemW, itemH) / 2
	local isPm: State<boolean> = model.Value:Compute(function(self)
		return self:Get().Hour >= 12
	end)

	local function item(pm: boolean, label: string, position: UDim2): TextButton
		local checked: State<boolean> = isPm:Compute(function(self)
			return self:Get() == pm
		end)
		local pressed = q.Source(false)
		local container: State<Color3> = checked:Compute(function(self, _prev, on, off)
			return if self:Get() then on:Get() else off:Get()
		end, raw.PrimaryContainer, raw.SurfaceContainerLowest)
		local content: State<Color3> = checked:Compute(function(self, _prev, on, off)
			return if self:Get() then on:Get() else off:Get()
		end, raw.OnPrimaryContainer, raw.OnSurfaceVariant)
		local contentAnimated = content:Apply(animation())
		local radius: State<UDim> = checked:Compute(function(self, _prev, p)
			return UDim.new(0, if self:Get() or p:Get() then CHECKED_RADIUS else fullRadius)
		end, pressed)
		local corner = radius:Apply(animation())
		local font: State<Font> = checked:Compute(function(self)
			return if self:Get() then boldFont else labelFont
		end)
		local ripple = Ripple.new({ Color = contentAnimated, Corner = corner })
		local ix = Interaction.new({
			OnHost = function(inst: GuiObject)
				inst.SelectionImageObject = Interactive.noSelectionImage()
			end,
			OnPressBegan = function(position: Vector2?)
				pressed:Set(true)
				ripple:Press(position)
			end,
			OnPressEnded = function(_cancelled: boolean)
				pressed:Set(false)
				ripple:Release()
			end,
		})
		return TextButton {
			Name = if pm then "PM" else "AM",
			ix.Hook,
			Size = UDim2.fromOffset(itemW, itemH),
			Position = position,
			BackgroundColor3 = container:Apply(animation()),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			UICorner = corner,
			Activated = function()
				model:SetPeriod(pm)
			end,
			StateLayer.new({
				Color = contentAnimated,
				Corner = corner,
				Hovered = ix.Hovered,
				Pressed = ix.Pressed,
				Focused = ix.Focused,
				Ripple = ripple,
				FocusRing = theme.Color.Secondary,
			}),
			TextLabel {
				Name = "Label",
				Text.Label("TitleMedium"),
				FontFace = font,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = label,
				TextColor3 = contentAnimated,
			},
		}
	end

	local second = if o.Horizontal then UDim2.fromOffset(itemW + GAP, 0) else UDim2.fromOffset(0, itemH + GAP)
	return Frame {
		Name = "PeriodToggle",
		Size = UDim2.fromOffset(o.Size.X, o.Size.Y),
		Position = o.Position,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		item(false, strings.AM, UDim2.new()),
		item(true, strings.PM, second),
	}
end

return {
	selector = selector,
	separator = separator,
	periodToggle = periodToggle,
	animation = animation,
}
