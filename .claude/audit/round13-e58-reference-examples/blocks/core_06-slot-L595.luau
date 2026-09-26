local slot = q.Slot<<Instance>>({ D.Frame {} })
local taken = slot:Extract(1)  -- 먼저 소유에서 꺼내고
q.dispose(taken)               -- 그다음에 지운다

local temp = q.Slot<<Instance>>({ D.Frame {}, D.Frame {} })
q.dispose(temp)                -- 마운트된 적 없는 Slot은 트리째 파괴된다
