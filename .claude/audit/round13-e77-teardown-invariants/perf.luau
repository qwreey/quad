--!nocheck
-- E77 perf shape: teardown time vs tree size for a mixed "application" subtree (Effect+cleanup, Observer on a
-- module-lived source, Tag, Attr, OnDestroyed, Tween on Size, Debounce-gated property, Ref) — wide (:List of
-- components, 3 nodes each) and deep (static chain). mock backend; relative shape only.
local H = require("./harness")
local VARIANT = ({ ... })[1] or "full" -- full | noExt | noPulse | bare
local q, D, mock = H.q, H.D, H.mock
local pulse = q.Source(0)
local ext = mock.newSignal()
local function comp(i)
	local sz = q.Source(i)
	return D.Frame({
		Name = "c" .. i,
		Size = sz:Compute(function(s) return q.Tween({ Value = s:Get(), Time = 1 }) end),
		LayoutOrder = if VARIANT == "noPulse" or VARIANT == "bare" then i else pulse:Apply(q.Debounce({ Time = 1 })),
		q.Tag("T" .. (i % 4)), q.Attr({ A1 = i }),
		if VARIANT == "noExt" or VARIANT == "bare" then q.Effect(function() return function() end end) else q.Effect(function() local c = ext:Connect(function() end); return function() c:Disconnect() end end),
		if VARIANT == "noPulse" or VARIANT == "bare" then q.Ref(nil) else pulse:Observer(function() end),
		q.OnDestroyed(function() end),
		q.Ref(nil),
		D.TextLabel({ Text = "x", if VARIANT == "noPulse" or VARIANT == "bare" then q.Ref(nil) else pulse:Observer(function() end) }),
		D.Frame({ q.Tag("inner") }),
	})
end
local function wide(n)
	local keys = {}
	for i = 1, n do keys[i] = i end
	return D.Frame({ q.Slot():List(q.Source(keys), function(ctx) if ctx.Item == q.KeyGone then return nil end return ctx.Prev or comp(ctx.Item) end) })
end
local function deep(n)
	local cur = comp(0)
	for i = 1, n - 1 do cur = D.Frame({ cur, pulse:Observer(function() end), q.Effect(function() return function() end end) }) end
	return cur
end
local function median(t) table.sort(t); return t[math.ceil(#t / 2)] end
local function measure(label, mk, n, how)
	local ts, tb = {}, {}
	for _ = 1, 3 do
		collectgarbage("collect")
		local t0 = os.clock()
		local root = mk(n)
		local t1 = os.clock()
		pulse:Set(pulse:Get() + 1) -- open debounce windows
		local t2 = os.clock()
		if how == "dispose" then q.dispose(root) else root:Destroy() end
		local t3 = os.clock()
		H.runTask(3); mock.resetTweenLog()
		table.insert(tb, t1 - t0); table.insert(ts, t3 - t2)
	end
	local b, s = median(tb), median(ts)
	print(string.format("%-6s %-8s n=%6d  build %8.2f ms  teardown %8.2f ms  teardown/unit %6.2f us", label, how, n, b * 1000, s * 1000, s * 1e6 / n))
end
print("variant", VARIANT)
for _, how in (if VARIANT == "full" then { "dispose", "destroy" } else { "dispose" }) do
	for _, n in { 100, 400, 1600, 6400 } do measure("wide", wide, n, how) end
	for _, n in { 50, 200, 800, 3200 } do measure("deep", deep, n, how) end
end
