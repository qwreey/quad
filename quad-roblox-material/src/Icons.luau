--!strict
--[[
	Icons: the kit ships no icon assets, so every built-in icon is a TEXT GLYPH picked from the ranges the Roboto face
	(the kit's font) actually covers, behind ONE table — and any of them can be swapped for an uploaded image asset
	without touching a component.

	    Icons.glyph("check")                  -> "√"          the default text glyph
	    Icons.asset("check")                  -> string?      the registered image asset id, nil by default
	    Icons.override({ check = "rbxassetid://123", close = "rbxassetid://456" })   -- once, at startup (`false` removes)
	    Icons.build("close", { Size = 18, Color = c, Transparency = t, LayoutOrder = 1, Name = "x" })
	                                          -> an ImageLabel when an asset is registered, else a TextLabel with the glyph

	Names: check, close, arrowDown, arrowUp, chevronLeft, chevronRight, edit, calendar, error (the "!" TextField shows while in the Error state).
	Defaults: check U+221A, close U+00D7, arrowDown U+25BC, arrowUp U+25B2, chevronLeft U+2039, chevronRight U+203A —
	all inside Roboto. edit (U+270E) and calendar (U+25A6) have NO Roboto glyph: the engine's font fallback draws them,
	which differs per platform — register image assets for them (and, if you want pixel-exact art, for all).

	Who goes through here: Chip (check, remove x unless the chip's own CheckIcon/RemoveIcon is given), Select (arrow, via
	`TrailingIcon` when an asset is registered), Snackbar (close), the date picker header / navigation / mode toggle
	(the previous / next month chevrons are GlyphButtons given `Icons.asset("chevronLeft"/"chevronRight")`, so an override
	IS picked up there; the "▼"/"▲" in the header label and the edit/calendar mode toggle stay glyph strings — see DatePicker/Body).
	`override` is module-wide (every theme, every Roblox VM script sharing this module) and read when a component is
	built, so call it before building UI; already-built instances keep what they have.
]]

export type Name = "check" | "close" | "arrowDown" | "arrowUp" | "chevronLeft" | "chevronRight" | "edit" | "calendar" | "error"

local Glyphs: { [Name]: string } = {
	check = "\u{221A}",
	close = "\u{00D7}",
	arrowDown = "\u{25BC}",
	arrowUp = "\u{25B2}",
	chevronLeft = "\u{2039}",
	chevronRight = "\u{203A}",
	edit = "\u{270E}",
	calendar = "\u{25A6}",
	error = "!",
}

local assets: { [string]: string } = {}

local function glyph(name: Name): string
	return Glyphs[name]
end

local function asset(name: Name): string?
	return assets[name]
end

local function override(map: { [Name]: string | false })
	for name, id in map do
		assets[name] = if id == false then nil else id
	end
end

return {
	glyph = glyph,
	asset = asset,
	override = override,
}
