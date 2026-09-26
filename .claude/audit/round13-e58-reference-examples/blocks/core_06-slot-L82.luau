local list = q.Slot<<Instance>>()      -- 빈 Slot(아직 수동/재조정 모드 미정)
local fixed = q.Slot<<Instance>>({     -- 초기 원소 둘, 수동 CRUD Slot으로 고정
    D.TextLabel { Text = "A" },
    D.TextLabel { Text = "B" },
})

local panel = D.Frame { list, fixed }  -- 숫자 키에 놓으면 그 자리가 Slot의 자식 구간이 된다
