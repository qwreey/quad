local H = require("./probe_h")
local q, mock = H.q, H.mock
local Tween = q.Tween
-- D1 tostring with Info overriding Time
print("D1", tostring(Tween({ Value = 1, Info = mock.tweenInfoShim.new(5), Time = 0.3 })))
-- D2 debug layer: Info + convenience fields together — any warning?
q.debug = true
local _ = Tween({ Value = 1, Info = mock.tweenInfoShim.new(5), Time = 0.3, Style = "x" })
print("D2 (no line above = no debug warning for Info+Time)")
q.debug = false
-- D3 CanAnimate flipped while an infinite tween runs: does the running tween stop?
mock.resetTweenLog()
local motion = q.Source(true)
local src = q.Source(0)
q.Declaration.Frame({ Name = "F", Rotation = src:Apply(q.Animate({ Time = 1, RepeatCount = -1, CanAnimate = motion })) })
src:Set(360)
motion:Set(false)
print("D3 after motion:Set(false): playing=", H.playingStr())
-- D4 a Tween on a property whose first write snaps, then a second write with a different value: engine Create is reached only then
mock.resetTweenLog()
local v = q.Source(Tween({ Value = 1, Time = 0.2 }) :: any)
local f = q.Declaration.Frame({ Name = "F", BackgroundTransparency = v }) :: any
print("D4 first set engine tweens=", #H.log, "prop=", f.BackgroundTransparency)
-- D5 Started fires synchronously right after Play even with DelayTime (engine has not moved the property)
mock.resetTweenLog()
local s5 = q.Source(0 :: any)
local f5 = q.Declaration.Frame({ Name = "F", Size = s5 }) :: any
s5:Set(Tween({ Value = 9, Time = 0.2, DelayTime = 3, Started = function(inst) print("D5 Started; plays=", H.last().plays, "prop=", inst.Size) end }))
