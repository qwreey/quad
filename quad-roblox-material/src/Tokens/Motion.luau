--!strict
--[[
	Material 3 motion tokens (m3.material.io/styles/motion/easing-and-duration/tokens-specs).

	DURATIONS (seconds): Short1 .05 ... Short4 .20, Medium1 .25 ... Medium4 .40, Long1 .45 ... Long4 .60,
	ExtraLong1 .70 ... ExtraLong4 1.0.

	EASINGS: M3 specifies cubic-bezier curves; Roblox tweens only offer the fixed `Enum.EasingStyle` set,
	so each M3 easing maps to the CLOSEST style/direction (curve shape compared by eye — all M3 "decelerate"
	curves are fast-start/long-tail, which is `Out`; "accelerate" is the mirror, `In`):
	  Standard              (.2, 0, 0, 1)      -> Quart Out   (fast start, soft landing)
	  StandardDecelerate    (0, 0, 0, 1)       -> Cubic Out
	  StandardAccelerate    (.3, 0, 1, 1)      -> Cubic In
	  Emphasized            (.2, 0, 0, 1)*     -> Quint Out   (* the single-curve CSS form of M3's two-part path)
	  EmphasizedDecelerate  (.05, .7, .1, 1)   -> Quint Out
	  EmphasizedAccelerate  (.3, 0, .8, .15)   -> Quint In
	  Linear                                   -> Linear
	Exact bezier evaluation would move every kit tween off the engine's TweenService into per-frame Lua (the kit's
	FrameDriver.luau, which today only runs the shapes a tween cannot express) — not worth it for UI micro-motion.

	Pure data (the Enum lookup happens in `style()`/`options()` at call time).
]]

export type DurationName =
	"Short1"
	| "Short2"
	| "Short3"
	| "Short4"
	| "Medium1"
	| "Medium2"
	| "Medium3"
	| "Medium4"
	| "Long1"
	| "Long2"
	| "Long3"
	| "Long4"
	| "ExtraLong1"
	| "ExtraLong2"
	| "ExtraLong3"
	| "ExtraLong4"

export type EasingName =
	"Standard"
	| "StandardDecelerate"
	| "StandardAccelerate"
	| "Emphasized"
	| "EmphasizedDecelerate"
	| "EmphasizedAccelerate"
	| "Linear"

local Duration: { [DurationName]: number } = {
	Short1 = 0.05,
	Short2 = 0.1,
	Short3 = 0.15,
	Short4 = 0.2,
	Medium1 = 0.25,
	Medium2 = 0.3,
	Medium3 = 0.35,
	Medium4 = 0.4,
	Long1 = 0.45,
	Long2 = 0.5,
	Long3 = 0.55,
	Long4 = 0.6,
	ExtraLong1 = 0.7,
	ExtraLong2 = 0.8,
	ExtraLong3 = 0.9,
	ExtraLong4 = 1.0,
}

-- Style / direction as plain names so this table stays loadable without the engine; `style()` converts.
local Easing: { [EasingName]: { Style: string, Direction: string } } = {
	Standard = { Style = "Quart", Direction = "Out" },
	StandardDecelerate = { Style = "Cubic", Direction = "Out" },
	StandardAccelerate = { Style = "Cubic", Direction = "In" },
	Emphasized = { Style = "Quint", Direction = "Out" },
	EmphasizedDecelerate = { Style = "Quint", Direction = "Out" },
	EmphasizedAccelerate = { Style = "Quint", Direction = "In" },
	Linear = { Style = "Linear", Direction = "Out" },
}

local function enumStyle(name: string): Enum.EasingStyle
	if name == "Quart" then
		return Enum.EasingStyle.Quart
	elseif name == "Cubic" then
		return Enum.EasingStyle.Cubic
	elseif name == "Quint" then
		return Enum.EasingStyle.Quint
	end
	return Enum.EasingStyle.Linear
end

local function enumDirection(name: string): Enum.EasingDirection
	if name == "In" then
		return Enum.EasingDirection.In
	end
	return Enum.EasingDirection.Out
end

export type AnimateOptions = { Time: number, Style: Enum.EasingStyle, Direction: Enum.EasingDirection }

-- Options table for `q.Animate(...)` / `q.Tween{...}`: `q.Animate(Motion.options("Short2", "Standard"))`.
local function options(duration: DurationName, easing: EasingName): AnimateOptions
	local e = Easing[easing]
	return { Time = Duration[duration], Style = enumStyle(e.Style), Direction = enumDirection(e.Direction) }
end

return {
	Duration = Duration,
	Easing = Easing,
	options = options,
}
