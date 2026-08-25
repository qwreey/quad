--!strict
type El = { tag: string }
-- 비제네릭으로 좁혀서 "선언된 다중 반환보다 적게 반환"만 본다
local function take(fn: (n: number) -> (El?, number?)) end

take(function(n) return { tag = "a" } end)   -- 1개만 반환
take(function(n) return nil end)             -- nil 하나
take(function(n) end)                        -- 아무것도 안 반환
take(function(n) return { tag = "a" }, 1 end)-- 정확히 2개
take(function(n) return nil, nil end)        -- 명시적 2개

-- 대조: 단일 옵셔널 반환
local function take2(fn: (n: number) -> El?) end
take2(function(n) return { tag = "a" } end)
take2(function(n) return nil end)
take2(function(n) end)
