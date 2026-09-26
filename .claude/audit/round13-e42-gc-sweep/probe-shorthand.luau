--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local UDim = H.EG.UDim
G.measure("b5 UICorner/UIPadding shorthand, inst:Destroy()", function(N, track)
	for i = 1, N do
		local f = D.Frame { UICorner = UDim.new(0, 4), UIPadding = q.Source(UDim.new(0, i)) }
		track(f, "inst"); track(f:FindFirstChild("_quad_corner") or f:GetChildren()[1], "managedChild")
		f:Destroy()
	end
end)
local seat = q.Source(UDim.new(0, 1))
local live = D.Frame { UICorner = seat }
G.measure("b6 live inst, UICorner toggled nil<->value N times (managed child destroyed/recreated)", function(N, track)
	for i = 1, N do seat:Set(UDim.new(0, i)); track(live:GetChildren()[1], "managedChild"); seat:Set(nil) end
end)
