--!strict
-- round13 E24 types — Tween/Animate/Mapped on interpolable vs non-interpolable slots (Q34), option types.
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration
local RobloxModule = require("../../quad-roblox/src")
type RobloxTween<T> = RobloxModule.Tween<T>

local function _A()
	local a1 = D.Frame({ Name = q.Source("a"):Apply(q.Animate({ Time = 0.2 })) }) -- T1 string State + Animate (expect-error?)
	local a2 = D.TextLabel({ TextXAlignment = q.Source(Enum.TextXAlignment.Left):Apply(q.Animate({})) }) -- T2 enum + Animate
	local a3 = D.Frame({ Visible = q.Source(true):Apply(q.Animate({})) }) -- T3 boolean + Animate (tweenable)
	local a4 = D.TextLabel({ FontFace = q.Source(Font.new("x")):Apply(q.Animate({})) }) -- T15 Font + Animate
	local a5 = D.Frame({ Parent = q.Source(nil :: Instance?):Apply(q.Animate({})) }) -- T16 Parent + Animate
	return a1, a2, a3, a4, a5
end

local function _B()
	local base = q.Tween({ Value = 1, Time = 0.3 })
	local b1 = D.Frame({ BackgroundTransparency = base:Mapped(function(v: number): string return "x" end) }) -- T4 expect-error
	local b2 = D.Frame({ Size = q.Tween({ Value = UDim2.new() }):Mapped(function(v: UDim2): number return 1 end) }) -- T5 expect-error
	local b3 = D.Frame({ BackgroundTransparency = base:Mapped(function(v: number): number? return nil end) }) -- T6 nil-returning Mapped (runtime Quad0249)
	local b4 = D.Frame({ BackgroundTransparency = q.Tween({ Value = q.Source(1) }) }) -- T8 expect-error Value State
	local b5 = D.Frame({ Name = base:Mapped(function(v: number): string return "x" end) }) -- T17 Mapped to string into string slot (expect-error)
	return b1, b2, b3, b4, b5
end

local function _C()
	local c1 = q.Animate({ Started = q.Source(function() end) }) -- T9 expect-error State callback
	local c2 = q.Animate({ CanAnimate = "no" }) -- T10 expect-error
	local c3 = q.Tween({ Value = 1, Style = "Quad" }) -- T11 expect-error
	local c4 = q.Tween({ Value = 1, Info = q.Source(TweenInfo.new()) }) -- T12 expect-error
	local c5 = q.Tween({ Value = 1, Time = -1, RepeatCount = 1.5 }) -- T7 passes (domain unchecked)
	local c6 = q.Tween({ Value = 1, Override = "cancel" }) -- T18 expect-error
	local c7 = q.Animate({ CanAnimate = function() return false end }) -- T19 expect-error
	return c1, c2, c3, c4, c5, c6, c7
end

local function _D()
	local d1 = D.Modifier.Frame():Name(q.Source("a"):Apply(q.Animate({}))) -- T13 setter string + Animate
	local d2 = D.Modifier.Frame():BackgroundTransparency(q.Tween({ Value = "x" })) -- T20 expect-error
	local d3 = D.Frame({ BackgroundTransparency = q.Source("s"):Apply(q.Animate({})) }) -- T21 string State + Animate into number slot
	return d1, d2, d3
end
-- control: plain Tween on the same non-interpolable slots (Q34 says type error)
local _e1 = D.Frame({ Name = q.Tween({ Value = "a" }) }) -- control expect-error
local _e2 = D.TextLabel({ TextXAlignment = q.Tween({ Value = Enum.TextXAlignment.Left }) }) -- control expect-error
local _e3 = D.TextLabel({ TextXAlignment = q.Source(Enum.TextXAlignment.Left):Compute(function(s: q.StateData<Enum.TextXAlignment>): any return q.Tween({ Value = s:Get() }) end) }) -- Compute returning Tween typed any
local _e4 = D.Frame({ Name = q.Source("a"):Compute(function(s: q.StateData<string>): RobloxTween<string> return q.Tween({ Value = s:Get() }) end) }) -- Compute honest Tween<string>

local _e5 = D.Frame({ Size = q.Source(1):Compute(function(s: q.StateData<number>): RobloxTween<UDim2> return q.Tween({ Value = UDim2.new() }) end) }) -- positive control
local _e6 = D.Frame({ Size = q.Source(1):Compute(function(s: q.StateData<number>): RobloxTween<number> return q.Tween({ Value = 1 }) end) }) -- cross-T via Compute, expect-error
local _n1 = D.Frame({ Size = q.Source(1):Compute(function(s: q.StateData<number>): number return 1 end) }) -- neg control expect-error
local _n2 = D.Frame({ Name = q.Source(1):Compute(function(s: q.StateData<number>): number return 1 end) }) -- neg control expect-error
local _n3: RobloxTween<number> = 5 -- is the alias any? expect-error
local _n4 = D.Frame({ Name = q.Source(q.Tween({ Value = "a" })) }) -- Source<Tween<string>> into Name
local _n5 = D.Frame({ Size = q.Source(q.Tween({ Value = 1 })) }) -- Source<Tween<number>> into Size
local _a1: number = q.Source(1):Apply(q.Animate({})) -- is Apply result any? (expect-error if typed)
local _a2: string = q.Source(1):Apply(function(s: any): number return 1 end) -- Apply with plain factory
local _a3 = q.Source(1):Apply(q.Animate({}))
local _a4: string = _a3:Get() -- Get of Animate result
return { _A, _B, _C, _D, _e1, _e2, _e3, _e4, _e5, _e6, _n1, _n2, _n3, _n4, _n5, _a1, _a2, _a4 }
