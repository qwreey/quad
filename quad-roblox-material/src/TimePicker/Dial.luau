--!strict
--[[
	M3 time picker, DIAL form — Compose `TimePicker(state, modifier, colors, layoutType)` (TimePicker.kt =
	androidx/androidx@40ff481 compose/material3/material3/src/commonMain/kotlin/androidx/compose/material3/TimePicker.kt
	248-266, TimePickerImpl 466-506, VerticalTimePicker 1958-1985, HorizontalTimePicker 1987-2013).

	    local t = q.Source(Material.TimePicker.Clock.time(9, 30))
	    Material.TimePicker.Dial({ Value = t, Is24Hour = false, LayoutType = "Vertical" })

	Props (all `read`)
	  Value        Source<Time>                 the time (two-way: the dial, the hour/minute boxes' mode and the AM/PM
	                                            toggle write it; an outside `:Set` shows it — the hand snaps there)
	  Is24Hour     boolean?                     Compose `is24Hour` (default false — Compose follows the device's
	                                            setting, which Roblox does not have): 24 h = no AM/PM toggle, a second
	                                            (inner) ring of hours 12..23
	  LayoutType   ("Vertical" | "Horizontal")? Compose `TimePickerLayoutType` (default "Vertical" — Compose's default
	                                            reads the window: Horizontal when it is wider than tall; a component has
	                                            no window when it is built, the Modal applies Compose's rule)
	  Locale       ("en" | "ko")?               the AM / PM texts (Compose's resources)
	  OnChange     ((Time) -> ())?              after Value was set by a USER action (tap, drag, key, AM/PM)
	  Theme, Modifier (Frame Modifier, applied after the base), Hooks    as every kit component
	Returns the host Frame (transparent — Compose's TimePicker has no container; the dialog draws one).

	LAYOUT (px = dp)
	  Vertical  (VerticalTimePicker): a column, centered — the display row (hour box 96 x 80, ":" 24, minute box 96 x 80,
	            then 4 + the vertical AM/PM toggle 52 x 80 in 12 h), 36 (ClockDisplayBottomMargin), the 256 dial, 24
	            (ClockFaceBottomMargin). 12 h 272 x 396, 24 h 256 x 396.
	  Horizontal (HorizontalTimePicker): a row, centered vertically — a column (the display row 216 x 80, then 16 + the
	            horizontal toggle 216 x 38 in 12 h — HorizontalClockDisplay 2383-2410), 36, the dial. 508 x 256. Compose
	            shrinks the dial to 238 / 200 when less than 384 / 330 dp of height is available (ClockFaceSizeModifier
	            4115-4132); a kit component has no measuring pass, the dial stays 256.
	The display row: Parts.selector (hour shows `hourForDisplay`, "07"), Parts.separator, Parts.periodToggle; clicking a
	box switches the dial between hours and minutes (Compose TimeSelector onClick). See ClockFace.luau for the dial.

	Instances (Vertical, 12 h): host + display (2 boxes x 6 + ":" + toggle 13) + dial 62 + the inner frame = 90; 24 h: host + inner frame + 13 + 86 = 101.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")
local Clock = require("./Clock")
local Model = require("./Model")
local Parts = require("./Parts")
local ClockFace = require("./ClockFace")
local D = q.Declaration

type State<T> = q.State<T>
type Time = Clock.Time

export type LayoutType = "Vertical" | "Horizontal"
export type Locale = "en" | "ko"

export type Props = {
	read Value: q.Source<Time>,
	read Is24Hour: boolean?,
	read LayoutType: LayoutType?,
	read Locale: Locale?,
	read OnChange: ((time: Time) -> ())?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local BOX_W, BOX_H = 96, 80 -- TimeSelectorContainerWidth / Height
local SEP_W = 24 -- DisplaySeparatorWidth
local TOGGLE_GAP = 4 -- PeriodTogglePaddingSmall (isUpdatedTimepickerToggleEnabled)
local V_TOGGLE = Vector2.new(52, 80) -- PeriodSelectorVerticalContainerWidth / Height
local H_TOGGLE = Vector2.new(216, 38) -- PeriodSelectorHorizontalContainerWidth / Height
local H_TOGGLE_TOP = 16 -- VibrantPeriodToggleLargePadding (used by the default style too, 2391)
local DISPLAY_GAP = 36 -- ClockDisplayBottomMargin
local FACE_BOTTOM = 24 -- ClockFaceBottomMargin
local DIAL = ClockFace.Size

export type BuildOptions = {
	Model: Model.Model,
	Theme: Theme.Theme,
	Locale: string,
	LayoutType: LayoutType,
	Name: string?,
	Position: UDim2?,
	Visible: (boolean | State<boolean>)?,
}

-- the size a layout takes (Modal sizes its card from it)
local function size(layout: LayoutType, is24: boolean): Vector2
	if layout == "Horizontal" then
		return Vector2.new(BOX_W * 2 + SEP_W + DISPLAY_GAP + DIAL, DIAL)
	end
	local row = BOX_W * 2 + SEP_W + (if is24 then 0 else TOGGLE_GAP + V_TOGGLE.X)
	return Vector2.new(math.max(row, DIAL), BOX_H + DISPLAY_GAP + DIAL + FACE_BOTTOM)
end

local function display(o: BuildOptions, at: Vector2, extra: { Instance })
	local model = o.Model
	local theme = o.Theme
	local is24 = model.Is24Hour
	local hourText: State<string> = model.Value:Compute(function(self)
		return Clock.pad2(Clock.hourForDisplay(self:Get().Hour, is24))
	end)
	local minuteText: State<string> = model.Value:Compute(function(self)
		return Clock.pad2(self:Get().Minute)
	end)
	local function selected(kind: Clock.Selection): State<boolean>
		return model.Selection:Compute(function(self)
			return self:Get() == kind
		end)
	end
	table.insert(
		extra,
		Parts.selector({
			Name = "HourSelector",
			Theme = theme,
			Selected = selected("Hour"),
			Text = hourText,
			Size = Vector2.new(BOX_W, BOX_H),
			Position = UDim2.fromOffset(at.X, at.Y),
			Role = "DisplayLarge",
			OnClick = function()
				model.Selection:SetIfChanged("Hour")
			end,
		})
	)
	table.insert(extra, Parts.separator({ Theme = theme, Role = "DisplayLarge", Height = BOX_H, Position = UDim2.fromOffset(at.X + BOX_W, at.Y) }))
	table.insert(
		extra,
		Parts.selector({
			Name = "MinuteSelector",
			Theme = theme,
			Selected = selected("Minute"),
			Text = minuteText,
			Size = Vector2.new(BOX_W, BOX_H),
			Position = UDim2.fromOffset(at.X + BOX_W + SEP_W, at.Y),
			Role = "DisplayLarge",
			OnClick = function()
				model.Selection:SetIfChanged("Minute")
			end,
		})
	)
end

export type Built = { read Frame: Frame, read Size: Vector2 }

local function build(o: BuildOptions): Built
	local model = o.Model
	local is24 = model.Is24Hour
	local layout = o.LayoutType
	local total = size(layout, is24)
	local children: { Instance } = {}
	if layout == "Horizontal" then
		local colH = BOX_H + (if is24 then 0 else H_TOGGLE_TOP + H_TOGGLE.Y)
		local top = math.floor((DIAL - colH) / 2)
		display(o, Vector2.new(0, top), children)
		if not is24 then
			table.insert(
				children,
				Parts.periodToggle({
					Theme = o.Theme,
					Model = model,
					Locale = o.Locale,
					Horizontal = true,
					Size = H_TOGGLE,
					Position = UDim2.fromOffset(0, top + BOX_H + H_TOGGLE_TOP),
				})
			)
		end
		table.insert(children, ClockFace.new({ Theme = o.Theme, Model = model, Position = UDim2.fromOffset(BOX_W * 2 + SEP_W + DISPLAY_GAP, 0) }))
	else
		local row = BOX_W * 2 + SEP_W + (if is24 then 0 else TOGGLE_GAP + V_TOGGLE.X)
		local rowX = math.floor((total.X - row) / 2)
		display(o, Vector2.new(rowX, 0), children)
		if not is24 then
			table.insert(
				children,
				Parts.periodToggle({
					Theme = o.Theme,
					Model = model,
					Locale = o.Locale,
					Horizontal = false,
					Size = V_TOGGLE,
					Position = UDim2.fromOffset(rowX + BOX_W * 2 + SEP_W + TOGGLE_GAP, 0),
				})
			)
		end
		table.insert(children, ClockFace.new({ Theme = o.Theme, Model = model, Position = UDim2.fromOffset(math.floor((total.X - DIAL) / 2), BOX_H + DISPLAY_GAP) }))
	end
	local frame = D.Frame {
		Name = o.Name or "TimePicker",
		Size = UDim2.fromOffset(total.X, total.Y),
		Position = o.Position or UDim2.new(),
		Visible = Util.visible(o.Visible),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		table.unpack(children),
	}
	return { Frame = frame, Size = total }
end

local function Dial(props: Props): Frame
	local theme = Theme.resolve(props.Theme)
	local model = Model.new({ Value = props.Value, Is24Hour = props.Is24Hour == true, OnChange = props.OnChange })
	local layout: LayoutType = props.LayoutType or "Vertical"
	local built = build({ Model = model, Theme = theme, Locale = props.Locale or "en", LayoutType = layout })
	local total = built.Size
	return D.Frame {
		Name = "TimePickerDial",
		D.Modifier.Frame():Size(UDim2.fromOffset(total.X, total.Y)):BorderSizePixel(0):BackgroundTransparency(1),
		props.Modifier or q.None,
		model.Sync,
		built.Frame,
		table.unpack(Util.hooks(props.Hooks)),
	}
end

return { Dial = Dial, build = build, size = size }
