--!nocheck
local H = require("./probe_h")
local F, on = H.F, H.on
local function run(variant)
	local q, lay = H.new()
	local host = H.mock.Instance.new("Frame")
	local inner = q.Slot({ F("x"), F("r") })
	local P = q.Slot({ inner, F("tail") })
	q.Dispatch.drive(host, { P })
	local y = F("y")
	local log = {}
	local r = inner._elements[2]
	local fn = function()
		local ok, e = pcall(function() P:Add(F("pz"), 2) end)
		log[#log+1] = "P:Add ok=" .. tostring(ok) .. (ok and "" or (string.match(e, "Quad%d+") or e))
	end
	if variant == "inner:Add" then on(y, "in", fn); inner:Add(y)
	else on(r, "out", fn); inner:Remove(2) end
	local logical = table.concat(H.leaves(q, P), ",")
	print(variant, table.concat(log, "|"), "logical", logical, "layout", lay(host), logical == lay(host) and "OK" or "DIVERGED")
end
run("inner:Add"); run("inner:Remove")
