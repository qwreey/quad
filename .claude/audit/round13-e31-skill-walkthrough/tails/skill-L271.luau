local data = q.Source({ { Id = "a", Title = "A" }, { Id = "b", Title = "B" } })
local host = D.Frame { ItemList(data) }
local function dump() local t = {} for _, c in host:GetChildren() do table.insert(t, c:GetChildren()[1].Text .. "@" .. tostring(c.LayoutOrder)) end table.sort(t) return table.concat(t, ",") end
print("rows:", dump())
local first = host:GetChildren()[1]
data:Set({ { Id = "b", Title = "B2" } })
print("after reorder/remove:", dump(), "a destroyed:", mock.isDestroyed(first) or first.Name)
