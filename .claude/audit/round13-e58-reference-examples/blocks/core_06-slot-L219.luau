local slot = q.Slot<<Instance>>({ D.Frame {}, D.Frame {} })
local taken = slot:Extract(1)          -- 살아 있는 채로 빠져나온다
local other = q.Slot<<Instance>>()
other:Add(taken)                       -- 다른 Slot으로 이사
