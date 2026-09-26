local got = {}
local bar = SearchBar(function(t) table.insert(got, t) end)
local box, x
for _, c in bar:GetChildren() do if c.ClassName == "TextBox" then box = c else x = c end end
box.Text = "sw"; box.Text = "swo"; H.runTask(0.5)
print("searched:", table.concat(got, "|"), "X visible:", x.Visible)
x.Activated:Fire("i", 1); print("after X:", box.Text, x.Visible)
