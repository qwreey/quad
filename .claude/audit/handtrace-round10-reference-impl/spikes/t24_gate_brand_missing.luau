--!nocheck
-- H-152 재현: `GateNode`가 `StateBrand`(여기선 메타테이블 판별)에 등록되지 않으면 `_emitDown`의
-- `isState(sub)` 분기가 거짓 → `canExecute(sub)`로 떨어져(게이트는 bind/Subscribe된 적 없음) 조용히 건너뜀.
-- 값(`:Get()`)은 멀쩡하고 통지만 죽는다 — "값은 맞는데 아무도 안 깨어나는" 모드.
local q = require("./core10")
local function scenario(label, dropBrand)
    local s = q.Source(1)
    local b = q.Blocker()
    local g = s:Block(b)                          -- GateNode
    if dropBrand then
        local mt = getmetatable(g); local copy = table.clone(mt); copy.__index = mt.__index
        setmetatable(g, copy)                     -- 같은 메소드, 다른 identity → isState(g) == false
    end
    local fires = 0
    local o = g:Observer(function() fires += 1 end); o:Subscribe()
    fires = 0
    s:Set(2); s:Set(3)
    print(("%s: isState(g)=%s | Observer 발화 %d (기대 2) | g:Get()=%d (값은 항상 최신)"):format(
        label, tostring(q.isState(g)), fires, g:Get()))
end
scenario("브랜드 등록됨   ", false)
scenario("브랜드 누락(재현)", true)
