--!nocheck
-- 레인 A: Store 구현 스케치의 "그림자 테이블"이 store 자신인지 별도인지에 따라 `Of("Of")` 런타임 거동이 어떻게 갈리는가
-- (타입 함수는 정적 이름만 잡고, 동적 `Of(name)`은 이름이 타입에 안 실린다 — store-plan.md 스스로 적어둔 갭)
local function Source(v) return { _v = v, Get = function(s) return s._v end, Set = function(s, x) s._v = x end, __isSource = true } end
local function isSource(x) return type(x) == "table" and x.__isSource == true end

-- 구현 (I): 그림자 = store 자신(메타테이블 __index에 메소드) — "store.key는 평범한 레코드 필드"에 맞는 모양
local StoreMT_I = {}; StoreMT_I.__index = StoreMT_I
function StoreMT_I:Of(name)
    local src = self[name]           -- 스케치 그대로 `shadow[name]`
    if src == nil then src = Source(nil); self[name] = src end
    return src
end
function StoreMT_I:Names() local t = {}; for k in pairs(self) do t[#t+1] = k end; return t end
local function StoreI(defaults)
    for k, v in pairs(defaults or {}) do if not isSource(v) then error(("quad.Store: defaults.%s is not a Source"):format(k), 2) end end
    return setmetatable(table.clone(defaults or {}), StoreMT_I)
end
-- 구현 (II): 그림자 별도 + store 프록시(__index → shadow) — "그림자 테이블"이라는 단어에 맞는 모양
local function StoreII(defaults)
    local shadow = table.clone(defaults or {})
    local methods = {}
    function methods:Of(name)
        local src = shadow[name]
        if src == nil then src = Source(nil); shadow[name] = src end
        return src
    end
    function methods:Names() local t = {}; for k in pairs(shadow) do t[#t+1] = k end; return t end
    return setmetatable({}, { __index = function(_, k) local m = methods[k]; if m ~= nil then return m end; return shadow[k] end })
end

for label, ctor in pairs({ ["(I) store==shadow"] = StoreI, ["(II) proxy→shadow"] = StoreII }) do
    print("== " .. label .. " ==")
    local s = ctor({ hp = Source(1) })
    local ok, err = pcall(function()
        local x = s:Of("Of")          -- 동적 예약 이름
        print("  Of('Of') 반환 타입:", type(x), isSource(x) and "Source" or "NOT a Source")
        local y = s:Of("hp2")         -- 이후 정상 Of가 아직 되는가
        print("  이후 Of('hp2'):", if isSource(y) then "OK" else "BROKEN")
    end)
    if not ok then print("  error:", err) end
    local ok2, err2 = pcall(function() return s:Names() end)
    print("  Names():", ok2 and table.concat(err2, ",") or ("error " .. tostring(err2)))
end
-- defaults에 예약 이름(타입은 잡지만 --!nocheck/동적이면 통과)
print("== defaults = { Of = Source(1) } ==")
local s3 = StoreI({ Of = Source(1) })
print("  isSource 검증은 통과 → s3:Of 는", type(s3.Of), "(메소드가 가려졌다)")
print("  s3:Of('x') →", select(2, pcall(function() return s3:Of("x") end)))
