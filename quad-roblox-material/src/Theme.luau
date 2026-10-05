--!strict
--[[
	Runtime theme: the baseline M3 color roles as reactive States, switchable light <-> dark with a
	color cross-fade.

	    local Theme = require("./Theme")
	    local theme = Theme.new({ Scheme = "dark" })            -- or just use `Theme.default`
	    D.Frame { BackgroundColor3 = theme.Color.Surface }       -- animated State<Color3>, follows scheme switches
	    theme:SetScheme("light")                                 -- every bound property tweens to the light role
	    theme.Scheme                                             -- Source<"light"|"dark">, also writable directly

	Fields
	  Scheme   Source<"light"|"dark">           the one input everything derives from
	  Color    { [Role]: State<Color3> }        ANIMATED role tokens — plug straight into properties
	                                            (`BackgroundColor3 = theme.Color.Primary`). Typed as the
	                                            Animate result; do not `:Get()` them for color math.
	  Raw      { [Role]: State<Color3> }        the same roles WITHOUT animation (the instantaneous value for
	                                            `:Compute` color math, e.g. mixing two roles). Plug into a
	                                            property only when you want a snap.

	`Overrides = { Light = { Primary = Color3... }?, Dark = { ... }? }` replaces individual roles of one scheme
	(a game brand color). The merge is done once at `new` — overrides are static; build a second Theme for
	a different seed. Roles you do not override keep the baseline value.

	Components take an optional `props.Theme: Theme?` and fall back with `Theme.resolve(props.Theme)`.
	Scheme switch duration/easing: Motion `Medium2` / `Standard` (300 ms), identical for every role.
]]

local q = require("./Quad")
local Tokens = require("./Tokens")

local ColorTokens = require("./Tokens/Color")

export type Role = ColorTokens.Role
export type SchemeName = ColorTokens.SchemeName

local _proto = q.Source(Color3.new()):Apply(q.Animate({ Time = 0 }))
-- The type `state:Apply(q.Animate{...})` returns (`State<Tween<any>>` — the name `Tween` is not re-exported).
export type Animated = typeof(_proto)

export type Overrides = { Light: { [Role]: Color3 }?, Dark: { [Role]: Color3 }? }

export type Theme = {
	read Scheme: q.Source<SchemeName>,
	read Color: { [Role]: Animated },
	read Raw: { [Role]: q.State<Color3> },
	SetScheme: (self: Theme, name: SchemeName) -> (),
	Toggle: (self: Theme) -> (),
}

export type Options = { Scheme: SchemeName?, Overrides: Overrides? }

local function merged(base: ColorTokens.Scheme, over: { [Role]: Color3 }?): ColorTokens.Scheme
	local out = table.clone(base)
	if over then
		for role, color in over do
			out[role] = color
		end
	end
	return out
end

local function setScheme(self: Theme, name: SchemeName)
	self.Scheme:SetIfChanged(name)
end

local function toggle(self: Theme)
	self.Scheme:SetIfChanged(if self.Scheme:Get() == "light" then "dark" else "light")
end

local function new(opts: Options?): Theme
	local o: Options = opts or {}
	local overrides: Overrides = o.Overrides or {}
	local light = merged(ColorTokens.Light, overrides.Light)
	local dark = merged(ColorTokens.Dark, overrides.Dark)

	local scheme = q.Source((o.Scheme or "light") :: SchemeName)
	-- one palette node; every role is a cheap Indexed read of it
	local palette: q.State<ColorTokens.Scheme> = scheme:Compute(function(self)
		return if self:Get() == "dark" then dark else light
	end)
	local animate = q.Animate(Tokens.Motion.options("Medium2", "Standard"))

	local Color: { [Role]: Animated } = {}
	local Raw: { [Role]: q.State<Color3> } = {}
	for _, role in ColorTokens.Roles do
		local raw: q.State<Color3> = palette:Compute(function(self)
			return self:Get()[role]
		end)
		Raw[role] = raw
		Color[role] = raw:Apply(animate)
	end

	return {
		Scheme = scheme,
		Color = Color,
		Raw = Raw,
		SetScheme = setScheme,
		Toggle = toggle,
	}
end

local default = new({ Scheme = "light" })

-- `props.Theme` or the module default.
local function resolve(theme: Theme?): Theme
	return theme or default
end

return {
	new = new,
	default = default,
	resolve = resolve,
}
