--!nocheck
local H = require("./harness")
local mockM = require("../../../quad-base/test/mock")
local q, D = H.q, H.D
for _, path in { "Destroy", "dispose" } do
	local log = {}
	local data = q.Source({ "a", "b" })
	local held
	local s = q.Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return q.Detach end
		if ctx.Prev then return ctx.Prev end
		local f = D.Frame { Name = ctx.Item, q.Effect(function() return function(d) table.insert(log, ctx.Item .. "C(" .. tostring(d) .. ")") end end) }
		if ctx.Item == "a" then held = f end
		return f
	end, function(it) return it end)
	local host = D.Frame { Name = "host", s }
	data:Set({ "b" })
	print(path, "held.Parent before:", held.Parent and held.Parent.Name, "destroyed:", mockM.isDestroyed(held))
	if path == "Destroy" then host:Destroy() else q.dispose(host) end
	print(path, "after:", table.concat(log, " "), "held destroyed:", mockM.isDestroyed(held))
end
-- remount: held element follows the slot's current mount target
do
	local log = {}
	local data = q.Source({ "a" })
	local held
	local s = q.Slot():List(data, function(ctx)
		if ctx.Item == q.KeyGone then return q.Detach end
		if ctx.Prev then return ctx.Prev end
		held = D.Frame { q.Effect(function() return function(d) table.insert(log, "heldC(" .. tostring(d) .. ")") end end) }
		return held
	end)
	local seat = q.Source(s)
	local h1 = D.Frame { seat }
	data:Set({})
	seat:Set(nil)
	h1:Destroy()
	print("remount: after old host destroyed (slot unmounted):", table.concat(log, " "), "held destroyed:", mockM.isDestroyed(held))
	local h2 = D.Frame { s }
	h2:Destroy()
	print("remount: after new host destroyed:", table.concat(log, " "), "held destroyed:", mockM.isDestroyed(held))
end
