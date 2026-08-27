--!nocheck
-- quad 확정 의사코드는 전부 level 인자 없는 error(msg) — level 1이 기본
local Slot = {}
function Slot.Add(self, index)          -- quad 내부(라이브러리) 코드
    error("Slot:Add — index가 범위 밖(1..3): " .. tostring(index))
end
function Slot.AddL2(self, index)
    error("Slot:Add — index가 범위 밖(1..3): " .. tostring(index), 2)
end

local ok1, e1 = pcall(function() Slot.Add(nil, 9) end)     -- 사용자 코드 줄
local ok2, e2 = pcall(function() Slot.AddL2(nil, 9) end)
print("level 기본(1):", e1)
print("level 2      :", e2)
