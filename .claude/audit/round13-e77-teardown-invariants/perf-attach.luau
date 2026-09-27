--!nocheck
-- E77 perf attribution 2: one attachment kind per component (n components under a :List), dispose(root).
-- per-unit teardown at n=100 vs n=6400; "none" is the plain-children control.
local H = require("./harness")
local q, D, mock = H.q, H.D, H.mock
local pulse = q.Source(0)
local ATT = {
	none = function(i) return nil end,
	tween = function(i) local s = q.Source(i); return s:Compute(function(x) return q.Tween({ Value = x:Get(), Time = 1 }) end), "Size" end,
	tag = function(i) return q.Tag("T" .. (i % 4)) end,
	attr = function(i) return q.Attr({ A1 = i }) end,
	effect = function(i) return q.Effect(function() return function() end end) end,
	onDestroyed = function(i) return q.OnDestroyed(function() end) end,
	ref = function(i) return q.Ref(nil) end,
	observer = function(i) return pulse:Observer(function() end) end,
	debounce = function(i) return pulse:Apply(q.Debounce({ Time = 1 })), "LayoutOrder" end,
}
local function build(kind, n)
	local keys = {}; for i = 1, n do keys[i] = i end
	return D.Frame({ q.Slot():List(q.Source(keys), function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local v, key = ATT[kind](ctx.Item)
		local p = { Name = "c", D.TextLabel({}), D.Frame({}) }
		if key then p[key] = v elseif v ~= nil then table.insert(p, v) end
		return D.Frame(p)
	end) })
end
for _, kind in { "none", "tween", "tag", "attr", "effect", "onDestroyed", "ref", "observer", "debounce" } do
	local row = {}
	for _, n in { 100, 1600, 6400 } do
		local ts = {}
		for _ = 1, 3 do
			collectgarbage("collect")
			local root = build(kind, n)
			if kind == "debounce" then pulse:Set(pulse:Get() + 1) end
			local t0 = os.clock(); q.dispose(root); table.insert(ts, os.clock() - t0)
			H.runTask(3); mock.resetTweenLog()
		end
		table.sort(ts)
		table.insert(row, string.format("n=%d %.2fus", n, ts[2] * 1e6 / n))
	end
	print(string.format("%-12s %s", kind, table.concat(row, "  ")))
end
