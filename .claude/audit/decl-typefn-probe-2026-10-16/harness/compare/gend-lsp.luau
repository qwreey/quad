--!strict
-- CLI/VSCode-only control (not synced to Studio): the SAME completion/hover spots as 01·02 against today's
-- generated Declaration, for Q6 (latency) and the hover-readability comparison.
local DM = require("../../../../../quad-roblox/src/Declaration")
local D: DM.Declaration = nil :: any
local ok1 = D.Frame({ BackgroundColor3 = Color3.new(1, 1, 1), Visible = true }) -- @c(gend-frame-Back) at='D.Frame({ ' ins='Back'
local ok2 = D.TextLabel({ Text = "hi" }) -- @c(gend-label-Te) at='D.TextLabel({ ' ins='Te'
local m = D.Modifier.Frame()
local c1 = m:BackgroundTransparency(0.5) -- @c(gend-mod-Back) at='m:' ins='Back'
local hoverF = D.Frame -- @h(gend-hover-Frame) at='Frame -- @h'
local hoverM = m -- @h(gend-hover-m) at='m -- @h'
local bad = D.Frame({ Visible = 5 })
return { ok1, ok2, c1, hoverF, hoverM, bad }
