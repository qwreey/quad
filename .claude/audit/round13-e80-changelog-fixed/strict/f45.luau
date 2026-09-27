--!strict
-- E80 F45: strict gates that were silently off (Debounce Time/MaxTime, Operator return type) + C40 option vars
local q = require("./Quad")
type State<T> = q.State<T>

local s = q.Source(0)
local _bad = s:Apply(q.Debounce({ Time = "x" })) -- EXPECT error (Time string)
local _badMax = s:Apply(q.Debounce({ Time = 1, MaxTime = "y" })) -- EXPECT error (MaxTime string)
local _ok = s:Apply(q.Debounce({ Time = q.Source(0.3) })) -- EXPECT clean (State<number> passes StateMarker<number>)
local _okT = s:Apply(q.Throttle({ Time = 0.2 })) -- EXPECT clean
local _badT = s:Apply(q.Throttle({ Time = "z" })) -- EXPECT error
local summed = s:Apply(q.Operator.Sum(1))
local _str: string = summed:Get() -- EXPECT error (number into string)
local _num: number = summed:Get() -- EXPECT clean
local opts = { Time = 0.3 }
local _var = s:Apply(q.Debounce(opts)) -- EXPECT clean (C40 option in a variable)
