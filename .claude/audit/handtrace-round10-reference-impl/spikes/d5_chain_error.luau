--!nocheck
local C = require("./chain")
-- AttributeKeyHandler(attribute-plan.md 확정 의사코드)를 그대로 옮긴 것
local nameClaims = {}
local setAttributeInjected = false
local function setAttribute(inst, name, v)
    if not setAttributeInjected then
        error("quad: setAttribute op이 주입되지 않았습니다(백엔드 팩토리 미설치)")  -- 확정된 "에러내는 스텁"
    end
end
local AttributeKeyHandler = {
    isHandlable = function(inst, k, v) return type(k) == "table" and k.Name ~= nil end,
    process = function(inst, k, v, index)
        local cur = nameClaims[inst] and nameClaims[inst][k.Name]
        if cur ~= nil and cur ~= k then
            error(`attribute "{k.Name}" is already bound by another owner`)
        end
        nameClaims[inst] = nameClaims[inst] or {}
        nameClaims[inst][k.Name] = k
        setAttribute(inst, k.Name, v)      -- ← 주입 안 됐으면 여기서 던진다
        return function()
            if nameClaims[inst][k.Name] == k then nameClaims[inst][k.Name] = nil end
        end
    end,
}
C.addHandler(AttributeKeyHandler)

local inst = {}
local keyA = { Name = "Score" }
local keyB = { Name = "Score" }   -- 같은 이름을 쓰는 다른 소유자(그룹 Attribute 등)

print("-- 백엔드 미주입 상태에서 Attribute 한 번 --")
local ok, err = pcall(C.process, inst, keyA, 10, 1)
print("던졌는가:", not ok, "|", err)
print("claim 남았는가:", nameClaims[inst] and nameClaims[inst].Score ~= nil)
local list = C.dump(inst, keyA)
print("체인 슬롯:", list and list[1] and "있음(retractor=" .. tostring(list[1].retractor) .. ")" or "없음")

print("-- 이제 백엔드를 붙이고 정상적으로 다시 시도 --")
setAttributeInjected = true
local ok2, err2 = pcall(C.process, inst, keyB, 20, 1)
print("성공했는가:", ok2, "|", err2)

print("-- 명시적 철거로 회수되는가 --")
setAttributeInjected = true
pcall(C.retractFrom, inst, keyA, 1)
print("철거 후 claim 남았는가:", nameClaims[inst] and nameClaims[inst].Score ~= nil)
local ok3, err3 = pcall(C.process, inst, keyB, 20, 1)
print("철거 후 재시도 성공?:", ok3, "|", err3)
