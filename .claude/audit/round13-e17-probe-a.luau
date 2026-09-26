--!nocheck
-- round13 E17 A — how-to 04 (RemoteEvent / input bridge) integration. a normal / b teardown+leak / c reentrancy / d time.
local H = require("./round13-e17-probe-setup")
local q, D, mock, try, track, alive, subs, conns = H.q, H.D, H.mock, H.try, H.track, H.alive, H.subs, H.conns
local function P(...) print(...) end

-- ── engine shims ──
local ProfileUpdated = { OnClientEvent = mock.newSignal() }
local serverLog = {}
local SubmitName = {
	OnClientEvent = mock.newSignal(),
	FireServer = function(self, v) table.insert(serverLog, v) end,
}
local UIS = { InputBegan = mock.newSignal(), InputChanged = mock.newSignal() }
local Enum2 = { KeyCode = { Tab = "Tab", E = "E" }, UserInputType = { MouseMovement = "MM", Keyboard = "KB" } }

P("== A1 §2 RemoteEvent → Store → TextLabel ==")
local ProfileStore = q.Store({ Gold = q.Source(0), Level = q.Source(1) })
ProfileUpdated.OnClientEvent:Connect(function(newData)
	if newData.Gold ~= nil then ProfileStore.Gold:Set(newData.Gold) end
	if newData.Level ~= nil then ProfileStore.Level:Set(newData.Level) end
end)
local function withCommas(n)
	local s = tostring(math.floor(n))
	local replaced = 1
	while replaced > 0 do s, replaced = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2") end
	return s
end
local function GoldDisplay()
	local goldText = ProfileStore.Gold:Compute(function(gold) return `보유 골드: {withCommas(gold:Get())} G` end)
	track("A1.goldText", goldText)
	return D.TextLabel { Text = goldText }
end
local gd = GoldDisplay()
track("A1.label", gd)
P("initial", gd.Text)
ProfileUpdated.OnClientEvent:Fire({ Gold = 1234567 })
P("after gold", gd.Text)
ProfileUpdated.OnClientEvent:Fire({ Level = 5 })
P("after level only", gd.Text, ProfileStore.Level:Get())
ProfileUpdated.OnClientEvent:Fire({ Gold = -1234.9 })
P("negative float", gd.Text)
P("Gold subs before destroy", subs(ProfileStore.Gold))
gd:Destroy()
gd = nil
P("Gold subs after destroy (goldText Compute node may linger until collect)", subs(ProfileStore.Gold))
ProfileUpdated.OnClientEvent:Fire({ Gold = 5 })
P("late event after screen destroy: store", ProfileStore.Gold:Get(), "alive:", alive("A1"))
-- remount 50 times; subs must stay bounded
for i = 1, 50 do local x = GoldDisplay(); x:Destroy() end
P("after 50 mount/destroy cycles, Gold subs", subs(ProfileStore.Gold), "alive", alive("A1"))
-- dropped WITHOUT Destroy (Parent never set, reference dropped)
for i = 1, 20 do local x = GoldDisplay() end
P("after 20 dropped-without-Destroy, Gold subs", subs(ProfileStore.Gold), "alive", alive("A1"))

P("== A2 §3 Tab toggles inventory, X closes ==")
local isInventoryOpen = q.Source(false)
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum2.KeyCode.Tab then isInventoryOpen:Set(not isInventoryOpen:Get()) end
end)
local function InventoryModal()
	return D.Frame {
		Visible = isInventoryOpen,
		D.TextButton { Name = "X", Text = "X", MouseButton1Click = function() isInventoryOpen:Set(false) end },
	}
end
local inv = InventoryModal()
P("initial Visible", inv.Visible)
UIS.InputBegan:Fire({ KeyCode = "Tab" }, false); P("Tab ->", inv.Visible)
UIS.InputBegan:Fire({ KeyCode = "Tab" }, true); P("Tab (gameProcessed) ->", inv.Visible)
inv:FindFirstChild("X").MouseButton1Click:Fire(); P("X ->", inv.Visible)
inv:Destroy()
UIS.InputBegan:Fire({ KeyCode = "Tab" }, false)
P("Tab after destroy: source", isInventoryOpen:Get(), "inv.Visible (dead)", inv.Visible, "subs", subs(isInventoryOpen))

P("== A3 §4 CrosshairOverlay (Effect + cleanup) ==")
local cleanupCalls = 0
local function CrosshairOverlay()
	local mousePos = q.Source(Vector2 and Vector2.zero or { X = 0, Y = 0 })
	track("A3.mousePos", mousePos)
	local dotPosition = mousePos:Compute(function(pos) local p = pos:Get() return { X = p.X, Y = p.Y } end)
	return D.Frame {
		Size = 1,
		q.Effect(function()
			local conn = UIS.InputChanged:Connect(function(input)
				if input.UserInputType == "MM" then mousePos:Set({ X = input.Position.X, Y = input.Position.Y }) end
			end)
			return function(dying) cleanupCalls += 1; conn:Disconnect() end
		end),
		D.Frame { Name = "Dot", Position = dotPosition },
	}
end
local base = conns(UIS.InputChanged)
local ov = CrosshairOverlay()
P("connections after mount", conns(UIS.InputChanged) - base)
UIS.InputChanged:Fire({ UserInputType = "MM", Position = { X = 10, Y = 20 } })
local dot = ov:FindFirstChild("Dot")
P("dot", dot.Position.X, dot.Position.Y)
ov:Destroy()
P("after destroy: conns", conns(UIS.InputChanged) - base, "cleanup calls", cleanupCalls)
UIS.InputChanged:Fire({ UserInputType = "MM", Position = { X = 99, Y = 99 } })
P("dot after late input (dead)", dot.Position.X)
ov, dot = nil, nil
P("alive A3", alive("A3"))
-- mount/destroy 30x
for i = 1, 30 do local o = CrosshairOverlay(); o:Destroy() end
P("30 cycles: conns", conns(UIS.InputChanged) - base, "cleanup", cleanupCalls, "alive", alive("A3"))
-- dropped without destroy: Effect never cleans (engine semantics — Destroying never fires)
for i = 1, 5 do local o = CrosshairOverlay() end
P("5 dropped-without-Destroy: conns (engine: leak by design)", conns(UIS.InputChanged) - base, "alive", alive("A3"))

P("== A4 §4 StatusPanel (component-time Connect + OnDestroyed) ==")
local SomeSignal = mock.newSignal()
local fires = 0
local function StatusPanel()
	local conn = SomeSignal:Connect(function() fires += 1 end)
	return D.Frame { q.OnDestroyed(function() conn:Disconnect() end) }
end
local sp = StatusPanel()
SomeSignal:Fire(); sp:Destroy(); SomeSignal:Fire()
P("fires", fires, "conns", conns(SomeSignal))
-- throw after Connect but inside the D.Frame (bad prop) → conn leaks (user pattern) ?
local ok = try("StatusPanel with a throwing sibling", function()
	local conn = SomeSignal:Connect(function() fires += 1 end)
	return D.Frame { q.OnDestroyed(function() conn:Disconnect() end), Nope = 1 }
end)
P("conns after throw", conns(SomeSignal))

P("== A5 input → Out → Store → validate → Debounce → FireServer; server echo ==")
local function NameForm(opts)
	local store = q.Store({ Name = q.Source("") })
	track("A5.store", store)
	local valid = store.Name:Compute(function(s) return #s:Get() >= 3 end)
	local debounced = store.Name:Apply(q.Debounce { Time = 0.3 })
	track("A5.debounced", debounced)
	local root = D.Frame {
		debounced:Observer(function(t)
			local v = t:Get()
			if valid:Get() then SubmitName:FireServer(v) end
		end),
		q.Effect(function()
			local c = SubmitName.OnClientEvent:Connect(function(norm)
				if opts.echo then store.Name:Set(norm) end
			end)
			return function() c:Disconnect() end
		end),
		D.TextBox { Name = "Input", Text = store.Name, q.Out("Text", store.Name) },
	}
	return root, store
end
local f5, st5 = NameForm({ echo = false })
local tb = f5:FindFirstChild("Input")
for _, s in { "a", "ab", "abc", "abcd" } do tb.Text = s; H.run(0.1) end
P("store while typing", st5.Name:Get(), "sent so far", #serverLog)
H.run(0.5)
P("after quiet: sent", table.concat(serverLog, ","))
table.clear(serverLog)
-- typing then destroy before the debounce fires → nothing sent after destroy
tb.Text = "zzzz"; H.run(0.1); f5:Destroy(); H.run(1)
P("destroy mid-window: sent", table.concat(serverLog, ","), "pending timers", H.pending())
-- store outlives screen (held by caller): late server event sets a store no UI reads
st5.Name:Set("late")
P("late Set after destroy: store", st5.Name:Get(), "Name subs", subs(st5.Name))
f5, tb = nil, nil

-- echo: the server normalizes (lowercase) and echoes on OnClientEvent; the listener Sets the Store
table.clear(serverLog)
SubmitName.FireServer = function(self, v)
	table.insert(serverLog, v)
	SubmitName.OnClientEvent:Fire(string.lower(v)) -- synchronous echo (worst case)
end
local f6, st6 = NameForm({ echo = true })
local tb6 = f6:FindFirstChild("Input")
tb6.Text = "ABCD"
H.run(0.35)
P("echo: sent after 1st window", table.concat(serverLog, ","), "store", st6.Name:Get(), "box", tb6.Text)
H.run(0.35)
P("echo: after 2nd window", table.concat(serverLog, ","))
H.run(3)
P("echo: after 3s more", #serverLog, "sends")
f6:Destroy(); H.run(1)
local n6 = #serverLog
H.run(2)
P("echo: after destroy sends grow?", #serverLog - n6)
