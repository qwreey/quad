--!nocheck
-- E15 S1 leak isolation — per-variant in its own function frame so no dead registers pin anything.
local H = require("./round13-e15-probe-setup")
local q, D, track, alive = H.q, H.D, H.track, H.alive

local function build(tag, sharedUser, pendingAtDestroy, useDebounce, destroy)
	local user = sharedUser or q.Source("")
	local root = D.Frame {
		(if useDebounce then user:Apply(q.Debounce { Time = 0.3 }) else user:Compute(function(s) return s:Get() end)):Observer(function() end),
		D.TextBox { Name = "User", Text = user, q.Out("Text", user) },
	}
	track(tag .. ".root", root)
	track(tag .. ".src", user)
	if pendingAtDestroy then user:Set("typing" .. tag) end
	if destroy then root:Destroy() end
end

build("A_debounce_idle_destroyed", nil, false, true, true)
build("B_debounce_pending_destroyed", nil, true, true, true)
build("C_compute_destroyed", nil, true, false, true)
print("before timers:", alive())
H.run(1)
print("after timers:", alive())
local shared = q.Source("")
build("D_shared_src_debounce_destroyed", shared, true, true, true)
H.run(1)
print("shared src alive, form destroyed:", alive("D_"))
build("E_shared_src_debounce_notdestroyed_dropped", shared, false, true, false)
print("shared src alive, form never destroyed, dropped:", alive("E_"))
