# 2026-08-12 아홉 번째 세션 — `Slot`의 store 재바인드도 `Ref`와 같은 `Relate` diff 패턴

## 배경

직전 세션(여덟 번째, `Ref`의 retract를 `TagHandler`와 같은 메커니즘으로
확정)에서 발견한 패턴이 다른 곳에도 있는지 사용자가 확인 요청: `Slot`도
store 값으로 재바인드될 수 있는가(`State<Slot>`), 그렇다면 같은 `Relate`
diff 패턴을 써야 하는가 — 그리고 이미 같은 바인딩이면 전부 빼고 다시
넣는 것 자체를 하지 말고 완전히 무시해야 하지 않겠냐는 제안.

## 확인

`slot-plan.md` "Slot과 Store 바인드의 관계" 절을 다시 읽어보니, `Ref`에서
고쳤던 것과 정확히 같은 종류의 부정확한 서술이 있었음: "store 바인드
핸들러가 이전 slot 상태를 `retract`하고 새 slot 상태로 다시 `process`하는
사이클을 돈다"는 문장은, `bind-system-plan.md`의 일반 계약("핸들러 *타입*이
안 바뀌면 `retract` 없이 `process`가 diff 담당")을 적용하면 틀림 —
`slotA→slotB`도 같은 SlotHandler가 매치하는 경우라 `retract`가 아니라
`process`가 처리해야 함. 게다가 실제 `Dispatch/Slot.luau`의 `process(inst,
k,slotValue)` 구현(`attachSlot(slotValue, inst, inst, k)` 한 줄)을 보면
이전 값과의 비교 자체가 아예 없었고, `destroySlotTree`(파괴 함수)도 CRUD
경로(`rawRemove`)에서만 쓰이고 store-bind retract 경로에 연결된 적이 없었음
— 실제로 와이어링 자체가 안 돼 있던 진짜 갭.

## 결정

`Ref`와 같은 `Relate` 기반 패턴을 재사용하되, Slot의 이미 확정된 "폐기,
옮기지 않음"(portal 없음) 정책 때문에 diff가 아니라 **identity 비교**로
단순화:

```lua
local relate = Relate()

function SlotHandler.process(inst, k, slotValue)
    local old = relate:GetStrong(inst, k)
    if old == slotValue then return end  -- 이미 같은 바인딩, no-op
    if old then destroySlotTree(old) end  -- 폐기, 옮기지 않음(기존 정책)
    attachSlot(slotValue, inst, inst, k)
    relate:SetStrong(inst, k, slotValue)
end

function SlotHandler.retract(inst, k, v)
    assert(v == nil)
    local old = relate:GetStrong(inst, k)
    if old then destroySlotTree(old) end
    relate:SetStrong(inst, k, nil)
end
```

**이 no-op 가드가 `Tag`/`Ref`보다 Slot에서 더 중요한 이유**: Tag/Ref의
diff는 값이 같아도 기껏해야 헛계산만 하고 넘어가지만, Slot은 "폐기,
옮기지 않음" 정책이 이미 확정돼 있어서 이 가드가 없으면 재귀 재emit이
있을 때마다(예: 상위 `:Compute` 재계산 결과가 우연히 같은 Slot
레퍼런스인 경우) 마운트된 서브트리 전체가 파괴됐다 다시 만들어짐 — 자식이
들고 있던 스크롤/포커스/애니메이션 상태 전부 유실되는, Tag의 diff가
막으려던 "깜빡임"보다 훨씬 파괴적인 버전.

## 반영

- `base/slot-plan.md` "Slot과 Store 바인드의 관계" 절 — 부정확했던
  "retract 사이클" 서술을 정정, 위 pseudocode와 근거 추가. "확정: 폐기,
  옮기지 않음" 정책 자체는 그대로 유지(메커니즘만 정정).
- `base/bind-system-plan.md` 일반 retract 계약 절 — `Tag`/`Ref`에 이어
  `Slot`도 같은 패턴의 세 번째 예시로 교차 참조 추가.
