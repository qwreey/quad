--!strict
-- base/slot-plan.md 확정: updateFn<UD>(item, index, offset, prev, userdata) -> (T|nil, UD?)
type Element = { tag: string }
export type SourceN = { Get: (self: SourceN) -> number }

local function List<T, UD>(
    updateFn: (item: any, index: number, offset: SourceN, prev: T?, userdata: UD?) -> (T?, UD?)
) end

-- (A) 값 하나만 반환하는 가장 흔한 모양
List(function(item, index, offset, prev, ud)
    return { tag = "x" } :: Element
end)

-- (B) 두 값 반환
List(function(item, index, offset, prev, ud)
    return { tag = "x" } :: Element, 42
end)

-- (C) nil만 반환(요소 버리기 — 확정된 정상 경로)
List(function(item, index, offset, prev, ud)
    return nil
end)

-- (D) 조건 분기 — 한쪽만 반환
List(function(item, index, offset, prev, ud)
    if index > 1 then return { tag = "x" } :: Element end
end)

-- (E) 아무것도 안 반환
List(function(item, index, offset, prev, ud) end)
