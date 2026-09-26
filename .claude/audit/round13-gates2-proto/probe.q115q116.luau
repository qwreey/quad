--!nocheck
-- round13 E24 B — q.Animate option matrix (eager literal check vs per-run check vs no check),
-- CanAnimate / callback paths, Value shapes the source State can carry.
local H = require("./probe-setup")
local q, D, mock = H.q, H.D, H.mock
local log = mock.tweenLog
local function first(e) return (tostring(e):gsub("\n.*", "")) end
local function short(e) local s = first(e); local id = s:match("Quad%d%d%d%d") or "VM"; local w = s:match("([%w%-%._]+%.luau:%d+):") return id .. " @" .. tostring(w) end

local function run(label, info, values, prop)
	prop = prop or "BackgroundTransparency"
	local okA, fac = pcall(function() return q.Animate(info) end) -- LINE 13 (Animate call)
	if not okA then print(string.format("%-40s ANIMATE %s", label, short(fac))) return end
	mock.resetTweenLog()
	local src = q.Source(values[1])
	local okB, st = pcall(function() return src:Apply(fac) end) -- LINE 17 (Apply)
	if not okB then print(string.format("%-40s APPLY %s", label, short(st))) return end
	local okC, f = pcall(function() return D.Frame({ [prop] = st }) end) -- LINE 19 (mount)
	if not okC then print(string.format("%-40s MOUNT %s", label, short(f))) return end
	local out = {}
	for i = 2, #values do
		local ok, e = pcall(function() src:Set(values[i]) end) -- LINE 23 (Set)
		table.insert(out, if ok then ("set->" .. tostring(f[prop]) .. " tw" .. #log) else ("SETERR " .. short(e)))
	end
	print(string.format("%-40s OK first=%s | %s", label, tostring(f[prop]), table.concat(out, "; ")))
end

local fired = {}
local function cb(tag) return function() table.insert(fired, tag) end end
local function F() local s = table.concat(fired, ","); table.clear(fired); return s end
print("== Q115 callback State ==")
run("K1 Started=fn animated", { Started = cb("S") }, { 0, 1 }); print("   fired:", F())
run("K2 Started=State(fn) animated", { Started = q.Source(cb("S")) }, { 0, 1 }); print("   fired:", F())
run("K3 Started=State(fn) CanAnimate=false", { Started = q.Source(cb("S")), CanAnimate = false }, { 0, 1 }); print("   fired:", F())
run("K4 Completed=State(fn) CanAnimate=State(true)", { Completed = q.Source(cb("C")), CanAnimate = q.Source(true) }, { 0, 1 }); print("   fired:", F())
run("K5 Cancelled=Compute State", { Cancelled = q.Source(1):Compute(function() return cb("X") end) }, { 0, 1 }); print("   fired:", F())
run("K6 Started=true literal", { Started = true }, { 0, 1 })
run("K7 CanAnimate=false Completed=fn", { CanAnimate = false, Completed = cb("C") }, { 0, 1 }); print("   fired:", F())
-- runtime reduce-motion flip with a State callback (the ledger scenario)
do
	local can = q.Source(true)
	local ok, e = pcall(function()
		local src = q.Source(0)
		local st = src:Apply(q.Animate({ Started = q.Source(cb("S")), CanAnimate = can }))
		local f = D.Frame({ BackgroundTransparency = st })
		src:Set(0.5); can:Set(false); src:Set(1)
	end)
	print("K8 State cb + flip CanAnimate at runtime", ok and "OK" or short(e), " fired:", F())
end
print("== Q116 CanAnimate ==")
run("C1 CanAnimate='no'", { CanAnimate = "no" }, { 0, 1 })
run("C2 CanAnimate=0", { CanAnimate = 0 }, { 0, 1 })
run("C3 CanAnimate=function", { CanAnimate = function() return false end }, { 0, 1 })
run("C4 CanAnimate=State(nil)", { CanAnimate = q.Source(nil) }, { 0, 1 })
run("C5 CanAnimate=false", { CanAnimate = false }, { 0, 1 })
run("C6 CanAnimate=true", { CanAnimate = true }, { 0, 1 })
run("C7 CanAnimate=State(true)", { CanAnimate = q.Source(true) }, { 0, 1 })
run("C8 CanAnimate=State('no')", { CanAnimate = q.Source("no") }, { 0, 1 })
do
	local can = q.Source(true)
	local ok, e = pcall(function()
		local src = q.Source(0)
		local f = D.Frame({ BackgroundTransparency = src:Apply(q.Animate({ Time = 0.1, CanAnimate = can })) })
		can:Set(0) -- no re-run (option change alone)
		src:Set(1) -- LINE: this Set re-runs with the bad option
	end)
	print("C9 State(true)->Set(0) then value Set", ok and "OK" or short(e))
	print("   full:", ok and "" or first(e))
end
run("C10 CanAnimate=None", { CanAnimate = q.None }, { 0, 1 })
print("done")
