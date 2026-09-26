local data = q.Source({ { Id = "a", Title = "A", Score = 1 }, { Id = "b", Title = "B", Score = 2 } })
local host = D.Frame { Leaderboard(data) }
data:Set({ { Id = "b", Title = "B", Score = 9 } })
local c = host:GetChildren()
print("rows:", #c, c[1].LayoutOrder, c[1]:GetChildren()[2].Text)
