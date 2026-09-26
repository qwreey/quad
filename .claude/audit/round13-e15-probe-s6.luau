--!nocheck
-- E15 (c)/(d) extras: Debounce timer callback's observer destroys its own host; Blocker released after host death;
-- Effect cleanup that Sets the Debounce source; Out echo while the displayed State is behind a Blocker.
local H = require("./round13-e15-probe-setup")
local q, D, mock, try = H.q, H.D, H.mock, H.try
print("== X1 debounced observer destroys its host from the timer callback ==")
do
	local src = q.Source("")
	local deb = src:Apply(q.Debounce { Time = 0.3 })
	local runs, host = 0, nil
	host = D.Frame { deb:Observer(function(t) runs += 1; if t:Get() == "kill" then host:Destroy() end end),
		D.TextLabel { Name = "L", Text = deb } }
	local lbl = host:FindFirstChild("L")
	src:Set("kill")
	H.run(0.31)
	print("runs", runs, "host destroyed", mock.isDestroyed(host), "label text", lbl.Text)
	src:Set("after"); H.run(0.31)
	print("runs after", runs, "label text (dead, must stay 'kill')", lbl.Text, "pending", H.pending())
end
print("== X2 Blocker held across host death, Off afterwards ==")
do
	local b = q.Blocker()
	local src = q.Source(1)
	local g = src:Apply(b)
	local writes = 0
	local host = D.Frame { D.TextLabel { Name = "L", Text = g:Compute(function(s) writes += 1; return tostring(s:Get()) end) } }
	local lbl = host:FindFirstChild("L")
	b:On(); src:Set(2); host:Destroy()
	try("blocker:Off after host death", function() b:Off() end)
	print("label text", lbl.Text, "compute runs", writes)
end
print("== X3 Effect cleanup(dying) Sets a Debounce'd source watched by a live sibling ==")
do
	local src = q.Source("a")
	local deb = src:Apply(q.Debounce { Time = 0.2 })
	local seen = {}
	local live = D.Frame { deb:Observer(function(t) table.insert(seen, t:Get()) end) }
	local dying = D.Frame { q.Effect(function() return function(d) if d then src:Set("from-cleanup") end end end) }
	dying:Destroy()
	H.run(0.25)
	print("live saw", table.concat(seen, ","))
	live:Destroy()
end
print("== X4 Out echo when the displayed Text is gated by a Blocker (typing during the window) ==")
do
	local b = q.Blocker()
	local store = q.Store({ Name = q.Source("init") })
	local box = D.TextBox { Text = store.Name:Apply(b), q.Out("Text", store.Name) }
	b:On()
	store.Name:Set("") -- programmatic reset inside window (display held)
	box.Text = "abc" -- user types during window -> Out writes store
	print("inside: store", store.Name:Get(), "box", box.Text)
	b:Off()
	print("after Off: store", store.Name:Get(), "box", box.Text)
	-- reverse: user typed, then program reset inside window, Off
	b:On(); box.Text = "typed"; store.Name:Set("reset"); b:Off()
	print("after Off2: store", store.Name:Get(), "box", box.Text)
end
