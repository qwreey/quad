local host = D.Frame { slot }
local e1, e2 = D.Frame { Name = "e1" }, D.Frame { Name = "e2" }
selected:Set(e1); selected:Set(e2)
print("e1 destroyed?", mock.isDestroyed(e1), "e1 parent:", e1.Parent, "e2 parent:", e2.Parent == host)
