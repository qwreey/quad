--!strict
-- E33: OnChangeDescriptor — two same-named types (package re-export vs generated) and frozen-ness
local QT = require("../../../quad-roblox/luau_packages/quad_types")
local QRmod = require("../../../quad-roblox/src")
local q: QT.Quad & QRmod.RobloxExtension = nil :: any
local d = q.OnChange("Size", function(v: UDim2) end)
d.Name = "Position" -- W1: runtime descriptor is frozen (doc "frozen 디스크립터"); does the type allow the write?
local _g: QRmod.OnChangeDescriptor<"Size"> = d -- W2: doc 05 shows OnChangeDescriptor<K>; re-exported alias is non-generic
local _h: QRmod.OnChangeDescriptor = d -- W3: generated descriptor into the re-exported one
return nil
