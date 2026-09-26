--!strict
-- round13 E23 types3 — Slot element controls (single vs nested State). Same command as probe-types.
local q = require("./round13-e16-probe-types-settings")
local D = q.Declaration
local frame = D.Frame {}
local _s1 = q.Slot { q.Source(frame) } -- single-level State element (control)
local inner = q.Source(frame)
local _s2 = q.Slot { q.Source(inner) } -- nested, bound through a local
local sl = q.Slot {}
sl:Add(q.Source(q.Source(frame))) -- nested via Add
local _s3 = q.Slot {}:Single(q.Source(q.Source(frame))) -- nested via :Single
return nil
