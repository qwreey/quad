--!nocheck
local H = require("./harness")
local D = H.D
local DeclarationModule = require("../../../quad-roblox/src/Declaration")

local buttonMod = D.Modifier.TextButton():BackgroundTransparency(0.5):Text("Go")
local sameRuntimeValue = D.Modifier.TextButton { BackgroundTransparency = 0.5, Text = "Go" }

local base = D.Modifier.GuiObject():Visible(true)
local checked = base:AsTextButton():Text("ok")
local unchecked = base:As("TextLabel")

local btn = D.TextButton { buttonMod, sameRuntimeValue, checked }
print("BackgroundTransparency:", btn.BackgroundTransparency, "Text:", btn.Text, "Visible:", btn.Visible)

local lbl = D.TextLabel { unchecked }
print("label visible:", lbl.Visible)
