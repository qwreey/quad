--!strict
--[[
	TextField internals: the shared types. `Field.Props` is the INTERNAL superset of the public `TextField.Props`
	(`TextField/init.luau`) — it adds what `Select` needs (a read-only `Text`, a `TrailingGlyph`, `OnClick`,
	`ForceFocused`). `Ctx` is the bundle of derived States and flags the part builders (Slots / Container / Support)
	read, so none of them recomputes focus, status or palette.
]]

local q = require("../Quad")
local Theme = require("../Theme")
local Util = require("../Util")

export type Variant = "Filled" | "Outlined"

export type Props = {
	read Variant: Variant?,
	read Label: (string | q.State<string>)?,
	read Value: q.Source<string>?,
	-- read-only display (makes the field read-only: no typing, no write-back) — used by Select
	read Text: q.State<string>?,
	read Placeholder: string?,
	read SupportingText: (string | q.State<string>)?,
	read Error: (boolean | q.State<boolean>)?,
	read ErrorText: (string | q.State<string>)?,
	read LeadingIcon: string?,
	read TrailingIcon: string?,
	-- a text glyph in the trailing slot (Select's dropdown arrow); `TrailingIcon` wins when both are given
	read TrailingGlyph: string?,
	read Prefix: string?,
	read Suffix: string?,
	read MaxLength: number?,
	read Disabled: (boolean | q.State<boolean>)?,
	read MultiLine: boolean?,
	read Height: number?,
	read OnChange: ((text: string) -> ())?,
	read OnSubmit: ((text: string) -> ())?,
	read OnFocusChanged: ((focused: boolean) -> ())?,
	-- pointer/gamepad click on the field (fires on release, not when the pointer left first)
	read OnClick: (() -> ())?,
	-- draws the focused look while true (Select: menu open)
	read ForceFocused: q.State<boolean>?,
	read NotchColor: (Color3 | q.State<Color3>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

export type Parts = {
	read Host: Frame,
	read Container: Frame,
	read Input: TextBox,
	read Focused: q.State<boolean>,
	read Floated: q.State<boolean>,
	read Value: q.Source<string>,
}

export type Status = "disabled" | "error" | "focused" | "hover" | "idle"

export type Colors = {
	Label: Theme.Animated,
	Line: Theme.Animated,
	Support: Theme.Animated,
	Trailing: Theme.Animated,
}

export type Ctx = {
	Props: Props,
	Theme: Theme.Theme,
	Filled: boolean,
	Multi: boolean,
	Height: number,
	Disabled: q.State<boolean>,
	Error: q.State<boolean>,
	ReadOnly: boolean,
	HasLabel: boolean,
	MaxLength: number?,
	Value: q.Source<string>,
	Focused: q.State<boolean>,
	Floated: q.State<boolean>,
	Hovered: q.State<boolean>,
	ContentTransparency: Theme.Animated,
	Colors: Colors,
}

return {}
