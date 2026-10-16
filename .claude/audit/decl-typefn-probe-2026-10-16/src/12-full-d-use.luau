--!strict
-- consumer of 11-full-d (Studio path via script.Parent; CLI path via relative require)
local D = require("./11-full-d")
local Frame, TextLabel, TextButton = D.Frame, D.TextLabel, D.TextButton
local hover = D.Modifier.GuiObject():BackgroundTransparency(0.2) -- @c(d-mod) at='D.Modifier.GuiObject():' ins='Back'
local card = Frame { -- @c(d-frame) at='Frame { ' ins='Back'
	Size = UDim2.fromScale(1, 0),
	hover,
	TextLabel { Text = "hi", TextSize = 18 },
	TextButton { AutoButtonColor = false, D.Modifier.TextButton():Text("x") },
}
local claimed = D.Mapper.Frame("Root")({ D.Mapper.TextLabel("Title")({ Text = "t" }) })
local BAD1 = D.Frame { Visible = 5 } -- NEG
local BAD2 = D.TextLabel { Text = 42 } -- NEG
local BAD3 = D.TextButton { D.Modifier.Frame() } -- NEG: Frame modifier into TextButton
return { card, claimed, BAD1, BAD2, BAD3 }
