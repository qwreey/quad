--!nocheck
-- round13 E17 A4 — one RemoteEvent payload setting two Store fields: how many intermediate states a combined label sees
local H = require("./round13-e17-probe-setup")
local q, D, mock = H.q, H.D, H.mock
local Remote = { OnClientEvent = mock.newSignal() }
local P = q.Store({ Gold = q.Source(0), Level = q.Source(1) })
local blocker = q.Blocker and q.Blocker() or nil
Remote.OnClientEvent:Connect(function(d)
	if d.Gold ~= nil then P.Gold:Set(d.Gold) end
	if d.Level ~= nil then P.Level:Set(d.Level) end
end)
local seen = {}
local label = P.Gold:Compute(function(g, _, l) return `Lv{l:Get()} G{g:Get()}` end, P.Level)
local lbl = D.TextLabel { Text = label, q.OnChange("Text", function(v) table.insert(seen, v) end) }
table.clear(seen)
Remote.OnClientEvent:Fire({ Gold = 10, Level = 2 })
print("writes for one payload:", table.concat(seen, " | "))
