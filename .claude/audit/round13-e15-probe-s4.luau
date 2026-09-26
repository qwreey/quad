--!nocheck
-- round13 E15 S4 — GS 14~18 CounterBoard: Slot:List(Detach) + Context(Theme) + Store(Settings) + Animate TextColor3 +
-- lifecycle hooks + Blocker(GS 18 unit switch). Teardown with detached (held) rows.
local H = require("./round13-e15-probe-setup")
local q, D, mock, try, track, alive = H.q, H.D, H.mock, H.try, H.track, H.alive
local ThemeP, SettingsP = q.Context.Provider("Theme"), q.Context.Provider("Settings")
local log = {}
local function L(s) table.insert(log, s) end
local function flush(label) print(label, table.concat(log, " | ")); table.clear(log) end

local function Counter(props)
	local theme = props.Ctx:Get(ThemeP)
	local settings = props.Ctx:Get(SettingsP)
	local count = q.Source(props.Start or 0)
	local unit = q.Source("pt")
	local blocker = q.Blocker()
	local countText = count:Compute(function(c, _p, u) return `{c:Get()} {u:Get()}` end, unit):Apply(blocker)
	local numberColor = count:Compute(function(c) return if c:Get() % 2 == 0 then "blue" else "white" end)
	local card = D.Frame {
		Name = props.Label,
		q.OnCreated(function() L("C:" .. props.Label) end),
		q.OnDestroyed(function() L("D:" .. props.Label) end),
		q.Effect(function() return function(dying) L("cleanup:" .. props.Label .. ":" .. tostring(dying)) end end),
		D.TextLabel { Name = "Num", Text = countText, TextColor3 = numberColor:Apply(q.Animate { Time = 0.3 }) },
		D.TextButton { Name = "Plus", BackgroundColor3 = theme.Accent, Text = "+1",
			Activated = function()
				count:Set(count:Get() + settings.Step:Get())
				if props.OnPlus then props.OnPlus(props.Label) end
			end },
		D.TextButton { Name = "Unit", Text = "unit", Activated = function()
			blocker:On()
			local toPoint = unit:Get() == "pt"
			count:Set(if toPoint then count:Get() * 10 else count:Get() // 10)
			unit:Set(if toPoint then "P" else "pt")
			blocker:Off()
		end },
	}
	track("S4.card", card)
	return card, blocker, countText
end

local function CounterBoard(props)
	local list = q.Slot()
	list:List(props.Rows, function(ctx)
		if ctx.Item == q.KeyGone then return (if props.Detach then q.Detach else nil), ctx.UserData end
		if ctx.Prev then return ctx.Prev, ctx.UserData end
		return Counter { Label = ctx.Item.Label, Start = ctx.Item.Start, Ctx = props.Ctx, OnPlus = props.OnPlus }, ctx.UserData
	end, function(item) return item.Id end)
	track("S4.list", list)
	return D.Frame { Name = "Board", list }, list
end

local settings = q.Store({ Step = q.Source(1) })
local ctx = q.Context():Set(ThemeP, { Accent = "sky" }):Set(SettingsP, settings)

print("== S4a normal ==")
local rows = q.Source({ { Id = "a", Label = "L", Start = 0 }, { Id = "b", Label = "R", Start = 10 } })
local board = CounterBoard { Rows = rows, Ctx = ctx, Detach = true }
flush("mount log")
local a = board:FindFirstChild("L")
a:FindFirstChild("Plus").Activated:Fire()
print("L num", a:FindFirstChild("Num").Text, "tweens", #H.tweenLog)
settings.Step:Set(5); a:FindFirstChild("Plus").Activated:Fire(); print("L num after step 5", a:FindFirstChild("Num").Text)
a:FindFirstChild("Unit").Activated:Fire(); print("after unit switch", a:FindFirstChild("Num").Text)

print("== S4c re-entrancy: +1 handler removes its own row (Detach) mid-handler; click the detached row; reattach ==")
local function removeRow(label)
	local nxt = {}
	for _, r in rows:Get() do if r.Label ~= label then table.insert(nxt, r) end end
	rows:Set(nxt)
end
local board2 = CounterBoard { Rows = rows, Ctx = ctx, Detach = true, OnPlus = removeRow }
flush("board2 mount")
local r2 = board2:FindFirstChild("R")
-- NOTE: rows is shared between board and board2 — both lists react
try("click R.Plus (removes R from shared rows inside handler)", function() r2:FindFirstChild("Plus").Activated:Fire() end)
print("R parent", r2.Parent, "destroyed", mock.isDestroyed(r2), "board kids", #board:GetChildren(), "board2 kids", #board2:GetChildren())
flush("log")
try("click detached R.Plus again", function() r2:FindFirstChild("Plus").Activated:Fire() end)
print("detached R num", r2:FindFirstChild("Num").Text)
rows:Set({ { Id = "a", Label = "L", Start = 0 }, { Id = "b", Label = "R", Start = 10 } })
print("after reattach board2 R is same inst", board2:FindFirstChild("R") == r2, "num", r2:FindFirstChild("Num").Text)
flush("log")

print("== S4d Blocker window: board-level blocker over rows:Set + settings change + per-card unit switch + tween snap ==")
do
	local bb = q.Blocker()
	local gatedRows = rows:Apply(bb)
	local b3 = CounterBoard { Rows = gatedRows, Ctx = ctx, Detach = false }
	flush("b3 mount")
	local L3 = b3:FindFirstChild("L")
	bb:On()
	rows:Set({ { Id = "a", Label = "L", Start = 0 } }) -- R leaves (destroy) — held
	L3:FindFirstChild("Unit").Activated:Fire() -- inner blocker window nested in outer (different blockers)
	settings.Step:Set(2)
	L3:FindFirstChild("Plus").Activated:Fire()
	print("inside: b3 kids", #b3:GetChildren(), "L3 num", L3:FindFirstChild("Num").Text)
	bb:Off()
	print("after Off: b3 kids", #b3:GetChildren(), "L3 num", L3:FindFirstChild("Num").Text)
	flush("log")
	b3:Destroy(); flush("b3 destroy")
end

print("== S4b teardown: board2 holds detached rows; destroy board2 -> detached rows destroyed? cleanup once? ==")
rows:Set({ { Id = "a", Label = "L", Start = 0 } }) -- R detached again in board, destroyed... (board Detach=true too)
flush("detach R in both boards")
local detachedR = r2
board2:Destroy()
flush("board2 destroy")
print("detached R destroyed after host destroy?", mock.isDestroyed(detachedR))
board:Destroy()
flush("board destroy")
ctx:Set(ThemeP, { Accent = "red" }) -- provider replaced after everything is dead
try("settings write after all destroyed", function() settings.Step:Set(3) end)
a, r2, detachedR, board, board2 = nil, nil, nil, nil, nil
H.mock.resetTweenLog()
print("alive", alive("S4."))
