--[[
	DRAFT (round13 P-TWEEN, scratch) — Tween callback bundle: Q91 (b) OLD-FIRST window order, Q92 (b) one callback
	set per shorthand Tween, Q99 c teardown window = Cancelled, Q82 (a) corpse gate, Q81 (b) Dedup reads the
	property for a record that names no running tween, Q97 (b) engine-read tolerance. Would be folded into
	`spec.tweenproperty.luau` §11 / new §12 on adoption. Shims: spec.tweenproperty + spec.shorthand idioms, plus a
	`typeof` seam on the Property module (engine value types are tables here).
]]

local Quad = require("../luau_packages/quad_base")
local QuadRoblox = require("../src").QuadRoblox
local installProperty = require("../src/Handlers/Property")
local installEvent = require("../src/Handlers/Event")
local installShorthand = require("../src/Handlers/InstanceShorthand")
local mock = require("../../quad-base/test/mock")

local W = { Write = "" }
local REFLECTED: { [string]: { any } } = {
	Frame = {
		{ Name = "Name", Permits = W },
		{ Name = "Size", Permits = W },
		{ Name = "BackgroundTransparency", Permits = W },
		{ Name = "Position", Permits = W },
	},
	UIPadding = { { Name = "Name", Permits = W }, { Name = "PaddingLeft", Permits = W }, { Name = "PaddingRight", Permits = W }, { Name = "PaddingTop", Permits = W }, { Name = "PaddingBottom", Permits = W } },
}
local gameShim = mock.gameShim(REFLECTED)
local q: any = Quad.New():UseProvider(QuadRoblox)
local penv: any = getfenv(installProperty)
penv.game = gameShim
penv.TweenInfo = mock.tweenInfoShim
penv.Enum = { EasingStyle = { Quad = "Quad" }, EasingDirection = { Out = "Out" }, PlaybackState = { Completed = "Completed", Cancelled = "Cancelled" } }
;(getfenv(installEvent) :: any).game = gameShim
;(getfenv(q.Declaration.New) :: any).Instance = { new = mock.Instance.new }
q.Backend.isInst = mock.isMockInstance
local UDIM_MT = {
	__eq = function(a: any, b: any): boolean return a.Scale == b.Scale and a.Offset == b.Offset end,
	__tostring = function(a: any): string return `UDim({a.Scale},{a.Offset})` end,
}
local function UDimNew(scale: number, offset: number): any
	return setmetatable({ Scale = scale, Offset = offset }, UDIM_MT)
end
;(getfenv(installShorthand) :: any).UDim = { new = UDimNew }
local V2_MT = { __eq = function(a: any, b: any): boolean return a.X == b.X and a.Y == b.Y end }
local function V2(x: number, y: number): any
	return setmetatable({ X = x, Y = y }, V2_MT)
end
local realTypeof = typeof
penv.typeof = function(v: any): string
	local mt = getmetatable(v)
	if mt == UDIM_MT then return "UDim" elseif mt == V2_MT then return "Vector2" end
	return realTypeof(v)
end
local function f32(x: number): number
	return (string.unpack("f", string.pack("f", x)))
end

local Tween = q.Tween
local log = mock.tweenLog
local function lastTween(): any
	return log[#log].tween
end
local order: { string } = {}
local function tw(tag: string, value: any, extra: any?): any
	local opts: any = {
		Value = value,
		Time = 0.3,
		Started = function() table.insert(order, tag .. ":started") end,
		Completed = function() table.insert(order, tag .. ":completed") end,
		Cancelled = function() table.insert(order, tag .. ":cancelled") end,
	}
	if extra then
		for k2, v2 in extra do
			if k2 == "then" then
				local base = opts.Completed
				opts.Completed = function() base(); (v2 :: () -> ())() end
			else
				opts[k2] = v2
			end
		end
	end
	return Tween(opts)
end
local function playingTargets(n0: number): string
	local t = {}
	for i = n0 + 1, #log do
		local e = log[i]
		if e.tween.PlaybackState == "Playing" then
			for _, v in e.props do table.insert(t, tostring(v)) end
		end
	end
	return table.concat(t, ",")
end
local function inWindow(t: any, f: any, k: string?)
	t.PlaybackState = "Completed" -- the engine reached the target; `Completed` still queued
	if f ~= nil then
		local key = k or "Size"
		f[key] = t.PropertyTable[key]
	end
end
local function joined(): string
	return table.concat(order, ",")
end

print("=== 12a. Q91 (b) — 창 안 교체: 옛 Completed는 새 레코드 기록 뒤, 새 Started 앞(OLD-FIRST); Completed가 이은 값이 새 값을 정상 교체(고아 없음) ===")
do
	mock.resetTweenLog()
	-- no chain: order unchanged from §11 (w:completed → x:started), late notice ignored
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = s }) :: any
	s:Set(tw("a", 10))
	local a = lastTween()
	inWindow(a, f)
	table.clear(order)
	s:Set(tw("b", 20))
	assert(joined() == "a:completed,b:started" and a.cancels == 0, "window replace: " .. joined())
	a.Completed:Fire("Completed")
	assert(joined() == "a:completed,b:started", "late notice ignored")
	-- chain inside the window: A.Completed sets C — C replaces B (B cancelled before it ever started), one tween plays
	mock.resetTweenLog()
	local s2 = q.Source(0 :: any)
	local g = q.Declaration.Frame({ Size = s2 }) :: any
	s2:Set(tw("a", 10, { ["then"] = function() s2:Set(tw("c", 77)) end }))
	local a2 = lastTween()
	local n0 = #log
	inWindow(a2, g)
	table.clear(order)
	s2:Set(tw("b", 20))
	assert(joined() == "a:completed,b:cancelled,c:started", "chain in window: " .. joined())
	assert(playingTargets(n0) == "77", "exactly one live tween (the chained one): " .. playingTargets(n0))
	q.Dispatch.retractFrom(g, "Size", 1)
	assert(playingTargets(n0) == "", "teardown reaches the chained tween (no orphan): " .. playingTargets(n0))
	-- zero-time incoming value in the window + chain: the snapped value is replaced by C; its own callbacks do not fire
	mock.resetTweenLog()
	local s3 = q.Source(0 :: any)
	local h = q.Declaration.Frame({ Size = s3 }) :: any
	s3:Set(tw("a", 10, { ["then"] = function() s3:Set(tw("c", 77)) end }))
	local a3 = lastTween()
	local n1 = #log
	inWindow(a3, h)
	table.clear(order)
	s3:Set(tw("z", 20, { Time = 0 }))
	assert(joined() == "a:completed,c:started" and h.Size == 20 and playingTargets(n1) == "77", "zero-time in window + chain: " .. joined())
	-- zero-time without a chain: old Completed, then the snap's Started/Completed
	mock.resetTweenLog()
	local s4 = q.Source(0 :: any)
	local i4 = q.Declaration.Frame({ Size = s4 }) :: any
	s4:Set(tw("a", 10))
	inWindow(lastTween(), i4)
	table.clear(order)
	s4:Set(tw("z", 20, { Time = 0 }))
	assert(joined() == "a:completed,z:started,z:completed" and i4.Size == 20, "zero-time in window: " .. joined())
	print("PASS")
end

print()
print("=== 12b. Q92 (b) — 숏핸드 Tween 하나 = 콜백 한 벌; Completed 연쇄가 네 변을 같은 목표로 ===")
do
	mock.resetTweenLog()
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ UIPaddingOffset = s }) :: any
	local n = { S = 0, C = 0, X = 0 }
	local step = 0
	local function mk(v: number): any
		return Tween({ Value = v, Time = 1,
			Started = function() n.S += 1 end,
			Cancelled = function() n.X += 1 end,
			Completed = function()
				n.C += 1
				if step < 3 then step += 1; s:Set(mk(100 + step)) end
			end })
	end
	s:Set(mk(10))
	assert(n.S == 1, "four engine tweens, one Started")
	for _ = 1, 6 do -- deliver each batch like the engine: all four finish on the same frame
		local batch = {}
		for i = 1, #log do if log[i].tween.PlaybackState == "Playing" then table.insert(batch, log[i].tween) end end
		if #batch == 0 then break end
		for _, t in batch do
			t.PlaybackState = "Completed"
			for pk, pv in t.PropertyTable do (t.Instance :: any)[pk] = pv end
		end
		for _, t in batch do t.Completed:Fire("Completed") end
	end
	local pad: any = f:GetChildren()[1]
	local offs = {}
	for _, p in { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" } do table.insert(offs, tostring(pad[p].Offset)) end
	assert(table.concat(offs, "/") == "103/103/103/103", "all four sides reach the last chained target: " .. table.concat(offs, "/"))
	assert(n.S == 4 and n.C == 4 and n.X == 0 and step == 3, `one callback set per value: S{n.S} C{n.C} X{n.X}`)
	print("PASS")
end

print()
print("=== 12c. Q99 c — 철거 창(도달했지만 통지 전)은 Cancelled; 거기서 잇기는 일어나지 않음 ===")
do
	mock.resetTweenLog()
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = s }) :: any
	s:Set(tw("a", 10, { ["then"] = function() s:Set(tw("c", 77)) end }))
	local a = lastTween()
	local n0 = #log
	inWindow(a, f)
	table.clear(order)
	q.Dispatch.retractFrom(f, "Size", 1)
	assert(joined() == "a:cancelled" and a.cancels == 0, "teardown in window reports Cancelled (no engine Cancel on a finished tween): " .. joined())
	assert(playingTargets(n0) == "", "no chained tween")
	a.Completed:Fire("Completed")
	assert(joined() == "a:cancelled", "late notice ignored")
	-- the record keeps `{ Value }` (property holds the target): same target re-declared does not replay
	q.Dispatch.drive(f, { Size = Tween({ Value = 10, Time = 0.3 }) })
	assert(#log == n0, "teardown in window keeps the value record")
	-- None (handler switch) in the window: same
	mock.resetTweenLog()
	local s2 = q.Source(0 :: any)
	local g = q.Declaration.Frame({ Size = s2 }) :: any
	s2:Set(tw("a", 10))
	inWindow(lastTween(), g)
	table.clear(order)
	s2:Set(q.None)
	assert(joined() == "a:cancelled", "None in window: " .. joined())
	print("PASS")
end

print()
print("=== 12d. Q82 (a) — 파괴된 인스턴스의 retractFrom은 무발화(정산·Cancel은 그대로) ===")
do
	mock.resetTweenLog()
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = s }) :: any
	s:Set(tw("a", 10))
	local a = lastTween()
	f:Destroy()
	table.clear(order)
	q.Dispatch.retractFrom(f, "Size", 1)
	assert(#order == 0 and a.cancels == 1, "running on a corpse: cancelled silently: " .. joined())
	local s2 = q.Source(0 :: any)
	local g = q.Declaration.Frame({ Size = s2 }) :: any
	s2:Set(tw("w", 10))
	inWindow(lastTween(), g)
	g:Destroy()
	table.clear(order)
	q.Dispatch.retractFrom(g, "Size", 1)
	assert(#order == 0, "window on a corpse: silent: " .. joined())
	print("PASS")
end

print()
print("=== 12e. Q81 (b) — 돌고 있지 않은 기록은 프로퍼티가 목표를 쥘 때만 Dedup; 도는 트윈은 그대로 ===")
do
	mock.resetTweenLog()
	-- running same target: still folded (H-391)
	local s = q.Source(0 :: any)
	local f = q.Declaration.Frame({ Size = s }) :: any
	s:Set(tw("a", 10))
	table.clear(order)
	s:Set(tw("b", 10))
	assert(#log == 1 and #order == 0, "running same target folds")
	-- finished at the target: folded
	local a = lastTween()
	inWindow(a, f)
	a.Completed:Fire("Completed")
	table.clear(order)
	s:Set(tw("c", 10))
	assert(#log == 1 and #order == 0, "finished at target folds")
	-- outside write (engine scroll/drag) then the same target: re-plays
	f.Size = 40
	s:Set(tw("d", 10))
	assert(#log == 2 and joined() == "d:started" and log[2].props.Size == 10, "outside write re-plays: " .. joined())
	-- Reverses rests at the start value: the next pulse plays
	mock.resetTweenLog()
	local p = q.Source(1 :: any)
	local g = q.Declaration.Frame({ Size = p }) :: any
	p:Set(Tween({ Value = 2, Time = 0.2, Reverses = true }))
	local r = lastTween()
	r.PlaybackState = "Completed"
	g.Size = 1
	p:Set(Tween({ Value = 2, Time = 0.2, Reverses = true }))
	assert(#log == 2, "second Reverses pulse plays")
	-- a snapped record after an outside write
	mock.resetTweenLog()
	local s3 = q.Source(Tween({ Value = 0, Time = 0.2 }) :: any)
	local h = q.Declaration.Frame({ Size = s3 }) :: any
	h.Size = 40
	s3:Set(Tween({ Value = 0, Time = 0.2 }))
	assert(#log == 1, "snapped record + outside write re-plays")
	print("PASS")
end

print()
print("=== 12f. Q97 (b) — 엔진이 양자화해 되돌려 준 값(float32·정수 Offset)은 같은 값 ===")
do
	mock.resetTweenLog()
	-- teardown record: finished at f32(0.1) → `{ Value }` kept → same target does not replay
	local f = q.Declaration.Frame({ BackgroundTransparency = 0 }) :: any
	q.Dispatch.drive(f, { BackgroundTransparency = Tween({ Value = 0.1, Time = 0.3 }) })
	local t = lastTween()
	t.PlaybackState = "Completed"
	f.BackgroundTransparency = f32(0.1)
	q.Dispatch.retractFrom(f, "BackgroundTransparency", 1)
	q.Dispatch.drive(f, { BackgroundTransparency = Tween({ Value = 0.1, Time = 0.3 }) })
	assert(#log == 1, "float32 read-back keeps the record")
	-- Q81 dedup with a quantized read-back: folds; a genuinely different value re-plays
	mock.resetTweenLog()
	local s = q.Source(V2(0, 0) :: any)
	local g = q.Declaration.Frame({ Position = s }) :: any
	s:Set(Tween({ Value = V2(0.1, 0.7), Time = 0.3 }))
	local t2 = lastTween()
	t2.PlaybackState = "Completed"
	g.Position = V2(f32(0.1), f32(0.7))
	s:Set(Tween({ Value = V2(0.1, 0.7), Time = 0.3 }))
	assert(#log == 1, "quantized Vector2 folds")
	g.Position = V2(0.1, 0.8)
	s:Set(Tween({ Value = V2(0.1, 0.7), Time = 0.3 }))
	assert(#log == 2, "different Vector2 re-plays")
	-- UDim: integer Offset + float32 Scale
	mock.resetTweenLog()
	local u = q.Source(UDimNew(0, 0) :: any)
	local h = q.Declaration.Frame({ Size = u }) :: any
	u:Set(Tween({ Value = UDimNew(0.3, 10.6), Time = 0.3 }))
	lastTween().PlaybackState = "Completed"
	h.Size = UDimNew(f32(0.3), 10)
	u:Set(Tween({ Value = UDimNew(0.3, 10.6), Time = 0.3 }))
	assert(#log == 1, "quantized UDim folds")
	print("PASS")
end

print()
print("=== ALL PASS ===")
