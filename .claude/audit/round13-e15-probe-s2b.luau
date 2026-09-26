--!nocheck
-- E15 S2 follow-up: rows destroyed (KeyGone inside a Blocker window, and Detach) while their Position tween is Playing.
local H = require("./round13-e15-probe-setup")
local q, D, mock, try, track, alive = H.q, H.D, H.mock, H.try, H.track, H.alive
local done, cancelled, started = {}, {}, {}
local function Row(id, abs)
	local pos = abs:Compute(function(a) return a:Get() * 50 end):Apply(q.Animate { Time = 0.2,
		Started = function() table.insert(started, id) end,
		Completed = function() table.insert(done, id) end,
		Cancelled = function() table.insert(cancelled, id) end })
	return D.Frame { Name = id, Position = pos }
end
local function run(mode)
	table.clear(done); table.clear(cancelled); table.clear(started); mock.resetTweenLog()
	local blocker = q.Blocker()
	local data = q.Source({ "a", "b", "c" })
	local gated = data:Apply(blocker)
	local slot = q.Slot():List(gated, function(ctx)
		if ctx.Item == q.KeyGone then return (if mode == "detach" then q.Detach else nil), ctx.UserData end
		if ctx.Prev then
			if ctx.UserData:Get() ~= ctx.Index then ctx.UserData:Set(ctx.Index) end
			return ctx.Prev, ctx.UserData
		end
		local abs = q.Source(ctx.Index)
		return Row(ctx.Item, abs), abs
	end, function(item) return item end)
	local host = D.Frame { slot }
	data:Set({ "b", "c" }) -- b,c shift -> tweens Playing
	local playing = {}
	for _, r in H.tweenLog do if r.tween.PlaybackState == "Playing" then table.insert(playing, r) end end
	print(mode, "playing after shift", #playing, "started", table.concat(started, ","))
	blocker:On()
	data:Set({})
	-- engine: Completed would arrive deferred; here the rows are not yet removed (blocker holds)
	blocker:Off()
	local cancels = 0
	for _, r in H.tweenLog do cancels += r.tween.cancels end
	print(mode, "after removal: children", #host:GetChildren(), "tween.Cancel calls", cancels, "Cancelled cb", table.concat(cancelled, ","), "destroyed b?", playing[1] and mock.isDestroyed(playing[1].inst))
	-- late natural completion arriving after removal
	for _, r in playing do if r.tween.PlaybackState == "Playing" then r.tween:simulateCompleted() end end
	print(mode, "late completes -> Completed cb", table.concat(done, ","), "Cancelled cb", table.concat(cancelled, ","))
	if mode == "detach" then
		-- reattach the detached rows
		blocker:On(); data:Set({ "b", "c" }); blocker:Off()
		print(mode, "reattach children", #host:GetChildren())
	end
	host:Destroy()
end
run("destroy")
run("detach")
