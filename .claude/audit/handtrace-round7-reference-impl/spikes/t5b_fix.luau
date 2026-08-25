--!nocheck
local q = require("./core")
-- 갈래 (b): rawInvalid를 fn 호출 *전에* 내리고, 도중에 다시 세워졌으면 그대로 둔다
local State = getmetatable(q.State(function() end, {})) 
State._recompute = function(self)
    self.recomputes += 1
    self.rawInvalid = false                      -- ← 먼저 내린다
    self.cache = self.fn(self, self.cache, table.unpack(self.deps))
    for _, d in self.deps do d:_track(self.valueEpochMap) end
    -- rawInvalid가 fn 도중 다시 true가 됐으면 그대로 둔다(덮어쓰지 않는다)
end
local A = q.Source(1)
local D = q.State(function(self, prev, a)
    local v = a:Get()
    if v == 1 then A:Set(99) end
    return v * 2
end, {A}, "D")
print("D:Get() =", D:Get())
print("다시 D:Get() =", D:Get(), "  ← 198이면 고쳐진 것")
print("재계산 횟수:", D.recomputes)
