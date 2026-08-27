--!nocheck
-- H-124 후보: recompute가 커서 i == N을 처리하는 중 사용자 코드가 요소를 제거하면
-- `local v = bk.lengthList[i]`가 되감기 판정보다 먼저 nil을 읽는다.
local q = require("./core9"); local D = require("./dispatch9")
local inst = q.newInst("inst")
local function L(n) return D.newSlot(n, {{name = n .. "_x"}}) end
local s1, s2, s3 = L("s1"), L("s2"), L("s3")
local O = D.newSlot("O", { s1, s2, s3 })
D.mountTop(inst, O)
print("초기: s3.Offset", s3.Offset:Get(), "O.Length", O.Length:Get())
-- s3.Offset(마지막 자리)을 보는 사용자 Observer가 그 통지 도중 O:Remove(1)
local fired = false
local w = s3.Offset:Observer(function(_, _, from)
    if from == nil or fired then return end
    fired = true
    print("  [watcher] s3.Offset ->", s3.Offset:Get(), "→ O:Remove(1) 호출")
    D.rawRemove(O, 1)
    print("  [watcher] rawRemove 반환. N =", D.getBookkeeping(O).N, "offsetSetUpTo =", D.getBookkeeping(O).offsetSetUpTo)
end)
q.bindLifetime(inst, w)
D.log = {}
local ok, err = pcall(function() D.rawAdd(s1, {name="s1_y"}) end)   -- s1 길이 1→2, s2·s3 offset이 밀린다 → i=3에서 watcher
print("rawAdd(s1, child) →", if ok then "정상 종료" else "ERROR: " .. tostring(err))
local bk = D.getBookkeeping(O)
print("O.Length", O.Length:Get(), "| N", bk.N, "| s2.Offset", s2.Offset:Get(), "(기대 0) | s3.Offset", s3.Offset:Get(), "(기대 1)")
print("log:", table.concat(D.log, " "))
