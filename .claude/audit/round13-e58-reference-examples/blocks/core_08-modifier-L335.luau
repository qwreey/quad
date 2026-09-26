local theme = q.Modifier { BackgroundTransparency = 0.2 }
local danger = q.Modifier { BackgroundTransparency = 0 }

local merged = q.Modifier.Overridden(theme, danger) -- danger가 이긴다
local same = theme:Overridden(danger)               -- 같은 함수, 같은 결과
