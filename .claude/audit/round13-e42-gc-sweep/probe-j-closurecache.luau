--!nocheck
-- control for j2/j4/j5 residue=1: Luau caches closures whose upvalues are all unchanged, so the
-- "per-iteration" callback is ONE object reused every iteration (held by the enclosing function).
local G = require("./gclib")
local H = require("./harness")
local q, D = H.q, H.D
local shared = q.Source("s")
local seen = {}
local distinct = 0
for i = 1, 5 do local cb = function(v) shared:Set(v) end; if not seen[cb] then seen[cb] = true; distinct += 1 end end
print("distinct closures over 5 iterations (upvalue-invariant):", distinct)
G.measure("j2b OnChange cb capturing per-iteration i, Destroy", function(N, track)
	for i = 1, N do local cb = function(v) shared:Set(v .. i) end; local f = D.Frame { q.OnChange("Name", cb) }; track(cb, "cb"); track(f, "inst"); f:Destroy() end
end)
