local ev = {}
flash:Observer(function(t) table.insert(ev, "flash=" .. tostring(t:Get())) end):Subscribe()
table.clear(ev)
local frame = D.Frame { Position = positionState, BackgroundColor3 = btnColor }
print("snap: Position.X.Scale", frame.Position.X.Scale, "tweens", #mock.tweenLog, "events", table.concat(ev, ","))
table.clear(ev)
targetSrc:Set(UDim2.fromScale(1, 0))
print("1st real tween: tweens", #mock.tweenLog, "events", table.concat(ev, ","))
table.clear(ev)
targetSrc:Set(UDim2.fromScale(0.5, 0))
print("replace: tweens", #mock.tweenLog, "events", table.concat(ev, ","), "old cancelled:", mock.tweenLog[1].tween.cancels)
table.clear(ev)
mock.tweenLog[#mock.tweenLog].tween:simulateCompleted()
print("natural finish: events", table.concat(ev, ","))
table.clear(ev)
targetSrc:Set(UDim2.fromScale(0.5, 0))
print("Dedup same target: tweens", #mock.tweenLog, "events", table.concat(ev, ","))
hoverSrc:Set(true)
print("Animate hover: tweens", #mock.tweenLog)
-- Animate CanAnimate=false + callback
local done = {}
local s = q.Source(0)
local lbl = D.Frame { BackgroundTransparency = s:Apply(q.Animate { Time = 0.2, CanAnimate = false, Started = function() table.insert(done, "S") end, Completed = function() table.insert(done, "C") end }) }
done = {}; local before = #mock.tweenLog
s:Set(0.5)
print("CanAnimate=false: value", lbl.BackgroundTransparency, "tweens added", #mock.tweenLog - before, "callbacks", table.concat(done, ","))
