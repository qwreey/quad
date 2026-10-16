--!strict
local QT = require("../../../../../../quad-types/src")
local q = (nil :: any) :: QT.Quad
local all = q.So -- @c(qb-dot) at='q.' ins='So'
local sp = q.Sp -- @c(qm-sp) at='q.' ins='Sp'
return { all, sp }
