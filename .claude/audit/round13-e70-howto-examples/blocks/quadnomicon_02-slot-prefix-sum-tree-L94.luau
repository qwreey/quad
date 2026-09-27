local gate = if self._physicalTarget ~= nil then S.BK.getBlocker(self) else nil -- [1] 배치 Blocker
local ownsGate = gate ~= nil and not gate.Blocking
if ownsGate then gate:On() end

base = S.BK.getOffsetAt(self, index) -- [2] 변형 전에 읽는다(캐시는 현재 배치를 서술)
-- ... removedLeaves 수집 ...
for i = index + removeCount - 1, index, -1 do
    rawUnmount(self, i, true)        -- [3] deferPhysical: 부기만, 물리 op는 미룬다
end
for k, element in ipairs(newElements) do
    rawAdd(self, element, index + k - 1, nil, true)
end
-- ... newLeaves 수집 ...
-- [4] 물리 op 단 한 번 (제거가 없으면 nativeInsert 한 번)
module.Backend.nativeExtract(self._mountedInst, base, removedLeaves, if #newLeaves > 0 then newLeaves else nil)

if ownsGate then
    gate:OffWithoutEmit()            -- [5] 파동 없이 게이트 해제
    maybeRecompute(self, S.BK.getBookkeeping(self))  -- [6] 최종 재계산 1회
end
