--!strict
--[[
	Material 3 type scale (m3.material.io/styles/typography/type-scale-tokens) — baseline values.

	Every entry: `Size` (px, used as `TextSize`), `LineHeight` (px, spec value), `Weight` (400 regular /
	500 medium), `Tracking` (px, spec letter-spacing; Roblox has no letter-spacing property, kept for
	documentation and for consumers that lay out glyphs themselves).

	Font family: M3's reference face is Roboto. Roblox ships it as the built-in family
	`rbxasset://fonts/families/Roboto.json` (no asset upload needed). If a place ever lacks it, use
	`Typography.font(role, Typography.FallbackFamily)` (GothamSSm — closest geometric fallback that ships
	with every client) or any family you own.

	This module is pure data + one function that builds a `Font` at call time (no engine global is read at
	require time, so it loads under plain `luau`).
]]

export type Entry = { Size: number, LineHeight: number, Weight: number, Tracking: number }
export type Role =
	"DisplayLarge"
	| "DisplayMedium"
	| "DisplaySmall"
	| "HeadlineLarge"
	| "HeadlineMedium"
	| "HeadlineSmall"
	| "TitleLarge"
	| "TitleMedium"
	| "TitleSmall"
	| "BodyLarge"
	| "BodyMedium"
	| "BodySmall"
	| "LabelLarge"
	| "LabelMedium"
	| "LabelSmall"

local Scale: { [Role]: Entry } = {
	DisplayLarge = { Size = 57, LineHeight = 64, Weight = 400, Tracking = -0.25 },
	DisplayMedium = { Size = 45, LineHeight = 52, Weight = 400, Tracking = 0 },
	DisplaySmall = { Size = 36, LineHeight = 44, Weight = 400, Tracking = 0 },
	HeadlineLarge = { Size = 32, LineHeight = 40, Weight = 400, Tracking = 0 },
	HeadlineMedium = { Size = 28, LineHeight = 36, Weight = 400, Tracking = 0 },
	HeadlineSmall = { Size = 24, LineHeight = 32, Weight = 400, Tracking = 0 },
	TitleLarge = { Size = 22, LineHeight = 28, Weight = 400, Tracking = 0 },
	TitleMedium = { Size = 16, LineHeight = 24, Weight = 500, Tracking = 0.15 },
	TitleSmall = { Size = 14, LineHeight = 20, Weight = 500, Tracking = 0.1 },
	BodyLarge = { Size = 16, LineHeight = 24, Weight = 400, Tracking = 0.5 },
	BodyMedium = { Size = 14, LineHeight = 20, Weight = 400, Tracking = 0.25 },
	BodySmall = { Size = 12, LineHeight = 16, Weight = 400, Tracking = 0.4 },
	LabelLarge = { Size = 14, LineHeight = 20, Weight = 500, Tracking = 0.1 },
	LabelMedium = { Size = 12, LineHeight = 16, Weight = 500, Tracking = 0.5 },
	LabelSmall = { Size = 11, LineHeight = 16, Weight = 500, Tracking = 0.5 },
}

local FontFamily = "rbxasset://fonts/families/Roboto.json"
local FallbackFamily = "rbxasset://fonts/families/GothamSSm.json"

-- `FontFace` for a role. 400 -> Regular, 500 -> Medium, 700 -> Bold (the only weights the scale uses).
local function font(role: Role, family: string?): Font
	local weight = Scale[role].Weight
	local w = Enum.FontWeight.Regular
	if weight >= 700 then
		w = Enum.FontWeight.Bold
	elseif weight >= 500 then
		w = Enum.FontWeight.Medium
	end
	return Font.new(family or FontFamily, w, Enum.FontStyle.Normal)
end

-- `TextLabel.LineHeight` is a MULTIPLIER of the text size: spec line height / size.
local function lineHeightScale(role: Role): number
	local e = Scale[role]
	return e.LineHeight / e.Size
end

return {
	Scale = Scale,
	FontFamily = FontFamily,
	FallbackFamily = FallbackFamily,
	font = font,
	lineHeightScale = lineHeightScale,
}
