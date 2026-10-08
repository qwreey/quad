--!strict
--[[
	UI strings of the time picker per locale key ("en", "ko" — the date picker's keys). The texts are Compose's own
	resources: androidx/androidx@40ff481 compose/material3/material3/src/androidMain/res/values/strings.xml 98-138
	(m3c_time_picker_*, m3c_time_input_dialog_title) and values-ko/strings.xml (the same names). Cancel / OK are the kit
	date picker's (Compose's samples spell them "Cancel" / "Ok" — TimePickerSamples.kt 195, 198; the kit keeps one "OK").
]]

export type Pack = {
	AM: string,
	PM: string,
	SelectTime: string, -- m3c_time_picker_dialog_title
	EnterTime: string, -- m3c_time_input_dialog_title
	Hour: string, -- m3c_time_picker_hour (the input field's supporting text)
	Minute: string, -- m3c_time_picker_minute
	HourError: string, -- m3c_time_picker_hour_error (12 h)
	HourError24: string, -- m3c_time_picker_hour_error_24h
	MinuteError: string, -- m3c_time_picker_minute_error
	ToKeyboard: string, -- m3c_time_picker_toggle_keyboard
	ToClock: string, -- m3c_time_picker_toggle_touch
	Cancel: string,
	OK: string,
}

local en: Pack = {
	AM = "AM",
	PM = "PM",
	SelectTime = "Select Time",
	EnterTime = "Enter Time",
	Hour = "Hour",
	Minute = "Minute",
	HourError = "Hour must be 1\u{2013}12",
	HourError24 = "Hour must be 0\u{2013}23",
	MinuteError = "Minute must be 0\u{2013}59",
	ToKeyboard = "Switch to text input mode",
	ToClock = "Switch to clock mode",
	Cancel = "Cancel",
	OK = "OK",
}

local ko: Pack = {
	AM = "오전",
	PM = "오후",
	SelectTime = "시간 선택",
	EnterTime = "시간 입력",
	Hour = "시간",
	Minute = "분",
	HourError = "시간은 1~12여야 함",
	HourError24 = "시간은 0~23이어야 함",
	MinuteError = "분은 0~59여야 함",
	ToKeyboard = "텍스트 입력 모드로 전환",
	ToClock = "시계 모드로 전환",
	Cancel = "취소",
	OK = "확인",
}

local packs: { [string]: Pack } = { en = en, ko = ko }

local function get(locale: string?): Pack
	local k = locale or "en"
	local p = packs[k]
	if not p then
		error(`TimePicker: unknown locale "{k}" (available: en, ko)`, 3)
	end
	return p
end

return { get = get, packs = packs }
