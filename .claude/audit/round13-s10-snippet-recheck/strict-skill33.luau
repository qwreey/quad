--!strict
local q = require("./s10-config")
local D = q.Declaration
local DeclarationModule = require("../../../quad-roblox/src/Declaration")

local buttonMod = D.Modifier.TextButton():BackgroundTransparency(0.5):Text("Go")
local sameRuntimeValue = D.Modifier.TextButton { BackgroundTransparency = 0.5, Text = "Go" }

local base = D.Modifier.GuiObject():Visible(true)
local checked = base:AsTextButton():Text("ok")
local unchecked = base:As<<DeclarationModule.TextLabelModifier>>()
print(buttonMod, sameRuntimeValue, checked, unchecked)
