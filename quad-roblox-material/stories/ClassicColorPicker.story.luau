--!strict
-- ClassicColorPicker: the faithful port of the original picker, Light and Dark side by side (the original demo's
-- layout). The window title is a plain prop, so the pair rebuilds when it changes; confirm / cancel are logged live.
-- The backdrop control only recolors the surface behind the windows (the picker has its own Light / Dark themes).
local Material = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local D = q.Declaration

local function bytes(c: Color3): string
	return `{math.floor(c.R * 255 + 0.5)}, {math.floor(c.G * 255 + 0.5)}, {math.floor(c.B * 255 + 0.5)}`
end

return StoryKit.story({
	controls = {
		Title = "Color Picker",
		Backdrop = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c)
		local log = q.Source("(press Select or Cancel)")
		local backdrop: q.State<Color3> = c.Backdrop:Compute(function(self: q.StateData<any>): Color3
			return if self:Get() == "dark" then Color3.fromRGB(32, 32, 36) else Color3.new(1, 1, 1)
		end)

		local function window(theme: "Light" | "Dark", title: string, order: number)
			return Material.ColorPicker.Classic({
				Theme = theme,
				Title = title,
				Initial = { H = 0.8, S = 0.4, V = 1 },
				LastColor = Color3.fromRGB(222, 0, 222),
				OnConfirm = function(color: Color3)
					log:Set(`[{theme} confirm] rgb({bytes(color)})`)
				end,
				OnCancel = function(last: Color3, draft: Color3)
					log:Set(`[{theme} cancel] last rgb({bytes(last)}), draft rgb({bytes(draft)})`)
				end,
				Modifier = D.Modifier.Frame():LayoutOrder(order),
			})
		end

		local pair = StoryKit.rebuild(c.Title, function(title: any)
			return D.Frame {
				Name = "Windows",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 32),
				},
				window("Light", tostring(title), 1),
				window("Dark", tostring(title), 2),
			}
		end, { Size = UDim2.fromOffset(492, 418), AutomaticSize = Enum.AutomaticSize.None, LayoutOrder = 1 })

		return D.Frame {
			Name = "ClassicColorPickerStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = backdrop,
			UIPaddingOffset = 24,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) },
			pair,
			D.TextLabel {
				Material.Text.Label("BodyMedium"),
				Name = "Log",
				LayoutOrder = 2,
				Size = UDim2.fromOffset(492, 22),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = backdrop:Compute(function(self: q.StateData<Color3>): Color3
					return if self:Get().R > 0.5 then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
				end),
				Text = log,
			},
		}
	end,
})
