--!nocheck
-- E35: trigger every q.debug branch, with debug off (expect silence) and on (expect one line), same outcome.
local H = require("./harness")
local mock = require("../../../quad-base/test/mock")
local q, D = H.q, H.D
local M = q.Declaration.Mapper
UDim2 = H.EG.UDim2

local function case(label, fn)
	for _, dbg in { false, true } do
		q.debug = dbg
		print(`--- [{label}] debug={dbg} BEGIN`)
		local ok, err = pcall(fn)
		print(`--- [{label}] debug={dbg} END ok={ok}` .. (if ok then "" else " err=" .. H.first(err)))
	end
	q.debug = false
end

-- 1. AddPlugin overwrite (fresh module each run so we don't clobber q)
case("AddPlugin overwrite", function()
	local m = q.New()
	m.debug = q.debug
	local same = m.Source
	m:AddPlugin(function() return { Source = same, Relate = function() end } end)
	print("  Relate replaced:", m.Relate ~= q.Relate)
end)

-- 2. Dispatch tie
case("Dispatch tie", function()
	local m = q.New()
	m.debug = q.debug
	local function mk(name, kt)
		return { name = name, priority = 7777, keyType = kt,
			isHandlable = function() return false end, process = function() end }
	end
	m.Dispatch.addHandler(mk("A", nil))
	m.Dispatch.addHandler(mk("B", nil))
	m.Dispatch.addHandler(mk("C-number", "number"))
end)
case("Dispatch tie across keyTypes (expect silence)", function()
	local m = q.New()
	m.debug = q.debug
	local function mk(name, kt)
		return { name = name, priority = 8888, keyType = kt,
			isHandlable = function() return false end, process = function() end }
	end
	m.Dispatch.addHandler(mk("S", "string"))
	m.Dispatch.addHandler(mk("N", "number"))
end)

-- 3. Debounce / Throttle unknown key
case("Debounce unknown", function()
	local g = q.Debounce({ Time = 0.1, Tme = 1 })
	print("  typeof:", typeof(g))
end)
case("Throttle unknown", function()
	local g = q.Throttle({ Time = 0.1, Leadng = true })
	print("  typeof:", typeof(g))
end)

-- 4. Slot:List / :Single opts
case("Slot:List Owned (old name)", function()
	local s = q.Slot()
	s:List(q.Source({ 1, 2 }), function(ctx) return D.Frame {} end, nil, { Owned = false })
	print("  owned field:", s._owned)
end)
case("Slot:Single unknown", function()
	local s = q.Slot()
	s:Single(q.Source(1), function(ctx) return D.Frame {} end, { Ownselements = false })
	print("  owned field:", s._owned)
end)

-- 5. Tween / Animate unknown
case("Tween unknown", function()
	local t = q.Tween({ Value = 1, Time = 0.2, Duration = 3, Easing = "Linear" })
	print("  tween ok:", t ~= nil)
end)
case("Animate unknown", function()
	local a = q.Animate({ Time = 0.2, Duration = 3 })
	print("  animate ok:", a ~= nil)
end)

-- 6. Claim root key ignored
case("Claim root key", function()
	local root = mock.Instance.foreign("Frame")
	local out = q.Claim(root, M.Frame("SomeName")({ BackgroundTransparency = 0.5 }))
	print("  claimed root itself:", out == root, root.BackgroundTransparency)
end)
-- 7. Claim child key non-string (M.Root in child slot)
case("Claim child key M.Root", function()
	local root = mock.Instance.foreign("Frame")
	local c = mock.Instance.foreign("TextLabel"); c.Name = "T"; c.Parent = root
	q.Claim(root, M.Frame(M.Root)({ M.TextLabel(M.Root)({}) }))
end)
case("Claim child key number", function()
	local root = mock.Instance.foreign("Frame")
	q.Claim(root, M.Frame(M.Root)({ M.TextLabel(5)({}) }))
end)
