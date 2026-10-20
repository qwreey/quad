--!strict
--[[
	Motion: a 0..1 progress number that follows a boolean, animated frame by frame (internal to the navigation bar / rail and
	the toolbars). Compose drives these components' geometry from ONE animated float per item (the indicator's
	`animateIndicatorProgressAsState`, the rail item's `iconPositionProgress`, the floating toolbar's expanded progress) and
	lays everything out from it each frame — widths, offsets and alphas that are not straight lines between two values. The
	kit does the same: the components compute their properties from `value` in `:Compute`s, so every derived property moves
	together, and there is ONE `RunService.Heartbeat` connection per animating progress, none at rest.

	    local value, effect = Motion.progress(selected, Tokens.Motion.Duration.Short4)
	    q.Elem "Frame" { effect, Size = value:Compute(function(self) return UDim2.fromOffset(56 * self:Get(), 32) end) }

	`value` starts AT the target (a mount never animates). A change animates from the current value to the new end (0 or 1)
	over `duration * |distance|` (an interrupted motion turns around from where it is), with the kit's Standard easing
	(Quart Out, as Ripple.luau evaluates it). `effect` is a `q.Effect` — put it in the host's array part so its cleanup (the
	Heartbeat connection) runs when the host dies. Options: `Snap` (a counter State — a change jumps to the end; a state's
	`SnapTo`) and `OnSettle(atOne)` (called when the value reaches an end, by animation or snap — a state's settled value).
	Compose uses springs (DefaultSpatial for the indicator and the rail, FastSpatial for the toolbar); the kit maps a spring to the duration token nearest its 1 % settling time like the sheets
	(Sheet/Parts.luau): DefaultSpatial (damping 0.9, stiffness 700) ~ 0.19 s -> Short4, FastSpatial (0.9, 1400) ~ 0.14 s ->
	Short3. No overshoot.
]]

local q = require("../Quad")
local FrameDriver = require("../FrameDriver")

local function ease(x: number): number
	local u = 1 - x
	return 1 - u * u * u * u
end

export type Options = {
	-- a counter: when it changes the value jumps to the target's end (a state's SnapTo)
	Snap: q.State<number>?,
	-- called when the value reaches an end by animation or by a snap (the state's settled value)
	OnSettle: ((atOne: boolean) -> ())?,
}

local function progress(target: q.State<boolean>, duration: number, opts: Options?): (q.Source<number>, any)
	local o: Options = opts or {}
	local value = q.Source(if target:Get() then 1 else 0)
	local snap = o.Snap or q.Source(0)
	local lastSnap = snap:Get()
	local onSettle = o.OnSettle
	local effect = q.Effect(function()
		local goal = if target:Get() then 1 else 0
		local start = value:Get()
		local snapped = snap:Get() ~= lastSnap
		lastSnap = snap:Get()
		if snapped and start ~= goal then
			value:Set(goal)
			start = goal
		end
		if start == goal then
			if onSettle then
				onSettle(goal == 1)
			end
			return nil :: any
		end
		local total = duration * math.abs(goal - start)
		local t = 0
		return FrameDriver.run(function(dt: number, stop: FrameDriver.Stop)
			t += dt
			if t >= total then
				value:Set(goal)
				stop()
				if onSettle then
					onSettle(goal == 1)
				end
				return
			end
			value:Set(start + (goal - start) * ease(t / total))
		end)
	end, target, snap)
	return value, effect
end

return { progress = progress }
