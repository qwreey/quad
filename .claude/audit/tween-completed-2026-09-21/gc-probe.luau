--[[ GC probe for Tween callbacks (round12 Q71 follow-up, 2026-09-21 evening, user: "gc문제가 우려되는데").
     Run: copy next to quad-roblox/test/spec.tweenproperty.luau (any name NOT spec.*), `./scripts/relink.sh`, then
     `cd quad-roblox/test && luau <file>`. Lines 12-45 of that spec are the CLI shim (requires + getfenv shims). ]]
local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local mock = require("../../quad-base/test/mock")
local _Instance = mock.Instance

local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = {
		{ Name = "Name", Permits = W },
		{ Name = "Size", Permits = W },
		{ Name = "Position", Permits = W },
		{ Name = "BackgroundTransparency", Permits = W },
	},
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
;(getfenv(installProperty) :: any).game = gameShim
;(getfenv(installProperty) :: any).TweenInfo = mock.tweenInfoShim
-- `H-333`: absent convenience fields are filled with the engine defaults — the
-- enum defaults come from the `Enum` global, shimmed here with plain markers
;(getfenv(installProperty) :: any).Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance

local Tween = q.Tween
local collectgarbage = (_G :: any).collectgarbage :: () -> ()
local log = mock.tweenLog
local function lastTween(): any
	return log[#log].tween
end

local Tween = q.Tween
local weak = setmetatable({}, { __mode = "v" })
local function gcFull() for _ = 1, 5 do collectgarbage("collect") end end
local function mkCallbacks(cap: any)
	local captured = cap -- own upvalue: a later `cap = nil` in the caller must not clear it (REPORT 7·8 lesson)
	return function() return captured end, function() return captured end
end
local function probe(name: string, withCallbacks: boolean, after: (any) -> (), settle: (any, any) -> ())
	local src = q.Source(0 :: any)
	local inst = q.Declaration.Frame({ Size = src }) :: any
	src:Set(Tween({ Value = 1, Time = 0.3 }))
	local cap = { name }
	local v: any
	if withCallbacks then
		local onC, onX = mkCallbacks(cap)
		v = Tween({ Value = 2, Time = 0.3, Completed = onC, Cancelled = onX })
	else
		v = Tween({ Value = 2, Time = 0.3 })
	end
	src:Set(v)
	local t = lastTween()
	weak[name .. ":value"] = v
	weak[name .. ":cap"] = cap
	weak[name .. ":tween"] = t
	weak[name .. ":inst"] = inst
	settle(inst, t)
	src:Set(0) -- the State no longer holds v
	after(inst)
	v = nil; cap = nil; t = nil; inst = nil
	mock.resetTweenLog() -- the mock log holds every tween (and its inst) strongly — not quad
	gcFull()
	local left = {}
	for _, k in { "value", "cap", "tween", "inst" } do
		if weak[name .. ":" .. k] ~= nil then table.insert(left, k) end
	end
	print(string.format("%-28s callbacks=%-5s still alive: %s", name, tostring(withCallbacks), if #left == 0 then "(none)" else table.concat(left, ",")))
end
local teardown = function(inst) q.Dispatch.retractFrom(inst, "Size", 1); inst:Destroy() end
local destroyOnly = function(inst) inst:Destroy() end
local keep = function(_) end
for _, cb in { false, true } do
	probe("A-complete-then-teardown", cb, teardown, function(_, t) t:simulateCompleted() end)
	probe("B-replace(Cancelled)-teardown", cb, teardown, function() end)
	probe("C-destroy-late-complete", cb, destroyOnly, function(inst, t) inst:Destroy(); t:simulateCompleted() end)
	probe("D-destroy-no-notice", cb, destroyOnly, function(inst, _) inst:Destroy() end)
	probe("E-complete-inst-kept", cb, keep, function(_, t) t:simulateCompleted() end)
end
