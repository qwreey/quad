--!nocheck
-- E56 (4a): 주석판에서 타입이 아닌(런타임에 남는) 편집 셋이 원문과 같은 관측을 내는지 — mock
local H = require("./harness")
local q, D = H.q, H.D
local out = {}
local function L(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end table.insert(out, table.concat(t, " ")) end
-- (1) 07#1 buttonRef.Value.ClassName vs buttonRef:Unwrap().ClassName (마운트 직후)
do
	local r = q.Ref(nil); local card = D.Frame { D.TextButton { r, Text = "+ 1" } }
	L("07#1", r.Value.ClassName, r:Unwrap().ClassName)
end
-- (2) 07 §5 :Wait().Value vs :Wait():Unwrap() — 빈 상자에서 대기하다 채워질 때
for _, form in { "Value", "Unwrap" } do
	local r = q.Ref(nil); local got
	local th = coroutine.create(function()
		local inst = if r.Value then r.Value else (if form == "Value" then r:Wait().Value else r:Wait():Unwrap())
		got = inst.ClassName
	end)
	coroutine.resume(th)
	local card = D.Frame { D.TextButton { r, Text = "x" } }
	L("07§5", form, coroutine.status(th), got)
end
-- (3) 14#8 인라인 ctx.Offset:Compute vs 지역 off로 뺀 판 — LayoutOrder 추적
for _, form in { "inline", "local" } do
	local cur = q.Source(nil)
	local single = q.Slot():Single(cur, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if form == "inline" then
			return D.TextLabel { Text = ctx.Item, LayoutOrder = ctx.Offset:Compute(function(o) return o:Get() + 1 end) }
		end
		local off = ctx.Offset
		return D.TextLabel { Text = ctx.Item, LayoutOrder = off:Compute(function(o) return o:Get() + 1 end) }
	end)
	local top = q.Slot { D.TextLabel { Text = "T1" }, D.TextLabel { Text = "T2" } }
	local panel = D.Frame { D.TextLabel { Text = "머리" }, top, single }
	cur:Set("지금 화면"); local a = single:Get(1).LayoutOrder
	top:Add(D.TextLabel { Text = "T3" }); local b = single:Get(1).LayoutOrder
	top:Remove(1); local c = single:Get(1).LayoutOrder
	L("14#8", form, a, b, c)
end
for _, l in out do print(l) end
