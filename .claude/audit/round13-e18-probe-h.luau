--!nocheck
-- round13 E18 probe H — frozen-ness of merged surfaces; provider fields vs base keys. Run from repo root.
local Quad = require("../../quad-roblox/luau_packages/quad_base")
local QuadRoblox = require("../../quad-roblox/src").QuadRoblox
local q = Quad.New():UseProvider(QuadRoblox)
for _, k in { "Declaration", "Backend", "Dispatch", "Bookkeeping", "moduleIdentity", "Operator", "Tag" } do
	print(k, type(q[k]), type(q[k]) == "table" and table.isfrozen(q[k]) or "-")
end
print("module frozen", table.isfrozen(q))
-- RobloxExtension keys vs base keys before merge
local bare = Quad.New()
for _, k in { "Declaration", "OnChange", "Out", "Animate", "Tween", "isTween" } do print("base has", k, bare[k] ~= nil) end
-- Tween installed directly by installTween before merge? check identity pre/post
local m = Quad.New()
local ext
local wrapped = function(qq) ext = QuadRoblox(qq); return ext end
m:UseProvider(wrapped)
print("module Tween == ext.Tween", m.Tween == ext.Tween, "isTween", m.isTween == ext.isTween)
-- a second Quad.New() after the first got QuadRoblox: does the provider's setFuncLevel/shared state interfere?
local m2 = Quad.New():UseProvider(QuadRoblox)
print("two instances distinct Declaration", m2.Declaration ~= q.Declaration, "Declaration.Frame distinct", m2.Declaration.Frame ~= q.Declaration.Frame)
