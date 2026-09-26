--!nocheck
-- E56 (4a): 주석 전(bare/mod)·후(annotated/mod) 컴포넌트 모듈을 같은 mock 하네스에서 같은 조작으로 돌려 관측 로그를 비교한다.
-- 사용: luau mock-modules.luau -a bare   /   luau mock-modules.luau -a annotated
local H = require("./harness")
local q, D = H.q, H.D
local EG = H.EG
local which = (...) or "annotated"
UDim2 = EG.UDim2; Color3 = EG.Color3; Enum = EG.Enum; Vector2 = EG.Vector2; UDim = EG.UDim
local log = {}
local function L(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end table.insert(log, table.concat(t, " ")) end
local function patch(mod)
	-- 모듈 env에 엔진 전역 셰임(harness 러너가 자기 env에 하던 것과 같은 값)
	local fn = if type(mod) == "function" then mod else nil
	if fn then
		local env = getfenv(fn)
		env.UDim2 = EG.UDim2; env.Color3 = EG.Color3; env.Enum = EG.Enum; env.Vector2 = EG.Vector2; env.UDim = EG.UDim
		env.game = H.game; env.task = H.task
	end
	return mod
end
local base = "./" .. which .. "/mod/"
local function req(name) return patch(require(base .. name)) end
-- 모듈이 서로 require하는 것도 같은 env 셰임이 필요 — 먼저 전부 불러 둔다
local Counter12 = req("Counter12"); local Counter13 = req("Counter13"); local Counter16 = req("Counter16")
local Counter17b = req("Counter17b"); local Counter18 = req("Counter18"); local Checkbox = req("Checkbox")
local CounterBoard = req("CounterBoard"); local Theme = req("Theme"); local Settings = req("Settings")
local function kids(inst, cls) local r = {} for _, c in inst:GetChildren() do if cls == nil or c.ClassName == cls then table.insert(r, c) end end return r end
local function desc(inst, acc) acc = acc or {} for _, c in inst:GetChildren() do table.insert(acc, c); desc(c, acc) end return acc end
local function btn(inst, text) for _, c in desc(inst) do if c.ClassName == "TextButton" and c.Text == text then return c end end end
local function labels(inst) local r = {} for _, c in desc(inst) do if c.ClassName == "TextLabel" then table.insert(r, tostring(c.Text)) end end return table.concat(r, "|") end

-- 12: Counter12
do
	local c = Counter12 { Label = "왼쪽", Start = 0 }
	L("12 mount", labels(c)); btn(c, "+ 1").Activated:Fire(); btn(c, "+ 1").Activated:Fire(); L("12 after2", labels(c))
	local c2 = Counter12 { Label = "오른쪽", Start = 10, Children = q.Slot { D.TextLabel { Text = "덤" } } }
	L("12 children", #c2:GetChildren(), labels(c2))
end
-- 12: Checkbox
do
	local agreed = q.Source(false)
	local cb = Checkbox { Label = "약관", Value = agreed }
	L("cb", cb.Text); cb.Activated:Fire(); L("cb", cb.Text, agreed:Get())
end
-- 13: Counter13 + Watch
do
	local seen = {}
	local c = Counter13 { Label = "L", Start = 8, Watch = function(count) return q.Effect(function() table.insert(seen, count:Get()) end, count) end }
	local b = btn(c, "+ 1")
	L("13 color", tostring(b.BackgroundColor3.R)); b.Activated:Fire(); b.Activated:Fire(); L("13 color", tostring(b.BackgroundColor3.R), labels(c), table.concat(seen, ","))
end
-- 14~16: Board + Ctx
do
	local rows = q.Source({ { Id = "a", Label = "왼쪽", Start = 0 }, { Id = "b", Label = "오른쪽", Start = 10 } })
	local settings = q.Store({ Step = q.Source(1) })
	local ctx = q.Context():Set(Theme.Provider, { Accent = Color3.fromRGB(0, 162, 255) }):Set(Settings.Provider, settings)
	local board = CounterBoard { Rows = rows, Ctx = ctx }
	L("board frames", #kids(board, "Frame"), labels(board))
	settings.Step:Set(3)
	local first = kids(board, "Frame")[1]
	btn(first, "+ 1").Activated:Fire(); L("board step3", labels(board))
	btn(board, "+ 카운터").Activated:Fire(); L("board add", #kids(board, "Frame"), labels(board))
	-- 17: 10의 배수에서 Tween/flash
	for _ = 1, 3 do btn(first, "+ 1").Activated:Fire() end
	L("board 12?", labels(first)); H.runTask(1)
	L("board after tween", labels(first))
end
-- 17b
do
	local c = Counter17b { Label = "x", Start = 0 }
	L("17b", labels(c), #c:GetChildren())
end
-- 18: blocker
do
	local c = Counter18()
	L("18", labels(c)); btn(c, "단위 바꾸기").Activated:Fire(); L("18 unit", labels(c))
	btn(c, "일시정지").Activated:Fire(); btn(c, "단위 바꾸기").Activated:Fire(); L("18 paused", labels(c))
	btn(c, "일시정지").Activated:Fire(); L("18 resumed", labels(c))
end
for _, line in log do print(line) end
