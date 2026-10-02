local H = require("./probe_h")
local q, mock = H.q, H.mock
for _, ev in { "Started", "Completed" } do
	mock.resetTweenLog()
	local src = q.Source(10)
	local once = false
	local info: any = { Time = 0.3 }
	info[ev] = function() if not once then once = true; src:Set(77) end end
	local st = src:Apply(q.Animate(info))
	local f = q.Declaration.Frame({ Name = "F", Size = st }) :: any
	print(`mount-snap {ev} via Animate -> src:Set(77): src={src:Get()} prop={f.Size} playing=[{H.playingStr()}]`)
	src:Set(5)
	print(`   then Set(5): playing=[{H.playingStr()}]`)
end
