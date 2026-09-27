--!nocheck
-- E75 F: Quad0228 — version gate. Needs a quad-base module whose Version differs; we clone the real
-- module table shallowly (fresh New()) and overwrite Version, since the real quad-base is 3.2.0.
local R = require("../runner")
local Quad = require("../../../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../../../quad-roblox/src").QuadRoblox
local TVC = require("../../../../quad-roblox/luau_packages/type_version_check")
local function fresh(ver)
	local q = Quad.New and Quad.New() or Quad
	q.Version = ver
	return q
end
R.case({ id = "Quad0228",
	trigger = function() fresh("3.1.0"):UseProvider(QuadRoblox) end,
	fix = function()
		local q = fresh("3.2.0")
		local r = q:UseProvider(QuadRoblox)
		return r.Declaration ~= nil, "3.2.0 accepted"
	end })
R.case({ id = "Quad0228", note = "3.2.5 (higher patch, same minor) and 3.4.0 (higher minor) per page '같은 메이저에서 3.2.0 이상'",
	trigger = function() fresh("4.0.0"):UseProvider(QuadRoblox) end,
	fix = function()
		local a = TVC.matchesPattern("3.2.5", "3.2^.0^")
		local b = TVC.matchesPattern("3.4.0", "3.2^.0^")
		local c = TVC.matchesPattern("3.10.1", "3.2^.0^")
		return a and b and c, ("3.2.5=%s 3.4.0=%s 3.10.1=%s"):format(tostring(a), tostring(b), tostring(c))
	end })
R.case({ id = "Quad0228", note = "prerelease base 3.3.0-rc.1 blocked; fix = quad-roblox pattern naming the rc exactly",
	trigger = function() fresh("3.3.0-rc.1"):UseProvider(QuadRoblox) end,
	fix = function()
		local exact = TVC.matchesPattern("3.3.0-rc.1", "3.3.0-rc.1")
		local caret = TVC.matchesPattern("3.3.0-rc.1", "3.3.0-rc.1^")
		return exact, ("exact=%s rc^=%s"):format(tostring(exact), tostring(caret))
	end })
print("New exists:", Quad.New ~= nil)
R.done()
