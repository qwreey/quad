local H = require("./probe_h")
local q, mock = H.q, H.mock
local Tween = q.Tween
-- A8a follow-up: after teardown-Cancelled re-entry, is the 77 tween orphaned?
mock.resetTweenLog()
local src = q.Source(0 :: any)
local f = q.Declaration.Frame({ Name = "F", Size = src }) :: any
local once = false
src:Set(Tween({ Value = 10, Time = 0.3, Cancelled = function() if not once then once = true; src:Set(Tween({ Value = 77, Time = 0.3 })) end end }))
q.Dispatch.retractFrom(f, "Size", 1)
print("after retractFrom: playing=", H.playingStr())
local t77 = H.last()
src:Set(Tween({ Value = 5, Time = 0.3 }))
print("after src:Set(5): playing=", H.playingStr(), "#log", #H.log, "t77 cancels", t77.cancels)
-- now a fresh process on the same (inst,k) — does it cancel the orphan?
q.Dispatch.process(f, "Size", Tween({ Value = 9, Time = 0.3 }), 1)
print("after fresh process(9): playing=", H.playingStr(), "t77 cancels", t77.cancels)
q.Dispatch.retractFrom(f, "Size", 1)
print("after second retractFrom: playing=", H.playingStr())

-- same thing via shorthand nil teardown (managed child destroyed)
mock.resetTweenLog()
local r = q.Source(q.Tween({ Value = 4, Time = 0.3 }) :: any)
local g = q.Declaration.Frame({ Name = "G", UIScale = r }) :: any
local once2 = false
r:Set(Tween({ Value = 8, Time = 0.3, Cancelled = function(inst, prop, v)
	print("  shorthand Cancelled", inst and inst.Name, prop, v)
	if not once2 then once2 = true; r:Set(Tween({ Value = 12, Time = 0.3 })) end
end }))
print("shorthand running:", H.playingStr())
local ok, err = pcall(function() r:Set(nil) end)
print("shorthand nil teardown ok=", ok, err)
print("after nil: playing=", H.playingStr(), "src=", tostring(r:Get() and r:Get().Value))
for _, c in g:GetChildren() do print("  child", c.Name, c.ClassName, c.Scale) end
