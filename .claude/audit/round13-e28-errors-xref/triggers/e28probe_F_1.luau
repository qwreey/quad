local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")
local Instance = mock.Instance
local q: any = Quad.New():UseProvider(QuadRoblox)
q.Backend.isInst = mock.isMockInstance
local function try(label, f)
	local ok, err = pcall(f)
	print(label, ok, err)
end
-- 1. Effect placed on unclaimed inst via Dispatch.process
local foreign = Instance.new("Frame")
try("effect-on-unclaimed", function()
	local e = q.Effect(function() end)
	q.Dispatch.process(foreign, 1, e, 1)
end)
-- 2. direct holdLifetime on unclaimed
try("holdLifetime-direct", function()
	q.Backend.holdLifetime(Instance.new("Frame"), {})
end)
-- 3. setTimeout negative
try("setTimeout-neg", function() q.Backend.setTimeout(function() end, -1) end)
-- 4. Claim a destroyed quad instance pre-GC
local inst = Instance.new("Frame")
q.Backend.nativeClaim(inst)
inst:Destroy()
try("claim-destroyed", function() q.Claim(inst, {}) end)
-- 5. Animate with a State as info
try("animate-state-info", function() q.Animate(q.Source({ Time = 1 })) end)
-- 6. Mapped returning nil
try("mapped-nil", function() q.Tween({ Value = 1 }):Mapped(function() return nil end) end)
-- 7. Out with Store?
try("out-number", function() q.Out("Text", 5) end)
