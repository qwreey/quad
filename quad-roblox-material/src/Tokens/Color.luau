--!strict
--[[
	Material 3 color tokens — the BASELINE scheme (seed #6750A4), light and dark, from the Material Theme
	Builder default (m3.material.io/styles/color/static/baseline). Static data only; the reactive/animated
	view is `Theme.luau`.

	Role names are PascalCase of the M3 role (`onPrimaryContainer` -> `OnPrimaryContainer`). Every role is
	present in BOTH schemes (a theme can switch scheme without a role going missing).

	Not included: dynamic-color generation (HCT) and the "tone" palettes — a game that wants another seed
	passes `Overrides` to `Theme.new` with the roles it generated elsewhere.
]]

export type Role =
	"Primary"
	| "OnPrimary"
	| "PrimaryContainer"
	| "OnPrimaryContainer"
	| "Secondary"
	| "OnSecondary"
	| "SecondaryContainer"
	| "OnSecondaryContainer"
	| "Tertiary"
	| "OnTertiary"
	| "TertiaryContainer"
	| "OnTertiaryContainer"
	| "Error"
	| "OnError"
	| "ErrorContainer"
	| "OnErrorContainer"
	| "Background"
	| "OnBackground"
	| "Surface"
	| "OnSurface"
	| "SurfaceVariant"
	| "OnSurfaceVariant"
	| "SurfaceTint"
	| "SurfaceDim"
	| "SurfaceBright"
	| "SurfaceContainerLowest"
	| "SurfaceContainerLow"
	| "SurfaceContainer"
	| "SurfaceContainerHigh"
	| "SurfaceContainerHighest"
	| "Outline"
	| "OutlineVariant"
	| "InverseSurface"
	| "InverseOnSurface"
	| "InversePrimary"
	| "Shadow"
	| "Scrim"
	| "PrimaryFixed"
	| "PrimaryFixedDim"
	| "OnPrimaryFixed"
	| "OnPrimaryFixedVariant"
	| "SecondaryFixed"
	| "SecondaryFixedDim"
	| "OnSecondaryFixed"
	| "OnSecondaryFixedVariant"
	| "TertiaryFixed"
	| "TertiaryFixedDim"
	| "OnTertiaryFixed"
	| "OnTertiaryFixedVariant"

export type Scheme = { [Role]: Color3 }
export type SchemeName = "light" | "dark"

local function hex(s: string): Color3
	return Color3.fromHex(s)
end

local Light: Scheme = {
	Primary = hex("#6750A4"),
	OnPrimary = hex("#FFFFFF"),
	PrimaryContainer = hex("#EADDFF"),
	OnPrimaryContainer = hex("#4F378B"),
	Secondary = hex("#625B71"),
	OnSecondary = hex("#FFFFFF"),
	SecondaryContainer = hex("#E8DEF8"),
	OnSecondaryContainer = hex("#4A4458"),
	Tertiary = hex("#7D5260"),
	OnTertiary = hex("#FFFFFF"),
	TertiaryContainer = hex("#FFD8E4"),
	OnTertiaryContainer = hex("#633B48"),
	Error = hex("#B3261E"),
	OnError = hex("#FFFFFF"),
	ErrorContainer = hex("#F9DEDC"),
	OnErrorContainer = hex("#8C1D18"),
	Background = hex("#FEF7FF"),
	OnBackground = hex("#1D1B20"),
	Surface = hex("#FEF7FF"),
	OnSurface = hex("#1D1B20"),
	SurfaceVariant = hex("#E7E0EC"),
	OnSurfaceVariant = hex("#49454F"),
	SurfaceTint = hex("#6750A4"),
	SurfaceDim = hex("#DED8E1"),
	SurfaceBright = hex("#FEF7FF"),
	SurfaceContainerLowest = hex("#FFFFFF"),
	SurfaceContainerLow = hex("#F7F2FA"),
	SurfaceContainer = hex("#F3EDF7"),
	SurfaceContainerHigh = hex("#ECE6F0"),
	SurfaceContainerHighest = hex("#E6E0E9"),
	Outline = hex("#79747E"),
	OutlineVariant = hex("#CAC4D0"),
	InverseSurface = hex("#322F35"),
	InverseOnSurface = hex("#F5EFF7"),
	InversePrimary = hex("#D0BCFF"),
	Shadow = hex("#000000"),
	Scrim = hex("#000000"),
	PrimaryFixed = hex("#EADDFF"),
	PrimaryFixedDim = hex("#D0BCFF"),
	OnPrimaryFixed = hex("#21005D"),
	OnPrimaryFixedVariant = hex("#4F378B"),
	SecondaryFixed = hex("#E8DEF8"),
	SecondaryFixedDim = hex("#CCC2DC"),
	OnSecondaryFixed = hex("#1D192B"),
	OnSecondaryFixedVariant = hex("#4A4458"),
	TertiaryFixed = hex("#FFD8E4"),
	TertiaryFixedDim = hex("#EFB8C8"),
	OnTertiaryFixed = hex("#31111D"),
	OnTertiaryFixedVariant = hex("#633B48"),
}

local Dark: Scheme = {
	Primary = hex("#D0BCFF"),
	OnPrimary = hex("#381E72"),
	PrimaryContainer = hex("#4F378B"),
	OnPrimaryContainer = hex("#EADDFF"),
	Secondary = hex("#CCC2DC"),
	OnSecondary = hex("#332D41"),
	SecondaryContainer = hex("#4A4458"),
	OnSecondaryContainer = hex("#E8DEF8"),
	Tertiary = hex("#EFB8C8"),
	OnTertiary = hex("#492532"),
	TertiaryContainer = hex("#633B48"),
	OnTertiaryContainer = hex("#FFD8E4"),
	Error = hex("#F2B8B5"),
	OnError = hex("#601410"),
	ErrorContainer = hex("#8C1D18"),
	OnErrorContainer = hex("#F9DEDC"),
	Background = hex("#141218"),
	OnBackground = hex("#E6E0E9"),
	Surface = hex("#141218"),
	OnSurface = hex("#E6E0E9"),
	SurfaceVariant = hex("#49454F"),
	OnSurfaceVariant = hex("#CAC4D0"),
	SurfaceTint = hex("#D0BCFF"),
	SurfaceDim = hex("#141218"),
	SurfaceBright = hex("#3B383E"),
	SurfaceContainerLowest = hex("#0F0D13"),
	SurfaceContainerLow = hex("#1D1B20"),
	SurfaceContainer = hex("#211F26"),
	SurfaceContainerHigh = hex("#2B2930"),
	SurfaceContainerHighest = hex("#36343B"),
	Outline = hex("#938F99"),
	OutlineVariant = hex("#49454F"),
	InverseSurface = hex("#E6E0E9"),
	InverseOnSurface = hex("#322F35"),
	InversePrimary = hex("#6750A4"),
	Shadow = hex("#000000"),
	Scrim = hex("#000000"),
	PrimaryFixed = hex("#EADDFF"),
	PrimaryFixedDim = hex("#D0BCFF"),
	OnPrimaryFixed = hex("#21005D"),
	OnPrimaryFixedVariant = hex("#4F378B"),
	SecondaryFixed = hex("#E8DEF8"),
	SecondaryFixedDim = hex("#CCC2DC"),
	OnSecondaryFixed = hex("#1D192B"),
	OnSecondaryFixedVariant = hex("#4A4458"),
	TertiaryFixed = hex("#FFD8E4"),
	TertiaryFixedDim = hex("#EFB8C8"),
	OnTertiaryFixed = hex("#31111D"),
	OnTertiaryFixedVariant = hex("#633B48"),
}

-- Every role name, in declaration order of the baseline table above (stable iteration for Theme).
local Roles: { Role } = {}
for role in Light do
	table.insert(Roles, role)
end
table.sort(Roles)

return {
	Light = Light,
	Dark = Dark,
	Roles = Roles,
}
