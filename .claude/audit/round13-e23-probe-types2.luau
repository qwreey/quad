--!strict
-- round13 E23 types2 — typed Modifier table fields with nested State; negative controls. Same command as probe-types.
local q = require("./round13-e16-probe-types-settings")
local D = q.Declaration
local _m1 = D.Modifier.TextLabel({ Text = q.Source(q.Source("x")) }) -- nested, right leaf type
local _m2 = D.Modifier.TextLabel({ Text = q.Source(q.Source(5)) }) -- nested, WRONG leaf type
local _m3 = D.Modifier.TextLabel({ Text = q.Source(5) }) -- single, WRONG type (control)
local _m4 = D.Modifier.TextLabel({ Text = 5 }) -- plain wrong (control)
local _m5 = D.TextLabel { D.Modifier.TextLabel({ Text = q.Source(q.Source(5)) }) } -- applied
local _m6 = D.TextLabel({}):Text(q.Source(q.Source("x"))) -- setter chain? (instances have no setters; expect error)
local _m7 = D.Modifier.TextLabel():Text(q.Source(q.Source("x"))) -- setter with nested State
local _m8 = D.Modifier.TextLabel():Text(q.Source(q.Source(5))) -- setter nested wrong
return nil
