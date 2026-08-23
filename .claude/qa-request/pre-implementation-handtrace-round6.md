# 구현 전 손 트레이싱 **6라운드** — 최근 확정분 전수 추적 + 2차 전역 패스

**상태**: **[2026-08-22 작성, 2026-08-23 2차 패스 추가] 사용자 회신 대기.**
아무것도 고치지 않았다 — `base/`는 한 줄도 안 건드린 상태이고, 아래는 전부
**발견 보고**다. 판단이 필요한 항목이 섞여 있어서(특히 `H-1`) 임의로
반영하지 않았다.

**⭐ [2026-08-23] 2차 패스를 이어붙였다** — 사용자 요청(*"지금 나온거 이외에
더 문제될만한게 있는지 조사해봐줘. … 시스템 전체 계획을 봐도 좋고"*)으로
**1차가 안 본 영역까지 확장**해서 다시 돌렸다. 1차는 사용자가 지목한 5개
영역이 범위였고, 2차는 `dispatch-core-plan.md`/`source-state-plan.md`/
`lifecycle-pattern.md`/`ref-plan.md`/`tag-plan.md`/`attribute-plan.md`/
`ui-shorthand-plan.md`/`brand-plan.md`/`gate-plan.md`/`blocker-plan.md`/
`state-epoch-plan.md`와 `slot-plan.md`의 `raw*` 계층을 **의사코드 단위로**
훑었다. 발견은 아래 "2차 패스" 절(`H-11`~`H-20`)이고, 1차와 같은 규칙으로
**아무것도 반영하지 않았다.**

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
| `H-2` | 🔴 | `pos`(리프 개수)를 `_elements` 배열 인덱스로 겸용 — 중첩 Slot 반환 시 즉시 크래시(**[2026-08-23 재검증] 트레이스 수치 정정**) | `base/slot-plan.md` |
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

**⚠️ [2026-08-23 재검증에서 정정] 원래 여기 적었던 트레이스는 숫자가
틀렸었다 — 그런데 실제 동작은 그것보다 더 나쁘다.** 옛 트레이스는
*"`updateFn`이 Length 3짜리 중첩 Slot을 반환"*을 전제했는데, **그 상황은
일어날 수 없다**:

- `updateFn`이 반환하는 중첩 Slot은 **정의상 아직 어디에도 마운트 안 된
  것**이다 — 이미 마운트돼 있으면 `rawAdd`의 `claimOwner`가 즉시 error다
  (`base/slot-plan.md`의 "요소 소유권" 절).
- 그런데 `Length`를 쓰는 주체는 **`recompute` 하나뿐**이고(5라운드 `C-2`
  확정), `recompute`는 `materializeSlotTree` 안에서야 처음 돈다. 즉 마운트
  전 Slot의 `.Length`는 **항상 `0`**이다(같은 문서가
  *"옛 코드는 `inner.Length == 0`인 미완성 스냅샷을 보여줬다"*고 확인해준다).

**그래서 `isSlot(result)` 분기는 언제나 `+ 0`이다.** 두 가지가 동시에 깨진다.

**(a) `_elements` 인덱스로서 — 첫 사이클에 바로 터진다**

빈 `:List`, 첫 아이템의 `updateFn`이 중첩 Slot `S`를 반환(멀티루트 컴포넌트
결과 — 문서가 명시적으로 지원하는 형태):

1. `pos = 0`, `candidateIndex = 1`
2. `result = S`, `isSlot` → `pos = 1 - 1 + S.Length:Get()` = `0 + 0` = **`0`**
3. `settle(k1, S, false, 0)` → `rawAdd(self, S, 0)` →
   `table.insert(self._elements, 0, S)` → Luau는 `pos`가 `1..#t+1` 밖이면
   **`position out of bounds`를 던진다** → 그 자리에서 터진다.

앞에 이미 생존자가 있는 변형에선 터지지 않는 대신 **직전 생존자와 똑같은
인덱스**를 받아 조용히 잘못된 자리에 끼워 넣고, `newKeyIndex[key] = pos`도
그 값으로 기록되어 다음 사이클의 `H-1`/`H-16` 경로와 합쳐진다.

**(b) `updateFn`의 `index`로서 — 원래 목적 자체가 첫 사이클에 성립 안 한다**

`pos`가 `.Length`만큼 전진하도록 만든 이유는 *"다음 형제의 index가 이
아이템이 실제로 차지하는 물리적 개수를 반영해야 함"*(`base/slot-plan.md`의
"`:List`의 `index`도 nested-Slot 결과의" 절)인데, 새로 만들어진 중첩 Slot은
그 시점 `Length`가 `0`이라 **아무것도 반영하지 못한다.** 다음 사이클부터는
그 Slot이 마운트돼 있어 진짜 `Length`가 나오므로, **같은 데이터에 대해
첫 사이클과 이후 사이클의 `index`가 달라진다** — `updateFn`이 그 값으로
`LayoutOrder`를 계산하는 확정 관용구(같은 문서의 "왜 `LayoutOrder`를 Slot이
대신 안 해주는가" 절 예시)가 첫 프레임에 틀린 값을 받는다는 뜻이다.

**주의**: `base/slot-plan.md`의 "`:List`의 `index`도 nested-Slot 결과의"
절이 **의도한 것**(`updateFn`에 넘기는 `index`가 물리 개수를 반영해야 함)
자체는 옳다. 깨진 건 둘이다 — (1) 같은 카운터를 `_elements` 배열 인덱스로도
재사용한 것, (2) 그 물리 개수를 **아직 마운트 안 된 Slot의 `.Length`**에서
읽는 것. (1)은 **리프 카운터와 슬롯 카운터를 분리**하면 닫힌다(`pos`는
리프용, `_elements` 위치는 별도 `slotPos`를 매 생존 아이템마다 +1).
(2)는 더 근본적이다 — 마운트 전 Slot의 기여도를 미리 알 방법이 지금
설계엔 없다(`Length`는 `recompute`만 쓰고 그건 마운트 시점에 돈다).
"이 자리를 몇 칸으로 세는가"를 마운트 전에 확정할 수 있게 하든, 첫
사이클의 `index`가 잠정값임을 계약으로 인정하든 정해야 한다.

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
- **`Ref` 콜백의 발화 계약** — `:Callback`은 등록 즉시 1회 불리고
  (**[2026-08-23 재검증 시 표현 정정]** "이미 채워져 있으면"이 아니라
  **미설정이어도 그 상태 그대로 무조건** 1회 — `base/ref-plan.md`의 "Ref
  일반화" 절), 함수 콜백은 소진되지 않는다. 그래서 `Effect`의 "최소 1회
  실행"과 "`Ref`는 `Set`될 때마다 발화"가 둘 다 성립하고, `Effect`의 설치
  구간 억제 플래그가 `Ref` 쪽 첫 발화까지 같이 눌러야 한다는 것도 이
  계약에서 바로 나온다(떼어내는 쪽만 `H-7`).
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

## 1차 패스 회신 방법

`H-1`만 **선택**이 필요하고(위 세 갈래), 나머지는 "맞다/아니다"만 알려주면
그대로 반영하겠다. `H-5`·`H-6`은 어느 쪽으로 정정할지도 같이 정해야 한다.
반영은 이 파일이 아니라 각 `base/` 문서에 하고, 처리 결과는 4·5라운드와 같은
방식으로 `-followup.md`에 쌓는다.

**⬇️ 아래에 2026-08-23 2차 패스(`H-11`~`H-20`)가 이어진다** — 회신 방법은
그 절 끝에 따로 적어뒀다.

---

# 2차 패스 (2026-08-23) — 1차가 안 본 영역까지 확장, 발견 9건 + 철회 1건

**범위가 왜 늘었나**: 1차는 사용자가 지목한 5개 영역만 봤다. 2차는 같은
방식(의사코드를 실제 값으로 돌려보기)을 **디스패치 코어 전체 / 라이프타임
유틸 / Ref·Tag·Attribute·UI 숏핸드 핸들러 / Slot의 `raw*` 계층**까지 넓혔다.
그래서 발견의 성격도 조금 다르다 — 1차가 "최근 확정분 안의 어긋남"이었다면,
2차엔 **오래 전에 확정됐지만 배선이 통째로 빠진 것**(`H-11`)과 **두 base
문서가 서로 반대를 말하는 것**(`H-13`)이 섞여 있다.

**읽는 순서**: `H-11`이 가장 무겁다 — 기능 하나가 아니라 **`Effect`라는
프리미티브 전체가 안 도는** 문제이고, `slot._detached` 정리와 `OnDestroyed`가
거기 딸려 있다. 그다음이 `H-12`(정상 사용 경로 크래시),
`H-13`(문서 간 정면 모순).

**⭐ [2026-08-23] 커밋 전에 `H-1`~`H-20` 전수를 `base/` 원문과 대조했다.**
결과는 셋이다:
- **`H-15`는 오탐이라 철회**했다 — `base/ui-shorthand-plan.md`에 이미 예외
  판정(`UI-11`)이 있었는데 그걸 못 보고 일반 규칙만 인용했다. 번호는
  비우지 않고 철회 기록으로 남긴다.
- **`H-2`는 결론은 맞지만 트레이스 수치가 틀려서 다시 썼다** — 마운트 전
  중첩 Slot의 `.Length`는 **항상 `0`**이라(그 값을 쓰는 주체가 `recompute`
  하나뿐이고 그건 마운트 시점에 돈다) 원래 적은 `+3`이 나올 수 없었다.
  실제 동작은 원래 적은 것보다 **더 나쁘다**(그 항목 참고).
- **나머지 18건은 원문 대조로 전부 유효**함을 확인했다. 특히 `H-3`은
  `bk.invalidAfter`에 대입하는 코드가 코퍼스 전체에서 `getOffsetAt` 안의
  두 줄뿐임을 grep으로, `H-11`은 `Destroying`이 산문에만 등장하고 어떤
  의사코드에도 연결되지 않음을 grep으로 다시 확인했다.

| 번호 | 심각도 | 한 줄 | 주 대상 |
|---|---|---|---|
| `H-11` | 🔴 | `Effect`의 leaf 사망 cleanup을 **발화시키는 배선이 어느 의사코드에도 없다** | `base/lifecycle-pattern.md`, `base/effect-plan.md` |
| `H-12` | 🔴 | `rawRemove`/`rawUnmount`/`rawDetach`에만 "아직 마운트 전" 분기가 없음 — 마운트 전 CRUD가 크래시 | `base/slot-plan.md` |
| `H-13` | 🔴 | `Effect(fn, ...deps)` 역전이 `source-state-plan.md`에 반영 안 됨 — 거긴 아직 "기각"이 **일반 원칙**으로 서 있음 | `base/source-state-plan.md`, `base/effect-plan.md` |
| `H-14` | 🟡 | `Effect`의 `fn` 시그니처가 확정 안 됨(`self`/`previous` 자리, `Ref` dep 읽는 법) | `base/effect-plan.md` |
| `H-15` | ✅ **철회** | (`UICornerHandler`가 자식 체인을 안 걷어냄 — **오탐이었다**, 아래 참고) | `base/ui-shorthand-plan.md` |
| `H-16` | 🟡 | `newKeyIndex[key] = pos`가 마운트 안 된 키에도 배열 인덱스를 기록(`0` 포함) | `base/slot-plan.md` |
| `H-17` | 🟡 | `Dispatch.drive`의 Blocker 범위가 `F-4-1`(단일 일반화 `for`)와 안 맞음 + `PostRef`가 blocker ON 상태에서 발화 | `base/dispatch-core-plan.md` |
| `H-18` | 🟡 | attribute 이름을 그룹 A→B로 옮기는 게 emit 순서에 따라 error | `base/attribute-plan.md` |
| `H-19` | 🟢 | `rawAdd`/`rawReplace`의 plain 분기가 `recompute`를 두 번 돌림 | `base/slot-plan.md` |
| `H-20` | 🟢 | `Processed*RefHandler`의 `process` 시그니처가 핸들러 계약과 다름 | `base/ref-plan.md` |

---

## 🔴 `H-11` — `Effect`의 leaf 사망 cleanup을 실제로 발화시키는 코드가 어디에도 없다

**어디**: `base/lifecycle-pattern.md`의 "(1)" 코드 블록(`bindLifetime`/
`unbindLifetime` 실 구현 스케치), `base/source-state-plan.md`의
"Observer/Effect Leaf dedup" 절(`ObserverEffectLeafHandler.process`),
`base/effect-plan.md`의 "보강" 문단.

**무엇이 어긋나나**: 세 문서가 `Destroying` 훅을 **전제로만** 쓰고, 아무도
그걸 **연결하지 않는다.**

- `base/lifecycle-pattern.md`의 "2. Instance 파괴는" 절은 *"인스턴스
  라이프사이클 훅 지점은 `Destroying` 하나로 통일"*이라 못박고, 같은 절의
  `LP-2` 구체화가 **`Effect`가 그 훅을 쓰는 유일한 소비자**라고 확정했다.
- `base/effect-plan.md`는 비용까지 적어뒀다 — *"비용은 leaf당 실제 Destroying
  바인딩 하나(공유 weak table로 되는 Observer보다 비쌈)"*.
- 그런데 leaf가 실제로 붙는 유일한 경로는
  `ObserverEffectLeafHandler.process`의 `bindLifetime(inst, v)` 한 줄이고,
  `bindLifetime`의 실 구현 스케치는 **`gchold[value] = true` + `BindData`에
  gcconn/gchold 복사**가 전부다. `Destroying`도, cleanup 저장도, 그걸 부를
  주체도 없다.

**트레이스**

```lua
local e = Effect(function()
    local conn = RunService.Heartbeat:Connect(tick)
    return function() conn:Disconnect() end     -- 이 cleanup
end)
Frame { e }
-- ... 나중에 frame:Destroy()
```

1. `Dispatch.drive` → `ObserverEffectLeafHandler.process(inst, 1, e, ...)` →
   `bindLifetime(inst, e)` → `gchold[e] = true`, `BindData:SetWeak(e, "gcconn", …)`.
2. `inst:Destroy()` → 엔진이 gcconn을 끊음 → `isBoundAlive(e)`가 거짓이 됨.
3. **끝.** `canExecute`가 거짓이 되어 *"앞으로 발화하지 마라"*는 성립하지만,
   **cleanup을 부르는 코드는 어디에도 없다.** `conn`은 영원히 연결된 채 남는다.

**파급이 국소적이지 않다** — 이 한 줄이 빠지면 같이 죽는 것들:

- **`slot._detachCleanup`**(`base/slot-plan.md`의 `activateList`). 이건
  `Detach`로 홀드된 요소를 파괴하는 **유일한** 경로이고, 같은 문서가
  *"quad는 자기가 만든 Instance마다 gcconn을 걸고 그 클로저가 `inst`를
  캡처하므로 … `Parent = nil`인 detach 노드는 아무도 안 들고 있어도 자기
  시그널 커넥션이 자기를 살려 영원히 남는다. GC 폴백이 아예 없으므로 명시적
  정리 경로가 **필수**"*라고 적어뒀다. 그 필수 경로가 `Effect` 하나에
  얹혀 있는데 그게 안 돈다.
- **`OnDestroyed`**(`base/lifecycle-hooks-plan.md`) — `Effect` 위의 순수
  슈가라 통째로 무동작.
- `base/lifecycle-pattern.md`가 *"커스텀 Destroy-time 처리가 필요하면
  `Effect`를 쓰면 되는 구조"*라며 `[Event "Destroying"]` 직접 바인드를
  비권장으로 돌린 안내(`LP-4`)도 근거를 잃는다.

**왜 지금까지 안 잡혔나**: 이 배선은 `bindLifetime`이 정식 명명되기(2026-08-09)
**전에** 결정된 것이고(`Effect` 절은 2026-08-07), 이후 `bindLifetime`의
실 구현 스케치가 세 번 재작성되는 동안(`canExecute` 시그니처 역전, `(0)`
gcconn 선생성 전환, `canBound` 재도입) 매번 **Observer 기준으로만** 쓰였다.
`Effect`만 필요한 추가 요구가 그 사이 조용히 빠진 것으로 보인다.

**정해야 하는 것**(전부 열려 있음):

1. **누가 `Destroying`을 거는가** — `bindLifetime`이 `isEffect(value)`일 때
   같이 걸지, `EffectHandle` 쪽이 자기 `bindLifetime` 직후에 걸지.
   전자면 `bindLifetime`이 값 타입을 가리게 되는데, 그건 *"게이트는 값
   타입을 안 가린다"*(`base/source-state-plan.md`의 "`bindLifetime`이 이
   게이트의 두 번째" 절)와 결이 다르다.
2. **`unbindLifetime`은 cleanup을 부르는가** — **안 부르는 게 맞아 보인다.**
   `destroySlotTree`가 `_detachCleanup`을 `unbindLifetime`하며 달아둔 주석
   (*"이미 손으로 비웠으니 Effect는 할 일 없음"*)이 그 전제 위에 서 있고,
   `base/effect-plan.md`의 `E-11`(leaf 바인딩엔 `:Unsubscribe()`가 아예 안
   먹는다)도 같은 방향이다. 다만 **그러면 `unbindLifetime`은 `Destroying`
   커넥션을 끊기만 하고 cleanup은 영영 안 불린다**는 것도 계약으로 명시해야
   한다(지금은 어느 쪽도 안 적혀 있다).
3. **cleanup을 어디 보관하는가** — `handle` 필드(예: `handle._cleanup`)로
   둘지, `Destroying` 클로저의 upvalue로만 둘지. `Rerun`(재실행 시 직전
   cleanup 호출)이 이미 그 값을 필요로 하므로 필드 쪽이 자연스러워 보인다.

---

## 🔴 `H-12` — `rawRemove`/`rawUnmount`/`rawDetach`에만 "아직 마운트 전" 분기가 없다

**어디**: `base/slot-plan.md`의 `raw*` 의사코드 블록.

**무엇이 어긋나나**: 같은 블록 안에서 **`rawAdd`와 `rawReplace`는
`if not self._mounted then … return end` 얼리리턴을 갖고 있는데, 자리를
없애는 3형제(`rawRemove`/`rawUnmount`/`rawDetach`)엔 그 분기가 없다.**
셋 다 `self._mountedInst`(마운트 전엔 `nil`)와 `Dispatch.getOffsetAt`,
`recompute`를 무조건 부른다.

**트레이스 — 완전히 평범한 사용**

```lua
local s = Slot()
s:Add(Frame{})     -- rawAdd: _mounted == false → _elements에만 넣고 return
s:Remove(1)        -- rawRemove: 얼리리턴 없음
```

`rawRemove(self, 1)`:
1. `local bk = getBookkeeping(self)` — `rawAdd`가 부기를 하나도 안 남겼으므로
   `lengthList`/`sourceList`가 **비어 있다**.
2. `Dispatch.getOffsetAt(self, 1)` — fresh `bk`라 `bk.invalidAfter`가 `nil`,
   즉 `H-4`가 지적한 `attempt to compare number with nil` 경로를 그대로 밟는다.
   (`H-4`를 고쳐 `invalidAfter = 0`으로 초기화하면 여기선 `0`이 반환된다.)
3. `nativeRemove(self._mountedInst, 0, { element })` — 첫 인자가 **`nil`**.
   백엔드가 `Destroy`를 부르든 뭘 하든 그 자리에서 터진다.
4. `recompute(self, bk)` — `bk.N`이 `nil`이라 `bk.N or 0` 방어에 걸려 no-op.

`rawUnmount`/`rawDetach`도 `nativeExtract(self._mountedInst, …)`로 정확히 같다.
중첩 Slot 요소면 `unmountSlotTree(element)`로 빠지는데 그것도 `H-6`
(`physicalTarget` 미정의)에 걸린다.

**이게 정상 사용인 근거**: `Slot`은 *"`inst`/`i`를 모르는 독립 값(어디
마운트될지 자기가 결정 안 함)"*이고, `rawAdd`의 `_mounted == false` 분기가
존재하는 이유 자체가 "마운트 전에 요소를 채워두는 것"을 정상 경로로 지원하기
위해서다. 그 상태에서 하나를 도로 빼는 것도 당연히 정상이다. CRUD 표의
에러 조건 목록에도 "마운트 전 `Remove` 금지" 같은 건 없다.

**필요한 것**: 셋에 `rawAdd`/`rawReplace`와 같은 얼리리턴을 넣고 —
`table.remove(self._elements, index)` + `releaseOwner`(+`rawRemove`면 파괴)만
하고 물리/부기 조작 없이 반환 — 그 안에서 파괴 대상 처리(`nativeDispose` vs
`destroySlotTree`)는 `rawReplace`의 `not self._mounted` 분기가 이미 쓰는
모양(*"트리 밖이라 물리 op이 필요 없다"*)을 그대로 재사용하면 된다.

---

## 🔴 `H-13` — `Effect(fn, ...deps)` 역전이 `source-state-plan.md`엔 반영 안 됐고, 거기선 아직 **일반 원칙**으로 서 있다

**어디**: `base/source-state-plan.md`의 "`:Compute(fn, ...)` — 추가 의존성을
trailing args로 직접 받는 sugar" 절 vs `base/effect-plan.md`의
"`Effect(fn, ...deps)`" 절.

**무엇이 어긋나나**: 두 base 문서가 정반대를 말한다.

- `source-state-plan.md`: *"**`Effect(fn, ...)`/`state:Observer(fn, ...)`류
  trailing-args 확장은 기각** — 여기선 진짜 새 노드가 생기기 때문."* 그리고
  바로 아래에서 이걸 **일반 원칙으로 승격**해뒀다 — *"trailing args sugar는
  그게 정말 무료일 때만 붙인다 … 없던 노드를 새로 만들어야 하는
  경우(Effect/Observer의 다중 의존성 병합)엔 sugar 없이 `:With`를 명시적으로
  남긴다."* 심지어 `quadnomicon` 에세이 소재로까지 등록돼 있다.
- `effect-plan.md`: 같은 결정을 5라운드 `C-6`에서 **역전**했다(`🔄 [역전됨,
  2026-08-21 …]`). 근거도 정면으로 부딪힌다 — *"각 의존성에 구독을 따로 걸면
  **합치는 노드 자체가 안 생긴다** — 감출 비용이 애초에 없다."*

**왜 위험한가**: `source-state-plan.md`는 반응형 코어의 정본이라 구현자가
`Effect` 표면을 짜기 전에 반드시 읽는 문서다. 지금 상태로는 그 문서만 보고
`Effect(fn, state?)`(단일 dep)로 구현하는 게 완전히 합리적이고, 그러면
5라운드가 닫은 갭(**`Ref`는 `:With`로 못 합치므로 `Effect`의 의존성이 될
방법이 아예 없다**)이 그대로 되돌아온다. `H-8`(`_observer` 단수)과 합쳐지면
"두 문서가 모두 단수를 말하고 한 문서만 복수를 말하는" 상태라, 단수 쪽으로
수렴할 가능성이 오히려 높다.

**같이 정해야 하는 것 — `Observer`는 정말 그대로 기각인가**: `effect-plan.md`
`C-6`은 `Effect`만 역전했다. 결과적으로 `state:Observer(fn, ...)`는 여전히
기각인데, **그 기각의 근거가 `Effect`와 공유되던 것**이라 지금은 논거가
비어 있다. 실제로는 "`Observer`는 리시버 State 하나에 붙는 구독이고, 여럿을
엮는 건 `Effect`가 대신한다"가 새 근거로 맞아 보이지만, 그건 어디에도 안
적혀 있다.

---

## 🟡 `H-14` — `Effect`의 `fn` 시그니처가 확정 안 됐다

`base/effect-plan.md`는 *"인자 모양은 `:Compute(fn, ...deps)`의 선례
그대로 — trailing deps를 **lazy 위치 인자**로 콜백에 넘긴다"*고만 적었다.
그런데 그 선례의 확정 시그니처는 **`fn(self, previous?, ...deps)`**이고
(`base/source-state-plan.md`), `Effect`엔 둘 다 없다:

- **`self`가 없다** — `Effect`는 자유 함수라 리시버 State가 없다.
- **`previous`가 없다** — 파생값을 안 만드는 leaf라 캐시 슬롯 자체가 없다.
  대신 `fn`의 **반환값이 cleanup**이라 의미가 정반대다.
- 같은 문서 위쪽엔 아직 옛 단수 시절 표기 **`fn(state)`**가 남아 있다.

그래서 `Effect(fn, a, b)`의 `fn`이 `fn(a, b)`인지 `fn(nil, a, b)`인지
문서만으로 안 정해진다. 단수 시절 `fn(state)`와 하위 호환되려면 `fn(...deps)`
쪽이지만, 그러면 "선례 그대로"라는 문장이 틀린 서술이 된다.

**곁가지 — `Ref` dep은 lazy 핸들이 아니다.** State/Source dep은 `dep:Get()`로
읽는 lazy 핸들인데 `Ref`는 즉시 값 박스라 `dep.Value`다(`:Get()`이 없다).
`Effect(fn, someState, someRef)`의 `fn`은 인자마다 읽는 법이 다른데, 그
구분을 사용자가 위치로 기억해야 하는지 `isRef`로 분기해야 하는지가 안 적혀
있다. `:Compute`의 "모든 인자가 lazy State 핸들"이라는 단일 규칙(그리고
`:Get()` 누락이 반복 실수라 별도 절까지 있는 그 규칙)이 `Effect`에서는
**성립하지 않는다**는 걸 명시할 필요가 있어 보인다.

---

## ✅ `H-15` — **철회됨(오탐)**. `UICornerHandler`가 자식 체인을 안 걷어내는 건 이미 판정된 사항

**[2026-08-23 커밋 전 재검증에서 철회]** 초안은 *"`destroyManagedChild`가
`Dispatch.retractFrom(child, "CornerRadius", 1)`을 안 부르는데,
`base/dispatch-core-plan.md`가 '실행 중인 Tween/구독처럼 즉시 끊어야 하는 게
있으면 명시적 정리가 필요'라고 요구한 바로 그 케이스"*라고 적었다.
**그 일반 규칙의 예외로 이미 사용자 판정이 나 있었다** —
`base/ui-shorthand-plan.md`의 "자식을 파괴할 때" 절(4라운드 `UI-11`)이
*"`Dispatch.retractFrom(child, prop, 1)`을 "정석"으로 요구하지 않는다 —
실익이 없다"*로 확정해뒀고, 근거 셋이 전부 유효하다:

1. Roblox 엔진이 Destroy 시점에 그 인스턴스에 걸린 Tween을 알아서 정리한다.
2. `PropertyHandler`가 반환하는 retractor는 애초에 몸체가 no-op이라 불러봐야
   하는 일이 없다(`base/tween-plan.md`).
3. `chains`는 `child`에 대해 weak-keyed라 자식을 버리면 결국 GC된다.

**직접 재확인한 나머지 한 갈래도 안전하다** — `v`가 `State<number>`여서 그
체인에 `StoreBind` Observer가 얹히는 경우, 그 Observer는
`bindLifetime(child, observer)`로 **자식에게** 묶이므로 자식이 Destroy되면
gcconn이 끊겨 `canExecute`가 거짓이 되고 `gchold`째로 GC된다. `UI-11`의
*"명시적 정리가 필요한 자원이 이 자리엔 없다"*가 맞다.

**남는 것은 표기 하나뿐(🟢)** — 그 의사코드 retractor의 인자 이름이 아직
`hint`다. `base/dispatch-core-plan.md`가 *"코퍼스 전반에서 이 인자를
`hintValue`라고 부르는데 이는 타입이 보장되지 않던 옛 모델에서 온 이름"*
이라고 이미 짚어둔 잔재이고, 이 문서만 남아 있는 것으로 보인다.

**교훈(다음 라운드용)**: 일반 규칙(`dispatch-core-plan.md`)만 보고 "이
호출부가 규칙을 안 지킨다"고 판정하기 전에, **그 호출부 문서에 예외 판정이
있는지**를 반드시 먼저 확인할 것. 이번 2차 패스에서 유일하게 이 확인을
빠뜨린 항목이다.

---

## 🟡 `H-16` — `newKeyIndex[key] = pos`가 마운트 안 된 키에도 배열 인덱스를 기록한다

**어디**: `base/slot-plan.md`의 `reconcile` 정상 루프 끝
(`userdata[key] = ud` 바로 다음 줄).

`newKeyIndex[key] = pos`는 **생존 여부와 무관하게 모든 키에** 실행된다.
그런데 `pos`는 `result ~= nil`일 때만 전진하므로:

| 키 | `updateFn` 반환 | `pos` | `newKeyIndex` |
|---|---|---|---|
| `a` | 새 값 | 1 | 1 |
| `b` | `nil`(필터 탈락) | 1 | **1** ← `a`와 같은 인덱스 |
| `c` | `Detach` | 1 | **1** ← 또 같음 |
| `d` | 새 값 | 2 | 2 |

그리고 **첫 아이템부터 탈락하면 `newKeyIndex[key] = 0`** 이다 — Lua 배열에
존재할 수 없는 인덱스다.

**지금은 대부분 안 터진다** — 그 키들이 다음 사이클에 밟는 분기들(재마운트,
`wasDetached` 파괴, 신규 `rawAdd`)이 마침 `keyIndex`를 안 쓰고 `pos`를 쓰기
때문이다. 하지만 그건 **우연이고**, `H-1`을 어느 갈래로 고치든(특히 (1)번
"라이브 인덱스 맵 유지") 이 값들이 실제 인덱스로 취급되는 순간 바로
`_elements[0]`/엉뚱한 요소를 만지게 된다.

**근본 원인은 `keyIndex`가 두 역할을 겸하는 것**이다:
1. **"직전 사이클에 데이터에 있던 키 전체 집합"** — 소멸 루프가
   `pairs(keyIndex)`를 도는 이유이고, 문서가 *"`pairs(mounted)`로는 필터
   탈락 상태로 사라진 키가 안 잡혀 `userdata`가 샌다"*고 명시적으로 요구한
   성질이다.
2. **"그 키가 차지한 `_elements` 인덱스"** — `raw*` 인자 규약이 의존하는 성질.

마운트 안 된 키는 (1)엔 있어야 하고 (2)는 **정의상 없다**. 두 관심사를 한
테이블에 담은 게 defect의 뿌리다 — `H-1`을 손볼 때 같이 쪼개야 한다
(예: `seenKeys` 집합 + `keyIndex`는 마운트된 키만).

---

## 🟡 `H-17` — `Dispatch.drive`의 Blocker 범위가 `F-4-1`과 안 맞고, `PostRef`가 blocker ON 상태에서 발화한다

**어디**: `base/dispatch-core-plan.md`의 `Dispatch.drive` 설명
(*"배열 파트 순회 전체를 `inst` 전용 `Blocker`로 감싼다"*)과 같은 문서의
`F-4-1` 정정(*"실제 구현은 일반화 `for` **한 번**"*).

**무엇이 어긋나나**: 확정 문장은 *"순회 시작 전에 … `:On()`하고, **배열 파트
순회가 (pre-pass/post-pass 포함) 전부 끝나면** `:OffWithoutEmit()` 한 뒤
`recompute(inst, bk)`를 명시적으로 1회"*다. 두 패스 구현에선 이게 자연스럽게
표현되지만, `F-4-1`이 확정한 **단일 일반화 `for` + `type(k) == "number"`
분기**에선 "배열 파트가 끝나는 시점"이 루프 밖에서 관측되지 않는다 — 첫
비숫자 키를 만나는 순간이거나 루프 종료이고, 둘 중 어느 쪽인지는 그 인스턴스의
props에 해시 키가 있느냐에 달렸다.

게다가 괄호 안의 *"post-pass 포함"*이 그 문장 자체와 부딪힌다 —
`postRefList` 소비는 **해시 파트보다 뒤**다(`base/ref-plan.md`의 `PostRef`
절: *"두 패스가 끝난 뒤"*). 그러니 실제로 감쌀 수 있는 범위는 배열 파트가
아니라 **`drive` 전체**다.

**그래서 무엇이 문제인가** — 범위가 넓어지는 것 자체는 무해해 보이지만
(해시 파트는 `setLength`를 안 부른다), **`PostRef` 콜백이 blocker가 켜진
채로 실행된다는 사실이 어디에도 안 적혀 있다.** 그 콜백은 사용자 코드이고,
`base/ref-plan.md`가 드는 대표 용례부터가 "이 시점 이후의 동적 변경을
구분하는 플래그를 세우는 것"이라 **그 자리에서 `slot:Add(...)`류를 부르는
게 자연스럽다.** 그러면:

- 그 Slot 자신의 blocker는 이미 꺼져 있어 자기 `recompute`는 정상적으로 돈다.
- 그 결과 바뀐 `slot.Length`가 emit되어 **부모 `inst`의** `bk.observers[i]` →
  `gatedRecompute`로 올라오는데, 여기서 부모 blocker가 **아직 ON**이라
  조용히 스킵된다.
- 정합성은 그 직후의 명시적 `recompute(inst, bk)` 한 번에 **전적으로**
  의존하게 된다. 지금은 우연히 맞지만, 그건 계약으로 적힌 적이 없다.

**정할 것**: (a) blocker 범위를 문장 그대로 "배열 파트"로 좁힐지(그러면
단일 루프 안에서 전이를 감지하는 구현을 명시해야 하고, post-pass는 밖으로
나간다), 아니면 (b) 실제대로 "`drive` 전체"로 넓혀 적고 **`PostRef` 콜백은
게이트 안에서 돈다**는 걸 계약으로 못박을지.

---

## 🟡 `H-18` — attribute 이름을 그룹 A에서 그룹 B로 옮기면 emit 순서에 따라 error가 난다

**어디**: `base/attribute-plan.md`의 "이름 소유권" 절, "해제 → 재클레임
순서는 `Dispatch`가 보장함" 항목.

그 항목의 논증은 이렇다 — *"같은 핸들러 재프로세스는 `slot.retractor(v)` →
`h.process(...)` 순서이고, 핸들러가 바뀌는 경우는 `retractFrom` → `process`
순서 — 어느 경로든 옛 claim 반납이 새 claim보다 먼저라 **자기 자신과
충돌하는 일이 없음**."* 마지막 다섯 글자가 정확하다: 이 보장은 **한
`(inst,k)` 체인 안에서만** 성립한다.

**트레이스 — 두 그룹이 이름을 주고받는 경우**

```lua
Frame {
    groupA,   -- k=1, State<Attribute>. 지금 {"Hp"}를 잡고 있음
    groupB,   -- k=2, State<Attribute>. 지금 {}
}
-- 런타임에: A는 "Hp"를 놓고, B가 "Hp"를 가져간다
```

두 자리는 **완전히 별개의 체인**이고, 각자 자기 `StoreBind`의 Observer가
독립적으로 깨어난다. `groupB` 쪽 emit이 먼저 처리되면:

1. `(inst,2)` 재프로세스 → `AttributeGroupHandler.process` →
   `Dispatch.process(inst, groupKey(vB,"Hp"), …, 1)` → `AttributeKeyHandler.process`
2. `nameClaims:GetStrong(inst, "Hp")`가 **아직 `groupA`의 전용 키**를 가리킴
   → `cur ~= nil and cur ~= k` → **`error("attribute "Hp" is already bound
   by another owner")`**

`groupA` 쪽 emit이 먼저면 정상 동작한다. 즉 **같은 코드가 emit 순서에 따라
성공하거나 크래시한다.** 사용자가 `Blocker`로 두 소스를 묶어도 두 체인의
전파 순서는 여전히 미정이라 통제 수단이 없다.

**곁가지 — 이건 "부분 실패"로도 나쁘다**: 위 2번에서 error가 날 때
`groupB`의 `process`는 이미 그 앞 이름 몇 개를 `Dispatch.process`로
위임해둔 뒤일 수 있다. 같은 문서가 *"에러=패닉 상태, 그 이후 정합성은
관리 대상 아님"*으로 이미 선을 그어뒀으니 계약 위반은 아니지만, **정상적인
리팩터링 의도가 그 패닉 경로로 들어간다**는 게 문제다.

**선택지**:
1. **UB/에러로 못박기** — "attribute 이름을 두 그룹 사이에서 옮기려면 한
   프레임 안에서 하지 말고, 놓는 쪽을 먼저 커밋하라"를 문서 계약으로.
   가장 싸지만 사용자가 순서를 통제할 수단이 지금 없다.
2. **claim 반납을 늦추기(2단계)** — 재프로세스 사이클 동안은 claim을 "예약
   해제" 상태로 두고 사이클 끝에 sweep. Dispatch에 사이클 개념을 들여야 해서
   비싸다.
3. **claim 충돌 시 즉시 error 대신 "이전 소유자가 아직 살아 있는가"를
   확인** — 옛 소유자의 체인이 이미 죽었으면 조용히 인수. 판정 수단이
   지금 없다(그래서 `groupClaimKeys`가 따로 생긴 것).

---

## 🟢 `H-19` — `rawAdd`/`rawReplace`의 plain 분기가 `recompute`를 두 번 돌린다

`base/slot-plan.md`의 `rawAdd` plain 분기:

```lua
Dispatch.setOffsetSource(self, index, None)
nativeInsert(self._mountedInst, Dispatch.getOffsetAt(self, index), { element })
Dispatch.setLength(self, index, 1, self._mountedInst)
recompute(self, bk)
```

`Dispatch.setLength`는 `len`이 상수여도 마지막에 `gatedRecompute()`를 부르고
(`base/dispatch-core-plan.md`의 `setLength` 구현 — *"상수 길이도 같은 게이트를
통과"*), 런타임 단건 경로에선 그 owner의 Blocker가 이미 꺼져 있으므로
(*"런타임에 이미 마운트된 Slot에 한 번에 하나씩 `:Add()`하는 흔한 패턴은 이
게이팅이 필요 없다"*) 그게 곧바로 `recompute(self, bk)`다. 바로 다음 줄이
또 `recompute(self, bk)`다. `rawReplace`의 마지막 두 줄도 같은 모양이다.

**크래시는 아니다** — `recompute`는 `offset:Get() ~= abs` 가드가 있어 두
번째 호출은 대체로 아무것도 안 쓴다. 다만 (a) O(N) 순회가 두 번 돌고,
(b) 더 중요하게는 **"`recompute`를 누가 부르는가"의 소스가 두 곳**이 되어
`H-3`(캐시 무효화)을 고칠 때 어느 자리에 `invalidAfter`를 당길지가 애매해진다.
`setLength`가 게이트를 태우는 것으로 통일하고 명시 호출을 지우든, 반대로
명시 호출만 남기고 상수 경로에선 `gatedRecompute`를 안 태우든 하나로 정할 것.

---

## 🟢 `H-20` — `ProcessedPreRefHandler`/`ProcessedPostRefHandler`의 `process` 시그니처가 핸들러 계약과 다르다

`base/ref-plan.md`의 두 의사코드가 전부 이 모양이다:

```lua
function ProcessedPreRefHandler.process(inst, i, v)
```

확정된 계약은 `process(inst, key, value, index)`(4-인자)다. 두 가지가 어긋난다:

1. **4번째 인자 `index`가 빠졌다.** 이 두 핸들러는 재위임을 안 하므로 실제로
   안 쓰지만, 시그니처는 계약대로 두는 게 맞다(`NilHandler`/`NoneHandler`는
   4-인자로 적혀 있어 지금은 표기가 갈려 있다).
2. **2번째 인자를 `k`가 아니라 `i`로 부른다.** 본문에서 실제로 배열 위치로
   쓰고 있으니 동작은 맞지만, 이건 `base/dispatch-core-plan.md`의 "Handler
   작성 체크리스트" 6번이 경고하는 바로 그 혼동이다 — *"배열 파트의
   위치(`k`)와 이 `index`는 완전히 다른 것 — `AttributeGroupHandler`가 배열
   위치를 `index`라고 이름 붙였다가 시그니처 자체가 계약과 어긋난 전례가 있음."*
   같은 실수의 거울상(위치를 `i`로 부르고 계약상 `index` 자리를 비움)이라,
   표기만 `(inst, k, v, index)`로 통일하면 닫힌다.

---

## 2차 패스에서 확인만 하고 **문제 없었던** 것 (다시 트레이싱하지 말 것)

- **`TagHandler`의 위치 기준 참조 카운트** — `Frame { Tag("a"), Tag("a","b") }`,
  `Tag(A)→Tag(B)` 같은 위치 교체, 같은 `Tag` 객체를 두 위치에서 재사용,
  spurious 재발행(`v == nextValue` 얼리리턴)까지 실제 값으로 돌렸다.
  `holders[k]` 기준이라 전부 정확하고, `added`/`removed`가 실제로 바뀐
  이름에만 모인다. (유일한 잔여는 `holders`가 빈 테이블이 된 뒤에도
  `tagNameMap` 엔트리가 남는 것인데, `inst`에 대해 weak라 누수가 아니고
  다음 `process`가 `next(holders) == nil`을 보고 정상적으로 `addTag`한다.)
- **`AttributeGroupHandler`의 retractor가 `Dispatch.retractFrom`을 부르는 것** —
  "클로저 안에서 `retractFrom` 금지"는 **같은 `(inst,k)`**에 대한 것이고
  (`base/dispatch-core-plan.md` 체크리스트 5번), 여기선 자기가 위임했던
  **다른 키들**이라 명시적으로 허용된 경우다. 게다가 `AttributeKeyHandler`의
  retractor가 엔진 부작용이 0(claim 반납만)이라 생존 이름을 일단 철거했다가
  다시 등록해도 `a→nil→b` 깜빡임이 없다. 계약대로 맞다.
- **`Dispatch.process`의 (A)/(B) 분기와 `#list` 불변식** — `drive`가 항상
  `index=1`로 진입하고, (B) 분기가 `h.process` **전에** 점유 마커를 박고,
  래핑 핸들러가 `index+1`로만 재귀하므로 배열에 구멍이 뚫리는 경로가 없다.
  `State<State<T>>`도 인덱스가 겹치지 않는다.
- **`Brand`의 다중 태깅과 `isState`/`isRef` 합성** — `Source`가
  `SourceBrand`+`EpochBrand`에 동시 등록되는 것과,
  `isRef = isPreRef or isPostRef or RefBrand:is`,
  `isState = isSource or StateBrand:is`가 서로 안 부딪힌다.
  `RefLeafHandler.isHandlable`의 `not isPreRef and not isPostRef` 배제와도
  일관된다.
- **`materializeSlotTree` → `mountSlotTree` 순서와 `_baseObserver` 생성 위치** —
  `_baseObserver`를 `blocker:On()` **뒤**에 만드는 것이 실제로 필요하고
  (등록 즉시 1회 실행이 빈 부기를 훑는 걸 막음), `activateList`를 `On()`
  **앞**에서 부르는 것도 `rawAdd`의 `_mounted == false` 얼리리턴 덕에 안전하다.
  두 배치가 서로 반대인 게 의도된 것이 맞다.
- **`Epoch` 리비전의 `bit32.bnot(-rev)` 랩** — `luau`로 실제 값을 확인했고
  (`0 → 4294967295`, `1 → 0`, `2 → 1`), 규칙이 `==`/`~=`만 쓰므로 감소·랩이
  문제되지 않는다. `2^32` 충돌 조건이 "정확히 한 바퀴 동안 한 번도 안
  건드려진 항목"이라는 문서 서술도 맞다.
- **`unmountSlotTree`/`destroySlotTree`의 자원 해제 대칭** — 언마운트는
  앵커만 풀고 핸들·`_listActivated`·`_detached`·`Offset` identity를 보존,
  파괴는 핸들까지 `nil`. `activateList`의 멱등 가드가 재마운트에서 앵커만
  옮기는 것과 정확히 맞물린다. (단 그 재마운트 경로가 `bindLifetime`을 다시
  부르는 게 안전한 건 언마운트가 먼저 `unbindLifetime`했기 때문이고,
  `canBound` 게이트가 그걸 전제한다 — 구현 시 이 짝이 깨지면 바로 error가
  난다는 걸 인지할 것.)

---

## 2차 패스 회신 방법

1차와 같다 — **"맞다/아니다"만 주면 그대로 반영**하겠다. 다만 아래 넷은
갈래 선택이 필요하다:

- **`H-11`** — `Destroying`을 누가 거는가(1/2/3번 소항목).
  **이게 가장 급하다**: M3의 `Effect` 구현이 여기서 시작하고,
  `slot._detached` 정리와 `OnDestroyed`가 전부 딸려 있다.
- **`H-13`** — `source-state-plan.md`의 기각 서술과 그 "일반 원칙"을 어떻게
  고칠지(원칙 자체를 `:Compute` 한정으로 좁힐지, `Observer`의 새 근거를
  같이 적을지).
- **`H-17`** — blocker 범위를 좁힐지(a) 넓혀 적을지(b).
- **`H-18`** — 세 선택지 중 하나.

나머지(`H-12`/`H-14`/`H-16`/`H-19`/`H-20`)는 확인만 해주면 바로
반영 가능하다. `H-15`는 **철회했으므로 답할 게 없다**(그 자리에 남은 🟢
표기 하나만 같이 봐주면 된다). 반영은 이 파일이 아니라 각 `base/` 문서에 하고, 처리 결과는
1차와 묶어 `-followup.md`에 쌓는다.
