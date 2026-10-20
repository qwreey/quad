--!strict
--[[
	UI strings and date patterns of the date picker, per locale key (the same keys as `Calendar.locales`: "en", "ko").
	Patterns are `Calendar.format` patterns. The input field always shows/accepts ISO `YYYY-MM-DD` first
	(`Calendar.parseLocalized` accepts more: `2026/10/5`, `2026.10.5`, `2026년 10월 5일`, English month names).
]]

local Util = require("../Util")

export type Pack = {
	SelectDate: string,
	SelectRange: string,
	EnterDate: string,
	Cancel: string,
	OK: string,
	DateLabel: string,
	Hint: string,
	MonthYear: string, -- header label of the visible month
	Headline: string, -- selected date in the modal headline
	RangeHeadline: string, -- "start - end" parts use this per date
	ErrInvalid: string,
	ErrRange: string,
	ErrDisabled: string,
	PrevMonth: string,
	NextMonth: string,
	SwitchToInput: string,
	SwitchToCalendar: string,
}

local en: Pack = {
	SelectDate = "Select date",
	SelectRange = "Select dates",
	EnterDate = "Enter date",
	Cancel = "Cancel",
	OK = "OK",
	DateLabel = "Date",
	Hint = "YYYY-MM-DD",
	MonthYear = "MMMM YYYY",
	Headline = "ddd, MMM D",
	RangeHeadline = "MMM D",
	ErrInvalid = "Invalid date (use YYYY-MM-DD)",
	ErrRange = "Date is out of range",
	ErrDisabled = "Date is not available",
	PrevMonth = "Previous month",
	NextMonth = "Next month",
	SwitchToInput = "Switch to text input",
	SwitchToCalendar = "Switch to calendar",
}

local ko: Pack = {
	SelectDate = "날짜 선택",
	SelectRange = "기간 선택",
	EnterDate = "날짜 입력",
	Cancel = "취소",
	OK = "확인",
	DateLabel = "날짜",
	Hint = "YYYY-MM-DD",
	MonthYear = "YYYY년 M월",
	Headline = "M월 D일 (ddd)",
	RangeHeadline = "M월 D일",
	ErrInvalid = "올바른 날짜가 아닙니다 (YYYY-MM-DD)",
	ErrRange = "선택할 수 있는 범위를 벗어났습니다",
	ErrDisabled = "선택할 수 없는 날짜입니다",
	PrevMonth = "이전 달",
	NextMonth = "다음 달",
	SwitchToInput = "직접 입력으로 전환",
	SwitchToCalendar = "달력으로 전환",
}

local packs: { [string]: Pack } = { en = en, ko = ko }

local function get(locale: string?): Pack
	local k = locale or "en"
	local p = packs[k]
	if not p then
		Util.fail("DatePicker", `unknown locale "{k}" (available: en, ko)`)
	end
	return p
end

return { get = get, packs = packs }
