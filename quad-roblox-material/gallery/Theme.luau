--!strict
--[[
	Gallery section "Theme": a light / dark Switch bound to the panel's Theme, a preview of the color roles (every
	swatch is an animated role State, so a scheme switch cross-fades all of them), and a second Theme built with
	`Overrides` (a brand color) whose scheme follows the first through one Effect.

	The Switch uses the CONTROLLED form (`Checked` + `OnChange`): `Checked` is a State derived from `theme.Scheme`, the
	Switch's OnChange writes the scheme (`theme:SetScheme`), and nothing else is needed — the Toggle button, another view
	bound to the same Theme, all flow through the one derivation (no bridge Source, no Effect). The brand Theme's scheme
	follows the panel through one Effect that writes a DIFFERENT target (`brand.Scheme`), hosted on the first brand
	Button through its `Hooks`.
]]

local q = require("./Quad")
local Common = require("./Common")
local Material = require("../src")
local Frame = q.Elem "Frame"
local TextLabel = q.Elem "TextLabel"

type Ctx = Common.Ctx
type Role = Material.Role

local PAIRS: { { Role } } = {
	{ "Primary", "OnPrimary" },
	{ "PrimaryContainer", "OnPrimaryContainer" },
	{ "Secondary", "OnSecondary" },
	{ "SecondaryContainer", "OnSecondaryContainer" },
	{ "Tertiary", "OnTertiary" },
	{ "TertiaryContainer", "OnTertiaryContainer" },
	{ "Error", "OnError" },
	{ "ErrorContainer", "OnErrorContainer" },
	{ "Surface", "OnSurface" },
	{ "SurfaceContainerHighest", "OnSurface" },
	{ "SurfaceVariant", "OnSurfaceVariant" },
	{ "InverseSurface", "InverseOnSurface" },
}

local labelStyle = Material.Text.Label("LabelMedium")

return function(ctx: Ctx): Instance
	local theme = ctx.Theme

	local dark: q.State<boolean> = theme.Scheme:Compute(function(self)
		return self:Get() == "dark"
	end)

	local brand = ctx.Memo("theme.brand", function()
		return Material.Theme.new({
			Scheme = theme.Scheme:Get(),
			Overrides = {
				Light = { Primary = Color3.fromRGB(0, 122, 108), OnPrimary = Color3.new(1, 1, 1) },
				Dark = { Primary = Color3.fromRGB(80, 218, 198), OnPrimary = Color3.fromRGB(0, 55, 48) },
			},
		})
	end)
	local follow = q.Effect(function()
		brand.Scheme:SetIfChanged(theme.Scheme:Get())
	end, theme.Scheme)

	local switchRow: { Instance } = {
		Common.Labeled(
			ctx,
			Material.Switch({
				Theme = theme,
				Checked = dark,
				OnChange = function(isDark: boolean)
					theme:SetScheme(if isDark then "dark" else "light")
				end,
			}),
			"Dark scheme"
		),
		Material.Button({
			Theme = theme,
			Variant = "Tonal",
			Label = "Toggle",
			OnClick = function()
				theme:Toggle()
			end,
		}),
		Common.Caption(ctx, theme.Scheme:Compute(function(self)
			return `Scheme: {self:Get()}`
		end), false),
	}

	local swatches: { Instance } = {}
	for _, pair in PAIRS do
		local bg, fg = pair[1], pair[2]
		table.insert(
			swatches,
			Frame {
				Name = bg,
				Size = UDim2.fromOffset(148, 56),
				BorderSizePixel = 0,
				BackgroundColor3 = theme.Color[bg],
				UICorner = UDim.new(0, 12),
				UIPaddingOffset = 8,
				TextLabel {
					labelStyle,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					TextWrapped = true,
					TextColor3 = theme.Color[fg],
					Text = bg,
				},
			}
		)
	end

	local branded: { Instance } = {
		Material.Button({ Theme = brand, Label = "Brand filled", Hooks = { follow } }),
		Material.Button({ Theme = brand, Variant = "Outlined", Label = "Brand outlined" }),
		Material.Switch({ Theme = brand, Value = q.Source(true) }),
		Material.Card({
			Theme = brand,
			Variant = "Filled",
			Padding = 12,
			Children = q.Slot<<Instance>>({ Common.Caption(ctx, "A Theme.new with Overrides (Primary only).", false) }),
		}),
	}

	return Common.Section(ctx, "Theme", "Theme", {
		Common.Group(ctx, "Scheme", switchRow, "Every bound property tweens to the new role over 300 ms."),
		Common.Group(ctx, "Role preview", swatches, "Each swatch is `theme.Color.<Role>`, an animated State<Color3>."),
		Common.Group(ctx, "Overrides", branded, "`Theme.new{ Overrides = { Light = { Primary = ... }, Dark = { ... } } }`; the scheme follows the panel through an Effect."),
	})
end
