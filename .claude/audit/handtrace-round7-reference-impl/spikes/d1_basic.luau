--!nocheck
local q = require("./core"); local D = require("./dispatch")
local inst = {}   -- 최상위 물리 inst가 owner
-- Frame { A, B, C } — 전부 plain 요소(길이 1, 발행 채널 None)
local bl = D.getBlocker(inst); bl:On()
for i = 1, 3 do
    D.setOffsetSource(inst, i, D.None)
    D.setLength(inst, i, 1, inst)
end
bl:OffWithoutEmit(); D.recompute(inst, D.getBookkeeping(inst))
print("offsets:", D.getOffsetAt(inst,1), D.getOffsetAt(inst,2), D.getOffsetAt(inst,3), "| 다음 자리:", D.getOffsetAt(inst,4))
print("recompute 횟수:", D.stats())
