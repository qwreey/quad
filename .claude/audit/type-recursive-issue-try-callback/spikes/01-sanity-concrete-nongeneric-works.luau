--!strict
-- 제네릭이 아예 없는 구체 함수 타입에서도 콜백 파라미터 추론이 되는가?
local function Apply(fn: (number) -> string): string
    return fn(1)
end

local r = Apply(function(a) return tostring(a) end) -- a 무주석, 기대: number
local ok: string = r
