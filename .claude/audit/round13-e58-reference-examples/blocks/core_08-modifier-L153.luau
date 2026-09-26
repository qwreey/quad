local scale = q.Source(1)
local base = D.Modifier.Frame { BackgroundTransparency = 0.5, LayoutOrder = 1 }

local dimmed = base:BackgroundTransparency(0.9)     -- 리터럴
local live = base:LayoutOrder(scale)                -- State 핸들 그대로
local cleared = base:BackgroundTransparency(q.None) -- 명시 해제

-- 변환: 지금 값이 평범한 값이면 그 값이 온다(필드가 없으면 nil)
local bumped = base:LayoutOrder(function(old) return (old :: number) + 1 end)
-- 변환: 지금 값이 State면 :Compute로 이어지고 old는 핸들이다
local doubled = live:LayoutOrder(function(old)
    return (old :: q.StateData<number>):Get() * 2
end)

-- base 는 여전히 0.5 — 전부 새 값이다
