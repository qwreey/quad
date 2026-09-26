--!strict
local q = require("./round13-e14-types-settings")
local D = q.Declaration
local _a = D.Modifier.Frame():BackgroundTransparency(q.Animate({ Time = 0.3 })) -- E?:A1 Animate factory into setter
local _b = D.Modifier.Frame():BackgroundTransparency(q.Source(0.5):Apply(q.Animate({ Time = 0.3 }))) -- OK:A2
local _c = D.Modifier.Frame():Apply(q.Animate({ Time = 0.3 })) -- E?:A3 Animate via Modifier:Apply
return nil
