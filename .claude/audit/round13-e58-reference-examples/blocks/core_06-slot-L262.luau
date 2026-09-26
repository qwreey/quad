local slot = q.Slot<<Instance>>({ D.Frame {}, D.Frame {}, D.Frame {} })
local removed = slot:Splice(2, 1, D.Frame {}, D.Frame {}) -- 2번을 빼고 그 자리에 둘을 넣는다
-- removed[1] 은 살아 있는 채로 손에 들어온다
