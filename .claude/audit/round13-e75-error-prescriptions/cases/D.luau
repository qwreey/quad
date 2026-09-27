--!nocheck
-- E75 group D: 04-ref-observer-effect.md (main session)
local H = require("../harness")
local R = require("../runner")
local q, D = H.q, H.D

-- 0086 bad cleanup
R.case({ id = "Quad0086",
	trigger = function()
		local sig = H.mock.newSignal()
		local e = q.Effect(function() return sig:Connect(function() end) end); e:Subscribe()
	end,
	fix = function()
		local sig = H.mock.newSignal()
		local conn
		local e = q.Effect(function()
			conn = sig:Connect(function() end)
			return function() conn:Disconnect() end
		end); e:Subscribe()
		e:Unsubscribe()
		return conn.Connected == false, "cleanup disconnected=" .. tostring(not conn.Connected)
	end })
R.case({ id = "Quad0086", note = "after 0086 the handle is dead: resubscribe refused; new Effect works",
	trigger = function()
		local e = q.Effect(function() return 5 end)
		pcall(function() e:Subscribe() end)
		e:Subscribe()
	end })

-- 0087 bind self inside own fn
R.case({ id = "Quad0087",
	trigger = function()
		local host = D.Frame({})
		local e
		e = q.Effect(function(self) q.dispose(host); D.Frame({ self }) end)
		host = D.Frame({ e })
	end,
	fix = function()
		-- "re-bind after fn/cleanup finished": bind in one frame, dispose it (outside fn), place into another
		local n = 0
		local e = q.Effect(function() n += 1 end)
		local a = D.Frame({ e })
		q.dispose(a)
		local ok, err = pcall(function() D.Frame({ e }) end)
		return ok, ok and ("rebind after dispose ok n=" .. n) or ("rebind after dispose -> " .. R.first(err))
	end })
R.case({ id = "Quad0087", note = "dead handle (fn threw on a rerun) then unsubscribe + bind outside fn; fix = new Effect",
	trigger = function()
		local s = q.Source(0)
		local e = q.Effect(function() if s:Get() == 1 then error("boom") end end, s)
		e:Subscribe()
		pcall(function() s:Set(1) end)
		print("  dead: unsubscribe ->", pcall(function() e:Unsubscribe() end))
		D.Frame({ e })
	end,
	fix = function()
		local n = 0
		local e2 = q.Effect(function() n += 1 end)
		D.Frame({ e2 })
		return n == 1, "new Effect n=" .. n
	end })

-- 0088 WeakSubscribe inside fn
R.case({ id = "Quad0088",
	trigger = function()
		local s = q.Source(0)
		local e = q.Effect(function(self) if s:Get() == 1 then self:WeakSubscribe() end end, s)
		D.Frame({ e })
		s:Set(1)
	end,
	fix = function()
		local s = q.Source(0)
		local n = 0
		local e = q.Effect(function(self) n += 1 end, s)
		e:WeakSubscribe()
		s:Set(1)
		return n == 2, "weak-subscribed outside fn, reruns n=" .. n
	end })
-- 0089 WeakSubscribe when subscribed
R.case({ id = "Quad0089",
	trigger = function() local e = q.Effect(function() end); e:Subscribe(); e:WeakSubscribe() end,
	fix = function()
		local s = q.Source(0); local n = 0
		local e = q.Effect(function() n += 1 end, s); e:Subscribe()
		e:Unsubscribe(); e:WeakSubscribe()
		s:Set(1)
		return e.Subscribed == true and n >= 2, ("strong->weak: Subscribed=%s n=%d"):format(tostring(e.Subscribed), n)
	end })
R.case({ id = "Quad0230",
	trigger = function() local e = q.Effect(function() end); D.Frame({ e }); e:WeakSubscribe() end,
	fix = function() local e = q.Effect(function() end); e:WeakSubscribe(); return e.Subscribed end })
R.case({ id = "Quad0090",
	trigger = function()
		local s = q.Source(0)
		local e = q.Effect(function(self) if s:Get() == 1 then self:Subscribe() end end, s)
		D.Frame({ e })
		s:Set(1)
	end,
	fix = function()
		local s = q.Source(0); local n = 0
		local e = q.Effect(function() n += 1 end, s); e:Subscribe(); s:Set(1)
		return n == 2, "n=" .. n
	end })
R.case({ id = "Quad0090", note = "Subscribe from inside fn while strongly subscribed (the 'unsubscribe inside' allowed?)",
	trigger = nil,
	fix = function()
		local s = q.Source(0); local n = 0
		local e; e = q.Effect(function(self) n += 1; if s:Get() == 1 then self:Unsubscribe() end end, s)
		e:Subscribe(); s:Set(1); s:Set(2)
		return n == 2 and e.Subscribed == false, ("unsubscribe inside fn ok: n=%d Subscribed=%s"):format(n, tostring(e.Subscribed))
	end })
R.case({ id = "Quad0091",
	trigger = function() local e = q.Effect(function() end); e:WeakSubscribe(); e:Subscribe() end,
	fix = function()
		local e = q.Effect(function() end); e:WeakSubscribe()
		e:WeakUnsubscribe(); e:Subscribe()
		return e.Subscribed, "weak->strong ok"
	end })
R.case({ id = "Quad0231",
	trigger = function() local e = q.Effect(function() end); D.Frame({ e }); e:Subscribe() end,
	fix = function() local e = q.Effect(function() end); e:Subscribe(); return e.Subscribed end })
R.case({ id = "Quad0092",
	trigger = function() local e = q.Effect(function() end); e:Subscribe(); e:WeakUnsubscribe() end,
	fix = function() local e = q.Effect(function() end); e:Subscribe(); e:Unsubscribe(); return e.Subscribed == false end })
R.case({ id = "Quad0093",
	trigger = function() local e = q.Effect(function() end); e:WeakSubscribe(); e:Unsubscribe() end,
	fix = function() local e = q.Effect(function() end); e:WeakSubscribe(); e:WeakUnsubscribe(); return e.Subscribed == false end })
R.case({ id = "Quad0093", note = "bound to a seat only: how does one release it?",
	trigger = function() local e = q.Effect(function() end); D.Frame({ e }); e:Unsubscribe() end,
	fix = function()
		local e = q.Effect(function() end); D.Frame({ e })
		local ok, err = pcall(function() e:WeakUnsubscribe() end)
		return ok, ok and "WeakUnsubscribe on seat-bound ok" or R.first(err)
	end })
R.case({ id = "Quad0094",
	trigger = function() q.Effect(5) end,
	fix = function() local n = 0; D.Frame({ q.Effect(function() n += 1 end) }); return n == 1 end })
R.case({ id = "Quad0095",
	trigger = function() local a; q.Effect(function() end, a) end,
	fix = function() local a = q.Source(0); local n = 0; D.Frame({ q.Effect(function() n += 1 end, a) }); a:Set(1); return n == 2, "n=" .. n end })
R.case({ id = "Quad0096",
	trigger = function() q.Effect(function() end, 5) end,
	fix = function() local a = q.Ref(); local n = 0; D.Frame({ q.Effect(function() n += 1 end, a) }); a:Set(1); return n == 2, "Ref dep n=" .. n end })
R.case({ id = "Quad0097",
	trigger = function() D.Frame({ Name = "x", Watch = q.Effect(function() end) }) end,
	fix = function() local n = 0; D.Frame({ q.Effect(function() n += 1 end) }); return n == 1 end })
R.case({ id = "Quad0097", note = "via State in array seat",
	trigger = function() D.Frame({ q.Source(q.Effect(function() end)) }) end })
R.case({ id = "Quad0101",
	trigger = function() q.OnDestroyed(5) end,
	fix = function()
		local died = false
		local f = D.Frame({ q.OnDestroyed(function() died = true end) })
		f:Destroy()
		return died, "OnDestroyed fired=" .. tostring(died)
	end })

-- Observer
R.case({ id = "Quad0109",
	trigger = function()
		local s = q.Source(0)
		local host
		local o; o = s:Observer(function() if s:Get() == 1 then q.dispose(host); D.Frame({ o }) end end)
		host = D.Frame({ o })
		s:Set(1)
	end,
	fix = function()
		-- "do not re-place yourself while running": rebind after the callback returned
		local s = q.Source(0); local n = 0
		local o = s:Observer(function() n += 1 end)
		local host = D.Frame({ o })
		q.dispose(host)
		local ok, err = pcall(function() D.Frame({ o }) end)
		local before = n; s:Set(1)
		return ok and n > before, ok and ("rebind after dispose ok, fires=" .. tostring(n > before)) or R.first(err)
	end })
R.case({ id = "Quad0110",
	trigger = function()
		local s = q.Source(0)
		local o; o = s:Observer(function(_, self) self:WeakSubscribe() end)
		D.Frame({ o }); s:Set(1)
	end,
	fix = function()
		local s = q.Source(0); local n = 0
		local o = s:Observer(function() n += 1 end); o:WeakSubscribe(); local b = n; s:Set(1)
		return n > b, "fires after Set: " .. b .. "->" .. n
	end })
R.case({ id = "Quad0111",
	trigger = function() local o = q.Source(0):Observer(function() end); o:Subscribe(); o:WeakSubscribe() end,
	fix = function()
		local s = q.Source(0); local n = 0
		local o = s:Observer(function() n += 1 end); o:Subscribe(); o:Unsubscribe(); o:WeakSubscribe(); local b = n; s:Set(1)
		return n > b and o.Subscribed, ("strong->weak %d->%d Subscribed=%s"):format(b, n, tostring(o.Subscribed))
	end })
R.case({ id = "Quad0112",
	trigger = function() local o = q.Source(0):Observer(function() end); o:Subscribe(); o:WeakUnsubscribe() end,
	fix = function() local o = q.Source(0):Observer(function() end); o:Subscribe(); o:Unsubscribe(); return not o.Subscribed end })
R.case({ id = "Quad0113",
	trigger = function()
		local s = q.Source(0)
		local o; o = s:Observer(function(_, self) self:Subscribe() end)
		D.Frame({ o }); s:Set(1)
	end,
	fix = function() local s = q.Source(0); local n = 0; local o = s:Observer(function() n += 1 end); o:Subscribe(); local b = n; s:Set(1); return n > b, b .. "->" .. n end })
R.case({ id = "Quad0114",
	trigger = function() local o = q.Source(0):Observer(function() end); o:WeakSubscribe(); o:Subscribe() end,
	fix = function()
		local s = q.Source(0); local n = 0
		local o = s:Observer(function() n += 1 end); o:WeakSubscribe(); o:WeakUnsubscribe(); o:Subscribe(); local b = n; s:Set(1)
		return n > b, "weak->strong " .. b .. "->" .. n
	end })
R.case({ id = "Quad0115",
	trigger = function() local o = q.Source(0):Observer(function() end); o:WeakSubscribe(); o:Unsubscribe() end,
	fix = function() local o = q.Source(0):Observer(function() end); o:WeakSubscribe(); o:WeakUnsubscribe(); return not o.Subscribed end })
R.case({ id = "Quad0116",
	trigger = function() D.Frame({ Name = "x", W = q.Source(0):Observer(function() end) }) end,
	fix = function() local s = q.Source(0); local n = 0; D.Frame({ s:Observer(function() n += 1 end) }); local b = n; s:Set(1); return n > b, b .. "->" .. n end })
R.case({ id = "Quad0234",
	trigger = function() local o = q.Source(0):Observer(function() end); D.Frame({ o }); o:WeakSubscribe() end,
	fix = function() local o = q.Source(0):Observer(function() end); o:WeakSubscribe(); return o.Subscribed end })
R.case({ id = "Quad0235",
	trigger = function() local o = q.Source(0):Observer(function() end); D.Frame({ o }); o:Subscribe() end,
	fix = function() local o = q.Source(0):Observer(function() end); o:Subscribe(); return o.Subscribed end })

-- Ref
R.case({ id = "Quad0130",
	trigger = function()
		local r = q.Ref()
		local co = coroutine.running()
		r:Wait(co)
		r:Set(1)
	end,
	fix = function()
		local r = q.Ref()
		local got
		local waiter = coroutine.create(function() got = r:Wait() end)
		coroutine.resume(waiter)
		r:Set(42)
		got = got and got.Value
		return got == 42, "unrelated coroutine Set woke waiter got=" .. tostring(got)
	end })
R.case({ id = "Quad0132",
	trigger = function() q.Ref():Callback(5) end,
	fix = function() local r = q.Ref(); local got; r:Callback(function(v) got = v end); r:Set(3); return got == 3, "got=" .. tostring(got) end })
R.case({ id = "Quad0133",
	trigger = function() q.Ref():Wait(5) end,
	fix = function()
		local r = q.Ref(); local got
		local th = coroutine.create(function(v) got = v end)
		r:Wait(th)
		r:Set(9)
		return got ~= nil, "registered thread resumed with=" .. tostring(got)
	end })
R.case({ id = "Quad0134",
	trigger = function()
		local r = q.Ref()
		local t = setmetatable({}, { __index = function() return r:Wait() end })
		local _ = t.x
	end,
	fix = function()
		local r = q.Ref(); local got
		local th = coroutine.create(function() got = r:Wait() end)
		coroutine.resume(th)
		r:Set(5)
		got = got and got.Value
		return got == 5, "got=" .. tostring(got)
	end })
R.case({ id = "Quad0135",
	trigger = function() q.Ref():Unwrap() end,
	fix = function()
		local r = q.PreRef()
		local got
		local b = D.TextButton({ r, Activated = function() got = r:Unwrap() end })
		b.Activated:Fire()
		local r2 = q.Ref()
		local v = r2.Value
		return got == b and v == nil, "Unwrap inside event after PreRef filled"
	end })
R.case({ id = "Quad0136",
	trigger = function() D.Frame({ q.Source(q.PreRef()) }) end,
	fix = function() local r = q.PreRef(); local f = D.Frame({ r }); return r.Value == f end })
R.case({ id = "Quad0137",
	trigger = function() D.Frame({ Name = "x", MyRef = q.Ref() }) end,
	fix = function() local r = q.Ref(); local f = D.Frame({ r }); return r.Value == f end })
R.done()
