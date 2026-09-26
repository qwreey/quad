--!nocheck
-- round13 E17 A3 — a destroyed Instance still referenced by user code: does its Text binding stay on the Source?
local H = require("./round13-e17-probe-setup")
local q, D, subs = H.q, H.D, H.subs
local s = q.Source("")
local tb = D.TextBox { Text = s }
print("subs live", subs(s))
tb:Destroy()
print("subs after Destroy, inst still referenced", subs(s))
s:Set("x"); print("dead Text", tb.Text, "subs after a Set", subs(s))
tb = nil
print("subs after reference dropped", subs(s))
