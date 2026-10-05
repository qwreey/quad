--!strict
--[[
	The original's tween vocabulary (every tween there is Quad / Out unless noted), as two helpers:
	  Anim.quad(t)        `state:Apply(Anim.quad(0.12))`  animate a whole State (a new value tweens, the first snaps)
	  Anim.tween(v, t, style?)   a Tween VALUE for a `:Compute` that picks time/style per direction
	No TweenService bookkeeping anywhere: quad cancels the previous tween of a property when a new value arrives
	(the original's `Cancel` + `Destroy` pair, 21 times).
]]

local q = require("../../Quad")

local function quad(time: number)
	return q.Animate({ Time = time, Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out })
end

local function tween<T>(value: T, time: number, style: Enum.EasingStyle?, completed: (() -> ())?)
	return q.Tween({
		Value = value,
		Time = time,
		Style = style or Enum.EasingStyle.Quad,
		Direction = Enum.EasingDirection.Out,
		Completed = if completed then function(_i: Instance, _p: string, _v: T) completed() end else nil,
	})
end

return {
	quad = quad,
	tween = tween,
}
