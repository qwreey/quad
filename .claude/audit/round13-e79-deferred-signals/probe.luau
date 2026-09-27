--!nocheck
-- E79 probe — seven axes, each run under three modes: mock (sync, fires on same value),
-- imm (sync + engine same-value suppression), def (deferred shim + suppression).
-- Run from repo root: mise exec -- luau .claude/audit/round13-e79-deferred-signals/probe.luau
local E = require("./env")
local S, mock = E.S, E.mock

local MODES = { "mock", "imm", "def" }
local function j(t) local o = {} for _, v in t do table.insert(o, tostring(v)) end return table.concat(o, ",") end
local function try(f, ...)
	local ok, err = pcall(f, ...)
	if ok then return "ok" end
	return "ERR " .. E.idOf(err) .. " :: " .. tostring(err):gsub("\n.*", ""):sub(1, 140)
end
local function run(title, fn)
	print(("="):rep(100))
	print(title)
	for _, m in MODES do
		S.reset(m)
		local q = E.newProv()
		local lines = {}
		local function out(s) table.insert(lines, s) end
		local ok, err = pcall(fn, q, out, m)
		if not ok then out("SCENARIO THREW: " .. tostring(err):gsub("\n.*", "")) end
		if #S.errors > 0 then out("listener errors (isolated): " .. table.concat(S.errors, " | ")) end
		if S.capped then out("FLUSH CAPPED at " .. S.cap) end
		print(("  [%s] %s"):format(m, table.concat(lines, "\n         ")))
	end
end

--------------------------------------------------------------------------- (1) q.Out echo / round trip
run("(1a) q.Out mount + user types 'a','ab' in one frame", function(q, out)
	local D = q.Declaration
	local src = q.Source("quad")
	local emits, seen = 0, {}
	src:Observer(function(s) emits += 1; table.insert(seen, s:Get()) end):Subscribe()
	local box = D.TextBox({ Text = src, q.Out("Text", src) })
	local d0 = S.flush()
	out(("after mount: emits=%d box.Text=%s deliveries=%d"):format(emits, tostring(box.Text), d0))
	E.engineWrite(box, "Text", "a")
	E.engineWrite(box, "Text", "ab")
	out(("before flush: src=%s emits=%d"):format(src:Get(), emits))
	local d1 = S.flush()
	out(("after flush: src=%s box.Text=%s emits=%d seen=[%s] deliveries=%d"):format(src:Get(), box.Text, emits, j(seen), d1))
end)

run("(1b) OnChange transform (upper) into the Source driving Text; user types 'a','ab'", function(q, out)
	local D = q.Declaration
	local src = q.Source("")
	local emits, seen, calls = 0, {}, 0
	src:Observer(function(s) emits += 1; table.insert(seen, s:Get()) end):Subscribe()
	local box = D.TextBox({ Text = src, q.OnChange("Text", function(v) calls += 1; src:Set(string.upper(v)) end) })
	S.flush()
	emits, seen, calls = 0, {}, 0
	E.engineWrite(box, "Text", "a")
	E.engineWrite(box, "Text", "ab")
	local d = S.flush()
	out(("src=%s box.Text=%s callbacks=%d emits=%d seen=[%s] deliveries=%d"):format(src:Get(), box.Text, calls, emits, j(seen), d))
end)

run("(1c) two TextBoxes, both Text=src + q.Out(src); engine writes box1='one' then box2='two' in one frame", function(q, out)
	local D = q.Declaration
	local src = q.Source("")
	local b1 = D.TextBox({ Text = src, q.Out("Text", src) })
	local b2 = D.TextBox({ Text = src, q.Out("Text", src) })
	S.flush()
	E.engineWrite(b1, "Text", "one")
	E.engineWrite(b2, "Text", "two")
	local d = S.flush()
	out(("src=%s b1=%s b2=%s deliveries=%d"):format(src:Get(), b1.Text, b2.Text, d))
end)

run("(1d) same frame: user types 'xyz' then program src:Set('reset') / reverse", function(q, out)
	local D = q.Declaration
	local src = q.Source("quad")
	local box = D.TextBox({ Text = src, q.Out("Text", src) })
	S.flush()
	E.engineWrite(box, "Text", "xyz")
	src:Set("reset")
	S.flush()
	out(("type→Set: src=%s box=%s"):format(src:Get(), box.Text))
	src:Set("prog")
	E.engineWrite(box, "Text", "progX")
	S.flush()
	out(("Set→type: src=%s box=%s"):format(src:Get(), box.Text))
end)

run("(1e) non-idempotent OnChange (v..'!') into the Source driving Text — runaway (callback self-limits at 300)", function(q, out)
	local D = q.Declaration
	local src = q.Source("")
	local calls = 0
	local box = D.TextBox({ Text = src, q.OnChange("Text", function(v) calls += 1; if calls >= 300 then return end; src:Set(v .. "!") end) })
	local mountCalls = calls
	local d = S.flush()
	out(("mount-sync calls=%d, calls after first flush=%d, len(Text)=%d, len(src)=%d, deliveries=%d, maxQueue=%d"):format(mountCalls, calls, #box.Text, #src:Get(), d, S.maxQueue))
	calls = 0
	local r = try(function() E.engineWrite(box, "Text", "k"); S.flush() end)
	out(("after mount, user types 'k': %s calls=%d len(Text)=%d len(src)=%d"):format(r, calls, #box.Text, #src:Get()))
end)

run("(1f) plain OnChange (no guard) → scrollY:Set(v); engine writes CanvasPosition-like prop 3 times in one frame", function(q, out)
	local D = q.Declaration
	local scrollY = q.Source(0)
	local seen = {}
	scrollY:Observer(function(s) table.insert(seen, s:Get()) end):Subscribe()
	local f = D.Frame({ q.OnChange("ZIndex", function(v) scrollY:Set(v) end) })
	S.flush(); seen = {}
	E.engineWrite(f, "ZIndex", 1); E.engineWrite(f, "ZIndex", 2); E.engineWrite(f, "ZIndex", 3)
	local d = S.flush()
	out(("scrollY emits seen=[%s] deliveries=%d"):format(j(seen), d))
end)

run("(1g) same frame: reset button Activated (name:Set('quad')) queued, THEN user keystroke box.Text='ab'", function(q, out)
	local D = q.Declaration
	local name = q.Source("x")
	local box = D.TextBox({ Text = name, q.Out("Text", name) })
	local reset = D.TextButton({ Activated = function() name:Set("quad") end })
	S.flush()
	E.engineEvent(reset, "Activated")
	E.engineWrite(box, "Text", "ab")
	local d = S.flush()
	out(("name=%s box.Text=%s deliveries=%d"):format(name:Get(), box.Text, d))
end)

run("(1h) OnChange callback throws on 'bad'; program src:Set('bad') then src:Set('good') (Q149 path)", function(q, out)
	local D = q.Declaration
	local src = q.Source("ok")
	local got = {}
	local box = D.TextBox({ Text = src, q.OnChange("Text", function(v) table.insert(got, v); if v == "bad" then error("onchange boom") end end) })
	S.flush(); got = {}
	local r1 = try(function() src:Set("bad") end)
	S.flush()
	local r2 = try(function() src:Set("good") end)
	S.flush()
	out(("Set('bad'): %s | Set('good'): %s | box.Text=%s got=[%s]"):format(r1, r2, box.Text, j(got)))
end)

--------------------------------------------------------------------------- (2) Property write + OnChange read-back
run("(2) Text = src:Compute(truncate 3) + q.Out('Text', src)", function(q, out)
	local D = q.Declaration
	local src = q.Source("hello")
	local emits = 0
	src:Observer(function() emits += 1 end):Subscribe()
	local shown = src:Compute(function(s) return string.sub(s:Get(), 1, 3) end)
	local box = D.TextBox({ Text = shown, q.Out("Text", src) })
	out(("mount, before flush: src=%s Text=%s emits=%d"):format(src:Get(), box.Text, emits))
	S.flush()
	out(("mount, after flush:  src=%s Text=%s emits=%d"):format(src:Get(), box.Text, emits))
	src:Set("world!!")
	out(("Set('world!!'), read right after: src=%s Text=%s"):format(src:Get(), box.Text))
	S.flush()
	out(("…after flush: src=%s Text=%s emits=%d"):format(src:Get(), box.Text, emits))
	E.engineWrite(box, "Text", "abcdef")
	S.flush()
	out(("user types 'abcdef': src=%s Text=%s emits=%d"):format(src:Get(), box.Text, emits))
	src:Set("xxxxx"); src:Set("yyyyy")
	S.flush()
	out(("two Sets in one frame: src=%s Text=%s emits=%d"):format(src:Get(), box.Text, emits))
end)

--------------------------------------------------------------------------- (3) Event → Set → Property → OnChange chain
run("(3) Activated → count:Set → Text → OnChange → lvl2:Set → label Text → OnChange → lvl3 …(4 hops)", function(q, out)
	local D = q.Declaration
	local count = q.Source(0)
	local lv = { q.Source("0"), q.Source("0"), q.Source("0") }
	local log = {}
	local readInside
	local btn
	btn = D.TextButton({
		Text = count:Compute(function(c) return tostring(c:Get()) end),
		Activated = function()
			count:Set(count:Get() + 1)
			readInside = ("btn.Text=%s lv1=%s lv3=%s"):format(btn.Text, lv[1]:Get(), lv[3]:Get())
		end,
		q.OnChange("Text", function(v) table.insert(log, "b:" .. v); lv[1]:Set(v) end),
	})
	local l1 = D.TextLabel({ Text = lv[1], q.OnChange("Text", function(v) table.insert(log, "l1:" .. v); lv[2]:Set(v) end) })
	local l2 = D.TextLabel({ Text = lv[2], q.OnChange("Text", function(v) table.insert(log, "l2:" .. v); lv[3]:Set(v) end) })
	local l3 = D.TextLabel({ Text = lv[3], q.OnChange("Text", function(v) table.insert(log, "l3:" .. v) end) })
	S.flush()
	log = {}
	E.engineEvent(btn, "Activated")
	out(("inside Activated after Set: %s"):format(readInside or "(not run yet)"))
	out(("after fire, before flush: log=[%s] lv3=%s"):format(j(log), lv[3]:Get()))
	local d = S.flush()
	out(("after flush: log=[%s] lv3=%s deliveries=%d maxQueue=%d"):format(j(log), lv[3]:Get(), d, S.maxQueue))
	out(("inside Activated after Set (read after flush): %s"):format(readInside or "(never)"))
end)

--------------------------------------------------------------------------- (4) Debounce / Throttle with deferred trigger
local function timed(kind, order)
	return function(q, out)
		local D = q.Declaration
		local src = q.Source("")
		local g = src:Apply(if kind == "Debounce" then q.Debounce({ Time = 0.3 }) else q.Throttle({ Time = 0.3 }))
		local emits = {}
		g:Observer(function(s) table.insert(emits, ("%s@%.2f"):format(s:Get(), mock.now())) end):Subscribe()
		local box = D.TextBox({ Text = src, q.Out("Text", src) })
		S.flush()
		emits = {}
		E.engineWrite(box, "Text", "a"); S.flush()
		mock.advanceTime(0.29)
		E.engineWrite(box, "Text", "ab")
		if order == "flush-first" then
			S.flush(); mock.advanceTime(0.01)
		else -- timer resumption point runs before the deferred delivery of the 'ab' write
			mock.advanceTime(0.01); S.flush()
		end
		mock.advanceTime(1)
		out(("emits=[%s] src=%s pendingTimers=%d"):format(j(emits), src:Get(), mock.pendingTimers()))
	end
end
run("(4a) Debounce(0.3) fed by q.Out; 'a'@0, 'ab'@0.29, delivery BEFORE the 0.3 timer", timed("Debounce", "flush-first"))
run("(4b) Debounce(0.3) fed by q.Out; 'a'@0, 'ab'@0.29, 0.3 timer runs BEFORE the delivery", timed("Debounce", "timer-first"))
run("(4c) Throttle(0.3) fed by q.Out; delivery BEFORE timer", timed("Throttle", "flush-first"))
run("(4d) Throttle(0.3) fed by q.Out; timer BEFORE delivery", timed("Throttle", "timer-first"))

--------------------------------------------------------------------------- (5) Destroy inside a deferred callback
local function destroyScenario(deliverAfterDestroy)
	return function(q, out, m)
		S.deliverAfterDestroy = deliverAfterDestroy
		local D = q.Declaration
		local src = q.Source("x")
		local mirror = q.Source("")
		local log = {}
		local slot = q.Slot()
		local btn
		btn = D.TextButton({
			Text = src,
			Activated = function() table.insert(log, "act"); btn:Destroy() end,
			q.OnChange("Text", function(v) table.insert(log, "btnOnChange:" .. tostring(v)); mirror:Set(v) end),
			q.Out("Text", src),
			q.OnDestroyed(function() table.insert(log, "OnDestroyed") end),
			D.TextLabel({ Text = src, q.OnChange("Text", function(v)
				table.insert(log, "childOnChange:" .. tostring(v))
				table.insert(log, "slotAdd:" .. try(function() slot:Add(D.Frame({})) end))
			end) }),
			slot,
		})
		local other = D.TextLabel({ Text = mirror })
		S.flush()
		log = {}
		E.engineEvent(btn, "Activated")
		src:Set("y")
		S.flush()
		out(("log=[%s]"):format(j(log)))
		out(("mirror=%s other.Text=%s src=%s destroyed=%s slot:Length=%s"):format(mirror:Get(), other.Text, src:Get(), tostring(mock.isDestroyed(btn)), tostring(slot.Length:Get())))
		out("later src:Set('z'): " .. try(function() src:Set("z"); S.flush() end) .. " log+=" .. #log)
	end
end
run("(5a) Activated destroys host; same frame src:Set('y') queued Text OnChanges; deliverAfterDestroy=true (H-291)", destroyScenario(true))
run("(5b) same, deliverAfterDestroy=false (sensitivity — engine rule for non-Destroying signals unmeasured)", destroyScenario(false))

--------------------------------------------------------------------------- (6) Slot :List data Set from a signal during mount
run("(6) :List updateFn makes a TextLabel with OnChange('Text') that Sets the list data (Q52 gate)", function(q, out)
	local D = q.Declaration
	local data = q.Source({ "a" })
	local outer = q.Slot()
	local fired = false
	local cbResult = "not run"
	outer:List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev ~= nil then return ctx.Prev end
		return D.TextLabel({ Text = ctx.Item, q.OnChange("Text", function(v)
			if v == "a" and not fired then
				fired = true
				cbResult = try(function() data:Set({ "a", "b" }) end)
			end
		end) })
	end, function(item) return item end)
	local host6
	local r = try(function() host6 = D.Frame({ outer }) end)
	out("mount: " .. r .. " | callback during mount: " .. cbResult)
	S.flush()
	out(("after flush: callback=%s outer.Length=%s later Set: %s"):format(cbResult, tostring(outer.Length:Get()),
		try(function() data:Set({ "a", "b", "c" }); S.flush() end)))
	out(("final outer.Length=%s data=%d host children=%d"):format(tostring(outer.Length:Get()), #data:Get(), host6 and #host6:GetChildren() or -1))
end)

--------------------------------------------------------------------------- (7) Tween Completed / Cancelled and isClaimed
local function tweenCase(label, body)
	run("(7" .. label .. ")", function(q, out)
		local D = q.Declaration
		local log = {}
		local cb = {
			Started = function() table.insert(log, "S") end,
			Completed = function() table.insert(log, "C") end,
			Cancelled = function() table.insert(log, "X") end,
		}
		local size = q.Source(0)
		local f = D.Frame({ Size = size })
		S.flush()
		local function tw(v) local o = { Value = v, Time = 1 } for k, fn in cb do o[k] = fn end return q.Tween(o) end
		size:Set(tw(10))
		local t1 = mock.tweenLog[#mock.tweenLog].tween
		body(q, f, size, tw, t1, log, out)
		out(("log=[%s] tweens=%d isClaimed(f)=%s"):format(j(log), #mock.tweenLog, tostring(q.Backend.isClaimed(f))))
	end)
end
tweenCase("a) natural finish, then flush", function(q, f, size, tw, t1, log, out)
	f.Size = 10; t1:simulateCompleted(); out("before flush: [" .. j(log) .. "]"); S.flush()
end)
tweenCase("b) natural finish, then host Destroy in the same frame, then flush (H-594)", function(q, f, size, tw, t1, log, out)
	f.Size = 10; t1:simulateCompleted(); f:Destroy(); S.flush()
end)
tweenCase("c) host Destroy, then natural finish (tween keeps running on corpse), then flush", function(q, f, size, tw, t1, log, out)
	f:Destroy(); S.flush(); f.Size = 10; t1:simulateCompleted(); S.flush()
end)
tweenCase("d) natural finish, then size:Set(new tween) in the same frame (deferred-window path), then flush", function(q, f, size, tw, t1, log, out)
	f.Size = 10; t1:simulateCompleted(); size:Set(tw(20)); S.flush()
end)
tweenCase("e) replace while running (quad Cancel → engine Cancelled notice queued), then flush", function(q, f, size, tw, t1, log, out)
	size:Set(tw(20)); S.flush()
end)
tweenCase("f) Completed chains the next tween (Set inside Completed), natural finish, flush", function(q, f, size, tw, t1, log, out)
	-- replace the running tween with one whose Completed chains
	local chained = false
	local o = { Value = 30, Time = 1, Completed = function() table.insert(log, "C30"); if not chained then chained = true; size:Set(q.Tween({ Value = 40, Time = 1, Started = function() table.insert(log, "S40") end })) end end }
	size:Set(q.Tween(o)); S.flush()
	local t2 = mock.tweenLog[#mock.tweenLog].tween
	f.Size = 30; t2:simulateCompleted(); S.flush()
	out("last tween PlaybackState=" .. tostring(mock.tweenLog[#mock.tweenLog].tween.PlaybackState))
end)
tweenCase("g) natural finish, host Destroy, deliverAfterDestroy=false", function(q, f, size, tw, t1, log, out)
	S.deliverAfterDestroy = false
	f.Size = 10; t1:simulateCompleted(); f:Destroy(); S.flush()
end)

--------------------------------------------------------------------------- (5c) direct (sync) Slot:Add after its host was destroyed
run("(5c) direct: host with a Slot destroyed, then slot:Add (no deferral involved)", function(q, out)
	local D = q.Declaration
	local slot = q.Slot()
	local host = D.Frame({ slot })
	host:Destroy(); S.flush()
	local fr
	local r = try(function() fr = D.Frame({}); slot:Add(fr) end)
	out(("slot:Add after Destroy: %s Length=%s fr.Parent=%s fr claimed=%s"):format(r, tostring(slot.Length:Get()), tostring(fr and fr.Parent), tostring(fr and q.Backend.isClaimed(fr))))
end)
