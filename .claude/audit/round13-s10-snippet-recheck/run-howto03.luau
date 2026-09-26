--!nocheck
local H = require("./harness")
local q = H.q

local scrollY = q.Source(0)
local gatedScrollY: any = scrollY:Apply(q.Throttle { Time = 0.1 })

local notifyCount = 0
gatedScrollY:Observer(function() notifyCount += 1 end)
print("notifyCount at mount (should be 1, first fire):", notifyCount)

scrollY:Set(10)
scrollY:Set(20)
scrollY:Set(30)
print("notifyCount right after 3 sets inside window (should still be 1):", notifyCount)
print("gatedScrollY:Get() (should be latest = 30):", gatedScrollY:Get())

H.runTask(0.1)
print("notifyCount after 0.1s window elapses (should be 2):", notifyCount)

H.runTask(1.0)
print("notifyCount after 1.0s more (sanity):", notifyCount)
