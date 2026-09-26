--!nocheck
-- round13 E17 B — how-to 07 (Claim / Clone pattern) integration. a normal / b teardown / c reentrancy / retry.
local H = require("./round13-e17-probe-setup")
local q, D, mock, try, track, alive, subs, foreign = H.q, H.D, H.mock, H.try, H.track, H.alive, H.subs, H.foreign
local M = D.Mapper
local function P(...) print(...) end

local function ItemCardTree()
	return foreign({ "Frame", name = "ItemCard", children = {
		{ "TextLabel", name = "ItemName" },
		{ "ImageLabel", name = "ItemIcon" },
		{ "TextButton", name = "ActionButton" },
	} })
end

P("== B1 §1 verbatim ==")
local template = ItemCardTree()
local clicks = q.Source(0)
local clickText = clicks:Compute(function(c) return `클릭 횟수: {c:Get()}` end)
local r = q.Claim(template, M.Frame(M.Root)({
	M.TextLabel("ItemName")({ Text = "검" }),
	M.ImageLabel("ItemIcon")({ Image = "rbxassetid://1" }),
	M.TextButton("ActionButton")({
		Text = clickText,
		Activated = function() clicks:Set(clicks:Get() + 1) end,
	}),
	Visible = true,
}))
local btn = template:FindFirstChild("ActionButton")
P("returns same inst", r == template, "Name", template:FindFirstChild("ItemName").Text, "btn", btn.Text)
btn.Activated:Fire(); btn.Activated:Fire()
P("after 2 clicks", btn.Text)
P("plain props table", select(2, try("Claim(inst, {Text=…})", function() q.Claim(ItemCardTree(), { Visible = true }) end)) and "" or "")

P("== B1b re-Claim / claim a D-made template (§2 bullet 1, §3 1) quote Quad0225) ==")
try("Claim same root again", function() q.Claim(template, M.Frame(M.Root)({})) end)
local dmade = D.Frame { Name = "ItemCard", D.TextLabel { Name = "ItemName", Text = "-" } }
try("Claim a D-made template", function() q.Claim(dmade, M.Frame(M.Root)({ M.TextLabel("ItemName")({}) })) end)

P("== B1c §2 bullet 2: unnamed child → Quad0032; fix & retry ==")
local t2 = foreign({ "Frame", children = { { "TextLabel" }, { "TextButton", name = "ActionButton" } } })
local nameSrc = q.Source("n")
local function desc()
	return M.Frame(M.Root)({ M.TextLabel("ItemName")({ Text = nameSrc, q.Out("Text", nameSrc) }), M.TextButton("ActionButton")({}) })
end
local d1 = desc()
try("claim unnamed", function() q.Claim(t2, d1) end)
P("  subs of nameSrc after failed claim", subs(nameSrc), "isClaimed root", q.Backend.isClaimed(t2))
t2:FindFirstChild("TextLabel").Name = "ItemName"
try("retry SAME descriptor after rename", function() q.Claim(t2, d1) end)
P("  label", t2:FindFirstChild("ItemName").Text, "subs", subs(nameSrc))

P("== B2 §2 Slot:List over Claim'd clones ==")
local itemsState = q.Source({ { id = "sword", label = "검" }, { id = "shield", label = "방패" } })
local made = 0
local function ItemCard(item, label)
	made += 1
	local card = ItemCardTree()
	track("B2.card", card)
	return q.Claim(card, M.Frame(M.Root)({
		M.TextLabel("ItemName")({ Text = label }),
		M.ImageLabel("ItemIcon")({ Image = "rbxassetid://2" }),
		M.TextButton("ActionButton")({ Text = "사용", Activated = function() P("  Selected:", item.id) end }),
	}))
end
local rows = q.Slot():List(itemsState, function(ctx)
	local item, prev, ud = ctx.Item, ctx.Prev, ctx.UserData
	if item == q.KeyGone then return nil, ud end
	if prev then ud.label:Set(item.label) return prev, ud end
	local label = q.Source(item.label)
	return ItemCard(item, label), { label = label }
end, function(item) return item.id end)
local host = D.ScrollingFrame { Name = "Host", D.UIListLayout {}, rows }
local function names()
	local t = {}
	for _, c in host:GetChildren() do if c.ClassName == "Frame" then table.insert(t, c:FindFirstChild("ItemName").Text) end end
	return table.concat(t, ",")
end
P("mounted", names(), "made", made)
itemsState:Set({ { id = "shield", label = "방패+" }, { id = "sword", label = "검" }, { id = "bow", label = "활" } })
P("reorder+relabel+add", names(), "made", made)
local shieldCard = host:GetChildren()[2]
itemsState:Set({ { id = "bow", label = "활" } })
P("remove two", names(), "shield card destroyed?", mock.isDestroyed(shieldCard))
shieldCard = nil
host:Destroy()
P("host destroyed; alive", alive("B2"))

P("== B3 §4 ShopWindow + Context + Animate + hooks; screen replacement with SAME rows Slot ==")
local Theme = q.Context.Provider and q.Context.Provider("Theme")
local log = {}
local function ShopTree()
	return foreign({ "Frame", name = "ShopWindow", children = {
		{ "TextButton", name = "CloseButton" },
		{ "TextLabel", name = "TitleText" },
		{ "Frame", name = "ContentArea", children = { { "UIListLayout" } } },
	} })
end
local function ShopWindow(isOpen, rows2)
	local window = ShopTree()
	track("B3.window", window)
	q.Claim(window, M.Frame(M.Root)({
		M.TextButton("CloseButton")({ Activated = function() isOpen:Set(false) end }),
		M.TextLabel("TitleText")({}),
		M.Frame("ContentArea")({ rows2 }),
		Visible = isOpen,
		q.OnCreated(function(i) table.insert(log, "C " .. i.Name .. " kids=" .. #i:GetChildren()) end),
		q.OnRendered(function(i) table.insert(log, "R " .. i.Name) end),
		q.OnDestroyed(function() table.insert(log, "D") end),
	}))
	return window
end
local isOpen = q.Source(true)
local data = q.Source({ "a", "b" })
local shopRows = q.Slot():List(data, function(ctx)
	if ctx.Item == q.KeyGone then return nil, ctx.UserData end
	if ctx.Prev then return ctx.Prev, ctx.UserData end
	return D.TextLabel { Name = ctx.Item, Text = ctx.Item }, nil
end)
local shopRows2 = q.Slot():List(q.Source({ "p" }), function(ctx)
	if ctx.Item == q.KeyGone then return nil, ctx.UserData end
	if ctx.Prev then return ctx.Prev, ctx.UserData end
	return D.TextLabel { Name = ctx.Item }, nil
end)
local w1 = ShopWindow(isOpen, shopRows)
P("w1 content kids", #w1:FindFirstChild("ContentArea"):GetChildren(), "log", table.concat(log, "|"))
w1:FindFirstChild("CloseButton").Activated:Fire()
P("Close → Visible", w1.Visible)
w1:Destroy()
P("after w1 Destroy: log", table.concat(log, "|"), "isOpen subs", subs(isOpen))
try("reopen: ShopWindow(isOpen, SAME rows Slot) after old window destroyed", function()
	isOpen:Set(true)
	local w2 = ShopWindow(isOpen, shopRows)
	P("  w2 content kids", #w2:FindFirstChild("ContentArea"):GetChildren())
	data:Set({ "a", "b", "c" })
	P("  w2 content kids after data", #w2:FindFirstChild("ContentArea"):GetChildren())
	w2:Destroy()
end)
try("reopen after q.dispose(old window) with SAME rows Slot", function()
	local wa = ShopWindow(isOpen, shopRows2)
	q.dispose(wa)
	local wb = ShopWindow(isOpen, shopRows2)
	P("  wb content kids", #wb:FindFirstChild("ContentArea"):GetChildren())
	wb:Destroy()
end)
try("reopen after Extract-ing the Slot? (rows is the Slot itself — no API to unseat a nested Slot from a claimed ContentArea)", function() end)
try("replace WITHOUT destroying old (w3 while w2b alive)", function()
	local w2b = ShopWindow(isOpen, q.Slot())
	local s = q.Slot()
	local w3 = ShopWindow(isOpen, s)
	w2b:Destroy(); w3:Destroy()
end)
w1 = nil
P("alive B3", alive("B3"), "isOpen subs", subs(isOpen))

P("== B4 partial ownership: mapped + unmapped grandchildren; dispose/Destroy order ==")
local function PartTree()
	return foreign({ "Frame", name = "Root", children = {
		{ "Frame", name = "A", children = { { "TextLabel", name = "Deep" } } },
		{ "Frame", name = "B" },
	} })
end
local pr = PartTree()
local deep = pr:FindFirstChild("A"):FindFirstChild("Deep")
local vis = q.Source(true)
local slotA = q.Slot()
q.Claim(pr, M.Frame(M.Root)({ M.Frame("A")({}), M.Frame("B")({ Visible = vis, slotA }) }))
slotA:Add(D.TextLabel { Name = "X" })
P("B kids", #pr:FindFirstChild("B"):GetChildren(), "Deep claimed?", q.Backend.isClaimed(deep))
try("q.dispose(mapped child A)", function() q.dispose(pr:FindFirstChild("A")) end)
try("q.dispose(unmapped grandchild Deep)", function() q.dispose(deep) end)
P("Deep destroyed?", mock.isDestroyed(deep))
try("q.dispose(root)", function() q.dispose(pr) end)
P("root destroyed?", mock.isDestroyed(pr), "slot element count", slotA.Length and slotA.Length:Get())
vis:Set(false)
P("vis subs after root dispose", subs(vis))
try("slotA:Add after host dispose", function() slotA:Add(D.TextLabel { Name = "Y" }) end)
try("re-Claim the disposed root (UB H-293 expected Quad0029/Quad0225?)", function() q.Claim(pr, M.Frame(M.Root)({})) end)

P("== B5 Out inside a claimed tree ==")
local txt = q.Source("init")
local form = foreign({ "Frame", children = { { "TextBox", name = "Input" } } })
local outFires = 0
local keepObs = txt:Observer(function() outFires += 1 end); keepObs:Subscribe()
q.Claim(form, M.Frame(M.Root)({ M.TextBox("Input")({ Text = txt, q.Out("Text", txt) }) }))
local before = outFires
form:FindFirstChild("Input").Text = "typed"
P("typed → src", txt:Get(), "observer runs from typing", outFires - before)
txt:Set("fromCode"); P("code → box", form:FindFirstChild("Input").Text)
local input = form:FindFirstChild("Input")
form:Destroy()
input.Text = "afterDeath"
P("after Destroy: src", txt:Get())

P("== B6 apply-phase throw inside Claim then retry with a FRESH clone ==")
local srcB6 = q.Source("v")
local bad = ItemCardTree()
try("claim with bad prop on 2nd child", function()
	q.Claim(bad, M.Frame(M.Root)({
		M.TextLabel("ItemName")({ Text = srcB6, q.Out("Text", srcB6) }),
		M.ImageLabel("ItemIcon")({ Nope = 1 }),
		M.TextButton("ActionButton")({}),
	}))
end)
P("  after throw: isClaimed root", q.Backend.isClaimed(bad), "subs srcB6", subs(srcB6))
local good = ItemCardTree()
q.Claim(good, M.Frame(M.Root)({
	M.TextLabel("ItemName")({ Text = srcB6, q.Out("Text", srcB6) }),
	M.ImageLabel("ItemIcon")({}),
	M.TextButton("ActionButton")({}),
}))
P("  fresh clone ok; subs", subs(srcB6))
bad:Destroy()
P("  after destroying the half-applied clone: subs", subs(srcB6))
