--!nocheck
-- round13 E17 A (cont.) — what keeps a node on the Store after the screen is gone; shared-store churn
local H = require("./round13-e17-probe-setup")
local q, D, mock, try, track, alive, subs = H.q, H.D, H.mock, H.try, H.track, H.alive, H.subs
local sent = {}
local Remote = { OnClientEvent = mock.newSignal(), FireServer = function(_, v) table.insert(sent, v) end }
local function NameForm()
	local store = q.Store({ Name = q.Source("") })
	local valid = track("valid", store.Name:Compute(function(s) return #s:Get() >= 3 end))
	local debounced = track("debounced", store.Name:Apply(q.Debounce { Time = 0.3 }))
	local root = D.Frame {
		debounced:Observer(function(t) if valid:Get() then Remote:FireServer(t:Get()) end end),
		D.TextBox { Name = "Input", Text = store.Name, q.Out("Text", store.Name) },
	}
	return root, store
end
local f, st = NameForm()
f:FindFirstChild("Input").Text = "abcd"; H.run(1)
f:Destroy(); f = nil
print("alive after destroy (store held)", alive(), "subs", subs(st.Name))
st = nil
print("alive after store dropped", alive())
local shared = q.Store({ Name = q.Source("") })
for i = 1, 100 do
	local debounced = shared.Name:Apply(q.Debounce { Time = 0.3 })
	local r = D.Frame { debounced:Observer(function() end), D.TextBox { Name = "I", Text = shared.Name, q.Out("Text", shared.Name) } }
	r:FindFirstChild("I").Text = "x" .. i
	r:Destroy()
end
H.run(1)
print("shared store after 100 screens: subs", subs(shared.Name), "pending timers", H.pending())
