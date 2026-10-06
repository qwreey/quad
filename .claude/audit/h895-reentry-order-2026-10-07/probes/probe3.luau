--!nocheck
local E = require("../round13-e79-deferred-signals/env")
local S, mock = E.S, E.mock
local MODES = { "imm", "def" }
local LOG
local function T(q, val, extra)
	local t = { Value = val,
		Started = function(_, _, v) table.insert(LOG, "S" .. tostring(v)) end,
		Cancelled = function(_, _, v) table.insert(LOG, "X" .. tostring(v)) end,
		Completed = function(_, _, v) table.insert(LOG, "C" .. tostring(v)) end }
	for kk, vv in extra or {} do t[kk] = vv end
	return q.Tween(t)
end
local function playing()
	local n, ts = 0, {}
	for _, e in mock.tweenLog do
		if e.tween.PlaybackState == "Playing" then n += 1; table.insert(ts, tostring(e.props.Size)) end
	end
	return n, table.concat(ts, ",")
end
local function run(title, fn)
	print(("="):rep(90)); print(title)
	for _, m in MODES do
		S.reset(m); LOG = {}
		local q = E.newProv()
		local lines = {}
		local function out(s) table.insert(lines, s) end
		local ok, err = pcall(fn, q, out, m)
		if not ok then out("THREW: " .. tostring(err):gsub("\n.*", "")) end
		if #S.errors > 0 then out("listener errors: " .. table.concat(S.errors, " | ")) end
		print(("  [%s] %s"):format(m, table.concat(lines, "\n         ")))
	end
end
local function tail(q, out, f, src)
	S.flush()
	local n, w = playing()
	out(("after: playing=%d [%s] Size=%s cb=[%s]"):format(n, w, tostring(f.Size), table.concat(LOG, " ")))
	LOG = {}
	q.Dispatch.retractFrom(f, "Size", 1); S.flush()
	n, w = playing()
	out(("after retractFrom: playing=%d [%s] cb=[%s]"):format(n, w, table.concat(LOG, " ")))
end
local function mk(q, src, cond, action)
	return q.Declaration.Frame({ Size = src, q.OnChange("Size", function(v) if cond(v) then action() end end) })
end
run("(A) plain: tween→10, Set(7) → OnChange(7) → Tween 99", function(q, out)
	local src = q.Source(0); local armed = false
	local f = mk(q, src, function(v) return armed and v == 7 end, function() armed = false; src:Set(T(q, 99)) end)
	S.flush(); src:Set(T(q, 10)); S.flush()
	armed = true; src:Set(7)
	tail(q, out, f, src)
end)
run("(B) Finish: tween→10, Set(Tween 20 Finish) → snap 10 → OnChange(10) → Tween 99", function(q, out)
	local src = q.Source(0); local armed = false
	local f = mk(q, src, function(v) return armed and v == 10 end, function() armed = false; src:Set(T(q, 99)) end)
	S.flush(); src:Set(T(q, 10)); S.flush()
	armed = true; src:Set(T(q, 20, { Override = "Finish" }))
	tail(q, out, f, src)
end)
run("(B0) Finish, no re-entry (order baseline)", function(q, out)
	local src = q.Source(0)
	local f = q.Declaration.Frame({ Size = src })
	src:Set(T(q, 10)); src:Set(T(q, 20, { Override = "Finish" }))
	tail(q, out, f, src)
end)
run("(C) zero-time: tween→10, Set(Tween 5 Time=0) → OnChange(5) → Tween 99", function(q, out)
	local src = q.Source(0); local armed = false
	local f = mk(q, src, function(v) return armed and v == 5 end, function() armed = false; src:Set(T(q, 99)) end)
	S.flush(); src:Set(T(q, 10)); S.flush()
	armed = true; src:Set(T(q, 5, { Time = 0 }))
	tail(q, out, f, src)
end)
run("(C0) zero-time no re-entry baseline", function(q, out)
	local src = q.Source(0)
	local f = q.Declaration.Frame({ Size = src })
	src:Set(T(q, 10)); src:Set(T(q, 5, { Time = 0 }))
	tail(q, out, f, src)
end)
run("(F) plain from true: Set(3) → OnChange(3) → Tween 99", function(q, out)
	local src = q.Source(1); local armed = false
	local f = mk(q, src, function(v) return armed and v == 3 end, function() armed = false; src:Set(T(q, 99)) end)
	S.flush(); armed = true; src:Set(3)
	tail(q, out, f, src)
end)
run("(H) plain re-entry, inner plain: tween→10, Set(7) → OnChange(7) → Set(8)", function(q, out)
	local src = q.Source(0); local armed = false
	local f = mk(q, src, function(v) return armed and v == 7 end, function() armed = false; src:Set(8) end)
	S.flush(); src:Set(T(q, 10)); S.flush()
	armed = true; src:Set(7)
	tail(q, out, f, src)
end)
run("(I) Finish re-entry with inner dedup-equal (Tween 10 = prev target)", function(q, out)
	local src = q.Source(0); local armed = false
	local f = mk(q, src, function(v) return armed and v == 10 end, function() armed = false; src:Set(T(q, 10)) end)
	S.flush(); src:Set(T(q, 10)); S.flush()
	armed = true; src:Set(T(q, 20, { Override = "Finish" }))
	tail(q, out, f, src)
end)
run("(J) Completed chain from zero-time snap (Q164 a')", function(q, out)
	local src = q.Source(0)
	local f = q.Declaration.Frame({ Size = src })
	src:Set(1)
	src:Set(T(q, 5, { Time = 0, Completed = function() table.insert(LOG, "C5"); src:Set(T(q, 99)) end }))
	tail(q, out, f, src)
end)
