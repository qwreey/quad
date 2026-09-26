--!nocheck
print("before require")
local ok, mod = pcall(function()
	return require("../../../quad-roblox/src")
end)
print("ok=", ok)
if not ok then
	print("ERR:", mod)
else
	print("mod=", mod, "QuadRoblox=", mod.QuadRoblox)
end
