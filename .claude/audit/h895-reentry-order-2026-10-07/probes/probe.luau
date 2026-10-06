--!nocheck
-- H-895 probe: Property write-before-record under synchronous OnChange re-entry; three modes (mock/imm/def).
local E = require("../round13-e79-deferred-signals/env")
local S, mock = E.S, E.mock
local MODES = { "mock", "imm", "def" }
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
		S.reset(m)
		local q = E.newProv()
		local lines = {}
		local function out(s) table.insert(lines, s) end
		local ok, err = pcall(fn, q, out, m)
		if not ok then out("THREW: " .. tostring(err):gsub("\n.*", "")) end
		if #S.errors > 0 then out("listener errors: " .. table.concat(S.errors, " | ")) end
		print(("  [%s] %s"):format(m, table.concat(lines, "\n         ")))
	end
end
-- common tail: after the scenario, is every playing tween reachable? teardown (retractFrom) then count
local function tail(q, out, f, src)
	S.flush()
	local n, w = playing()
	out(("after scenario: playing=%d [%s] Size=%s src=%s"):format(n, w, tostring(f.Size), tostring(src:Get())))
	src:Set(5); S.flush()
	n, w = playing()
	out(("after plain src:Set(5): playing=%d [%s] Size=%s"):format(n, w, tostring(f.Size)))
end
local function tail2(q, out, f)
	S.flush()
	local n, w = playing()
	out(("after scenario: playing=%d [%s]"):format(n, w))
	q.Dispatch.retractFrom(f, "Size", 1); S.flush()
	n, w = playing()
	out(("after retractFrom: playing=%d [%s]"):format(n, w))
end

local function mk(q, src, cond, action)
	return q.Declaration.Frame({ Size = src, q.OnChange("Size", function(v) if cond(v) then action() end end) })
end

run("(A) plain path: tween→10 active, src:Set(7) → OnChange(7) → src:Set(Tween 99)", function(q, out)
	local src = q.Source(0); local armed = false
	local f = mk(q, src, function(v) return armed and v == 7 end, function() armed = false; src:Set(q.Tween({ Value = 99 })) end)
	src:Set(q.Tween({ Value = 10 })); S.flush()
	armed = true; src:Set(7)
	tail(q, out, f, src)
end)
run("(A') same, teardown instead", function(q, out)
	local src = q.Source(0); local armed = false
	local f = mk(q, src, function(v) return armed and v == 7 end, function() armed = false; src:Set(q.Tween({ Value = 99 })) end)
	src:Set(q.Tween({ Value = 10 })); S.flush()
	armed = true; src:Set(7)
	tail2(q, out, f)
end)
run("(B) Finish path: tween→10 active, src:Set(Tween 20 Finish) → snap write 10 → OnChange(10) → Tween 99", function(q, out)
	local src = q.Source(0); local armed = false
	local f = mk(q, src, function(v) return armed and v == 10 end, function() armed = false; src:Set(q.Tween({ Value = 99 })) end)
	src:Set(q.Tween({ Value = 10 })); S.flush()
	armed = true; src:Set(q.Tween({ Value = 20, Override = "Finish" }))
	tail(q, out, f, src)
end)
run("(C) zero-time path: tween→10 active, src:Set(Tween 5 Time=0) → OnChange(5) → Tween 99", function(q, out)
	local src = q.Source(0); local armed = false
	local f = mk(q, src, function(v) return armed and v == 5 end, function() armed = false; src:Set(q.Tween({ Value = 99 })) end)
	src:Set(q.Tween({ Value = 10 })); S.flush()
	armed = true; src:Set(q.Tween({ Value = 5, Time = 0 }))
	src:Set(6) S.flush()
	local n, w = playing()
	out(("after plain src:Set(6): playing=%d [%s] Size=%s"):format(n, w, tostring(f.Size)))
end)
run("(D) first-set plain (prev nil): mount Size=src(1); OnChange(1) → src:Set(2); src:Set(Tween 99)", function(q, out)
	local src = q.Source(1); local armed = true
	local f = mk(q, src, function(v) return armed and v == 1 end, function() armed = false; src:Set(2); src:Set(q.Tween({ Value = 99 })) end)
	tail(q, out, f, src)
end)
run("(E) first-set snap (prev nil, Tween): Size=src(Tween 1); OnChange(1) → src:Set(2); src:Set(Tween 99)", function(q, out)
	local src = q.Source(q.Tween({ Value = 1 })); local armed = true
	local f = mk(q, src, function(v) return armed and v == 1 end, function() armed = false; src:Set(2); src:Set(q.Tween({ Value = 99 })) end)
	tail(q, out, f, src)
end)
run("(F) plain from plain record (prev true): src:Set(3) → OnChange(3) → Tween 99", function(q, out)
	local src = q.Source(1); local armed = false
	local f = mk(q, src, function(v) return armed and v == 3 end, function() armed = false; src:Set(q.Tween({ Value = 99 })) end)
	S.flush(); armed = true; src:Set(3)
	tail(q, out, f, src)
end)
run("(G) snap-path Completed chaining (Q164 a'): Tween{Time=0, Completed=chain Tween 99}", function(q, out)
	local src = q.Source(0)
	local f = q.Declaration.Frame({ Size = src })
	src:Set(1)
	src:Set(q.Tween({ Value = 5, Time = 0, Completed = function() src:Set(q.Tween({ Value = 99 })) end }))
	tail(q, out, f, src)
end)
