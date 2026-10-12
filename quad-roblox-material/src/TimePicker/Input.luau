--!strict
--[[
	M3 time picker, INPUT form — Compose `TimeInput(state, modifier, colors)` (TimePicker.kt = androidx/androidx@40ff481
	compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/TimePicker.kt 300-318, TimeInputImpl
	2033-2228, TimeInputTransformation 3655-3744, SupportingText 3746-3787, TimePickerTextField 3789-3933).

	    Material.TimePicker.Input({ Value = t, Is24Hour = true })

	Props (all `read`) — as `Dial` without LayoutType:
	  Value Source<Time>, Is24Hour boolean?, Locale ("en" | "ko")?, OnChange ((Time) -> ())?, Theme, Modifier, Hooks
	OnChange fires after a USER edit made Value change (a typed valid hour / minute, the AM/PM toggle).

	LAYOUT (TimeInputTokens.kt): hour field 96 x 72 (TimeFieldContainerWidth / Height, CornerSmall 8, DisplayMedium text
	centered), ":" 24 x 72 (DisplayMedium), minute field, then in 12 h 4 + the AM/PM toggle 52 x 72 (Parts.periodToggle).
	Under each field the supporting text (BodySmall, 7 below, two lines tall: "Hour" / "Minute" in onSurfaceVariant, or
	the error in error color). 12 h 272 x 111, 24 h 216 x 111.

	FIELD LOOK (TimePickerTextField + defaultTimeInputColors 848-889): the field being edited (Compose `selection`) is an
	outlined text field — focused: primaryContainer + onPrimaryContainer text + 2 px outline border, unfocused: surface-
	ContainerHighest + 1 px; the other field is a TimeSelector (surfaceContainerHighest / onSurface, no border). Invalid:
	errorContainer, the edited field's text and border in error, the other's text onErrorContainer. Roblox has one TextBox
	per field for both looks: clicking (focusing) the other field makes it the edited one, and a field that stops being
	edited shows the TimeSelector's text ("07" — the valid hour for display, else what was typed).

	TYPING (Clock.editField / hourFromTyped; the Model keeps Compose's hourInput / minuteInput):
	  * digits only (anything else is reverted), at most two — a third digit typed into a full field replaces it
	  * hour: 24 h as typed; 12 h mapped into the current period (12 -> 0 / 12, else +12 in PM); valid = isValidHour
	    (12 h AM 0..11 / PM 12..23 — so "13" is an error in 12 h); a valid hour writes Value; invalid keeps the last valid
	    Value and shows the error ("Hour must be 1–12" / "Hour must be 0–23"); empty = 0 (12 in a 12 h PM state)
	  * after two digits, or a single 12 h digit 2..9, with a valid hour, editing moves to the minute field (focus moves)
	  * Enter in the hour field moves to the minute field when the hour is valid (Compose ImeAction.Next)
	  * minute: 0..59 valid ("Minute must be 0–59"); empty = 0
	  * an outside change of Value (the dial in the modal, the AM/PM toggle, a `:Set`) rewrites both texts
	Not done: Compose focuses the edited field as soon as the TimeInput appears; the inline component does not take the
	keyboard focus on its own (`Input.build(...).Focus()` — the Modal calls it when it shows the input). No state layer
	or ripple on the fields (Compose's text field has none; its TimeSelector surface has one).

	Instances (12 h): host + inner frame + 2 x (TextBox + UICorner + UIStroke + supporting label) + ":" + toggle 13 = 24.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Text = require("../Text")
local Util = require("../Util")
local Interactive = require("../Interactive")
local Clock = require("./Clock")
local Model = require("./Model")
local Parts = require("./Parts")
local Strings = require("./Strings")
local D = q.Declaration
local inputName = D.Modifier.Frame():Name("TimePickerInput")

type State<T> = q.State<T>
type Time = Clock.Time
type Selection = Clock.Selection

export type Locale = "en" | "ko"

export type Props = {
	read Value: q.Source<Time>,
	read Is24Hour: boolean?,
	read Locale: Locale?,
	read OnChange: ((time: Time) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local FIELD_W, FIELD_H = 96, 72 -- TimeFieldContainerWidth / Height
local SEP_W = 24
local TOGGLE_GAP = 4
local TOGGLE = Vector2.new(52, 72) -- TimeInputTokens PeriodSelectorContainerWidth / Height
local SUPPORT_TOP = 7 -- SupportLabelTop
local SUPPORT_H = 32 -- two BodySmall lines (minLines = 2)
local HEIGHT = FIELD_H + SUPPORT_TOP + SUPPORT_H

local fieldStyle = Text.Box("DisplayMedium")
local supportStyle = Text.Label("BodySmall")

export type BuildOptions = {
	Model: Model.Model,
	Theme: Theme.Theme,
	Locale: string,
	Name: string?,
	Position: UDim2?,
	Visible: (boolean | State<boolean>)?,
}

export type Built = {
	read Frame: Frame,
	read Size: Vector2,
	Focus: () -> (), -- capture the keyboard focus in the field being edited
	Sync: () -> (), -- rewrite both texts from the model (Modal: on switching to the input)
}

local function size(is24: boolean): Vector2
	return Vector2.new(FIELD_W * 2 + SEP_W + (if is24 then 0 else TOGGLE_GAP + TOGGLE.X), HEIGHT)
end

local function build(o: BuildOptions): Built
	local model = o.Model
	local theme = o.Theme
	local raw = theme.Raw
	local strings = Strings.get(o.Locale)
	local is24 = model.Is24Hour
	local total = size(is24)
	local animation = Parts.animation

	local boxes: { [Selection]: TextBox } = {}
	local texts: { [Selection]: string } = {}
	local writing = false
	local typing = false

	-- what a field shows when written from the model (Compose hourTextValue / minuteTextValue, TimeSelector value)
	local function display(kind: Selection): string
		if kind == "Hour" then
			if model.HourValid:Get() then
				return Clock.pad2(Clock.hourForDisplay(model.Value:Get().Hour, is24))
			end
			return Clock.pad2(model.HourInput:Get())
		end
		return Clock.pad2(model.MinuteInput:Get())
	end
	local function setText(kind: Selection, s: string)
		texts[kind] = s
		local box = boxes[kind]
		if box ~= nil and box.Text ~= s then
			writing = true
			box.Text = s
			writing = false
		end
	end
	local function focus(kind: Selection)
		local box = boxes[kind]
		if box ~= nil and not box:IsFocused() then
			box:CaptureFocus()
		end
	end
	local function selectMinute()
		model.Selection:SetIfChanged("Minute")
		focus("Minute")
	end

	local function apply(kind: Selection, text: string, inserted: boolean)
		typing = true
		local pm = Clock.isPm(model.Value:Get().Hour)
		if kind == "Hour" then
			if text == "" then
				model:SetHourInput(if pm and not is24 then 12 else 0)
			else
				local v = tonumber(text) :: number
				model:SetHourInput(Clock.hourFromTyped(v, is24, pm))
				local advance = #text == 2 or (inserted and not is24 and v >= 2 and v <= 9)
				if advance and model.HourValid:Get() then
					typing = false
					selectMinute()
				end
			end
		else
			model:SetMinuteInput(if text == "" then 0 else tonumber(text) :: number)
		end
		typing = false
	end

	local function onText(kind: Selection)
		if writing then
			return
		end
		local box = boxes[kind]
		local old = texts[kind] or ""
		if box.Text == old then
			return -- our own write (the declaration's first Text lands after the hook connected)
		end
		local text, inserted = Clock.editField(old, box.Text)
		if text == nil then
			setText(kind, old)
			return
		end
		setText(kind, text)
		apply(kind, text, inserted)
	end

	-- an outside change of the model rewrites the texts (Compose LaunchedEffect(hour / minute) with userOverride)
	-- (it also watches the inputs: the model's own Sync effect may run after this one)
	local rewrite = q.Effect(function()
		model.Value:Get()
		model.HourInput:Get()
		model.MinuteInput:Get()
		if not typing then
			setText("Hour", display("Hour"))
			setText("Minute", display("Minute"))
		end
	end, model.Value, model.HourInput, model.MinuteInput)
	-- a field that stops being edited shows the TimeSelector text
	local reformat = q.Effect(function()
		local sel = model.Selection:Get()
		local other: Selection = if sel == "Hour" then "Minute" else "Hour"
		setText(other, display(other))
	end, model.Selection)

	local function field(kind: Selection, x: number): { Instance }
		local focused = q.Source(false)
		local editing: State<boolean> = model.Selection:Compute(function(self)
			return self:Get() == kind
		end)
		local valid = if kind == "Hour" then model.HourValid else model.MinuteValid
		local container: State<Color3> = editing:Compute(function(self, _prev, ok, f, errC, sel, rest)
			if not ok:Get() then
				return errC:Get()
			end
			return if self:Get() and f:Get() then sel:Get() else rest:Get()
		end, valid, focused, raw.ErrorContainer, raw.PrimaryContainer, raw.SurfaceContainerHighest)
		local content: State<Color3> = editing:Compute(function(self, _prev, ok, err, onErrC, sel, rest)
			if not ok:Get() then
				return if self:Get() then err:Get() else onErrC:Get()
			end
			return if self:Get() then sel:Get() else rest:Get()
		end, valid, raw.Error, raw.OnErrorContainer, raw.OnPrimaryContainer, raw.OnSurface)
		local stroke: State<Color3> = valid:Compute(function(self, _prev, outline, err)
			return if self:Get() then outline:Get() else err:Get()
		end, raw.Outline, raw.Error)
		local thickness: State<number> = focused:Compute(function(self)
			return if self:Get() then 2 else 1
		end)
		local support: State<string> = valid:Compute(function(self)
			if self:Get() then
				return if kind == "Hour" then strings.Hour else strings.Minute
			elseif kind == "Minute" then
				return strings.MinuteError
			end
			return if is24 then strings.HourError24 else strings.HourError
		end)
		local supportColor: State<Color3> = valid:Compute(function(self, _prev, variant, err)
			return if self:Get() then variant:Get() else err:Get()
		end, raw.OnSurfaceVariant, raw.Error)
		texts[kind] = display(kind)
		return {
			D.TextBox {
				Name = if kind == "Hour" then "HourField" else "MinuteField",
				fieldStyle,
				Size = UDim2.fromOffset(FIELD_W, FIELD_H),
				Position = UDim2.fromOffset(x, 0),
				BackgroundColor3 = container:Apply(animation()),
				BorderSizePixel = 0,
				Text = texts[kind],
				TextColor3 = content:Apply(animation()),
				TextXAlignment = Enum.TextXAlignment.Center,
				ClearTextOnFocus = false,
				UICorner = Tokens.Shape.corner("Small"),
				Util.preHook(function(inst: GuiObject)
					local box = inst :: TextBox
					boxes[kind] = box
					box.SelectionImageObject = Interactive.noSelectionImage()
					box:GetPropertyChangedSignal("Text"):Connect(function()
						onText(kind)
					end)
					box.Focused:Connect(function()
						focused:SetIfChanged(true)
						model.Selection:SetIfChanged(kind)
					end)
					box.FocusLost:Connect(function(enterPressed: boolean)
						focused:SetIfChanged(false)
						if kind == "Hour" and enterPressed and model.HourValid:Get() then
							selectMinute()
						end
					end)
				end),
				D.UIStroke {
					Name = "Outline",
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = stroke:Apply(animation()),
					Thickness = thickness,
					Enabled = editing,
				},
			},
			D.TextLabel {
				Name = if kind == "Hour" then "HourSupport" else "MinuteSupport",
				supportStyle,
				Size = UDim2.fromOffset(FIELD_W, SUPPORT_H),
				Position = UDim2.fromOffset(x, FIELD_H + SUPPORT_TOP),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = support,
				TextColor3 = supportColor:Apply(animation()),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
			},
		}
	end

	local children: { Instance } = {}
	for _, c in field("Hour", 0) do
		table.insert(children, c)
	end
	table.insert(children, Parts.separator({ Theme = theme, Role = "DisplayMedium", Height = FIELD_H, Position = UDim2.fromOffset(FIELD_W, 0) }))
	for _, c in field("Minute", FIELD_W + SEP_W) do
		table.insert(children, c)
	end
	if not is24 then
		table.insert(
			children,
			Parts.periodToggle({
				Theme = theme,
				Model = model,
				Locale = o.Locale,
				Horizontal = false,
				Size = TOGGLE,
				Position = UDim2.fromOffset(FIELD_W * 2 + SEP_W + TOGGLE_GAP, 0),
			})
		)
	end
	local frame = D.Frame {
		Name = o.Name or "TimeInput",
		Size = UDim2.fromOffset(total.X, total.Y),
		Position = o.Position or UDim2.new(),
		Visible = Util.visible(o.Visible),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		rewrite,
		reformat,
		table.unpack(children),
	}
	return {
		Frame = frame,
		Size = total,
		Focus = function()
			focus(model.Selection:Get())
		end,
		Sync = function()
			setText("Hour", display("Hour"))
			setText("Minute", display("Minute"))
		end,
	}
end

local function Input(props: Props): Frame
	local theme = Theme.resolve(props.Theme)
	local model = Model.new({ Value = props.Value, Is24Hour = props.Is24Hour == true, OnChange = props.OnChange })
	local built = build({ Model = model, Theme = theme, Locale = props.Locale or "en" })
	local total = built.Size
	return D.Frame {
		inputName,
		D.Modifier.Frame():Size(UDim2.fromOffset(total.X, total.Y)):BorderSizePixel(0):BackgroundTransparency(1),
		props.Modifier or q.None,
		model.Sync,
		built.Frame,
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return { Input = Input, build = build, size = size }
