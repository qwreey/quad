local function find(p, name) for _, c in p:GetChildren() do if c.Name == name then return c end end end
local function click(b) b.Activated:Fire("input", 1) end
local count = find(gui, "Count")
print("count0:", count.Text)
click(find(gui, "Inc")); click(find(gui, "Inc"))
print("count2:", count.Text)
local list = find(gui, "List")
click(find(gui, "AddItem")); click(find(gui, "AddItem"))
local rows = {}
for _, c in list:GetChildren() do if c.ClassName == "Frame" then table.insert(rows, c.Name .. "@" .. tostring(c.LayoutOrder)) end end
table.sort(rows); print("rows:", table.concat(rows, ","))
-- reorder + remove: keep id2 first, drop id1 (recycle path + KeyGone)
local r2 = find(list, "id2")
items:Set({ { Id = "id2", Title = "Item 2 renamed" } })
print("id2 same instance:", find(list, "id2") == r2, "LayoutOrder:", r2.LayoutOrder, "title:", r2:GetChildren()[1].Text, "id1 gone:", find(list, "id1") == nil)
local panel = find(gui, "Panel")
print("panel first Position (snap):", panel.Position.Y.Scale, "tweens so far:", #mock.tweenLog)
click(find(gui, "Open"))
local close = find(panel, "ModalClose")
print("modal open:", close ~= nil, "tweens:", #mock.tweenLog, "tween target Y:", mock.tweenLog[#mock.tweenLog] and mock.tweenLog[#mock.tweenLog].props.Position.Y.Scale)
click(close)
print("modal closed:", find(panel, "ModalClose") == nil, "close destroyed:", mock.isDestroyed(close), "tweens:", #mock.tweenLog)
