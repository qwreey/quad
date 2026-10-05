--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Tokens = require("../src/Tokens")

local Color = Tokens.Color

local function lin(c: number): number
	return if c <= 0.03928 then c / 12.92 else ((c + 0.055) / 1.055) ^ 2.4
end
local function luminance(c: Color3): number
	return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B)
end
local function contrast(a: Color3, b: Color3): number
	local la, lb = luminance(a), luminance(b)
	if la < lb then
		la, lb = lb, la
	end
	return (la + 0.05) / (lb + 0.05)
end

H.section("color: both schemes complete and identical role sets", function()
	local nLight, nDark = 0, 0
	for role in Color.Light do
		nLight += 1
		assert((Color.Dark :: any)[role] ~= nil, "dark missing " .. role)
	end
	for role in Color.Dark do
		nDark += 1
		assert((Color.Light :: any)[role] ~= nil, "light missing " .. role)
	end
	assert(nLight == nDark and nLight == #Color.Roles, "role counts " .. nLight .. "/" .. nDark .. "/" .. #Color.Roles)
	assert(nLight == 49, "49 roles, got " .. nLight)
end)

H.section("color: baseline spot values", function()
	assert(Color.Light.Primary == Color3.fromHex("#6750A4"))
	assert(Color.Light.Surface == Color3.fromHex("#FEF7FF"))
	assert(Color.Light.SurfaceContainerHighest == Color3.fromHex("#E6E0E9"))
	assert(Color.Dark.Primary == Color3.fromHex("#D0BCFF"))
	assert(Color.Dark.Surface == Color3.fromHex("#141218"))
	assert(Color.Dark.OnSurface == Color3.fromHex("#E6E0E9"))
	assert(Color.Light.Scrim == Color3.new(0, 0, 0) and Color.Light.Shadow == Color3.new(0, 0, 0))
end)

H.section("color: on-color pairs reach WCAG AA (4.5:1) in both schemes", function()
	local pairs_ = {
		{ "Primary", "OnPrimary" },
		{ "PrimaryContainer", "OnPrimaryContainer" },
		{ "Secondary", "OnSecondary" },
		{ "SecondaryContainer", "OnSecondaryContainer" },
		{ "Tertiary", "OnTertiary" },
		{ "TertiaryContainer", "OnTertiaryContainer" },
		{ "Error", "OnError" },
		{ "ErrorContainer", "OnErrorContainer" },
		{ "Surface", "OnSurface" },
		{ "SurfaceVariant", "OnSurfaceVariant" },
		{ "InverseSurface", "InverseOnSurface" },
		{ "Background", "OnBackground" },
	}
	for _, entry in { { "Light", Color.Light }, { "Dark", Color.Dark } } do
		local name, scheme = entry[1] :: string, entry[2] :: any
		for _, p in pairs_ do
			local c = contrast((scheme :: any)[p[1]], (scheme :: any)[p[2]])
			assert(c >= 4.5, `{name} {p[1]}/{p[2]} contrast {c}`)
		end
	end
end)

H.section("typography font + motion enums + shape UDim (need the engine datatypes)", function()
	local f = Tokens.Typography.font("LabelLarge")
	assert(f.Family == "rbxasset://fonts/families/Roboto.json" and f.Weight == Enum.FontWeight.Medium)
	assert(Tokens.Typography.font("BodyLarge").Weight == Enum.FontWeight.Regular)
	assert(Tokens.Typography.font("BodyLarge", Tokens.Typography.FallbackFamily).Family == Tokens.Typography.FallbackFamily)
	local o = Tokens.Motion.options("Medium2", "Emphasized")
	assert(o.Time == 0.3 and o.Style == Enum.EasingStyle.Quint and o.Direction == Enum.EasingDirection.Out)
	local a = Tokens.Motion.options("Short2", "StandardAccelerate")
	assert(a.Style == Enum.EasingStyle.Cubic and a.Direction == Enum.EasingDirection.In)
	assert(Tokens.Shape.corner("Full") == UDim.new(0.5, 0))
	assert(Tokens.Shape.corner("Medium") == UDim.new(0, 12))
end)

H.assertNoDebugOutput("tokens")
H.done()
