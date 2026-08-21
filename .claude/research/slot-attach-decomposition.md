# `attachSlot` 책임 분해 — 결정 근거 기록 (2026-08-21 확정)

**상태**: **[2026-08-21] 결론 확정 — (B) 분해 채택, `base/slot-plan.md`에
반영 완료.** 이 문서는 이제 "왜 그렇게 정했나"의 근거 기록이고, **지금 유효한
설계는 `base/slot-plan.md`의 "재귀 메커니즘" 절**(`materializeSlotTree` /
`mountSlotTree` / 얇은 `attachSlot`)이 소스다.

**사용자 확정 근거**(2026-08-21): *"함수 분해는 확정해도 좋을것 같음. 이게
하나의 큰 복잡한 복합 함수라 여러 session 간의 실수가 발생하던 부분이고, 지금
적절한 방향으로 이동하지 않으면 계속 실수에 의한 시간/기술비용이 축적될것
같음. 지금 의사코드를 건들이는 비용이, 추후 실수가 누적되는 비용보다 싸다고
생각함."*

아래는 그 결론에 이른 조사/논거를 그대로 보존한 것 — 원래 서술은 "논의 전
준비 자료"였다.

**왜 생겼나**: 2026-08-21 구현 전 QA 4라운드 `F-4-3`에서 `Dispatch.setLength`를
flush 루프 앞에 둘지 뒤에 둘지가 갈렸는데, 사용자가 그 자리를 고르는 문제가
아니라고 짚었다 — *"리스트 액티베이션을 먼저 하고 length 를 얻어 밀고
attachSlot 되는게 맞을지도. **attachSlot 의 기능이 너무 다양해진게
문제같음.** 이 부분에 있어서는 확장 논의를 하게 준비해두자."*

정본은 `base/slot-plan.md`의 "재귀 메커니즘" 절 — **이 문서가 그 확정을
대체하지 않는다.**

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

> **[2026-08-21 갱신] 사용자 판단으로 (B) 방향 + "공개 표면은 안 쪼갬"까지
> 좁혀졌다** — 구체안은 **6절**, "물리 마운트가 일괄로 밀리는" 차이에 대한
> 검토와 판단 갱신은 **7절**이 최신이고, 이 절과 3절은 거기까지 온 경로다.

- **확정된 건 없다.** `base/slot-plan.md`의 단일 `attachSlot`이 여전히 정본.
- **급하지 않다** — (A)로 두어도 동작은 맞고(자기 교정), M2/M3 착수를 막지
  않는다. 다만 **M6(`:List`) 구현 전에는 정해두는 게 낫다** — 그 시점에
  `activateList`/`rawAdd`/`attachSlot`을 실제로 짜기 때문.
- **선행 항목**: 위 4-6번대로 `F-3`(`Detach` 보관 위치 + `KeyGone`)이 먼저
  닫히면 이 논의의 요구사항이 완전해진다.

---

## 6. (B)를 실제로 쪼갠다면 — 구체안 (2026-08-21, 사용자 질문에 대한 답)

**사용자 판단**: *"자식중 slot 이 있으면 activateList 로 실체화 하고 길이를
구해서 대입해주는게 맞는듯. 즉 말했던것인 B. 그런데 쪼개야할지 의문이 들긴 함.
attachSlot 이라는 이름이 하는 일로써 정당해보이긴 함 … 혹시 쪼갠다면 어떻게
쪼갤것 같아?"*

### 6-1. 먼저 — **공개 표면은 안 쪼개도 된다**

`attachSlot`이라는 이름이 정당하다는 판단에 동의한다. **쪼개야 하는 건
호출부에 보이는 함수가 아니라 재귀 자체다.**

- (B)가 요구하는 건 **"부기는 bottom-up으로 다 만든 뒤, 물리는 top-down으로
  붙인다"** 인데, 그러려면 재귀가 **두 번** 돌아야 한다(한 번은 길이를
  올리려고, 한 번은 붙이려고).
- 재귀를 두 번 돌리려면 진입점이 둘이거나 모드 파라미터가 필요하다 —
  **그게 "쪼갠다"의 실체**이고, 공개 `attachSlot`을 없애자는 뜻이 전혀 아니다.
- 그래서 제안은 **`attachSlot`은 이름·시그니처·호출부 전부 그대로 두고, 몸통을
  비공개 재귀 헬퍼 둘로 나누는 것**. `attachSlot`의 몸통은 두 줄이 된다.

### 6-2. 구체안 — `materializeSlotTree` / `mountSlotTree`

이름은 코퍼스가 이미 쓰는 `unmountSlotTree`/`destroySlotTree`의 `...SlotTree`
접미사(= 재귀 walk)를 그대로 따랐다.

```lua
-- 비공개 재귀 1: 부기만 만든다. 물리 마운트 없음.
local function materializeSlotTree(slot, physicalTarget, ownerKey, position)
    -- R1 — offset 먼저(C1: activateList가 updateFn에 넘겨야 함)
    local offsetSource = Source(0)
    Dispatch.setOffsetSource(ownerKey, position, offsetSource)
    slot.Offset = offsetSource

    -- R2 — _mounted는 여전히 false (C2: RC-3/RC-4)
    if slot._listed then activateList(slot, physicalTarget) end

    -- R5 + R6a + R7 — 자식 부기만, 재귀로 길이를 bottom-up으로 확정
    local blocker = getBlocker(slot)
    blocker:On()
    for i, element in ipairs(slot._elements) do
        if isSlot(element) then
            materializeSlotTree(element, physicalTarget, slot, i)  -- 자기 길이를 slot[i]에 등록하고 옴
        else
            Dispatch.setOffsetSource(slot, i, None)                -- C4 순서
            Dispatch.setLength(slot, i, 1)
        end
    end
    blocker:OffWithoutEmit()
    recompute(slot, bk)                     -- 여기서 slot.Length가 최종값으로 확정

    -- R4 — 자기 길이를 부모에게. 이제 **최종값**이다 (C6)
    Dispatch.setLength(ownerKey, position, slot.Length)
end

-- 비공개 재귀 2: 물리만 붙인다.
local function mountSlotTree(slot, physicalTarget)
    slot._mounted = true                    -- R3 (C3)
    slot._mountedInst = physicalTarget
    for i, element in ipairs(slot._elements) do
        if isSlot(element) then mountSlotTree(element, physicalTarget)
        else element.Parent = physicalTarget end   -- R6b
    end
end

-- 공개 진입점 — 이름/시그니처/호출부 전부 그대로
local function attachSlot(slot, physicalTarget, ownerKey, position)
    materializeSlotTree(slot, physicalTarget, ownerKey, position)
    mountSlotTree(slot, physicalTarget)
end
```

**핵심은 `setLength`가 `materializeSlotTree`의 *끝*으로 간 것** — 자기
길이를 부모에게 알리는 일이 자기 서브트리 부기가 다 끝난 뒤이므로 **처음부터
최종값**이고, 그러면서도 **어떤 `Parent` 대입보다도 먼저**다. 나머지 재귀
단계에서 자연스럽게 대칭이 된다(중첩 슬롯은 자기 `materialize` 끝에서
`slot[i]`에 자기 길이를 등록하므로, 부모 루프가 따로 등록해줄 필요가 없다).

### 6-3. C1~C7 재점검 — 전부 유지된다

| 제약 | 어디서 지켜지나 |
|---|---|
| C1 (`Offset` → `activateList`) | `materializeSlotTree` 앞 두 줄 |
| C2 (`activateList`는 `_mounted == false`) | `_mounted`는 `mountSlotTree`에서만 켜짐 — **오히려 지금보다 더 확실해짐**(중간에 켜질 자리가 아예 없음) |
| C3 (반환 시 `_mounted == true`) | `attachSlot`이 `mountSlotTree`를 부르고 끝남 |
| C4 (`setOffsetSource` → `setLength`) | 중첩: 자식 materialize의 첫 줄(offset) → 마지막 줄(length). 평범: 루프 안 두 줄 |
| C5 (Blocker가 자식 배치 전체를 감쌈) | `blocker:On()` … `OffWithoutEmit()`이 루프를 감쌈. 자식의 `setLength`가 부모 blocker에 막혀 스킵되는 것도 그대로 |
| **C6 (최종값으로 등록)** | ✅ **이제 만족** — `recompute` 다음 줄이라 최종값 |
| **C7 (부기가 물리보다 먼저)** | ✅ **이제 만족** — 모든 `Parent` 대입이 `mountSlotTree`에 몰려 있고 그건 부기가 다 끝난 뒤 |

**부수 이득**: 지금은 배치 밖 재마운트에서 부모 `recompute`가 **2회**
돌았는데(`Length=0`으로 한 번, 확정 후 한 번 — `SL-58`) **1회로 준다.**

### 6-4. 비용과 남는 것

- **`_elements` 순회가 2회**로 는다. 배열 walk 두 번이라 할당도 없고 실측에서
  문제될 규모로 보이진 않지만, 명시해둘 비용.
- **비공개 함수가 둘 는다.** 다만 호출부(셋: `SlotHandler.process`, 런타임
  `rawAdd`, 재귀)는 **하나도 안 바뀐다** — "한쪽만 부르는" 오용 위험이
  구조적으로 없다(공개 진입점이 여전히 하나).
- **안 고쳐지는 것**: `materializeSlotTree`는 여전히 "내 부모에게 등록"(R1/R4)과
  "내 자식 배치"(R5/R6a)를 같이 한다. 그것까지 떼려면 부모 등록을 호출부로
  올려야 하는데, 그러면 호출부 셋이 전부 두 줄이 되고 순서 실수를 열어주므로
  **과한 분해로 보인다.**
- **비대칭 하나**: `mountSlotTree` ↔ `unmountSlotTree`는 정확한 거울상인데,
  `materializeSlotTree`의 거울상(부기 철거)은 별도 함수가 아니라 호출부의
  `setOffsetSource(None)` → `setLength(0)` 관용구다. 이름만 보고 짝을 찾으면
  헷갈릴 수 있어 문서화 시 짚을 것.

### 6-5. 그래서 쪼개야 하나 — 내 판단

**쪼개는 쪽을 약하게 추천한다.** 근거는 셋인데 어느 하나도 결정적이진 않다:

1. **C6/C7을 둘 다 만족시키는 유일한 방법**이고, 지금은 둘 중 하나를 포기하고
   있다(자기 교정 1회). 값이 틀려지진 않지만 "일반 계약을 세워놓고 자기가
   예외"인 상태가 남는다.
2. **`_mounted`의 의미가 정직해진다** — 지금은 "`activateList`는 지났고 flush는
   아직"이라는 중간 시점이라 `RC-3`/`RC-4`가 그 미묘함에서 나왔다. 분해하면
   문자 그대로 "mount 단계를 지났는가"가 되고, 그 버그 클래스가 구조적으로
   사라진다.
3. `attachSlot` 몸통이 두 줄이 되어 **읽는 사람이 "무엇을 언제 하는가"를 두
   이름만으로** 파악한다.

**반대로 안 쪼갤 이유**도 정당하다 — 동작이 지금도 맞고(자기 교정), 순회가
하나 늘며, 확정된 의사코드를 건드리는 변경이다. **M6 착수 시점에 실제로 짜보며
정해도 늦지 않다.**

---

## 7. "물리 마운트가 일괄로 밀린다"는 차이 — 손해가 아니라 이득 (2026-08-21)

**사용자 관찰**: *"얼마나 nested 든, 하나 마운트되고 하나 마운트되고… 각
객체들이 `Parent = inst` 되어가며 피지컬에 붙어가는 일자 진행인데, 이건 관측
이후 일괄 등록이라는 차이가 있는듯 … 그러나 이런 사소한, 문제를 야기하기 어려운
동작을 원래와 동치시키기 위해 디버깅이 어려운 함수를 만드는건 옳지 않아보임."*

**결론에 동의한다. 그리고 그 "차이"는 감수하는 비용이 아니라 개선이다.**

### 7-1. 마운트 **순서**는 안 바뀐다 — 바뀌는 건 부기와 섞이느냐뿐

`outer { A, inner { B, C }, D }` 기준:

| | 현행(인터리브) | 분해(일괄) |
|---|---|---|
| `Parent` 대입 순서 | A → B → C → D | A → B → C → D (**동일**) |
| 각 대입 시점의 부기 상태 | 부분적 — A가 붙을 때 `inner.Length == 0`, outer의 뒤 offset은 아직 stale | **전부 완결** |

두 방식 다 `_elements`를 깊이 우선으로 같은 순서로 훑으므로 **관측 가능한
마운트 순서는 동일**하다. 달라지는 건 "그 시점에 부기가 얼마나 완성돼
있는가"뿐이다.

### 7-2. 그 차이를 실제로 관측하는 주체가 있고, 분해 쪽이 더 정확하다

Roblox의 `Parent` 대입은 **동기적으로 `ChildAdded`/`DescendantAdded`/
`AncestryChanged`를 발화**시킨다. 즉 사용자 핸들러가 마운트 도중에 실제로
끼어들어 상태를 읽는다.

- **현행**: A의 `ChildAdded`가 뜰 때 `inner.Length`는 아직 `0`이고, `outer`의
  뒤 형제 offset도 아직 안 밀려 있다 — **완성 전 스냅샷**을 보게 된다.
- **분해**: 첫 `ChildAdded`가 뜰 때 **서브트리 전체의 `Length`/`Offset`이 이미
  최종값**이다.

`slot.Length`를 구독하는 사용자 State/Observer("n개 검색됨" 라벨 등)도 같다 —
분해 쪽이 **한 번, 최종값으로** 발화한다(현행은 `0` → 최종으로 두 번).
`PostRef`가 "자기 아래는 전부 끝난 뒤"를 보장하는 것과 결이 같아진다.

**즉 원래 동작을 보존할 이유가 약한 정도가 아니라, 원래 동작 쪽이 덜 정확하다.**

### 7-3. "합치는 거대 함수"는 애초에 목적을 못 이룬다

*"액티베이션 재귀와 실측시 마운트를 합치는 거대한 함수를 만드는게 아닌이상
해결하지 못할 문제"* — 맞는데, **그 거대 함수를 만들어도 안 풀린다.** 두
변형을 다 따져보면:

- **완전 병합(측정하면서 그 자리에서 마운트)** — 자식의 최종 길이는 그 자식의
  재귀가 **끝나야** 알 수 있으므로, 자식을 마운트하는 시점엔 아직 자기 길이를
  모른다. **C6를 못 지킨다** — 그게 정확히 지금 코드(= `Length=0`으로 등록 후
  자기 교정)다. 새로 얻는 게 없다.
- **부분 병합(자식마다 `materialize` → 바로 `mount` → 다음 형제)** — 실제로
  가능하고 인터리브도 유지된다. 하지만 **자기 길이를 부모에게 등록하는 건
  여전히 루프가 다 끝난 뒤**라, 고치려던 부모 레벨 C7 위반이 그대로 남는다.
  구조만 복잡해지고 목적은 못 이룬다.

**그래서 실질적 선택지는 둘뿐이다** — (A) 인터리브 + 자기 교정(현행),
(B) 분해 + 일괄. "인터리브하면서 최종값도 아는" 제3의 안은 구조적으로 없다.

### 7-4. 부수 이득 둘

1. **Blocker의 목적이 선명해진다** — `mountSlotTree`는 부기를 전혀 안
   건드리는 순수 walk라 Blocker가 필요 없다. 결과적으로 Blocker가
   `materializeSlotTree` **하나만** 감싸게 되고, "이건 배치 *등록*을 게이팅하는
   물건"이라는 정의와 코드 모양이 일치한다(지금은 물리 마운트까지 같이 감싸고
   있어 이름과 범위가 어긋난다).
2. **백엔드가 갈아끼울 seam이 생긴다** — `mountSlotTree`가 "부기는 끝났고
   붙이기만 하면 되는" 순수 함수라, 일괄 삽입이 유리한 백엔드(웹의
   `DocumentFragment` 등)가 **이 함수 하나만** 자기 방식으로 바꿔 끼울 수 있다.
   인터리브 구조에서는 부기 호출 사이사이에 물리 조작이 박혀 있어 불가능하다.

### 7-5. 판단 갱신 — 약한 추천에서 **추천**으로

6-5절은 "약하게 추천"이었는데, 위 7-2(관측 정확도)와 사용자가 짚은 **구현
실수 위험**을 더하면 근거가 한 단계 올라간다:

- 안 쪼개면 C1~C7 일곱 제약이 **한 함수 안에서 줄 순서로만** 지켜진다 —
  `RC-1`/`RC-3`/`RC-4`가 전부 그 줄 순서를 잘못 잡아서 난 버그였다. 분해하면
  그중 C2/C3/C7이 **함수 경계로 강제**되어 줄 순서 실수로 깨질 수 없게 된다.
- 남는 반대 근거는 "확정된 의사코드를 건드린다" 하나인데, 위 위험과 견주면
  약하다.

**단 여전히 M6 착수 전까지 시간이 있고, 실제로 짜보며 확정해도 늦지 않다** —
지금 확정할 필요는 없다는 판단은 안 바뀐다.
