local FADE = q.Tween({ Value = 0, Time = 0.15 })

local a = FADE:Mapped(function(v: number): number return 1 end)  -- Time = 0.15 유지
local b = FADE:Mapped(function(v: number): number return 0.5 end)
