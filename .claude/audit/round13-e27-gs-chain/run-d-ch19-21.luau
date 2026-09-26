--!nocheck
-- E27 D — GS 19~21(각 장이 "앞 장들과 별개로 돌려 보는 짧은 조각"이라 밝힌 블록) + 20장 표 대조
local H = require("./harness")
local C = require("./check")
local check, expectErr = C.check, C.expectErr
local q, D = H.q, H.D
local mock = H.mock
UDim2 = H.EG.UDim2; Color3 = H.EG.Color3; Enum = H.EG.Enum

do -- 19#1
	local P, log = H.capture()
	const count = q.Source(0)
	const countText = count:Compute(function(c) P("파이프가 돌았다"); return `카운트: {c:Get()}` end)
	count:Set(1); count:Set(2)
	check("19#1 0번", #log == 0)
	const l = D.TextLabel { Text = countText }
	check("19#1 꽂으면 한 번", #log == 1)
	count:Set(3)
	check("19#1 그 뒤 Set마다 한 번", #log == 2)
end
do -- 19#2
	const n = q.Source(1)
	const doubled = n:Compute(function(s) return s:Get() * 2 end)
	local calls = 0
	const total = n:Compute(function(s, previous, d) calls += 1; return s:Get() + d:Get() end, doubled)
	const label = D.TextLabel { Text = total:Compute(function(s) return tostring(s:Get()) end) }
	check("19#2 1 \"3\"", calls == 1 and label.Text == "3", `{calls} {label.Text}`)
	n:Set(5)
	check("19#2 2 \"15\"", calls == 2 and label.Text == "15", `{calls} {label.Text}`)
end
do -- 19#3
	const log = {}
	const hp = q.Source(100)
	const observer = hp:Observer(function(target) table.insert(log, target:Get()) end)
	check("19#3 1", #log == 1)
	hp:Set(80); hp:Set(60)
	check("19#3 보류 1", #log == 1)
	observer:Subscribe()
	check("19#3 2 60", #log == 2 and log[2] == 60)
	observer:Unsubscribe()
end
do -- 19#4 (14장 목록 축약 + updates 카운터)
	local updates = 0
	const rows = q.Source({ { Id = "a", Label = "왼쪽", Start = 0 }, { Id = "b", Label = "오른쪽", Start = 10 } })
	const list = q.Slot()
	list:List(rows, function(ctx)
		updates += 1
		if ctx.Item == q.KeyGone then return nil, ctx.UserData end
		if ctx.Prev then return ctx.Prev, ctx.UserData end
		return D.TextLabel { Text = ctx.Item.Label }, ctx.UserData
	end, function(item) return item.Id end)
	check("19#4 0", updates == 0)
	const board = D.Frame { list }
	check("19#4 2", updates == 2)
	rows:Set({ { Id = "a", Label = "왼쪽", Start = 0 }, { Id = "b", Label = "오른쪽", Start = 10 }, { Id = "c", Label = "새로", Start = 0 } })
	check("19#4 5", updates == 5, updates)
end
do -- 19#5 (17 §2의 numberColor, Time만 State)
	const count = q.Source(0)
	const numberColor = count:Compute(function(c) return if c:Get() % 2 == 0 then Color3.fromRGB(0, 200, 255) else Color3.fromRGB(255, 255, 255) end)
	mock.resetTweenLog()
	const time = q.Source(0.3)
	const animated = numberColor:Apply(q.Animate { Time = time })
	const label = D.TextLabel { TextColor3 = animated }
	time:Set(1.0)
	check("19#5 time:Set → 트윈 0", #mock.tweenLog == 0)
	count:Set(1)
	check("19#5 count:Set(1) → 트윈 1, Time 1.0", #mock.tweenLog == 1 and mock.tweenLog[1].info.args[1] == 1.0, #mock.tweenLog)
end
do -- 19#6 (18 파이프 + runs)
	local runs = 0
	const count = q.Source(10); const unit = q.Source("점")
	const blocker = q.Blocker()
	const raw = count:Compute(function(c, prev, u) runs += 1; return `{c:Get()} {u:Get()}` end, unit)
	const l = D.TextLabel { Text = raw }
	count:Set(100); unit:Set("포인트")
	check("19#6 게이트 없이 3", runs == 3, runs)
	runs = 0
	const count2 = q.Source(10); const unit2 = q.Source("점")
	const gated = count2:Compute(function(c, prev, u) runs += 1; return `{c:Get()} {u:Get()}` end, unit2):Apply(blocker)
	const l2 = D.TextLabel { Text = gated }
	blocker:On(); count2:Set(100); unit2:Set("포인트"); blocker:Off()
	check("19#6 게이트 2", runs == 2, runs)
end

------------------------------------------------------------------ 20
do -- 20#1
	local names = {}
	for _, handler in q.Dispatch.listHandlers() do table.insert(names, handler.name) end
	local have = {}; for _, n in names do have[n] = true end
	check("20#1 SlotHandler/StoreBind/Event/InstanceChild/Property 모두 있음",
		have.SlotHandler and have.StoreBind and have.Event and have.InstanceChild and have.Property, table.concat(names, ","))
	-- 20 table rows
	const host = D.Frame {}
	local rows = {
		{ "Tag(05)", 1, q.Tag("Card"), "TagFallbackHandler" },
		{ "Attr(05)", 1, q.Attr { Kind = "counter" }, "AttrGroupFallbackHandler" },
		{ "Ref", 1, q.Ref(nil), "RefLeafHandler" },
		{ "Effect", 1, q.Effect(function() end), "EffectLeafHandler" },
		{ "Slot", 1, q.Slot {}, "SlotHandler" },
		{ "D.Frame(02)", 1, D.Frame {}, "InstanceChild" },
		{ "Text string(02)", "Text", "x", "Property" },
		{ "Activated fn(04)", "Activated", function() end, "Event" },
		{ "Source num key(03)", 1, q.Source(1), "StoreBind" },
		{ "Source str key(03)", "Text", q.Source("a"), "StoreBind" },
	}
	for _, r in rows do
		local inst = if r[2] == "Activated" or r[2] == "Text" then D.TextButton {} else host
		local h = q.Dispatch.getHandler(inst, r[2], r[3])
		check("20 표 " .. r[1], h and h.name == r[4], h and h.name)
	end
	expectErr("20 §1 Tag at string key Quad0076", function() D.Frame { Foo = q.Tag("x") } end,
		"Quad0076 Dispatch: no handler matched key Foo (value: table, brand: Tag) — a quad value at a string key: it belongs in a numeric (array) slot")
	expectErr("20 §1 Effect at string key Quad0097", function() D.Frame { Foo = q.Effect(function() end) } end,
		"Quad0097 Effect: must be an array item, not the value of a string key")
end
do -- 20#2
	const a = q.Source("A"); const b = q.Source("B")
	const which = q.Source(a)
	const label = D.TextLabel { Text = which :: any }
	local s = { label.Text }
	a:Set("A2"); table.insert(s, label.Text)
	which:Set(b); table.insert(s, label.Text)
	a:Set("A3"); table.insert(s, label.Text)
	check("20#2 A/A2/B/B", table.concat(s, ",") == "A,A2,B,B", table.concat(s, ","))
end
do -- 20#3
	local P, log = H.capture()
	const count = q.Source(0)
	local function makeEffect(label)
		return q.Effect(function() P(`{label} run {count:Get()}`); return function() P(`{label} cleanup`) end end, count)
	end
	const which = q.Source(makeEffect("A"))
	const host = D.Frame { which }
	count:Set(1)
	which:Set(makeEffect("B"))
	count:Set(2)
	host:Destroy()
	check("20#3 순서", table.concat(log, "|") == "A run 0|A cleanup|A run 1|B run 1|A cleanup|B cleanup|B run 2|B cleanup", table.concat(log, "|"))
end
do -- 20#4
	const refA = q.Ref<<TextLabel?>>(nil); const refB = q.Ref<<TextLabel?>>(nil)
	const which = q.Source(refA)
	const label = D.TextLabel { which, Text = "안녕" }
	local r1 = `{refA.Value ~= nil} {refB.Value ~= nil}`
	which:Set(refB)
	local r2 = `{refA.Value ~= nil} {refB.Value ~= nil}`
	check("20#4 true false → false true", r1 == "true false" and r2 == "false true", r1 .. " / " .. r2)
end

------------------------------------------------------------------ 21#1
do
	local P, log = H.capture()
	const count = q.Source(0)
	const screen = D.ScreenGui { ResetOnSpawn = false }
	const strong = count:Observer(function(t) P("strong", t:Get()) end):Subscribe()
	const card = D.Frame {
		count:Observer(function(t) P("obs", t:Get()) end),
		q.Effect(function() P("run"); return function() P("cleanup") end end),
		q.OnDestroyed(function() P("destroyed") end) }
	card.Parent = screen
	q.dispose(screen)
	count:Set(1)
	local s = table.concat(log, "|")
	check("21#1 obs 멈춤·cleanup·OnDestroyed 1회·강한 구독 계속", s:find("cleanup") and s:find("destroyed") and not s:find("obs\t1") and s:find("strong\t1") ~= nil, s)
	strong:Unsubscribe()
	-- 21 details: UICorner 관리 자식 dispose 거부
	const f = D.Frame { UICorner = 8 }
	expectErr("21 관리 자식 dispose → Quad0179", function() q.dispose(f:GetChildren()[1]) end, "Quad0179 dispose: this value is still held by a Slot or a mounted position")
end
C.summary("run-d-ch19-21")
