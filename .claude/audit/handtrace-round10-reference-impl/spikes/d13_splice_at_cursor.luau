--!nocheck
-- H-113 양성 확인: 커서 자리 i(< N)에서 제거하면 -1 덕에 i를 재방문해 밀려 들어온 요소가 Set을 받는다.
local q = require("./core9"); local D = require("./dispatch9")
local inst = q.newInst("inst")
local s = {}; for i = 1, 4 do s[i] = D.newSlot("s" .. i, {{name = "x" .. i}}) end
local O = D.newSlot("O", { s[1], s[2], s[3], s[4] })
D.mountTop(inst, O)
local fired = false
local w = s[2].Offset:Observer(function(_, _, from)
    if from == nil or fired then return end
    fired = true
    print("  [watcher@i=2] Remove(2) — 커서 자리 자신을 제거")
    D.rawRemove(O, 2)
end)
q.bindLifetime(inst, w)
local ok, err = pcall(function() D.rawAdd(s[1], {name="x1b"}) end)
print("rawAdd(s1, child) →", if ok then "정상 종료" else "ERROR: " .. tostring(err))
print("최종: s3.Offset", s[3].Offset:Get(), "(기대 2) s4.Offset", s[4].Offset:Get(), "(기대 3) | O.Length", O.Length:Get(), "(기대 4)")
