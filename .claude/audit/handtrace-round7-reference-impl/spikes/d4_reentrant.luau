--!nocheck
local q = require("./core"); local D = require("./dispatch")
local owner = D.newSlot("owner")
local s1, s2 = D.newSlot("s1"), D.newSlot("s2")
local bl = D.getBlocker(owner); bl:On()
D.setOffsetSource(owner, 1, s1.Offset); D.setLength(owner, 1, s1.Length, owner)
D.setOffsetSource(owner, 2, s2.Offset); D.setLength(owner, 2, s2.Length, owner)
bl:OffWithoutEmit(); D.recompute(owner, D.getBookkeeping(owner))
print("초기 owner.Length =", owner.Length:Get(), "| s2.Offset =", s2.Offset:Get())

-- s2.Offset을 보는 소비자가 그 통지 도중 같은 owner에 3번째 자리를 추가한다
local added = false
local watcher = q.Observer(s2.Offset, function()
    if added then return end
    added = true
    D.setOffsetSource(owner, 3, D.None)
    D.setLength(owner, 3, 1, owner)     -- 재진입 recompute
end)
watcher.Subscribed = true

print("-- s1.Length:Set(2) --")
s1.Length:Set(2)
local bk = D.getBookkeeping(owner)
local expect = 0
for i = 1, bk.N do
    local v = bk.lengthList[i]
    expect += (if type(v) == "table" then v:Get() else v)
end
print("owner.Length =", owner.Length:Get(), "| 실제 합계 =", expect, "| N =", bk.N, "| recompute:", D.stats())
print("s2.Offset =", s2.Offset:Get(), "(기대 2) | 3번 자리 offset =", D.getOffsetAt(owner, 3), "(기대 2)")
if owner.Length:Get() ~= expect then print("  ❌ owner.Length가 실제 합계와 다르다") else print("  ✅ 일치") end
