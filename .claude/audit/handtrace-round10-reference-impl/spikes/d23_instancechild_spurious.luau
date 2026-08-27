--!nocheck
-- 레인 B: `InstanceChildHandler`(ROADMAP M5 / dispatch-core `H-134` 다섯째 문단)를 하강 diff 체인 위에 그대로 옮기고,
-- `state<Frame>`의 **같은 Frame 재발행**(spurious)과 **교체**에서 `Parent` 대입이 몇 번 나는지 센다.
-- 대조군: `SlotHandler`(같은 값이면 retractor 얼리리턴) / `RefLeafHandler`(`old ~= v` dedup).
local q = require("./core10"); local D = require("./dispatch10"); local C = require("./chain")
local inst = q.newInst("inst")
local parentOps = {}
local function log(s) parentOps[#parentOps+1] = s end
local None = D.None
-- StoreBind (dispatch-core "Store 바인드는 … 래핑" 의사코드)
local StoreBind = { priority = 100,
    isHandlable = function(_, _, v) return q.isState(v) end,
    process = function(inst, k, state, index)
        local observer = state:Observer(function() C.process(inst, k, state:Get(), index + 1) end)
        q.bindLifetime(inst, observer)
        return function() q.unbindLifetime(observer) end
    end }
-- InstanceChildHandler — ROADMAP M5 그대로: None → Parent → setLength(1); retractor: Parent=nil → None → setLength(0)
local InstanceChild = { priority = 10,
    isHandlable = function(_, k, v) return type(k) == "number" and type(v) == "table" and v.__isInst == true end,
    process = function(inst, k, v, index)
        D.setOffsetSource(inst, k, None)
        v.Parent = inst; log("Parent(" .. v.name .. ")=inst")
        D.setLength(inst, k, 1, inst)
        return function(nextValue)
            v.Parent = nil; log("Parent(" .. v.name .. ")=nil")
            D.setOffsetSource(inst, k, None)
            D.setLength(inst, k, 0)
        end
    end }
C.addHandler(StoreBind); C.addHandler(InstanceChild)
local A, B = { __isInst = true, name = "A" }, { __isInst = true, name = "B" }
local child = q.Source(A)
D.recomputes = 0
C.process(inst, 1, child, 1)
print("최초:", table.concat(parentOps, " "), "| recompute(inst)", D.recomputes)
parentOps = {}; D.recomputes = 0
child:Set(A)                          -- spurious 재발행 — 같은 Frame
print("같은 Frame 재발행:", table.concat(parentOps, " "), "| recompute", D.recomputes, "(SlotHandler/RefLeaf라면 0)")
parentOps = {}; D.recomputes = 0
child:Set(B)
print("교체 A→B:", table.concat(parentOps, " "), "| recompute", D.recomputes, "| A.Parent =", tostring(A.Parent))
