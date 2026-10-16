--!strict
local UI = require("./Ui")

local ok = UI.Frame { BackgroundTransparency = 0.5 } -- @c(central-Back) at='UI.Frame { ' ins='Back'
local name = UI.Fr -- @c(central-name) at='UI.' ins='Te'
local BAD1 = UI.Frame { Visible = 5 }
local BAD2 = UI.TextLabel { Text = 42 }
return { ok, BAD1, BAD2 }
