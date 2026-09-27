--!nocheck
-- E80 C65: quad_roblox → quad_base version pattern "3.2^.0^" (runtime check in UseProvider)
local H = require("../harness")
local L = require("../lib")
local TVC = require("../../../../quad-roblox/luau_packages/type_version_check")
for _, v in { "3.2.0", "3.2.5", "3.3.0", "3.9.1", "3.1.9", "4.0.0", "3.3.0-rc.2", "2.24.0" } do
	print(string.format("  matches(%s, 3.2^.0^) = %s", v, tostring(TVC.matchesPattern(v, "3.2^.0^"))))
end
L.check("C65 3.3.0 & 3.9.1 accepted, 3.1.9/4.0.0 rejected", TVC.matchesPattern("3.3.0", "3.2^.0^") and TVC.matchesPattern("3.9.1", "3.2^.0^") and not TVC.matchesPattern("3.1.9", "3.2^.0^") and not TVC.matchesPattern("4.0.0", "3.2^.0^"), "")
L.check("C65 prerelease pattern takes only that build", TVC.matchesPattern("3.3.0-rc.2", "3.3.0-rc.2") and not TVC.matchesPattern("3.3.0-rc.3", "3.3.0-rc.2"), "")
local Q = H.Quad.New()
rawset(Q, "Version", "3.7.0")
local ok, e = pcall(function() Q:UseProvider(H.QuadRoblox) end)
L.check("C65 UseProvider accepts quad_base 3.7.0", ok, ok and "ok" or L.first(e))
local Q2 = H.Quad.New()
rawset(Q2, "Version", "4.0.0")
local m, id = L.err("C65 UseProvider with 4.0.0", function() Q2:UseProvider(H.QuadRoblox) end)
L.check("C65 4.0.0 rejected", id == "Quad0228", id)
L.done()
