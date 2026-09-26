--!nocheck
-- E45 3(a) control: does ANY Offset observer fire on sibling growth? (outside updateFn, manual Slot)
local E = require("./env")
local mk, row, try = E.mk, E.row, E.try
local q = E.newQ()
local before = q.Slot({ mk("B1") })
local mid = q.Slot({ mk("M1") })
local fired, vals = 0, {}
local o = mid.Offset:Observer(function(st) fired += 1; table.insert(vals, st:Get()) end)
local p = E.I.new("Folder")
q.Dispatch.drive(p, { before, mid })
local f0 = fired
before:Add(mk("B2"))
local f1 = fired
local o2 = mid.Offset:Compute(function(st) return st:Get() * 10 end); local o3 = o2:Observer(function(st) table.insert(vals, "C" .. st:Get()) end)
before:Add(mk("B3"))
row("manual Slot Offset observer", `mount fired={f0} after Add={f1} after 2nd Add={fired} vals={table.concat(vals, ",")} Offset={mid.Offset:Get()}`)
