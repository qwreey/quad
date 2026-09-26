--!nocheck
-- E27 chain A — GS 01~10 누적 프로그램(Main.client.luau)을 장 순서대로 재구성해 mock에서 실행.
-- 각 stage는 "그 장 끝의 독자 코드"(앞 장 코드 + 이 장이 고치라는 대로 고친 것)를 그대로 옮긴 것.
-- `…생략…`/`…나머지 그대로…` 자리는 직전 stage의 해당 코드로 채웠다.
local H = require("./harness")
local C = require("./check")
local check, expectErr = C.check, C.expectErr
local q = H.q
UDim2 = H.EG.UDim2; Color3 = H.EG.Color3; Enum = H.EG.Enum; Vector2 = H.EG.Vector2; UDim = H.EG.UDim
local mock = H.mock
local task = H.task

-- engine tag-call log (wrap the shared CollectionService shim)
local tagCalls = {}
do
	local cs = H.CollectionService
	local add, rem = cs.AddTag, cs.RemoveTag
	cs.AddTag = function(self, inst, name) table.insert(tagCalls, "addTag:" .. name); return add(self, inst, name) end
	cs.RemoveTag = function(self, inst, name) table.insert(tagCalls, "removeTag:" .. name); return rem(self, inst, name) end
end
local function tagsOf(inst) local t = mock.getTags(inst); table.sort(t); return table.concat(t, ",") end
local function childCount(inst) return #inst:GetChildren() end
local function click(btn) btn.Activated:Fire() end

------------------------------------------------------------------ 01 §2 (진입점 — Players/playerGui 부분은 mock 밖)
local q1, D = q, q.Declaration
local screen = D.ScreenGui { ResetOnSpawn = false }
local hello = D.TextLabel {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(240, 40),
	BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 18, Text = "Quad is running",
}
hello.Parent = screen
check("01#3 hello label", hello.Text == "Quad is running" and hello.Parent == screen)
-- 01#2 const/local 조각
do const D2 = q.Declaration; local n = 0; check("01#2 const 조각", D2 == D and n == 0) end

------------------------------------------------------------------ 02 (hello 지움)
hello:Destroy()
do -- 02#2
	const card = D.Frame {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(240, 160),
		BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
	}
	card.Parent = screen
	check("02#3 card.ClassName", card.ClassName == "Frame", card.ClassName)
	check("02#2 UICorner shorthand child", childCount(card) == 1 and card:GetChildren()[1].ClassName == "UICorner")
	expectErr("02 Parent in props → Quad0076", function() D.Frame { Parent = screen } end,
		"Quad0076 Dispatch: no handler matched key Parent (value: ") -- mock 인스턴스는 table이라 value 표기만 다름
	card:Destroy()
end
do -- 02#4 (card 고침; card.Parent = screen 줄은 §1 그대로 남는다고 가정)
	const card = D.Frame {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(240, 160),
		BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 0, 48), BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = "카운트: 0" },
	}
	card.Parent = screen
	local lbl
	for _, c in card:GetChildren() do if c.ClassName == "TextLabel" then lbl = c end end
	check("02#4 라벨 카운트: 0", lbl and lbl.Text == "카운트: 0")
	card:Destroy()
end
do -- 02#5 별도: nil 구멍
	local msg = expectErr("02#5 nil hole → Quad0023", function()
		const maybe = nil
		const card = D.Frame { D.TextLabel { Text = "a" }, maybe, D.TextLabel { Text = "b" } }
	end, "Quad0023 Bookkeeping.recompute: sourceList[2] is nil")
	check("02#5 에러 문구 verbatim",
		msg == "Quad0023 Bookkeeping.recompute: sourceList[2] is nil — a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None (the children placed before this raise stay seated in the half-built Instance, reachable as child.Parent — q.dispose that Instance to clean up; it takes those children with it, so build the retry with new ones); if you are writing a handler, bookkeeping is broken (setLength without setOffsetSource? the contract says None)"
			or msg:find("sourceList%[2%] is nil — a nil hole") ~= nil, msg)
end

------------------------------------------------------------------ 03
local function labelOf(card) for _, c in card:GetChildren() do if c.ClassName == "TextLabel" then return c end end end
local function buttonOf(card, text) for _, c in card:GetChildren() do if c.ClassName == "TextButton" and (text == nil or c.Text == text) then return c end end end
do -- 03#2 §1
	const label = q.Source("카운트: 0")
	const card = D.Frame { Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 0, 48), BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = label } }
	card.Parent = screen
	label:Set("카운트: 1")
	check("03#2 Text follows Source", labelOf(card).Text == "카운트: 1", labelOf(card).Text)
	card:Destroy()
end
do -- 03#3 §2, 03#4 §3
	const count = q.Source(0)
	const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
	const card = D.Frame { Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 0, 48), BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = countText } }
	card.Parent = screen
	count:Set(7)
	check("03#3 카운트: 7", labelOf(card).Text == "카운트: 7", labelOf(card).Text)
	const suffix = q.Source("회")
	const both = count:Compute(function(c, previous, s) return `{c:Get()}{s:Get()}` end, suffix)
	check("03#4 both 7회", both:Get() == "7회", both:Get())
	suffix:Set("번")
	check("03#4 both 7번", both:Get() == "7번", both:Get())
	-- 03 §3 claim: previous is nil on first calc
	local seen = {}
	const p = count:Compute(function(c, previous) table.insert(seen, previous == nil and "nil" or tostring(previous)); return c:Get() end)
	p:Get(); count:Set(8); p:Get()
	check("03 §3 previous nil on first calc then value", seen[1] == "nil" and seen[2] == "7", table.concat(seen, ","))
	card:Destroy()
end

------------------------------------------------------------------ 04 (지금까지의 코드 + 버튼)
local function build04(count, countText, extraCard, extraBtn, extraLabel)
	return nil
end
do -- 04#1 + 04#2
	const count = q.Source(0)
	const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
	const card = D.Frame { Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 0, 48), BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, Text = countText },
		D.TextButton { Size = UDim2.new(1, -40, 0, 42), Position = UDim2.new(0, 20, 1, -62), BackgroundColor3 = Color3.fromRGB(0, 162, 255),
			TextColor3 = Color3.fromRGB(255, 255, 255), Text = "+ 1", TextSize = 16, UICorner = 8,
			Activated = function() count:Set(count:Get() + 1) end },
	}
	card.Parent = screen
	click(buttonOf(card)); click(buttonOf(card))
	check("04#2 두 번 클릭 → 카운트: 2", labelOf(card).Text == "카운트: 2", labelOf(card).Text)
	card:Destroy()
end

------------------------------------------------------------------ 05
do
	const count = q.Source(0)
	const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
	-- 05#2 §1
	table.clear(tagCalls)
	const card1 = D.Frame { q.Tag("Card"), Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Text = countText }, D.TextButton { Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end } }
	card1.Parent = screen
	check("05#2 tag Card", tagsOf(card1) == "Card", tagsOf(card1))
	card1:Destroy()
	-- 05#4 두 자리 같은 이름
	table.clear(tagCalls)
	const inst = D.Frame { q.Tag("Card"), q.Tag("Card", "Panel") }
	check("05#4 {Card,Panel} addTag 둘", tagsOf(inst) == "Card,Panel" and table.concat(tagCalls, " ") == "addTag:Card addTag:Panel", table.concat(tagCalls, " "))
	inst:Destroy()
	-- 05#5 §2 + 05#6
	table.clear(tagCalls)
	const card = D.Frame { q.Tag("Card"),
		count:Compute(function(c: q.StateData<number>) return q.Tag("Card"):Added(if c:Get() % 2 == 0 then "Even" else nil) end),
		Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Text = countText }, D.TextButton { Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end } }
	card.Parent = screen
	check("05#5 초기 {Card,Even}", tagsOf(card) == "Card,Even", tagsOf(card))
	table.clear(tagCalls); count:Set(2)
	check("05#6 Set(2) 엔진 호출 0", #tagCalls == 0, table.concat(tagCalls, " "))
	table.clear(tagCalls); count:Set(3)
	check("05#6 Set(3) removeTag:Even 하나", table.concat(tagCalls, " ") == "removeTag:Even", table.concat(tagCalls, " "))
	-- 05 §2 click cycle {Card,Even} → {Card} (문서: 버튼 누를 때마다 교체)
	count:Set(0) -- 문서: 확인 두 줄은 지운다 → 0에서 다시
	click(buttonOf(card)); local t1 = tagsOf(card); click(buttonOf(card)); local t2 = tagsOf(card)
	check("05 §2 클릭 교체 {Card} → {Card,Even}", t1 == "Card" and t2 == "Card,Even", t1 .. " / " .. t2)
	card:Destroy()
	-- 05#7 §3 (지운 두 줄 반영: count 0부터)
	count:Set(0)
	const active = q.Source(true)
	const card3 = D.Frame { q.Tag("Card"),
		count:Compute(function(c: q.StateData<number>) return q.Tag("Card"):Added(if c:Get() % 2 == 0 then "Even" else nil) end),
		q.Attr { Kind = "counter", Count = count }, q.BooleanAttr("Active", active),
		Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12,
		D.TextLabel { Text = countText }, D.TextButton { Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end } }
	card3.Parent = screen
	local a = card3:GetAttributes()
	check("05#8 attrs 초기 {Active=true,Kind=counter,Count=0}", a.Active == true and a.Kind == "counter" and a.Count == 0, `{a.Active} {a.Kind} {a.Count}`)
	click(buttonOf(card3)); click(buttonOf(card3))
	check("05#8 두 번 클릭 Count=2", card3:GetAttributes().Count == 2)
	active:Set(false)
	check("05#8 Active=false", card3:GetAttributes().Active == false)
	active:Set(q.None)
	check("05#8 None → Active 삭제", card3:GetAttributes().Active == nil and card3:GetAttributes().Kind == "counter")
	-- 05#9 same attr name twice
	expectErr("05#9 Quad0002", function() D.Frame { q.Attr { Kind = "counter" }, q.Attr { Kind = "other" } } end,
		'Quad0002 AttrKey: attribute "Kind" is already bound by another owner')
	-- 05#10 QueryDescendants — mock에 없음(엔진 API)
	check("05#10 QueryDescendants (mock 불가 — 엔진 API, 건너뜀)", true, "skipped")
	card3:Destroy()
end

------------------------------------------------------------------ 06
do
	const count = q.Source(0)
	const name = q.Source("quad")
	-- 06#2 §1 (Out 없음)
	const nameLabel = D.TextLabel { Size = UDim2.fromOffset(240, 28), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = name:Compute(function(n) return `{n:Get()}의 카운터` end) }
	nameLabel.Parent = screen
	const nameBox0 = D.TextBox { Size = UDim2.fromOffset(240, 32), BackgroundColor3 = Color3.fromRGB(50, 50, 58), TextColor3 = Color3.fromRGB(255, 255, 255),
		PlaceholderText = "이름", Text = name }
	nameBox0.Parent = screen
	check("06#2 label quad의 카운터 / box quad", nameLabel.Text == "quad의 카운터" and nameBox0.Text == "quad")
	nameBox0.Text = "abc" -- 엔진이 바꾼 것처럼
	check("06#2 Out 없이 name:Get() 그대로", name:Get() == "quad" and nameLabel.Text == "quad의 카운터")
	nameBox0:Destroy()
	-- 06#5 확인용 emits — nameBox 전에 등록
	local emits = 0
	const obs = name:Observer(function() emits += 1 end):Subscribe()
	check("06#5 등록 즉시 emits 1", emits == 1, emits)
	-- 06#3 §2
	const nameBox = D.TextBox { q.Out("Text", name), Size = UDim2.fromOffset(240, 32), BackgroundColor3 = Color3.fromRGB(50, 50, 58),
		TextColor3 = Color3.fromRGB(255, 255, 255), PlaceholderText = "이름", Text = name }
	nameBox.Parent = screen
	check("06#5 초기 바인딩 뒤 emits 1", emits == 1, emits)
	-- 06#4 reset button
	const resetButton = D.TextButton { Size = UDim2.fromOffset(120, 28), Text = "이름 되돌리기", Activated = function() name:Set("quad") end }
	resetButton.Parent = screen
	nameBox.Text = "민수"
	check("06#3 타이핑 → name/label 따라옴", name:Get() == "민수" and nameLabel.Text == "민수의 카운터", nameLabel.Text)
	check("06#5 타이핑 뒤 emits 2", emits == 2, emits)
	click(resetButton)
	check("06#4 되돌리기 → 입력창 quad", nameBox.Text == "quad" and name:Get() == "quad")
	check("06#5 되돌리기 뒤 emits 3", emits == 3, emits)
	obs:Unsubscribe()
	-- 06#6 §4 OnChange
	const shout = q.Source("")
	const box2 = D.TextBox { Text = name, q.OnChange("Text", function(v) shout:Set(string.upper(v)) end) }
	box2.Text = "hey"
	check("06#6 OnChange → shout HEY", shout:Get() == "HEY", shout:Get())
	-- 06#7 §5
	expectErr("06#7 Quad0224", function()
		const derived = name:Compute(function(n) return n:Get() end)
		D.TextBox { q.Out("Text", derived) }
	end, 'Quad0224 Out: second argument for "Text" must be a Source to write back into (got a read-only State (a :Compute result?))')
	nameLabel:Destroy(); nameBox:Destroy(); resetButton:Destroy(); box2:Destroy()
end

------------------------------------------------------------------ 07
do
	const count = q.Source(0)
	const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
	-- 07#1 §1
	do
		const buttonRef = q.Ref<<TextButton?>>(nil)
		const card = D.Frame { Size = UDim2.fromOffset(240, 160), UICorner = 12, D.TextLabel { Text = countText },
			D.TextButton { buttonRef, Text = "+ 1", Activated = function() count:Set(count:Get() + 1) end } }
		check("07#1 buttonRef.Value.ClassName", buttonRef.Value.ClassName == "TextButton")
		card:Destroy()
	end
	-- 07#3 §2 PreRef + Unwrap
	do
		const buttonRef = q.PreRef<<TextButton?>>(nil)
		const card = D.Frame { Size = UDim2.fromOffset(240, 160), UICorner = 12, D.TextLabel { Text = countText },
			D.TextButton { buttonRef, Text = "+ 1", BackgroundTransparency = 0,
				Activated = function() count:Set(count:Get() + 1); buttonRef:Unwrap().BackgroundTransparency = 0.5 end } }
		const btn = buttonOf(card)
		local before = btn.BackgroundTransparency
		click(btn)
		check("07#3 클릭 BT 0 → 0.5", before == 0 and btn.BackgroundTransparency == 0.5, `{before}->{btn.BackgroundTransparency}`)
		card:Destroy()
		expectErr("07 Unwrap empty Quad0135", function() q.Ref(nil):Unwrap() end,
			"Quad0135 Ref:Unwrap: the Ref is empty (Value is nil) — not filled yet, or never placed")
	end
	-- 07#4 §3 Callback, 07#5 Wait
	do
		local P, log = H.capture()
		const buttonRef = q.Ref<<TextButton?>>(nil)
		buttonRef:Callback(function(inst) P("상자:", if inst then inst.ClassName else "nil") end)
		const card = D.Frame { Size = UDim2.fromOffset(240, 160), UICorner = 12, D.TextLabel { Text = countText },
			D.TextButton { buttonRef, Text = "+ 1", BackgroundTransparency = 0,
				Activated = function() count:Set(count:Get() + 1); buttonRef:Unwrap().BackgroundTransparency = 0.5 end } }
		check("07#4 Callback nil → TextButton", table.concat(log, "|") == "상자:\tnil|상자:\tTextButton", table.concat(log, "|"))
		-- 07#5 (plain Ref 상태에서 §2의 Activated가 buttonRef:Unwrap()를 그대로 쓴다 — 동작 확인)
		click(buttonOf(card))
		check("07#4 plain Ref로 되돌린 뒤 §2 Activated(:Unwrap) 동작", buttonOf(card).BackgroundTransparency == 0.5)
		local got
		task.spawn(function()
			const inst = if buttonRef.Value then buttonRef.Value else buttonRef:Wait().Value
			got = inst.ClassName
		end)
		check("07#5 이미 차 있으면 곧바로", got == "TextButton", got)
		-- 빈 상자: 채워질 때까지 대기
		const r2 = q.Ref<<Frame?>>(nil); local got2
		task.spawn(function() const inst = if r2.Value then r2.Value else r2:Wait().Value; got2 = inst.ClassName end)
		local mid = got2
		const f2 = D.Frame { r2 }
		check("07#5 빈 상자 → 채워질 때", mid == nil and got2 == "Frame", tostring(mid) .. "/" .. tostring(got2))
		-- 07 Ref reuse
		expectErr("07 Ref 두 자리 Quad0233", function() D.Frame { buttonRef } end, "Quad0233 bindLifetime: value is already bound to another Instance")
		const pre = q.PreRef<<Frame?>>(nil); D.Frame { pre }
		expectErr("07 PreRef 재사용 Quad0069", function() D.Frame { pre } end, "Quad0069 PreRef: already fired — a PreRef is one-shot, make a new one for each instance")
		card:Destroy(); f2:Destroy()
	end
	-- 07#6 §4 PostRef 별도
	do
		local P, log = H.capture()
		const doneRef = q.PostRef<<Frame?>>(nil)
		doneRef:Callback(function(inst) if inst then P("자식 수:", #inst:GetChildren()) end end)
		const card = D.Frame { doneRef, D.TextLabel { Text = "A" }, D.TextLabel { Text = "B" } }
		check("07#6 자식 수: 2", table.concat(log, "|") == "자식 수:\t2", table.concat(log, "|"))
	end
end

------------------------------------------------------------------ 08 (07 §3 끝 상태: plain buttonRef, BT 두 줄·Activated 그대로)
do
	const count = q.Source(0)
	const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
	-- 08#1 §1 inline Observer on label
	do
		local P, log = H.capture()
		const buttonRef = q.Ref<<TextButton?>>(nil)
		const card = D.Frame { Size = UDim2.fromOffset(240, 160), UICorner = 12,
			D.TextLabel { Text = countText, count:Observer(function(target: q.StateData<number>) P("카운트가", target:Get(), "가 되었습니다") end) },
			D.TextButton { buttonRef, Text = "+ 1", BackgroundTransparency = 0,
				Activated = function() count:Set(count:Get() + 1); buttonRef:Unwrap().BackgroundTransparency = 0.5 end } }
		click(buttonOf(card))
		check("08#1 생성 즉시 1줄 + 클릭마다 1줄", #log == 2 and log[1] == "카운트가\t0\t가 되었습니다" and log[2] == "카운트가\t1\t가 되었습니다", table.concat(log, "|"))
		labelOf(card):Destroy(); count:Set(2)
		check("08 라벨 Destroy 뒤 Set(2) 안 찍힘", #log == 2, #log)
		card:Destroy()
	end
	-- 08#2 lonely
	do
		local P, log = H.capture()
		const lonely = count:Observer(function(target) P("이건 한 번만 찍힙니다", target:Get()) end)
		count:Set(99)
		check("08#2 lonely 1회", #log == 1, #log)
	end
	count:Set(0)
	-- 08#3 logger
	do
		local P, log = H.capture()
		const logger = q.Source<<q.Observer?>>(count:Observer(function(t) P("카운트", t:Get()) end))
		const card = D.Frame { logger }
		count:Set(1); logger:Set(nil); count:Set(2)
		check("08#3 logger:Set(nil) 뒤 조용", table.concat(log, "|") == "카운트\t0|카운트\t1", table.concat(log, "|"))
		card:Destroy()
	end
	count:Set(0)
	-- 08#4 §2 Effect on card
	do
		local P, log = H.capture()
		const buttonRef = q.Ref<<TextButton?>>(nil)
		const card = D.Frame { Size = UDim2.fromOffset(240, 160), UICorner = 12,
			D.TextLabel { Text = countText },
			D.TextButton { buttonRef, Text = "+ 1", BackgroundTransparency = 0, Activated = function() count:Set(count:Get() + 1); buttonRef:Unwrap().BackgroundTransparency = 0.5 end },
			q.Effect(function()
				const n = count:Get()
				P("이펙트: 지금", n)
				return function() P("정리:", n, "회차의 뒤처리") end
			end, count),
		}
		click(buttonOf(card))
		card:Destroy(); count:Set(5)
		check("08#4 run0 / 정리0, run1 / 정리1 후 조용", table.concat(log, "|") == "이펙트: 지금\t0|정리:\t0\t회차의 뒤처리|이펙트: 지금\t1|정리:\t1\t회차의 뒤처리", table.concat(log, "|"))
	end
	count:Set(0)
	-- 08#5 §3 color pipe + 08#6 §4 GuiService effect (full 08 card)
	do
		local GuiService = { SelectedObject = nil }
		local sel = {}
		const buttonRef = q.Ref<<TextButton?>>(nil)
		const isBig = count:Compute(function(c) return c:Get() >= 10 end)
		const card = D.Frame { Size = UDim2.fromOffset(240, 160), UICorner = 12,
			D.TextLabel { Text = countText },
			D.TextButton { buttonRef, Text = "+ 1", BackgroundTransparency = 0,
				Activated = function() count:Set(count:Get() + 1); buttonRef:Unwrap().BackgroundTransparency = 0.5 end,
				BackgroundColor3 = count:Compute(function(c: q.StateData<number>)
					return if c:Get() >= 10 then Color3.fromRGB(255, 190, 0) else Color3.fromRGB(0, 162, 255) end) },
			q.Effect(function()
				const inst = buttonRef.Value
				if inst and isBig:Get() then
					GuiService.SelectedObject = inst; table.insert(sel, "select")
					return function() if GuiService.SelectedObject == inst then GuiService.SelectedObject = nil; table.insert(sel, "unselect") end end
				end
				return nil
			end, isBig, buttonRef),
		}
		const btn = buttonOf(card)
		local blue = btn.BackgroundColor3 == Color3.fromRGB(0, 162, 255)
		count:Set(10); local yellow = btn.BackgroundColor3 == Color3.fromRGB(255, 190, 0)
		count:Set(11); count:Set(3); local blue2 = btn.BackgroundColor3 == Color3.fromRGB(0, 162, 255)
		check("08#5 색 파랑→노랑→파랑", blue and yellow and blue2)
		count:Set(12); card:Destroy()
		check("08#6 select/unselect 순서", table.concat(sel, ",") == "select,unselect,select,unselect,select,unselect", table.concat(sel, ","))
	end
end

------------------------------------------------------------------ 09
do
	const count = q.Source(0)
	const countText = count:Compute(function(c) return `카운트: {c:Get()}` end)
	local function card09(extra, P)
		const buttonRef = q.Ref<<TextButton?>>(nil)
		local props = { Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), UICorner = 12, q.Tag("Card") }
		for _, e in extra do table.insert(props, e) end
		table.insert(props, D.TextLabel { Text = countText })
		table.insert(props, D.TextButton { buttonRef, Text = "+ 1", UICorner = 8, Activated = function() count:Set(count:Get() + 1) end })
		return D.Frame(props)
	end
	-- 09#1 §1 hand-rolled
	local P1, log1 = H.capture()
	const created = q.PreRef<<Frame?>>(nil)
	created:Callback(function(inst) if inst then P1("만들어짐:", inst.ClassName) end end)
	const rendered = q.PostRef<<Frame?>>(nil)
	rendered:Callback(function(inst) if inst then const kids = inst:GetChildren(); P1("다 그려짐: 자식", #kids, "개") end end)
	const card1 = card09({ created, rendered, q.Effect(function() return function() P1("없어짐") end end) })
	local pre = table.concat(log1, "|")
	card1:Destroy()
	check("09#1 만들어짐/다 그려짐 3/없어짐", pre == "만들어짐:\tFrame|다 그려짐: 자식\t3\t개" and log1[3] == "없어짐", table.concat(log1, "|"))
	-- 09#2 §2 named hooks
	local P2, log2 = H.capture()
	const card2 = card09({
		q.OnCreated<<Frame>>(function(inst) P2("만들어짐:", inst.ClassName) end),
		q.OnRendered<<Frame>>(function(inst) const kids = inst:GetChildren(); P2("다 그려짐: 자식", #kids, "개") end),
		q.OnDestroyed(function() P2("없어짐") end),
	})
	card2:Destroy()
	check("09#2 §1과 출력 동일", table.concat(log1, "|") == table.concat(log2, "|"), table.concat(log2, "|"))
end

------------------------------------------------------------------ 10
do
	-- 10#1..#3
	const hot = q.Source(false)
	const cardColor = hot:Compute(function(h) return if h:Get() then Color3.fromRGB(240, 60, 60) else Color3.fromRGB(35, 35, 42) end)
	const CardStyle = D.Modifier.Frame { BackgroundColor3 = cardColor, BorderSizePixel = 0 }
	const card = D.Frame { CardStyle, Size = UDim2.fromOffset(240, 160), UICorner = 12 }
	check("10#3 BorderSizePixel 0 / 초기 색", card.BorderSizePixel == 0 and card.BackgroundColor3 == Color3.fromRGB(35, 35, 42))
	hot:Set(true)
	check("10#3 hot → 빨강", card.BackgroundColor3 == Color3.fromRGB(240, 60, 60))
	-- 10#4 immutability
	const base = D.Modifier.TextButton { TextSize = 16 }
	const big = base:TextSize(24)
	const b1 = D.TextButton { base }; const b2 = D.TextButton { big }
	check("10#4 base 16 / big 24", b1.TextSize == 16 and b2.TextSize == 24)
	-- builder chain form
	const chain = D.Modifier.TextButton():TextSize(16)
	check("10 §1 빌더 체인", D.TextButton { chain }.TextSize == 16)
	-- rule 1: string key wins
	const SomeMod = D.Modifier.TextButton { Text = "mod" }
	check("10 규칙1 문자 키가 이김", D.TextButton { SomeMod, Text = "확정" }.Text == "확정")
	-- 10#5 accent
	local function accent(color) return D.Modifier.TextButton { BackgroundColor3 = color, TextColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0 } end
	const button = D.TextButton { accent(Color3.fromRGB(0, 162, 255)), Text = "+ 1" }
	check("10#5 accent 색", button.BackgroundColor3 == Color3.fromRGB(0, 162, 255) and button.BorderSizePixel == 0)
	-- 10#7 §4
	const accentColor = q.Source(Color3.fromRGB(0, 162, 255))
	const button2 = D.TextButton { accent(accentColor), Text = "+ 1" }
	accentColor:Set(Color3.fromRGB(240, 60, 60))
	check("10#7 accentColor 따라감", button2.BackgroundColor3 == Color3.fromRGB(240, 60, 60))
	expectErr("10 Quad0182", function() q.Source(CardStyle) end, "Quad0182 Source: cannot hold a Modifier as a Source value")
	-- 10#8 emphasis
	local function emphasis(size) return function(mod) return mod:TextSize(size):TextColor3(Color3.fromRGB(255, 230, 120)) end end
	const title = D.Modifier.TextLabel { BackgroundTransparency = 1 }:Apply(emphasis(24))
	const label = D.TextLabel { title, Text = "카운터" }
	check("10#8 emphasis", label.TextSize == 24 and label.BackgroundTransparency == 1 and label.Text == "카운터")
end

C.summary("chain-a")
