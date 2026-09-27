--!nocheck
-- E80 group A: Effect/Observer/Ref/hooks Fixed bullets (F1 F2 F13 F15 F22 F29 F32) + Changed C63
local H = require("../harness")
local L = require("../lib")
local q, D = H.q, H.D

print("--- F1: fn이 던져 죽은 Effect를 Unsubscribe로 놓을 수 있다 ---")
L.section(function()
	local s = q.Source(1)
	local e = q.Effect(function() if s:Get() == 2 then error("boom") end end, s):Subscribe()
	pcall(function() s:Set(2) end)
	local ok, err = pcall(function() e:Unsubscribe() end)
	L.check("F1 dead Effect Unsubscribe ok", ok and e.Subscribed == false, ok and "released" or L.first(err))
	-- WeakUnsubscribe on a dead weak-subscribed handle
	local s2 = q.Source(1)
	local e2 = q.Effect(function() if s2:Get() == 2 then error("boom") end end, s2):WeakSubscribe()
	pcall(function() s2:Set(2) end)
	local okw, errw = pcall(function() e2:WeakUnsubscribe() end)
	L.check("F1 dead Effect WeakUnsubscribe ok", okw and e2.Subscribed == false, okw and "released" or L.first(errw))
	-- GC: the strong keep released → collectable
	local s3 = q.Source(1)
	local weak = setmetatable({}, { __mode = "v" })
	do
		local e3 = q.Effect(function() if s3:Get() == 2 then error("boom") end end, s3):Subscribe()
		weak[1] = e3
		pcall(function() s3:Set(2) end)
		e3:Unsubscribe()
	end
	collectgarbage("collect"); collectgarbage("collect")
	L.check("F1 released dead Effect is collected", weak[1] == nil, "weak[1]=" .. tostring(weak[1]))
	-- Observer: callback throws → frozen; Unsubscribe works; firing continues
	local o = q.Source(1)
	local fired = 0
	local ob = o:Observer(function(st) fired += 1; if st:Get() == 2 then error("obs boom") end end):Subscribe()
	pcall(function() o:Set(2) end)
	local f0 = fired
	pcall(function() o:Set(3) end)
	L.check("F1 frozen Observer keeps firing", fired == f0 + 1, "fired " .. f0 .. "→" .. fired)
	local m, id = L.err("F1 frozen Observer re-Subscribe", function() ob:Subscribe() end)
	local oku, erru = pcall(function() ob:Unsubscribe() end)
	L.check("F1 frozen Observer Unsubscribe ok", oku and ob.Subscribed == false, oku and "released" or L.first(erru))
	-- self-release inside callback
	local sr = q.Source(0)
	local calls = 0
	local e4
	e4 = q.Effect(function() calls += 1; if sr:Get() == 1 then e4:Unsubscribe() end end, sr):Subscribe()
	local oks, errs = pcall(function() sr:Set(1) end)
	L.check("F1 self-Unsubscribe inside fn ok, fn not re-called", oks and e4.Subscribed == false and calls == 2, oks and ("calls=" .. calls) or L.first(errs))
end)

print("--- F2: fn 도중 실행 자격 상실 → 돌려준 cleanup 즉시 소진 (yield + host death → dying=true) ---")
L.section(function()
	local s = q.Source(0)
	local host = D.Frame {}
	local cl, dy = 0, nil
	local e = q.Effect(function()
		if s:Get() == 1 then coroutine.yield() end
		return function(d) cl += 1; dy = d end
	end, s)
	host = D.Frame { e }
	local co = coroutine.create(function() s:Set(1) end)
	coroutine.resume(co)
	local before = cl
	host:Destroy()
	coroutine.resume(co)
	L.check("F2 cleanup consumed at once with dying=true", cl == before + 1 and dy == true, "cl " .. before .. "→" .. cl .. " dying=" .. tostring(dy))
	-- self-unsubscribe in fn returning cleanup
	local s2 = q.Source(0); local c2 = 0; local e2
	e2 = q.Effect(function()
		if s2:Get() == 1 then e2:Unsubscribe() end
		return function(d) c2 += 1 end
	end, s2):Subscribe()
	s2:Set(1)
	L.check("F2 self-unsubscribe: returned cleanup consumed", c2 == 2, "cleanups=" .. c2)
end)

-- Deferred Destroying emulation
local origOn = q.Backend.onDestroying
local queue = {}
local function deferOn()
	q.Backend.onDestroying = function(inst, fn) return origOn(inst, function() table.insert(queue, fn) end) end
end
local function flush() local qq = queue; queue = {}; for _, fn in qq do fn() end end

print("--- F13: Deferred — 파괴 뒤 같은 프레임 안 다른 인스턴스에 재바인드, 옛 콜백 무시 ---")
L.section(function()
	deferOn()
	local dep = q.Source(0)
	local runs, cls = 0, {}
	local eff = q.Effect(function() runs += 1; return function(d) table.insert(cls, d) end end, dep)
	local h1 = D.Frame { eff }
	h1:Destroy()
	local h2 = D.Frame { eff }
	flush()
	dep:Set(1)
	L.check("F13 rebound Effect survives stale Destroying", runs == 2 and #cls == 1 and cls[1] == false, "runs=" .. runs .. " cleanups=" .. #cls)
	h2:Destroy(); flush()
	L.check("F13 real death consumes once dying=true", #cls == 2 and cls[2] == true, "#cls=" .. #cls)
	q.Backend.onDestroying = origOn
end)

print("--- F15: Deferred — 호스트 파괴 직후 :Subscribe()로 되살림, 늦은 Destroying 무시 ---")
L.section(function()
	deferOn()
	local dep = q.Source(0)
	local runs, cls = 0, {}
	local eff = q.Effect(function() runs += 1; return function(d) table.insert(cls, d) end end, dep)
	local h = D.Frame { eff }
	h:Destroy()
	eff:Subscribe()
	flush()
	dep:Set(1)
	L.check("F15 revived Effect keeps running", runs == 2 and #cls == 1 and cls[1] == false and eff.Subscribed == true, "runs=" .. runs .. " #cls=" .. #cls)
	eff:Unsubscribe()
	-- WeakSubscribe variant
	local runs2 = 0
	local eff2 = q.Effect(function() runs2 += 1 end, dep)
	local h2 = D.Frame { eff2 }
	h2:Destroy(); eff2:WeakSubscribe(); flush(); dep:Set(2)
	L.check("F15 WeakSubscribe revive keeps running", runs2 == 2, "runs2=" .. runs2)
	q.Backend.onDestroying = origOn
end)

print("--- F22: Ref :Wait() 대기자가 철거의 nil에 깨어나 던져도 되꽂으면 채워진다 ---")
L.section(function()
	local ref = q.Ref(nil)
	local holder = q.Source(ref)
	local host = D.Frame { holder }
	local th = coroutine.create(function() local v = ref:Wait():Unwrap() end)
	coroutine.resume(th)
	local m = L.err("F22 retract wakes waiter that throws", function() holder:Set(nil) end)
	holder:Set(ref)
	L.check("F22 re-placed Ref is filled", ref.Value == host, "ref.Value=" .. tostring(ref.Value))
end)

print("--- F29: OnDestroyed를 State 자리에 담아 None으로 뺐다 되꽂기 → 죽을 때 한 번 ---")
L.section(function()
	local n = 0
	local hook = q.OnDestroyed(function() n += 1 end)
	local slot = q.Source(hook)
	local host = D.Frame { slot }
	slot:Set(q.None)
	L.check("F29 removing does not fire", n == 0, "n=" .. n)
	slot:Set(hook)
	host:Destroy()
	L.check("F29 death fires exactly once", n == 1, "n=" .. n)
	local n2 = 0
	local hook2 = q.OnDestroyed(function() n2 += 1 end)
	local slot2 = q.Source(hook2)
	local host2 = D.Frame { slot2 }
	slot2:Set(q.None); host2:Destroy()
	L.check("F29 removed then died: no fire", n2 == 0, "n2=" .. n2)
end)

print("--- F32: cleanup 안의 dep :Set → 한 사이클 ---")
L.section(function()
	local a = q.Source(1); local log = {}; local once = true
	local e = q.Effect(function()
		table.insert(log, "fn" .. a:Get())
		return function() table.insert(log, "cl"); if once then once = false; a:Set(99) end end
	end, a):Subscribe()
	a:Set(2)
	L.check("F32 one cycle", table.concat(log, " ") == "fn1 cl fn99", table.concat(log, " "))
	local b = q.Source(1); local log2 = {}; local inFn = true
	local e2 = q.Effect(function() table.insert(log2, "fn" .. b:Get()); if inFn then inFn = false; b:Set(5) end end, b):Subscribe()
	L.check("F32 Set inside fn still reruns", table.concat(log2, " ") == "fn1 fn5", table.concat(log2, " "))
end)

print("--- C63: Effect fn이 함수/nil 아닌 값을 돌려주면 즉시 에러 ---")
L.section(function()
	local m, id = L.err("C63 return number", function() q.Effect(function() return 5 end) end)
	L.check("C63 message", L.has(m, "Effect: fn must return a cleanup function or nothing (got"), id)
	L.check("C63 blame user file", L.has(m, "a-effect.luau"), m)
	local conn = { Disconnect = function() end }
	local m2 = L.err("C63 return table (connection)", function() q.Effect(function() return conn end) end)
end)
L.done()
