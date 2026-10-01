local H = require("./probe_h")
local q, mock = H.q, H.mock
local Tween = q.Tween
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Name = "F", Size = src, Position = src }) :: any
	local once = false
	src:Set(Tween({ Value = 10, Time = 0.3, Completed = function(_, prop) if prop == "Size" and not once then once = true; src:Set(Tween({ Value = 77, Time = 0.3 })) end end }))
	for _, e in H.log do if e.props.Size then H.finish(e.tween) end end
	for _, e in H.log do if e.props.Position and e.tween.PlaybackState == "Playing" and e.props.Position == 10 then H.finish(e.tween) end end
	print(`B5 engine Completed(async): src={src:Get().Value} playing=[{H.playingStr()}]`)
end
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local armed, once = false, false
	local st = src:Apply(q.Animate({ Time = 0.3, Started = function(inst, prop, v)
		print("   Animate Started", prop, v, "armed", armed)
		if armed and prop == "Size" and not once then once = true; src:Set(77) end
	end }))
	local f = q.Declaration.Frame({ Name = "F", Size = st, Position = st }) :: any
	armed = true
	src:Set(20)
	print(`B6 Animate fan-out Started -> src:Set(77): src={src:Get()} playing=[{H.playingStr()}]`)
end
