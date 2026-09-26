--!strict
local q = require("./s10-config")
local D = q.Declaration
local src = q.Source(D.Frame {} :: GuiObject)
local _x = D.Frame { q.Out("NextSelectionUp", src) } -- X1 Out with non-nil Source<GuiObject>
local _y = D.Frame { q.OnChange("NextSelectionUp", function(v) local _n: GuiObject = v end) } -- X2 OnChange callback param nilable?
