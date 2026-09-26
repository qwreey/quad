--!nocheck
-- round13 E18 probe I — Backend slot inventory of a bare New() vs after the mock/roblox provider. Run from repo root.
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local bare = Quad.New()
local keys = {}
for k in bare.Backend do table.insert(keys, k) end
table.sort(keys)
print(#keys, table.concat(keys, " "))
local r = Quad.New():UseProvider(QuadRoblox)
local changed, same = {}, {}
for _, k in keys do if r.Backend[k] ~= bare.Backend[k] then table.insert(changed, k) end end
local n = 0; for k in r.Backend do n += 1 end
print("roblox Backend keys", n)
-- which remain stubs (error message Quad0108) after QuadRoblox?
for _, k in keys do
	local ok, err = pcall(r.Backend[k])
	if not ok and tostring(err):find("Quad0108") then print("still stub after roblox:", k) end
end
