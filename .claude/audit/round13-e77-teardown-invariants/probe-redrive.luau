--!nocheck
-- E77: a second Dispatch.drive onto an element the Declaration already built re-processes the numeric keys it
-- names — what sat at those positions is retracted (not destroyed). Found as a harness trap in the fuzzer.
local H = require("./harness")
local q, D, mock = H.q, H.D, H.mock
local log = {}
local root = D.Frame({
	q.Effect(function() table.insert(log, "fn"); return function(d) table.insert(log, "cleanup(" .. tostring(d) .. ")") end end), -- position 1
	q.OnDestroyed(function() table.insert(log, "onDestroyed") end), -- position 2
	D.Frame({ Name = "kid" }), -- position 3
})
table.insert(log, "|drive{1,2}")
q.Dispatch.drive(root, { q.Slot(), q.Slot() })
table.insert(log, "|kids=" .. #root:GetChildren())
table.insert(log, "|Destroy")
root:Destroy()
print(table.concat(log, " "))
