# 구현 전 손 트레이싱 **6라운드** — 최근 확정분 전수 추적 + 2~4차 전역 패스

**상태**: **[2026-08-22 작성, 2026-08-23 2·3차 패스, 2026-08-24 4차 패스 추가] 사용자 회신 대기.**
아무것도 고치지 않았다 — `base/`는 한 줄도 안 건드린 상태이고, 아래는 전부
**발견 보고**다. 판단이 필요한 항목이 섞여 있어서(특히 `H-1`) 임의로
반영하지 않았다.

**⭐⭐ [2026-08-23] 3차 패스가 맨 아래 붙어 있다(`H-21`~`H-38`)** — 1·2차가
한 번도 안 연 문서 전체(Store/State/Source 코어, Modifier·컴포넌트 합성,
이벤트·라이프사이클·에러 격리, Tween·시간 게이트, 타입 계약과 **실제 커밋된
M1 코드**)와 문서 경계를 가로지르는 통합 시나리오를 돌린 결과다. **이번엔
추론으로 끝내지 않고 로컬 `luau` 0.734 / `luau-analyze`로 직접 재현했고**,
그 과정에서 **기존 `H-2`의 크래시 주장이 틀렸다는 것도 드러났다**(3차 패스
머리의 "먼저" 절이 소스 — 결론은 유효하지만 결과가 크래시가 아니라 조용한
영구 고아다).

**⭐⭐ [2026-08-24] 4차 패스도 붙어 있다(`H-39`~`H-54`)** — 이번엔 문서 단위가
아니라 **축을 바꿔서** 훑었다(핸들러 레지스트리 전수 / 두 대형 핸들러 문서
심층 / **스파이크 실제 재실행** / 프리미티브 조합 매트릭스 / `reference`·
`archive`·로드맵 M3~M9 / **엔진·언어 사실 주장 전수 검증**). 가장 무거운
`H-39`는 **세 축에서 독립적으로 같은 결론**에 도달했고, 문서를 하나씩 읽는
방식으로는 구조적으로 안 보이는 종류였다. 부수로 **`H-21`의 전제가 공식
문서로 확인**됐고, 반대로 **`PreRef`의 존재 근거가 엔진 설정에 조건부**라는
게 드러났다(`H-42`).

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

**⬇️ 아래에 2026-08-23 3차 패스(`H-21`~`H-38`)가 이어진다** — 회신 방법은
그 절 끝에 따로 적어뒀고, 맨 앞에 **`H-2` 실측 정정**이 있다.

**⬇️ 그 뒤에 2026-08-24 4차 패스(`H-39`~`H-54`)가 이어진다** — 회신 방법은
그 절 끝에 따로 있다.

---

# 3차 패스 (2026-08-23) — 1·2차가 안 본 문서 전체 + 실측 검증, 발견 18건 + `H-2` 정정

**범위가 왜 또 늘었나**: 사용자 요청(*"지금 나온거 이외에 더 문제될만한게
있는지 조사해봐줘 … 시스템 전체 계획을 봐도 좋고 … 그러고 나서 모든 요소들이
진짜 실존하는 문제인지 사실확인을 해줘"*). 1차는 최근 확정 5개 영역, 2차는
디스패치 코어·라이프타임·핸들러·`raw*` 계층이었다. **3차는 그 둘이 한 번도
안 연 문서를 전부 연다** — `store-plan.md`/`source-state-plan.md`(`:Compute`/
`Observer`/GC 불변식) / `modifier-plan.md`/`component-composition-plan.md`/
`bind-system-plan.md` / `event-plan.md`/`onchange-plan.md`/`relate-plan.md`/
`module-lifecycle-plan.md`/`fallback-plan.md`/`lifecycle-hooks-plan.md` /
`tween-plan.md`/`debounce-throttle-plan.md` / `typing-limits.md`/
`quad-types-plan.md`/`project-setup-plan.md`와 **실제 커밋된 M1 코드**, 그리고
`slot-plan.md`의 공개 CRUD·`:Single`·래핑·`dispose` 계층. 여기에 문서 경계를
가로지르는 통합 시나리오(실제 앱 한 화면 / 중첩 멀티루트 / 파괴 순서 / 에러
경로)를 따로 돌렸다.

**1·2차와 다른 점 — 이번엔 추론으로 끝내지 않고 실제로 돌렸다.** 로컬
`luau` 0.734 / `luau-analyze`로 (a) `table.insert`의 범위 밖 동작, (b) 테이블
순회 중 키 추가의 실제 결과, (c) `Tween<T>:Mapped`의 타입 누수, (d)
`quad.Dispatch` 접근의 타입 에러를 **직접 재현**했다. 그 결과 **기존
`H-2`의 트레이스가 틀렸다는 것도 드러났다**(아래 바로 다음 절).

**여기서도 `base/`는 한 줄도 안 고쳤다.**

## ⚠️ 먼저 — `H-2`의 크래시 주장이 틀렸다 (실측 정정)

`H-2`는 *"`table.insert(self._elements, 0, S)` → Luau는 `pos`가 `1..#t+1`
밖이면 **`position out of bounds`를 던진다** → 그 자리에서 터진다"*고 적었다.
**Luau에서 안 터진다.** 로컬 `luau` 0.734로 확인(모든 fflag를 켠 상태도 동일):

| 호출 | 결과 |
|---|---|
| `table.insert({}, 0, "x")` | 에러 없음 → `t[0] = "x"`, `#t == 0` |
| `table.insert({"a","b"}, 0, "x")` | 에러 없음 → `t[0] = "x"`, `t[1]/t[2]` 그대로, `#t == 2` |
| `table.insert({"a","b"}, 5, "x")` | 에러 없음 → `t[5] = "x"`, `#t == 2` |
| `table.insert({"a","b"}, -1, "x")` | 에러 없음 |

**그래서 실제 결과는 크래시가 아니라 "조용한 영구 고아"다** — `H-2`가 원래
*"실제 동작은 더 나쁘다"*고 쓴 것보다도 한 단계 더 나쁘다:

1. `rawAdd`가 `claimOwner(S, self)`를 **먼저** 통과시킨다 → `elementOwner`에
   기록되어 `S`는 이제 **영원히 다른 곳에 마운트할 수 없다**(다시 넣으려 하면
   "이미 마운트돼 있음" error).
2. `table.insert(self._elements, 0, S)` → `_elements[0] = S`, `#_elements`는
   **안 변한다**.
3. `materializeSlotTree`/`mountSlotTree`/`destroySlotTree`/`unmountSlotTree`가
   전부 `ipairs(slot._elements)`로 도는데, `ipairs`는 인덱스 `1`부터 시작한다 →
   **`_elements[0]`은 어떤 walk도 닿지 않는다.** 실체화도, 마운트도, 파괴도
   영원히 안 된다.
4. `S`가 이미 자식 Instance를 갖고 있다면 그 Instance들엔 gcconn이 걸려 있어
   (`base/lifecycle-pattern.md`) **아무도 참조 안 해도 GC되지 않는다** —
   서브트리 통째로 영구 누수.
5. `newKeyIndex[key] = 0`으로 기록되므로 다음 사이클엔 `rawMove(self, 0, 1)`
   같은 호출로 이어진다(그 함수는 정의 자체가 없다 — `H-29`).

`H-2`의 **결론(두 좌표계를 한 변수에 겹쳤다 / 마운트 전 Slot의 `.Length`는
항상 0이다)은 그대로 유효하다.** 틀린 건 "터진다"는 마지막 한 걸음뿐이고,
고칠 방향(`pos`를 리프 카운터와 슬롯 카운터로 분리)도 안 바뀐다. 다만
**"터지니까 금방 발견된다"는 안심이 사라졌다** — 이건 테스트를 통과하고
프로덕션에서 조용히 메모리를 먹는 종류의 결함이다.

---

| 번호 | 심각도 | 한 줄 | 주 대상 |
|---|---|---|---|
| `H-21` | 🔴 | `unwrapElement`가 Instance 요소에서 즉시 크래시 — `:List` 두 번째 사이클에 죽음 | `base/slot-plan.md` |
| `H-22` | 🔴 | 기본 identity `updateFn`이 `KeyGone`을 그대로 반환해 항상 error | `base/slot-plan.md` |
| `H-23` | 🔴 | 전파 도중 새 구독자가 붙으면 **구독자 하나가 누락되고 다른 하나가 두 번 발화**(실측) | `base/source-state-plan.md` |
| `H-24` | 🔴 | `Tween<T>:Mapped`가 재귀 제네릭 타입 누수 — `typing-limits.md`가 이걸 모름(실측) | `base/tween-plan.md`, `base/typing-limits.md` |
| `H-25` | 🔴 | `New(): Quad`가 닫힌 5-필드 타입이라 M2가 붙일 `quad.Dispatch`가 타입에러(실측) | `base/quad-types-plan.md`, `base/module-lifecycle-plan.md` |
| `H-26` | 🟡 | 부분 생성 후 예외가 나면 이미 만든 Instance가 **영구히 회수 안 됨** + 그걸 커버한다던 서술이 모순 | `base/fallback-plan.md`, `base/dispatch-core-plan.md` |
| `H-27` | 🟡 | `OnChangeHandler`에 `v == nil` 얼리리턴이 없음 — `None`으로 끄면 폭탄 Connection이 심김 | `base/onchange-plan.md` |
| `H-28` | 🟡 | `dispose`의 소유권 가드가 Slot 분기에만 있음 — Instance는 그냥 파괴됨 | `base/slot-plan.md` |
| `H-29` | 🟡 | `rawMove`/`rawSwap`/`rawExtract`/`rawSplice`/`rawClear`가 **정의 자체가 없음** | `base/slot-plan.md` |
| `H-30` | 🟡 | `Splice`의 "반쪽 상태 방지" 약속을 지키는 코드 경로가 없음 | `base/slot-plan.md` |
| `H-31` | 🟡 | duplicate key 가드가 **이미 절반 뮤테이트한 뒤**에 터짐 | `base/slot-plan.md` |
| `H-32` | 🟡 | `Debounce{Trailing=false}` + `MaxTime`에서 `pending`이 새어 `Flush`가 영구 no-op | `base/debounce-throttle-plan.md` |
| `H-33` | 🟡 | debounce 7절 의사코드가 확정된 `state:Gate(setup)` API로는 성립 불가 | `base/debounce-throttle-plan.md`, `base/gate-plan.md` |
| `H-34` | 🟢 | `native*` 조합 폴백이 `Move`/`Swap`을 만든 이유를 그대로 되돌림 | `base/slot-plan.md` |
| `H-35` | 🟢 | `ProcessedModifierHandler`가 의사코드도 없고 색인 두 곳에서 빠짐 | `base/modifier-plan.md` |
| `H-36` | 🟢 | `store-plan.md`가 미해결 항목(상류 strong 여부)을 확정처럼 근거로 인용 | `base/store-plan.md` |
| `H-37` | 🟢 | `Slot:List` 의사코드에 `_crudUsed` 역방향 가드가 빠짐 | `base/slot-plan.md` |
| `H-38` | 🟢 | `:List` reconcile의 예외 원자성 계약이 어디에도 없음 | `base/slot-plan.md` |

---

## 🔴 `H-21` — `unwrapElement`가 Instance 요소에서 즉시 크래시한다

**어디**: `base/slot-plan.md`의 "래핑/언래핑은 Slot 전체에 걸린 연산이다" 절.

**확정된 의사코드**:
```lua
local function unwrapElement(el)
    if el == nil then return nil end
    return el._wrapped or el   -- 래퍼면 원래 값, 아니면 자기 자신
end
```

**무엇이 어긋나나**: `el`은 **물리 요소**다 — 같은 절이 *"`_elements`에는 항상
물리 요소(래퍼일 수 있음)가 들어간다"*고 못박았고, quad-roblox에서 그건 사실상
**Roblox `Instance`**다(`base/slot-plan.md`의 "요소 타입 제약" 절: *"quad-roblox엔
사실상 `T = Instance` 하나뿐"*). **Roblox Instance는 없는 멤버를 인덱싱하면
`nil`을 주는 게 아니라 에러를 던진다** — `_wrapped is not a valid member of
Frame`. 즉 `el._wrapped` 한 줄이 **가장 흔한 요소 타입에서 항상 죽는다.**

**트레이스**:
```lua
local items = Source({ {id=1}, {id=2} })
slot:List(items, function(item, index, offset, prev, ud)
    if prev then return prev end
    return Frame { Name = "row"..item.id }
end, function(item) return item.id end)
```
1. 첫 사이클: `mounted[1]`, `mounted[2]`가 아직 없으므로 `unwrapElement(nil)` →
   얼리리턴 `nil`. 정상 통과, 두 Frame이 마운트된다.
2. `items:Set({ {id=1}, {id=2} })` — 아주 평범한 갱신.
3. reconcile 첫 아이템: `local prev = unwrapElement(mounted[1] or ...)` →
   `mounted[1]`은 **Frame Instance** → `Frame._wrapped` → **error**.

`:List`가 raw Instance를 다루는 **모든** 두 번째 사이클이 여기서 죽는다.
같은 이유로 `settle`의 `result == unwrapElement(prev)` 비교, 소멸 루프의
`prev` 계산, 그리고 공개 `Get`/`IndexOf`/`Extract`/`ExtractAll`/`Splice`의
반환 경로가 전부 같은 줄에서 죽는다.

**반대 증거 확인**: 코퍼스 전체에서 `_wrapped`를 grep했다 — 정의 두 줄
(`slot-plan.md` 2616/2622)과 5라운드 followup의 요약, 그리고 세션 원문뿐이다.
가드가 붙은 변형은 **어디에도 없다**. `isSlot`은 `Brand`의 weak-key 집합
조회라(`base/brand-plan.md`) Instance/userdata에 대해 안전하다.

**참고 — base의 일반성 관점에서도 틀렸다**: `Slot<T>`의 `T`는 base 레벨에서
"뭐든 될 수 있는" 제네릭이라고 같은 문서의 `Splice` 항목이 명시적으로
논증한다(*"다른 백엔드면 테이블일 수도, userdata일 수도"*). `T`가 number/boolean이면
Luau에서도 `attempt to index number`로 죽는다.

**갈래**: 단순 정정에 가깝지만 어느 쪽인지는 정해야 한다 —
1. **`isSlot` 가드**: `if isSlot(el) then return el._wrapped or el end return el`
   — 래퍼는 항상 Slot이므로 정확하고 O(1)(브랜드 조회) 유지.
2. **필드 대신 weak side table**: `wrappedOf[sub] = v` — `T`가 우연히
   `_wrapped` 필드를 가진 테이블인 백엔드까지 커버되지만 조회 한 단계가 는다.

---

## 🔴 `H-22` — 기본 identity `updateFn`이 `KeyGone`을 그대로 반환해 항상 error를 낸다

**어디**: `base/slot-plan.md`의 `:Single` 절(`identityUpdateFn`)과 "키가
데이터에서 사라질 때 처분을 묻는다" 절.

**무엇이 어긋나나**: 확정된 기본 `updateFn`은
```lua
local function identityUpdateFn(item) return item end
```
이고, 소멸 루프는 `updateFn(KeyGone, 0, offset, prev, ud)`를 부른 뒤
**`nil`/`None`/`Detach`가 아닌 반환은 전부 `error`**로 못박았다(5라운드 `DE-9`).
identity는 받은 `KeyGone`을 **그대로 돌려주므로 그 error에 100% 걸린다.**

**트레이스**:
```lua
local s = Source(myFrame)
slot:Add(s)          -- 확정 sugar: wrapElement → sub:Single(s, nil, { Owned = false })
...
s:Set(nil)           -- State<T?>가 nil이 되는, 문서가 명시적으로 지원한다는 경우
```
1. `:Single`의 `data = state:Compute(...)`가 `{}`(빈 배열)을 낸다.
2. `_listObserver` → `reconcile({})` → 메인 루프가 0회 돈다.
3. 소멸 루프: 직전 사이클의 `keyIndex`에 고정 키 `true`가 있다 →
   `identityUpdateFn(KeyGone)` → **`KeyGone` 반환**.
4. `if result == None then result = nil end` — `KeyGone`은 `None`이 아니다.
   `local detach = (result == Detach)` — `Detach`도 아니다.
5. `if result ~= nil then error("Slot:List — KeyGone에는 …") end` → **터진다.**

**문서 내부 모순이기도 하다**: 같은 문서의 "래핑/언래핑" 절이
*"`State<T?>`(nilable)도 특별 취급 없이 그냥 됨 — `:Single`이 이미
`if v:Get() == nil then {} else {v:Get()}`로 nil을 '빈 리스트'로 흡수하므로"*
라고 **명시적으로 보장**하고 있는데, 실제로는 그 흡수가 곧바로 소멸 루프를
깨운다.

**영향 범위**: `Slot:Add(state)` sugar 전부, `Slot():Single(state)`의 updateFn
생략 전부, 그리고 quad **내부**의 `wrapElement`(=`:List`가 State를 반환받는
모든 자리). 즉 반응형 raw 요소 기능 전체다.

**반대 증거 확인**: `KeyGone`/`identityUpdateFn`을 코퍼스 전체에서 grep했다 —
identity를 예외 처리하는 서술도, `:Single`이 소멸 루프를 우회한다는 서술도
없다. `:Single`은 `keyFn = function() return true end`로 **키가 하나뿐**이라
"데이터가 비면 그 키가 사라진다"가 정확히 매 nil-전이마다 일어난다.

**갈래**:
1. **`identityUpdateFn`이 `KeyGone`을 흡수**: `if item == KeyGone then return nil end`
   — 기본 동작이 "사라지면 파괴"가 되어 `Owned` 표와도 맞는다(`Owned = false`면
   `releaseElement`가 언마운트만 하므로 사용자 값은 안 죽는다).
2. **`:Single` 층에서 흡수**: `:Single`이 감싸는 래퍼 `updateFn`이 `KeyGone`을
   가로챈다 — `:Single`은 애초에 키가 하나뿐이라 "키 소멸"에 사용자 판단을
   물을 이유가 없다는 논거.
3. **소멸 루프가 `item == KeyGone`을 반환한 경우만 nil로 강등** — 가장 관대하지만
   `DE-9`의 fail-fast 톤과 어긋난다.

---

## 🔴 `H-23` — 전파 도중 새 구독자가 붙으면 구독자 하나가 누락되고 다른 하나가 두 번 발화한다 (실측)

**어디**: `base/source-state-plan.md`의 "`state:Observer(fn)` — 값을 안
실어주는 구독" 절(*"외부에 weak table(`{[observer] = true}`, `__mode = "k"`)로
인덱싱"*)과 "동적 경로 가드 — `k` 무관 매치" 절(*"이 게이팅이 일어나는 자리는
State의 전파 루프다 — State는 구독자를 weak로 담고, 발화 시 각 구독자마다
`canExecute(observer)`를 확인해 거짓이면 그 구독자만 건너뜀"*).

**무엇이 어긋나나**: 전파 루프가 구독자 weak table을 순회하는데, **그 순회
도중 같은 테이블에 새 키가 추가되는 정상 경로가 있다.** Lua/Luau에서 순회 중
**기존 키의 값 변경은 안전하지만 새 키 추가는 미정의**다. 코퍼스 어디에도
"순회 전에 스냅샷을 뜬다"는 서술이 없다.

**실측(로컬 `luau` 0.734)** — 구독자 8개짜리 weak 집합을 순회하면서 첫 콜백에서
새 구독자 1개를 등록:

```
run 1: obs8 fired=2                (obs8이 두 번)
run 2: obs4 fired=2
run 3: obs1 fired=2, obs2 fired=0  (obs1은 두 번, obs2는 아예 안 불림)
```
`pairs()`로 명시해도 동일했고, **실행마다 결과가 달랐다**(어떤 실행은 깨끗했다).
크래시는 안 났다 — 즉 *"터져서 금방 잡히는"* 종류가 아니라 **간헐적으로 한
Observer가 통째로 누락되는** 종류다.

**quad에서 실제로 어떻게 닿는가** (가상의 오용이 아니라 문서가 권장하는 조합):
```lua
slot:List(store.items, function(item, index, offset, prev, ud)
    return Row { Text = store.items:Compute(function(s) return #s:Get() end) }
end)
```
1. `store.items:Set(...)` → 전파 루프가 구독자 집합을 순회 시작.
2. 그중 하나가 `:List`의 `_listObserver` → `reconcile` → `updateFn` →
   `Row{...}` 생성 → `Dispatch.drive` → `store.items:Compute(...)`가
   **같은 `store.items`의 구독자 집합에 새 키를 삽입**.
3. 그 순간 순회 중인 테이블이 리해시되어 위 실측 그대로 누락/이중 발화가 난다.

**반대 증거 확인**: `base/*.md` 전체에서 스냅샷/복사/`table.clone`으로 순회를
방어한다는 서술을 찾지 못했다. `base/dispatch-core-plan.md`의 Handler 작성
체크리스트는 `chains` 배열과 핸들러 재진입만 다루고 State 구독자 테이블
순회는 다루지 않는다. 반대로 **재진입 자체는 이미 정상 경로로 인정**돼
있다 — `Dispatch.process`의 (A)/(B) 분기가 "`h.process`가 내부에서 재귀하는
것이 정상 경로"라고 전제하므로, 발화 중 새 구독이 생기는 것은 예외가 아니라
기본이다.

**갈래**:
1. **순회 전 스냅샷**(배열로 복사한 뒤 그 배열을 돈다) — 이번 파동에 새로
   붙은 구독자는 **다음 파동부터** 참여한다고 계약을 못박는다. 비용은 파동마다
   배열 하나. `canExecute` 게이트가 이미 있으므로 스냅샷 사이에 죽은 구독자는
   그 게이트가 걸러준다.
2. **지연 큐** — 순회 중 등록을 큐에 모았다가 끝나고 병합. (1)보다 무겁고,
   "이번 파동에도 참여해야 하는가"라는 질문에 답해야 한다.
3. **배열 + 인덱스 순회로 자료구조 자체를 바꾸기** — 구독자 집합을 hash가
   아니라 배열로 들면 추가는 항상 끝이라 순회가 안 깨진다. 대신 제거가 O(n)
   이거나 tombstone이 필요하고, weak 의미론을 배열로 유지해야 한다.

**⚠️ 이건 `Epoch` 규칙으로 못 막는다** — 1차 패스가 확인한 dedup 규칙 1/2/3은
"같은 emit이 두 번 도착했을 때 접는" 것이라 **이중 발화는 접히지만 누락은
안 접힌다.** 누락된 Observer는 아무 신호도 못 받는다.

---

## 🔴 `H-24` — `Tween<T>:Mapped`가 재귀 제네릭 타입 누수에 걸리는데 `typing-limits.md`가 이걸 모른다 (실측)

**어디**: `base/tween-plan.md`의 "`Tween<T>:Mapped(fn)` — 값만 갈아끼운 새
`Tween`을 반환" 절 vs `base/typing-limits.md`의 "1. ⭐ 재귀 제네릭이 다른
타입 인자로 자기를 반환하면 타입 안전성이 조용히 사라짐" 절.

**무엇이 어긋나나**: 확정된 시그니처
`tween:Mapped(fn: (T) -> U): Tween<U>`는 `typing-limits.md` 1번이 *"이것만"*
문제라고 못박은 모양(`Foo<T>` 안에서 `-> Foo<U>`)과 **글자 그대로 같다.**
그런데 그 문서의 "영향 범위" 절에는 `Compute`/`With`/`Apply`/`Effect`/`Observer`만
있고 **`Tween`/`Mapped`는 한 번도 언급되지 않는다**(전수 grep 0건). `tween-plan.md`
쪽도 이 한계를 모른다(같은 grep 0건).

**실측**:
```lua
--!strict
export type Tween<T> = { Value: T, Mapped: <U>(self: Tween<T>, fn: (T) -> U) -> Tween<U> }
local t = (nil :: any) :: Tween<number>
local mapped = t:Mapped(function(x: number) return tostring(x) end)
local wrong: number = mapped.Value   -- Tween<string>.Value는 string → 에러여야 정상
```
`luau-analyze` → **진단 0건**(조용히 통과). 같은 검사를 `typing-limits.md` 1번③
(`typeof(named function)` 선언)으로 바꾸면 →
`TypeError: Expected this to be 'number', but got 'string'`으로 **정상적으로
잡힌다.** 즉 **기존 완화책이 그대로 통하는데 아무도 적용을 지시하지 않았다.**

**반대 증거 확인**: `typing-limits.md` §6(`type function`을 거친 값)과 다른
문제인지 확인했다 — `Mapped`는 `type function`을 안 거치는 순수 제네릭 메소드라
무관하다. `quad-types-plan.md`의 `AddPlugin` 실측 사례와도 별개다.

**갈래**: 단순 정정 — `typing-limits.md`의 "영향 범위" 절에 `Tween<T>:Mapped`
행을 추가하고, `tween-plan.md`의 `Mapped` 절에 "인라인 제네릭 메소드가 아니라
`typeof(named function)`로 선언할 것" 각주를 단다. 새 설계 결정 불필요.

**⭐ 함께 볼 것**: 같은 종류의 누수가 다른 최근 확정 표면에도 있는지 한 번
훑는 게 맞다. 이번에 `state:Gate(setup)`/`EpochMap`/`Effect`는 확인했고
**전부 이 패턴이 아니라 무관**했다(그 셋은 제네릭 self를 다른 타입 인자로
반환하지 않는다).

---

## 🔴 `H-25` — `New(): Quad`가 닫힌 타입이라, M2가 `Dispatch`를 붙이는 순간 확정된 `quad.Dispatch` 접근이 타입에러가 된다 (실측)

**어디**: `base/quad-types-plan.md`의 "`Quad` 타입 — 확정된 표면" 절(실제 반영
파일 `quad-types/src/init.luau`) vs `base/module-lifecycle-plan.md`의
"New()의 내부 구성 — InitXxx 팩토리 체이닝" 절 vs `base/architecture.md`
확정된 결정 13번.

**무엇이 어긋나나**: 실제 커밋된 `quad-types/src/init.luau`의 `Quad`는
`Version`/`debug`/`New`/`RunInit`/`AddPlugin` **5개 필드짜리 닫힌 레코드**이고,
`quad-base/src/init.luau`의 `New(): Quad`가 그 별칭을 그대로 반환 타입으로
쓴다. `RunInit`은 `(self: Quad, initFn: (Quad) -> any) -> ()`로 **반환값이
없어 타입을 넓히지 못한다** — `AddPlugin<Self, P>`만이 타입을 넓히는 경로인데
`quad-types-plan.md` 자신이 그건 **외부 플러그인**용이라고 선을 긋는다.
그런데 `architecture.md` 13번은 *"`require(quad)`가 돌려준 걸 바로
`Quad.Dispatch`처럼 씀"*을 **표준 사용법으로 확정**해뒀다.

**실측** — 실제 `Quad` 정의와 `InitDebug`와 완전히 같은 모양의 `InitDispatch`로
재현:
```lua
local quad = New()
quad.Dispatch.addHandler(function() end)
```
`luau-analyze` → `TypeError: Key 'Dispatch' not found in table 'Quad'`.

즉 M2가 `Dispatch.luau`를 만들고 `module:RunInit(InitDispatch)` 패턴(문서가
이미 예시로 보여준 그 패턴)으로 붙이면, **런타임엔 붙지만 타입엔 영원히 안
보인다.** `ROADMAP.md` M2 체크리스트의 *"`Dispatch.addHandler(handler)` …
quad-roblox가 팩토리 뮤테이션 시점에 호출"*(M5)도 같은 벽에 부딪힌다 —
quad-roblox는 `quad-types`의 좁은 `Quad`만 본다.

**반대 증거 확인**: `Quad & X` 형태의 타입 확장 언급은 `AddPlugin` 항목 하나뿐이고,
같은 문서가 *"모든 백엔드/플러그인 패키지가 이 패턴을 따를 필요는 없다"*고
범위를 좁힌다. `ROADMAP.md` M2 체크리스트에 "`quad-types`의 `Quad`를 갱신"
류 항목은 없다 — **아무도 이 필요성을 항목화해두지 않았다.**

**갈래(판단 필요)**:
1. **quad-base 내부만 넓은 로컬 교차 타입** —
   `New(): Quad & { Dispatch: Dispatch, ... }`로 서브시스템마다 누적.
   `module-lifecycle-plan.md`의 원래 그림 그대로. 단 quad-roblox도 결국
   `Dispatch.addHandler`를 부르므로 그 경로엔 별도 노출이 필요하다.
2. **`quad-types`의 `Quad`를 마일스톤마다 갱신** — M2가 `Dispatch` 필드(와
   그 타입 재수출)를 추가하는 걸 체크리스트 항목으로 명시.
   "가벼운 타입 계약"이라는 존재 이유와 상충하는지부터 봐야 한다(타입만
   재수출하면 런타임 무게는 안 는다는 게 1차 판단이지만 아직 미검증).
3. **내부 접근을 전부 `(quad :: any).Dispatch`로 캐스트** — 가장 싸지만
   `typing-limits.md`가 시종 강조하는 "명시 바인딩으로 다운스트림 안전성
   확보"와 정면으로 배치되고, quad-base 자기 코드가 `--!strict`의 이득을 잃는다.

**⚠️ 이건 M2 착수 전에 정해야 한다** — 첫 서브시스템을 붙이는 방식 자체가
여기서 갈린다.

---

## 🟡 `H-26` — 부분 생성 후 예외가 나면 이미 만든 Instance가 영구히 회수되지 않는다

**어디**: `base/fallback-plan.md`(`Fallback`/`Traceback`의 격리 범위)와
`base/lifecycle-pattern.md`의 "(0) gcconn/gchold는" 절.
**두 에이전트가 서로 독립적으로 같은 결론에 도달한 항목이다.**

**무엇이 어긋나나**: quad는 *"자기가 만든 Instance마다 생성 즉시 gcconn을
걸고 그 클로저가 `inst`를 캡처"*하므로 *"참조를 놓는 것만으로는 회수되지 않고
반드시 `Destroy`로 회수된다"*(같은 절). 이 모델은 **"만든 Instance는 언젠가
반드시 `Destroy`된다"**를 전제한다. 그런데 컴포넌트가 자기 리터럴을 만드는
도중 예외를 던지면, 그때까지 완성된 형제/자손은 **트리에 붙지도, `Destroy`되지도
않은 채** 예외에 실려 스코프를 빠져나간다. `Fallback`은 `pcall(base, ...)`
하나라 그 존재를 알 방법이 없다.

**트레이스**:
```lua
local function Broken(props) error("bug!") end
local function Parent(props)
    return Frame {
        Frame { Text = "child A" },   -- (1) 완주 — gcconn/gchold 확정
        Broken {},                    -- (2) error
        Frame { Text = "child C" },   -- (3) 도달 안 함
    }
end
local SafeParent = Fallback(Parent, function(err) return Frame { Text = tostring(err) } end)
```
1. Lua 테이블 생성자는 원소를 좌→우로 **완전히 평가**하므로 `child A`가 먼저
   실제 Instance로 완성되고 gcconn이 걸린다.
2. `Broken{}`이 던진다 — 바깥 `Frame(...)` 호출은 인자 테이블조차 완성 못 해
   **호출되지 않는다.**
3. `Fallback`이 `pcall` 경계에서 잡아 대체 UI를 만든다 → 겉보기엔 격리 성공.
4. `child A`는 (a) 어떤 지역 변수에도 안 남고, (b) `Parent`가 끝내 세팅된 적
   없고, (c) `Fallback`이 존재를 모른다. 그를 살려두는 건 자기 gcconn↔gchold
   순환뿐이고 그걸 끊는 유일한 수단(`Destroy`)을 부를 주체가 없다 →
   **참조 0개인데 세션 끝까지 안 죽는다.**
5. 실패 지점 앞에 중첩 서브트리가 있으면 **그 전체**가 대상이다.

**⭐ 그리고 이건 다른 문서의 안전망 서술과 정면으로 부딪힌다.**
`base/dispatch-core-plan.md`가 `AttributeGroupHandler`의 부분 실패를 두고
*"`nameClaims`/`tagNameMap`이 `inst`에 대해 weak라 그 인스턴스가 GC되면 잔여
부기도 같이 사라지는 것으로 충분히 커버됨"*이라고 적어뒀는데, **그 전제(실패한
`inst`가 결국 GC된다)가 gcconn 불멸성과 양립하지 않는다.** 아무도 `Destroy`를
안 부르면 `inst`가 안 죽고, 따라서 잔여 부기도 안 사라진다. 즉 이 문제는
`Fallback` 전용이 아니라 **"부분 실패 후 아무도 `Destroy`를 안 부르는 모든
경로"의 일반적 위험**이고, `Fallback`/`Traceback`은 그 경로를 **계속 살려두는
것을 존재 이유로 삼는** 대표 사용처다.

**반대 증거 확인**: 두 에이전트가 각각 "고아/orphan/leak/반쪽/Instance.new"
계열로 전수 grep했고, 회수 경로를 언급하는 문장을 못 찾았다. 인접 사례로
`materializeSlotTree`의 예외 시 Blocker가 켜진 채 남는 갭이 **사용자 판단으로
이미 인정**돼 있지만(*"마운트 도중 예외는 quad가 복구를 보장하지 않는 상태"*),
그건 **마운트 경로에 한정**된 국소적 결과(`Length` 영구 stale)이고, 이쪽은
`Fallback`이라는 **사용자에게 노출된 복구 API**가 "예외 후에도 앱이 계속 정상
동작한다"를 약속하는 자리라 층위가 다르다.

**갈래(판단 필요)**:
1. **`Fallback`/`Traceback`이 실패 시 이번 호출에서 생성된 Instance를
   정리** — `New`/`Dispatch.drive`가 "이번 construction에서 만든 것" 목록을
   쌓고 `pcall` 실패 시 역순 `Destroy`. 정상 경로에도 부기 비용이 붙는다.
2. **gcconn 자기순환 자체를 재고**(한 번도 Parent 안 된 채 참조가 끊기면 GC
   가능하게) — `lifecycle-pattern.md` (0)의 핵심 트레이드오프를 건드리므로
   재설계 규모가 크다. 두 에이전트 모두 비권장.
3. **UB로 명문화** — `Fallback`/`Traceback` 문서에 "실패 이전에 생성된 부분
   트리는 회수되지 않는다"를 캐비엇으로 못박고, 컴포넌트 저작자에게 "생성
   전에 검증부터"를 권고. 비용 0이지만 장수 세션에서 실제 누수로 누적된다.
   **이 갈래를 고르더라도 `base/dispatch-core-plan.md`에서 잔여 부기가
   인스턴스 GC로 정리된다고 적은 문장은 같이 고쳐야 한다** — 그건 캐비엇이
   아니라 틀린 안전망 주장이다.

---

## 🟡 `H-27` — `OnChangeHandler`에 `v == nil` 얼리리턴이 없다

**어디**: `base/onchange-plan.md`의 "확정" 절 안 `process` 항목 vs
`base/event-plan.md`의 "이벤트도 store-bind 가능" 절.

**무엇이 어긋나나**: `onchange-plan.md`는 `process`를
*"`inst:GetPropertyChangedSignal(name):Connect(function() v(inst[name]) end)` 후
그 Connection을 `:Disconnect()`하는 클로저를 반환. 일반 `Handlers/Event.luau`와
같은 결"*로 확정했다. 그런데 `event-plan.md`가 확정한 그 "같은 결"의 핵심은
**`(k=이벤트키, v=nil)`을 받으면 기존 Connection 해제만 하고 새로 Connect하지
않는다**는 것인데, `OnChange` 쪽 의사코드엔 그 얼리리턴이 없다.

**트레이스**: `Frame { [OnChange "Position"] = someState }`, `someState`가
`fn1`을 들고 있다가 `None`으로 바뀌는 경우:
1. StoreBind가 언랩 → index 2에서 `OnChangeHandler`가 `fn1`로 Connect. 정상.
2. `someState:Set(None)` → 재-dispatch → index 2에서 `NoneHandler`가 매치 →
   (B) 분기 → `retractFrom`이 옛 Connection을 정상 Disconnect →
   `NoneHandler.process`가 `Dispatch.process(inst, k, nil, 3)`로 재귀.
3. index 3에서 `OnChangeHandler`가 다시 매치된다 — 매치가 **키 기반**이라
   `v == nil`도 잡고, `NilHandler`는 `type(k) == "number"` 전용이라 여기 안 걸린다.
4. 의사코드 그대로면 `Connect(function() nil(inst.Position) end)`가 **실제로
   실행**된다. 이 시점엔 아무 일도 안 일어난다.
5. 나중에 `inst.Position`이 실제로 바뀌면(Tween이든 다른 코드든) 그 콜백이
   발화 → **`attempt to call a nil value`**.

즉 "콜백을 끈다"는 동작이 실제로는 **"나중에 터질 Connection을 새로 심는"**
동작이 된다.

**반대 증거 확인**: `OnChangeHandler`가 언급되는 모든 파일을 확인했다
(`onchange-plan.md`/`attribute-plan.md`/`lifecycle-hooks-plan.md`/
`dispatch-core-plan.md`/`architecture.md`) — 별도 의사코드도 nil 가드 언급도
없다. `dispatch-core-plan.md`는 같은 종류의 방어를 `PropertyHandler`에는
명시적으로 요구하고 있어(*"`v == nil`이면 셋을 건너뛰는 방어"*), `OnChange`만
빠진 모양이다.

**갈래**: 단순 정정 — `process`에 `if v == nil then return function() end end`
(또는 Connect를 건너뛰고 no-op retractor 반환)을 명시. 문서가 이미 스스로
"event-plan.md와 같은 결"이라 결론 내린 것을 의사코드에 반영만 하면 된다.

---

## 🟡 `H-28` — `dispose`의 소유권 가드가 Slot 분기에만 있다

**어디**: `base/slot-plan.md`의 "quad가 관리 중인 값을 안전하게 지우는 유일한
경로" 절.

**확정된 의사코드**:
```lua
function dispose(value)
    if isSlot(value) then
        -- 위 elementOwner 기반 판정 재사용 — 요구 중이면 error, 아니면 재귀 파괴
        ...
    else
        nativeDispose(value)  -- 아래 주입 op
    end
end
```

**무엇이 어긋나나**: 같은 절이 산문으로는 *"대상이 아직 어느 트리에 의해
살아있길 요구되고 있으면 파괴를 거부하고 즉시 `error`"*라고 대상 구분 없이
선언하고, 그게 성립하는 근거로 *"`elementOwner`가 element → owner를 들고
있음"*을 든다. `elementOwner`는 **Slot이든 plain 마운트 가능 값이든 전부**를
커버한다(같은 문서의 `elementOwner` 정의 주석이 명시). 그런데 의사코드는
가드를 `isSlot` 분기 안에만 뒀고, **가장 흔한 대상인 "Slot에 마운트된
Instance"**는 `else`로 새어 그대로 파괴된다 — `dispose`가 막으려던 바로 그
UB(`_elements`/`lengthList`/`sourceList`/`elementOwner`가 어긋남)가 그대로
일어난다.

**트레이스**: `local f = Frame{}; slot:Add(f); dispose(f)` → `isSlot(f)`가
거짓 → `nativeDispose(f)` → `f:Destroy()`. `slot._elements`엔 죽은 Instance가
남고 `elementOwner`엔 클레임이 남는다. 이후 그 자리의 `recompute`/`rawRemove`가
죽은 대상을 만난다. 정상 경로였다면 *"아직 요구 중이므로 error"*가 나야 했다.

**갈래**: 단순 정정 — 가드를 분기 **밖**으로 끌어올린다(`elementOwner` 조회는
값 종류와 무관하므로 그대로 재사용 가능).

---

## 🟡 `H-29` — `rawMove`/`rawSwap`/`rawExtract`/`rawSplice`/`rawClear`가 정의 자체가 없다

**어디**: `base/slot-plan.md` 전체. 의사코드가 존재하는 `raw*`는
`rawUnmount`/`rawDetach`/`rawAdd`/`rawReplace`/`rawRemove` **다섯뿐**이다
(전수 grep). 나머지 다섯은 이름만 있다.

**왜 그냥 "미작성"이 아닌가**: `rawMove`는 **reconcile이 직접 부르는 둘 중
하나**다 — 같은 문서가 *"`reconcile`이 직접 호출하는 건 `rawAdd`/`rawMove`와,
처분 헬퍼 …"*라고 못박았고, `settle`의 리오더 분기가 실제로
`rawMove(self, keyIndex[key], pos)`를 부른다. 즉 **`:List`의 핵심 경로에
정의 없는 함수가 있다.** 그리고 그 의무는 자명하지 않다:

1. **어떤 배열이 함께 치환되는가** — `bk`의 배열들은 **position 인덱스**다.
   `lengthList[i]`(그 요소의 기여도)와 `bk.observers[i]`(그 요소의 `Length`
   State를 보는 Observer)는 요소를 따라가야 한다. `sourceList[i]`도 마찬가지다 —
   `materializeSlotTree`가 `Dispatch.setOffsetSource(ownerKey, position, offsetSource)`에
   넘기는 값이 **그 중첩 Slot 자신의 `slot.Offset`**이라 position이 아니라
   요소에 귀속된다. 셋 다 같은 순열로 움직여야 하는데 어디에도 안 적혀 있다.
2. **`bk.N`은 안 변한다** — 자리 수가 그대로이므로. `spliceArraysUp`/`Down`과
   다른 점인데 명시가 없다.
3. **`recompute`를 부르는가** — 순서가 바뀌면 offset이 전부 바뀌므로 불러야
   한다.
4. **⭐ `nativeMove(target, fromOffset, elements, toOffset)`의 `elements`를
   중첩 Slot에서 어떻게 만드는가** — `native*` 계층은 *"빠지는 요소는 반드시
   `elements` 배열로 넘긴다"*(Roblox는 offset으로 역조회를 못 하므로)를 계약으로
   못박았는데, `_elements[index]`가 Slot이면 **평탄화된 리프 목록**이 필요하다.
   코퍼스에 그런 헬퍼가 **없다** — 재귀 리프 walk는 `mountSlotTree` 하나뿐이고
   그건 수집이 아니라 삽입이다. `rawRemove`/`rawUnmount`는 Slot 요소를
   `destroySlotTree`/`unmountSlotTree`로 빠져나가 이 문제를 피했지만, `Move`엔
   그런 우회가 없다.

`rawSwap`도 같은 문제를 두 구간에 대해 갖는다. `rawSplice`는 여기에 더해
`H-30`의 사전 검증까지 져야 한다.

**참고**: 같은 문서에 *"`raw*` 내부 호출 규약은 공개 API와 다를 수 있음(구현
세부, M6에서 확정)"*이라는 옛 문장이 남아 있는데, 5라운드가 **index 기준으로
통일**하며 그 갈래는 이미 닫혔다 — 이 문장은 지금 "정의를 안 적어도 되는
이유"처럼 읽히지만 실제로는 stale이다.

**갈래**: 판단이라기보다 작성이다. 다만 4번(리프 평탄화)은 **새 헬퍼가
필요하다**는 뜻이라 그 자체가 결정이다 — `collectLeaves(slot)` 같은 걸 둘지,
아니면 `Move`/`Swap`이 중첩 Slot 요소에 대해선 다른 경로(`unmount` +
`attach`)를 타게 할지.

---

## 🟡 `H-30` — `Splice`의 "반쪽 상태 방지" 약속을 지키는 코드 경로가 없다

**어디**: `base/slot-plan.md`의 "CRUD API 확정" 절, `Splice`의 에러 조건 항목.

**확정된 문장**: *"`newElements` 각각에 `Add`와 동일한 검증(이미 마운트/타입
제약) 적용, 검증은 실제 mutate 전에 전부 먼저 통과해야 함(일부만 적용된 채
중간에 에러나는 반쪽 상태 방지)"*.

**무엇이 어긋나나**: "이미 마운트됨" 판정을 실제로 하는 코드는 `rawAdd` 안의
`claimOwner` 하나뿐이고, 그건 **요소를 삽입하기 직전에 요소마다** 돈다. 사전
일괄 검증을 하는 자리가 어디에도 없다(그리고 `rawSplice` 자체가 미정의 —
`H-29`).

**트레이스**: `local a, b = Frame{}, Frame{}; other:Add(c)` 상태에서
`slot:Splice(1, 0, a, b, c)`:
1. `a` 삽입 — `claimOwner(a, slot)` 통과, `_elements`/물리 갱신.
2. `b` 삽입 — 통과.
3. `c` — `claimOwner`가 `other`의 클레임을 보고 **error**.
결과: `a`/`b`는 이미 들어가 있고 `c`만 실패한 **반쪽 상태**. 문서가 명시적으로
방지하겠다고 한 바로 그 상태다.

**갈래**: 단순 정정 — `Splice`(와 `Add`/`Replace`/`Extract`의 `newElement`)가
`rawSplice` 호출 **전에** `elementOwner` 조회 + 타입 제약을 전량 선행 검증하도록
의사코드에 명시. `H-31`과 같은 처방이다.

---

## 🟡 `H-31` — duplicate key 가드가 이미 절반 뮤테이트한 뒤에 터진다

**어디**: `base/slot-plan.md`의 `reconcile` 의사코드.

**무엇이 어긋나나**: 중복 키 검사는 메인 루프 **안에서** item마다 돈다:
```lua
for i, item in ipairs(items) do
    local key = keyFn(item, i)
    if seen[key] then error("Slot:List — duplicate key: " .. tostring(key)) end
    ...
    settle(key, result, detach, pos)
```
N번째 item에서 중복이 발견될 때 1..N-1번째의 `settle`(=`rawAdd`/`rawReplace`/
`rawMove`/물리 조작)은 **이미 커밋됐고**, `keyIndex = newKeyIndex` 교체는 루프
**뒤**라 일어나지 않는다.

**트레이스**: `data = [{id=1},{id=2},{id=2}]`(사용자 데이터에 흔한 중복 id):
1. `key=1` → `rawAdd` 커밋.
2. `key=2` → `rawAdd` 커밋.
3. `key=2` 재등장 → error → reconcile 전체가 unwind.
4. 이제 `_elements`엔 두 요소가 들어 있는데 `keyIndex`는 **옛 사이클 것**
   (첫 사이클이면 빈 테이블). 다음에 `data`가 갱신되면 reconcile이 어긋난
   인덱스로 돌고, `H-1`과 합쳐지면 `nil` 인덱싱까지 간다.

**왜 "에러=패닉이니 신경 안 씀"으로 못 넘기나**: 중복 키는 **사용자 데이터에서
가장 흔한 실수 중 하나**라 도달 빈도가 다른 패닉 경로와 다르다. 그리고
`:List`는 앱 수명 내내 반복되는 경로라, 한 번 어긋난 부기가 이후 모든
사이클을 오염시킨다.

**갈래**: 단순 정정 — 키 수집/중복 검사를 **선행 패스**로 분리(`H-30`과
같은 처방). `keyFn`을 한 번 더 도는 O(n) 비용이 붙지만, `:List`는 이미 O(n)
단일 패스라 상수배다.

---

## 🟡 `H-32` — `Debounce{Trailing=false}` + `MaxTime`에서 `pending`이 새어 `Flush`가 영구 no-op이 된다

**어디**: `base/debounce-throttle-plan.md`의 "7. 의사코드" 절.

**무엇이 어긋나나**: 창이 열려 있는 동안 오는 신호는 `trailing`과 **무관하게**
`pending = true`를 세우는데, `pending`을 `false`로 되돌리는 자리는
**전부** `if pending and trailing then` 안에 있다(`onWindowEnd`, `MaxTime`
콜백, `_flush` 셋 다). 그래서 `Trailing = false` 구성에서 한 버스트에 신호가
둘 이상 오면 `pending`이 **영구히 참**으로 남는다. 그런데
`Leading = true, Trailing = false`는 문서가 *"버스트 시작에 한 번만"*이라며
직접 드는 정상 사용례이고, 5-2절의 유효성 검사는 *"둘 다 false"*만 막는다.

**트레이스** — `Debounce{Time=1, Leading=true, Trailing=false, MaxTime=3}`,
신호 `t = 0, 0.3, 0.6`:

| 시각 | 무슨 일 | 상태 |
|---|---|---|
| 0 | idle → `leading` → `passThrough()`, `openWindow()` | `pending=false`, 창 마감 1.0 |
| 0.3 | 창 안 → `pending = true`, reset → 창 재개 | `pending=true`, 마감 1.3, `cap` 무장(마감 3.3) |
| 0.6 | 창 안 → `pending=true`(변화 없음), 창 재개 | 마감 1.6 |
| 1.6 | `onWindowEnd` → `if pending and trailing` → **스킵** | `pending`이 `true`로 **남는다** |
| 3.3 | `cap` 콜백 → `if pending and trailing` → **스킵** | 타이머 하나를 통째로 낭비 |

이후 이 게이트에서는 (a) `MaxTime`이 매번 재무장되며 **영원히 아무 효과가
없고**, (b) `opts.Handle`로 받은 `:Flush()`가 `if pending and trailing`에
막혀 **영구 no-op**이다 — 사용자가 명시적으로 커밋을 요청해도 반응이 없다.
`:Cancel()`만이 `pending = false`를 무조건 하므로 유일한 탈출구다.

**반대 증거 확인**: `MaxTime`이 `Trailing`에 의존한다거나 그 조합을 금지한다는
서술을 `base/debounce-throttle-plan.md`/`base/gate-plan.md`/`base/blocker-plan.md`와
4·5라운드 문항지 전체에서 찾지 못했다.

**갈래**:
1. `else`-분기의 `pending = true`를 `if trailing then pending = true end`로
   좁힌다(가장 단순 — `Trailing=false`면 애초에 그 부기를 안 함).
2. `MaxTime` + `Trailing=false` 조합을 5-2절 수준의 명시적 error로 막는다.
3. `MaxTime`을 `Trailing`과 독립적으로 재정의(예: 강제 재-leading) — 의미론
   변경이라 범위가 크다.

---

## 🟡 `H-33` — debounce 7절 의사코드가 확정된 `state:Gate(setup)` API로는 성립하지 않는다

**어디**: `base/debounce-throttle-plan.md`의 "7. 의사코드" 절 vs
`base/gate-plan.md`.

**무엇이 어긋나나**: 7절은 `local gate = Gate(self)`로 **탑레벨 생성자**를
부르고 반환 객체에 `.onUpstreamSignal`/`._flush`/`._cancel`을 **사후 대입**한다.
확정된 형태는 정반대다 — `gate-plan.md`가 `state:Gate(setup)`
(`setup: (emit) -> (onUpstreamEmit)`)로 못박으면서 *"탑레벨 `Gate(...)`
생성자는 안 만든다"*고 명시했고, 호출자는 `state:Gate(setup)`가 돌려주는
**State 하나**만 받을 뿐 노드 객체에 접근할 수 없다. 실제로 확정된 자매
구현인 `Blocker`는 그 제약을 지켜서, 제어 표면(onunblock 핸들)을
**정책 클로저 안에서 외부 `blocker` 객체에 등록**하는 형태로 우회한다.

즉 7절을 그대로 옮기면 (a) `Gate`라는 호출 가능한 값이 없어 `attempt to call a
nil value`, (b) 이름을 `self:Gate(...)`로 고쳐도 `setup`이 핸들러를 **반환**해야
하는 프로토콜과 안 맞고, (c) `Handle:Set({Flush = gate._flush, ...})`는 노드
참조를 못 받으므로 **표현 자체가 불가능**하다.

**반대 증거 확인**: 7절 머리말에 *"`Gate` 노드의 내부 훅(`onUpstreamSignal`,
`commit`)은 아직 이름도 계약도 확정되지 않은 가칭"*이라는 캐비엇이 **실제로
있다** — 그래서 이걸 🔴가 아니라 🟡로 낮춘다. 다만 그 캐비엇은 "이름/계약이
가칭"이라 말할 뿐, **코드의 골격(탑레벨 생성자 + 필드 대입)이 확정 모델에서
아예 성립 불가능**하다는 건 알려주지 않는다. 반대로 `gate-plan.md` 쪽은
`gate:passThrough()`/`onWindowEnd`를 *"이미 같은 것을 …로 부르고 있다"*며
정착된 이름처럼 인용해, 이 절이 여전히 미해결이라는 신호를 오히려 흐린다.

**갈래**: 단순 정정 — `Blocker`의 실제 패턴대로 `makeGate`의 `__call`을
`self:Gate(policy)`로 바꾸고, `policy(emit)`이 `pending`/`window`/`cap`을
지역으로 들고 `onUpstreamEmit`을 **반환**하며, `Handle`/`instances` 등록도
`policy` 본문에서 `emit`을 캡처한 클로저로 다시 쓴다.
**우선순위 주의**: `Debounce`/`Throttle`은 백로그라 급하지 않다 — 다만 `H-32`를
고칠 때 같은 코드를 손대므로 한 번에 처리하는 게 싸다.

---

## 🟢 `H-34` — `native*` 조합 폴백이 `Move`/`Swap`을 만든 이유를 그대로 되돌린다

**어디**: `base/slot-plan.md`의 "물리 조작은 주입 op다" 절의 조합 폴백 항목 vs
"원시 최소화 원칙 정정" 절.

**무엇이 어긋나나**: 폴백은 *"`nativeMove` = `nativeExtract` + `nativeInsert`"*로
정의되고 *"백엔드는 이득 있는 것만 덮어쓴다"*고 적혀 있다 — 즉 **안 덮어써도
맞다**는 톤이다. 그런데 `Move`/`Swap`이 공개 CRUD에 추가된 근거가 정확히
*"`Extract`+`Add`는 실제 Parent 조작이 두 번(detach+reattach) 일어남 — Roblox에서
`AncestryChanged` 발화, 잠재적 깜빡임, 불필요한 재바인딩 비용"*을 피하려는
것이었다. Roblox 백엔드가 `nativeMove`/`nativeSwap`을 덮어쓰지 않으면
**그 비용이 그대로 돌아온다** — 조합 폴백은 이 경우 "느린 정답"이 아니라
**관측 가능한 동작 차이**(`ChildAdded` 재발화, 레이아웃 리플로우)를 만든다.

**정확히 짚어둘 것 — quad 자신의 배관은 안 깨진다.** quad의 생명주기 관측은
`Destroying` 하나로 통일돼 있고 `AncestryChanged`를 안 쓴다(`base/lifecycle-pattern.md`).
영향은 사용자 코드/렌더 쪽이다. 그래서 🟢다.

**갈래**: 단순 보강 — "Roblox 백엔드는 `nativeMove`/`nativeSwap`을 no-op으로
덮어써야 한다(offset을 무시하는 백엔드에서 순서 이동은 물리 조작이 아니다)"를
그 절에 명시. `nativeInsert`를 흡수하지 않은 이유를 적어둔 것과 같은 결이다.

---

## 🟢 `H-35` — `ProcessedModifierHandler`가 의사코드도 없고 색인 두 곳에서 빠져 있다

**어디**: `base/modifier-plan.md`의 "flatten의 정확한 형태" 절.

**무엇이 어긋나나**: `flatten`이 배열 자리를 `ProcessedModifier` 센티널로
소진하고 *"전담 nop Handler `ProcessedModifierHandler`가 정상 `Dispatch.process`
경로에서 캐치해 `setOffsetSource(None)`/`setLength(0)`을 등록한다"*고 한 줄로
확정했는데:
- **의사코드가 없다.** 같은 문서가 *"`Pre`/`PostRef`와 완전히 같은 방식"*이라며
  지목한 `ProcessedPreRefHandler`/`ProcessedPostRefHandler`는 `base/ref-plan.md`에
  실제 `process` 골격이 있다(그 골격 자체엔 `H-20`이 지적한 시그니처 문제가
  있지만, 최소한 "이렇게 짜라"가 있다).
- **`base/dispatch-core-plan.md`의 Length/Offset 등록 책임 열거에 없다.**
  그 절은 plain 요소 / Slot / store-bind / `NilHandler` /
  `ProcessedPreRefHandler` / `ProcessedPostRefHandler`를 하나씩 짚는데
  `ProcessedModifier`만 빠져 있다(전수 grep 확인).
- **`base/architecture.md`의 `Dispatch/` 파일트리에도 없다** — `Modifier.luau`
  항목은 flatten/체이닝만 적고 자기가 만드는 센티널의 핸들러를 언급하지 않는다.

`Modifier`가 하나라도 든 `Frame{...}` 호출은 **전부** 이 핸들러를 거치므로,
`modifier-plan.md`를 안 읽고 두 색인 문서만 보고 구현하는 사람은 이 핸들러의
존재 자체를 놓친다.

**심각도를 🟢로 두는 이유**: 이건 "그대로 구현하면 깨진다"가 아니라 **스펙
공백**이다 — `modifier-plan.md`를 정확히 읽으면 산문으로 재구성할 수 있다.

**갈래**: 단순 보강 — (1) `modifier-plan.md`에 의사코드 추가, (2)
`dispatch-core-plan.md`의 열거에 항목 추가, (3) `architecture.md` 파일트리에
소속 파일 명시.

---

## 🟢 `H-36` — `store-plan.md`가 미해결 항목을 확정처럼 근거로 인용한다

**어디**: `base/store-plan.md`(*"State/Source 그래프 구독이 전부 weak-keyed
GC-native"*) vs `base/source-state-plan.md`의 "⚠️ 미해결 — 중간 State가
살아남는가(구독 엣지의 방향성)" 절.

**무엇이 어긋나나**: `store-plan.md`는 "그래프 구독이 **전부** weak-keyed"라는
명제를 기정사실로 써서 다른 결론(이중 해제 걱정 불필요)을 내리는데, 그 명제
자체가 `source-state-plan.md`가 **스스로 미확정이라고 선언한 바로 그
항목**(상류 방향이 strong인지 weak인지)이다. 사용자가 지목한 해법 방향
(*"하류로 weak, 상류로 strong"*)으로 확정되면 그래프는 더 이상 "전부 weak"가
아니게 되어 인용된 전제가 깨진다. `.claude/todos.md`도 이 항목을 **M3 착수 전
필요**로 열어두고 있다.

**결론 자체는 안 뒤집힌다** — 그 문단의 결론(이중 해제 불가)은 "Store가 Store를
안 담기로 확정"이라는 별개 이유만으로도 성립한다. 문제는 **근거로 쓰인 명제**뿐이다.

**갈래**: 새 결정이 아니라 **기존 미해결이 닫힐 때 같이 처리할 표기 문제**다 —
그 결론이 "상류 strong"이면 이 문장을 그에 맞게 정정하고, "전부 weak + 별도
앵커"면 그 앵커를 반영한다. **닫을 때 이 문장을 같이 훑을 것**을 남겨둔다.

---

## 🟢 `H-37` — `Slot:List` 의사코드에 `_crudUsed` 역방향 가드가 빠져 있다

**어디**: `base/slot-plan.md`의 "CRUD API 확정" 절(*"`:List`/`:Single`(내부적으로
`:List` 호출)이 설치 시 `assert(not self._crudUsed, ...)`를 추가로 확인"*) vs
같은 문서의 `Slot:List` 의사코드(`assert(not self._listed, ...)` 하나만 있음).

산문이 확정한 대칭 가드가 코드에 안 옮겨졌다. 그 가드가 막으려던 것
(`Slot():Add(x); slot:List(...)`가 조용히 통과해 reconcile이 `x`의 존재를 모른
채 도는 것)은 지금도 유효한 위험이다.

**갈래**: 단순 정정.

---

## 🟢 `H-38` — `:List` reconcile의 예외 원자성 계약이 어디에도 없다

**어디**: `base/slot-plan.md`의 `reconcile` 의사코드.

`updateFn`이 사이클 중간에 던지면 앞선 `settle`들이 이미 물리/부기를 커밋한
채 unwind되고 `keyIndex = newKeyIndex`는 실행되지 않는다 — `H-31`(duplicate
key)과 **정확히 같은 실패 모양**인데, 이쪽은 원인이 사용자 `updateFn`이라
훨씬 흔하다. 그런데 "reconcile이 예외에 대해 원자적인가 / 부분 커밋을
허용하는가"를 명시한 문장이 코퍼스에 없다.

`materializeSlotTree`의 예외 갭은 이미 인정돼 있지만 그건 **마운트 경로에
한정**된 서술이고, `:List`의 steady-state reconcile은 언급하지 않는다.

**갈래**:
1. **`H-1`/`H-31` 해법에 흡수** — `H-1`을 "라이브 인덱스 맵"으로 고치면 부분
   커밋이 그 자체로 일관되어 문제가 거의 사라진다.
2. **계약만 명문화**("reconcile은 원자적이지 않다, 예외 시 부분 커밋을
   예상하라").
3. **`updateFn` 호출을 `pcall`로 감싸 그 키만 스킵** — `:List` 레벨 국소 격리.
   비용/필요성 모두 불확실.

---

## 3차 패스에서 확인만 하고 **문제 없었던** 것 (다시 트레이싱하지 말 것)

**Modifier / 컴포넌트 합성 / 바인드**
- **같은 `Modifier` 객체를 두 Frame(또는 `:List`의 여러 행)에 재사용** —
  `flatten`은 Modifier를 읽기만 하고 뮤테이션 대상은 항상 그 호출부의 `input`
  배열이다. 필드 저장소가 `table.clone` 기반 immutable 체이닝이라 공유가 안전하다.
- **인라인 필드가 modifier를 이기는 규칙** — `Frame { BackgroundColor3 = None, M }`를
  reverse 순회 + `input[key] ~= nil`로 손으로 돌렸고 확정 서술과 일치.
- **컴포넌트 경계 `props.Modifier or None` 관용구** — 미전달 시
  `None` → `NoneHandler`(재귀) → `NilHandler`(`setLength(0)`/`setOffsetSource(None)`)로
  정확히 떨어진다.
- **멀티루트(Slot 반환) 컴포넌트에 modifier/`Ref`를 붙이려는 시도** — 크래시가
  아니라 "저작자가 안 받으면 조용히 버려짐"으로, 문서가 의도한 동작 그대로.
- **`bind-system-plan.md`의 "확정된 것"** — 핸들러 3종 계약/Signal 미채택/
  Ref 도입 배경/quad2-try 죽은 접근 목록 전부 최신 문서와 대조해 불일치 없음.

**Store / State / Source**
- **`:Compute`/`:With`의 lazy 핸들 체인 3단(A→B→C)** — `previous` 스코핑,
  `valueEpochMap`/`emitEpochMap` 시딩(`:Sync` vs `:TrackFrom`)까지 정상.
- **같은 상류를 두 번 참조**(`a:With(b, b)`, `:Compute(fn, b, b)`) —
  `EpochMap`이 테이블 identity 키라 idempotent.
- **재진입 — Observer 콜백에서 상류를 다시 `Set`** — 다이아몬드로 확장해
  돌렸고, 중첩 `Set`이 먼저 훑은 가지에 outer가 뒤늦게 도착하면 규칙 3이
  중복 배달을 삼킨다. glitch/누락 없음. (**단 `H-23`은 이것과 별개다** —
  거긴 `Set` 재호출이 아니라 **새 구독자 등록**이다.)
- **`Store` eager 생성의 순회 중 값 교체** — `for k, v in sources do sources[k] = Source(v) end`는
  **기존 키의 값만** 바꾸므로 안전(`H-23`과 성격이 다르다).

**이벤트 / 라이프사이클 / 모듈**
- **이벤트 재디스패치 전 사이클**(`fn1 → fn2 → None → fn3`) — (A)/(B) 분기,
  `NoneHandler`/`NilHandler` 재귀, `chains` 인덱스 배정이 이중 Connect/유실
  없이 맞물린다. `EventHandler`는 `v==nil`을 명시적으로 다뤄 안전하다(빠진 건
  `OnChange`뿐 — `H-27`).
- **`Relate` 상호 강참조 순환** — 이 영역의 어떤 문서도 두 `Relate`가 서로의
  키를 상대 값으로 강하게 잡는 패턴을 새로 만들지 않는다. 실측 스파이크
  (`luau-test`의 상호 순환 케이스)도 이미 통과.
- **`RunInit` 멱등성** — 실행 **전에** 표시하는 순서 덕에 상호 재귀 초기화에서도
  무한루프가 안 난다.
- **`OnDestroyed(fn) = Effect(function() return fn end)`의 zero-dep 시그니처** —
  계약과 정확히 맞음(그 cleanup을 발화시키는 배선이 없는 건 `H-11`, 파생일 뿐).
- **최상위 `Destroy()`의 원자성** — Roblox 재귀 파괴는 Lua가 관측 가능한
  지점에서 인터리브되지 않으므로 "파괴 도중 emit이 절반만 죽은 대상을 만나는"
  경로가 없다. `Blocker`로 지연된 emit이 `Destroy` 뒤에 풀려도 `canExecute`가
  걸러낸다.

**Tween / 시간 게이트**
- **`Tween<T>`는 State/Epoch 그래프에 아예 안 얹힌다** — 값-레벨 raw 데이터일
  뿐이고 실제 보간은 엔진 `TweenService`가 전담한다. 매 프레임 `Set`이 도는
  코드 경로가 없어 dedup/에포크와 섞일 지점 자체가 없다.
- **대상 인스턴스 사망 시 tween 정리** — `H-11`의 파생이 **아니다.** 정리할
  임의 자원이 없고(부기는 `Relate` 슬롯뿐), 실행 중이던 엔진 Tween은 엔진이
  자동으로 멈춘다(이미 사용자 판정으로 확인된 사실).
- **`Throttle{Time=1}` 기본(`Trailing=true`) 워크스루** — 문서의 자체 트레이스와
  재계산 결과가 일치. `_flush`/`_cancel`의 `setTimeout`/`clearTimeout` 짝도
  더블프리/댕글링 없음(`H-32`는 `Trailing=false`에서만).

**타입 / M1 코드 / 셋업**
- **실제 `pesde install` 재실행** — 워크스페이스 4멤버 심볼릭 링크 구조가
  `base/project-setup-plan.md` 서술 그대로 재현되고, 재설치 후에도 `git status`
  클린(lockfile 5개 전부 커밋돼 있음).
- **문서가 서술한 symlink 문제 재현** — `luau-analyze quad-base/src/init.luau`가
  실제로 `Unknown require: unsupported path`로 깨지고, 스모크도 런타임에서 같은
  이유로 깨진다(문서 주장과 일치).
- **symlink를 실파일로 치환한 복사본으로 M1 전체 검증** —
  `quad-base/src/init.luau`가 `luau-analyze` **0 진단**, 스모크 3종(`RunInit`
  멱등성 / `AddPlugin` mutate+identity 보존+체이닝 누적 / `Relate` 격리) **전부
  PASS**.
- **`RelateImpl`/`Relate()` 실제 구현이 `base/relate-plan.md`와 1:1 일치** —
  weak-key 버킷, `StrongMap`/`WeakMap` lazy 생성, 공유 메타테이블 재사용까지.
- **`Gate`/`Effect`/`EpochMap`은 재귀 제네릭 한계와 무관** — 셋 다
  "`Foo<T>` 안에서 `-> Foo<U>`" 패턴이 아니다(`H-24`와 대조).
- **`luau-test/STATUS.md`의 재작성 대기 지침** — 2026-08-22의 마일스톤 이동
  (`EpochMap`/`GateNode`/`Blocker`가 M2로)은 "어디서 구현하는가"만 바꿨고
  "무엇을 검증하는가"는 안 바꿔서 스파이크 지침엔 영향 없음.

---

## 3차 패스 회신 방법

1·2차와 같다 — **"맞다/아니다"만 주면 그대로 반영**하겠다. 다만 아래는 갈래
선택이 필요하다:

- **`H-25`(`Quad` 타입 확장 경로)** — 세 갈래 중 하나. **이게 가장 급하다**:
  M2가 첫 서브시스템(`Dispatch`)을 붙이는 방식 자체가 여기서 갈리고, M5의
  quad-roblox 주입 경로까지 딸려 있다.
- **`H-23`(구독자 집합 순회)** — 세 갈래 중 하나. 실측으로 재현되는 간헐적
  누락이라 M3 `State` 구현에 직접 걸린다.
- **`H-26`(부분 생성 후 예외)** — 세 갈래 중 하나. 어느 쪽을 고르든
  `base/dispatch-core-plan.md`에서 잔여 부기가 인스턴스 GC로 정리된다고 적은
  문장은 **틀린 안전망 주장**이라 같이 고쳐야 한다.
- **`H-21`/`H-22`** — 각각 두세 갈래이지만 전부 좁은 선택이라 "1번으로"
  정도면 충분하다.
- **`H-29`** — 미작성 함수를 쓰는 일이라 대부분 작업이지만, **리프 평탄화
  헬퍼를 새로 둘지**는 결정이다.
- **`H-32`/`H-33`** — 백로그(`Debounce`/`Throttle`)라 급하진 않다. 둘이 같은
  코드를 손대므로 한 번에 처리하는 게 싸다.

나머지(`H-27`/`H-28`/`H-30`/`H-31`/`H-34`~`H-38`)는 확인만 해주면 바로 반영
가능하다. **`H-2`의 실측 정정**도 같이 확인해주면 그 항목을 고쳐 쓰겠다.
반영은 이 파일이 아니라 각 `base/` 문서에 하고, 처리 결과는 1·2차와 묶어
`-followup.md`에 쌓는다.

---

# 4차 패스 (2026-08-24) — 축을 바꿔서 훑기, 발견 16건

**이번엔 "문서를 하나씩"이 아니라 축을 바꿨다.** 1~3차는 문서 단위로 훑었고
그 층은 상당히 걷혔다. 그래서 4차는 **문서를 가로지르는 축 여섯 개**로 다시
잡았다 — (G) 모든 핸들러를 한 표에 모아 서로 부딪히는지, (H) 두 대형 핸들러
문서(`ref-plan.md`/`attribute-plan.md`)의 심층, (I) **`luau-test` 스파이크를
실제로 다시 실행**, (J) 프리미티브 × 프리미티브 조합, (K) `reference/`·
`archive/`·로드맵 M3~M9·`question.md`, (L) **코퍼스가 근거로 삼는 엔진/언어
사실 주장을 전수 검증**.

**이번에도 실측했고, 인터넷으로 엔진 사실을 교차검증했다.** 로컬 `luau`
0.734 / `luau-analyze`에 더해 `create.roblox.com` 공식 문서를 대조했다.
그 결과 **`H-21`의 전제가 공식 문서로 확인**됐고(Roblox `Instance`는 없는
멤버 인덱싱 시 에러), 반대로 **`PreRef`의 존재 근거가 엔진 설정에 조건부**라는
게 드러났다(`H-42`).

**⭐ 가장 무거운 발견(`H-39`)은 세 에이전트가 서로 다른 축에서 독립적으로
같은 결론에 도달했다** — 핸들러 레지스트리 전수(G), `ref-plan.md` 심층(H),
조합 매트릭스(J). 문서를 하나씩 읽는 방식으로는 **구조적으로 안 보이는**
종류였다: 등록 의무는 `dispatch-core-plan.md`에만 있고 각 핸들러 문서는
자기 로직만 서술하므로, 교차 대조 없이는 빠진 걸 알 수 없다.

**여기서도 `base/`는 한 줄도 안 고쳤다.**

| 번호 | 심각도 | 한 줄 | 주 대상 |
|---|---|---|---|
| `H-39` | 🔴 | **배열 자리를 차지하는 말단 핸들러 4종이 `setLength`/`setOffsetSource`를 아예 등록 안 함** — 첫 마운트에 `recompute`가 명시적 error로 죽음 | `base/tag-plan.md`, `base/attribute-plan.md`, `base/ref-plan.md`, `base/source-state-plan.md` |
| `H-40` | 🔴 | 공개 `Slot:Add` 의사코드가 CRUD 절이 확정한 가드를 **하나도** 안 함(`H-37`은 이 문제의 반쪽이었다) | `base/slot-plan.md` |
| `H-41` | 🔴 | `groupClaimKeys`(같은 그룹 객체 이중 배치 방지) 확정이 실제 의사코드에 배선 안 됨 | `base/attribute-plan.md` |
| `H-42` | 🟡 | `PreRef`의 **존재 근거 자체**가 `Workspace.SignalBehavior`에 조건부인데 코퍼스가 이 설정을 모름 | `base/ref-plan.md` |
| `H-43` | 🟡 | `dispose`가 Slot도 Instance도 아닌 값을 그대로 백엔드로 흘림(`H-28`의 짝) | `base/slot-plan.md` |
| `H-44` | 🟡 | `ROADMAP.md` M6의 Slot 백엔드 줄이 `native*` 확정 이전 모델 + 존재하지 않는 엔진 API | `ROADMAP.md` |
| `H-45` | 🟡 | `H-18` 파생 — 단건 `AttributeKey` ↔ 그룹 사이의 이름 이전도 emit 순서 의존 | `base/attribute-plan.md` |
| `H-46` | 🟢 | top-level `Slot.luau`가 소스 트리에 없는데 `slot-plan.md`는 그 파일명을 박아둠 | `base/architecture.md` |
| `H-47` | 🟢 | 소스 트리가 **이미 커밋된** `quad-base/src/Debug/`를 빠뜨림 | `base/architecture.md` |
| `H-48` | 🟢 | `Quad.debug` 스코프가 문서상 "미정"인데 M1 코드가 이미 인스턴스별로 정함 | `base/module-lifecycle-plan.md` |
| `H-49` | 🟢 | `todos.md`가 `Gate`의 이미 닫힌 항목(재진입)을 남은 것처럼 나열 + 남은 하나를 오분류 | `.claude/todos.md` |
| `H-50` | 🟢 | `ROADMAP.md` M6이 `Effect`의 `_detached` 정리를 사실처럼 서술(`H-11` 파생) | `ROADMAP.md` |
| `H-51` | 🟢 | `todos.md`가 마일스톤 재편을 아직 열린 것처럼 적은 문장이 2026-08-22 재편으로 이미 닫힘 | `.claude/todos.md` |
| `H-52` | 🟢 | `TagHandler`/`AttributeGroupHandler`의 `isHandlable`에 `type(k)=="number"` 가드가 없음(`RefLeafHandler`는 같은 버그로 이미 한 번 고쳐졌다) | `base/tag-plan.md`, `base/attribute-plan.md` |
| `H-53` | 🟢 | `Ref:Set()`이 `.Value`를 언제 쓰는지 의사코드가 없음 | `base/ref-plan.md` |
| `H-54` | 🟢 | 스파이크 `12`의 자기 주석이 실제 결과와 어긋남(총론은 유효) | `.claude/luau-test/` |

---

## 🔴 `H-39` — 배열 자리를 차지하는 말단 핸들러 4종이 `setLength`/`setOffsetSource`를 아예 등록하지 않는다

**어디**: `base/dispatch-core-plan.md`의 "Length/Offset — 여러 Slot이 형제로
섞일 때 순서 보장" 절이 세운 계약 vs `base/tag-plan.md`의 `TagHandler.process` /
`base/attribute-plan.md`의 `AttributeGroupHandler.process` /
`base/ref-plan.md`의 `RefLeafHandler.process` /
`base/source-state-plan.md`의 `ObserverEffectLeafHandler.process`.

**확신도**: 확실. **세 에이전트가 서로 다른 축에서 독립 발견**했고, 메인
세션이 전수 grep으로 재확인했다.

**계약 쪽 원문**:
- *"**둘 다 array part의 모든 number 인덱스에 대해 반드시 호출 — 생략은 UB**"*
- *"호출 책임은 … **그 위치의 체인을 실제로 끝내는 말단 Handler**"*
- *"아래 '짝을 맞춰 `0`' 규칙은 **값이 정말 없는 자리**(Ref/`nil`)에만 해당한다
  … 대상은 **일반 `Ref`뿐 아니라** 그 배열 위치의 값 자체가 `None`인 모든 경우"*
  — 즉 이 문서가 **일반 `Ref`를 등록 대상으로 명시적으로 지목**한다.
- `recompute` 의사코드: `if offset == nil then error("Dispatch.recompute:
  sourceList[" .. i .. "]가 nil — 부기가 깨졌음(계약상 None이어야 함)") end`
  (2026-08-20 `C-6`으로 "관대한 skip"에서 **error로 승격**된 자리다).

**검증(메인 세션 재확인)**: `setLength|setOffsetSource` 전수 grep —
- `tag-plan.md`: **0건**
- `attribute-plan.md`: **0건**
- `source-state-plan.md`: 1건(무관한 산문, `ObserverEffectLeafHandler`와 별개)
- `ref-plan.md`: `ProcessedPreRefHandler`/`ProcessedPostRefHandler` 두 블록에만 있음
  — `RefLeafHandler.process` 본문엔 없음

대조군은 전부 정확히 등록한다: `NilHandler`, `ProcessedPreRefHandler`,
`ProcessedPostRefHandler`, `materializeSlotTree`.

**무엇이 어긋나나**: `bk.N`은 `setLength` 안에서 `bk.N = math.max(bk.N or 0, i)`로
**다른 위치가 등록될 때** 커진다. 그래서 "등록을 건너뛴 위치"가 `bk.N` 범위
안에 끼면 `recompute`가 그 자리에서 `sourceList[i] == nil`을 만난다.

**트레이스** — `Frame { Tag("card"), TextLabel { Text = "Hi" } }`
(Tag를 자식보다 앞에 두는, 아주 흔한 배치):

| 스텝 | 무슨 일 | 부기 상태 |
|---|---|---|
| 1 | `Dispatch.drive`가 배치 Blocker를 켜고 배열 파트 순회 | — |
| 2 | `i=1`: `TagFallbackHandler` 매치 → `addTag(inst, {"card"})`만 하고 리턴 | `sourceList[1]`/`lengthList[1]` **둘 다 `nil`**, `bk.N`도 아직 없음 |
| 3 | `i=2`: plain 요소 경로가 `setOffsetSource(inst,2,None)` → `setLength(inst,2,1)` | `bk.N = math.max(nil or 0, 2) = 2` |
| 4 | 배치 종료 → `blocker:OffWithoutEmit()` → `recompute(inst, bk)` | — |
| 5 | `for i = 1, 2`의 `i=1`: `bk.sourceList[1]`이 `nil` | **`error("Dispatch.recompute: sourceList[1]가 nil …")`** |

같은 트레이스가 `Frame { Ref(myRef), Frame{} }`, `Frame { someObserver, Frame{} }`,
`Frame { Attribute(store), Slot() }`에서 그대로 재현된다. **해당 항목이 배열
맨 끝이면 `bk.N`이 거기까지 안 커져서 안 터진다** — 즉 저작 순서에 따라
"가끔 되고 가끔 터지는" 형태로 드러난다.

**반대 증거 확인**: (1) `Dispatch.process`/`Dispatch.drive` 의사코드에
기본값 채우기가 있는지 직접 읽음 — 없다. `chains`(handler/retractor 부기)와
`lengthList`/`sourceList`/`bk`는 **완전히 별개 자료구조**다. (2) "이
핸들러들은 Length/Offset 대상이 아니다"라는 면제 규정을 코퍼스 전체에서
grep — 없다. (3) 오히려 `dispatch-core-plan.md`에서 말단 핸들러의 `inst` 부작용을 정리한
표가 `NilHandler` 행엔 *"없음(`setLength`/`setOffsetSource` 부기만)"*이라
적어두고 바로 아래 `RefLeafHandler` 행엔 `Ref:Set` 하나만 적어놨다 — **그
표 자체가 이미 비대칭을 드러내고 있었다.** (4) `H-3`/`H-4`(캐시 무효화·
스펙 부재)와 다른 문제다 — 그쪽은 등록은 하되 캐시가 어긋나는 것이고,
이쪽은 **값 자체가 없다.** (5) `H-35`(`ProcessedModifierHandler` 의사코드
부재)와도 다르다 — 그쪽은 핸들러가 아예 안 적힌 것이고, 이쪽은 **적혀
있는데 등록을 안 한다.**

**갈래**: 대부분은 단순 정정이지만 한 자리는 판단이 필요하다.
1. **네 핸들러의 `process` 본문에 `setOffsetSource(inst,k,None)` +
   `setLength(inst,k,0)`을 추가**(순서는 계약대로 offsetSource 먼저).
   `Ref`/`Observer`/`Effect`는 이걸로 끝이고, 문서가 이미 "일반 `Ref`도
   대상"이라 못박아뒀으므로 새 결정이 아니다.
2. **`AttributeGroupHandler`만 층위 질문이 남는다** — 그룹 핸들러는 자기
   체인에선 말단이지만 실제로는 **다른 키로 위임**하는 성격이라, "이 배열
   위치가 몇 개를 기여하는지 답하는 게 왜 Attribute 핸들러의 책임인가"가
   깔끔하지 않다. (a) 그냥 다른 핸들러와 똑같이 `process` 맨 앞에서 등록,
   (b) Tag/Attribute를 "Length/Offset에 참여하지 않는 별도 카테고리"로
   재정의하고 `recompute`가 건너뛰게 — (b)는 `bk.N` 의미를 바꾸므로 파급이
   크다. **(a)를 권한다.**

---

## 🔴 `H-40` — 공개 `Slot:Add` 의사코드가 CRUD 절이 확정한 가드를 하나도 하지 않는다

**어디**: `base/slot-plan.md`의 "CRUD API 확정" 절(계약)과 같은 문서의
`Slot:Add` 의사코드(구현).

**의사코드 전문**(이게 전부다):
```lua
function Slot:Add(element, index)
    return rawAdd(self, wrapElement(element), index)
end
```

**같은 문서가 확정한 것 — 네 가지가 전부 빠졌다**:
1. **`self._listed` 가드** — *"공개 CRUD 중 실제로 mutate하는 것은 … `self._listed`
   (`:List`가 설치돼 있으면 수동 CRUD 금지)만 확인하고 실제 로직은 `raw*`에"*.
2. **`self._crudUsed = true`** — *"모든 mutate CRUD(`Slot(initial)`이 호출하는
   `:Add` 포함)가 `self._crudUsed = true`를 세팅"*. 이게 없으면
   `Slot():Add(x); slot:List(...)` 같은 코드가 조용히 통과한다(그 가드가
   막으려던 바로 그 gap).
3. **요소 타입 검증** — *"`element`가 `nil`/`None`이거나 핸들러 계층 값
   (Ref/PreRef/PostRef/Observer/Effect/Modifier)이면 에러"*.
4. **index 범위 검증** — *"`index`가 범위 밖(1..현재 개수+1)이면 에러 — **clamp
   안 함**"*.

**검증**: `slot-plan.md` 전체에서 `error(` 호출을 전수 확인 — 소유권
(`claimOwner`/`releaseOwner`), `duplicate key`, `KeyGone` 관련뿐이고
**요소 타입/index 범위 검증 error는 0건**이다.

**⭐ `H-37`은 이 문제의 반쪽이었다.** 3차 패스가 "`Slot:List` 의사코드에
`_crudUsed` 가드가 빠졌다"고 보고했는데, 이제 보면 **그 대칭 가드의 양쪽이
둘 다 어느 의사코드에도 없다** — `:List` 쪽은 `assert(not self._crudUsed)`가
없고, `Add` 쪽은 `_crudUsed = true` 세팅 자체가 없다. 즉 그 가드는 **완전히
배선되지 않았다.**

**트레이스 (a) — 타입 검증 부재로 조용히 통과하는 값**:
```lua
local t = Tween { Value = someFrame }
slot:Add(t)
```
1. `wrapElement(t)` — `isState(t)`가 거짓(`Tween`은 `TweenBrand`) → `t` 그대로.
2. `rawAdd(self, t, nil)` — `claimOwner(t, self)`는 타입을 안 본다 →
   `table.insert(self._elements, t)`.
3. `isSlot(t)`도 거짓 → plain 분기 → `nativeInsert(..., { t })` +
   `setLength(self, index, 1)`. **물리적으로 아무것도 안 붙었는데 `Length`만
   유령 +1**이 되고, 나중 파괴 경로에서 `nativeDispose(t)`(= `t:Destroy()`)가
   `Destroy` 메소드 없는 테이블에서 죽는다.
- **`Tween`은 애초에 금지 목록에도 없다** — "요소 타입 제약"의 블랙리스트는
  Ref/PreRef/PostRef/Observer/Effect/Modifier뿐이다. 블랙리스트 방식이라
  목록에 없는 값 타입은 전부 샌다.

**트레이스 (b) — 상호 배타 가드가 안 걸림**:
`Slot():Add(frameA)` 후 `slot:List(data, fn)` → `Slot:List`의
`assert(not self._listed)`는 통과(아직 `:List` 없음), `_crudUsed` assert는
애초에 코드에 없음 → **설치 성공** → reconcile이 `frameA`의 존재를 모른 채
`mounted`/`keyIndex`가 빈 상태로 시작 → Length 이중 계산·인덱스 꼬임.
문서가 *"이 상태로는 … gap이 있었음"*이라며 막았다고 선언한 바로 그 경로다.

**갈래**: 단순 정정 — 확정 산문이 이미 정확한 알고리즘을 서술해뒀으므로
의사코드에 옮기기만 하면 된다. 하나만 판단이 필요하다: **`Tween`(그리고
앞으로 생길 다른 값 타입)을 블랙리스트에 추가할지, 아니면 화이트리스트로
뒤집을지.** base는 `T`가 뭔지 모른다는 게 이 문서의 일관된 입장이라
(`Splice`의 `T | {T}` 기각 논거) 화이트리스트는 어려워 보이는데, 그러면
블랙리스트는 영원히 새는 채로 남는다.

---

## 🔴 `H-41` — `groupClaimKeys` 확정이 `AttributeGroupHandler.process` 의사코드에 배선되지 않았다

**어디**: `base/attribute-plan.md`의 "이름 소유권 — 그룹 전용 키 + 이름 claim"
절(확정 서술)과 "메커니즘 — 그룹 전용 키로 단일 키 경로에 위임" 절(실제 코드).

**확정 서술**: *"✅ [해소, 2026-08-21 구현 전 QA 5라운드 `AT-1`] 키는
`(inst, groupValue) → k`로 확정 … **판정**: `process` 시점에
`groupClaimKeys[inst][groupValue]`를 보고, 비어 있으면 `k`를 기록하고 통과,
**이미 다른 `k`가 있으면 error**. retract에서 자기 `k`일 때만 지운다 …
**`nameClaims`와의 순서**: 위치 claim이 **먼저다**"*.

**실제 의사코드**:
```lua
function AttributeGroupHandler.process(inst, k, v, index)
    local keys = {}
    for name, source in pairs(v:NameMap()) do
        local key = groupKey(v, name)
        Dispatch.process(inst, key, source, 1)
        keys[key] = true
    end
    return function()
        for key in pairs(keys) do Dispatch.retractFrom(inst, key, 1) end
    end
end
```
**`groupClaimKeys` 읽기도 쓰기도 없다**(전수 grep — 그 이름은 "이름 소유권"
절의 **서술에만** 3회 등장한다). 이 코드 블록은 2026-08-13 확정본이고
`AT-1` 결정보다 **시기적으로 앞선다** — 결정이 나면서 이 블록을 안 고친 것.

**트레이스** — 문서 자신이 예로 드는 `Frame { a, a }`(같은 그룹 값 객체):
1. `k=1`: 체크가 없으니 곧장 `groupKey(a, name)`으로 위임.
2. `k=2`: 역시 체크가 없으니 **아무 저지 없이** 같은 `groupKey(a, name)`으로
   또 위임 → `nameClaims`는 `cur == k`라 통과(문서가 "이름 소유권" 절에서
   이미 지적한 우회).
3. 두 위치가 `(inst, 같은 groupKey)` 체인 하나를 공유하게 된다.
4. `k=1`이 retract되면 그 클로저가 `retractFrom(inst, key, 1)`을 부르는데
   **그건 `k=2`가 아직 쓰고 있는 체인**이라 `k=2`의 바인딩까지 통째로 철거된다
   — `AT-11`이 원래 지적했던 크래시가 그대로 재현.

**반대 증거 확인**: `groupKey(v, name)` 자체가 막아주지 않는지 확인했는데,
그건 "그룹 값 객체별·이름별 메모이즈"라 **같은 객체면 의도적으로 같은 키를
반환**한다(1회성 재프로세스 dedup에 필요한 설계). 즉 이 함수가 이중 배치
방지를 겸할 수 없고, 그래서 별도로 `groupClaimKeys`를 두기로 한 것이다.

**갈래**: 단순 정정 — "판정" 문단이 이미 정확한 알고리즘을 서술해뒀으므로
`process` 맨 앞과 retractor에 그대로 옮기면 된다.

---

## 🟡 `H-42` — `PreRef`의 존재 근거가 `Workspace.SignalBehavior`에 조건부인데, 코퍼스가 이 설정을 모른다

**어디**: `base/ref-plan.md`의 `PreRef` 신설 근거 문단.

**근거 원문**: *"Roblox 이벤트 중 일부(`ChildAdded`/`DescendantAdded`/`Changed`류)는
유저 인터랙션을 기다리지 않고 **setup 도중 프로퍼티 대입/Parent 세팅 자체의
부작용으로 동기적으로 발화**할 수 있음 — 이때 이벤트 핸들러가 아직 안 채워진
self-ref를 읽으면 터짐."* `PreRef`가 pre-pass로 호이스팅되는 이유 전체가 이
**동기성** 전제 위에 서 있다.

**검증(공식 문서)**: `Workspace.SignalBehavior`(`Enum.SignalBehavior`:
`Default`/`Immediate`/`Deferred`)가 이 동기성을 결정한다.
- **Immediate**: 이벤트가 다른 이벤트를 트리거하면 두 번째 핸들러가 **즉시**
  발화(중첩 실행).
- **Deferred**: 큐 뒤에 붙어 **다음 resumption point**(입력 처리, `RunService`
  콜백, `task` 계열)에서 실행 — 스크립트의 동기 실행 흐름을 끊지 않는다.
- **"template places are directly set to Deferred by default"** — 오늘 Studio에서
  새로 만드는 템플릿 place는 **이미 Deferred**다.
- `Default`(레거시 place)는 현재 Immediate와 같지만 **앞으로 Deferred로 바뀔
  예정**이라고 공식 문서가 명시한다.
- 출처: https://create.roblox.com/docs/scripting/events/deferred ,
  https://create.roblox.com/docs/reference/engine/classes/Workspace#SignalBehavior

**무엇이 어긋나나**: Deferred에서는 `PreRef`가 막으려는 레이스가 **발생할 수
없다** — `Parent` 대입이 `ChildAdded`를 발화 "대상"으로 만들어도 그 콜백은
quad의 동기 마운트가 **전부 끝난 뒤에** 실행되므로, 그 시점엔 일반 `Ref`도
이미 채워져 있다. 즉 코퍼스 90개+ 문서 어디에도 `SignalBehavior`/`Deferred`가
**단 한 번도 등장하지 않는데**(전수 grep 0건), 조건부 사실이 무조건 사실처럼
서술돼 있다.

**왜 그냥 넘기면 안 되나**: 크래시를 만들진 않는다 — Deferred에서 `PreRef`는
무해하게 불필요해질 뿐이다. 문제는 **나중에 실측할 때다.** 언젠가 Studio에서
"이 레이스가 재현이 안 된다"는 결과가 나오면, 그게 quad 설계가 틀린 건지
place의 `SignalBehavior` 때문인지 **아무도 구분할 수 없다** — 근거 문장이
전제를 안 적어놨기 때문. 그리고 quad는 `PreRef`/`PostRef`라는 **두 프리미티브와
pre-pass 전체**를 이 전제 위에 세웠다.

**반대 증거 확인**: `dispatch-core-plan.md`의 *"프레임 경계는 여전히 안
낀다(yield 금지)"*는 **quad 자신의 코드가 yield 안 한다**는 얘기이고,
**Roblox가 그 이벤트 콜백을 큐잉하는지**와는 다른 축이다 — 반박이 아니다.

**갈래**:
1. **문서만 정정**(권장) — "동기 발화"를 "`SignalBehavior.Immediate`에서 동기
   발화(Deferred에선 이 레이스가 없고 `PreRef`는 무해하게 불필요)"로 조건을
   명시. 코드 변경 없음. 실측 계획을 세울 때 place 설정을 같이 적게 만드는
   효과가 진짜 이득이다.
2. **런타임 감지·경고** — `Workspace.SignalBehavior`를 읽어 진단 도구에서
   안내(읽기 가능 여부 미확인). 오버엔지니어링 소지.
3. **아무것도 안 함** — 실질 피해가 없다고 보고 방치.

**⚠️ 판단이 필요한 진짜 질문은 그 다음이다** — Deferred가 표준이 되어가는
방향이라면, `PreRef`/`PostRef`/pre-pass라는 구조 자체를 **계속 유지할
가치가 있는가**? 이건 문구 정정과 다른 층위의 결정이라 여기서 답하지 않는다.

---

## 🟡 `H-43` — `dispose`가 Slot도 Instance도 아닌 값을 그대로 백엔드로 흘린다

**어디**: `base/slot-plan.md`의 "quad가 관리 중인 값을 안전하게 지우는 유일한
경로" 절. **`H-28`(가드가 Slot 분기에만 있음)의 짝이다** — 그쪽은 "Instance인데
아직 필요한데도 파괴된다"이고, 이쪽은 "**Instance가 아닌 것도 그대로 파괴로
간다**"이다.

**무엇이 어긋나나**: 시그니처는 `dispose(value: Slot | Instance): ()`이고
산문은 *"범위 — `Slot` + 엔진 객체(Instance)만, `Observer`/`Effect`는 명시적으로
제외"*라고 하는데, 의사코드는 `if isSlot(value) then ... else nativeDispose(value) end`
하나뿐이라 **`isSlot`이 거짓이면 뭐든 `else`로 샌다.** "제외"가 타입 체크가
아니라 산문상 규약일 뿐이다.

**트레이스**: `local r = Ref(); dispose(r)` → `isSlot(r)` 거짓 →
`nativeDispose(r)` = `r:Destroy()`. `Ref`는 `.Value`/`:Set`/`:Callback`/`:Wait`만
갖는 값 박스라 `Destroy`가 없다 → **`attempt to call a nil value (method
'Destroy')`**. quad 레벨의 명확한 에러("dispose는 Slot|Instance만 받습니다")
대신 백엔드 깊은 곳에서 알 수 없는 실패가 난다 — 이 유틸의 존재 이유가
정확히 "명확한 에러로 잡아주는 것"인데 그 반대가 된다.

**갈래**: 단순 정정 — `else` 진입 전에 백엔드가 제공하는 판별(`isInstance` 류)로
확인하고 아니면 `error("dispose는 Slot | Instance만 받습니다, got " .. typeof(value))`.
`H-28`(소유권 가드를 분기 밖으로)과 **한 번에 같이 고치는 게 맞다.**

---

## 🟡 `H-44` — `ROADMAP.md` M6의 Slot 백엔드 줄이 `native*` 확정 이전 모델이다

**원문**: *"base `Dispatch/Slot.luau`(추상 재조정, mount/unmount/reposition
**3훅**) + quad-roblox `Handlers/Slot.luau`(실제 Parent 조작 + reposition —
**`SetSiblingIndex`** 또는 `LayoutOrder` 기반이면 no-op, 구현 선택)"*

**무엇이 어긋나나**: 2026-08-21에 확정된 건 3훅이 아니라 **`native*` 6개**
(`nativeInsert`/`nativeExtract`/`nativeRemove`/`nativeMove`/`nativeSwap`/
`nativeDispose`)이고, 인자는 **0-based 절대 offset + 대상 요소 배열**이며,
미주입 시 조합 폴백이다. `base/architecture.md`의 `EngineOps.luau` 줄이
**"이 줄이 주입 op 전체 목록의 단일 소스다"**라고 스스로 선언해뒀다.
M6 체크박스를 그대로 따르면 **이미 폐기된 인터페이스를 구현**하게 된다.

**부수 — `SetSiblingIndex`는 Roblox에 없는 API로 보인다**:
`create.roblox.com`/devforum 검색에서 찾지 못했고, Roblox가 문서화한 자식
순서 수단은 `LayoutOrder`(+`table.sort`)와 "Parent가 설정된 순서"뿐이다
(https://create.roblox.com/docs/reference/engine/classes/GuiObject ,
https://create.roblox.com/docs/reference/engine/classes/Instance#GetChildren —
후자는 *"The returned array is not sorted in any particular order"*).
부재 증명은 아니지만, 그 줄이 `native*` 확정 이전에 **엔진 API를 추정으로
적어둔 자리**라는 정황이 강해진다.

**갈래**: 단순 정정 — M6 줄을 `native*` 계약으로 다시 쓰고, 백엔드 쪽 서술은
`architecture.md`의 `EngineOps.luau` 줄을 가리키게 한다(개수를 다시 세지 말 것).
**`H-34`(조합 폴백이 `Move`/`Swap` 이유를 되돌림)와 같이 처리하는 게 싸다.**

---

## 🟡 `H-45` — `H-18` 파생: 단건 `AttributeKey` ↔ 그룹 사이의 이름 이전도 emit 순서에 의존한다

**어디**: `base/attribute-plan.md`의 "이름 소유권 — 그룹 전용 키 + 이름 claim" 절.

**무엇이 어긋나나**: `H-18`은 "그룹 A가 이름을 놓고 그룹 B가 가져가는" 조합만
봤다. 같은 메커니즘이 **직접 쓰기 ↔ 그룹** 조합에도 그대로 적용된다.
그 문서는 *"직접 리터럴 쓰기는 … 한 Modifier 안에 같은 해시 키가 중복될 수
없어 이 경로 자체의 소유자는 항상 유일하고, 그룹이 이미 그 이름을 잡고 있으면
claim이 즉시 error"*라며 **소유자 유일성**만 논증하는데, 유일성은 **소유권
이전 시의 순서 문제**를 없애주지 않는다.

**트레이스**:
```lua
Frame {
    [AttributeKey<<number>> "Hp"] = someStore:Compute(fn),  -- 지금 "Hp" claim 보유
    groupB,                                                  -- State<Attribute>, {} → {"Hp"}
}
```
`someStore`가 `None`으로 물러나는 emit과 `groupB`가 "Hp"를 흡수하는 emit이
**서로 다른 두 `(inst,k)` 체인**이라 도착 순서가 미정이다. `groupB` 쪽이
먼저 처리되면 `nameClaims:GetStrong(inst,"Hp")`가 아직 직접 쓰기 키를 가리켜
`cur ~= nil and cur ~= k` → **error**. 반대 순서면 정상.

**갈래**: `H-18`과 **같은 결정으로 닫힌다** — 새 선택지가 필요한 게 아니라,
그 결정의 적용 범위를 "그룹↔그룹"에서 **"이름을 가진 임의의 두 소유자 조합"**으로
넓히기만 하면 된다.

---

## 🟢 `H-46` ~ `H-49` — 소스 트리·문서 층의 어긋남 (메인 세션 발견)

### `H-46` top-level `Slot.luau`가 소스 트리에 없다
`base/architecture.md`의 소스 트리에서 quad-base/src의 값 타입은 전부 top-level
파일을 갖는다(`Modifier`/`Tag`/`Attribute`/`AttributeKey`/`Tween`/`Ref`/`Effect`).
**Slot만 없다** — 트리엔 `Dispatch/Slot.luau`와 quad-roblox `Handlers/Slot.luau`뿐이다.
그런데 `slot-plan.md`(3106줄)가 정의하는 것(생성자, 공개 CRUD 11종,
`:List`/`:Single`, `raw*` 세트, `wrapElement`/`unwrapElement`, `attachSlot`
3형제, `elementOwner`/`claimOwner`/`releaseOwner`, `dispose`, `Detach`/`KeyGone`)의
집이 어디인지 정해져 있지 않다. **⭐ 그냥 누락이 아니라 문서 간 불일치다** —
`slot-plan.md`의 `attachSlot` 의사코드 블록이 머리에 **`-- quad-base, Slot.luau`**라고
파일명을 직접 적어놨다. 대조: `Brand.luau`/탑레벨 `None.luau`가 트리에 없는 건
`ROADMAP.md`가 **이미 알고 항목화**해뒀는데(정상), Slot은 아무도 모른다.
**갈래**: (a) top-level `Slot.luau` 신설(다른 값 타입과 대칭), (b) `Dispatch/Slot.luau`
하나에 값 타입+핸들러를 같이 둔다고 명시(배치 규칙이 Slot만 갈림).

### `H-47` 소스 트리가 이미 커밋된 `Debug/`를 빠뜨렸다
`quad-base/src/Debug/init.luau`는 M1에서 **이미 커밋됐고**(`InitDebug(module)`,
`module.debug = false`) `base/project-setup-plan.md`가 그 경로를 여러 번 인용한다.
그런데 트리엔 없다. 즉 그 트리는 세 방향으로 어긋나 있다 — 실재하는데 없는 것
(`Debug/`), 확정됐는데 없지만 **로드맵이 아는 것**(`Brand.luau`/탑레벨 `None.luau`),
확정됐는데 없고 **아무도 모르는 것**(`Slot.luau`, `H-46`).

### `H-48` `Quad.debug` 스코프가 문서상 "미정"인데 M1이 이미 정했다
`base/module-lifecycle-plan.md`: *"다중 인스턴스화 시 인스턴스별인지 전역인지는
미정."* 그런데 커밋된 `Debug/init.luau`가 `module.debug = false`로 **인스턴스
필드**를 심고, `quad-types/src/init.luau`의 `Quad` 타입도 `debug: boolean`을
**필드로** 갖는다 → 사실상 인스턴스별로 확정돼 있다. 결함은 아니지만, 다음
세션이 "아직 정할 게 남았다"고 읽고 다시 논의하거나 전역으로 바꾸려 들 수 있다.

### `H-49` `todos.md`가 `Gate`의 잔여 항목을 잘못 나열·분류한다
`base/gate-plan.md`의 "아직 안 정한 것 (사용자 판단 필요)" 절에서 `[해소]`/
`[확정]` 태그가 **안 붙은 항목은 5번(생명주기) 하나뿐**이고, 6번(재진입)은
**`[2026-08-21 정리 — 열린 항목 아님]`**으로 명시적으로 닫혔다. 그런데
`todos.md`는 *"판단이 아니라 구현 시 정할 것들 — `Gate`의 생명주기·**재진입
계약**"*이라 적는다. (a) 재진입은 이미 닫혔는데 남은 것처럼 나열하고,
(b) 생명주기를 "판단이 아니"라고 분류하는데 그 항목이 사는 절 제목이 정확히
**"사용자 판단 필요"**다. 그리고 5번은 실제로 판단이 필요해 보인다 — 그 안의
*"`Gate` 자체에 `Flush`/`Cancel` 같은 표면을 둘지"*가 **`H-33`이 걸린 바로
그 자리**다(debounce 7절 의사코드가 `gate._flush`/`gate._cancel`을 전제).

---

## 🟢 `H-50` ~ `H-54` — 나머지

### `H-50` `ROADMAP.md` M6이 `Effect`의 `_detached` 정리를 사실처럼 서술한다 (`H-11` 파생)
*"owner가 죽으면 `activateList`가 건 `Effect`가 `_detached`를 전부 정리한다"* —
`H-11`이 확인한 대로 **그 cleanup을 발화시키는 배선이 코퍼스 어디에도 없다.**
ROADMAP은 구현 순서를 신뢰하고 읽는 문서라 이 문장은 안 되는 일을 "된다"로
오도한다. `H-11` 처리 시 같이 정정할 것.

### `H-51` `todos.md`가 마일스톤 재편을 아직 열린 것처럼 적은 문장이 이미 닫혔다
그 문장이 가리키는 구체적 문제("M2가 M3 소속 `Blocker.luau`에 의존")는
2026-08-22 재편으로 **`Blocker.luau`/`EpochMap.luau`/`GateNode`가 M2로
옮겨지며 사라졌다.** 지금 실제로 열려 있는 더 큰 문제(M2↔M3 양방향 의존,
`question.md` 2번)는 바로 위 문단이 이미 짚고 있어 실질 혼동 위험은 낮다.

### `H-52` `TagHandler`/`AttributeGroupHandler`에 `type(k)=="number"` 가드가 없다
`TagHandler.isHandlable(inst,k,v) = isTag(v)`(주석엔 *"array-part 전용"*),
`AttributeGroupHandler`도 `k`가 array-part라고 산문으로만 서술한다.
**이 코퍼스는 같은 버그를 이미 한 번 고친 전례가 있다** — `RefLeafHandler`의
주석: *"[2026-08-18 구현 전 QA] `type(k) == "number"` 체크가 빠져 있었음 —
leaf 바인딩은 배열 전용이고 … 빠지면 named 자리로 흘러온 Ref를 잡으려는
`HANDLER_PRIORITY_FALLBACK` 가드가 죽은 코드가 된다."* Tag/AttributeGroup은
그 수정을 못 받았고, 게다가 Ref/PreRef/PostRef/Observer/Effect가 가진
"동적 경로 가드"(k 무관 매치 + 명시적 error)도 없어 **안전망이 이중으로 없다.**
다만 지금 타입 시스템에서 `Tag`/`Attribute` 값이 실제로 해시 자리로 흘러들
경로를 확정하지 못해 🟢로 둔다. **갈래**: (a) 대칭적으로 가드+동적 경로 가드
추가, (b) 그 경로가 없으니 불필요하다고 판단하고 그대로 둠.

### `H-53` `Ref:Set()`이 `.Value`를 언제 쓰는지 의사코드가 없다
`.Value`를 **읽는** 관용구는 여러 번 나오지만 `:Set(value)`가 `self.Value = value`를
콜백 순회 **전/후** 어디에 두는지 보여주는 코드가 없다(`\.Value = ` grep 0건).
콜백은 값을 인자로 직접 받으므로 실무 영향은 낮지만, 콜백 A가 `.Value`를
읽는데 콜백 B가 아직 안 돈 시점에 무엇이 보이는지가 사양에 없다.
**갈래**: 단순 정정(콜백 순회 **전**에 쓰는 것으로 자연스럽게 채우면 됨).

### `H-54` 스파이크 `12`의 자기 주석이 실제 결과와 어긋난다
`12-type-attribute-generic-key-narrowing.luau`가 *"이건 당연히 통과해야 함"*이라
적어둔 동질 대조군(line 41-43)이 실제로는 에러를 낸다(`AttributeKey<T>(name)`이
문맥에서 `T`를 못 추론해 `unknown`으로 남음). 이건 오히려 "왜 진짜 테스트
대상이 조용히 통과하는지(= narrowing이 아예 안 일어남)"를 설명해주는 정합적
결과라 **`STATUS.md`의 총론(❌지만 설계 영향 없음)은 그대로 유효**하다 —
근거 라인만 다르다. 재작성 시 참고.

---

## 4차 패스에서 확인만 하고 **문제 없었던** 것 (다시 하지 말 것)

### ⭐ `luau-test` 스파이크 전수 재실행 — 전원 일치, 설계 드리프트 없음
`done/`의 16개를 **실제로 다시 돌렸다**(`luau`/`luau-analyze`).
- **16개 전원이 `STATUS.md`/`README.md`의 주장과 실행 결과가 일치**했다.
- **GC 스파이크(`07` 연쇄 GC, `18` 두-`Relate` 상호 순환)는 각 3회 반복 실행에서
  완전히 동일한 수치**가 나왔다(07: 5/5→0/0, 18: true/true→false/false) —
  `lifecycle-pattern.md`의 GC-native 전제를 흔드는 신호 없음.
- **설계 드리프트 0건** — `done/` 16개를 최근 확정분 키워드(`Epoch`/`EpochMap`/
  `Brand` 재작성, `Effect(fn,...deps)`, `state:Gate`, `native*`, `Detach`/
  `_detached`/`KeyGone`/`Owned`, `attachSlot` 분해)로 전수 grep → **매칭 0건**.
  전부 그 재설계 이전부터 있던 기반 메커니즘만 검증하고 있어 오염이 없다.
  `Brand`를 직접 구현해 쓰던 `22`는 이미 `rewrite-required/`에 있다.
- `23`이 원위치에서 `Unknown require: unsupported path`로 깨지는 건 **3차 패스가
  이미 기록한 pesde symlink 문제**이고, symlink 해제 복사본에서는 정상 통과한다.

### ⭐ 엔진/언어 사실 주장 검증 표 (코퍼스가 근거로 삼는 것들)
| 주장 | 결과 | 근거 |
|---|---|---|
| Roblox `Instance`는 없는 멤버 인덱싱 시 **에러**(`nil` 아님) | **참** | 공식 문서 + devforum 다수 — **`H-21`의 전제가 확인됨** |
| `GetChildren()` 순서 미보장, 자식은 순서 없는 집합 | **참** | *"not sorted in any particular order"* — `native*` 전체의 전제 |
| `LayoutOrder`/`ZIndex`는 물리 parent 순서와 분리 | **참** | 위와 정합 |
| `ClassName`은 안 바뀌어 그 시그널은 발화 안 함 | **참** | `audit/gcconn-trick-verification.md` 기존 실측(대조만) |
| 연결이 살아있으면 캡처값이 GC 안 됨 / `Destroy()` 시 `Connected` 즉시 false | **참** | 같은 실측(대조만) — `canExecute`의 유일한 하드 의존 |
| `Destroy()`는 재귀적으로 자식까지 파괴 + 커넥션 해제 | **참** | 공식 문서 |
| `Parent=nil` 후 `Destroy()`가 그냥 `Destroy()`보다 비싸다 | **부분적으로 참** | `Destroy()`가 그 일을 어차피 다 하는 건 확인 — 실제 비용 차 **벤치마크 근거는 없음**(논리적 추론) |
| Luau에 ephemeron 테이블 없음 | **참** | luau.org/compatibility, 코퍼스 인용 URL/내용 일치 |
| `bit32.bnot(-rev)` 랩 | **참** | 로컬 `luau` 실행, 코퍼스 예시값과 정확히 일치 |
| `ipairs`는 첫 `nil`에서 멈춤 | **참** | 로컬 실행 |
| `table.insert(t,0,x)`가 에러 | **거짓** | 3차 패스 정정을 재확인(범위 밖 큰 index·음수도 에러 없음) |
| `TweenBase:Cancel()`은 프로퍼티를 안 되돌림 / 진행 중 목표 교체 API 없음 | **참** | 공식 문서 + devforum — `tween-plan.md`의 override 정책 근거 유효 |
| `ChildAdded`류가 setup 중 **동기** 발화 | **조건부(Immediate 한정)** | **`H-42`** |
| Instance userdata가 나중에 다시 얻으면 같은 객체인가 | **미검증** | `audit/`가 이미 "미확인"으로 정확히 표시 |
| weak-key 테이블 + Instance 키 동작 | **미검증** | 같음(Studio 필요) |
| `table.insert`의 구멍 재사용 일반성 / `Relate` lazy 성능 / `CollectionService` 왕복 | **미검증** | 전부 문서가 이미 "실측 대기"로 표시 — 중복 실측 안 함 |

### 핸들러 레지스트리 — `H-39`/`H-52` 외엔 깨끗
- **매치 중복 없음** — `NoneHandler`/`NilHandler`/`StoreBind`/`RefLeafHandler`/
  `ObserverEffectLeafHandler`/`ProcessedPreRefHandler`/`ProcessedPostRefHandler`를
  전부 짝지어 대조했고, 브랜드/센티널이 상호 배타라 동률 우선순위여도 모호성이 없다.
- **`HANDLER_PRIORITY_FALLBACK`끼리도 충돌 없음** — Tag/AttributeKey/AttributeGroup/
  PreRef·PostRef·Effect·Observer 동적 경로 가드가 전부 다른 브랜드/조건.
- **매치 공백 없음** — `k`(number/string/AttributeKey) × `v`(nil/None/Ref/Observer/
  Effect/Tag/Attribute/State/Slot/Instance/Modifier) 조합이 전부 어느 핸들러
  하나 또는 명시적 매치 실패 error로 수렴한다(`ProcessedModifier`만 예외 —
  이미 `H-35`).
- **retractor 계약 위반 없음** — 이번에 읽은 모든 핸들러가 함수를 반환한다.
- **`SlotHandler`의 Length/Offset 등록은 정상** — `attachSlot` →
  `materializeSlotTree`가 자기 owner 위치와 자식 위치를 전부 정확히 등록한다
  (`H-39`의 대조군).

### 조합 매트릭스 — 다음은 안전
- **`Blocker`/`Gate` × `Slot.Length`** — `slot.Length:Block(b)`은 새 노드를
  반환할 뿐 원본을 변형하지 않고, `Dispatch.setLength`가 쓰는 `len`은 항상
  프레임워크가 만든 원본/상수라 사용자의 게이트가 그 경로에 끼어들 수 없다.
  `:Get()`이 게이트와 무관하다는 계약이 이걸 한 번 더 보강한다.
- **`Tween` × Slot 요소 위치** — `PropertyHandler`는 해시 파트 키만 매치하고
  배열 자리는 다른 체인을 타므로 조합 자체가 성립하지 않는다(단 검증 부재는 `H-40`).
- **`Ref` × `:List`** — 같은 Ref를 여러 행에 재사용하면 `bindLifetime`의 범용
  `canBound` 가드가 의도대로 즉시 error를 낸다. `Detach` 재마운트는
  `claimOwner`의 `fromDetached` 예외로 이미 처리되고, Ref 바인딩은 비파괴
  Detach로 안 끊긴다.
- **`Modifier`(State 필드) × `:List`의 각 행** — 각 행이 독립 Instance라 공유
  상태가 없다.
- **`State<Slot>` 3중 중첩** — `materializeSlotTree`의 `isSlot` 재귀가 깊이
  무관하게 일반화돼 있어 depth-2 검증이 귀납적으로 적용된다(단 3단을 손으로
  전부 펼치진 않았으므로 "불확실"에 가깝다 — 필요하면 다음 세션이 재확인).
- **단건 `Attribute`(named) × Slot** — 배열 파트가 아니라 Length/Offset 시스템과
  애초에 무관(`H-39`의 대상이 아님).

### `reference/` · `archive/` · 로드맵
- `reference/epoch-brand-composition.md`/`slot-attach-decomposition.md` — 둘 다
  상단 배너로 "근거 기록, 정본은 `base/`"를 명시하고, 본문의 옛 서술도 의도된
  역사 기록임을 `base/` 대조로 확인.
- `slot-attach-decomposition.md`가 열어둔 "prepare만 하고 mount 안 한 중간 상태"는
  `base/slot-plan.md`가 이미 인용하며 열린 채로 주석 처리 — 추적 누락 아님.
- `archive/`의 최근 역전 문서 7종 전부 살아있는 `base/`가 정확히 반영·포인팅.
  특히 두 dedup 역전 문서는 **서로 다른 역전임을 상호 명시**해 혼동을 자체 차단.
- `question.md` ↔ `todos.md` ↔ `HUMAN_TODO.md` ↔ `ROADMAP.md`의 번호·상태
  상호 참조는 정확히 맞물린다(`H-49`/`H-51`의 두 문장만 예외).
- `ROADMAP.md` M2 체크박스(`Brand`/`EpochMap`/`Gate`+`GateNode`/`Blocker`/`None`)는
  최근 확정 문서와 정합. M6의 `attachSlot` 분해가 체크박스가 아닌 것은
  "확정된 것 — 코드 아님" 관례에 따른 정상.

### 그 밖에
- **`Effect`의 `EpochMap` dedup이 실제로 성립한다** — `state-epoch-plan.md`가
  *"뒤로 emit (**받은 `from`을 그대로 넘긴다**)"*로 확정해뒀으므로, `A→b`,
  `A→c`, `Effect(fn,b,c)`에서 두 내부 Observer가 **같은 `from`(=A)**을 받아
  두 번째가 규칙대로 접힌다. `Update`가 처음 보는 `Epoch`엔 `true`를 주므로
  첫 파동도 정상. (3차 패스가 "확인만" 했던 것을 이번에 `from` 전파 규칙까지
  따라가 닫았다.)
- **`Blocker`의 "중첩마다 별도 인스턴스" 규칙이 실제 코드 경로와 맞는다** —
  `materializeSlotTree`가 `getBlocker(slot)`로 **그 Slot 자신의 키**로 만들고,
  중첩 자식은 재귀에서 자기 키로 또 만든다. 부모 Blocker 재사용 경로가 없다.
- **`architecture.md`의 Store/State/Source 온톨로지 요약**이 2026-08-21 `Epoch`
  갱신까지 반영돼 있어 `source-state-plan.md`/`state-epoch-plan.md`와 어긋나지 않는다.

---

## 4차 패스 회신 방법

1~3차와 같다 — **"맞다/아니다"만 주면 그대로 반영**하겠다. 갈래 선택이
필요한 것:

- **`H-39`** — 네 핸들러에 등록을 추가하는 건 확정 계약대로라 판단이 필요
  없는데, **`AttributeGroupHandler`만 층위 질문**이 남는다(그냥 똑같이 등록 /
  Tag·Attribute를 Length/Offset 비참여 카테고리로 재정의). **이게 이번 패스에서
  가장 급하다** — M2 디스패치 코어가 그대로 이 계약 위에 선다.
- **`H-40`** — 빠진 가드 넷을 다 넣는 건 정정이지만, **`Tween` 같은 값 타입을
  블랙리스트에 계속 더할지 화이트리스트로 뒤집을지**는 결정이다(base가 `T`를
  모른다는 기존 입장과 충돌).
- **`H-42`** — 세 갈래 중 하나. 그리고 **그 뒤의 진짜 질문**(Deferred가
  표준이 되어가는데 `PreRef`/`PostRef`/pre-pass 구조를 유지할 가치가 있는가)에
  대한 방향도 같이 주면 좋겠다.
- **`H-52`** — 가드를 대칭적으로 추가할지, 경로가 없으니 둘지.
- **`H-46`** — top-level `Slot.luau`를 만들지, `Dispatch/Slot.luau`에 합칠지.

나머지(`H-41`/`H-43`/`H-44`/`H-45`/`H-47`~`H-51`/`H-53`/`H-54`)는 확인만
해주면 바로 반영 가능하다. **묶어서 고치면 싼 것**: `H-28`+`H-43`(둘 다
`dispose`), `H-34`+`H-44`(둘 다 `native*` 계약), `H-18`+`H-45`(같은 결정),
`H-33`+`H-49`(둘 다 `Gate`의 `Flush`/`Cancel` 표면), `H-11`+`H-50`.
반영은 이 파일이 아니라 각 `base/` 문서에 하고, 처리 결과는 1~3차와 묶어
`-followup.md`에 쌓는다.
