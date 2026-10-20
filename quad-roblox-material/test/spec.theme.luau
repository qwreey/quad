--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Frame = q.Elem "Frame"
local Theme = require("../src/Theme")
local Tokens = require("../src/Tokens")

H.section("default theme: light roles bound to a property, switch tweens to dark", function()
	local theme = Theme.new({ Scheme = "light" })
	local f = Frame {
		BackgroundColor3 = theme.Color.Primary,
		BorderColor3 = theme.Color.Outline,
	}
	assert(f.BackgroundColor3 == Tokens.Color.Light.Primary, "first write snaps to light primary")
	assert(theme.Scheme:Get() == "light")
	theme:SetScheme("dark")
	assert(theme.Scheme:Get() == "dark")
	assert(theme.Raw.Primary:Get() == Tokens.Color.Dark.Primary, "Raw follows at once")
	H.finishTweens()
	assert(f.BackgroundColor3 == Tokens.Color.Dark.Primary, "animated role reaches dark primary")
	assert(f.BorderColor3 == Tokens.Color.Dark.Outline)
	-- same scheme again: no new tween (SetIfChanged)
	local before = #H.tweenLog()
	theme:SetScheme("dark")
	assert(#H.tweenLog() == before, "no-op switch starts no tween")
	theme:Toggle()
	H.finishTweens()
	assert(f.BackgroundColor3 == Tokens.Color.Light.Primary, "toggle back to light")
	q.dispose(f)
	H.assertNoDebugOutput("theme switch")
end)

H.section("Scheme Source is writable directly", function()
	local theme = Theme.new({ Scheme = "dark" })
	assert(theme.Raw.Surface:Get() == Tokens.Color.Dark.Surface)
	theme.Scheme:Set("light")
	assert(theme.Raw.Surface:Get() == Tokens.Color.Light.Surface)
end)

H.section("overrides replace single roles per scheme, others keep the baseline", function()
	local brand = Color3.fromRGB(255, 0, 100)
	local brandDark = Color3.fromRGB(100, 0, 255)
	local theme = Theme.new({ Scheme = "light", Overrides = { Light = { Primary = brand }, Dark = { Primary = brandDark } } })
	assert(theme.Raw.Primary:Get() == brand)
	assert(theme.Raw.OnPrimary:Get() == Tokens.Color.Light.OnPrimary, "untouched role keeps baseline")
	theme:SetScheme("dark")
	assert(theme.Raw.Primary:Get() == brandDark)
	-- overrides did not mutate the shared baseline tables
	assert(Tokens.Color.Light.Primary == Color3.fromHex("#6750A4"))
	-- a second, independent theme is unaffected
	local other = Theme.new({ Scheme = "light" })
	assert(other.Raw.Primary:Get() == Tokens.Color.Light.Primary)
end)

H.section("resolve falls back to the default", function()
	assert(Theme.resolve(nil) == Theme.default)
	local t = Theme.new()
	assert(Theme.resolve(t) == t)
	assert(Theme.default.Scheme:Get() == "light", "default theme starts light")
end)

H.section("all roles exist as both Color and Raw", function()
	local theme = Theme.new()
	for _, role in Tokens.Color.Roles do
		assert(theme.Color[role] ~= nil and theme.Raw[role] ~= nil, "missing " .. role)
	end
end)

H.assertNoDebugOutput("theme")
H.done()
