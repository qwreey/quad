--!strict
--[[
	M3 text field: Filled and Outlined (one function, `Variant` prop), floating label, supporting/error text,
	counter, leading/trailing icon, prefix/suffix, optional multi-line.

	    local TextField = require("@self")                  -- via the kit root: Material.TextField
	    local name = q.Source("")
	    TextField({ Label = "Name", Value = name, SupportingText = "As on your card", MaxLength = 20 })
	    TextField({ Variant = "Outlined", Label = "Email", Value = email, Error = emailBad, ErrorText = "Invalid" })

	Props (all `read`):
	  Variant         "Filled" | "Outlined"                       default "Filled"
	  Label           string | State<string>?                      floats (BodyLarge -> BodySmall) when focused or non-empty
	  Value           Source<string>?                             two-way (`Text = value` + `q.Out("Text", value)`); an
	                                                              internal Source when omitted
	  Placeholder     string?                                     shown once the label floated (always when no label)
	  SupportingText  string | State<string>?
	  Error           boolean | State<boolean>?                   error colors; swaps the supporting text for `ErrorText`
	  ErrorText       string | State<string>?
	  LeadingIcon     string?                                     image id, 24 px at x = 12
	  TrailingIcon    string?                                     image id, 24 px at the right edge
	  Prefix/Suffix   string?                                     shown after the label floated
	  MaxLength       number?                                     utf8 characters; clips typing, shows `n/max`
	  ShowCounter     boolean?                                    default true; false keeps the MaxLength clipping but drops `n/max`
	  Disabled        boolean | State<boolean>?                   not editable/focusable, M3 disabled opacities
	  MultiLine       boolean?, Height: number?                   height default 56 (120 multi-line)
	  OnChange        ((text: string) -> ())?                     after a USER edit (typing, paste, clip) — not on a
	                                                              programmatic `Value:Set`; the new (clipped) text
	  OnSubmit        ((text: string) -> ())?                     FocusLost with enterPressed
	  OnFocusChanged  ((focused: boolean) -> ())?
	  NotchColor      Color3 | State<Color3>?                     Outlined: the surface behind the field (default theme Surface)
	  Theme, Modifier (Frame Modifier applied after the base; `Size` default is 210 wide, height automatic), Hooks
	Returns the host `Frame` (a vertical list: the 56 px container, then the supporting row).

	Behavior notes
	  * Focus look comes from the TextBox `Focused`/`FocusLost` events written into an internal Source.
	  * MaxLength is enforced in the write-back path (see Field.luau header for why `value:Set`, not
	    `SetIfChanged`, and why it is not an Observer/Effect).
	  * A click anywhere on the container (label, padding, icons) focuses the TextBox (`CaptureFocus` on the container's
	    press release, unless the click already focused it) — the TextBox itself covers only the row's padded box.
	  * Hover is tracked on the container (Interaction hook). The editable TextBox covers the input area; whether
	    the engine keeps `MouseEnter` alive over it is not verified on a device (미완 — see report).

	M3 deviations (Roblox / cost): the Filled container rounds only its TOP corners by drawing the rounded fill taller than
	its clipping parent (Container.luau); the Outlined notch is a surface-colored label background (needs `NotchColor` on a
	non-Surface backdrop); the error "icon" is a bold "!" text mark; label animation interpolates TextSize (glyphs re-rasterize while it runs);
	no text selection color/handle theming (engine-owned).
	Instances at rest (asserted in the spec): Filled+label 13 incl. host, Outlined+label 12 incl. host.
]]

local q = require("./Quad")
local Theme = require("./Theme")
local Util = require("./Util")
local Field = require("@self/Field")

export type Variant = Field.Variant

-- The PUBLIC props. (`Field.Props`, in Field.luau / Ctx.luau, is the internal superset: it adds `Text` (a read-only
-- display), `TrailingGlyph`, `OnClick` and `ForceFocused`, which only `Select` uses.)
export type Props = {
	read Variant: Variant?,
	read Label: (string | q.State<string>)?,
	read Value: q.Source<string>?,
	read Placeholder: string?,
	read SupportingText: (string | q.State<string>)?,
	read Error: (boolean | q.State<boolean>)?,
	read ErrorText: (string | q.State<string>)?,
	read LeadingIcon: string?,
	read TrailingIcon: string?,
	read Prefix: string?,
	read Suffix: string?,
	read MaxLength: number?,
	read ShowCounter: boolean?,
	read Disabled: (boolean | q.State<boolean>)?,
	read MultiLine: boolean?,
	read Height: number?,
	read OnChange: ((text: string) -> ())?,
	read OnSubmit: ((text: string) -> ())?,
	read OnFocusChanged: ((focused: boolean) -> ())?,
	read NotchColor: (Color3 | q.State<Color3>)?,
	read Theme: Theme.Theme?,
	read Modifier: q.FrameModifier?,
	read Hooks: Util.Hooks?,
}

local function TextField(props: Props): Frame
	return Field.build(props).Host
end

return TextField
