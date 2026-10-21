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
			Focused: Source<boolean>?,             two-way focus: true asks for it, false releases it, the user's own
			                                       focus changes are written back
			Style: Style?, Modifier: ModifierInto<Frame>?, FieldModifier: ModifierInto<TextBox>?, FieldSpread: SpreadInto<TextBox>?,
		}

	`Focused` [2026-10-20 user decision, a consumer focused nine boxes by hand after mount]: `CaptureFocus` does nothing
	on a box that is not on screen yet (no LayerCollector above it, or one that is not placed itself — a capture there is
	lost at once, Studio 2026-10-20), so a `true` set before that is kept and taken when the box gets there (its own
	AncestryChanged, which the engine fires on descendants: a box mounted with `Focused` already true takes the focus
	once its ScreenGui is placed — one task.defer after it, because a capture inside that signal is lost at once).
	A box hidden by an ANCESTOR fires nothing — set `Focused` again after showing it. A disabled box does not take the
	focus. Clicking elsewhere writes `false`, clicking the box writes `true`.

	"change" mode is the plain `Text = value` + `q.Out "TextBox" "Text" (value)` pair (with an `OnChange` callback it is the
	equivalent `q.OnChange` write-back that only calls back for changes the user made — an echo of a programmatic
	`:Set` is skipped). "submit" mode never writes mid-edit: the text typed so far lives in the box, the Source is
	written once at FocusLost, so downstream consumers see one value per edit (how-to 02 section 6). An external
	`:Set` during an edit overwrites the box either way. Returns a row Frame (field + optional label).
]]

local Quad = require("../Quad")
local q = Quad
local Frame = q.Elem "Frame"
local TextBox = q.Elem "TextBox"
local UIFlexItem = q.Elem "UIFlexItem"
local UIPadding = q.Elem "UIPadding"
local FrameModifier = q.Modifier "Frame"
local TextBoxModifier = q.Modifier "TextBox"
local inputTextName = FrameModifier():Name("InputText")
local fieldName = TextBoxModifier():Name("Field")
local Common = require("../Common")
local Interaction = require("../Interaction")
local Style = require("../Style")
local Util = require("../Util")
local Visibility = require("../Visibility")

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
	read Focused: Source<boolean>?,
	read Style: Style?,
	read Modifier: Quad.ModifierInto<Frame>?,
	read FieldModifier: Quad.ModifierInto<TextBox>?,
	read FieldSpread: Quad.SpreadInto<TextBox>?, -- [3.4.0] spread into the inner box (refs, hooks, descriptors)
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
			writeBack = q.OnChange "TextBox" "Text" (function(t: string)
				if t ~= value:Get() then
					value:Set(t)
					onChange(t)
				end
			end)
		else
			writeBack = q.Out "TextBox" "Text" (value)
		end
	end

	-- two-way focus (see the header)
	local focused = props.Focused
	local function takeFocus()
		local box = boxRef.Value
		if focused == nil or box == nil or not focused:Get() or not enabled:Get() then
			return
		end
		if Visibility.isOnScreen(box) and not box:IsFocused() then
			box:CaptureFocus()
		end
	end
	local focusFollow: any = if focused
		then focused:Observer(function(self)
			if self:Get() then
				takeFocus()
			else
				local box = boxRef.Value
				if box ~= nil and box:IsFocused() then
					box:ReleaseFocus()
				end
			end
		end)
		else q.None
	local focusPlaced: any = if focused
		then q.PostRef(nil :: TextBox?):Callback(function(box: TextBox?)
			if box ~= nil then
				-- deferred: a CaptureFocus inside AncestryChanged (the engine is mid-reparent) is lost in the same frame —
				-- Focused then FocusLost at once; one task.defer later it holds (Studio 2026-10-20)
				box.AncestryChanged:Connect(function()
					task.defer(takeFocus)
				end)
			end
		end)
		else q.None

	return Frame({
		inputTextName,
		props.Modifier or q.None,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Common.rowLayout(style),
		TextBox({
			fieldName,
			props.FieldModifier or q.None,
			props.FieldSpread or q.None,
			boxRef,
			hover.Hook,
			-- clip the text: a long text would run out of the box's left edge, a placeholder out of a narrow box. Ref: devplorer U29
			ClipsDescendants = true,
			writeBack,
			focusFollow,
			focusPlaced,
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
			Focused = if focused
				then function()
					focused:SetIfChanged(true)
				end
				else nil,
			FocusLost = function(enterPressed: boolean, _input: InputObject)
				if focused then
					focused:SetIfChanged(false)
				end
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
			UIPadding({ PaddingLeft = padX, PaddingRight = padX }),
			Common.stroke(style),
			UIFlexItem({ FlexMode = Enum.UIFlexMode.Fill }),
		}),
		if props.Text then Common.label(style, props.Text, enabled, 2) else q.None,
	})
end

return InputText
