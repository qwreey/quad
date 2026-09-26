--!nocheck
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local ref = q.Ref()
local up = q.Source(0)
G.measure("e9 long-lived Ref seated on N insts, each destroyed (Ref.Value keeps the last)", function(N, track)
	for i = 1, N do local f = D.Frame { ref }; track(f, "inst"); f:Destroy() end
end)
print("ref.Value after e9 is destroyed inst:", ref.Value ~= nil)
G.measure("e10 long-lived Ref + Effect(dep ref) on each inst, destroyed", function(N, track)
	for i = 1, N do local e = q.Effect(function() end, ref, up); local f = D.Frame { ref, e }; track(f, "inst"); track(e, "eff"); f:Destroy() end
end)
