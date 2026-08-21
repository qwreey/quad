# `attachSlot` 책임 분해 — 확장 논의 준비 자료

**상태**: research — **논의 전 준비 자료.** 아무것도 확정하지 않았고, 다음
논의가 바로 시작될 수 있게 **지금 무엇이 얽혀 있는지**를 한 곳에 모은 것.

**왜 생겼나**: 2026-08-21 구현 전 QA 4라운드 `F-4-3`에서 `Dispatch.setLength`를
flush 루프 앞에 둘지 뒤에 둘지가 갈렸는데, 사용자가 그 자리를 고르는 문제가
아니라고 짚었다 — *"리스트 액티베이션을 먼저 하고 length 를 얻어 밀고
attachSlot 되는게 맞을지도. **attachSlot 의 기능이 너무 다양해진게
문제같음.** 이 부분에 있어서는 확장 논의를 하게 준비해두자."*

정본은 여전히 `base/slot-plan.md`의 "재귀 메커니즘" 절 —
**이 문서가 그 확정을 대체하지 않는다.**

---

## 1. `attachSlot`이 지금 하는 일 — 책임 일곱 개

`base/slot-plan.md`의 의사코드를 책임 단위로 쪼개면 이렇다(코드는 그 문서가
소스, 여기선 라벨만 붙임):

| 라벨 | 하는 일 | 층위 |
|---|---|---|
| **R1** | `offsetSource` 생성 → `Dispatch.setOffsetSource(ownerKey, position, ...)` → `slot.Offset` 공개 | **부모에 대한 자기 등록** |
| **R2** | `slot._listed`면 `activateList` — `:List` reconcile이 `_elements`를 채움(물리 마운트 없음) | **내용 실체화** |
| **R3** | `slot._mounted = true`, `slot._mountedInst = physicalTarget` | **자기 상태 전이** |
| **R4** | `Dispatch.setLength(ownerKey, position, slot.Length)` | **부모에 대한 자기 등록** |
| **R5** | `getBlocker(slot):On()` … `:OffWithoutEmit()` + 마지막 `recompute` | **배치 게이팅** |
| **R6** | flush 루프 — 각 요소의 부기 등록(`setOffsetSource`/`setLength`) **+ 물리 마운트(`Parent` 대입)** | **자식 배치** |
| **R7** | 중첩 Slot 요소에 대해 `attachSlot` 재귀 | **재귀** |

**서로 다른 축이 넷 섞여 있다** — (a) 부모에게 나를 알리는 일(R1/R4),
(b) 내 내용을 만드는 일(R2), (c) 내 자식을 실제로 붙이는 일(R6), (d) 상태
플래그와 배치 게이팅(R3/R5). 사용자가 "기능이 너무 다양해졌다"고 한 게 이것.

**호출부는 셋**:
- `SlotHandler.process`(최상위) — `bindLifetime` 후 `attachSlot(slotValue, inst, inst, k)`
- R7(중첩) — flush 루프 안에서 재귀
- `rawAdd`(런타임 단건) — 이미 마운트된 Slot에 나중에 nested Slot을 `Add`할 때

---

## 2. 순서 제약과 그 출처 — 왜 지금 모양이 됐나

**이 제약들은 전부 실제로 밟은 버그에서 나왔다.** 분해안을 평가할 때 하나라도
깨면 그 버그가 되돌아온다.

| # | 제약 | 왜 | 출처 |
|---|---|---|---|
| **C1** | `slot.Offset`(R1)이 `activateList`(R2)보다 **먼저** | `:List`의 `updateFn`이 `offset`을 인자로 받는 계약 | `slot-plan.md` `:List` 파라미터 |
| **C2** | `activateList`(R2)는 `_mounted == false`인 상태에서 돌아야 함 → **R2가 R3보다 먼저** | 아니면 reconcile의 `rawAdd`가 매 항목마다 즉시 물리 마운트 + `setLength`를 태워 (a) Blocker 없이 `recompute`가 돌고 (b) nested Slot에 `attachSlot`이 **두 번** 불림 | `RC-3`/`RC-4`(QA 3라운드) |
| **C3** | `attachSlot`이 **반환될 때는** `_mounted == true`여야 함 | 런타임 `rawAdd`가 이 플래그로 "지금 붙일까 `_elements`에만 넣을까"를 가름 | `slot-plan.md` `rawAdd` |
| **C4** | `setOffsetSource`가 `setLength`보다 **먼저** | `setLength` 끝의 `gatedRecompute`가 죽는 중인 Source에 `:Set`을 날림 | `dispatch-core-plan.md` 해제 순서 계약 |
| **C5** | R5의 Blocker가 R6 **전체**를 감쌈 | 없으면 등록마다 `recompute`가 돌아 O(N²) | `RC-1` 해결(QA 2라운드) |
| **C6** | R4가 넘기는 `slot.Length`의 **최종값**은 R5/R7이 끝나야 정해짐 | 중첩 Slot 요소의 `.Length`는 그 요소의 `attachSlot`이 돌아야 확정됨 | 구조적 |
| **C7** | 부기 갱신이 물리 트리 조작보다 **먼저** | 백엔드가 "내가 물리적으로 밀어낼 때 부기는 이미 정확하다"를 전제할 수 있어야 함 | `dispatch-core-plan.md` 일반 계약(QA 4라운드 `C-7`) |

### ⭐ C6와 C7이 정면으로 부딪힌다 — 이게 `F-4-3`의 근본

- **C7을 지키려면** R4(부모에게 내 길이 알리기)가 R6(자식 물리 마운트)보다
  먼저여야 한다.
- **C6를 지키려면** R4는 R6/R7이 끝난 **뒤**여야 최종값을 알 수 있다.

**지금은 C7을 지키고 C6를 포기했다** — R4가 `slot.Length`(값이 아직 `0`인
State **객체**)를 넘기고, flush가 끝나 `recompute`가 실제 값을 넣으면 부모가
Observer로 다시 반응해 스스로 교정한다. 대가는 **배치 밖 재마운트에서 부모
`recompute`가 2회 도는 것**(뒤에 형제가 있으면 그 offset들이 두 번 `Set`됨).

**단일 함수로는 둘 다 만족할 수 없다** — 한 함수 안에서 R4의 자리가 하나뿐이기
때문. 그래서 이건 "어느 줄에 놓을까"가 아니라 **분해 문제**다.

---

## 3. 분해 후보

### (A) 현행 유지 — 단일 `attachSlot`

- C7 지킴, C6 포기(자기 교정 1회).
- **비용**: 배치 밖 재마운트마다 부모 `recompute` 1회 낭비. 크래시도 영구
  오류도 아님(`SL-58`에 이미 "손대지 않기로" 기록됨).
- **문제**: 사용자가 지적한 "기능이 너무 다양함"은 그대로 남는다.

### (B) 2단 분리 — `prepare` / `mount` ⭐ 사용자 제안에 가장 가까움

*"리스트 액티베이션을 먼저 하고 length 를 얻어 밀고 attachSlot 되는게 맞을지도"*
를 그대로 구조화하면 이 모양이 된다. **핵심은 R6를 부기(R6a)와 물리(R6b)로
쪼개는 것.**

```lua
-- 개념 스케치. 이름/시그니처 전부 가칭
local function prepareSlot(slot, physicalTarget, ownerKey, position)
    -- R1
    local offsetSource = Source(0)
    Dispatch.setOffsetSource(ownerKey, position, offsetSource)
    slot.Offset = offsetSource

    -- R2 (여전히 _mounted == false — C2)
    if slot._listed then activateList(slot, physicalTarget) end

    -- R5 + R6a + R7-prepare : 부기만, 물리 마운트 없음
    local blocker = getBlocker(slot)
    blocker:On()
    for i, element in ipairs(slot._elements) do
        if isSlot(element) then
            prepareSlot(element, physicalTarget, slot, i)   -- 재귀 → element.Length 확정
            Dispatch.setLength(slot, i, element.Length)
        else
            Dispatch.setOffsetSource(slot, i, None)
            Dispatch.setLength(slot, i, 1)
        end
    end
    blocker:OffWithoutEmit()
    recompute(slot, bk)          -- 여기서 slot.Length가 **최종값**으로 확정 (C6 만족)
end

local function mountSlot(slot, physicalTarget)
    slot._mounted = true                       -- R3 (C3)
    slot._mountedInst = physicalTarget
    for i, element in ipairs(slot._elements) do
        if isSlot(element) then mountSlot(element, physicalTarget)   -- R7-mount
        else element.Parent = physicalTarget end                      -- R6b
    end
end

-- 호출부(최상위)
prepareSlot(slotValue, inst, inst, k)
Dispatch.setLength(inst, k, slotValue.Length)   -- R4 — 이제 최종값 (C6 + C7 동시 만족)
mountSlot(slotValue, inst)
```

- **C6와 C7을 둘 다 만족한다** — 부모에게 넘기는 길이가 처음부터 최종값이고,
  그 등록이 어떤 `Parent` 대입보다도 먼저다.
- **각 함수의 일이 하나로 좁아진다** — `prepareSlot` = "부기를 정확하게
  만든다", `mountSlot` = "그 부기대로 트리에 붙인다".
- **`_mounted`의 의미가 정직해진다** — 지금은 "`activateList`는 지났고 flush는
  아직"이라는 어정쩡한 중간 시점인데, 분리하면 문자 그대로 "mount 단계를
  지났는가"가 된다.
- **비용**: `_elements` 순회가 2회로 늘고, 호출부가 **셋 다** 두 함수를 순서대로
  불러야 한다(빠뜨리면 half-attached 상태).

### (C) 3단 분리 — `register` / `activate` / `mount`

R1(부모 등록)까지 따로 떼는 안. `Dispatch.drive`의 최상위 배열 파트도 같은
3단으로 맞추면 "배치 등록 → 실체화 → 마운트"라는 하나의 모양이 코퍼스 전체에
반복된다.

- **이득**: `Dispatch.drive`와 `attachSlot`이 지금 서로 비슷한데 미묘하게
  다른 구조(전자는 Blocker + 두 패스, 후자는 Blocker + flush)인 걸 하나로
  수렴시킬 수 있음.
- **비용**: 단계가 하나 더 늘고, 호출부가 셋 → 셋 × 3단이 됨. (B)의 이득
  대부분을 (B)만으로 이미 얻으므로 **추가 이득이 뭔지가 논의 대상**.

### (D) 최소 변경 — 분리 없이 문서만

`attachSlot` 안을 R1~R7 주석 블록으로 명시하고 각 제약(C1~C7)을 그 자리에
달아둠. 코드는 그대로.

- **이득**: 위험 0. **비용**: 근본 문제(C6/C7 충돌, 책임 과다)는 안 풀림.

---

## 4. 어떤 분해든 같이 정해야 하는 것

1. **`activateList`의 `data:Observer(fn)` `bindLifetime`은 어느 단계인가.**
   지금은 `activateList` 안에서 `bindLifetime(inst, observer)`를 부르는데,
   (B)에서 그건 prepare 단계다 — 아직 아무것도 물리적으로 안 붙은 시점에
   `physicalTarget`에 생명주기를 묶는 게 맞는지.
2. **호출부를 감싸는 얇은 `attachSlot`을 남길지.** 남기면 `SlotHandler.process`/
   `rawAdd`가 지금처럼 한 줄로 끝나고 "한쪽만 부르는" 오용도 막힌다. 대신
   "결국 다시 한 함수"라 분해의 이득이 반쯤 희석된다.
3. **`Dispatch.drive`도 같은 모양으로 맞출지**(후보 (C)와 직결).
4. **prepare만 하고 mount 안 한 중간 상태를 어떻게 다룰지** — 방어할지, UB로
   둘지. 코퍼스 기조상 UB + 문서화가 자연스러워 보이지만 확인 필요.
5. **`_mounted` 소비처가 새 정의로도 맞는지** — (a) `:List()`가 마운트 이후에
   불릴 때 즉시 `activateList`하는 분기, (b) `rawAdd`의 "붙일까 말까" 분기.
   (B)에서는 `_mounted`가 mount 단계에서 켜지므로, prepare와 mount 사이에
   `:List()`가 불리는 경로가 있는지 따져야 한다.
6. **`Detach` 정리용 `Effect`(QA 4라운드 `F-3`)를 어디에 설치할지** — 그건
   `physicalTarget`에 묶이므로 mount 단계가 자연스럽다. **`F-3`이 먼저
   닫히는 게 순서상 낫다** — 그 결정이 이 분해의 요구사항을 하나 더 얹는다.

---

## 5. 지금 상태 요약

- **확정된 건 없다.** `base/slot-plan.md`의 단일 `attachSlot`이 여전히 정본.
- **급하지 않다** — (A)로 두어도 동작은 맞고(자기 교정), M2/M3 착수를 막지
  않는다. 다만 **M6(`:List`) 구현 전에는 정해두는 게 낫다** — 그 시점에
  `activateList`/`rawAdd`/`attachSlot`을 실제로 짜기 때문.
- **선행 항목**: 위 4-6번대로 `F-3`(`Detach` 보관 위치 + `KeyGone`)이 먼저
  닫히면 이 논의의 요구사항이 완전해진다.
