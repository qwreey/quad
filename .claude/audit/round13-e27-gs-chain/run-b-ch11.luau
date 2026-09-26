--!nocheck
-- E27 B — GS 11 (카운터와 별개인 "새 예시: 별도 스크립트" 넷 + 이어지는 조각들)
local H = require("./harness")
local C = require("./check")
local check, expectErr = C.check, C.expectErr
local q, D = H.q, H.D
UDim2 = H.EG.UDim2; Color3 = H.EG.Color3
local function texts(inst) local t = {} for _, c in inst:GetChildren() do table.insert(t, c.Text) end return table.concat(t, ",") end

do -- 11#1 + 11#3 (§1 → §2 이어짐)
	const items = q.Slot { D.TextLabel { Text = "첫째" }, D.TextLabel { Text = "둘째" } }
	const box = D.Frame { Size = UDim2.fromOffset(240, 160), BackgroundColor3 = Color3.fromRGB(35, 35, 42), items }
	check("11#1 #box 2", #box:GetChildren() == 2)
	items:Add(D.TextLabel { Text = "셋째" }); check("11#3 Add → 3", #box:GetChildren() == 3)
	items:Add(D.TextLabel { Text = "앞에" }, 1); check("11#3 Add@1 → 4", #box:GetChildren() == 4)
	items:Remove(1); check("11#3 Remove(1) → 3", #box:GetChildren() == 3)
	items:Clear(); check("11#3 Clear → 0", #box:GetChildren() == 0)
	expectErr("11#4 빈 채로 Extract → Quad0236", function() items:Extract(1) end, "Quad0236 Slot:Extract: index out of range (got 1, limit 0)")
	items:Add(D.TextLabel { Text = "x" }); items:Add(D.TextLabel { Text = "y" }); items:Add(D.TextLabel { Text = "z" })
	const taken = items:Extract(1)
	const rest = items:ExtractAll()
	check("11#4 Extract/ExtractAll 살아 있음", not H.mock.isDestroyed(taken) and #rest == 2 and #box:GetChildren() == 0)
	-- 같은 원소 두 자리
	const other = q.Slot()
	const s2 = q.Slot { D.TextLabel { Text = "held" } }
	const host2 = D.Frame { s2 }
	const held = s2:Get(1)
	local ok = pcall(function() const s3 = q.Slot {}; D.Frame { s3 }; s3:Add(held) end)
	check("11 §2 이미 든 원소 :Add 거부", not ok)
end
do -- 11#2 strict 조각
	const items = q.Slot<<Instance>>({ D.TextLabel { Text = "첫째" } })
	check("11#2 Slot<<Instance>>({..}) 런타임", items ~= nil)
end
do -- 11#5 + 11#6 + 11#9(§5)
	const slotA = q.Slot { D.TextLabel { Text = "A1" }, D.TextLabel { Text = "A2" } }
	const slotB = q.Slot { D.TextLabel { Text = "B1" } }
	const panel = D.Frame { D.TextLabel { Text = "머리" }, slotA, slotB }
	check("11#5 slotA 1 2", slotA.Offset:Get() == 1 and slotA.Length:Get() == 2, `{slotA.Offset:Get()} {slotA.Length:Get()}`)
	check("11#5 slotB 3 1", slotB.Offset:Get() == 3 and slotB.Length:Get() == 1, `{slotB.Offset:Get()} {slotB.Length:Get()}`)
	slotA:Add(D.TextLabel { Text = "A3" })
	check("11#6 slotA 1 3", slotA.Offset:Get() == 1 and slotA.Length:Get() == 3)
	check("11#6 slotB 4 1", slotB.Offset:Get() == 4 and slotB.Length:Get() == 1)
	-- 11 §3 note: Length 0 before mount
	const pre = q.Slot { D.TextLabel { Text = "p" } }
	check("11 §3 마운트 전 Length 0", pre.Length:Get() == 0, pre.Length:Get())
	-- 11#9
	slotB:Add(D.TextLabel { Text = "B2",
		LayoutOrder = slotB.Offset:Compute(function(o: q.StateData<number>) return o:Get() + 2 end) })
	const b2 = slotB:Get(2)
	check("11#9 B2 LayoutOrder 6", b2.LayoutOrder == 6, b2.LayoutOrder)
	slotA:Add(D.TextLabel { Text = "A4" })
	check("11#9 앞이 자라면 7", b2.LayoutOrder == 7, b2.LayoutOrder)
end
do -- 11#7 + 11#8
	const innerA = q.Slot { D.TextLabel { Text = "Inner1" }, D.TextLabel { Text = "Inner2" } }
	const innerB = q.Slot { D.TextLabel { Text = "Inner3" } }
	const outer = q.Slot { innerA, D.TextLabel { Text = "Outer" }, innerB }
	const host = D.Frame { outer }
	check("11#7 4 0 4", #host:GetChildren() == 4 and outer.Offset:Get() == 0 and outer.Length:Get() == 4)
	check("11#7 innerA 0 2", innerA.Offset:Get() == 0 and innerA.Length:Get() == 2)
	check("11#7 innerB 3 1", innerB.Offset:Get() == 3 and innerB.Length:Get() == 1)
	innerA:Add(D.TextLabel { Text = "Inner4" })
	check("11#8 5 5", #host:GetChildren() == 5 and outer.Length:Get() == 5)
	check("11#8 innerB 4 1", innerB.Offset:Get() == 4 and innerB.Length:Get() == 1)
	check("11#8 물리 순서 Inner1,Inner2,Outer,Inner3,Inner4", texts(host) == "Inner1,Inner2,Outer,Inner3,Inner4", texts(host))
end
do -- 11#10
	const cur = q.Source<<Instance?>>(nil)
	const host = D.Frame { D.TextLabel { Text = "머리" }, cur }
	check("11#10 1", #host:GetChildren() == 1)
	const a = D.TextLabel { Text = "A" }
	cur:Set(a)
	check("11#10 2 A", #host:GetChildren() == 2 and host:GetChildren()[2].Text == "A")
	const b = D.TextLabel { Text = "B" }
	cur:Set(b)
	check("11#10 2 B", #host:GetChildren() == 2 and host:GetChildren()[2].Text == "B")
	check("11 §6 옛 a 파괴 안 됨·Parent nil", not H.mock.isDestroyed(a) and a.Parent == nil)
	cur:Set(nil)
	check("11#10 1", #host:GetChildren() == 1)
	cur:Set(a); check("11 §6 a 다시 돌아옴", a.Parent == host)
	expectErr("11 §6 지금 놓인 원소 q.dispose 막힘", function() q.dispose(a) end, "Quad0179")
	cur:Set(nil)
	local ok = pcall(q.dispose, a)
	check("11 §6 내려놓은 뒤 dispose 성공", ok)
	-- 11 §6 text: "State 자리에 지금 놓여 있는 원소는 q.dispose도 막지 않으니" — 실측은 위(막힘) 참고
end
C.summary("run-b-ch11")
