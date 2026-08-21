# 구현 전 손 트레이싱 **6라운드** — 최근 확정분 전수 추적, 발견 10건

**상태**: **[2026-08-22 작성] 사용자 회신 대기.** 아무것도 고치지 않았다 —
`base/`는 한 줄도 안 건드린 상태이고, 아래는 전부 **발견 보고**다. 판단이
필요한 항목이 섞여 있어서(특히 `H-1`) 임의로 반영하지 않았다.

**왜 이 라운드가 있는가**: 사용자 요청 — *"Effect 의 다인자 Ref 허용
변경분, Gate/Blocker 의 새 형태, State 의 전파모델(invalid 의 새 전략,
emit 지연과 전파의 새 전략), Slot 의 새로운 native와 offset/length/mount
전략, 새로운 Brand와 Epoch/EpochMap에 대해 손 트레이싱을 시도해봐요.
뭔가 문제가 되는 것들이 나오면 알려주세요."*

**성격이 4·5라운드와 다르다.** 4·5라운드는 "예/아니오로 답할 문항지"였는데,
이번엔 **2·3라운드와 같은 손 트레이싱**이다 — 확정된 의사코드를 실제 값으로
한 줄씩 돌려보고 어긋나는 지점만 적는다. 그래서 문항 번호가 아니라 **발견
번호**(`H-n`)를 쓴다.

**추적 대상 5개 영역**(사용자가 지목한 그대로):
`Effect(fn, ...deps)` / `Gate`·`Blocker` / State 전파(`rawInvalid`·emit 지연) /
Slot의 `native*`·offset·length·mount / `Brand`·`Epoch`·`EpochMap`.

**읽는 순서**: 🔴 셋(`H-1`~`H-3`)이 실제로 크래시하거나 조용히 어긋나는
것이고 나머지는 그보다 가볍다. 마지막 "이상 없다고 확인한 것" 절도 같이
볼 것 — **다시 트레이싱할 필요가 없는 자리**를 적어뒀다.

| 번호 | 심각도 | 한 줄 | 주 대상 |
|---|---|---|---|
| `H-1` | 🔴 | `:List`의 `keyIndex`가 사이클 도중엔 stale인데 live 배열 인덱스로 쓰임 | `base/slot-plan.md` |
| `H-2` | 🔴 | `pos`(리프 개수)를 `_elements` 배열 인덱스로 겸용 — 중첩 Slot 반환 시 즉시 크래시 | `base/slot-plan.md` |
| `H-3` | 🔴 | `getOffsetAt`의 접두합 캐시를 아무도 무효화하지 않음 | `base/dispatch-core-plan.md` |
| `H-4` | 🟡 | `bk.invalidAfter`/`bk.offsetCache`가 부기 스펙에 없음 + 초기값 `nil` 비교 | `base/dispatch-core-plan.md` |
| `H-5` | 🟡 | `spliceArraysUp`이 `bk.N`을 먼저 올려, 금지하기로 한 창을 연다 | `base/slot-plan.md` |
| `H-6` | 🟡 | `unmountSlotTree`가 정의되지 않은 `physicalTarget`을 참조 | `base/slot-plan.md` |
| `H-7` | 🟡 | `Effect`의 `Ref` 의존성은 떼어낼 방법이 없음(해제 API·게이팅 부재) | `base/effect-plan.md`, `base/ref-plan.md` |
| `H-8` | 🟡 | `EffectHandle._observer`가 아직 단수 — N-deps 확정과 불일치 | `base/effect-plan.md` |
| `H-9` | 🟢 | 게이트 `withheld`가 첫 flush 스왑에서 weak를 잃음 | `base/gate-plan.md` |
| `H-10` | 🟢 | `recompute`의 `sum` 시작값 주석이 stale — 그대로 구현하면 `Length`가 틀림 | `base/dispatch-core-plan.md` |

---

## 🔴 `H-1` — `:List` reconcile의 `keyIndex`가 사이클 **도중**엔 stale인데 live `_elements` 인덱스로 쓰인다

**어디**: `base/slot-plan.md`의 `settle`(`keyIndex[key]`를 `rawDetach`/
`releaseElement`/`rawMove`/`rawReplace`의 index 인자로 넘기는 네 자리)과
`reconcile`의 소멸 루프.

**무엇이 어긋나나**: `keyIndex = newKeyIndex` 교체는 `reconcile`의 **끝**에서
한 번만 일어난다. 그런데 사이클 도중의 `rawAdd`/`rawRemove`는
`table.insert`/`spliceArraysDown`으로 배열을 시프트하므로, 그 뒤에 처리되는
키들의 `keyIndex` 값은 전부 한 칸씩(또는 그 이상) 어긋난다. `raw*` 인자
규약 절이 *"그 값은 이미 `keyIndex`가 들고 있다(그 키가 지금 차지한 압축
위치 = `_elements` 인덱스)"* 라고 단정한 게 정확히 여기서 깨진다.

**트레이스 A — 앞에 하나 끼우기(가장 흔한 케이스)**

`data = [a, b]` → `_elements = {A, B}`, `keyIndex = {ka=1, kb=2}`.
다음 사이클 `data = [x, a, b]`:

| 스텝 | 키 | 판정 | 결과 |
|---|---|---|---|
| 1 | `kx` | 새 키 → `rawAdd(self, X, 1)` | `_elements = {X, A, B}` |
| 2 | `ka` | `result == prev`, `keyIndex[ka]=1 ≠ pos=2` → `rawMove(self, 1, 2)` | 인덱스 1은 이제 **`X`** → `{A, X, B}` |
| 3 | `kb` | `keyIndex[kb]=2 ≠ pos=3` → `rawMove(self, 2, 3)` | 인덱스 2는 **`X`** → `{A, B, X}` |

최종이 `x, a, b`여야 하는데 `a, b, x`가 된다. `rawMove`가 `Parent`를 안
건드리는 경로라 물리 순서는 `recompute`가 만드는 offset을 통해 어긋난다 —
에러가 안 나고 **조용히 틀린다.**

**트레이스 B — 전체 삭제(크래시)**

`data = [a, b, c]` → `data = []`. 소멸 루프가 `pairs(keyIndex)`를 도는데
해시 순회라 순서가 임의다. `kb`가 먼저 나오면:

1. `settle(kb, nil, false, 0)` → `releaseElement(self, 2, B, false)` →
   `rawRemove(self, 2)` → `spliceArraysDown` → `_elements = {A, C}`
2. 이어서 `kc` → `releaseElement(self, 3, C, false)` → `rawRemove(self, 3)` →
   `local element = self._elements[3]` = **`nil`** →
   `releaseOwner(nil, self)` 또는 `nativeRemove(..., { nil })`에서 터진다.

즉 **필터도 중첩도 없는 평범한 "리스트 비우기"가 순회 순서에 따라 크래시**한다.

**왜 지금까지 안 잡혔나**: 2·3라운드 트레이싱은 `RC-1`/`RC-3`/`RC-4`처럼
**마운트 순서** 쪽을 봤고, 5라운드의 `raw*` index 통일은 "`settle`이 index를
어디서 구하나"만 물었지 **그 값이 언제 유효한가**는 안 물었다.

**⭐ 판단이 필요하다 — 세 갈래 중 어느 쪽으로 갈지**:

1. **라이브 인덱스 맵 유지** — 모든 `raw*`가 자리 수를 바꿀 때
   `keyIndex`(또는 전용 맵)를 같이 갱신. 정확하지만 `raw*`가 `:List`의
   클로저 상태를 알아야 해서 층이 섞인다.
2. **`settle`에 element를 넘기고 `indexOfRaw`를 기본 경로로** — 5라운드가
   "폴백이지 기본 경로가 아니다"라고 못박은 걸 되돌리는 것. O(n)이 붙지만
   층 분리는 유지된다.
3. **reconcile을 2패스로** — 제거/detach를 전부 먼저 처리해 배열을 압축한
   뒤, 삽입/이동을 하는 forward pass. 시프트가 한 방향으로만 일어나
   인덱스 추론이 가능해진다.

어느 쪽이든 **`raw*`를 전부 index 기준으로 통일한 5라운드 결정의 전제를
다시 봐야 한다.**

---

## 🔴 `H-2` — `pos`(리프 개수)를 `_elements` 배열 인덱스로 겸용한다

**어디**: `base/slot-plan.md`의 `reconcile` —
`pos = candidateIndex - 1 + (if isSlot(result) then result.Length:Get() else 1)`
로 전진시킨 `pos`를 그대로 `settle(key, result, detach, pos)`에 넘기고,
`settle`은 그걸 `rawAdd(self, element, pos)` / `rawMove(..., pos)` /
`newKeyIndex[key] = pos`로 쓴다.

**무엇이 어긋나나**: `pos`는 **물리 리프 개수** 기준(중첩 Slot 하나가
`.Length`만큼 전진)인데, `_elements`는 **중첩 Slot 하나당 한 칸**이다. 두
좌표계가 한 변수에 겹쳐 있다.

**트레이스 — 첫 사이클에 바로 터진다**

빈 `:List`, 첫 아이템의 `updateFn`이 Length 3짜리 중첩 Slot `S`를 반환
(멀티루트 컴포넌트 결과 — 문서가 명시적으로 지원하는 형태):

1. `pos = 0`, `candidateIndex = 1`
2. `result = S`, `isSlot` → `pos = 1 - 1 + 3 = 3`
3. `settle(k1, S, false, 3)` → `rawAdd(self, S, 3)` →
   `table.insert(self._elements, 3, S)` 인데 `#_elements == 0` →
   **`position out of bounds`로 그 자리에서 터진다.**

터지지 않는 변형(앞에 이미 요소가 있는 경우)에서도 `newKeyIndex[key] = pos`가
배열 인덱스가 아니게 되므로 다음 사이클의 `H-1` 경로와 합쳐져 더 나빠진다.

**주의**: `base/slot-plan.md`의 "`:List`의 `index`도 nested-Slot 결과의"
절은 **`updateFn`에 넘기는 `index`(=`candidateIndex`)** 얘기이고, 그 결론
자체는 옳다. 문제는 같은 카운터를 배열 인덱스로도 재사용한 것 — **리프
카운터와 슬롯 카운터를 분리**해야 한다(예: `pos`는 리프용으로 두고,
`_elements` 위치는 별도 `slotPos`를 매 생존 아이템마다 +1).

---

## 🔴 `H-3` — `getOffsetAt`의 접두합 캐시가 어디에서도 무효화되지 않는다

**어디**: `base/dispatch-core-plan.md`의 "Length/Offset — 여러 Slot이 형제로
섞일 때 순서 보장" 절, `Dispatch.getOffsetAt` 의사코드와 그 아래 무효화 표.

**무엇이 어긋나나**: 표는 무효화 규칙(`invalidAfter = math.min(invalidAfter, i)`,
베이스 변경이면 `0`)을 정확히 정의해뒀는데, **코퍼스 전체에서
`bk.invalidAfter`에 실제로 대입하는 코드는 `getOffsetAt` 안의 `= 1`/`= at`
둘뿐이다**(전수 grep으로 확인). `Dispatch.setLength`, `gatedRecompute`,
`slot._baseObserver`의 콜백, `spliceArraysUp`/`spliceArraysDown` 어느
의사코드도 캐시를 당기지 않는다. 즉 **규칙이 산문으로만 존재하고 코드
경로가 없다.**

**트레이스 A — 형제 길이 변경**

`Frame { SlotA(Length 2), SlotB(Length 3) }`:
- 등록 후 `bk.offsetCache = {0, 2}`, `bk.invalidAfter = 2`, `SlotB.Offset = 2`
- `SlotA`에 요소가 하나 늘어 `Length` 2 → 3, emit → `bk.observers[1]` →
  `gatedRecompute` → `recompute(Frame, bk)`
- `recompute`의 `i = 2`: `Dispatch.getOffsetAt(Frame, 2)` →
  `at(2) <= invalidAfter(2)` → **캐시된 `2`를 반환**(정답은 3)
- `offset:Get() ~= abs` 가드에 걸려 `Set`이 안 일어남 →
  **`SlotB.Offset`이 2에 고정된 채 `SlotA`가 0..2를 점유**

`sum`(→ `ownerKey.Length`)은 `lengthList`에서 매번 새로 더하므로 **위로는
맞고 옆으로만 틀린다** — 알아채기 특히 어려운 형태다.

**트레이스 B — 베이스 변경 / 포탈 재마운트**

- `slot._baseObserver`도 `recompute`만 부르고 캐시를 `0`으로 안 당긴다 →
  앞 형제가 커져 내 베이스가 밀려도 **자식 offset 전체가 옛 베이스 기준**.
- 재마운트는 더 나쁘다: `bk`는 `Relate(slot)` 위에 있어 언마운트를 넘어
  살아남으므로 `invalidAfter > 0`이고 `offsetCache[1]`엔 **옛 베이스**가 들어
  있다. `materializeSlotTree`의 `setOffsetSource` 즉시 계산이 `slot.Offset`에
  새 값을 넣어도, 그 시점 `_baseObserver`는 아직 `unbindLifetime` 상태(재앵커
  전)라 `canExecute`가 거짓이어서 **발화조차 안 한다.**

**필요한 것**: 표의 세 규칙을 실제 호출부에 배치. 최소한 (a) `setLength`
본문과 그 Observer 콜백, (b) `spliceArraysUp`/`Down`, (c) `_baseObserver`
콜백 — 셋 다 `recompute` **전에** `invalidAfter`를 당겨야 한다.

---

## 🟡 `H-4` — `bk.invalidAfter`/`bk.offsetCache`가 부기 스펙에 없고, 초기값이 `nil`이면 비교에서 터진다

`base/dispatch-core-plan.md`의 "저장 위치" 문단은 `lengthList`/`sourceList`/
`observers`/`N`만 열거한다 — `offsetCache`/`invalidAfter`가 빠져 있다.

그리고 `getOffsetAt`은 `if bk.invalidAfter == 0 then`으로 시작하는데,
`bk.N`이 `nil`로 시작하는 규칙(그래서 `recompute`가 `bk.N or 0`으로 방어)과
같은 lazy 생성이면 `invalidAfter`도 `nil`이다 → `nil == 0`은 거짓 → 다음 줄
`at <= bk.invalidAfter`에서 **`attempt to compare number with nil`**. 첫
position의 `setOffsetSource`가 바로 이 경로다(그 함수가 `getOffsetAt`을
부르므로 fresh `bk`에서 반드시 밟는다).

`getBookkeeping`이 `invalidAfter = 0`, `offsetCache = {}`로 초기화한다는 것을
"저장 위치" 문단에 명시하면 닫힌다.

---

## 🟡 `H-5` — `spliceArraysUp`이 `bk.N`을 먼저 올려, 금지하기로 한 창을 연다

`base/dispatch-core-plan.md`의 `bk.N` 수명주기 문단은 이렇게 못박아뒀다 —
**`setOffsetSource`는 `bk.N`을 건드리지 않는다**, 그래야
*"`lengthList[i]`가 아직 안 채워진 채로 `bk.N`만 먼저 커지는 창이 안 생긴다"*.

그런데 `base/slot-plan.md`의 `rawAdd`는:

```
spliceArraysUp(self, index)   -- 주석: "_elements 외 배열들을 한 칸 밀고 bk.N 증가"
Dispatch.setOffsetSource(self, index, None)
nativeInsert(self._mountedInst, Dispatch.getOffsetAt(self, index), { element })
Dispatch.setLength(self, index, 1, self._mountedInst)
```

`bk.N`은 첫 줄에서 이미 올라가고 `lengthList[index]`는 마지막 줄에서야
채워지므로 **그 창이 실재하며, 그 안에 물리 op이 들어 있다.** Roblox의
`Parent` 대입은 `ChildAdded`/`DescendantAdded`를 **동기 발화**시키므로, 그
핸들러가 같은 owner에 손대면 `recompute`가 `lengthList[index] == nil`을 읽어
`sum += nil`로 터진다(`sourceList[index]`는 `None`으로 채워져 있어 그쪽
`error` 가드엔 안 걸린다).

이건 yield가 아니라 **동기 재진입**이라 "체인 도중 yield 금지" 불변식으로는
안 덮인다. 셋 중 하나가 필요하다 — (a) `bk.N` 규칙 문단을 "splice도 올린다"로
정정하고 그 창을 UB로 명시, (b) `spliceArraysUp`이 `lengthList[index]`에
자리표시자를 채우게 함, (c) `nativeInsert`를 `setLength` 뒤로 옮김(단
"자기 자리 먼저 / 뒤를 미는 것 나중" 계약과 충돌하므로 그쪽을 다시 봐야 함).

---

## 🟡 `H-6` — `unmountSlotTree`가 정의되지 않은 `physicalTarget`을 참조한다

`base/slot-plan.md`의 "파괴 — 재귀적 `Clear()` 금지, flat teardown" 절:

```lua
local function unmountSlotTree(slot)       -- 인자는 slot 하나뿐
    ...
        nativeExtract(physicalTarget, Dispatch.getOffsetAt(slot, i), { element })
```

`physicalTarget`이 **어디에도 안 묶여 있다.** `slot._mountedInst`여야 하고,
같은 함수가 아래에서 `slot._mountedInst = nil`로 지우므로 **읽는 순서도**
같이 지켜야 한다(루프가 그 대입보다 위라 지금 배치로는 문제없지만, 로컬로
먼저 뽑아두는 게 안전).

**곁가지(같은 절)**: 이 루프는 요소를 하나씩 빼면서 매번
`Dispatch.getOffsetAt(slot, i)`(=부기 offset)을 넘기는데, 앞을 뺄 때마다 뒤가
물리적으로 당겨지므로 **두 번째부터는 실제 물리 위치와 다른 값**이 넘어간다.
`native*` 계약이 *"빠지는 요소는 반드시 `elements` 배열로 넘긴다"*로 확정돼
있어 Roblox 백엔드는 무해하지만, offset을 신뢰하는 백엔드(DOM에서
`childNodes[offset]`으로 찾는 최적화 등)에선 어긋난다. `nativeExtract`의
`offset`이 **제거 경로에선 의미가 없다**는 걸 계약으로 못박든지, 역순
순회(뒤에서부터)로 바꾸든지 정해야 한다.

---

## 🟡 `H-7` — `Effect`의 `Ref` 의존성은 떼어낼 방법이 없다

`base/effect-plan.md`의 "`Effect(fn, ...deps)` — 여러 의존성을 직접 받는다"
절이 `Ref`를 의존성으로 허용하고, `Ref`면 `:Callback`으로 구독한다고
확정했다. 그런데 `base/ref-plan.md`는 콜백을 이렇게 확정해뒀다 —
`type(v) == "thread"`인 대기자만 발화 후 `[i] = nil`로 소진하고, **일반 콜백
함수는 *"소진 안 함, 계속 유지"***. 그리고 **콜백 해제 API가 없다**
(`:Uncallback` 류 없음), **`canExecute` 게이팅도 안 걸린다**(그건 Observer
쪽 배관이다).

**트레이스**: `Effect(fn, someRef)`를 children 배열 leaf로 놓는다. 그 leaf가
죽는다 →

- Observer 쪽은 `bindLifetime` cascade가 끊겨 `canExecute`가 거짓이 된다. ✅
- `Ref` 쪽은 `ref.Callbacks`에 클로저가 **영구히 남는다.** 그 클로저가
  `EffectHandle`을 강참조하므로 → **누수**, 그리고 이후 `ref:Set`마다
  **이미 죽은 leaf에 대해 직전 cleanup + `fn`을 계속 실행**한다.

같은 절이 *"leaf dedup/cascade가 전부를 덮어야 한다"*고 요구하는데, `Ref`
쪽은 그걸 만족시킬 **수단 자체가 아직 없다.** 필요한 건 둘 중 하나 —
(a) `Ref`에 콜백 해제 경로를 추가, 또는 (b) Effect가 거는 `Ref` 콜백이
자기 핸들의 `canExecute`를 먼저 확인하고(거짓이면 자기 자신을 `Callbacks`에서
`nil`로 소진) 넘어가게 하는 관용구를 계약으로 못박기.

---

## 🟡 `H-8` — `EffectHandle._observer`가 아직 단수다

`base/effect-plan.md`의 "보강 — `EffectHandle`의 내부 Observer 바인딩 세부"
문단 전체가 단수 전제로 쓰여 있다 — `handle._observer = observer`,
`bindLifetime(inst, handle._observer)` cascade, `:Subscribe()`도
`handle._observer`.

N-deps 확정(같은 문서 아래 절)과 정면으로 어긋난다. 그대로 구현하면 **2번째
이후 dep의 Observer에는 `canExecute` 판정 근거가 아예 안 실려** 그 Observer의
재실행이 통째로 죽는다 — 그 문단 자신이 옛날에 경고한 바로 그 실패 모드다.
필드를 `handle._observers`(배열)로 바꾸고 cascade/`Subscribe`/`Unsubscribe`를
전부 순회로 고치면 된다(새 결정 없음, 단순 반영 누락).

---

## 🟢 `H-9` — 게이트 `withheld`가 첫 flush 스왑에서 weak를 잃는다

`base/gate-plan.md` 4번이 `withheld`를 **weak key**로 확정했는데, flush
의사코드는 `self._withheld = {}`로 **평범한 테이블**을 만든다
(`OffWithoutEmit`의 "새 테이블로 스왑"도 같다). 첫 flush 이후로는 그 게이트가
죽은 `Epoch`를 붙잡을 수 있다. `setmetatable({}, {__mode = "k"})`로 만드는
헬퍼 하나면 닫힌다.

---

## 🟢 `H-10` — `recompute`의 `sum` 시작값 주석이 stale하다

`base/dispatch-core-plan.md`의 `recompute` 의사코드 위 주석은 여전히
*"`0`이 아니라 이 owner의 베이스에서 시작한다"*인데, 바로 아래 코드는
`local sum = 0`이고 **지금은 그게 맞다** — 접두합이 `getOffsetAt`으로
빠지면서 `sum`은 `Length` 전용이 됐고, 같은 함수 끝의 주석이
*"`Length`엔 base를 안 더한다"*로 이미 그렇게 말한다. 주석을 믿고 구현하면
`Length`에 베이스가 더해져 **상위 전체의 길이 합이 틀어진다.** 주석 한 줄
정정.

---

## 이상 없다고 확인한 것 (다시 트레이싱하지 말 것)

- **`Epoch`/`EpochMap` 판정 규칙** — `base/state-epoch-plan.md` §1의
  다이아몬드(`A→B→D`, `A→C→D`)를 실제 값으로 돌렸다. 규칙 1/2/3 +
  `valueEpochMap:Refresh()`가 섞인 값 관측과 이중 재계산을 **둘 다** 막는다.
  전파 도중 하류가 `D:Get()`을 부르면 `C`가 `Refresh`로 스스로 낡음을 알아채
  재계산하고, 뒤늦게 도착한 `C` 쪽 emit은 규칙 3으로 접힌다.
- **게이트가 붙들고 있는 동안 하류가 앞당겨 읽는 경로** — 재계산이 끝나며
  `valueEpochMap`을 전부 갱신해두므로, 나중에 게이트가 푸는 통지는 규칙 2
  (통지만)로 떨어져 같은 값을 다시 계산하지 않는다. `GateNode`가
  `emitEpochMap`을 수신이 아니라 flush 시점에 `:Sync(batch)`로 갱신하는
  예외도 다이아몬드에서 정책이 한 번 더 도는 것 말고 부작용이 없다.
- **`blocker:OffWithoutEmit()` 후 `emitEpochMap`이 뒤에 남는 것** — 그
  `Epoch`의 다음 진짜 emit이 규칙 1로 걸려 자가 치유된다. 별도 조치 불필요가
  맞다.
- **`Effect`의 `EpochMap` dedup + `_installing` 순서** — `A → b`, `A → c`,
  `Effect(fn, b, c)`에서 `A:Set()` 한 번에 `fn`이 정확히 한 번 돈다. 억제
  플래그가 `Update`보다 먼저라 설치 발화의 `from = nil`이 맵을 오염시키지도
  않는다.
- **`Ref` 콜백의 발화 계약** — `:Callback`이 "이미 채워져 있으면 등록 즉시
  1회"이고 함수 콜백은 소진되지 않으므로, `Effect`의 "최소 1회 실행" 및
  "`Ref`는 `Set`될 때마다 발화"가 둘 다 성립한다(떼어내는 쪽만 `H-7`).
- **`materializeSlotTree` → `mountSlotTree` 분해** — depth 2 트리
  (`{plainA, SlotInner{p1, p2}, plainB}`)로 부기와 물리를 양쪽 다 돌렸고,
  등록 순서(`setOffsetSource` → 실체화 → `setLength`)와 물리 삽입 위치
  (`acc`)가 정확히 맞는다. 중첩 Slot을 런타임에 `Add`하는 경로도 추적했고
  `nativeInsert`가 뒤 형제를 미는 결과가 부기 offset과 일치한다.
- **단건 `rawAdd`의 순서가 배치 경로와 반대인 것** — plain 분기는
  `nativeInsert` → `setLength`, 중첩 Slot 분기는 `attachSlot`(부기 먼저) →
  물리다. `native*`가 미는 주체라는 계약 아래에선 **둘 다 맞다**(모순 아님).
- **`activateList`를 `blocker:On()` 밖에서 부르는 것** — `rawAdd`의
  `_mounted == false` 얼리리턴이 실제로 그걸 안전하게 만든다(게이팅할
  `recompute` 자체가 안 일어남).
- **`Brand` 인스턴스 브랜드 + 다중 태깅** — `Source`를 `SourceBrand`와
  `EpochBrand`에 동시 등록하는 것과, 포함 관계를 predicate 합성으로 남기는
  것 사이에 충돌이 없다. `isEpoch` 분기(노드 생성 시딩의 `:Sync` vs
  `:TrackFrom`)도 이 표면으로 정확히 표현된다.

---

## 회신 방법

`H-1`만 **선택**이 필요하고(위 세 갈래), 나머지는 "맞다/아니다"만 알려주면
그대로 반영하겠다. `H-5`·`H-6`은 어느 쪽으로 정정할지도 같이 정해야 한다.
반영은 이 파일이 아니라 각 `base/` 문서에 하고, 처리 결과는 4·5라운드와 같은
방식으로 `-followup.md`에 쌓는다.
