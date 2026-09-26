--!nocheck
-- E15: is a never-destroyed, dropped tree collectable in the CLI mock? (method check for leak counts)
local H = require("./round13-e15-probe-setup")
local q, D, track, alive = H.q, H.D, H.track, H.alive
local shared = q.Source("x")
local function mk(tag, bindShared)
	local f = D.Frame { D.TextLabel { Text = if bindShared then shared else "plain" } }
	track(tag, f)
end
mk("A_plain_dropped", false)
mk("B_bound_to_live_source_dropped", true)
local function mk2(tag)
	local f = D.Frame { D.TextLabel { Text = shared } }
	track(tag, f)
	f:Destroy()
end
mk2("C_bound_destroyed")
print(alive())
