-- E73 discriminating probe (quad-roblox over mock instances — the REAL LifetimeHandle/EngineOps/Property).
-- Not a spec. Copied into quad-roblox/test/ by probe_survivors.py. Harness = spec.tweenproperty + spec.timers shims.
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local installEngineOps = require("../src/EngineOps")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local collectgarbage = (_G :: any).collectgarbage :: (any?) -> ()

local W = { Write = "" }
local REFLECTED = {
	Frame = { { Name = "Name", Permits = W }, { Name = "Size", Permits = W } },
	TextLabel = { { Name = "Name", Permits = W }, { Name = "Text", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local taskShim = { delay = function(_d, fn) return coroutine.create(fn) end, cancel = function(_th) end }
;(getfenv(installEngineOps) :: any).task = taskShim
local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installProperty) :: any).TweenInfo = mock.tweenInfoShim
;(getfenv(installProperty) :: any).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local D, M = q.Declaration, q.Declaration.Mapper
local fails = {}
local function check(c, m) if not c then table.insert(fails, m) end end
local function errOf(f) local ok, e = pcall(f); return if ok then "<no error>" else tostring(e) end
local function has(e, code) return string.find(e, code, 1, true) ~= nil end

-- PR10 (item 2a): Info-less Time = 0 WITH Reverses keeps the engine tween (docs roblox/06 "그 셋 중 하나라도 있으면")
do
	mock.resetTweenLog()
	local src = q.Source(0 :: any)
	local f = D.Frame({ Size = src }) :: any
	src:Set(q.Tween({ Value = 5, Time = 0, Reverses = true }))
	check(#mock.tweenLog == 1, "PR10a engine tween created for Time=0+Reverses: " .. #mock.tweenLog)
	check(f.Size == 0, "PR10b no snap (mock does not interpolate): " .. tostring(f.Size))
	mock.resetTweenLog()
	src:Set(q.Tween({ Value = 6, Time = 0, RepeatCount = 2 }))
	check(#mock.tweenLog == 1, "PR10c engine tween for Time=0+RepeatCount: " .. #mock.tweenLog)
end

-- EO12: NaN delay is rejected with the documented code
do
	local e = errOf(function() q.Backend.setTimeout(function() end, 0 / 0) end)
	check(has(e, "Quad0216"), "EO12 NaN delay: " .. e)
end

-- LR03/LR06/LR08: nil / unclaimed inputs to the public hold predicates answer false, not raise
do
	check(errOf(function() assert(q.Backend.isClaimed(nil) == false) end) == "<no error>", "LR03 isClaimed(nil)")
	check(errOf(function() assert(q.Backend.isHeld(nil) == false) end) == "<no error>", "LR06 isHeld(nil)")
	check(q.Backend.isHeldBy({}, Instance.new("Frame")) == false, "LR08 isHeldBy(unheld, unclaimed) must be false")
end

-- LR10/LR12/LR13: bindLifetime keeps the value alive; unbind releases it early and forgets the holder
do
	local inst = D.Frame({}) :: any
	local src = q.Source(0)
	local fired = 0
	do
		local o = src:Observer(function() fired += 1 end)
		q.Backend.bindLifetime(inst, o)
	end
	collectgarbage("collect"); collectgarbage("collect")
	local f0 = fired
	src:Set(1)
	check(fired == f0 + 1, "LR10 bound observer survived GC and fired: " .. (fired - f0))

	local weak = setmetatable({}, { __mode = "v" })
	do
		local o2 = src:Observer(function() end)
		q.Backend.bindLifetime(inst, o2)
		check(q.Backend.isHeldBy(o2, inst), "LR13a held after bind")
		q.Backend.unbindLifetime(o2)
		check(not q.Backend.isHeldBy(o2, inst), "LR13 isHeldBy after unbind must be false")
		weak[1] = o2
	end
	collectgarbage("collect"); collectgarbage("collect")
	check(weak[1] == nil, "LR12 unbound value collectible while inst lives")
	local _ = inst
end

-- DC02: generated DefineSubtype edge GuiObject -> ScrollingFrame
do
	local e = errOf(function() return D.Modifier.GuiObject():AsScrollingFrame() end)
	check(e == "<no error>", "DC02 GuiObject():AsScrollingFrame(): " .. e)
end

-- Claim gates
local function tmpl()
	local root = Instance.new("Frame")
	local t = Instance.new("TextLabel"); t.Name = "Title"; t.Parent = root
	return root, t
end
do -- CL06: a descriptor under a hash key
	local root = tmpl()
	local e = errOf(function() q.Claim(root, M.Frame(M.Root)({ Foo = M.TextLabel("Title")({}) })) end)
	check(not has(e, "attempt to compare"), "CL06 hash-key descriptor: " .. e)
end
do -- CL07: a fractional array key rejected in the validating pass (root stays unclaimed)
	local root = tmpl()
	local e = errOf(function() q.Claim(root, M.Frame(M.Root)({ [1.5] = M.TextLabel("Title")({}) })) end)
	check(has(e, "Quad0031"), "CL07 fractional key: " .. e)
	check(not q.Backend.isClaimed(root), "CL07b root not claimed after a pass-1 failure")
end
do -- CL15: non-descriptor second argument
	local root = tmpl()
	local e = errOf(function() q.Claim(root, { _props = {} }) end)
	check(has(e, "Quad0034"), "CL15 plain table desc: " .. e)
end
do -- CL16: empty class name
	local e = errOf(function() q.newMapperClass("") end)
	check(has(e, "Quad0026"), "CL16 empty className: " .. e)
end
do -- CL17: bottom-up drive order — the child's props are applied before the parent's PostRef fires
	local root = tmpl()
	local order = {}
	q.Claim(root, M.Frame(M.Root)({
		q.OnRendered(function() table.insert(order, "root") end),
		M.TextLabel("Title")({ q.OnRendered(function() table.insert(order, "child") end) }),
	}))
	check(order[1] == "child" and order[2] == "root", "CL17 drive order: " .. table.concat(order, ","))
end

if #fails == 0 then print("PROBE ALL OK") else for _, f in fails do print("FAIL " .. f) end end
