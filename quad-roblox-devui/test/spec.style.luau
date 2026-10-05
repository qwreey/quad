--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local Style = require("../src/Style")

H.section("default tokens (dark) and live scheme switch", function()
	local s = Style.new()
	assert(s.Color.Text:Get() == Color3.fromRGB(255, 255, 255))
	assert(s.Color.WindowBg:Get() == Color3.fromRGB(15, 15, 15) and s.Transparency.WindowBg:Get() == 0.06)
	assert(s.Metrics.TextSize:Get() == 13 and s.Metrics.FramePadding:Get() == Vector2.new(4, 3))
	assert(s.FrameHeight:Get() == 19, "13 + 2 * 3")

	local seen: { Color3 } = {}
	local obs = s.Color.Text:Observer(function(target)
		table.insert(seen, target:Get())
	end)
	obs:Subscribe()
	s:SetScheme("Light")
	assert(s.Color.Text:Get() == Color3.fromRGB(0, 0, 0) and s.Color.WindowBg:Get() == Color3.fromRGB(240, 240, 240))
	assert(seen[#seen] == Color3.fromRGB(0, 0, 0), "observers are notified")
	s:SetScheme("Dark")
	assert(s.Color.Text:Get() == Color3.fromRGB(255, 255, 255))
	obs:Unsubscribe()
end)

H.section("density switch changes metrics, frame height and font", function()
	local s = Style.new()
	local font = s.Metrics.TextFont:Get()
	s:SetDensity("Clear")
	assert(s.Metrics.TextSize:Get() == 15 and s.Metrics.FrameRounding:Get() == 4)
	assert(s.FrameHeight:Get() == 23, "15 + 2 * 4")
	assert(s.Metrics.TextFont:Get() ~= font)
	s:SetDensity("Default")
	assert(s.FrameHeight:Get() == 19)
end)

H.section("overrides (Iris names), icons, and typo guards", function()
	local s = Style.new({
		Scheme = "Light",
		Dark = { ButtonColor = Color3.new(1, 0, 0), ButtonTransparency = 0.25 },
		Light = { TextColor = Color3.new(0, 0, 1) },
		Metrics = { TextSize = 20 },
		Icons = { Close = "rbxassetid://1" },
	})
	assert(s.Color.Text:Get() == Color3.new(0, 0, 1), "light override active")
	s:SetScheme("Dark")
	assert(s.Color.Button:Get() == Color3.new(1, 0, 0) and s.Transparency.Button:Get() == 0.25)
	assert(s.Metrics.TextSize:Get() == 20)
	s:SetDensity("Clear")
	assert(s.Metrics.TextSize:Get() == 20, "metric overrides apply to both densities")
	assert(s.Icons.Close == "rbxassetid://1" and s.Icons.CheckMark ~= "")
	-- the default style is untouched
	assert(Style.default.Metrics.TextSize:Get() == 13)

	local function throws(fn: () -> ()): string
		local ok, err = pcall(fn)
		assert(not ok, "expected an error")
		return tostring(err)
	end
	assert(string.find(throws(function()
		Style.new({ Dark = { ButtonColour = Color3.new() } })
	end), "must end in", 1, true) ~= nil)
	assert(string.find(throws(function()
		Style.new({ Dark = { NopeColor = Color3.new() } })
	end), "unknown token", 1, true) ~= nil)
	assert(string.find(throws(function()
		Style.new({ Dark = { ButtonColor = 1 } })
	end), "must be a Color3", 1, true) ~= nil)
	assert(string.find(throws(function()
		Style.new({ Metrics = { Nope = 1 } })
	end), "unknown metric", 1, true) ~= nil)
	assert(string.find(throws(function()
		local _ = s:ColorOf("Nope")
	end), "unknown colour token", 1, true) ~= nil)
	assert(string.find(throws(function()
		s:SetScheme("Purple" :: any)
	end), "expected", 1, true) ~= nil)
end)

H.section("lazy tokens: one cached State per name", function()
	local s = Style.new()
	assert(s.Color.Button == s.Color.Button and s:ColorOf("Button") == s.Color.Button)
	assert(s:HasToken("Button") and not s:HasToken("Nope"))
end)

H.section("Style.interactive picks idle / hovered / active", function()
	local s = Style.new()
	local hovered = q.Source(false)
	local pressed = q.Source(false)
	local look = Style.interactive(s, "Button", hovered, pressed)
	assert(look.Color:Get() == Color3.fromRGB(66, 150, 250) and look.Transparency:Get() == 0.6)
	hovered:Set(true)
	assert(look.Transparency:Get() == 0)
	pressed:Set(true)
	assert(look.Color:Get() == Color3.fromRGB(15, 135, 250))
	hovered:Set(false)
	assert(look.Color:Get() == Color3.fromRGB(15, 135, 250), "pressed wins")
	-- a token family without variants falls back to the base
	local sep = Style.interactive(s, "Separator", hovered, pressed)
	assert(sep.Color:Get() == Color3.fromRGB(110, 110, 128))
	H.assertNoDebugOutput("style")
end)

H.done()
