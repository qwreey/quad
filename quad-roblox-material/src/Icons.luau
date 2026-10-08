--!strict
--[[
	Icons: every built-in icon of the kit behind ONE table — an IMAGE asset by default (Google's Material Design Icons,
	"baseline" style, as uploaded for qwreey's old IconPack Studio plugin), with a TEXT GLYPH fallback for each name.

	    Icons.asset("check")                  -> string?      the image asset id (a default below, or your override)
	    Icons.glyph("check")                  -> "√"          the text glyph, used where no image is registered
	    Icons.override({ check = "rbxassetid://123", close = "rbxassetid://456" })   -- once, at startup
	    Icons.override({ edit = false })      -- drop the image for a name: that icon falls back to its glyph
	    Icons.Defaults                        -- the default name -> asset id table (read-only; the list below)

	Names: check, close, arrowDown, arrowUp, chevronLeft, chevronRight, edit, calendar, error (the "!" TextField shows while
	in the Error state).

	DEFAULT IMAGES (Studio QA 2026-10-08, 9th: the edit glyph U+270E drew as a "?" box — the engine's font fallback has no
	glyph for it on that machine — while U+25A6 drew). Material Design Icons (google/material-design-icons, Apache License
	2.0 — see the kit's NOTICE), the "baseline" PNGs uploaded to Roblox by the user's icon account (qwreey74_icon) for the
	IconPack plugin; the ids come from its dump (qwreey/qwreey.roblox.plugins@7b6552a:IconPack.Plugin/res/IconDump.lua,
	`IconDump.baseline[group][name]`). Each id was checked as an IMAGE asset (AssetTypeId 1, not a decal) through
	economy.roblox.com/v2/assets/<id>/details on 2026-10-08, and four of them (check, arrowDown, edit, calendar) rendered
	through thumbnails.roblox.com as white glyphs on transparency (the ink spans about 3/4 of the square, Material's 24 dp
	grid) — not yet seen inside Studio.
	The names follow what Compose Material 3 draws (androidx/androidx@5ac4c7c compose/material3/material3/src/commonMain/
	kotlin/androidx/compose/material3/): the date picker mode toggle Icons.Filled.Edit / DateRange (DatePicker.kt 1453,
	1460), its month arrows AutoMirrored KeyboardArrowLeft / Right (2511, 2519), its year dropdown and the exposed dropdown
	menu ArrowDropDown (DatePicker.kt 2547, ExposedDropdownMenu.kt 463), the Snackbar dismiss Icons.Filled.Close
	(Snackbar.kt 263); the chip check is the Material "check".
	  check         6031094667   baseline/navigation/check
	  close         6031094678   baseline/navigation/close
	  arrowDown     6031091004   baseline/navigation/arrow_drop_down
	  arrowUp       6031090990   baseline/navigation/arrow_drop_up
	  chevronLeft   6034818375   baseline/hardware/keyboard_arrow_left
	  chevronRight  6034818365   baseline/hardware/keyboard_arrow_right
	  edit          6034328955   baseline/image/edit
	  calendar      6022668894   baseline/action/date_range
	  error         (none)       the dump has no "error" icon; the glyph "!" (ASCII, always in the font) stays
	White on transparent, so `ImageColor3` tints them like text.

	GLYPH FALLBACKS (kept for a place that cannot load images, and for any name you override with `false`): check U+221A,
	close U+00D7, arrowDown U+25BC, arrowUp U+25B2, chevronLeft U+2039, chevronRight U+203A — inside Roboto; edit (U+270E)
	and calendar (U+25A6) have NO Roboto glyph and depend on the platform's font fallback.

	Who goes through here: Chip (check; remove x — unless the chip's own CheckIcon / RemoveIcon is given), Select (the
	arrow, a `TrailingIcon` image / `TrailingGlyph` fallback), Snackbar (close), the date picker month arrows and the modal's
	edit / calendar mode toggle (GlyphButtons given the asset), the ColorPicker's selected-swatch check. Still a glyph by
	design: the "▼"/"▲" after the month-year label of the date picker header — part of a text Button's label (the kit Button
	has no trailing image), and U+25BC / U+25B2 are in Roboto.
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

-- Material Design Icons (Apache 2.0), baseline style; IMAGE asset ids (see the header)
local defaultIds: { [string]: string } = {
	check = "rbxassetid://6031094667",
	close = "rbxassetid://6031094678",
	arrowDown = "rbxassetid://6031091004",
	arrowUp = "rbxassetid://6031090990",
	chevronLeft = "rbxassetid://6034818375",
	chevronRight = "rbxassetid://6034818365",
	edit = "rbxassetid://6034328955",
	calendar = "rbxassetid://6022668894",
}
local Defaults = table.freeze(defaultIds)

local assets: { [string]: string } = table.clone(Defaults)

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
	Defaults = Defaults,
}
