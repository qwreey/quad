local shim = require("./shim")
local q = shim.q
local D = q.Declaration
local f = D.Frame({ Name = "x", Size = shim.UDim2.fromScale(1,1) })
print(f.Name, f.ClassName)
local btn = D.TextButton({ Text = "hi", Activated = function() print("clicked") end })
print(btn.Text)
