--!nocheck
-- E27 chain C — GS 12~18: Counter.luau / CounterBoard.luau / Theme / Settings 모듈을 장별 모양 그대로 지역 함수로 옮기고
-- Main.client 쪽 코드를 장 순서대로 실행한다. `…생략…` 자리는 직전 장 모양으로 채웠다.
local H = require("./harness")
local C = require("./check")
local check, expectErr = C.check, C.expectErr
local q, D = H.q, H.D
local mock = H.mock
UDim2 = H.EG.UDim2; Color3 = H.EG.Color3; Enum = H.EG.Enum; Vector2 = H.EG.Vector2; UDim = H.EG.UDim
local screen = D.ScreenGui { ResetOnSpawn = false }
local function click(b) b.Activated:Fire() end
local function find(inst, cls, pred) for _, c in inst:GetChildren() do if c.ClassName == cls and (pred == nil or pred(c)) then return c end end end
local function labelOf(card) return find(card, "TextLabel") end
local function plusOf(card) return find(card, "TextButton", function(b) return b.Text == "+ 1" or b.Text == "✨" end) end
local function btnText(card, t) return find(card, "TextButton", function(b) return b.Text == t end) end

------------------------------------------------------------------ 12 §1 Counter.luau (12#1 == 12#3 "지금까지의 코드")
local function Counter12(props)
	const count = q.Source(props.Start or 0)
	const countText = count:Compute(function(c) return `{props.Label}: {c:Get()}` end)
	return D.Frame { Size = UDim2.fromOffset(200, 120), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 0, 48), BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = countText },
		D.TextButton { Size = UDim2.new(1, -24, 0, 40), Position = UDim2.new(0, 12, 1, -52), BackgroundColor3 = Color3.fromRGB(0, 162, 255),
			TextColor3 = Color3.fromRGB(255, 255, 255), Text = "+ 1", UICorner = 8,
			Activated = function() count:Set(count:Get() + 1) end } }
end
do -- 12#2 / 12#4
	const Counter = Counter12
	const row = D.Frame { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(420, 120),
		BackgroundTransparency = 1,
		D.UIListLayout { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) },
		Counter { Label = "왼쪽", Start = 0 }, Counter { Label = "오른쪽", Start = 10 } }
	row.Parent = screen
	local cs = {} for _, c in row:GetChildren() do if c.ClassName == "Frame" then table.insert(cs, c) end end
	click(plusOf(cs[1]))
	check("12#2 두 카운터 독립", labelOf(cs[1]).Text == "왼쪽: 1" and labelOf(cs[2]).Text == "오른쪽: 10", labelOf(cs[1]).Text .. " / " .. labelOf(cs[2]).Text)
	row:Destroy()
end
do -- 12#5 Checkbox + 12#6 caller + 12#7
	local function Checkbox(props)
		const checked = props.Value
		const labelText = checked:Compute(function(c) return `{if c:Get() then "☑" else "☐"} {props.Label}` end)
		return D.TextButton { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(255, 255, 255), Text = labelText, Activated = function() checked:Set(not checked:Get()) end }
	end
	const agreed = q.Source(false)
	const statusText = agreed:Compute(function(c) return if c:Get() then "켜짐" else "꺼짐" end)
	const panel = D.Frame { Size = UDim2.fromOffset(260, 80), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.UIListLayout { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 4) },
		Checkbox { Label = "약관에 동의합니다", Value = agreed },
		D.TextLabel { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(180, 180, 190), Text = statusText } }
	panel.Parent = screen
	const cb = find(panel, "TextButton"); const st = find(panel, "TextLabel")
	local b0 = cb.Text .. "/" .. st.Text
	click(cb)
	check("12#6 ☐/꺼짐 → ☑/켜짐", b0 == "☐ 약관에 동의합니다/꺼짐" and cb.Text == "☑ 약관에 동의합니다" and st.Text == "켜짐", b0 .. " → " .. cb.Text .. "/" .. st.Text)
	expectErr("12#7 readOnly:Set 에러", function()
		const readOnly = agreed:Compute(function(c) return c:Get() end)
		readOnly:Set(true)
	end, "attempt to call missing method 'Set' of table")
	panel:Destroy()
end
do -- 12#8/#9 Children + 12#10 or q.None + 12 conditional child
	local function Counter12c(props)
		const count = q.Source(props.Start or 0)
		const countText = count:Compute(function(c) return `{props.Label}: {c:Get()}` end)
		return D.Frame { Size = UDim2.fromOffset(200, 120), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
			D.TextLabel { Text = countText },
			D.TextButton { Text = "+ 1", UICorner = 8, Activated = function() count:Set(count:Get() + 1) end },
			props.Children or q.None }
	end
	const Counter = Counter12c
	const row = D.Frame { BackgroundTransparency = 1,
		D.UIListLayout { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) },
		Counter { Label = "왼쪽", Start = 0 },
		Counter { Label = "오른쪽", Start = 10, Children = q.Slot { D.TextLabel { Text = "덤으로 붙는 자식", TextSize = 12 } } } }
	local cs = {} for _, c in row:GetChildren() do if c.ClassName == "Frame" then table.insert(cs, c) end end
	check("12#9 오른쪽에만 덤 자식", #cs[1]:GetChildren() == 3 and #cs[2]:GetChildren() == 4, `{#cs[1]:GetChildren()} {#cs[2]:GetChildren()}`)
	expectErr("12 §3 and-false 자식 → Quad0076 key 1 boolean", function()
		local showBadge = false
		D.Frame { (showBadge and D.TextLabel { Text = "b" }) }
	end, "Quad0076 Dispatch: no handler matched key 1 (value: boolean)")
	row:Destroy()
end

------------------------------------------------------------------ 13
local function highlightColor(state, threshold)
	return state:Compute(function(c) return if c:Get() >= threshold then Color3.fromRGB(255, 190, 0) else Color3.fromRGB(0, 162, 255) end)
end
local function Counter13(props)
	const count = q.Source(props.Start or 0)
	const countText = count:Compute(function(c) return `{props.Label}: {c:Get()}` end)
	return D.Frame { Size = UDim2.fromOffset(200, 120), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 0, 48), BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = countText },
		D.TextButton { Size = UDim2.new(1, -24, 0, 40), Position = UDim2.new(0, 12, 1, -52), TextColor3 = Color3.fromRGB(255, 255, 255), UICorner = 8,
			BackgroundColor3 = highlightColor(count, 10), Text = "+ 1",
			Activated = function() count:Set(count:Get() + 1) end },
		props.Children or q.None,
		if props.Watch then props.Watch(count) else q.None }
end
do -- 13#2/#3/#4/#5
	local P, log = H.capture()
	const Counter = Counter13
	const left = Counter { Label = "왼쪽", Start = 0,
		Watch = function(count) return q.Effect(function() P("왼쪽 카운터:", count:Get()); return function() P("왼쪽 카운터 정리") end end, count) end }
	const right = Counter { Label = "오른쪽", Start = 10 }
	check("13#3 오른쪽(10) 버튼 노랑", plusOf(right).BackgroundColor3 == Color3.fromRGB(255, 190, 0))
	check("13#3 왼쪽(0) 버튼 파랑", plusOf(left).BackgroundColor3 == Color3.fromRGB(0, 162, 255))
	click(plusOf(left)); left:Destroy()
	check("13#5 Watch 로그", table.concat(log, "|") == "왼쪽 카운터:\t0|왼쪽 카운터 정리|왼쪽 카운터:\t1|왼쪽 카운터 정리", table.concat(log, "|"))
	check("13#5 Watch 없는 카운터 자식 수(UICorner·라벨·버튼)", #right:GetChildren() == 3, #right:GetChildren())
	right:Destroy()
end
do -- 13#1 콜백 셋 (조각)
	const count = q.Source(0)
	count:Compute(function(c) return `카운트: {c:Get()}` end)
	count:Observer(function(t) print(t:Get()) end)
	D.TextButton { Activated = function() count:Set(1) end }
	check("13#1 세 콜백 조각 실행", true)
end
do -- 13#6 Sum + 13#9 Operator + 13#11 Doubled
	local function Sum(n) return function(c) return c:Get() + n end end
	const count = q.Source(0)
	const plusTen = count:Compute(Sum(10))
	check("13#6 plusTen 10", plusTen:Get() == 10)
	count:Set(1)
	check("13#6 plusTen 11", plusTen:Get() == 11)
	const plusTenOp = count:Apply(q.Operator.Sum(10))
	check("13#8 Operator.Sum(10) 같은 결과", plusTenOp:Get() == 11, plusTenOp:Get())
	const Doubled = { __apply = function(self, state) return state:Compute(function(c) return c:Get() * 2 end) end }
	const twice = count:Apply(Doubled)
	check("13#10 Doubled 2", twice:Get() == 2)
	expectErr("13 Quad0191", function() count:Apply({}) end, "Quad0191 State: Apply factory must be a function or an object with an __apply method")
	local nOps = 0; for k, v in q.Operator do if type(v) == "function" then nOps += 1 end end
	check("13 §4 Operator 이름 붙은 것 열넷", nOps == 14, nOps)
end
do -- 13#7 logWith
	local P, log = H.capture()
	const count = q.Source(0)
	local function logWith(prefix) return function(t) P(prefix, t:Get()) end end
	const label = D.TextLabel { Text = "…", count:Observer(logWith("카운트:")) }
	count:Set(1)
	check("13#7 카운트: 0 / 1", table.concat(log, "|") == "카운트:\t0|카운트:\t1", table.concat(log, "|"))
end
do -- 13#12 Verbose
	local P, log = H.capture()
	const count = q.Source(3)
	local function mk(props)
		const extra = if props.Verbose then q.Effect(function() P(count:Get()) end, count) else q.None
		return D.Frame { extra }
	end
	mk({ Verbose = true }); mk({ Verbose = false })
	check("13#12 Verbose만 Effect", #log == 1)
end

------------------------------------------------------------------ 14
local function makeCounterBoard(Counter, passCtx)
	return function(props)
		const list = q.Slot()
		list:List(props.Rows, function(ctx)
			if ctx.Item == q.KeyGone then return nil, ctx.UserData end
			if ctx.Prev then return ctx.Prev, ctx.UserData end
			if passCtx then
				return Counter { Label = ctx.Item.Label, Start = ctx.Item.Start, Ctx = props.Ctx }, ctx.UserData
			end
			return Counter { Label = ctx.Item.Label, Start = ctx.Item.Start }, ctx.UserData
		end, function(item) return item.Id end)
		return D.Frame { Size = UDim2.fromOffset(640, 140), BackgroundTransparency = 1,
			D.UIListLayout { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12) },
			list,
			-- 14#4 (§3) add button
			D.TextButton { Size = UDim2.fromOffset(120, 40), Text = "+ 카운터",
				Activated = function()
					const nextRows = table.clone(props.Rows:Get())
					table.insert(nextRows, { Id = `c{#nextRows}`, Label = "새 카운터", Start = 0 })
					props.Rows:Set(nextRows)
				end } }
	end
end
local function counters(board) local t = {} for _, c in board:GetChildren() do if c.ClassName == "Frame" then table.insert(t, c) end end return t end
do
	const rows = q.Source({ { Id = "a", Label = "왼쪽", Start = 0 }, { Id = "b", Label = "오른쪽", Start = 10 } })
	const CounterBoard = makeCounterBoard(Counter13, false)
	const board = CounterBoard { Rows = rows }
	board.Parent = screen
	local cs = counters(board)
	check("14#3 카운터 둘", #cs == 2 and labelOf(cs[1]).Text == "왼쪽: 0" and labelOf(cs[2]).Text == "오른쪽: 10")
	click(plusOf(cs[1]))
	const addBtn = btnText(board, "+ 카운터")
	click(addBtn)
	local cs2 = counters(board)
	check("14#4 추가 뒤 3개, a·b 재사용·카운트 유지", #cs2 == 3 and cs2[1] == cs[1] and labelOf(cs[1]).Text == "왼쪽: 1", `{#cs2}`)
	check("14#4 자식 3 → 4 (카운터 둘+버튼 → 셋+버튼)", #board:GetChildren() == 5, #board:GetChildren()) -- UIListLayout 포함 실제 개수
	-- dup key: 지우기 시작하면 c2 재생성
	click(addBtn) -- c3
	rows:Set({ rows:Get()[1], rows:Get()[2], rows:Get()[4] }) -- c2 지움 → 길이 3
	expectErr("14 §3 dup key c2가 아니라 실제 문구", function() click(addBtn) end, "Quad0145 Slot:List: duplicate key c3")
	board:Destroy()
end
do -- 14#5 Detach 조각
	const rows = q.Source({ { Id = "a" }, { Id = "b" } })
	const list = q.Slot()
	list:List(rows, function(ctx)
		if ctx.Item == q.KeyGone then return q.Detach, ctx.UserData end
		if ctx.Prev then return ctx.Prev, ctx.UserData end
		return D.TextLabel { Text = ctx.Item.Id }, ctx.UserData
	end, function(item) return item.Id end)
	const f = D.Frame { list }
	const b = f:GetChildren()[2]
	rows:Set({ { Id = "a" } }); local mid = #f:GetChildren()
	rows:Set({ { Id = "a" }, { Id = "b" } })
	check("14#5 Detach 뒤 같은 원소 재마운트", mid == 1 and f:GetChildren()[2] == b and not mock.isDestroyed(b))
end
do -- 14#6 + 14#7 logRows
	const logRows = q.Source({ { Id = "a", Label = "왼쪽" }, { Id = "b", Label = "오른쪽" } })
	const list = q.Slot()
	list:List(logRows, function(ctx)
		if ctx.Item == q.KeyGone then return nil, ctx.UserData end
		if ctx.Prev then ctx.UserData:Set(ctx.Item.Label); return ctx.Prev, ctx.UserData end
		const label = q.Source(ctx.Item.Label)
		return D.TextLabel { Text = label }, label
	end, function(item) return item.Id end)
	const box = D.Frame { BackgroundTransparency = 1, list }
	const first = box:GetChildren()[1]
	logRows:Set({ { Id = "a", Label = "왼쪽(수정)" }, { Id = "b", Label = "오른쪽" }, { Id = "c", Label = "새로" } })
	check("14#7 3 / 왼쪽(수정) / 같은 인스턴스", #box:GetChildren() == 3 and box:GetChildren()[1].Text == "왼쪽(수정)" and box:GetChildren()[1] == first)
end
do -- 14#8 :Single
	const cur = q.Source<<string?>>(nil)
	const single = q.Slot<<Instance>>():Single(cur, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		return D.TextLabel { Text = ctx.Item, LayoutOrder = ctx.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 1 end) }
	end)
	const top = q.Slot { D.TextLabel { Text = "T1" }, D.TextLabel { Text = "T2" } }
	const panel = D.Frame { D.TextLabel { Text = "머리" }, top, single }
	cur:Set("지금 화면")
	local a = single:Get(1).LayoutOrder
	top:Add(D.TextLabel { Text = "T3" }); local b = single:Get(1).LayoutOrder
	top:Remove(1); local c = single:Get(1).LayoutOrder
	check("14#8 LayoutOrder 4 5 4", a == 4 and b == 5 and c == 4, `{a} {b} {c}`)
end

------------------------------------------------------------------ 15
local ThemeProvider = q.Context.Provider("Theme")
local function Counter15(props)
	const theme = props.Ctx:Get(ThemeProvider)
	const count = q.Source(props.Start or 0)
	const countText = count:Compute(function(c) return `{props.Label}: {c:Get()}` end)
	return D.Frame { Size = UDim2.fromOffset(200, 120), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = countText },
		D.TextButton { TextColor3 = Color3.fromRGB(255, 255, 255), UICorner = 8, BackgroundColor3 = theme.Accent, Text = "+ 1",
			Activated = function() count:Set(count:Get() + 1) end },
		props.Children or q.None,
		if props.Watch then props.Watch(count) else q.None }
end
do
	const rows = q.Source({ { Id = "a", Label = "왼쪽", Start = 0 }, { Id = "b", Label = "오른쪽", Start = 10 } })
	const ctx = q.Context():Set(ThemeProvider, { Accent = Color3.fromRGB(0, 162, 255) })
	const board = makeCounterBoard(Counter15, true) { Rows = rows, Ctx = ctx }
	local cs = counters(board)
	check("15#3 가방 색", plusOf(cs[1]).BackgroundColor3 == Color3.fromRGB(0, 162, 255) and plusOf(cs[2]).BackgroundColor3 == Color3.fromRGB(0, 162, 255))
	expectErr("15 §3 Ctx 없으면 Lua 에러", function() Counter15 { Label = "x" } end, "attempt to index nil with 'Get'")
	expectErr("15 §4 Quad0038", function() q.Context():Get(q.Context.Provider("Locale")) end,
		"Quad0038 Context:Get: no value for Provider(Locale) — the creator of this Context did not :Set it (use :Peek to test)")
	check("15 §4 Peek nil", q.Context():Peek(q.Context.Provider("Locale")) == nil)
	check("15 §4 같은 이름 둘은 다른 키", q.Context.Provider("T") ~= q.Context.Provider("T"))
end

------------------------------------------------------------------ 16
local SettingsProvider = q.Context.Provider("Settings")
local function Counter16(props)
	const theme = props.Ctx:Get(ThemeProvider)
	const settings = props.Ctx:Get(SettingsProvider)
	const count = q.Source(props.Start or 0)
	const countText = count:Compute(function(c) return `{props.Label}: {c:Get()}` end)
	return D.Frame { Size = UDim2.fromOffset(200, 120), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = countText },
		D.TextButton { TextColor3 = Color3.fromRGB(255, 255, 255), UICorner = 8, BackgroundColor3 = theme.Accent, Text = "+ 1",
			Activated = function() count:Set(count:Get() + settings.Step:Get()) end },
		props.Children or q.None,
		if props.Watch then props.Watch(count) else q.None }
end
do
	local P, log = H.capture()
	const settings = q.Store({ Step = q.Source(1) })
	P(settings.Step:Get())
	check("16#2 Step 1", log[1] == "1")
	settings.Step:Set(1) -- 문서 16#2의 Set(5)는 확인용으로 보고, 아래 버튼 서술(보폭: 1 시작)에 맞춰 1로 둔다
	const rows = q.Source({ { Id = "a", Label = "왼쪽", Start = 0 }, { Id = "b", Label = "오른쪽", Start = 10 } })
	const ctx = q.Context():Set(ThemeProvider, { Accent = Color3.fromRGB(0, 162, 255) }):Set(SettingsProvider, settings)
	const board = makeCounterBoard(Counter16, true) { Rows = rows, Ctx = ctx }
	const stepButton = D.TextButton { Size = UDim2.fromOffset(120, 32),
		Text = settings.Step:Compute(function(s: q.StateData<number>) return `보폭: {s:Get()}` end),
		Activated = function() settings.Step:Set(settings.Step:Get() % 5 + 1) end }
	local seq = { stepButton.Text }
	for _ = 1, 5 do click(stepButton); table.insert(seq, stepButton.Text) end
	check("16#7 보폭 1→2→…→5→1", table.concat(seq, ",") == "보폭: 1,보폭: 2,보폭: 3,보폭: 4,보폭: 5,보폭: 1", table.concat(seq, ","))
	click(stepButton); click(stepButton) -- 3
	local cs = counters(board)
	click(plusOf(cs[1]))
	check("16#7 보폭 3 → 왼쪽 3", labelOf(cs[1]).Text == "왼쪽: 3", labelOf(cs[1]).Text)
	check("16 퀴즈 선언 안 한 키 nil", settings.Label == nil)
	const x = settings:Of("Dyn"); check("16 :Of 같은 객체", settings:Of("Dyn") == x and x:Get() == nil)
	expectErr("16 예약 이름 Of", function() q.Store({ Of = q.Source(1) }) end, "Quad")
end

------------------------------------------------------------------ 17
local function tweenLog() return mock.tweenLog end
do -- 17#1 Tween in Counter (Counter16 + TextColor3 pipe), 17#2 Started/Completed/Cancelled
	local function Counter17a(props)
		const settings = props.Ctx:Get(SettingsProvider)
		const count = q.Source(props.Start or 0)
		const countText = count:Compute(function(c) return `{props.Label}: {c:Get()}` end)
		const flash = q.Source(false)
		return D.Frame { UICorner = 12,
			D.TextLabel { Text = countText, TextScaled = true,
				TextColor3 = count:Compute(function(c: q.StateData<number>)
					const n = c:Get()
					const isMilestone = n > 0 and n % 10 == 0
					return q.Tween { Value = if isMilestone then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 255, 255),
						Time = if isMilestone then 0.6 else 0.2,
						Started = if isMilestone then function() flash:Set(true) end else nil,
						Completed = if isMilestone then function() flash:Set(false) end else nil,
						Cancelled = if isMilestone then function() flash:Set(false) end else nil }
				end) },
			D.TextButton { UICorner = 8, Text = flash:Compute(function(f: q.StateData<boolean>) return if f:Get() then "✨" else "+ 1" end),
				Activated = function() count:Set(count:Get() + settings.Step:Get()) end } }
	end
	const settings = q.Store({ Step = q.Source(1) })
	const ctx = q.Context():Set(ThemeProvider, { Accent = Color3.fromRGB(0, 162, 255) }):Set(SettingsProvider, settings)
	mock.resetTweenLog()
	const card = Counter17a { Label = "왼쪽", Start = 0, Ctx = ctx }
	const btn = plusOf(card)
	for _ = 1, 9 do click(btn) end
	check("17#1 1~9회 엔진 트윈 0", #tweenLog() == 0, #tweenLog())
	click(btn)
	check("17#1 10회째 트윈 하나(0.6)", #tweenLog() == 1, #tweenLog())
	check("17#2 10회째 ✨", btn.Text == "✨", btn.Text)
	tweenLog()[1].tween:simulateCompleted()
	check("17#2 완료 뒤 + 1", btn.Text == "+ 1", btn.Text)
	for _ = 1, 10 do click(btn) end -- 20
	check("17#2 20회 ✨", btn.Text == "✨")
	click(btn) -- 21: cancel gold
	check("17#2 도중 클릭 → Cancelled → + 1", btn.Text == "+ 1", btn.Text)
	-- Start=10 counter: first set milestone → Started+Completed immediately
	const card10 = Counter17a { Label = "b", Start = 10, Ctx = ctx }
	check("17 §1 첫 세팅 Started→Completed 즉시(✨ 안 남음)", plusOf(card10).Text == "+ 1", plusOf(card10).Text)
end
do -- 17#3/#4 Animate
	const count = q.Source(0)
	const numberColor = count:Compute(function(c) return if c:Get() % 2 == 0 then Color3.fromRGB(0, 200, 255) else Color3.fromRGB(255, 255, 255) end)
	mock.resetTweenLog()
	const lbl = D.TextLabel { TextColor3 = numberColor:Apply(q.Animate { Time = 0.3, Style = Enum.EasingStyle.Quad }) }
	check("17#4 첫 표시 트윈 없음·하늘색", #tweenLog() == 0 and lbl.TextColor3 == Color3.fromRGB(0, 200, 255))
	count:Set(1)
	check("17#4 변경 시 트윈 하나", #tweenLog() == 1)
end

------------------------------------------------------------------ 18
do -- 18 문서 지시 그대로 Counter를 되돌린 모양(§1~§3). "props.Ctx를 읽던 줄과 Theme require는 지웁니다" 를
   -- theme·settings 두 줄 모두로 읽은 경우: 16장의 Activated(settings.Step)가 남아 전역 nil 참조가 된다.
	local function Counter18_literal(props)
		const count = q.Source(10)
		const unit = q.Source("점")
		const blocker = q.Blocker()
		const countText = count:Compute(function(c, prev, u) return `{c:Get()} {u:Get()}` end, unit):Apply(blocker)
		return D.Frame { UICorner = 12, D.TextLabel { Text = countText },
			D.TextButton { BackgroundColor3 = Color3.fromRGB(0, 162, 255), Text = "+ 1",
				Activated = function() count:Set(count:Get() + settings.Step:Get()) end } } -- `settings`: 16장이 넣은 이름, 18장이 지우라는 줄에서 정의되던 것
	end
	const card = Counter18_literal {}
	local ok, err = pcall(click, plusOf(card))
	check("18 (c) 문서 지시를 문자 그대로 따르면 + 1 클릭이 전역 nil 참조로 던짐", not ok, tostring(err):gsub("\n.*", ""))
end
local runs = 0
local function Counter18(props, withBlocker)
	const count = q.Source(10)
	const unit = q.Source("점")
	const blocker = q.Blocker()
	local countText = count:Compute(function(c, prev, u) runs += 1; return `{c:Get()} {u:Get()}` end, unit)
	if withBlocker then countText = countText:Apply(blocker) end
	return D.Frame { UICorner = 12, D.TextLabel { Text = countText },
		D.TextButton { BackgroundColor3 = Color3.fromRGB(0, 162, 255), Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end },
		D.TextButton { Text = "단위 바꾸기", Activated = function()
			if withBlocker then blocker:On() end
			const toPoint = unit:Get() == "점"
			count:Set(if toPoint then count:Get() * 10 else count:Get() // 10)
			unit:Set(if toPoint then "포인트" else "점")
			if withBlocker then blocker:Off() end
		end },
		D.TextButton { Text = "일시정지", Activated = function() if blocker.Blocking then blocker:Off() else blocker:On() end end },
	}, countText, count, unit
end
do -- 18#1~#3 (no gate)
	runs = 0
	local card, countText, count, unit = Counter18({}, false)
	const lbl = labelOf(card)
	local seq = { lbl.Text }
	local sw = btnText(card, "단위 바꾸기")
	-- 끊어 보기: 버튼 본문을 한 줄씩
	count:Set(count:Get() * 10); table.insert(seq, lbl.Text); unit:Set("포인트"); table.insert(seq, lbl.Text)
	check("18#3 10 점 → 100 점 → 100 포인트", table.concat(seq, ",") == "10 점,100 점,100 포인트", table.concat(seq, ","))
	check("18 §1 파이프 3회", runs == 3, runs)
end
do -- 18#4/#6 gate
	runs = 0
	local card, countText = Counter18({}, true)
	const lbl = labelOf(card)
	local seen = {}
	-- 중간 상태 관측: Property 쓰기를 가로채지 않고 버튼 뒤 결과만 본다
	click(btnText(card, "단위 바꾸기"))
	check("18#6 곧장 100 포인트", lbl.Text == "100 포인트", lbl.Text)
	check("18#6 파이프 2회", runs == 2, runs)
	click(btnText(card, "단위 바꾸기")) -- 되돌림 10 점
	-- §3 pause
	click(btnText(card, "일시정지"))
	for _ = 1, 3 do click(plusOf(card)) end
	check("18#7 일시정지 중 라벨 10 점", lbl.Text == "10 점", lbl.Text)
	check("18#8 countText:Get() 13 점", countText:Get() == "13 점", countText:Get())
	click(btnText(card, "일시정지"))
	check("18#7 다시 누르면 13 점", lbl.Text == "13 점", lbl.Text)
	-- blocker Blocking double On
	const b = q.Blocker(); b:On(); b:On(); b:Off()
	check("18 §4 Blocking 불리언", b.Blocking == false)
end

C.summary("chain-c")
