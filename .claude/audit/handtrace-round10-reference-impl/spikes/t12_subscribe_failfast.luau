--!nocheck
local q = require("./core9")
local s = q.Source(0)
local function try(label, f) local ok, err = pcall(f); print(label, if ok then "→ 통과(no error)" else "→ error: " .. tostring(err)) end
local o1 = s:Observer(function() end)
try("WeakSubscribe 뒤 Unsubscribe", function() o1:WeakSubscribe(); o1:Unsubscribe() end)
local o2 = s:Observer(function() end)
try("Subscribe 뒤 WeakUnsubscribe", function() o2:Subscribe(); o2:WeakUnsubscribe() end)
local o3 = s:Observer(function() end)
try("Subscribe 두 번", function() o3:Subscribe(); o3:Subscribe() end)
local o4 = s:Observer(function() end)
try("구독 안 한 값에 Unsubscribe", function() o4:Unsubscribe() end)
local o5 = s:Observer(function() end)
try("구독 안 한 값에 WeakUnsubscribe", function() o5:WeakUnsubscribe() end)
local o6 = s:Observer(function() end)
try("Subscribe → Unsubscribe → Subscribe (재구독)", function() o6:Subscribe(); o6:Unsubscribe(); o6:Subscribe() end)
-- Effect: 내부 Observer는 WeakSubscribe만. Effect:Subscribe/Unsubscribe가 내부에 손대지 않는지
local n = 0
local e = q.Effect(function() n += 1 end, s)
try("Effect:Subscribe", function() e:Subscribe() end)
s:Set(1); print("  Effect 구독 뒤 Set → n", n, "(기대 2)")
try("Effect:Unsubscribe", function() e:Unsubscribe() end)
s:Set(2); print("  Effect 해제 뒤 Set → n", n, "(기대 2)")
-- 내부 Observer에 범용 정리 코드가 Unsubscribe를 부르면?
local inner; for _, v in pairs(e._deps) do inner = v end
try("Effect 내부 Observer에 Unsubscribe", function() inner:Unsubscribe() end)
