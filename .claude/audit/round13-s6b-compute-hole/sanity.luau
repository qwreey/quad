--!strict
local S = require("./_setup")
local B = require("./_setup_base")
local n1 = S.q.Source(1)
local _1: string = n1          -- L5 expect error
local n2 = B.q.Source(1)
local _2: string = n2          -- L7 expect error
local r2 = n2:Compute(function(s) return s:Get() + 1 end)
local _3: string = r2          -- L9 expect error
local _4: string = r2:Get()    -- L10 expect error
