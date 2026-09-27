--!nocheck
-- Bookkeeping ownerKey kinds other than a claimed Instance / Slot: which error, which ID (mock backend and the real
-- quad-roblox provider on mock shims, via E64's env)
local E = require("./env")
local E64 = require("../round13-e64-dispatch-fuzz/env")
local function try(f, ...)
	local ok, e = pcall(f, ...)
	return if ok then "ok" else tostring(e):gsub("^[^:]*:%d+: ", ""):sub(1, 110)
end
for name, mk in { mock = E.newBase, roblox = E64.newProv } do
	local q = mk()
	local BK = q.Bookkeeping
	print(`[{name}]`)
	print("  setEmpty({}, 1):", try(BK.setEmpty, {}, 1))
	print("  getBookkeeping('str'):", try(BK.getBookkeeping, "str"))
	print("  getBlocker(0/0):", try(BK.getBlocker, 0 / 0))
	print("  getBookkeeping(0/0):", try(BK.getBookkeeping, 0 / 0))
	print("  setEmpty(foreign unclaimed Instance, 1):", try(BK.setEmpty, E.mock.Instance.foreign("Frame"), 1))
	print("  claimOwnerAt(e, inst, 0/0):", try(BK.claimOwnerAt, {}, E.mock.Instance.new("Frame"), 0 / 0))
	print("  claimOwnerAt(0/0, inst, 1):", try(BK.claimOwnerAt, 0 / 0, E.mock.Instance.new("Frame"), 1))
end
