--!strict
type El = { tag: string }
type Fn2 = (n: number) -> (El?, number?)
type Fn1 = (n: number) -> El?
type Fn0 = (n: number) -> ()
local function takeU(fn: Fn2 | Fn1 | Fn0) end
takeU(function(n) return { tag = "a" } end)
takeU(function(n) return nil end)
takeU(function(n) end)
takeU(function(n) return { tag = "a" }, 1 end)
-- 음성 대조군: 엉뚱한 타입을 돌려주면 걸려야 정상
takeU(function(n) return 42 end)
