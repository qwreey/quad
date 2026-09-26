--!nocheck
local mock = require("./mock")
local q = mock.newQuad()
local Instance = mock.Instance
for _, where in { "newItem", "keyGone" } do
	local parent = Instance.new("Folder")
	local data = q.Source({ { id = "a" }, { id = "b" } })
	local s = q.Slot()
	local boom = false
	s:List(data, function(ctx)
		if ctx.Item == q.KeyGone then
			if boom and where == "keyGone" and ctx.UserData == "a" then error("throw in KeyGone a") end
			return nil, ctx.UserData
		end
		if boom and where == "newItem" and ctx.Item.id == "boom" then error("throw in updateFn boom") end
		local f = ctx.Prev or (function() local f = Instance.new("Frame"); f.Name = ctx.Item.id; return f end)()
		return f, ctx.Item.id
	end, function(it) return it.id end)
	q.Dispatch.drive(parent, { s })
	boom = true
	local ok, e = pcall(function() data:Set({ { id = "x" }, { id = "boom" } }) end)
	local names = {}
	for _, c in parent:GetChildren() do table.insert(names, c.Name) end
	table.sort(names)
	local bk = q.Bookkeeping.getBlocker and q.Bookkeeping.getBlocker(s)
	print(where, "threw", not ok, "children", table.concat(names, ","), "#_elements", #s._elements, "Length", s.Length:Get(), "blocking", bk and bk.Blocking)
	boom = false
	data:Set({ { id = "x" }, { id = "z" } })
	names = {}
	for _, c in parent:GetChildren() do table.insert(names, c.Name) end
	table.sort(names)
	print(where, " after recover: children", table.concat(names, ","), "Length", s.Length:Get())
end
