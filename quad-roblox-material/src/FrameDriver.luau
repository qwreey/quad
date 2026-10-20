--!strict
--[[
	FrameDriver: the kit's one per-frame driver (internal — not exported). Every animation the kit computes in Lua each
	frame (the shapes a tween cannot express: the radio's sprite frames, the checkbox's two-phase marks, the ripple's
	clipped disc, the navigation progress, the app bar's settle, the progress loops, the list's edge scroll) runs
	through `run`, so the connection pattern lives in one place.

	    local stop = FrameDriver.run(function(dt: number, stop: FrameDriver.Stop)
	        ...                  -- every `RunService.Heartbeat`, with the frame delta
	        if done then stop() end
	    end)
	    ...
	    stop()                   -- from outside (an Effect cleanup, the host dying)

	`run` connects at once and returns `stop`; the step gets the same `stop` as its second argument, so it ends itself
	at the exact point it decides to (before or after its last writes — the callers rely on that order). `stop` is
	idempotent and may be called from inside the step or after it ended on its own. It ignores its arguments, so it
	can be returned as a `q.Effect` cleanup as it is (a cleanup is called with the `dying` flag).

	WHEN a driver runs (from mount, only while visible, until a goal) is the caller's business — `run` adds no
	condition. Progress/Loop.luau gates on "mounted in a GUI tree and visible"; the others run from a change until
	their goal or their owner's cleanup.
]]

local RunService = game:GetService("RunService")

export type Stop = (...any) -> ()

local function run(step: (dt: number, stop: Stop) -> ()): Stop
	local conn: RBXScriptConnection? = nil
	local function stop(...: any)
		local c = conn
		if c ~= nil then
			conn = nil
			c:Disconnect()
		end
	end
	conn = RunService.Heartbeat:Connect(function(dt: number)
		step(dt, stop)
	end)
	return stop
end

return { run = run }
