--!strict
-- Pure token math (plain `luau`, no engine globals at require time): type scale, motion, state opacities,
-- shape, elevation tables.
local Typography = require("../src/Tokens/Typography")
local Motion = require("../src/Tokens/Motion")
local StateTokens = require("../src/Tokens/State")
local Shape = require("../src/Tokens/Shape")
local Elevation = require("../src/Tokens/Elevation")

local failed = 0
local function check(cond: boolean, msg: string)
	if not cond then
		failed += 1
		print("FAIL: " .. msg)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

-- type scale: 15 roles, line height >= size, spec spot values
local n = 0
for role, e in Typography.Scale do
	n += 1
	check(e.LineHeight >= e.Size, role .. " line height >= size")
	check(e.Weight == 400 or e.Weight == 500, role .. " weight")
end
check(n == 15, "15 type roles, got " .. n)
check(Typography.Scale.LabelLarge.Size == 14 and Typography.Scale.LabelLarge.LineHeight == 20, "label large 14/20")
check(Typography.Scale.DisplayLarge.Size == 57 and Typography.Scale.DisplayLarge.LineHeight == 64, "display large 57/64")
check(near(Typography.lineHeightScale("LabelLarge"), 20 / 14), "line height multiplier")
check(Typography.FontFamily == "rbxasset://fonts/families/Roboto.json", "roboto family")

-- motion: durations monotonic in name order, spec spots, every easing has a mapping
local order = { "Short1", "Short2", "Short3", "Short4", "Medium1", "Medium2", "Medium3", "Medium4", "Long1", "Long2", "Long3", "Long4", "ExtraLong1", "ExtraLong2", "ExtraLong3", "ExtraLong4" }
local prev = 0
for _, name in order do
	local d = (Motion.Duration :: any)[name]
	check(d ~= nil and d > prev, name .. " increasing")
	prev = d
end
check(near(Motion.Duration.Short1, 0.05) and near(Motion.Duration.Medium2, 0.3) and near(Motion.Duration.ExtraLong4, 1.0), "duration spots")
for _, e in { "Standard", "StandardDecelerate", "StandardAccelerate", "Emphasized", "EmphasizedDecelerate", "EmphasizedAccelerate", "Linear" } do
	check((Motion.Easing :: any)[e] ~= nil, e .. " mapped")
end

-- state layer opacities
local O = StateTokens.Opacity
check(near(O.Hover, 0.08) and near(O.Focus, 0.10) and near(O.Pressed, 0.10) and near(O.Dragged, 0.16), "state opacities")
check(near(StateTokens.layerOpacity({}), 0), "idle 0")
check(near(StateTokens.layerOpacity({ Hovered = true }), 0.08), "hover")
check(near(StateTokens.layerOpacity({ Hovered = true, Focused = true }), 0.10), "highest wins, not additive")
check(near(StateTokens.layerOpacity({ Hovered = true, Pressed = true, Dragged = true }), 0.16), "dragged wins")
check(near(StateTokens.layerOpacity({ Hovered = true, Disabled = true }), 0), "disabled hides the layer")

-- shape
check(Shape.Radius.None == 0 and Shape.Radius.ExtraSmall == 4 and Shape.Radius.Small == 8, "shape low")
check(Shape.Radius.Medium == 12 and Shape.Radius.Large == 16 and Shape.Radius.ExtraLarge == 28, "shape high")
check(Shape.Radius.Full == nil, "full has no px radius")

-- elevation: dp 0,1,3,6,8,12; blur/offset/spread nondecreasing, shadow gets darker (transparency decreasing)
local dps = { [0] = 0, 1, 3, 6, 8, 12 }
for i = 0, Elevation.MaxLevel do
	check(Elevation.Levels[i].Dp == dps[i], "dp level " .. i)
	if i > 0 then
		local a, b = Elevation.Levels[i - 1], Elevation.Levels[i]
		check(b.BlurRadius >= a.BlurRadius and b.OffsetY >= a.OffsetY and b.Spread >= a.Spread, "level " .. i .. " geometry grows")
		check(b.Transparency <= a.Transparency, "level " .. i .. " darker")
	end
end
check(Elevation.levelOf(-3).Dp == 0 and Elevation.levelOf(99).Dp == 12 and Elevation.levelOf(2.4).Dp == 3, "levelOf clamps and rounds")

if failed > 0 then
	error(failed .. " check(s) failed")
end
print("PASS spec.pure.tokens")
