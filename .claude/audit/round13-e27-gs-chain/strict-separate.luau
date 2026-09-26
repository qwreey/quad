--!strict
-- E27 strict — "새 예시: 별도 스크립트"/"짧은 조각" 블록들(11·13·14·19·20·21), 블록마다 do…end
const q = require("./s10-config")
const D = q.Declaration
do -- 11#1/#3/#4
	const items = q.Slot { D.TextLabel { Text = "첫째" }, D.TextLabel { Text = "둘째" } }
	const box = D.Frame { Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), items }
	print(#box:GetChildren())
	items:Add(D.TextLabel { Text = "셋째" })
	items:Add(D.TextLabel { Text = "앞에" }, 1)
	items:Remove(1)
	items:Clear()
	const taken = items:Extract(1)
	const rest = items:ExtractAll()
	print(taken, rest)
end
do -- 11#2
	const items = q.Slot<<Instance>>({ D.TextLabel { Text = "첫째" } })
	print(items)
end
do -- 11#5/#6/#9
	const slotA = q.Slot { D.TextLabel { Text = "A1" }, D.TextLabel { Text = "A2" } }
	const slotB = q.Slot { D.TextLabel { Text = "B1" } }
	const panel = D.Frame { D.TextLabel { Text = "머리" }, slotA, slotB }
	print(slotA.Offset:Get(), slotA.Length:Get(), panel)
	slotA:Add(D.TextLabel { Text = "A3" })
	slotB:Add(D.TextLabel { Text = "B2", LayoutOrder = slotB.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 2 end) })
end
do -- 11#7/#8
	const innerA = q.Slot { D.TextLabel { Text = "Inner1" }, D.TextLabel { Text = "Inner2" } }
	const innerB = q.Slot { D.TextLabel { Text = "Inner3" } }
	const outer = q.Slot { innerA, D.TextLabel { Text = "Outer" }, innerB }
	const host = D.Frame { outer }
	print(#host:GetChildren(), outer.Offset:Get(), outer.Length:Get())
	innerA:Add(D.TextLabel { Text = "Inner4" })
end
do -- 11#10
	const cur = q.Source<<Instance?>>(nil)
	const host = D.Frame { D.TextLabel { Text = "머리" }, cur }
	const a = D.TextLabel { Text = "A" }
	cur:Set(a)
	print(#host:GetChildren(), host:GetChildren()[2].Text)
	cur:Set(nil)
end
do -- 13#6/#7/#9/#10
	local function Sum(n)
		return function(c) return c:Get() + n end
	end
	const count = q.Source(0)
	const plusTen = count:Compute(Sum(10))
	print(plusTen:Get())
	local function logWith(prefix)
		return function(t) print(prefix, t:Get()) end
	end
	const label = D.TextLabel { Text = "…", count:Observer(logWith("카운트:")) }
	const plusTenOp = count:Apply(q.Operator.Sum(10))
	const Doubled = { __apply = function(self, state) return state:Compute(function(c) return c:Get() * 2 end) end }
	const twice = count:Apply(Doubled)
	print(label, plusTenOp, twice)
end
do -- 13#11 (문서의 strict 판 그대로)
	local function Sum(n: number)
		return function(c: q.StateData<number>): number return c:Get() + n end
	end
	local function logWith(prefix: string)
		return function(t: q.StateData<number>) print(prefix, t:Get()) end
	end
	local function highlightColor(state: q.State<number>, threshold: number): q.State<Color3>
		return state:Compute(function(c: q.StateData<number>): Color3
			return if c:Get() >= threshold then Color3.fromRGB(255, 190, 0) else Color3.fromRGB(0, 162, 255)
		end)
	end
	const count = q.Source(0)
	const total: q.State<number> = count:Apply(q.Operator.Sum(10))
	print(Sum, logWith, highlightColor(count, 10), total)
end
do -- 14#6/#7
	const logRows = q.Source({ { Id = "a", Label = "왼쪽" }, { Id = "b", Label = "오른쪽" } })
	const list = q.Slot()
	list:List(logRows, function(ctx)
		if ctx.Item == q.KeyGone then return nil, ctx.UserData end
		if ctx.Prev then
			ctx.UserData:Set(ctx.Item.Label)
			return ctx.Prev, ctx.UserData
		end
		const label = q.Source(ctx.Item.Label)
		return D.TextLabel { Text = label }, label
	end, function(item) return item.Id end)
	const box = D.Frame { BackgroundTransparency = 1, list }
	const first = box:GetChildren()[1]
	logRows:Set({ { Id = "a", Label = "왼쪽(수정)" }, { Id = "b", Label = "오른쪽" }, { Id = "c", Label = "새로" } })
	print(box:GetChildren()[1] == first)
end
do -- 14#8
	const cur = q.Source<<string?>>(nil)
	const single = q.Slot<<Instance>>():Single(cur, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		return D.TextLabel { Text = ctx.Item, LayoutOrder = ctx.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 1 end) }
	end)
	const top = q.Slot { D.TextLabel { Text = "T1" }, D.TextLabel { Text = "T2" } }
	const panel = D.Frame { D.TextLabel { Text = "머리" }, top, single }
	cur:Set("지금 화면")
	print(single:Get(1).LayoutOrder, panel)
end
do -- 19#1/#2/#3
	const count = q.Source(0)
	const countText = count:Compute(function(c) print("파이프가 돌았다"); return `카운트: {c:Get()}` end)
	count:Set(1)
	const n = q.Source(1)
	const doubled = n:Compute(function(s) return s:Get() * 2 end)
	local calls = 0
	const total = n:Compute(function(s, previous, d) calls += 1; return s:Get() + d:Get() end, doubled)
	const label = D.TextLabel { Text = total:Compute(function(s) return tostring(s:Get()) end) }
	print(calls, label.Text, countText)
	const log = {}
	const hp = q.Source(100)
	const observer = hp:Observer(function(target) table.insert(log, target:Get()) end)
	observer:Subscribe()
end
do -- 19#5
	const count = q.Source(0)
	const numberColor = count:Compute(function(c) return if c:Get() % 2 == 0 then Color3.fromRGB(0, 200, 255) else Color3.fromRGB(255, 255, 255) end)
	const time = q.Source(0.3)
	const animated = numberColor:Apply(q.Animate { Time = time })
	const label = D.TextLabel { TextColor3 = animated }
	time:Set(1.0); count:Set(1); print(label)
end
do -- 20#1/#2/#3/#4
	for _, handler in q.Dispatch.listHandlers() do print(handler.name) end
	const a = q.Source("A"); const b = q.Source("B")
	const which = q.Source(a)
	const label = D.TextLabel { Text = which :: any }
	which:Set(b)
	const count = q.Source(0)
	local function makeEffect(lbl)
		return q.Effect(function()
			print(`{lbl} run {count:Get()}`)
			return function() print(`{lbl} cleanup`) end
		end, count)
	end
	const which2 = q.Source(makeEffect("A"))
	const host = D.Frame { which2 }
	which2:Set(makeEffect("B"))
	host:Destroy()
	const refA = q.Ref<<TextLabel?>>(nil)
	const refB = q.Ref<<TextLabel?>>(nil)
	const which3 = q.Source(refA)
	const label3 = D.TextLabel { which3, Text = "안녕" }
	which3:Set(refB)
	print(label, label3)
end
do -- 21#1
	const screen = D.ScreenGui { ResetOnSpawn = false }
	q.dispose(screen)
end
