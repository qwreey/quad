local H = require("./probe_h")
local q, mock = H.q, H.mock
-- Dialog pattern: Size animates with `open`; Completed of the CLOSE tween hides the dialog / notifies "closed".
local open = q.Source(false)
local notified = {}
local size = open:Apply(q.Animate({ Time = 0.25, Completed = function(inst, prop, v)
	table.insert(notified, `Completed(open={open:Get()}, value={tostring(v)}, Parent={tostring(inst.Parent)}, Name={tostring(inst.Name)}, Rotation={tostring(inst.Rotation)})`)
end, Started = function(inst, prop, v)
	table.insert(notified, `Started(value={tostring(v)})`)
end }))
local size2 = open:Compute(function(s) return if s:Get() then 1 else 0 end)
local parent = q.Declaration.Frame({ Name = "Parent" }) :: any
local dlg = q.Declaration.Frame({ Name = "Dialog", Rotation = 5, BackgroundTransparency = size2:Apply(q.Animate({ Time = 0.25, Completed = function(inst) table.insert(notified, "BT Completed Parent=" .. tostring(inst.Parent)) end })), Size = size }) :: any
print("callbacks fired during D.Frame construction (dialog starts CLOSED):")
for _, s in notified do print("  " .. s) end
dlg.Parent = parent
table.clear(notified)
open:Set(true)
print("after open:Set(true):", table.concat(notified, " | "), "#tweens", #H.log)
