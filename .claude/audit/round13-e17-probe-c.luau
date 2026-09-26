--!nocheck
-- round13 E17 C — how-to 04 + 07 combined: a Claim'd HUD fed by RemoteEvent values; screen replacement (re-Claim of a
-- fresh clone) N times; leak counting after collectgarbage. a normal / b teardown+leak / c reentrancy (replace from inside a wave).
local H = require("./round13-e17-probe-setup")
local q, D, mock, try, track, alive, subs, conns, foreign = H.q, H.D, H.mock, H.try, H.track, H.alive, H.subs, H.conns, H.foreign
local M = D.Mapper
local function P(...) print(...) end

local Remote = { OnClientEvent = mock.newSignal() }
local ToastRemote = { OnClientEvent = mock.newSignal() }
local sent = {}
local NameRemote = { FireServer = function(_, v) table.insert(sent, v) end }

local Profile = q.Store({ Gold = q.Source(0), Level = q.Source(1), Name = q.Source("") })
Remote.OnClientEvent:Connect(function(d)
	if d.Gold ~= nil then Profile.Gold:Set(d.Gold) end
	if d.Level ~= nil then Profile.Level:Set(d.Level) end
end)
local Theme = q.Context.Provider("Theme")
local ctx = q.Context():Set(Theme, { Accent = "gold" })

local log = {}
local function HudTree()
	return foreign({ "Frame", name = "Hud", children = {
		{ "TextLabel", name = "Gold" },
		{ "Frame", name = "Bar" },
		{ "TextBox", name = "NameBox" },
		{ "Frame", name = "Toasts", children = { { "UIListLayout" } } },
	} })
end
local function Hud(context, id)
	local theme = context:Get(Theme)
	local goldText = Profile.Gold:Compute(function(g) return "G " .. g:Get() end)
	local ratio = Profile.Gold:Compute(function(g) return math.clamp(g:Get() / 100, 0, 1) end)
	local animated = ratio:Apply(q.Animate({ Time = 0.5 }))
	local debounced = Profile.Name:Apply(q.Debounce { Time = 0.3 })
	local toasts = q.Source({})
	local list = q.Slot():List(toasts, function(c)
		if c.Item == q.KeyGone then return nil, c.UserData end
		if c.Prev then return c.Prev, c.UserData end
		return D.TextLabel { Text = c.Item }, nil
	end)
	local root = HudTree()
	track("C.root", root); track("C.goldText", goldText); track("C.animated", animated); track("C.list", list)
	q.Claim(root, M.Frame(M.Root)({
		M.TextLabel("Gold")({ Text = goldText, TextColor3 = theme.Accent }),
		M.Frame("Bar")({ BackgroundTransparency = animated }),
		M.TextBox("NameBox")({ Text = Profile.Name, q.Out("Text", Profile.Name) }),
		M.Frame("Toasts")({ list }),
		debounced:Observer(function(t) NameRemote:FireServer(t:Get()) end),
		q.Effect(function()
			local c = ToastRemote.OnClientEvent:Connect(function(msg)
				local nx = table.clone(toasts:Get()); table.insert(nx, msg); toasts:Set(nx)
			end)
			return function() c:Disconnect() end
		end),
		q.OnDestroyed(function() table.insert(log, "D" .. id) end),
	}))
	return root
end

P("== C1 normal ==")
local hud = Hud(ctx, 0)
Remote.OnClientEvent:Fire({ Gold = 50 })
H.run(0.6)
P("gold", hud:FindFirstChild("Gold").Text, "bar", hud:FindFirstChild("Bar").BackgroundTransparency, "color", hud:FindFirstChild("Gold").TextColor3)
ToastRemote.OnClientEvent:Fire("hi")
P("toasts kids", #hud:FindFirstChild("Toasts"):GetChildren())
hud:FindFirstChild("NameBox").Text = "qwe"; H.run(0.4)
P("name → store", Profile.Name:Get(), "sent", table.concat(sent, ","))

local base = { gold = subs(Profile.Gold), name = subs(Profile.Name), toast = conns(ToastRemote.OnClientEvent) }
P("baseline with 1 hud: Gold subs", base.gold, "Name subs", base.name, "toast conns", base.toast)

P("== C2 replace 30x (Destroy old, Claim fresh clone), with remote traffic + tween in flight ==")
for i = 1, 30 do
	Remote.OnClientEvent:Fire({ Gold = i * 3 }) -- starts a tween on the old hud
	H.run(0.1)
	hud:FindFirstChild("NameBox").Text = "n" .. i -- debounce pending on the old hud
	local old = hud
	if i % 2 == 0 then old:Destroy() else q.dispose(old) end
	hud = Hud(ctx, i)
	ToastRemote.OnClientEvent:Fire("t" .. i)
end
old = nil
H.run(2)
P("after 30 replacements: Gold subs", subs(Profile.Gold), "Name subs", subs(Profile.Name), "toast conns", conns(ToastRemote.OnClientEvent), "pending timers", H.pending())
P("alive", alive("C."), "OnDestroyed calls", #log)
P("sent after replacements", #sent, sent[#sent])
P("current hud toasts", #hud:FindFirstChild("Toasts"):GetChildren() - 1, "gold", hud:FindFirstChild("Gold").Text, "bar", hud:FindFirstChild("Bar").BackgroundTransparency)

P("== C3 reentrancy: an Observer inside the HUD replaces the HUD during the Level wave ==")
local current = hud
local replaced = 0
local function HudWithLevelUp(id)
	local root = Hud(ctx, id)
	local obs = Profile.Level:Observer(function(l)
		if l:Get() >= 5 and current == root then
			replaced += 1
			current:Destroy()
			current = HudWithLevelUp(id + 100)
		end
	end)
	q.Backend.bindLifetime(root, obs)
	return root
end
current:Destroy()
current = HudWithLevelUp(500)
local ok = try("Level 5 from remote (observer destroys own host and claims a new one mid-wave)", function()
	Remote.OnClientEvent:Fire({ Level = 5 })
end)
P("replaced", replaced, "current destroyed?", mock.isDestroyed(current))
try("Level 6 afterwards", function() Remote.OnClientEvent:Fire({ Level = 6 }) end)
P("replaced", replaced)
current:Destroy(); current = nil; hud = nil
H.run(2)
P("final (no hud): Gold subs", subs(Profile.Gold), "Level subs", subs(Profile.Level), "Name subs", subs(Profile.Name), "toast conns", conns(ToastRemote.OnClientEvent), "alive", alive("C."))
