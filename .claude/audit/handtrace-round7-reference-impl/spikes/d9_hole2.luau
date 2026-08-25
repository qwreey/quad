--!nocheck
local q = require("./core"); local D = require("./dispatch")
local inst = {}
local s2 = D.newSlot("s2")
local bl = D.getBlocker(inst); bl:On()
-- 1번 자리 등록 생략(H-39 버그 재발), 2번은 발행 채널이 있는 Slot
local ok, err = pcall(function()
    D.setOffsetSource(inst, 2, s2.Offset)   -- 여기서 getOffsetAt(inst, 2)를 부른다
end)
print("setOffsetSource에서 터지는가:", not ok)
print("메시지:", err)
