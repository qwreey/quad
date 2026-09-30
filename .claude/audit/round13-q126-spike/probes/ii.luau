--!strict
-- Q126 spike — option (ii): Source:Set accepts None. P = wanted, N = must still error, S = side effect (passes but is a hole).
local q = require("./config")
local QT = require("../quad-types/src")
local D = q.Declaration
type None = QT.None

local active = q.Source(true)
local _a = D.Frame { q.BooleanAttr("Active", active) }
active:Set(q.None) -- P1 the GS 05 idiom as written
local _n1 = q.Source(1):Set("x") -- N1 wrong type still rejected
local label = q.Source("hi")
label:Set(q.None) -- S1 any State now takes None…
local _s2 = D.TextLabel { Text = label } -- S2 …and flows into Text (runtime writes nil → engine throws); no diagnostic
local n: number = q.Source(1):Set(q.None):Get() -- S3 Get() still typed number, runtime value is None
local _s4 = n + 1 -- S4 arithmetic on it type-checks
