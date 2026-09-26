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

local function rec(order) return function(tag) return {
	Started = function() table.insert(order, tag..":S") end,
	Completed = function() table.insert(order, tag..":C") end,
	Cancelled = function() table.insert(order, tag..":X") end,
} end end
local function tw(opts, cb) if cb then for k,v in cb do opts[k]=v end end return Tween(opts) end

print("--- P1 Reverses=true pulse re-trigger (Tween-in-State) ---")
do
	mock.resetTweenLog()
	local pulse = q.Source(1 :: any)
	local f = q.Declaration.Frame({ Size = pulse }) :: any
	pulse:Set(Tween({ Value = 2, Time = 0.2, Reverses = true }))
	print("after click1: creates", #log)
	local t1 = lastTween()
	t1:simulateCompleted(); f.Size = 1 -- engine: Reverses=true rests at the START value (tween-plan 4순회 캐비엇)
	pulse:Set(Tween({ Value = 2, Time = 0.2, Reverses = true }))
	print("after click2: creates", #log, "Size", f.Size)
end

print("--- P1b Reverses via Animate: same Source value never re-emits, but Animate over a Compute ---")
do
	mock.resetTweenLog()
	local n = q.Source(0)
	local f = q.Declaration.Frame({ Size = n:Compute(function(h) return if h:Get() % 2 == 1 then 2 else 1 end):Apply(q.Animate({ Time = 0.2, Reverses = true })) }) :: any
	n:Set(1); print("to 2 creates", #log)
	lastTween():simulateCompleted(); f.Size = 1
	n:Set(2); print("to 1 creates", #log)
end

print("--- P2 external write then same-target Tween (scroll-to-top) ---")
do
	mock.resetTweenLog()
	local scroll = q.Source(5 :: any)
	local f = q.Declaration.Frame({ Size = scroll }) :: any
	scroll:Set(Tween({ Value = 0, Time = 0.2 }))
	lastTween():simulateCompleted(); f.Size = 0
	f.Size = 40 -- user scrolls (engine writes the property)
	scroll:Set(Tween({ Value = 0, Time = 0.2 }))
	print("completed record + external write: creates", #log, "Size", f.Size)
	-- snapped record variant
	mock.resetTweenLog()
	local s2 = q.Source(Tween({ Value = 0, Time = 0.2 }) :: any)
	local g = q.Declaration.Frame({ Size = s2 }) :: any
	g.Size = 40
	s2:Set(Tween({ Value = 0, Time = 0.2 }))
	print("snapped record + external write: creates", #log, "Size", g.Size)
	-- plain slot comparison
	local s3 = q.Source(0 :: any)
	local h = q.Declaration.Frame({ Size = s3 }) :: any
	h.Size = 40
	s3:Set(0) print("plain Source same value re-set: Size", h.Size)
end

print("--- P3 throwing Cancelled then same target (UB observe) ---")
do
	mock.resetTweenLog()
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = s }) :: any
	s:Set(Tween({ Value = 10, Time = 0.3, Cancelled = function() error("boom") end }))
	f.Size = 4
	print("throw:", pcall(function() s:Set(Tween({ Value = 20, Time = 0.3 })) end))
	s:Set(Tween({ Value = 10, Time = 0.3 }))
	print("after throw, same old target: creates", #log, "Size", f.Size)
	-- teardown throw variant
	mock.resetTweenLog()
	local g = q.Declaration.Frame({ Size = 0 }) :: any
	q.Dispatch.drive(g, { Size = Tween({ Value = 10, Time = 0.3, Cancelled = function() error("boom2") end }) })
	g.Size = 3
	print("retract throw:", pcall(function() q.Dispatch.retractFrom(g, "Size", 1) end))
	q.Dispatch.drive(g, { Size = Tween({ Value = 10, Time = 0.3 }) })
	print("re-drive same target: creates", #log, "Size", g.Size)
end

print("--- P4 shared Animate factory on two props / two insts ---")
do
	mock.resetTweenLog()
	local order = {}
	local A = q.Animate({ Time = 0.2, Completed = function() table.insert(order, "C") end })
	local s = q.Source(0)
	local f1 = q.Declaration.Frame({ Size = s:Apply(A), Position = s:Apply(A) }) :: any
	local f2 = q.Declaration.Frame({ Size = s:Apply(A) }) :: any
	s:Set(1)
	print("creates", #log)
	for _, e in log do e.tween:simulateCompleted() end
	print("completed calls", #order)
end

print("--- P5 Parent=nil (not destroyed) then completes ---")
do
	mock.resetTweenLog()
	local order = {}
	local par = q.Declaration.Frame({}) :: any
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = s }) :: any
	f.Parent = par
	s:Set(Tween({ Value = 1, Time = 0.3, Completed = function() table.insert(order, "C") end }))
	f.Parent = nil
	lastTween():simulateCompleted()
	print("parent=nil completed fires", #order)
	-- destroy the PARENT (descendant destroyed)
	table.clear(order)
	f.Parent = par
	s:Set(Tween({ Value = 2, Time = 0.3, Completed = function() table.insert(order, "C") end }))
	par:Destroy()
	lastTween():simulateCompleted()
	print("ancestor destroyed completed fires", #order)
end

print("--- P6 deferred window + Dedup same target ---")
do
	mock.resetTweenLog()
	local order = {}
	local mk = rec(order)
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = s }) :: any
	s:Set(tw({ Value = 5, Time = 0.3 }, mk("a")))
	local a = lastTween()
	a.PlaybackState = "Completed" -- reached target, notice queued
	f.Size = 5
	s:Set(tw({ Value = 5, Time = 0.3 }, mk("b")))
	print("dedup inside window order:", table.concat(order, ","))
	a.Completed:Fire("Completed")
	print("after late notice:", table.concat(order, ","))
end

print("--- P7 None -> value -> None with running tween + callbacks ---")
do
	mock.resetTweenLog()
	local order = {}
	local mk = rec(order)
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = s }) :: any
	s:Set(tw({ Value = 5, Time = 0.3 }, mk("a")))
	s:Set(q.None)
	s:Set(tw({ Value = 5, Time = 0.3 }, mk("b")))
	s:Set(q.None)
	print("order", table.concat(order, ","), "creates", #log, "Size", f.Size)
end

print("--- P8 Modifier over a tweened property ---")
do
	mock.resetTweenLog()
	local order = {}
	local mk = rec(order)
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = s }) :: any
	s:Set(tw({ Value = 5, Time = 0.3 }, mk("a")))
	local ok, e = pcall(function() q.Dispatch.drive(f, { q.Modifier({ Size = 9 }) }) end)
	print("modifier drive", ok, e, "order", table.concat(order, ","), "Size", f.Size, "cancels", log[1].tween.cancels)
end

print("--- P9 callbacks after gcconn cut: retractFrom / Set on a destroyed Instance ---")
do
	mock.resetTweenLog()
	local order = {}
	local mk = rec(order)
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = s }) :: any
	s:Set(tw({ Value = 5, Time = 0.3 }, mk("a")))
	f:Destroy()
	print("isClaimed after destroy", q.Backend.isClaimed(f))
	s:Set(tw({ Value = 6, Time = 0.3 }, mk("b")))
	print("Set after destroy: order", table.concat(order, ","), "creates", #log)
	print("retractFrom corpse:", pcall(function() q.Dispatch.retractFrom(f, "Size", 1) end))
	print("order", table.concat(order, ","))
	-- deferred-window variant
	table.clear(order)
	mock.resetTweenLog()
	local s2 = q.Source(0 :: any)
	local g = q.Declaration.Frame({ Size = s2 }) :: any
	s2:Set(tw({ Value = 5, Time = 0.3 }, mk("w")))
	lastTween().PlaybackState = "Completed"
	g:Destroy()
	print("retractFrom corpse in window:", pcall(function() q.Dispatch.retractFrom(g, "Size", 1) end))
	print("order", table.concat(order, ","))
end

print("--- P10 non-interpolable Tween value: first set snaps silently ---")
do
	mock.resetTweenLog()
	local s = q.Source(Tween({ Value = "hello", Time = 0.2 }) :: any)
	local f = q.Declaration.Frame({ Name = s }) :: any
	print("first snap Name", f.Name, "creates", #log)
	s:Set(Tween({ Value = "bye", Time = 0.2 }))
	print("second: creates", #log, "(mock Create accepts; real TweenService raises — engine)")
end
