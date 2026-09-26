local prefab = mock.Instance.new("Frame")
for _, nm in { "PlayerName", "PlayerLevel" } do local l = mock.Instance.new("TextLabel"); l.Name = nm; l.Parent = prefab end
local ps = q.Source({ Name = "Ada", Level = 3 })
BindPlayerCard(prefab, ps); ps:Set({ Name = "Bo", Level = 4 })
local t = {} for _, c in prefab:GetChildren() do table.insert(t, c.Text) end
print("claimed:", table.concat(t, ","))
