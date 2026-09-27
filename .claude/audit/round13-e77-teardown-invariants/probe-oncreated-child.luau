--!nocheck
-- E77: what happens to the child whose OnCreated disposed the host that the child is about to be Added to
-- (and the variant where the child's own Effect/OnDestroyed are present).
local H = require("./harness")
local q, D, mock = H.q, H.D, H.mock
local weak = setmetatable({}, { __mode = "k" })
local log = {}
local s = q.Slot()
local root = D.Frame({ s })
local child
local ok, e = pcall(function()
	child = D.Frame({ Name = "child",
		q.OnCreated(function() q.dispose(root) end),
		q.Effect(function() return function(d) table.insert(log, "childCleanup(" .. tostring(d) .. ")") end end),
		q.OnDestroyed(function() table.insert(log, "childOD") end) })
	s:Add(child)
end)
print("add ok", ok, ok and "" or H.first(e))
print("root destroyed", mock.isDestroyed(root), "child destroyed", mock.isDestroyed(child), "child parent", child.Parent)
print("log", table.concat(log, " "))
weak[child] = "child"
local ok2, e2 = pcall(function() q.dispose(child) end)
print("dispose(child) afterwards", ok2, ok2 and "" or H.first(e2), "log", table.concat(log, " "))
child = nil; root = nil; s = nil
for _ = 1, 6 do collectgarbage("collect") end
local n = 0; for _ in weak do n += 1 end
print("child survivors after GC", n)
-- same, without the manual dispose (the program simply drops the child)
local s2 = q.Slot(); local root2 = D.Frame({ s2 })
local c2
pcall(function() c2 = D.Frame({ q.OnCreated(function() q.dispose(root2) end) }); s2:Add(c2) end)
local w2 = setmetatable({ [c2] = true }, { __mode = "k" })
print("variant drop: child destroyed", mock.isDestroyed(c2))
c2 = nil; root2 = nil; s2 = nil
for _ = 1, 6 do collectgarbage("collect") end
local n2 = 0; for _ in w2 do n2 += 1 end
print("variant drop: survivors", n2)
