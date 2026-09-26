--!strict
local q = require("./round13-e14-types-settings")
local R = require("../../quad-roblox/src")
local D = q.Declaration
local Boldify = function(mod: R.TextButtonModifier): R.TextButtonModifier return mod:TextSize(20) end
local z: number = D.Modifier.Frame():Apply(Boldify) -- probe U
local z2: number = D.Modifier.TextButton():Apply(Boldify) -- probe U
local w = D.Modifier.TextButton():Apply(Boldify)
local _w = D.Frame({ w }) -- E?: TextButtonModifier into Frame children
local v: R.TextButtonModifier = D.Modifier.TextButton()
local _v = D.Frame({ v }) -- E: control
return z, z2
