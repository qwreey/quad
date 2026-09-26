--!strict
-- E56 최소 재현: 두 갈래 Effect(한쪽은 cleanup, 한쪽은 없음)를 문서 모양(return nil)대로 쓰면 strict가 거부
const q = require("../annotated/Quad")
const flag = q.Source(false)
const e1 = q.Effect(function()      -- A: GS 08 §4 모양 — 거부 기대
    if flag:Get() then return function() end end
    return nil
end, flag)
const e2 = q.Effect(function()      -- B: 한 갈래만(무반환) — 통과 기대
    print(flag:Get())
end, flag)
const e3 = q.Effect(function(): ((dying: boolean) -> ())?  -- C: 반환 타입을 옵셔널로 주석 — 거부 기대
    if flag:Get() then return function() end end
    return nil
end, flag)
const e4 = q.Effect(function()      -- D: nil 대신 빈 cleanup — 통과 기대(문서 밖 재구성)
    if flag:Get() then return function() end end
    return function() end
end, flag)
print(e1, e2, e3, e4)
