--!strict
-- ColorPicker: the Material Panel bound to ONE Source<Color3> (shown live as a swatch + hex text, and writable from the
-- "Randomize" button to show the outside-write path), Disabled as a State, and a button that opens ColorPicker.Modal.
-- ShowChannels / AreaHeight are plain props, so one combined State rebuilds the panel (the Source survives).
local Material = require("../src")
local q = require("./Quad")
local StoryKit = require("./StoryKit")
local D = q.Declaration
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

type Config = { ShowChannels: boolean, AreaHeight: number }

local function hex(c: Color3): string
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

return StoryKit.story({
	controls = {
		ShowChannels = true,
		AreaHeight = StoryKit.Slider(160, 100, 240, 10),
		Disabled = false,
		Scheme = StoryKit.Choose({ "light", "dark" }),
	},
	render = function(c, ctx)
		local theme, follow = themed(c.Scheme)
		local brand = q.Source(Color3.fromRGB(103, 80, 164))
		local changes = q.Source(0)

		local config: q.State<Config> = c.ShowChannels:Compute(function(self: q.StateData<any>, _prev: Config?, height: q.State<any>): Config
			return { ShowChannels = self:Get() == true, AreaHeight = height:Get() }
		end, c.AreaHeight)

		local panel = StoryKit.rebuild<<Config>>(config, function(cfg: Config)
			return Material.ColorPicker.Panel({
				Theme = theme,
				Value = brand,
				ShowChannels = cfg.ShowChannels,
				AreaHeight = cfg.AreaHeight,
				Disabled = c.Disabled,
				OnChange = function()
					changes:Set(changes:Get() + 1)
				end,
			})
		end, { Size = UDim2.fromOffset(360, 560), AutomaticSize = Enum.AutomaticSize.None, LayoutOrder = 1 })

		return D.Frame {
			follow,
			Name = "ColorPickerStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Surface,
			UIPaddingOffset = 24,
			D.UIListLayout {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 32),
			},
			panel,
			D.Frame {
				Name = "Side",
				LayoutOrder = 2,
				Size = UDim2.fromOffset(240, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) },
				D.Frame {
					Name = "Swatch",
					LayoutOrder = 1,
					Size = UDim2.fromOffset(240, 96),
					BorderSizePixel = 0,
					BackgroundColor3 = brand,
					UICorner = UDim.new(0, 16),
				},
				D.TextLabel {
					Material.Text.Label("TitleMedium"),
					Name = "Hex",
					LayoutOrder = 2,
					Size = UDim2.fromOffset(240, 24),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = theme.Color.OnSurface,
					Text = brand:Compute(function(self: q.StateData<Color3>): string
						return hex(self:Get())
					end),
				},
				D.TextLabel {
					Material.Text.Label("BodyMedium"),
					Name = "Changes",
					LayoutOrder = 3,
					Size = UDim2.fromOffset(240, 20),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = theme.Color.OnSurfaceVariant,
					Text = changes:Compute(function(self: q.StateData<number>): string
						return `OnChange fired {self:Get()} times (user edits only)`
					end),
				},
				Material.Button({
					Theme = theme,
					Variant = "Tonal",
					Label = "Open modal",
					LayoutOrder = 4,
					OnClick = function()
						Material.ColorPicker.Modal.open({
							Value = brand:Get(),
							Title = "Brand color",
							OnConfirm = function(color: Color3)
								brand:Set(color)
							end,
							Overlay = ctx.Overlay,
							Theme = theme,
						})
					end,
				}),
				Material.Button({
					Theme = theme,
					Variant = "Outlined",
					Label = "Randomize (outside write)",
					LayoutOrder = 5,
					OnClick = function()
						brand:Set(Color3.fromHSV(math.random(), 0.6 + math.random() * 0.4, 0.5 + math.random() * 0.5))
					end,
				}),
			},
		}
	end,
})
