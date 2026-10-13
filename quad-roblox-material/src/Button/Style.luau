--!strict
--[[
	Shared style plumbing for Button / IconButton / FAB (internal to the kit; other components may reuse it).

	`disabledPick(disabled, normal, off)`  -> animated State of the role color to show now. `normal`/`off` are
	  the RAW (non-animated) role States (`theme.Raw.X`); the result is animated once, so a scheme switch AND
	  a disabled flip both cross-fade.
	`disabledNumber(disabled, normal, off)` -> animated State<number> (transparencies).
	M3 disabled look: container onSurface @ 12 % (transparency .88), content onSurface @ 38 % (.62).
]]

local q = require("../Quad")
local Tokens = require("../Tokens")
local Theme = require("../Theme")

local DisabledContainerTransparency = 1 - Tokens.State.Opacity.DisabledContainer
-- The BUTTON family's disabled container (token audit 2026-10-13, androidx-main): Filled / Elevated buttons, the
-- Outlined button's OUTLINE, every icon-button container and the toggle buttons of a ButtonGroup are 10 %
-- (`FilledButtonTokens` / `ElevatedButtonTokens` / `OutlinedButtonTokens` / `Filled(Tonal)IconButtonTokens`
-- `.DisabledContainerOpacity = 0.1`). The standalone TONAL button and the Tonal SplitButton are still 12 % in canon
-- (`Button.kt` filledTonalButtonColors -> `FilledTonalButtonTokens` 0.12) — per component, as canon has it. The
-- shared 12 % above stays for what canon still has at 12 % (switch track, slider inactive track, chips, the
-- outlined text field) and for the FAB (no disabled state in canon: the kit's own).
local DisabledButtonContainerTransparency = 1 - 0.10
local function disabledContainerTransparencyOf(variant: string): number
	return if variant == "Tonal" then DisabledContainerTransparency else DisabledButtonContainerTransparency
end
local DisabledContentTransparency = 1 - Tokens.State.Opacity.DisabledContent

local function animation()
	return q.Animate(Tokens.Motion.options("Short4", "Standard"))
end

local function disabledPick(disabled: q.State<boolean>, normal: q.State<Color3>, off: q.State<Color3>): Theme.Animated
	local picked: q.State<Color3> = disabled:Compute(function(self, _prev, n, o)
		return if self:Get() then o:Get() else n:Get()
	end, normal, off)
	return picked:Apply(animation())
end

local function disabledNumber(disabled: q.State<boolean>, normal: number, off: number): Theme.Animated
	local picked: q.State<number> = disabled:Compute(function(self)
		return if self:Get() then off else normal
	end)
	return picked:Apply(animation())
end

-- raw State<Color3> chosen by a boolean State (no animation) — compose with `animated` / `disabledPick`.
local function choose(cond: q.State<boolean>, whenTrue: q.State<Color3>, whenFalse: q.State<Color3>): q.State<Color3>
	return cond:Compute(function(self, _prev, a, b)
		return if self:Get() then a:Get() else b:Get()
	end, whenTrue, whenFalse)
end

-- the standard button animation (Short4 / Standard) applied to a State
local function animated(state: q.State<Color3>): Theme.Animated
	return state:Apply(animation())
end

-- boolean State -> number State (for LayoutOrder-like / transparency selects)
local function select(cond: q.State<boolean>, whenTrue: number, whenFalse: number): q.State<number>
	return cond:Compute(function(self)
		return if self:Get() then whenTrue else whenFalse
	end)
end

return {
	DisabledContainerTransparency = DisabledContainerTransparency,
	DisabledButtonContainerTransparency = DisabledButtonContainerTransparency,
	disabledContainerTransparencyOf = disabledContainerTransparencyOf,
	DisabledContentTransparency = DisabledContentTransparency,
	disabledPick = disabledPick,
	disabledNumber = disabledNumber,
	select = select,
	choose = choose,
	animated = animated,
	animation = animation,
}
