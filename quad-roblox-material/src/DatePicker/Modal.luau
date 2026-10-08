--!strict
--[[
	M3 modal date picker: a dialog over a scrim, opened through the kit's `Overlay`.

	    local handle = DatePicker.Modal.open({
	        Value = birthday,                       -- Source<Date?>: committed on OK (optional)
	        Min = Calendar.date(1900, 1, 1), Max = today,
	        Locale = "ko",
	        OnConfirm = function(date) ... end,      -- after OK
	        OnCancel = function() ... end,           -- Cancel, scrim click, Escape / B, or the overlay layer dying
	                                                 -- ("Destroyed") — i.e. every close that is not OK
	    })
	    handle.Close()                              -- Overlay Handle (idempotent)

	OpenOptions (all optional unless noted)
	  Value          Source<Date?>?     the committed value. The dialog edits a separate DRAFT (initial = Value, or
	                                    `Initial`); OK writes the draft into Value, Cancel / scrim discard it.
	  Initial        Date?              initial draft when there is no Value source
	  Min, Max, IsDisabled, FirstDayOfWeek, Locale, Today, UtcOffset, Theme    as Docked
	  StartInInput   boolean?           open in text-input mode
	  OnConfirm      (Date) -> ()       after OK
	  OnCancel       () -> ()           on every close that did not commit: Cancel, scrim, Escape / gamepad B, and the
	                                    Overlay layer's death (reason "Destroyed": the owning ScreenGui was destroyed)
	  Overlay        Overlay?           default `Overlay.default()` (mount its Layer once at the app root)
	Returns the Overlay `Handle`.

	Anatomy (360 x 569): supporting text ("Select date" / "Enter date") + headline (the draft date formatted in
	the locale: "Mon, Oct 5" / "10월 5일 (월)", "–" when nothing is picked) + a mode toggle button (edit glyph -> input
	mode, calendar glyph -> calendar) / divider / the calendar (Body) or the text field (InputMode) / Cancel + OK
	(Text buttons, right aligned; OK is disabled while nothing is picked or the typed text is invalid).
	The toggle draws the `Icons` images "edit" / "calendar" (Material edit / date_range — Compose's DatePicker mode toggle
	Icons.Filled.Edit / DateRange), or their text glyphs when either image is overridden away.

	Motion (docs/how-to 09): the card is a CanvasGroup mounted snapped (transparent, scale .92) and animated in from a
	postHook: GroupTransparency 1 -> 0 and a UIScale .92 -> 1 over Short4 / Standard; `Handle.IsOpen` going false (OK /
	Cancel / scrim) animates it back out while the Overlay keeps it mounted for its ExitTime (0.2 s), then
	destroys it. Escape / gamepad B / scrim dismiss like Cancel (Overlay `DismissOnEscape`); the gamepad selection is
	trapped in the card while it is open and starts on Cancel when the last input was a gamepad (Overlay `TrapSelection` /
	`InitialSelection`).

	Small screens: when the overlay layer is laid out and smaller than the 360 x 569 card (+16 px margin per side) the
	card's UIScale is multiplied by the fitting factor (<= 1; measured at open, not re-measured).

	CanvasGroup lifetime: the group (needed for the fade) stays a CanvasGroup for the card's whole life — an offscreen
	texture composited every frame while it is up. Fine for one short-lived card; swapping to a plain Frame once the enter
	animation ends is possible but not done (it would also lose the exit fade). Deviations: no UIShadow on the card (a
	CanvasGroup clips its children; the scrim carries the separation).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")
local Util = require("../Util")
local Button = require("../Button")
local Overlay = require("../Overlay")
local Icons = require("../Icons")
local Text = require("../Text")
local Body = require("./Body")
local Calendar = require("./Calendar")
local GlyphButton = require("../GlyphButton")
local InputMode = require("./InputMode")
local Status = require("./Status")
local Strings = require("./Strings")
local View = require("./View")
local D = q.Declaration

type Date = Calendar.Date
type State<T> = q.State<T>
type Mode = "Calendar" | "Input"

export type OpenOptions = {
	Value: q.Source<Date?>?,
	Initial: Date?,
	Min: Date?,
	Max: Date?,
	IsDisabled: ((date: Date) -> boolean)?,
	FirstDayOfWeek: number?,
	Locale: ("en" | "ko")?,
	Today: Date?,
	UtcOffset: number?,
	StartInInput: boolean?,
	OnConfirm: ((date: Date) -> ())?,
	OnCancel: (() -> ())?,
	Theme: Theme.Theme?,
	Overlay: Overlay.Overlay?,
}

local WIDTH = Body.Width
local HEAD_H = 120
local BODY_H = Body.Height
local ACTIONS_H = 52
local CARD_H = HEAD_H + 1 + BODY_H + ACTIONS_H

local supportStyle = Text.Label("LabelMedium")
local headlineStyle = Text.Label("HeadlineLarge")

local function card(o: OpenOptions, handle: Overlay.Handle, layerSize: Vector2, onConfirm: (Date) -> (), onCancelButton: (GuiObject) -> ()): CanvasGroup
	local theme = Theme.resolve(o.Theme)
	local locale = o.Locale or "en"
	local strings = Strings.get(locale)
	local today = o.Today or Calendar.today(nil, o.UtcOffset)
	local valueSource = o.Value
	local startValue: Date? = if valueSource ~= nil then valueSource:Get() else o.Initial
	local draft = q.Source<<Date?>>(startValue)
	local mode = q.Source((if o.StartInInput then "Input" else "Calendar") :: Mode)
	local inputError = q.Source<<string?>>(nil)
	local selectable = Status.selectable(o.Min, o.Max, o.IsDisabled)
	local initialDate = if startValue ~= nil then startValue else Calendar.clamp(today, o.Min, o.Max)

	local isCalendar: State<boolean> = mode:Compute(function(self)
		return self:Get() == "Calendar"
	end)
	local isInput: State<boolean> = mode:Compute(function(self)
		return self:Get() == "Input"
	end)

	local body = Body.new({
		Min = o.Min,
		Max = o.Max,
		IsDisabled = o.IsDisabled,
		FirstDayOfWeek = o.FirstDayOfWeek or 0,
		Locale = locale,
		Today = today,
		Theme = theme,
		InitialMonth = View.containing(initialDate),
		Follow = draft,
		StatusFor = Status.single({ Value = draft, Today = today, Selectable = selectable }),
		OnPick = function(date: Date)
			draft:Set(date)
		end,
		Visible = isCalendar,
		Position = UDim2.fromOffset(0, HEAD_H + 1),
	})

	local input = InputMode.new({
		Draft = draft,
		Error = inputError,
		Locale = locale,
		Min = o.Min,
		Max = o.Max,
		IsDisabled = o.IsDisabled,
		Theme = theme,
		Width = WIDTH,
		Height = BODY_H,
		Visible = isInput,
		Position = UDim2.fromOffset(0, HEAD_H + 1),
	})
	if o.StartInInput then
		input.Sync()
	end

	local headline: State<string> = draft:Compute(function(self)
		local d = self:Get()
		return if d ~= nil then Calendar.format(d, strings.Headline, locale) else "\u{2013}"
	end)
	local supporting: State<string> = mode:Compute(function(self)
		return if self:Get() == "Input" then strings.EnterDate else strings.SelectDate
	end)
	local toggleGlyph: State<string> = mode:Compute(function(self)
		return Icons.glyph(if self:Get() == "Input" then "calendar" else "edit")
	end)
	-- the Material images when both are registered (the default — Icons.luau), else the glyphs
	local editAsset, calendarAsset = Icons.asset("edit"), Icons.asset("calendar")
	local toggleAsset: State<string>? = nil
	if editAsset ~= nil and calendarAsset ~= nil then
		toggleAsset = mode:Compute(function(self)
			return if self:Get() == "Input" then calendarAsset else editAsset
		end)
	end

	-- OK needs a picked date and, in input mode, valid text
	local okDisabled: State<boolean> = draft:Compute(function(self, _prev, err, m)
		if self:Get() == nil then
			return true
		end
		return m:Get() == "Input" and err:Get() ~= nil
	end, inputError, mode)

	-- enter / exit: snapped mount, animated from the postHook; `IsOpen` false animates out
	local entered = q.Source(false)
	local shown: State<boolean> = handle.IsOpen:Compute(function(self, _prev, ent)
		return self:Get() and ent:Get()
	end, entered)
	local fade: State<number> = shown:Compute(function(self)
		return if self:Get() then 0 else 1
	end)
	-- the card must fit a small layer: a constant extra factor on the animated UIScale (1 when unmeasured / roomy)
	local fit = 1
	if layerSize.X > 0 and layerSize.Y > 0 then
		fit = math.min(1, (layerSize.X - 32) / WIDTH, (layerSize.Y - 32) / CARD_H)
		fit = math.max(fit, 0.25)
	end
	local scale: State<number> = shown:Compute(function(self)
		return (if self:Get() then 1 else 0.92) * fit
	end)
	local motion = Tokens.Motion.options("Short4", "Standard")

	return D.CanvasGroup {
		Name = "DatePickerModal",
		Active = true, -- 3D / camera input only; a GUI click is sunk by the InputSink child (a plain frame passes it down)
		Util.inputSink(),
		Size = UDim2.fromOffset(WIDTH, CARD_H),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = theme.Color.SurfaceContainerHigh,
		BorderSizePixel = 0,
		GroupTransparency = fade:Apply(q.Animate(motion)),
		UICorner = Tokens.Shape.corner("ExtraLarge"),
		UIScale = scale:Apply(q.Animate(motion)),
		Util.postHook(function()
			entered:Set(true)
		end),
		D.TextLabel {
			Name = "Supporting",
			supportStyle,
			Size = UDim2.fromOffset(WIDTH - 48, 16),
			Position = UDim2.fromOffset(24, 16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = supporting,
			TextColor3 = theme.Color.OnSurfaceVariant,
			TextXAlignment = Enum.TextXAlignment.Left,
		},
		D.TextLabel {
			Name = "Headline",
			headlineStyle,
			Size = UDim2.fromOffset(WIDTH - 24 - 72, 40),
			Position = UDim2.fromOffset(24, 48),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = headline,
			TextColor3 = theme.Color.OnSurface,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		},
		GlyphButton.new({
			Name = "ModeToggle",
			Glyph = toggleGlyph,
			Asset = toggleAsset,
			Position = UDim2.fromOffset(WIDTH - 12 - 40, 56),
			Theme = theme,
			OnClick = function()
				if mode:Get() == "Calendar" then
					input.Sync()
					mode:Set("Input")
				else
					mode:Set("Calendar")
				end
			end,
		}),
		D.Frame {
			Name = "Divider",
			Size = UDim2.fromOffset(WIDTH, 1),
			Position = UDim2.fromOffset(0, HEAD_H),
			BackgroundColor3 = theme.Color.OutlineVariant,
			BorderSizePixel = 0,
		},
		body.Frame,
		input.Frame,
		D.Frame {
			Name = "Actions",
			Size = UDim2.fromOffset(WIDTH, ACTIONS_H),
			Position = UDim2.fromOffset(0, HEAD_H + 1 + BODY_H),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			},
			D.UIPadding { PaddingRight = UDim.new(0, 12) },
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
					local d = draft:Get()
					if d ~= nil then
						onConfirm(d)
					end
				end,
				Modifier = D.Modifier.TextButton():LayoutOrder(2),
			}),
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
			return card(o, h, overlay.Layer.AbsoluteSize, function(date: Date)
				committed = true
				if o.Value ~= nil then
					o.Value:Set(date)
				end
				if o.OnConfirm then
					o.OnConfirm(date)
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
