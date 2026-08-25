--!nocheck
-- base/dispatch-core-plan.md "Dispatch 체인" 절의 확정 의사코드 그대로
local C = {}
local chains = {}
local NOOP = function() end
local handlers = {}
function C.addHandler(h) table.insert(handlers, h) end
local function getHandler(inst, k, v)
    for _, h in handlers do if h.isHandlable(inst, k, v) then return h end end
    error("Dispatch: 매치되는 핸들러 없음")
end
function C.process(inst, k, v, index)
    local list = chains[inst] and chains[inst][k]
    if not list then
        list = {}
        chains[inst] = chains[inst] or {}
        chains[inst][k] = list
    end
    local slot = list[index]
    local h = getHandler(inst, k, v)
    if slot ~= nil and slot.handler == h then
        slot.retractor(v)
        slot.retractor = NOOP
        local retractor = h.process(inst, k, v, index)
        if retractor == nil then error("Dispatch: 핸들러가 retractor 반환을 생략했음 — 생략 불가") end
        slot.retractor = retractor
    else
        C.retractFrom(inst, k, index)
        list[index] = { handler = h, retractor = NOOP }
        local retractor = h.process(inst, k, v, index)
        if retractor == nil then error("Dispatch: 핸들러가 retractor 반환을 생략했음 — 생략 불가") end
        list[index] = { handler = h, retractor = retractor }
    end
end
function C.retractFrom(inst, k, index)
    local list = chains[inst] and chains[inst][k]
    if not list then return end
    for i = #list, index, -1 do
        local slot = list[i]
        if slot == nil then error("Dispatch: 인덱스 " .. i .. "에 슬롯이 없음 — 배열에 구멍이 뚫렸음") end
        slot.retractor(nil)
        list[i] = nil
    end
end
C.dump = function(inst, k) return chains[inst] and chains[inst][k] end
return C
