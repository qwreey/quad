--!strict
--[[
	Gallery section "Pickers": DatePicker (docked calendar, range calendar, modal in English / Korean with text-input
	mode and a UTC offset), ColorPicker (inline Material panel bound to one Source<Color3>, the modal with its
	draft-versus-committed behavior, and the Classic port of the original picker for comparison — see
	docs/colorpicker-comparison.md).

	This is the heaviest section (hundreds of instances: 42 persistent day cells per calendar, ~110 for the color
	panel). That is why sections are built lazily and destroyed when the tab is left; the selected date and colors live in
	the Memo, so coming back shows the same values.
]]

local q = require("../Quad")
local Common = require("./Common")
local Button = require("../Button")
local DatePicker = require("../DatePicker")
local ColorPicker = require("../ColorPicker")

type Ctx = Common.Ctx
type Date = DatePicker.Date

local Calendar = DatePicker.Calendar

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
			DatePicker.Docked({
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
			DatePicker.RangeDocked({
				Theme = theme,
				Start = rangeStart,
				End = rangeEnd,
				Locale = "ko",
			}),
			Common.Caption(ctx, rangeText, false),
		}, 360, 8),
	}
	local modals: { Instance } = {
		Button({
			Theme = theme,
			Label = "Pick a date (en)",
			OnClick = function()
				DatePicker.Modal.open({ Value = modalDay, Overlay = ctx.Overlay, Theme = theme })
			end,
		}),
		Button({
			Theme = theme,
			Variant = "Tonal",
			Label = "날짜 선택 (ko, UTC+9)",
			OnClick = function()
				DatePicker.Modal.open({
					Value = modalDay,
					Locale = "ko",
					UtcOffset = 9 * 3600,
					Overlay = ctx.Overlay,
					Theme = theme,
				})
			end,
		}),
		Button({
			Theme = theme,
			Variant = "Outlined",
			Label = "Start in text input",
			OnClick = function()
				DatePicker.Modal.open({ Value = modalDay, StartInInput = true, Overlay = ctx.Overlay, Theme = theme })
			end,
		}),
		Common.Caption(ctx, modalText, false),
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
	local swatch = q.Declaration.Frame {
		Name = "ModalSwatch",
		Size = UDim2.fromOffset(48, 48),
		BorderSizePixel = 0,
		BackgroundColor3 = committed,
		UICorner = UDim.new(0, 12),
	}
	local panel: { Instance } = {
		Common.Column({
			ColorPicker.Panel({ Theme = theme, Value = brand }),
			Common.Caption(ctx, brandText, false),
		}, 360, 8),
	}
	local colorModal: { Instance } = {
		Button({
			Theme = theme,
			Label = "Choose color",
			OnClick = function()
				ColorPicker.Modal.open({
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
	local scheme = theme.Scheme:Get()
	local classic: { Instance } = {
		ColorPicker.Classic({ Theme = if scheme == "dark" then "Dark" else "Light", Title = "Classic picker" }),
		Common.Caption(
			ctx,
			"The near-identical port of the original OOP picker (own look, 0..255 scale). It reads the scheme once, at construction; see docs/colorpicker-comparison.md for the differences.",
			true
		),
	}

	return Common.Section(ctx, "Pickers", "Pickers", {
		Common.Group(ctx, "DatePicker: docked and range", docked, "Docked: Monday first, 2026-2027 only, even Sundays disabled. Range: Korean."),
		Common.Group(ctx, "DatePicker: modal", modals, "Cancel and the scrim keep the old value; OK writes it."),
		Common.Group(ctx, "ColorPicker: panel", panel, "One Source<Color3> in; the picker keeps its own HSV so hue survives black and grey."),
		Common.Group(ctx, "ColorPicker: modal", colorModal, "Edits a draft; only OK commits."),
		Common.Group(ctx, "ColorPicker: Classic", classic),
	})
end
