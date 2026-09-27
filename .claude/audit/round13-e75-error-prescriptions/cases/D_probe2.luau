--!nocheck
-- E75 D: 0093 seat-bound handle — what does the prescribed :WeakUnsubscribe() do?
local H = require("../harness")
local q, D = H.q, H.D
local s = q.Source(0); local n, cleaned = 0, 0
local e = q.Effect(function() n += 1; return function() cleaned += 1 end end, s)
local f = D.Frame({ e })
print("bound n", n)
print("Unsubscribe ->", pcall(function() e:Unsubscribe() end))
print("WeakUnsubscribe ->", pcall(function() e:WeakUnsubscribe() end))
s:Set(1)
print("after Set n", n, "cleaned", cleaned, "Subscribed", e.Subscribed)
f:Destroy()
print("after Destroy cleaned", cleaned)
-- Observer same
local o = s:Observer(function() n += 1 end)
local g = D.Frame({ o })
print("O WeakUnsubscribe ->", pcall(function() o:WeakUnsubscribe() end))
local b = n; s:Set(2); print("O still fires", n > b)
-- routes that do stop a seat-bound handle
local s2 = q.Source(0); local m = 0
local e2 = q.Effect(function() m += 1 end, s2)
local seat = q.Source(e2)
D.Frame({ seat })
seat:Set(nil); local b2 = m; s2:Set(1); print("State seat -> nil stops Effect:", m == b2)
local e3 = q.Effect(function() m += 1 end, s2)
D.Frame({ e3 }); q.Backend.unbindLifetime(e3); local b3 = m; s2:Set(2); print("unbindLifetime stops Effect:", m == b3)
