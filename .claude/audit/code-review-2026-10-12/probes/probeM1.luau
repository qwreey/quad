--!nocheck
-- main probe: a :List reconcile whose backend call synchronously re-sets the list's own data
local H = require("./probe_h")
local F, on = H.F, H.on
for _, variant in { "add-then-set", "remove-then-set" } do
	local q, lay = H.new()
	local host = H.mock.Instance.new("Frame")
	local data = q.Source({ "a", "b" })
	local made = {}
	local L = q.Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return nil end
		if ctx.Prev then return ctx.Prev end
		local f = F(ctx.Item); made[ctx.Item] = f
		if ctx.Item == "c" then on(f, "in", function() data:Set({ "a", "b", "c", "d" }) end) end
		return f
	end, function(item) return item end)
	local P = q.Slot({ F("head"), L, F("tail") })
	q.Dispatch.drive(host, { P })
	if variant == "remove-then-set" then on(made.b, "out", function() data:Set({ "a", "z" }) end) end
	local ok, e = pcall(function()
		if variant == "add-then-set" then data:Set({ "a", "b", "c" }) else data:Set({ "a" }) end
	end)
	local logical = table.concat(H.leaves(q, P), ",")
	print(variant, "ok", ok, ok and "" or tostring(e):sub(1, 120))
	print("  logical", logical, "layout", lay(host), "Length", L.Length:Get(), logical == lay(host) and "OK" or "DIVERGED")
end
