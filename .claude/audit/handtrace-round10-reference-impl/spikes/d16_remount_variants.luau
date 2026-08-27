--!nocheck
-- Q2 대조: 재마운트 처방 none / (a) / (c)
-- 트리: O = { a, b, S },  S = { C, plain },  C = { plain }   (S의 베이스 2)
-- 유저 체인: `:List`의 updateFn이 만든 요소가 S.Offset을 구독해 LayoutOrder를 정하는 모양.
--   요소 인스턴스는 언마운트를 넘어 살아남으므로(파괴 아님) 그 Observer도 살아 있다.
local q = require("./core9"); local D = require("./dispatch9")
local function run(fix)
    D.remountFix = fix
    local inst  = q.newInst("inst1")
    local elem  = q.newInst("elem")          -- updateFn이 만든 요소(살아남는다)
    local C = D.newSlot("C", {{name="cx"}})
    local S = D.newSlot("S", { C, {name="sx"} })
    local O = D.newSlot("O", { {name="a"}, {name="b"}, S })
    D.mountTop(inst, O)
    -- 유저 LayoutOrder: index(=1) + S.Offset
    local lo = { value = nil }
    local userObs = S.Offset:Observer(function(target) lo.value = 1 + target:Get() end)
    q.bindLifetime(elem, userObs)
    print(("[%s] 1차: S.Offset=%d C.Offset=%d userLO=%s | bk(S) valid=%d setUpTo=%d cache[1]=%s")
        :format(fix, S.Offset:Get(), C.Offset:Get(), tostring(lo.value),
                D.getBookkeeping(S).offsetCacheValidUpTo, D.getBookkeeping(S).offsetSetUpTo,
                tostring(D.getBookkeeping(S).offsetCache[1])))
    D.rawRemove(O, 3)                        -- 언마운트(포탈로 떼어냄)
    local inst2 = q.newInst("inst2")
    local O2 = D.newSlot("O2", {})
    D.mountTop(inst2, O2)
    D.rawAdd(O2, S)                          -- 베이스 0에 재마운트
    local bkS = D.getBookkeeping(S)
    print(("[%s] 재마운트: S.Offset=%d (기대 0) C.Offset=%d (기대 0) userLO=%s (기대 1) | bk(S) valid=%d setUpTo=%d cache[1]=%s")
        :format(fix, S.Offset:Get(), C.Offset:Get(), tostring(lo.value),
                bkS.offsetCacheValidUpTo, bkS.offsetSetUpTo, tostring(bkS.offsetCache[1])))
    local ok = (S.Offset:Get() == 0) and (C.Offset:Get() == 0) and (lo.value == 1)
    print(("[%s] → %s"):format(fix, if ok then "✅ 전부 정합" else "❌ 어긋남"))
    -- 재마운트 뒤 런타임 베이스 변경도 도는가(O2 앞에 요소를 하나 끼워 S를 민다)
    D.rawAdd(O2, {name="z"}, 1)
    print(("[%s] 앞에 z 삽입 후: S.Offset=%d (기대 1) C.Offset=%d (기대 1) userLO=%s (기대 2)")
        :format(fix, S.Offset:Get(), C.Offset:Get(), tostring(lo.value)))
    print("")
end
run("none"); run("a"); run("c"); run("ctor")
