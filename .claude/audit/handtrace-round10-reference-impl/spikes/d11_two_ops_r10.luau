--!nocheck
-- 4차 code-review의 2-연산 경로(Remove 뒤 Add, 한 콜백 안)를 두 필드 분리 위에서 실제 값으로.
local q = require("./core10"); local D = require("./dispatch10")
local inst = q.newInst("inst")
local s = {}; for i = 1, 4 do s[i] = D.newSlot("s" .. i, {{name = "x" .. i}}) end
local O = D.newSlot("O", { s[1], s[2], s[3], s[4] })
D.mountTop(inst, O)
print("초기 offsets:", s[1].Offset:Get(), s[2].Offset:Get(), s[3].Offset:Get(), s[4].Offset:Get(), "| O.Length", O.Length:Get())
local s5 = D.newSlot("s5", {{name = "x5"}})
local fired = false
local w = s[3].Offset:Observer(function(_, _, from)
    if from == nil or fired then return end
    fired = true
    local bk = D.getBookkeeping(O)
    print("  [watcher@i=3] Remove(1): before setUpTo", bk.offsetSetUpTo, "cacheValid", bk.offsetCacheValidUpTo)
    D.rawRemove(O, 1)
    print("  [watcher] after Remove: N", bk.N, "setUpTo", bk.offsetSetUpTo, "cacheValid", bk.offsetCacheValidUpTo)
    D.rawAdd(O, s5)
    print("  [watcher] after Add: N", bk.N, "setUpTo", bk.offsetSetUpTo, "cacheValid", bk.offsetCacheValidUpTo, "s5.Offset", s5.Offset:Get())
end)
q.bindLifetime(inst, w)
D.log = {}
local ok, err = pcall(function() D.rawAdd(s[2], {name="x2b"}) end)
print("rawAdd(s2, child) →", if ok then "정상 종료" else "ERROR: " .. tostring(err))
print("최종 offsets: s2", s[2].Offset:Get(), "(기대 0) s3", s[3].Offset:Get(), "(기대 2) s4", s[4].Offset:Get(), "(기대 3) s5", s5.Offset:Get(), "(기대 4) | O.Length", O.Length:Get(), "(기대 5)")
print("log:", table.concat(D.log, " "))
