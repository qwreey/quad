--!strict
local q = require("./round13-e14-types-settings")
local R = require("../../quad-roblox/src")
local D = q.Declaration
local function f1(m: R.TextButtonModifier) return m end
local _a = f1(D.Modifier.GuiObject():ZIndex(2)) -- E?:H1a ancestor into concrete param
local _b = f1(D.Modifier.Frame()) -- E?:H1b sibling into concrete param
type P = { read Modifier: R.TextButtonModifier? }
local function f2(p: P) return p end
local _c = f2({ Modifier = D.Modifier.GuiObject() }) -- E?:H1c optional field ancestor
local _d = f2({ Modifier = D.Modifier.Frame() }) -- E?:H1d optional field sibling
local _e: R.TextButtonModifier = D.Modifier.Frame() -- E?:H1e direct assignment sibling
local Boldify = function(mod: R.TextButtonModifier): R.TextButtonModifier return mod:TextSize(20) end
local _x = D.Modifier.Frame():Apply(Boldify) -- E?:X2
local _y = D.Frame({ D.Modifier.Frame():Apply(Boldify) }) -- E?:X3 result TextButtonModifier into Frame children
return nil
