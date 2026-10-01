local H = require("./probe_h")
local q, mock = H.q, H.mock
mock.resetTweenLog()
local motion = q.Source(true)
local src = q.Source(0)
local f = q.Declaration.Frame({ Name = "F", Rotation = src:Apply(q.Animate({ Time = 1, RepeatCount = -1, CanAnimate = motion })) }) :: any
src:Set(360)
motion:Set(false)
src:Set(src:Get())
print("after re-emit same value with motion off: playing=", H.playingStr(), "prop=", f.Rotation, "cancels=", H.last().cancels)
