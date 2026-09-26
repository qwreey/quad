local current = q.Source<<Instance?>>(nil)
local slot = q.Slot<<Instance>>():Single(current)
local host = D.Frame { slot }

current:Set(D.TextLabel { Text = "화면 A" })  -- 붙는다
current:Set(D.TextLabel { Text = "화면 B" })  -- A는 파괴되고 B로 교체
current:Set(nil)                              -- 비워진다
