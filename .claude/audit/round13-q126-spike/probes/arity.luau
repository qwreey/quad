--!strict
-- Q126 spike side probe — is the zero-arg annotated callback rejection about nil or about arity?
local q = require("./config")
local D = q.Declaration
local f: () -> () = function() end
local _a = D.TextButton { Activated = f } -- P1 annotated zero-arg function value, no State
local _b = D.TextButton { Activated = q.Source(f) } -- P2 same inside State (inferred T = () -> ())
local g = function() end
local _c = D.TextButton { Activated = q.Source(g) } -- P3 unannotated local function inside State
