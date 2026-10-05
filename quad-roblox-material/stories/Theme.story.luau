--!strict
-- Theme: every color role of a per-story `Theme.new` as a live swatch (animated States — the Scheme control
-- cross-fades them all), and a second theme built with `Overrides` from the Brand color control (a different seed is a
-- different Theme, so the brand row rebuilds) with real components on it. `Theme.default` is never touched.
local Material = require("../src")
local q = require("../src/Quad")
local StoryKit = require("./StoryKit")
local D = q.Declaration
local StoryParts = require("./StoryParts")
local themed = StoryParts.themed

local ROLES: { Material.Role } = {
	"Primary", "OnPrimary", "PrimaryContainer", "OnPrimaryContainer",
	"Secondary", "OnSecondary", "SecondaryContainer", "OnSecondaryContainer",
	"Tertiary", "OnTertiary", "TertiaryContainer", "OnTertiaryContainer",
	"Error", "OnError", "ErrorContainer", "OnErrorContainer",
	"Background", "OnBackground", "Surface", "OnSurface",
	"SurfaceVariant", "OnSurfaceVariant", "SurfaceDim", "SurfaceBright",
	"SurfaceContainerLowest", "SurfaceContainerLow", "SurfaceContainer", "SurfaceContainerHigh",
	"SurfaceContainerHighest", "Outline", "OutlineVariant", "InverseSurface",
	"InverseOnSurface", "InversePrimary", "Shadow", "Scrim",
}

local function text(theme: Material.Theme, value: string | q.State<string>, order: number): TextLabel
	return D.TextLabel {
		Material.Text.Label("TitleMedium"),
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = theme.Color.OnSurface,
		Text = value,
	}
end

return StoryKit.story({
	controls = {
		Scheme = StoryKit.Choose({ "light", "dark" }),
		Brand = Color3.fromRGB(0, 122, 108),
	},
	render = function(c)
		local theme, follow = themed(c.Scheme)

		local cells: { Instance } = {}
		for i, role in ROLES do
			table.insert(
				cells,
				D.Frame {
					Name = role,
					LayoutOrder = i,
					Size = UDim2.fromOffset(112, 72),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) },
					D.Frame {
						Name = "Swatch",
						LayoutOrder = 1,
						Size = UDim2.new(1, 0, 0, 44),
						BorderSizePixel = 0,
						BackgroundColor3 = theme.Color[role],
						UICorner = UDim.new(0, 8),
						D.UIStroke { Color = theme.Color.OutlineVariant, Thickness = 1 },
					},
					D.TextLabel {
						Material.Text.Label("LabelSmall"),
						LayoutOrder = 2,
						Size = UDim2.new(1, 0, 0, 16),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextColor3 = theme.Color.OnSurface,
						Text = role,
					},
				}
			)
		end

		local brandRow = StoryKit.rebuild(c.Brand, function(seed: any)
			local brand = Material.Theme.new({
				Scheme = c.Scheme:Get(),
				Overrides = {
					Light = { Primary = seed :: Color3 },
					Dark = { Primary = seed :: Color3 },
				},
			})
			local follow2 = q.Effect(function()
				brand.Scheme:SetIfChanged(c.Scheme:Get())
			end, c.Scheme)
			return D.Frame {
				follow2,
				Name = "BrandRow",
				Size = UDim2.fromScale(1, 1),
				BorderSizePixel = 0,
				BackgroundColor3 = brand.Color.Surface,
				UICorner = UDim.new(0, 16),
				UIPaddingOffset = 16,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 12),
				},
				Material.Button({ Theme = brand, Label = "Filled", LayoutOrder = 1 }),
				Material.Button({ Theme = brand, Variant = "Outlined", Label = "Outlined", LayoutOrder = 2 }),
				Material.Switch({ Theme = brand, Value = q.Source(true), Modifier = D.Modifier.TextButton():LayoutOrder(3) }),
				Material.LinearProgress({ Theme = brand, Value = 0.6, Modifier = D.Modifier.Frame():LayoutOrder(4) }),
			}
		end, { Size = UDim2.new(1, 0, 0, 80), AutomaticSize = Enum.AutomaticSize.None, LayoutOrder = 4 })

		return D.Frame {
			follow,
			Name = "ThemeStory",
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = theme.Color.Surface,
			UIPaddingOffset = 24,
			D.UIListLayout { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) },
			text(theme, c.Scheme:Compute(function(self: q.StateData<any>): string
				return `Color roles — scheme: {self:Get()}`
			end), 1),
			D.Frame {
				Name = "Palette",
				LayoutOrder = 2,
				Size = UDim2.fromOffset(960, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				D.UIListLayout {
					FillDirection = Enum.FillDirection.Horizontal,
					Wraps = true,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				},
				q.Slot<<Instance>>(cells),
			},
			text(theme, "Brand theme (Overrides.Primary from the Brand control)", 3),
			brandRow,
		}
	end,
})
