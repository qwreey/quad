--!strict
--[[
	Time pickers (Material 3): the DIAL (clock face) and the INPUT (two text fields), inline or in a modal dialog —
	Compose material3 `TimePicker` / `TimeInput` / `TimePickerDialog` (androidx/androidx@40ff481, compose/material3/
	material3/src/commonMain/kotlin/androidx/compose/material3/TimePicker.kt, TimePickerDialog.kt, tokens/TimePickerTokens.kt,
	tokens/TimeInputTokens.kt) — the M3 spec's "dial" and "input" (m3.material.io/components/time-pickers).

	    local TimePicker = Material.TimePicker
	    local t = q.Source(TimePicker.Clock.time(9, 30))           -- Source<Time>
	    TimePicker.Dial({ Value = t })                             -- the clock face (+ hour / minute boxes, AM/PM)
	    TimePicker.Input({ Value = t, Is24Hour = true })           -- the two fields
	    TimePicker.Modal.open({ Value = t, OnConfirm = save })     -- the dialog (dial <-> input toggle, Cancel / OK)
	    TimePicker.Clock                                           -- the pure time math (no engine)

	The value is the frozen `Clock.Time = { Hour (0-23), Minute (0-59) }` — Compose `TimePickerState.hour` / `.minute`;
	`Is24Hour` is Compose's `is24hour`, the dial / input mode is Compose's `selection` (internal), the dialog's
	`DisplayMode` is Compose's TimePickerDisplayMode ("Picker" | "Input"), the dial's `LayoutType` Compose's
	TimePickerLayoutType ("Vertical" | "Horizontal"). The UI never reads the machine's time zone (`Clock.now(nil, offset)`).

	Files: Clock (math) / Strings (Compose's texts, en / ko) / Model (the shared TimePickerState) / Parts (time selector
	box, ":" separator, AM/PM toggle) / ClockFace (the dial) / Dial / Input / Modal.
]]

local Clock = require("@self/Clock")
local Dial = require("@self/Dial")
local Input = require("@self/Input")
local Modal = require("@self/Modal")

export type Time = Clock.Time
export type Locale = Dial.Locale
export type LayoutType = Dial.LayoutType
export type DisplayMode = Modal.DisplayMode
export type DialProps = Dial.Props
export type InputProps = Input.Props
export type ModalOptions = Modal.OpenOptions

return {
	Dial = Dial.Dial,
	Input = Input.Input,
	Modal = Modal,
	Clock = Clock,
}
