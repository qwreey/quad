--!nocheck
-- round13 E24 B — q.Animate option matrix (eager literal check vs per-run check vs no check),
-- CanAnimate / callback paths, Value shapes the source State can carry.
local H = require("./round13-e15-probe-setup")
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

print("== literal eager validation ==")
run("Animate(nil)", nil, { 0, 1 })
run("Time='x'", { Time = "x" }, { 0, 1 })
run("Time=-1", { Time = -1 }, { 0, 1 })
run("Reverses=1", { Reverses = 1 }, { 0, 1 })
run("Override='cancel'", { Override = "cancel" }, { 0, 1 })
run("Style='Quad' string (unchecked)", { Style = "Quad" }, { 0, 1 })
print("== State options (per-run) ==")
run("Time=State('x')", { Time = q.Source("x") }, { 0, 1 })
run("Time=State(nil)", { Time = q.Source(nil) }, { 0, 1 })
run("Override=State('nope')", { Override = q.Source("nope") }, { 0, 1 })
print("== CanAnimate (no runtime check) ==")
run("CanAnimate='no' (string)", { CanAnimate = "no" }, { 0, 1 })
run("CanAnimate=0", { CanAnimate = 0 }, { 0, 1 })
run("CanAnimate=State(nil)", { CanAnimate = q.Source(nil) }, { 0, 1 })
run("CanAnimate=false", { CanAnimate = false }, { 0, 1 })
run("CanAnimate=function", { CanAnimate = function() return false end }, { 0, 1 })
print("== callbacks via Animate ==")
local fired = {}
local function cb(tag) return function() table.insert(fired, tag) end end
run("Started=fn (animated)", { Started = cb("S") }, { 0, 1 })
print("  fired:", table.concat(fired, ",")); table.clear(fired)
run("Started=State(fn) animated", { Started = q.Source(cb("S")) }, { 0, 1 })
print("  fired:", table.concat(fired, ",")); table.clear(fired)
run("Started=State(fn) CanAnimate=false", { Started = q.Source(cb("S")), CanAnimate = false }, { 0, 1 })
print("  fired:", table.concat(fired, ",")); table.clear(fired)
run("Started=true literal", { Started = true }, { 0, 1 })
run("Completed=fn Dedup=State('x') CanAnim=false", { Completed = cb("C"), Dedup = q.Source("x"), CanAnimate = false }, { 0, 1 })
run("Completed=fn Dedup=State('x') animated", { Completed = cb("C"), Dedup = q.Source("x") }, { 0, 1 })
run("CanAnim=false Style='bad' Time='x'State", { CanAnimate = false, Completed = cb("C"), Time = q.Source("x") }, { 0, 1 })
print("  fired:", table.concat(fired, ",")); table.clear(fired)
print("== what the source carries ==")
run("value false (Visible)", {}, { true, false, true }, "Visible")
run("value NaN twice", {}, { 0, 0 / 0, 0 / 0 })
run("value Tween (already wrapped)", {}, { 0, q.Tween({ Value = 1 }) })
run("value None", {}, { 0, q.None, 1 })
run("value Void", {}, { 0, q.Void })
run("value 'str' into number prop", {}, { 0, "x" })
-- nested State: the Source carries a State
local inner = q.Source(0.2)
run("value State (State<State>)", {}, { 0, inner })
print("== Value key in Animate info (ignored?) ==")
q.debug = true
run("Animate{Value=5}", { Value = 5 }, { 0, 1 })
run("Animate{Duration=5}", { Duration = 5 }, { 0, 1 })
q.debug = false
