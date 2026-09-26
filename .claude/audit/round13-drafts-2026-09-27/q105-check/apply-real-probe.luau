--!strict
-- Real q.Operator / q.Animate / q.Blocker / q.Debounce through :Apply, unannotated bindings.
-- q105-check scratch, not repo source.
local Setup = require("./_setup")
local q = Setup.q

local count = q.Source(0)
local r1 = count:Apply(q.Operator.Sum(10))
local w1: string = r1
local w1b: string = r1:Get()

local alpha = q.Source(0)
local r2 = alpha:Apply(q.Animate({ Time = 0.3 }))
local w2: string = r2
local w2b: string = r2:Get()

local raw = q.Source(0)
local blocker = q.Blocker()
local r3 = raw:Apply(blocker)
local w3: string = r3
local w3b: string = r3:Get()

local searchInput = q.Source("")
local r4 = searchInput:Apply(q.Debounce({ Time = 0.2 }))
local w4: string = r4
local w4b: boolean = r4:Get()

print(w1, w1b, w2, w2b, w3, w3b, w4, w4b)
