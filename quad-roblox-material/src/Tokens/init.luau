--!strict
--[[
	Static Material 3 design tokens. No reactivity here — `Theme.luau` turns the color tokens into States.

	  Tokens.Color       baseline light/dark color roles           (Color.luau)
	  Tokens.Typography  type scale + `font(role)`                  (Typography.luau)
	  Tokens.Shape       corner radii + `corner(role): UDim`        (Shape.luau)
	  Tokens.Elevation   levels 0-5 -> UIShadow numbers             (Elevation.luau)
	  Tokens.Motion      durations + easing approximations          (Motion.luau)
	  Tokens.State       state-layer / disabled opacities           (State.luau)
]]

return {
	Color = require("@self/Color"),
	Typography = require("@self/Typography"),
	Shape = require("@self/Shape"),
	Elevation = require("@self/Elevation"),
	Motion = require("@self/Motion"),
	State = require("@self/State"),
}
