--!strict
-- TimePicker: the Dial and the Input side by side on ONE Source<Time>, plus a button that opens TimePicker.Modal in the story
-- overlay. Is24Hour / LayoutType / Locale are plain construction-time props, so one combined State rebuilds the two
-- pickers; the time lives in a Source OUTSIDE the rebuild, so it survives it.
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local D = q.Declaration
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

local TimePicker = Material.TimePicker
local Clock = TimePicker.Clock

type Time = Material.Time
type Config = {
	Is24Hour: boolean,
	LayoutType: Material.TimePickerLayoutType,
	Locale: Material.TimePickerLocale,
}

local function text(theme: Material.Theme, value: string | q.State<string>, order: number): TextLabel
	return D.TextLabel {
		Material.Text.Label("BodyMedium"),
		LayoutOrder = order,
		Size = UDim2.fromOffset(820, 22),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = theme.Color.OnSurface,
		Text = value,
	}
end

return StoryKit.story({
	controls = {
		Is24Hour = false,
		LayoutType = StoryKit.Choose({ "Vertical", "Horizontal" }),
		Locale = StoryKit.Choose({ "en", "ko" }),
		StartInInput = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c, ctx)
		local theme, follow = themed(c.Scheme)
		local time = q.Source<<Time>>(Clock.time(9, 30))
		local modalTime = q.Source<<Time>>(Clock.time(18, 45))

		local config: q.State<Config> = c.Is24Hour:Compute(function(self: q.StateData<any>, _prev: Config?, layout: q.State<any>, locale: q.State<any>): Config
			return {
				Is24Hour = self:Get() == true,
				LayoutType = layout:Get(),
				Locale = locale:Get(),
			}
		end, c.LayoutType, c.Locale)

		local pickers = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			return D.Frame {
				Name = "Pickers",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 24),
				},
				TimePicker.Dial({
					Theme = theme,
					Value = time,
					Is24Hour = cfg.Is24Hour,
					LayoutType = cfg.LayoutType,
					Locale = cfg.Locale,
					Modifier = D.Modifier.Frame():LayoutOrder(1),
				}),
				TimePicker.Input({
					Theme = theme,
					Value = time,
					Is24Hour = cfg.Is24Hour,
					Locale = cfg.Locale,
					Modifier = D.Modifier.Frame():LayoutOrder(2),
				}),
			}
		end, { Size = UDim2.fromOffset(820, 400), AutomaticSize = Enum.AutomaticSize.None, LayoutOrder = 1 })

		return D.Frame {
			follow,
			Name = "TimePickerStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Surface,
			UIPaddingOffset = 24,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) },
			pickers,
			text(theme, time:Compute(function(self: q.StateData<Time>): string
				local t = self:Get()
				return `Value: {Clock.format(t, false)} ({Clock.format(t, true)})`
			end), 2),
			text(theme, modalTime:Compute(function(self: q.StateData<Time>): string
				return `Modal (committed on OK): {Clock.format(self:Get(), true)}`
			end), 3),
			Material.Button({
				Theme = theme,
				Variant = "Tonal",
				Label = "Open modal picker",
				Modifier = D.Modifier.TextButton():LayoutOrder(4),
				OnClick = function()
					TimePicker.Modal.open({
						Value = modalTime,
						Is24Hour = c.Is24Hour:Get() == true,
						Locale = c.Locale:Get() :: Material.TimePickerLocale,
						DisplayMode = if c.StartInInput:Get() == true then "Input" else "Picker",
						Overlay = ctx.Overlay,
						Theme = theme,
					})
				end,
			}),
		}
	end,
})
