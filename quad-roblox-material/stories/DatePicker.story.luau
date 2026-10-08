--!strict
-- DatePicker: Docked and RangeDocked side by side, plus a button that opens DatePicker.Modal in the story overlay.
-- Locale / FirstDayOfWeek / Min / Max / UtcOffset are plain construction-time props, so one combined State rebuilds the
-- two calendars; the picked dates live in Sources OUTSIDE the rebuild, so they survive it.
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local D = q.Declaration
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

local DatePicker = Material.DatePicker
local Calendar = DatePicker.Calendar

type Date = Material.Date
type Config = {
	Locale: Material.DatePickerLocale,
	FirstDayOfWeek: number,
	Min: Date?,
	Max: Date?,
	UtcOffset: number,
}

local MIN = Calendar.date(2026, 9, 15)
local MAX = Calendar.date(2026, 11, 20)

local function text(theme: Material.Theme, value: string | q.State<string>, order: number): TextLabel
	return D.TextLabel {
		Material.Text.Label("BodyMedium"),
		LayoutOrder = order,
		Size = UDim2.fromOffset(740, 22),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = theme.Color.OnSurface,
		Text = value,
	}
end

local function iso(d: Date?): string
	return if d == nil then "(none)" else Calendar.formatISO(d)
end

return StoryKit.story({
	controls = {
		Locale = StoryKit.Choose({ "en", "ko" }),
		FirstDayOfWeek = StoryKit.Slider(0, 0, 6, 1),
		MinOn = false,
		MaxOn = false,
		UtcOffsetHours = StoryKit.Slider(0, -12, 14, 1),
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c, ctx)
		local theme, follow = themed(c.Scheme)
		local docked = q.Source<<Date?>>(Calendar.date(2026, 10, 5))
		local rangeStart = q.Source<<Date?>>(nil)
		local rangeEnd = q.Source<<Date?>>(nil)
		local modalValue = q.Source<<Date?>>(nil)

		local config: q.State<Config> = c.Locale:Compute(function(self: q.StateData<any>, _prev: Config?, first: q.State<any>, minOn: q.State<any>, maxOn: q.State<any>, offset: q.State<any>): Config
			return {
				Locale = self:Get(),
				FirstDayOfWeek = first:Get(),
				Min = if minOn:Get() == true then MIN else nil,
				Max = if maxOn:Get() == true then MAX else nil,
				UtcOffset = offset:Get() * 3600,
			}
		end, c.FirstDayOfWeek, c.MinOn, c.MaxOn, c.UtcOffsetHours)

		local calendars = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			return D.Frame {
				Name = "Calendars",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 20),
				},
				DatePicker.Docked({
					Theme = theme,
					Value = docked,
					Locale = cfg.Locale,
					FirstDayOfWeek = cfg.FirstDayOfWeek,
					Min = cfg.Min,
					Max = cfg.Max,
					UtcOffset = cfg.UtcOffset,
					Modifier = D.Modifier.Frame():LayoutOrder(1),
				}),
				DatePicker.RangeDocked({
					Theme = theme,
					Start = rangeStart,
					End = rangeEnd,
					Locale = cfg.Locale,
					FirstDayOfWeek = cfg.FirstDayOfWeek,
					Min = cfg.Min,
					Max = cfg.Max,
					UtcOffset = cfg.UtcOffset,
					Modifier = D.Modifier.Frame():LayoutOrder(2),
				}),
			}
		end, { Size = UDim2.fromOffset(740, 400), AutomaticSize = Enum.AutomaticSize.None, LayoutOrder = 1 })

		return D.Frame {
			follow,
			Name = "DatePickerStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Surface,
			UIPaddingOffset = 24,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) },
			calendars,
			text(theme, docked:Compute(function(self: q.StateData<Date?>): string
				return `Docked: {iso(self:Get())}`
			end), 2),
			text(theme, rangeStart:Compute(function(self: q.StateData<Date?>, _prev: string?, finish: q.State<Date?>): string
				return `Range: {iso(self:Get())} to {iso(finish:Get())}`
			end, rangeEnd), 3),
			text(theme, modalValue:Compute(function(self: q.StateData<Date?>): string
				return `Modal (committed on OK): {iso(self:Get())}`
			end), 4),
			Material.Button({
				Theme = theme,
				Variant = "Tonal",
				Label = "Open modal picker",
				LayoutOrder = 5,
				OnClick = function()
					DatePicker.Modal.open({
						Value = modalValue,
						Locale = c.Locale:Get() :: Material.DatePickerLocale,
						FirstDayOfWeek = c.FirstDayOfWeek:Get(),
						Min = if c.MinOn:Get() == true then MIN else nil,
						Max = if c.MaxOn:Get() == true then MAX else nil,
						UtcOffset = c.UtcOffsetHours:Get() * 3600,
						Overlay = ctx.Overlay,
						Theme = theme,
					})
				end,
			}),
		}
	end,
})
