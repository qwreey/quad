--!strict
--[[
	Gallery section "Pickers": DatePicker (docked calendar, range calendar, modal in English / Korean with text-input
	mode and a UTC offset), TimePicker (the dial in 12 h and 24 h, the two-field input in 12 h and 24 h — all four on ONE
	Source<Time>, so they follow each other — and the modal: picker first, 24 h Korean, input first), ColorPicker (inline Material panel bound to one Source<Color3>, the modal with its
	draft-versus-committed behavior).

	This is the heaviest section (hundreds of instances: 42 persistent day cells per calendar, ~110 for the color
	panel). That is why sections are built lazily and destroyed when the tab is left; the selected date and colors live in
	the Memo, so coming back shows the same values.
]]

local q = require("./Quad")
local Common = require("./Common")
local Material = require("../src")

type Ctx = Common.Ctx
type Date = Material.Date
type Time = Material.Time

local Calendar = Material.DatePicker.Calendar
local Clock = Material.TimePicker.Clock

local function formatDate(d: Date?): string
	if d == nil then
		return "(no date)"
	end
	return Calendar.formatISO(d)
end

local function hex(c: Color3): string
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

return function(ctx: Ctx): Instance
	local theme = ctx.Theme

	-- dates
	local day = ctx.Memo("pick.day", function()
		return q.Source<<Date?>>(Calendar.date(2026, 10, 5))
	end)
	local rangeStart = ctx.Memo("pick.rangeStart", function()
		return q.Source<<Date?>>(nil)
	end)
	local rangeEnd = ctx.Memo("pick.rangeEnd", function()
		return q.Source<<Date?>>(nil)
	end)
	local modalDay = ctx.Memo("pick.modalDay", function()
		return q.Source<<Date?>>(nil)
	end)
	local dayText: q.State<string> = day:Compute(function(self)
		return `Docked: {formatDate(self:Get())}`
	end)
	local rangeText: q.State<string> = rangeStart:Compute(function(self, _prev, finish)
		return `Range: {formatDate(self:Get())} to {formatDate(finish:Get())}`
	end, rangeEnd)
	local modalText: q.State<string> = modalDay:Compute(function(self)
		return `Modal: {formatDate(self:Get())}`
	end)

	local docked: { Instance } = {
		Common.Column({
			Material.DatePicker.Docked({
				Theme = theme,
				Value = day,
				FirstDayOfWeek = 1,
				Min = Calendar.date(2026, 1, 1),
				Max = Calendar.date(2027, 12, 31),
				IsDisabled = function(d: Date)
					return Calendar.weekday(d) == 0 and d.Day % 2 == 0
				end,
			}),
			Common.Caption(ctx, dayText, false),
		}, 360, 8),
		Common.Column({
			Material.DatePicker.RangeDocked({
				Theme = theme,
				Start = rangeStart,
				End = rangeEnd,
				Locale = "ko",
			}),
			Common.Caption(ctx, rangeText, false),
		}, 360, 8),
	}
	local modals: { Instance } = {
		Material.Button({
			Theme = theme,
			Label = "Pick a date (en)",
			OnClick = function()
				Material.DatePicker.Modal.open({ Value = modalDay, Overlay = ctx.Overlay, Theme = theme })
			end,
		}),
		Material.Button({
			Theme = theme,
			Variant = "Tonal",
			Label = "날짜 선택 (ko, UTC+9)",
			OnClick = function()
				Material.DatePicker.Modal.open({
					Value = modalDay,
					Locale = "ko",
					UtcOffset = 9 * 3600,
					Overlay = ctx.Overlay,
					Theme = theme,
				})
			end,
		}),
		Material.Button({
			Theme = theme,
			Variant = "Outlined",
			Label = "Start in text input",
			OnClick = function()
				Material.DatePicker.Modal.open({ Value = modalDay, StartInInput = true, Overlay = ctx.Overlay, Theme = theme })
			end,
		}),
		Common.Caption(ctx, modalText, false),
	}

	-- times: one Source for the four inline pickers, one for the modal
	local time = ctx.Memo("pick.time", function()
		return q.Source<<Time>>(Clock.time(9, 30))
	end)
	local modalTime = ctx.Memo("pick.modalTime", function()
		return q.Source<<Time>>(Clock.time(18, 45))
	end)
	local timeText: q.State<string> = time:Compute(function(self)
		local t = self:Get()
		return `Value: {Clock.format(t, false)} ({Clock.format(t, true)})`
	end)
	local modalTimeText: q.State<string> = modalTime:Compute(function(self)
		return `Modal: {Clock.format(self:Get(), false)}`
	end)
	local timeDials: { Instance } = {
		Material.TimePicker.Dial({ Theme = theme, Value = time }),
		Material.TimePicker.Dial({ Theme = theme, Value = time, Is24Hour = true }),
	}
	local timeInputs: { Instance } = {
		Common.Column({
			Material.TimePicker.Input({ Theme = theme, Value = time }),
			Material.TimePicker.Input({ Theme = theme, Value = time, Is24Hour = true }),
			Common.Caption(ctx, timeText, false),
		}, 300, 16),
	}
	local timeModals: { Instance } = {
		Material.Button({
			Theme = theme,
			Label = "Pick a time",
			OnClick = function()
				Material.TimePicker.Modal.open({ Value = modalTime, Overlay = ctx.Overlay, Theme = theme })
			end,
		}),
		Material.Button({
			Theme = theme,
			Variant = "Tonal",
			Label = "시간 선택 (ko, 24 h)",
			OnClick = function()
				Material.TimePicker.Modal.open({ Value = modalTime, Is24Hour = true, Locale = "ko", Overlay = ctx.Overlay, Theme = theme })
			end,
		}),
		Material.Button({
			Theme = theme,
			Variant = "Outlined",
			Label = "Start in text input",
			OnClick = function()
				Material.TimePicker.Modal.open({ Value = modalTime, DisplayMode = "Input", Overlay = ctx.Overlay, Theme = theme })
			end,
		}),
		Common.Caption(ctx, modalTimeText, false),
	}

	-- colors
	local brand = ctx.Memo("pick.brand", function()
		return q.Source(Color3.fromRGB(103, 80, 164))
	end)
	local committed = ctx.Memo("pick.committed", function()
		return q.Source(Color3.fromRGB(0, 122, 108))
	end)
	local brandText: q.State<string> = brand:Compute(function(self)
		return `Panel value: {hex(self:Get())}`
	end)
	local committedText: q.State<string> = committed:Compute(function(self)
		return `Modal committed: {hex(self:Get())}`
	end)
	local swatch = q.Elem "Frame" {
		Name = "ModalSwatch",
		Size = UDim2.fromOffset(48, 48),
		BorderSizePixel = 0,
		BackgroundColor3 = committed,
		UICorner = UDim.new(0, 12),
	}
	local panel: { Instance } = {
		Common.Column({
			Material.ColorPicker.Panel({ Theme = theme, Value = brand }),
			Common.Caption(ctx, brandText, false),
		}, 360, 8),
	}
	local colorModal: { Instance } = {
		Material.Button({
			Theme = theme,
			Label = "Choose color",
			OnClick = function()
				Material.ColorPicker.Modal.open({
					Theme = theme,
					Overlay = ctx.Overlay,
					Value = committed:Get(),
					Title = "Brand color",
					OnConfirm = function(c: Color3)
						committed:Set(c)
					end,
				})
			end,
		}),
		swatch,
		Common.Caption(ctx, committedText, false),
	}

	return Common.Section(ctx, "Pickers", "Pickers", {
		Common.Group(ctx, "DatePicker: docked and range", docked, "Docked: Monday first, 2026-2027 only, even Sundays disabled. Range: Korean."),
		Common.Group(ctx, "DatePicker: modal", modals, "Cancel and the scrim keep the old value; OK writes it."),
		Common.Group(ctx, "TimePicker: dial (12 h, 24 h)", timeDials, "Tap or drag the dial; an hour pick moves on to the minutes. The boxes above switch hour / minute; 24 h has an inner ring for 12-23."),
		Common.Group(ctx, "TimePicker: input (12 h, 24 h)", timeInputs, "Digits only; 12 h takes 1-12 in the period of the AM / PM toggle. All four pickers share one value."),
		Common.Group(ctx, "TimePicker: modal", timeModals, "The keyboard / clock button switches input and dial; Cancel and the scrim keep the old value; OK writes it."),
		Common.Group(ctx, "ColorPicker: panel", panel, "One Source<Color3> in; the picker keeps its own HSV so hue survives black and grey."),
		Common.Group(ctx, "ColorPicker: modal", colorModal, "Edits a draft; only OK commits."),
	})
end
