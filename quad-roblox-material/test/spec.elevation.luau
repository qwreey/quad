--!strict
local H = require("./support/harness")
local q = H.attach(require("../src/Quad"))
q.debug = true
local D = q.Declaration
local Elevation = require("../src/Elevation")
local Text = require("../src/Text")
local Tokens = require("../src/Tokens")
local Theme = require("../src/Theme")

local lv = Tokens.Elevation.Levels
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

H.section("Shadow: ONE UIShadow child, static level", function()
	local host = D.Frame { Elevation.Shadow({ Level = 3 }) }
	assert(H.countDescendants(host) == 1)
	local s = H.find(host, "Elevation")
	assert(s.ClassName == "UIShadow" and s.ShowBehindParent == true and s.Enabled == true)
	assert(s.BlurRadius == UDim.new(0, lv[3].BlurRadius) and s.Offset == UDim2.fromOffset(0, lv[3].OffsetY))
	assert(s.Spread == UDim2.fromOffset(lv[3].Spread, lv[3].Spread) and near(s.Transparency, lv[3].Transparency))
	assert(s.Color == Tokens.Color.Light.Shadow)
	q.dispose(host)
	H.assertNoDebugOutput("static")
end)

H.section("Shadow: State level tweens, 0 disables, theme color follows the scheme", function()
	local level = q.Source(1)
	local theme = Theme.new({ Scheme = "light", Overrides = { Dark = { Shadow = Color3.fromRGB(5, 5, 5) } } })
	local host = D.Frame { Elevation.Shadow({ Level = level, Theme = theme }) }
	local s = H.find(host, "Elevation")
	level:Set(5)
	H.finishTweens()
	assert(s.BlurRadius == UDim.new(0, lv[5].BlurRadius) and near(s.Transparency, lv[5].Transparency))
	level:Set(0)
	H.finishTweens()
	assert(s.Enabled == false)
	level:Set(99)
	H.finishTweens()
	assert(s.Enabled == true and s.BlurRadius == UDim.new(0, lv[5].BlurRadius), "clamped to level 5")
	theme:SetScheme("dark")
	H.finishTweens()
	assert(s.Color == Color3.fromRGB(5, 5, 5))
	q.dispose(host)
	H.assertNoDebugOutput("state")
end)

H.section("Backdrop: ONE 9-slice ImageLabel (the UIShadow fallback)", function()
	local level = q.Source(2)
	local host = D.Frame { Elevation.Backdrop({ Level = level }) }
	assert(H.countDescendants(host) == 1)
	local b = H.find(host, "ElevationBackdrop")
	assert(b.ClassName == "ImageLabel" and b.ScaleType == Enum.ScaleType.Slice and b.Image == Elevation.Config.BackdropImage)
	assert(b.SliceCenter == Elevation.Config.BackdropSlice and b.BackgroundTransparency == 1)
	local grow = 2 * (lv[2].BlurRadius + lv[2].Spread)
	assert(b.Size == UDim2.new(1, grow, 1, grow) and b.Position == UDim2.new(0.5, 0, 0.5, lv[2].OffsetY))
	level:Set(4)
	H.finishTweens()
	assert(near(b.ImageTransparency, lv[4].Transparency))
	q.dispose(host)
	H.assertNoDebugOutput("backdrop")
end)

H.section("Text modifiers carry font, size and line-height multiplier", function()
	local label = D.TextLabel { Text.Label("BodyLarge"), Text = "x" }
	assert(label.TextSize == 16 and label.FontFace.Weight == Enum.FontWeight.Regular and near(label.LineHeight, 24 / 16))
	local button = D.TextButton { Text.Button("LabelLarge") }
	assert(button.TextSize == 14 and button.FontFace.Weight == Enum.FontWeight.Medium)
	local box = D.TextBox { Text.Box("TitleMedium") }
	assert(box.TextSize == 16 and box.FontFace.Family == Tokens.Typography.FontFamily)
	local fb = D.TextLabel { Text.Label("BodyMedium", Tokens.Typography.FallbackFamily) }
	assert(fb.FontFace.Family == Tokens.Typography.FallbackFamily)
	for _, i in { label, button, box, fb } do
		q.dispose(i)
	end
	H.assertNoDebugOutput("text")
end)

H.done()
