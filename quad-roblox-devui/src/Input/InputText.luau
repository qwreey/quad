--!strict
--[[
	InputText (Iris: InputText) — a single-line text box bound two-way to a string Source.

		InputText {
			Text: string | State<string>?,         trailing label
			Value: Source<string>?,                two-way; an internal Source ("") when omitted
			Placeholder: string | State<string>?,
			Commit: "change" | "submit"?,          "change" (default): Value follows every keystroke (q.Out);
			                                       "submit": Value is written only when the box loses focus or Enter is pressed
			OnChange: ((text: string) -> ())?,     after Value was written by the user
			OnSubmit: ((text: string) -> ())?,     Enter pressed (FocusLost with enterPressed)
			Disabled: (boolean | State<boolean>)?,
			Style: Style?, Modifier: FrameModifier?, FieldModifier: TextBoxModifier?,
		}

	"change" mode is the plain `Text = value` + `q.Out("Text", value)` pair (with an `OnChange` callback it is the
	equivalent `q.OnChange` write-back that only calls back for changes the user made — an echo of a programmatic
	`:Set` is skipped). "submit" mode never writes mid-edit: the text typed so far lives in the box, the Source is
	written once at FocusLost, so downstream consumers see one value per edit (how-to 02 section 6). An external
	`:Set` during an edit overwrites the box either way. Returns a row Frame (field + optional label).
]]

local Quad = require("../Quad")
local q = Quad
local D = q.Declaration
local Common = require("../Common")
local Interaction = require("../Interaction")
local Style = require("../Style")
local Util = require("../Util")

type State<T> = Quad.State<T>
type Source<T> = Quad.Source<T>
type Style = Style.Style

export type InputTextProps = {
	read Text: (string | State<string>)?,
	read Value: Source<string>?,
	read Placeholder: (string | State<string>)?,
	read Commit: ("change" | "submit")?,
	read OnChange: ((text: string) -> ())?,
	read OnSubmit: ((text: string) -> ())?,
	read Disabled: (boolean | State<boolean>)?,
	read Style: Style?,
	read Modifier: Quad.FrameModifier?,
	read FieldModifier: Quad.TextBoxModifier?,
}

local function InputText(props: InputTextProps): Frame
	local style = props.Style or Style.default
	local value: Source<string> = props.Value or q.Source("")
	local enabled = Common.enabled(props.Disabled)
	local submitMode = props.Commit == "submit"
	local onChange, onSubmit = props.OnChange, props.OnSubmit
	local boxRef: Quad.Ref<TextBox?> = q.Ref<<TextBox?>>(nil)

	local hover = Interaction.hover()
	local look = Common.fieldLook(style, hover, enabled)
	local textLook = Common.textLook(style, enabled)
	local padX: State<UDim> = Util.pxX(style.Metrics.FramePadding)

	-- the user-edit write-back ("change" mode); "submit" mode has none (FocusLost writes)
	local writeBack: any = q.None
	if not submitMode then
		if onChange then
			writeBack = q.OnChange("Text", function(t: string)
				if t ~= value:Get() then
					value:Set(t)
					onChange(t)
				end
			end)
		else
			writeBack = q.Out("Text", value)
		end
	end

	return D.Frame({
		props.Modifier or q.None,
		Name = "InputText",
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Common.rowLayout(style),
		D.TextBox({
			props.FieldModifier or q.None,
			boxRef,
			hover.Hook,
			writeBack,
			Name = "Field",
			LayoutOrder = 1,
			Text = value,
			PlaceholderText = props.Placeholder or "",
			TextEditable = enabled,
			ClearTextOnFocus = false,
			FontFace = style.Metrics.TextFont,
			TextSize = style.Metrics.TextSize,
			TextColor3 = textLook.Color,
			TextTransparency = textLook.Transparency,
			PlaceholderColor3 = style.Color.TextDisabled,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = look.Color,
			BackgroundTransparency = look.Transparency,
			BorderSizePixel = 0,
			Size = Common.frameHeight(style),
			FocusLost = function(enterPressed: boolean, _input: InputObject)
				local box = boxRef.Value
				if submitMode and box ~= nil then
					local text = box.Text
					if text ~= value:Get() then
						value:Set(text)
						if onChange then
							onChange(text)
						end
					end
				end
				if enterPressed and onSubmit then
					onSubmit(value:Get())
				end
			end,
			UICorner = style.Metrics.FrameRounding,
			D.UIPadding({ PaddingLeft = padX, PaddingRight = padX }),
			Common.stroke(style),
			D.UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
		}),
		if props.Text then Common.label(style, props.Text, enabled, 2) else q.None,
	})
end

return InputText
