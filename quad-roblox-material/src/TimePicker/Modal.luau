--!strict
--[[
	M3 time picker dialog, opened through the kit's `Overlay` — Compose `TimePickerDialog` (androidx/androidx@40ff481
	compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/TimePickerDialog.kt) as its switchable
	sample uses it (samples/src/main/java/androidx/compose/material3/samples/TimePickerSamples.kt 152-219).

	    local handle = TimePicker.Modal.open({
	        Value = alarm,                          -- Source<Time>: committed on OK (optional)
	        Is24Hour = false, Locale = "ko",
	        OnConfirm = function(t) ... end,         -- after OK
	        OnCancel = function() ... end,           -- every close that is not OK (Cancel, scrim, Escape / B, layer death)
	    })
	    handle.Close()

	OpenOptions (all optional)
	  Value         Source<Time>?                the committed value; the dialog edits a DRAFT (initial = Value, else
	                                             `Initial`, else `Clock.now(nil, UtcOffset)` — Compose's
	                                             rememberTimePickerState starts at the current time); OK writes it
	  Initial       Time?                        UtcOffset number? (seconds east of UTC, for the "now" default)
	  Is24Hour, Locale                           as Dial
	  DisplayMode   ("Picker" | "Input")?        Compose TimePickerDisplayMode: the dial or the text input first
	                                             (default "Picker")
	  LayoutType    ("Vertical" | "Horizontal")? the dial's layout; default = Compose's `defaultTimePickerLayoutType`
	                                             (androidMain TimePicker.android.kt 34-41): Horizontal when the overlay layer is
	                                             wider than tall, else Vertical (Vertical while the layer is unmeasured)
	  OnConfirm     (Time) -> ()                 OnCancel () -> ()        Theme, Overlay (default Overlay.default())
	Returns the Overlay `Handle`.

	ANATOMY (TimePickerDialogLayout / TimePickerCustomLayout, TimePickerDialog.kt 165-198, 233-329): a surfaceContainerHigh card
	(DialogTokens.ContainerColor), corner ExtraLarge 28; the title ("Select Time" / "Enter Time" —
	TimePickerDialogDefaults.Title 523-538: LabelMedium, 20 below it, color = the dialog's content color onSurface) at
	24, 24; the content (Dial or Input) 24 px from the sides; the actions row as wide as the content: the mode toggle
	(an IconButton — Icons.Filled.Keyboard in picker mode, Icons.Filled.Schedule in input mode, onSurfaceVariant,
	DisplayModeToggle 436-472) at the start, Cancel and OK (Text buttons, 8 apart) at the end; OK is enabled while the
	input is valid (`state.isInputValid` in the sample — Model.Valid).
	  Portrait (the input, and the Vertical dial): width = content + 48; title 24 + 16 + 20, content, actions 48 (the
	  48 dp minimum touch height of TextButton / IconButton), 24 bottom. Dial 12 h: 320 x 528, 24 h 304 x 528; input
	  12 h 320 x 243, 24 h 264 x 243.
	  Landscape (the Horizontal dial — `isLandscape` = content wider than tall and at least 200 tall): content at 24, 16,
	  actions 4 below it, 8 bottom; the title stays at 24, 24 beside the display column. 556 x 332. (Compose makes a
	  landscape dialog as tall as the screen allows; the kit uses the content's own height — the branch Compose takes for
	  unbounded height.)
	  The card resizes when the mode changes (Compose re-measures the dialog). When the overlay layer is measured and at
	  most 300 tall (TimePickerDialogDefaults.MinHeightForTimePicker) the dial is not offered: input only, no toggle (the
	  sample's rule).
	Motion, scrim, Escape / B, gamepad trap, the small-screen fit (the card's UIScale times min(1, room / size), measured
	at open) and the CanvasGroup card are DatePicker/Modal.luau's (that header). Switching to the input focuses the
	field being edited (Compose focuses it when TimeInput appears), also when the dialog opens in input mode.
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Button = require("../Button")
local Overlay = require("../Overlay")
local Icons = require("../Icons")
local Text = require("../Text")
local GlyphButton = require("../GlyphButton")
local Clock = require("./Clock")
local Model = require("./Model")
local Strings = require("./Strings")
local Dial = require("./Dial")
local Input = require("./Input")
local D = q.Declaration

type Time = Clock.Time
type State<T> = q.State<T>

export type DisplayMode = "Picker" | "Input"

export type OpenOptions = {
	Value: q.Source<Time>?,
	Initial: Time?,
	UtcOffset: number?,
	Is24Hour: boolean?,
	Locale: Dial.Locale?,
	DisplayMode: DisplayMode?,
	LayoutType: Dial.LayoutType?,
	OnConfirm: ((time: Time) -> ())?,
	OnCancel: (() -> ())?,
	Theme: Theme.Theme?,
	Overlay: Overlay.Overlay?,
}

local PAD = 24
local TITLE_H = 16 + 20 -- LabelMedium line + Title's bottom padding
local ACTIONS_H = 48
local MIN_HEIGHT_FOR_PICKER = 300 -- TimePickerDialogDefaults.MinHeightForTimePicker

local titleStyle = Text.Label("LabelMedium")

type Geometry = {
	Card: Vector2,
	Content: Vector2, -- top-left of the content
	Actions: Vector2, -- top-left of the actions row
	ActionsWidth: number,
}

local function geometry(content: Vector2, landscape: boolean): Geometry
	if landscape then
		return {
			Card = Vector2.new(content.X + PAD * 2, 16 + content.Y + 4 + ACTIONS_H + 8),
			Content = Vector2.new(PAD, 16),
			Actions = Vector2.new(PAD, 16 + content.Y + 4),
			ActionsWidth = content.X,
		}
	end
	local w = content.X + PAD * 2
	return {
		Card = Vector2.new(w, PAD + TITLE_H + content.Y + ACTIONS_H + PAD),
		Content = Vector2.new(math.floor((w - content.X) / 2), PAD + TITLE_H),
		Actions = Vector2.new(PAD, PAD + TITLE_H + content.Y),
		ActionsWidth = content.X,
	}
end

local function card(o: OpenOptions, handle: Overlay.Handle, layerSize: Vector2, onConfirm: (Time) -> (), onCancelButton: (GuiObject) -> ()): CanvasGroup
	local theme = Theme.resolve(o.Theme)
	local locale = o.Locale or "en"
	local strings = Strings.get(locale)
	local is24 = o.Is24Hour == true
	local measured = layerSize.X > 0 and layerSize.Y > 0
	local pickerAllowed = not (measured and layerSize.Y <= MIN_HEIGHT_FOR_PICKER)
	local layout: Dial.LayoutType = o.LayoutType or (if measured and layerSize.Y < layerSize.X then "Horizontal" else "Vertical")

	local valueSource = o.Value
	local start: Time = if valueSource ~= nil then valueSource:Get() else (o.Initial or Clock.now(nil, o.UtcOffset))
	local draft = q.Source<<Time>>(start)
	local model = Model.new({ Value = draft, Is24Hour = is24 })
	local initialMode: DisplayMode = if pickerAllowed then (o.DisplayMode or "Picker") else "Input"
	local mode = q.Source(initialMode)

	local pickerGeo = geometry(Dial.size(layout, is24), layout == "Horizontal")
	local inputGeo = geometry(Input.size(is24), false)
	local function geo(m: DisplayMode): Geometry
		return if m == "Picker" then pickerGeo else inputGeo
	end

	local isPicker: State<boolean> = mode:Compute(function(self)
		return self:Get() == "Picker"
	end)
	local isInput: State<boolean> = mode:Compute(function(self)
		return self:Get() == "Input"
	end)
	local picker = Dial.build({
		Model = model,
		Theme = theme,
		Locale = locale,
		LayoutType = layout,
		Visible = isPicker,
		Position = UDim2.fromOffset(pickerGeo.Content.X, pickerGeo.Content.Y),
	})
	local input = Input.build({
		Model = model,
		Theme = theme,
		Locale = locale,
		Visible = isInput,
		Position = UDim2.fromOffset(inputGeo.Content.X, inputGeo.Content.Y),
	})

	local cardSize: State<UDim2> = mode:Compute(function(self)
		local c = geo(self:Get()).Card
		return UDim2.fromOffset(c.X, c.Y)
	end)
	local actionsPosition: State<UDim2> = mode:Compute(function(self)
		local g = geo(self:Get())
		return UDim2.fromOffset(g.Actions.X, g.Actions.Y)
	end)
	local actionsSize: State<UDim2> = mode:Compute(function(self)
		return UDim2.fromOffset(geo(self:Get()).ActionsWidth, ACTIONS_H)
	end)
	local title: State<string> = mode:Compute(function(self)
		return if self:Get() == "Input" then strings.EnterTime else strings.SelectTime
	end)
	local toggleGlyph: State<string> = mode:Compute(function(self)
		return Icons.glyph(if self:Get() == "Picker" then "keyboard" else "schedule")
	end)
	local keyboardAsset, scheduleAsset = Icons.asset("keyboard"), Icons.asset("schedule")
	local toggleAsset: State<string>? = nil
	if keyboardAsset ~= nil and scheduleAsset ~= nil then
		toggleAsset = mode:Compute(function(self)
			return if self:Get() == "Picker" then keyboardAsset else scheduleAsset
		end)
	end
	local okDisabled: State<boolean> = Util.negate(model.Valid)

	-- enter / exit (DatePicker/Modal.luau): snapped mount, animated from the postHook; `IsOpen` false animates out
	local entered = q.Source(false)
	local shown: State<boolean> = handle.IsOpen:Compute(function(self, _prev, ent)
		return self:Get() and ent:Get()
	end, entered)
	local fade: State<number> = shown:Compute(function(self)
		return if self:Get() then 0 else 1
	end)
	local function fitFor(m: DisplayMode): number
		if not measured then
			return 1
		end
		local c = geo(m).Card
		return math.max(0.25, math.min(1, (layerSize.X - 32) / c.X, (layerSize.Y - 32) / c.Y))
	end
	local scale: State<number> = shown:Compute(function(self, _prev, m)
		return (if self:Get() then 1 else 0.92) * fitFor(m:Get())
	end, mode)
	local motion = Tokens.Motion.options("Short4", "Standard")

	local function setMode(m: DisplayMode)
		if m == "Input" then
			input.Sync()
			mode:Set("Input")
			input.Focus()
		else
			-- back to the dial: drop whatever was typed (an out-of-range hour would keep `Valid` false — and OK
			-- disabled — while the dial shows the last valid time). SetTime with the current value only rewrites the
			-- two inputs (no OnChange). Compose gets the same from its inputs leaving the composition.
			model:SetTime(model.Value:Get())
			mode:Set("Picker")
		end
	end

	return D.CanvasGroup {
		Name = "TimePickerModal",
		Active = true, -- 3D / camera input only; a GUI click is sunk by the ClickSink child (a plain frame passes it down)
		Util.clickSink(),
		Size = cardSize,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = theme.Color.SurfaceContainerHigh,
		BorderSizePixel = 0,
		GroupTransparency = fade:Apply(q.Animate(motion)),
		UICorner = Tokens.Shape.corner("ExtraLarge"),
		UIScale = scale:Apply(q.Animate(motion)),
		model.Sync,
		Util.postHook(function()
			entered:Set(true)
			if mode:Get() == "Input" then
				input.Focus()
			end
		end),
		D.TextLabel {
			Name = "Title",
			titleStyle,
			Size = UDim2.fromOffset(200, 16),
			Position = UDim2.fromOffset(PAD, PAD),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = title,
			TextColor3 = theme.Color.OnSurface,
			TextXAlignment = Enum.TextXAlignment.Left,
		},
		picker.Frame,
		input.Frame,
		D.Frame {
			Name = "Actions",
			Size = actionsSize,
			Position = actionsPosition,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			GlyphButton.new({
				Name = "ModeToggle",
				Glyph = toggleGlyph,
				Asset = toggleAsset,
				Position = UDim2.fromOffset(0, (ACTIONS_H - 40) / 2),
				Visible = pickerAllowed,
				Theme = theme,
				OnClick = function()
					setMode(if mode:Get() == "Picker" then "Input" else "Picker")
				end,
			}),
			D.Frame {
				Name = "Buttons",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				},
				Button({
					Variant = "Text",
					Label = strings.Cancel,
					Theme = theme,
					OnClick = function()
						handle.Close()
					end,
					Modifier = D.Modifier.TextButton():LayoutOrder(1),
					Hooks = {
						Util.preHook(function(inst: GuiObject)
							onCancelButton(inst)
						end),
					},
				}),
				Button({
					Variant = "Text",
					Label = strings.OK,
					Theme = theme,
					Disabled = okDisabled,
					OnClick = function()
						if model.Valid:Get() then
							onConfirm(draft:Get())
						end
					end,
					Modifier = D.Modifier.TextButton():LayoutOrder(2),
				}),
			},
		},
	}
end

local function open(o: OpenOptions): Overlay.Handle
	local overlay = o.Overlay or Overlay.default()
	local committed = false
	local cancelButton: GuiObject? = nil
	local handle = overlay:Open({
		Scrim = true,
		DismissOnEscape = true,
		TrapSelection = true,
		InitialSelection = function(): GuiObject?
			return cancelButton
		end,
		Content = function(h: Overlay.Handle): Instance
			return card(o, h, overlay.Layer.AbsoluteSize, function(t: Time)
				-- the card stays mounted (and clickable) while it animates out: a second OK, or an OK after Cancel,
				-- within the exit time must not commit (again)
				if not h.IsOpen:Get() then
					return
				end
				committed = true
				if o.Value ~= nil then
					o.Value:Set(t)
				end
				if o.OnConfirm then
					o.OnConfirm(t)
				end
				h.Close()
			end, function(inst: GuiObject)
				cancelButton = inst
			end)
		end,
		OnClose = function()
			if not committed and o.OnCancel then
				o.OnCancel()
			end
		end,
	})
	return handle
end

return { open = open }
