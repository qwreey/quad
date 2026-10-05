--!strict
--[[
	Material 3 elevation levels 0-5 (dp: 0, 1, 3, 6, 8, 12) mapped onto ONE `UIShadow`.

	M3 draws each level as two stacked CSS shadows (key + ambient). Roblox's `UIShadow` is a single
	shadow, so each level here is the visual average of the two M3 layers:
	  BlurRadius   px   softness (UIShadow.BlurRadius is a UDim — Offset component = this number)
	  OffsetY      px   vertical offset (the key light sits above)
	  Spread       px   grow (UIShadow.Spread is a UDim2; both axes get this number)
	  Transparency 0..1 shadow transparency (UIShadow.Transparency); higher level = darker shadow
	The shadow COLOR is the theme's `Shadow` role (black in the baseline scheme).

	These are APPROXIMATIONS tuned by eye against the M3 reference elevations, not exact conversions —
	retune here (one place) after looking at it on a device. Level 0 means "no shadow" (`Enabled = false`).

	Surface-tint overlays (the dark-theme "lighter surface at higher elevation") are NOT applied here:
	pick the matching `SurfaceContainer*` role for the surface color instead (that is what M3 2023+ does).
]]

export type Level = { Dp: number, BlurRadius: number, OffsetY: number, Spread: number, Transparency: number }

local Levels: { [number]: Level } = {
	[0] = { Dp = 0, BlurRadius = 0, OffsetY = 0, Spread = 0, Transparency = 1 },
	[1] = { Dp = 1, BlurRadius = 3, OffsetY = 1, Spread = 0, Transparency = 0.78 },
	[2] = { Dp = 3, BlurRadius = 6, OffsetY = 2, Spread = 1, Transparency = 0.74 },
	[3] = { Dp = 6, BlurRadius = 8, OffsetY = 4, Spread = 2, Transparency = 0.72 },
	[4] = { Dp = 8, BlurRadius = 10, OffsetY = 6, Spread = 3, Transparency = 0.7 },
	[5] = { Dp = 12, BlurRadius = 12, OffsetY = 8, Spread = 4, Transparency = 0.68 },
}

local MaxLevel = 5

-- Clamp + floor an arbitrary number to a defined level.
local function levelOf(n: number): Level
	local i = math.clamp(math.floor(n + 0.5), 0, MaxLevel)
	return Levels[i]
end

return {
	Levels = Levels,
	MaxLevel = MaxLevel,
	levelOf = levelOf,
}
