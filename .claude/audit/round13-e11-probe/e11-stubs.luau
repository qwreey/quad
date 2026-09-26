--!nocheck
local Quad = require("../src")
local q = Quad.New()
local names = { "nativeInsert","nativeExtract","nativeRemove","nativeMove","nativeSwap","nativeDispose","isInst","onDestroying","nativeClaim","isClaimed","nativeFindChild","holdLifetime","releaseLifetime","isHeld","isHeldBy","addTag","removeTag","setAttr","setTimeout","clearTimeout" }
local n = 0
for _, k in names do
	local f = q.Backend[k]
	if type(f) ~= "function" then print(k, "MISSING (", type(f), ")") else
		local ok, e = pcall(f)
		n += 1
		print(string.format("%-16s %s %s", k, ok and "OK?!" or "ERR", tostring(e):match("Quad%d+ [^—]+") or tostring(e)))
	end
end
print("stubs:", n)
-- pure predicates contract says "never throw": what do they do on a bare module? (canExecute -> isHeld stub)
print("canExecute(bare)", pcall(q.Backend.canExecute, {}))
local extra = {}
for k in pairs(q.Backend) do if not table.find(names, k) then extra[#extra+1]=k end end
table.sort(extra); print("other Backend fields:", table.concat(extra, ","))
