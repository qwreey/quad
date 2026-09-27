--!nocheck
-- E70 probe: how-to 10:82 `if myRef.Value then myRef.Value else myRef:Wait().Value` — 값이 없는 갈래(코루틴 안에서 대기 → 다음 채워짐)
local H = require("../harness")
local q, D = H.q, H.D
local myRef = q.PreRef(nil)
local got = "unset"
local th = coroutine.create(function()
	local inst = if myRef.Value then myRef.Value else myRef:Wait().Value
	got = inst
end)
print(coroutine.resume(th))
print("status after resume", coroutine.status(th))
local f = D.Frame { myRef }
print("status after fill", coroutine.status(th), got == f)
