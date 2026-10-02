local H = require("./probe_h")
local q, mock = H.q, H.mock
-- "pulse" loop chained from Completed (the documented chaining seat)
local function run(canAnimate: boolean)
	mock.resetTweenLog()
	local pulse = q.Source(0)
	local n = 0
	local st = pulse:Apply(q.Animate({ Time = 0.5, CanAnimate = canAnimate, Completed = function(_, _, v)
		n += 1
		pulse:Set(if v == 0 then 1 else 0)
	end }))
	local ok, err = pcall(function()
		q.Declaration.Frame({ Name = "F", BackgroundTransparency = st })
	end)
	print(`CanAnimate={canAnimate}: mount ok={ok} completedCalls={n} engineTweens={#H.log} err={err and string.sub(tostring(err), 1, 200)}`)
	if ok and canAnimate then
		for i = 1, 5 do local t = H.last(); if t and t.PlaybackState == "Playing" then H.finish(t) end end
		print(`   after 5 engine finishes: completedCalls={n} engineTweens={#H.log}`)
	end
end
run(true)
run(false)
-- same, but the motion switch is flipped at runtime while the loop is running
do
	mock.resetTweenLog()
	local pulse = q.Source(0)
	local motion = q.Source(true)
	local n = 0
	local st = pulse:Apply(q.Animate({ Time = 0.5, CanAnimate = motion, Completed = function(_, _, v)
		n += 1
		pulse:Set(if v == 0 then 1 else 0)
	end }))
	q.Declaration.Frame({ Name = "F", BackgroundTransparency = st })
	print("runtime flip: after mount n=", n, "#log", #H.log)
	motion:Set(false) -- option State is not a dependency: nothing happens yet
	print("   after motion:Set(false) n=", n)
	local ok, err = pcall(function() H.finish(H.last()) end)
	print(`   after the running tween finishes: ok={ok} n={n} err={err and string.sub(tostring(err), 1, 160)}`)
end
