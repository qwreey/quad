--!strict
local D = require("./ctor-map")
local M = require("./mod-47")
local Frame, TextLabel, TextButton = D.Frame, D.TextLabel, D.TextButton
local hover = M.Modifier.GuiObject():BackgroundTransparency(0.2) -- @c(split-mod) at='M.Modifier.GuiObject():' ins='Back'
local card = Frame { -- @c(split-frame) at='Frame { ' ins='Back'
	Size = UDim2.fromScale(1, 0),
	hover,
	TextLabel { Text = "hi", TextSize = 18 },
	TextButton { AutoButtonColor = false, M.Modifier.TextButton():Text("x") },
}
local one = Frame { Visible = true } -- @c(split-frame-1line) at='Frame { ' ins='Back'
local claimed = D.Mapper.Frame("Root")({ D.Mapper.TextLabel("Title")({ Text = "t" }) })
local BAD1 = D.Frame { Visible = 5 } -- NEG
local BAD2 = D.TextLabel { Text = 42 } -- NEG
local BAD3 = D.TextButton { M.Modifier.Frame() } -- NEG: Frame modifier into TextButton
return { one, card, claimed, BAD1, BAD2, BAD3 }
