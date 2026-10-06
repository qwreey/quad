--!nocheck
local E = require("../round13-e79-deferred-signals/env")
local S, mock = E.S, E.mock
S.reset("imm")
local q = E.newProv()
local src = q.Source(1); local armed = true
local log = {}
local f = q.Declaration.Frame({ Size = src,
	q.OnChange("Size", function(v) table.insert(log, "w" .. tostring(v)); if armed and v == 1 then armed = false; table.insert(log, "set2"); src:Set(2); table.insert(log, "setT99"); src:Set(q.Tween({ Value = 99 })); table.insert(log, "done") end end) })
print(table.concat(log, " "), "Size", f.Size)
for i, e in mock.tweenLog do print(i, e.props.Size, e.tween.PlaybackState, e.tween.cancels) end
src:Set(5)
for i, e in mock.tweenLog do print(i, e.props.Size, e.tween.PlaybackState, e.tween.cancels) end
