--!nocheck
local q = require("./core9")
local r = q.Ref(nil)
local calls = {}
local function fn(v, ref) table.insert(calls, tostring(v) .. "/" .. tostring(ref == r)) end
r:WeakCallback(fn); r:Callback(fn)      -- 같은 fn을 약·강 양쪽에
print("등록 즉시 호출:", table.concat(calls, ","), "(기대 nil/true 두 번 — 등록마다 1회)")
calls = {}
r:Set(7)
print("Set(7) 후 호출:", table.concat(calls, ","), "(기대 7/true 한 번 — 교차 dedup)")
r:Uncallback(fn); calls = {}
r:Set(8)
print("Uncallback 뒤 Set(8):", #calls, "회 (기대 0)")
-- thread 대기자 + 값→리비전→콜백 순서
local seenRev
local co = coroutine.create(function(ref) seenRev = ref.Revision end)
r.Callbacks[co] = true
local rev0 = r.Revision
r:Set(9)
print("thread가 본 Revision ~= 옛 리비전:", seenRev ~= rev0, "| 소진됨:", r.Callbacks[co] == nil)
