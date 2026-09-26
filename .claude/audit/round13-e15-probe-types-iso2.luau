--!strict
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration
type Sub = { Username: string }
local s = q.Source("")
local sub = q.Source<<Sub?>>(nil)
local _a = D.Frame { s:Observer(function(t) local n: number = t:Get(); print(n) end) } -- J1 expect error (string->number) if typed
local _b = D.Frame { sub:Observer(function(t) local p = t:Get(); if p == nil then return end; local n: number = p.Username; print(n) end) } -- J2 how-to 02 §5 shape
local _c = D.ScreenGui { sub:Observer(function(t) local p = t:Get(); if p == nil then return end; print(p.Username) end) } -- J3 verbatim-ish
local _d = D.Frame { s:Observer(function(t) local v = t:Get(); print(string.upper(v)) end) } -- J4
local _e = D.Frame { s:Observer(function(t: q.StateData<string>) local v = t:Get(); print(#v) end) } -- J5 annotated param
local _f = D.Frame { q.Effect(function() local v = s:Get(); print(#v) end, s) } -- J6 Effect reading closure
local o = s:Observer(function(t) local n: number = t:Get(); print(n) end) -- J7 standalone expect error
local _g = D.Frame { o }
