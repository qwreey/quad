--!nocheck
-- E48 separate axes (a)~(h). Each case prints one line: [axis] name: observed.
local H = require("./harness")
local Instance, idOf, mock = H.Instance, H.idOf, H.mock
local q = H.newQ()
local M, D = q.Declaration.Mapper, q.Declaration

local function line(axis, name, v) print(`[{axis}] {name}: {v}`) end
local function try(f, ...)
	local ok, e = pcall(f, ...)
	return ok and "ok" or idOf(e), e
end
local function tpl()
	local root = Instance.new("Frame"); root.Name = "Root"
	local title = Instance.new("TextLabel"); title.Name = "Title"; title.Parent = root
	local list = Instance.new("Frame"); list.Name = "List"; list.Parent = root
	local inner = Instance.new("TextLabel"); inner.Name = "Inner"; inner.Parent = list
	return root, title, list, inner
end
local C = q.Backend.isClaimed

-- (a) partial failure → re-Claim
do
	local root, title, list, inner = tpl()
	local d = M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "x" }), M.Frame("List")({ M.TextLabel("Nope")({}) }) })
	line("a", "pass-1 failure", try(q.Claim, root, d))
	line("a", "  claimed root/title/list after", `{C(root)}/{C(title)}/{C(list)} fired={d._fired}`)
	inner.Name = "Nope"
	line("a", "  same descriptor after fixing the tree", try(q.Claim, root, d))
	line("a", "  title.Text", title.Text)
end
do
	-- pass-2 (drive) failure: documented exception (roblox/04:107)
	local root, title = tpl()
	local d = M.Frame(M.Root)({ M.TextLabel("Title")({ Text = "x" }), BackgroundTransparency = 0.5, Bogus = 1 })
	local r, e = try(q.Claim, root, d)
	line("a", "pass-2 (drive) failure", r .. " | " .. tostring(e):gsub("\n.*", ""):sub(1, 110))
	line("a", "  claimed root/title, title.Text, fired", `{C(root)}/{C(title)} {title.Text} {d._fired}`)
	line("a", "  fixed retry with fresh descriptor", try(q.Claim, root, M.Frame(M.Root)({ M.TextLabel("Title")({}) })))
end
do
	-- Q85 residue re-confirm: descriptor at a STRING key passes pass 1
	local root, title = tpl()
	local d = M.Frame(M.Root)({ Title = M.TextLabel("Title")({ Text = "s" }) })
	line("a", "descriptor at string key (Q85 known)", (try(q.Claim, root, d)) .. ` root claimed={C(root)}`)
end

-- (b) after Claim: Slot element / dispose / parent Destroy chain
do
	local root, title, list, inner = tpl()
	local src = q.Source("s0")
	local runs = 0
	q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = src }), M.Frame("List")({ M.TextLabel("Inner")({ q.Effect(function() runs += 1 end) }) }) }))
	local host = D.Frame({})
	local slot = q.Slot()
	D.Frame({ slot })
	line("b", "slot:Add(mapped child)", try(function() slot:Add(title) end))
	line("b", "D.Frame{ mapped child } (static)", try(function() D.Frame({ inner }) end))
	line("b", "q.dispose(mapped child)", try(q.dispose, title))
	src:Set("s1")
	line("b", "  title.Text after failed dispose", title.Text)
	-- dispose the root: whole tree destroyed, claims drop, reactive edges inert
	line("b", "q.dispose(root)", try(q.dispose, root))
	line("b", "  destroyed root/title/inner", `{mock.isDestroyed(root)}/{mock.isDestroyed(title)}/{mock.isDestroyed(inner)} claimed={C(root)}/{C(title)}`)
	line("b", "  src:Set after dispose", try(function() src:Set("s2") end) .. ` title.Text={title.Text}`)
	local _ = host
end
do
	local root, title = tpl()
	local src = q.Source(1)
	q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({ Text = src:Compute(function(self) return tostring(src:Get()) end) }) }))
	root:Destroy()
	line("b", "root:Destroy() → claimed title", tostring(C(title)))
	line("b", "  src:Set after Destroy", try(function() src:Set(2) end) .. ` title.Text={title.Text}`)
	line("b", "  Claim the dead root again (UB §7-13)", try(q.Claim, root, M.Frame(M.Root)({})))
end
do
	-- a Slot element parked inside a template (slot-hosted, claimed) → mapped → 0029
	local slot = q.Slot()
	local host = D.Frame({ slot })
	local el = D.Frame({ Name = "Kid" })
	slot:Add(el)
	local root = Instance.new("Frame")
	el.Parent = root -- raw move (user hack) — the element is still quad-owned
	line("b", "Slot element parked in template, mapped", try(q.Claim, root, M.Frame(M.Root)({ M.Frame("Kid")({}) })))
	line("b", "  root claimed after", tostring(C(root)))
	local _ = host
end

-- (c) descriptor reuse
do
	local rA = tpl(); local rB = tpl()
	local d = M.Frame(M.Root)({ M.TextLabel("Title")({}) })
	line("c", "first Claim", try(q.Claim, rA, d))
	line("c", "same root desc, other tree", try(q.Claim, rB, d))
	local rC = tpl()
	local child = M.TextLabel("Title")({})
	line("c", "same child desc at two slots", try(q.Claim, rC, M.Frame(M.Root)({ child, child })) .. ` claimed={C(rC)}`)
	local rD = tpl()
	local self_ = M.Frame(M.Root)({})
	table.insert(self_._props, self_)
	line("c", "desc nested in itself", try(q.Claim, rD, self_))
	local rE = tpl()
	local rootDesc = M.Frame(M.Root)({ M.TextLabel("Missing")({}) })
	line("c", "failed pass 1 then same desc on a good tree", try(q.Claim, rE, rootDesc) .. " → " .. try(q.Claim, rE, (function() rootDesc._props[1] = M.TextLabel("Title")({}); return rootDesc end)()))
	-- a child descriptor of a consumed tree used as a ROOT elsewhere
	local rF = tpl()
	local kid = M.TextLabel("Title")({})
	q.Claim(rF, M.Frame(M.Root)({ kid }))
	line("c", "consumed child desc as another root", try(q.Claim, Instance.new("TextLabel"), kid))
	-- child desc used at ROOT of one Claim and child of another (fresh)
	local kid2 = M.Frame("List")({})
	local rG = tpl()
	line("c", "keyed desc at root (key ignored)", try(q.Claim, (select(3, tpl())), kid2) .. " then as child: " .. try(q.Claim, rG, M.Frame(M.Root)({ kid2 })))
end

-- (d) names
do
	for _, nm in { ".", "a.b", "", "1", " ", "Title ", "a/b", "日本" } do
		local root = Instance.new("Frame")
		local c = Instance.new("TextLabel"); c.Name = nm; c.Parent = root
		local r = try(q.Claim, root, M.Frame(M.Root)({ M.TextLabel(nm)({ Text = "ok" }) }))
		line("d", `name {string.format("%q", nm)}`, r .. ` text={c.Text}`)
	end
	local root = Instance.new("Frame")
	local c = Instance.new("TextLabel"); c.Name = "1"; c.Parent = root
	line("d", 'number key 1 vs child "1" (mock)', try(q.Claim, root, M.Frame(M.Root)({ M.TextLabel(1)({}) })) .. ` root claimed={C(root)}`)
	local root2 = Instance.new("Frame")
	line("d", "boolean key true", try(q.Claim, root2, M.Frame(M.Root)({ M.TextLabel(true)({}) })))
	line("d", "MapperRoot as child key", try(q.Claim, Instance.new("Frame"), M.Frame(M.Root)({ M.TextLabel(q.MapperRoot)({}) })))
	line("d", "nil key", try(q.Claim, Instance.new("Frame"), M.Frame(M.Root)({ M.TextLabel(nil)({}) })))
	-- rename after resolve? the name is read once in pass 1
	local r3, t3 = tpl()
	line("d", "Name in mapped child's props (rename)", try(q.Claim, r3, M.Frame(M.Root)({ M.TextLabel("Title")({ Name = "Renamed" }) })) .. ` name={t3.Name}`)
end

-- (e) class hierarchy (mock IsA = equality)
do
	local root, title = tpl()
	line("e", 'newMapperClass("GuiObject") child over a TextLabel (mock)', try(q.Claim, root, M.Frame(M.Root)({ q.newMapperClass("GuiObject")("Title")({}) })))
	local root2 = tpl()
	line("e", "root M.TextLabel over a Frame (Q84 known)", try(q.Claim, root2, M.TextLabel(M.Root)({})) .. ` claimed={C(root2)}`)
	local root3 = tpl()
	line("e", 'root newMapperClass("GuiObject") over a Frame', try(q.Claim, root3, q.newMapperClass("GuiObject")(q.MapperRoot)({ BackgroundTransparency = 0.3 })) .. ` bt={root3.BackgroundTransparency}`)
end

-- (f) OnChange / Out / Tween on a mapped child
do
	local root, title = tpl()
	local seen = {}
	local out = q.Source("init")
	local tw = q.Source(q.Tween({ Value = 0.5, Time = 1 }))
	mock.resetTweenLog()
	q.Claim(root, M.Frame(M.Root)({
		M.TextLabel("Title")({
			q.OnChange("Text", function(v) table.insert(seen, v) end),
			q.Out("Text", out),
			BackgroundTransparency = tw,
		}),
	}))
	title.Text = "typed"
	tw:Set(q.Tween({ Value = 0.9, Time = 1 }))
	line("f", "OnChange fired", table.concat(seen, ","))
	line("f", "Out source", out:Get())
	line("f", "tweens created on mapped child", `{#mock.tweenLog} inst={mock.tweenLog[1] and mock.tweenLog[1].inst == title}`)
end

-- (g) two module instances
do
	local qB = H.newQ()
	local root, title = tpl()
	q.Claim(root, M.Frame(M.Root)({ M.TextLabel("Title")({}) }))
	line("g", "B.Claim of an A-claimed root", try(qB.Claim, root, qB.Declaration.Mapper.Frame(qB.MapperRoot)({})) .. ` B.isClaimed={qB.Backend.isClaimed(root)}`)
	local r2 = tpl()
	line("g", "B.Claim with an A-made descriptor", try(qB.Claim, r2, M.Frame(M.Root)({})))
	local r3 = tpl()
	line("g", "A.MapperRoot == B.MapperRoot", tostring(q.MapperRoot == qB.MapperRoot))
	local src = q.Source("A")
	local r, e = try(qB.Claim, r3, qB.Declaration.Mapper.Frame(qB.MapperRoot)({ qB.Declaration.Mapper.TextLabel("Title")({ Text = src }) }))
	line("g", "B.Claim with an A.Source in child props", r .. ` root claimed by B={qB.Backend.isClaimed(r3)} fired-left`)
	local r4, t4 = tpl()
	local aKid = D.TextLabel({ Name = "Kid" }); aKid.Parent = r4
	line("g", "B.Claim mapping an A-made (D.New) child", try(qB.Claim, r4, qB.Declaration.Mapper.Frame(qB.MapperRoot)({ qB.Declaration.Mapper.TextLabel("Kid")({ Text = "b" }) })) .. ` A.isClaimed={C(aKid)} B.isClaimed={qB.Backend.isClaimed(aKid)}`)
end

-- (h) performance
do
	local function bench(label, n, mapAll)
		local root = Instance.new("Frame")
		local items = {}
		for i = 1, n do
			local c = Instance.new("TextLabel"); c.Name = "c" .. i; c.Parent = root
			if mapAll then items[i] = M.TextLabel("c" .. i)({ Text = "t" }) end
		end
		local t = os.clock()
		q.Claim(root, M.Frame(M.Root)(items))
		line("h", label, string.format("%.1f ms", (os.clock() - t) * 1000))
	end
	bench("1000 children, root only", 1000, false)
	bench("1000 children, all mapped", 1000, true)
	bench("2000 children, all mapped", 2000, true)
	bench("4000 children, all mapped", 4000, true)
	-- deep chain
	local root = Instance.new("Frame"); local cur = root
	for i = 1, 200 do local c = Instance.new("Frame"); c.Name = "n"; c.Parent = cur; cur = c end
	local function chain(k) if k == 0 then return {} end return { M.Frame("n")(chain(k - 1)) } end
	local t = os.clock()
	local r = try(q.Claim, root, M.Frame(M.Root)(chain(200)))
	line("h", "depth-200 chain", r .. string.format(" %.1f ms", (os.clock() - t) * 1000))
end
