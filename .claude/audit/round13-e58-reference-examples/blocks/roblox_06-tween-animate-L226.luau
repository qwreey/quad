-- 첫 값은 즉시 10, 그다음 Set부터 애니메이션
local size = q.Source(q.Tween({ Value = 10, Time = 0.3 }))
local box = D.Frame({ BackgroundTransparency = size })
