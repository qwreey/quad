--!nocheck
-- Q152 scratch: a handler that follows the extend/02 wording ("getBlocker = batch gate for several
-- registrations") and toggles it INSIDE drive. Count recomputes; check final offsets.
local E = require("./env")
for _, mode in { "none", "toggle", "ownsGate" } do
	local q = E.newBase()
	local BK = q.Bookkeeping
	local nrec = 0
	local orig = BK._recompute
	BK._recompute = function(...) nrec += 1; return orig(...) end
	local sources = {}
	q.Dispatch.addHandler({
		name = "Leaf",
		isHandlable = function(_i, k, v) return type(k) == "number" and type(v) == "number" end,
		priority = q.Dispatch.HANDLER_PRIORITY_NORMAL,
		process = function(inst, k, v)
			local b = BK.getBlocker(inst)
			local owns = (mode == "toggle") or (mode == "ownsGate" and not b.Blocking)
			if owns then b:On() end
			local src = q.Source(-1); sources[k] = src
			BK.setOffsetSource(inst, k, src); BK.setLength(inst, k, v)
			if owns then b:Off() end
			return function() end
		end,
	})
	local N = tonumber(os.getenv and nil) or 2000
	local props = {}
	for i = 1, N do props[i] = 1 end
	local inst = E.mock.Instance.new("Frame")
	local t0 = os.clock()
	q.Dispatch.drive(inst, props)
	local dt = (os.clock() - t0) * 1000
	local ok = true
	for i = 1, N do if sources[i]:Get() ~= i - 1 then ok = false end end
	print(string.format("mode %-8s  N=%d  internal-recompute calls (via BK._recompute) %d  offsets correct %s  %.2f ms", mode, N, nrec, tostring(ok), dt))
end
