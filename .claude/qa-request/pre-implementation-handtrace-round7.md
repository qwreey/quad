# 구현 전 손 트레이싱 **7라운드** — M2(반응형 코어) 범위 + M2→M3 경계

**상태**: **[2026-08-25] 발견 보고 — 아무것도 반영하지 않았다.** 판정은
사용자가 이 목록을 보고 한다. 6라운드까지의 결정은 뒤집지 않는 것을
기본으로 했고, 뒤집어야 한다고 보는 항목은 **그 근거의 어느 추론이
틀렸는지**를 항목 안에 지목했다. 결정이 나면 `-followup.md`를 새로 만들고
`base/`에 반영할 것(6라운드와 같은 절차).

**왜 이 라운드가 있는가**: 사용자 요청 — *"M2(반응형 코어) 구현 착수
직전이다. 여기서 놓친 설계 결함은 구현 한참 뒤에 터지고, 그때는 M2/M3를
다시 짜는 비용이 된다."* 6라운드가 쓴 각도(문서 간 정합성, 의사코드 손
트레이싱, 인덱스 레이어, `doc-check.py`)와 **겹치지 않는 것**을 찾으라는
지시였다.

**이번에 쓴 각도(6라운드와 다른 것)**:
1. **M2 프리미티브 사이의 *호출 순서*를 실제 시간축으로 돌리기** — 생성자
   시점 / 바인드 시점 / 전파 시점 / 파괴 시점에 각 계약이 무엇을 요구하는지
   겹쳐 보기(6라운드는 함수 하나의 본문을 위주로 봤다).
2. **정책(policy)이 값으로 분리된 뒤의 권한 경계** — `H-33`/`H-49`로
   `Blocker`가 `blocker:Policy(emit)` 값이 된 뒤, 정책이 **손에 쥔 것만으로**
   자기 계약을 이행할 수 있는가.
3. **한 계약이 두 진입 경로를 갖는 자리**(leaf 바인드 vs `:Subscribe()`, 값
   교체 vs 포탈 언마운트)에서 **한쪽만 배선된 것**.
4. **"같은 것"을 두 문서가 다른 말로 부르는 자리** — 구독자 집합의 원소,
   구독 엣지의 등록 시점.

**범위**: `base/source-state-plan.md` / `state-epoch-plan.md` / `store-plan.md` /
`gate-plan.md` / `blocker-plan.md` / `effect-plan.md` / `lifecycle-pattern.md` /
`brand-plan.md` / `relate-plan.md` / `ref-plan.md`(Callbacks·`:Set`) /
`debounce-throttle-plan.md`(7절 배너) / `typing-limits.md`(영향 범위 표) /
`ROADMAP.md` M2 / `slot-plan.md`의 `_detachCleanup`·`unmountSlotTree`·
`destroySlotTree` / `dispatch-core-plan.md`의 `setLength`·`StoreBind.process`
(M2가 M3에 넘기는 `Observer`/`bindLifetime` 표면). 6라운드 followup은
전부 읽었고, 6라운드 본문과 이전 라운드·`session/`은 인용된 자리만 부분
확인했다.

**검사 대상이 아닌 것**(사용자 지시): `question.md` 최우선 두 항목(중간 State
GC 실측, `store:GetDynamic` 위치)에서 파생되는 것. 아래에서 그 항목과 닿는
지점은 "이건 그 미해결과 별개다"라고만 적었다.

**읽는 순서**: 🔴 다섯이 그대로 구현하면 동작이 어긋나는 것, 🟡은 정의가
비어 있거나 두 서술이 갈려 M2 구현자가 임의로 정하게 되는 것, 🟢은 문서
정합·구현 시 정하면 되는 것. "미확정" 표시는 트레이싱으로 확신까지 못 간
의심이다.

| 번호 | 심각도 | 한 줄 | 주 대상 | 성격 |
|---|---|---|---|---|
| `H-55` | 🔴 | `setup(emit)` 하나만 쥔 정책은 `OffWithoutEmit`/`Cancel`/`Trailing=false`가 요구하는 "흡수 집합 버리기"를 할 수 없다 | `gate-plan.md` 4·5, `blocker-plan.md`, `debounce-throttle-plan.md` 7절 | M2 착수 전 |
| `H-56` | 🔴 | 전파 루프 의사코드가 없고, 있는 서술대로면 자식 State 구독자가 `canExecute`에 걸려 State→State 전파가 전면 중단 | `lifecycle-pattern.md` (4), `source-state-plan.md` | M2 착수 전 |
| `H-57` | 🔴 | `State<Effect>` 값 교체(retract) 경로에서 옛 `Effect`의 cleanup이 영영 안 불린다 | `effect-plan.md` `H-11` 절, `source-state-plan.md` leaf dedup 절 | M2/M3 경계 |
| `H-58` | 🔴 | `_bindDestroying`의 `Ref` 콜백 (재)등록이 `:Callback`의 "등록 즉시 1회 호출"에 걸려 **바인드마다 `Rerun`**이 돈다 | `effect-plan.md`, `ref-plan.md`, `lifecycle-pattern.md` (1) | M2 |
| `H-59` | 🔴 | `Effect(fn, ref):Subscribe()`는 `Ref` 콜백을 아무도 안 걸어 영구 무동작 — "handle 자신을 등록하는가"가 구현 세부로 남은 것이 이제 load-bearing | `effect-plan.md` | M2 |
| `H-60` | 🟡 | `EffectHandle:Rerun()`이 공개 표면(`self:Rerun()`)인데 정의가 없다 | `effect-plan.md`, `ROADMAP.md` M2 | M2 |
| `H-61` | 🟡 | 인자 없는 `state:Observer()`가 "no-op 콜백"이면 `Get()`을 안 부르므로 명시된 용도(재계산 강제)를 못 한다 | `source-state-plan.md` | M2 |
| `H-62` | 🟡 | 구독 엣지 등록 시점이 "관측될 때"(lazy)와 "생성 즉시"(eager)로 갈려 있고, lazy면 `Get()` 안 하는 Observer 계약이 깨진다 | `source-state-plan.md` 두 절 | M2 착수 전 |
| `H-63` | 🟡 | `Blocker`의 onunblock "weak 배열" — 구멍/순회/강참조 주체 셋 다 미정, `Policy(emit)` 분리 후 핸들이 GC되면 `Off()`가 조용히 no-op | `blocker-plan.md`, `gate-plan.md` 5 | M2 |
| `H-64` | 🟡 | 포탈 언마운트 구간의 dep 변경 캐치업이 dep 종류에 따라 갈린다(State는 안 하고 `Ref`는 `H-58`의 부작용으로 함) — **미확정** | `effect-plan.md` | 계약 결정 |
| `H-65` | 🟡 | 죽은 바인딩 재사용 허용 + mount-only `Effect(fn)`: 첫 Destroying 뒤 재바인드하면 `fn` 재실행 없이 inert — **미확정** | `lifecycle-pattern.md` (3), `effect-plan.md` | 계약 결정 |
| `H-66` | 🟢 | `typing-limits.md` 영향 범위 표의 `state:Observer(fn)` 행이 "`EffectHandle` 반환" | `typing-limits.md` | 문서 정합 |
| `H-67` | 🟢 | `gate-plan.md` 4번이 `OffWithoutEmit` 비우기의 근거로 `Dispatch.drive`를 드는데 그 용례는 gated state를 안 쓴다 | `gate-plan.md`, `blocker-plan.md` | 문서 정합 |
| `H-68` | 🟢 | `Source:Set(v)`가 현재값과 같을 때 리비전 갱신/emit 여부가 어디에도 없다 | `source-state-plan.md`, `state-epoch-plan.md` | 구현 시 정하면 |
| `H-69` | 🟢 | 통과 모드 게이트가 emit마다 weak 테이블을 하나씩 할당한다 | `gate-plan.md` 4 | 구현 시 정하면 |
| `H-70` | 🟢 | `Effect(fn, ...deps)`의 deps 검증·`nil` 구멍·같은 `Ref` 중복이 미정 | `effect-plan.md` | 구현 시 정하면 |

---

## 🔴 `H-55` — `setup(emit)` 하나만 쥔 정책은 흡수 집합을 **버릴** 수 없다

**어디**: `base/gate-plan.md` 4번("emit 없이 푸는 경로는 집합을 *버려야*
한다")과 5번(`blocker:Policy(emit) -> onUpstreamEmit`, "`Trailing = false`는
`OffWithoutEmit()`, `Cancel`은 `b`를 캡처해 만든다"), `base/blocker-plan.md`의
"메커니즘"(`OffWithoutEmit`: "각 핸들이 자기 `HasBlockedEmit`은 그대로
리셋하되 실제 emit은 건너뜀") + "`HasBlockedEmit`은 게이트 흡수 집합의
특수형이다 — 두 개를 따로 들지 말 것", `base/debounce-throttle-plan.md`
7절 배너.

**무엇이 어긋나나**: 세 확정이 동시에 성립하지 않는다.

1. `setup: (emit: () -> ()) -> (() -> ())` — 정책이 노드에서 받는 건 **flush
   핸들 하나**뿐이고, `H-49`로 이 시그니처는 안 바뀐다고 재확정됐다.
2. `withheld`는 **노드**가 들고, 정책은 "노드가 정책이 뭘 하는지 들여다볼
   필요조차 없다"(4번). 반대 방향도 마찬가지 — 정책이 `withheld`에 닿는
   통로가 없다.
3. `OffWithoutEmit()`은 "밀린 전파를 **버리며** 끈다"이고, 4번은 그 경로가
   `withheld`를 **새 테이블로 스왑**해야 한다고 명시한다. `HasBlockedEmit`은
   `next(withheld) ~= nil`의 특수형이라 별도 플래그로 대체할 수도 없다.

`Blocker`가 노드 안의 특수 배선이던 2026-08-21 시점엔 (2)와 (3)이 같은
객체 안에 있어 성립했다. **`H-33`/`H-49`가 `Blocker`를 `Policy(emit)` 값으로
떼어내면서 (1)이 (3)을 막는다** — 정책이 손에 쥔 건 `emit`뿐이라
`OffWithoutEmit`의 onunblock 핸들이 할 수 있는 일은 "`emit()`을 안 부른다"
까지이고, 집합은 그대로 남는다.

**손 트레이스** — `Debounce{Leading = true, Trailing = false}`(문서가 정상
사용례로 드는 조합)를 `gated = d:Gate(...)`로, `d = a:With(b)`, 하류에 `Get()`
안 하는 Observer `O`:

```
t=0.00  a:Set r1   → gate 규칙1 → withheld{a} → 정책: idle → pass() → b off → flush {a} ✅
                     → b:On(), 창 열림
t=0.10  b:Set r7   → gate 규칙1 → withheld{b} → 정책: 창 안 → pass() → blocked (보류)
t=1.00  창 끝(Trailing=false) → b:OffWithoutEmit() → onunblock(emit=false): emit() 안 부름
                     withheld{b}는 **그대로** (정책이 비울 방법이 없음)
t=3.00  a:Set r2   → gate 규칙1 → withheld{a, b} → 정책: idle → pass() → flush {a, b}
                     → O 발화(정상) … 그리고 하류 중 b만 보는 노드 X가 규칙1로 무효화
                       → X의 Observer가 t=0.10의 변경에 대해 **지금** 운다
```

`Trailing = false`는 "창 안의 변경은 통지하지 않는다"인데 다음 버스트에
실려 나간다 — `gate-plan.md` 4번이 *"버리기로 했던 옛 원천들이 같이 실려
나가"*라고 경고한 바로 그 모양이 **정책 분리 때문에 되살아났다**. 같은
이유로 `Cancel`(= `OffWithoutEmit`)도 "타이머만 정리하고 보류분을 버림"이
아니라 "타이머만 정리"가 된다.

**`state:Block(b)` + `b:OffWithoutEmit()`**(공개 API)도 같은 경로다 —
`blocker-plan.md`가 확정한 "밀린 전파를 버리며 끈다"가 실제로는 "미룬다"가
된다.

**어느 추론이 틀렸나**: `H-49` 결정문의 *"`pending`은 Blocker의
`HasBlockedEmit`으로 흡수한다(중복 상태를 안 만든다)"*는 `HasBlockedEmit`이
Blocker 쪽에 실체로 있다고 전제하는데, 2026-08-21 확정(`blocker-plan.md`)은
그걸 **게이트 노드의 `withheld`로 흡수**해 Blocker 쪽엔 남겨두지 않았다.
두 흡수가 반대 방향이라 결과적으로 **아무도 안 들고 있다.**

**갈래(결정 전 목록)**: (a) `setup(emit, discard)`처럼 노드가 버리기 핸들을
하나 더 준다(시그니처 변경 — `H-49`의 "안 바뀐다"를 되짚어야 함), (b)
`emit`이 인자를 받아 `emit(false)`가 버리기가 된다(타입은 그대로
`(boolean?) -> ()`), (c) Blocker 정책이 자기 `HasBlockedEmit` 플래그를 따로
들고 노드의 집합은 남긴다 — 이건 위 트레이스의 늦은 통지를 그대로
허용하는 것이라 "버린다"가 아니게 됨. 어느 쪽이든 `blocker-plan.md`의
`두 개를 따로 들지 말 것` 문장과 `gate-plan.md` 4·5번, `debounce-throttle-plan.md`
7절 배너가 같이 움직여야 한다.

## 🔴 `H-56` — 전파 루프 의사코드가 없고, 있는 서술대로면 State→State 전파가 멈춘다

**어디**: `base/lifecycle-pattern.md` "(4) 실제 호출부"(*"State는 자기
구독자(Observer의 emit 클로저)를 weak로 담는다 … 발화 시 각 구독자에 대해
`canExecute(observer)`를 확인하고, 거짓이면 그 구독자만 조용히 건너뜀"*),
`base/source-state-plan.md`의 ":With도 새 State 노드로 확정"(*"이 노드는
Observer와 같은 패턴(외부 weak table)으로 상위 노드의 구독자 목록에
등록됨"*)과 "`state:Observer(fn)`" 절의 구현 노트(*"살아있는 Observer 집합을
… 외부 weak table `{[observer] = true}`"*), `ROADMAP.md` M2 "State 전파 루프"
체크박스.

**무엇이 어긋나나**: 세 서술을 겹치면 —

- `:With`/`:Compute`/`:Gate`가 만드는 **자식 State 노드**는 상위의 구독자
  집합에 "Observer와 같은 패턴"으로 들어간다.
- 전파 루프는 **각 구독자마다** `canExecute`를 본다.
- `canExecute(v) == isBoundAlive(v)`이고 `isBoundAlive`는 (a) `BindData`의
  gcconn, (b) `isObserver(v) or isEffect(v)`일 때 `.Subscribed` — **둘 다
  아니면 `false`**. 자식 State는 `bindLifetime`된 적도, `:Subscribe()`된 적도
  없다.

→ 그대로 짜면 `A:Set()`이 `A`의 Observer에게만 닿고 `A:With(...)`/`A:Compute(...)`
노드에는 **한 번도 닿지 않는다.** 파생 State 아래의 모든 Observer가 침묵한다.

**부수로 드러난 것 — 구독자 집합의 원소가 무엇인지 두 문서가 다르다.**
`lifecycle-pattern.md`는 *"Observer의 emit 클로저"*, `source-state-plan.md`는
*"`{[observer] = true}`"*(Observer **값**). `bindLifetime(inst, observer)`는
Observer 값을 키로 `BindData`에 gcconn을 복사하므로, 집합의 원소가
클로저면 `canExecute(클로저)`는 항상 거짓이다(다른 identity). 어느 쪽이든
루프가 "구독자 종류별로 무엇을 하는가"를 적은 코드가 코퍼스에 없다 —
`H-23`이 스냅샷을 확정했지만 그 스냅샷 안에서 **무엇을 호출하는지**는
여전히 산문뿐이다.

**이건 `question.md`의 "중간 State GC" 미해결과 별개다** — 그쪽은 자식
노드가 *살아남는가*, 이쪽은 살아있어도 *호출되는가*.

**필요한 것**: 전파 루프의 실제 의사코드 — 구독자가 State 노드면
`canExecute` 없이 `state-epoch-plan.md` §4의 수신 규칙으로, Observer면
`canExecute` 뒤 `fn(self, from)`으로 분기하는 형태(또는 두 집합을 따로
드는 형태). `H-23`의 스냅샷·`from` 전달·재진입까지 한 블록에.

## 🔴 `H-57` — `State<Effect>` 값 교체 경로에서 옛 `Effect`의 cleanup이 영영 안 불린다

**어디**: `base/effect-plan.md` "`Destroying` 바인딩을 누가 거는가"의 2번
(*"`unbindLifetime`은 cleanup을 부르지 않는다"*), `base/lifecycle-pattern.md`
(1)의 `unbindLifetime` 스케치, `base/source-state-plan.md` "Observer/Effect
Leaf dedup" 절의 retract 클로저(`if nextValue ~= v then unbindLifetime(v) …`).

**손 트레이스**: `Frame { effectState }`, `effectState = Source(E1)`,
`E1 = Effect(function() local t = startTimer(); return function() t:Stop() end end)`.

```
mount   → ObserverEffectLeafHandler.process → bindLifetime(frame, E1)
          → gchold, _bindDestroying(frame): Destroying 연결 ✅
effectState:Set(E2)
        → Dispatch.process (A) 분기 → retractor(E2): nextValue ~= v
          → unbindLifetime(E1) → _unbindDestroying(): Destroying 연결 해제, Ref 콜백 해제
            **E1._cleanup은 그대로** (2번 계약)
        → process(frame, k, E2): bindLifetime(frame, E2)
이후    → frame이 Destroy돼도 E1의 Destroying 연결은 이미 끊겨 있음
        → E1의 타이머는 영원히 돈다. E1 핸들 자체는 gchold에서 빠져 GC될 수
          있지만 타이머 콜백이 잡고 있으면 그것도 아님.
```

`H-11` 반영이 cleanup을 `unbindLifetime`에서 뺀 이유는 정당하다
(`destroySlotTree`가 `_detachCleanup`을 손으로 비운 뒤 unbind하는 경로의 이중
호출, 그리고 "포탈은 파괴가 아니다"). 하지만 그 결정은 **포탈 언마운트**만
봤고, `unbindLifetime`을 부르는 또 하나의 정상 경로 — **값 교체 retract** —
는 파괴에 준하는 것이다(그 `Effect`는 다시 안 온다). React로 치면
`useEffect` 클로저가 바뀌었는데 이전 cleanup을 안 부르는 것.

**어느 추론이 틀렸나**: followup D-4의 *"bind/unbind가 대칭이라 포탈이
자연히 성립한다"*는 unbind의 호출부가 포탈뿐이라고 가정했다. 호출부는
셋이다 — 포탈 언마운트(`unmountSlotTree`), 파괴 직전(`destroySlotTree`), 값
교체 retract(`ObserverEffectLeafHandler`/`setLength`). 앞의 둘은 cleanup을 안
불러도 되지만 셋째는 아니다.

**갈래**: (a) retract 클로저의 `nextValue ~= v` 분기가 `unbindLifetime(v)`
뒤에 `Effect`면 cleanup을 직접 부른다(`_cleanup`을 `nil`로 소진하는 헬퍼가
필요 — `Destroying` 클로저와 같은 것), (b) `unbindLifetime(value, teardown:
boolean?)`처럼 호출부가 의도를 넘긴다, (c) "값 교체는 cleanup을 안 부르는
게 계약"으로 못박고 문서화 — 이러면 `State<Effect>`는 사실상 쓸 수 없는
표면이 된다. `_cleanup = nil` 소진이 있으므로 (a)를 택해도 파괴 경로와의
이중 호출은 없다.

## 🔴 `H-58` — `_bindDestroying`의 `Ref` 콜백 (재)등록이 바인드마다 `Rerun`을 돌린다

**어디**: `base/effect-plan.md`의 `EffectHandle:_bindDestroying` 의사코드
(`for _, ref in ipairs(self._refDeps) do … ref:Callback(cb) end`),
`base/ref-plan.md` "API 모양"(*"콜백은 이미 채워져 있으면 등록 즉시 그 값으로
1회 호출됨 — nil/미설정 상태여도 그 상태 그대로 호출"*),
`base/lifecycle-pattern.md` (1)의 `bindLifetime`(gchold → `BindData` 복사 →
**그 다음** `isEffect`면 `_bindDestroying`).

**손 트레이스**: `E = Effect(fn, someRef)`, `Frame { E }`.

```
Effect(fn, someRef)      → _installing=true → (State dep 없음) → _installing=false
                         → fn(E) 1회 실행, _cleanup 저장         ← 설치 ✅
Frame 생성 → leaf 매치   → bindLifetime(frame, E)
   gchold[E]=true, BindData(E).gcconn = frame의 gcconn   ← 이 시점부터 canExecute(E) == true
   isEffect(E) → E:_bindDestroying(frame)
      someRef:Callback(cb) → 등록 즉시 cb(someRef.Value) 호출
         cb: canExecute(E) → true → E:Rerun()
            → _cleanup() 실행, fn(E) 다시 실행               ← 설치 직후 **두 번째 실행**
```

`Ref` dep이 N개면 첫 바인드에서 `Rerun`이 N번, 포탈 재마운트마다 또 N번
돈다. `_installing` 플래그는 생성자 구간만 덮고 이 자리는 안 덮는다.
`ref-plan.md`의 즉시 호출 계약은 `Ref(default):Callback(fn)` 관용구를 위한
것이라 그 자체는 맞지만, `_bindDestroying`이 그 계약 위에 올라탔다는 걸
어느 쪽도 안 적어뒀다.

**같이 봐야 할 반대 면**: `Ref` dep의 구독은 **바인드 전엔 아예 없다**
(`_bindDestroying`에서만 등록). 그런데 `Ref`가 채워지는 정상 시점이 바로
생성~바인드 사이다(같은 트리의 `Ref` leaf가 dispatch되며 `:Set`). 그
변경은 콜백이 없어 누락되고, 위 즉시 호출이 **우연히** 그걸 캐치업한다 —
즉 이 이중 실행은 지금 구조에서 정확성의 일부이기도 하다. 그래서
"즉시 호출을 `_installing`류 플래그로 누른다"만으로는 안 닫힌다.

**갈래**: (a) `Ref` 콜백도 생성자에서 등록하고(State dep과 대칭 —
`canExecute(E)`가 바인드 전엔 거짓이라 발화는 어차피 안 됨) 바인드 시점엔
재등록하지 않는다(그러면 포탈 unbind에서 왜 콜백을 떼는지부터 다시 봐야
함 — `H-7`의 누수 논거는 `canExecute` 게이팅이 추가되며 약해졌다), (b)
`_bindDestroying`이 등록 구간 동안 억제 플래그를 세우고, 바인드 직후 **한
번** 캐치업 `Rerun`을 명시적으로 돈다(이러면 `Ref` dep 유무와 무관하게
바인드가 곧 재실행이 되어 `H-64`와 같이 정해야 함), (c) `Ref:Callback`에
즉시 호출을 끄는 변형을 둔다.

## 🔴 `H-59` — `Effect(fn, ref):Subscribe()`는 영구 무동작이다

**어디**: `base/effect-plan.md` "`EffectHandle:Subscribe()`/`:Unsubscribe()`"
(*"강참조 레지스트리에 자신(또는 `state` 있는 경우 내부 Observer)을 등록"*,
*"`handle` 자신 + `handle._observers` 전부, 또는 `handle._observers`만으로
충분한지는 구현 세부"*), `_bindDestroying(inst)` 의사코드(`Ref` 콜백 등록이
여기 **만** 있음), `base/ref-plan.md` `H-7` 항목(*"`EffectHandle`은 …
`unbindLifetime`과 `:Unsubscribe()`에서 `:Uncallback`한다"*).

**무엇이 어긋나나**:

1. `Ref` 콜백을 거는 코드는 `_bindDestroying(inst)`뿐이고, `:Subscribe()`엔
   `inst`가 없어 그걸 못 부른다. `:Unsubscribe()`가 떼는 콜백은 **건 적이
   없는 것**이다.
2. 그 콜백 본문은 `canExecute(handle)`을 본다. "`_observers`만 등록해도
   충분한가"를 구현 세부로 두면 `handle.Subscribed`가 안 세워지고
   `canExecute(handle)`은 영원히 거짓 — `Ref` 경로가 열려 있어도 발화하지
   않는다.
3. `Effect(fn):Subscribe()`(deps 없음)는 `_observers`가 비어 있어 위 "또는"
   해석에선 **아무것도 레지스트리에 안 들어간다** → 핸들이 GC 가능 →
   `:Unsubscribe()`할 대상이 사라지고 cleanup이 안 불린다. Observer 쪽
   확정(*"`state:Observer(fn):Subscribe()`처럼 참조를 아무 데도 안 담아도
   정상"*)이 Effect엔 성립하지 않는다.

2026-08-07엔 "구현 세부"가 맞았다 — 그땐 `Ref` dep도 `canExecute(handle)`
게이트도 없었다. `H-7`/`H-11`이 둘 다 **핸들 자신**의 생존 판정에 의존하는
배선을 추가하면서 이 선택이 계약이 됐다.

**필요한 것**: `:Subscribe()`가 (a) `handle.Subscribed = true` + 레지스트리에
핸들 자신 등록, (b) `_observers` 각각 `:Subscribe()`, (c) `Ref` 콜백 등록 —
셋을 다 한다고 못박고, `_bindDestroying`에서 `Ref` 등록 부분을 떼어 두
진입점이 공유하는 헬퍼로 두는 것(`H-58`의 갈래 (a)와 같은 자리).

## 🟡 `H-60` — `EffectHandle:Rerun()`이 정의 없이 쓰인다

**어디**: `base/effect-plan.md` — `H-11` 절 3번(*"`Rerun`이 이미 직전
cleanup을 필요로 하므로"*), `_bindDestroying`의 `self:Rerun()`, `H-14` 절
(*"`fn` 안에서 `self:Rerun()`/`self:Unsubscribe()` 같은 핸들 표면에 바로
닿는다"*), `H-6` 절의 `handle:Rerun()   -- 직전 cleanup 호출 후 fn 재실행`.
`ROADMAP.md` M2의 "`Effect` 구현 시 같이 만들 것" 목록엔 `_observers`/
`_cleanup`/`_refDeps`/`_refCallbacks`/`_destroyConn`/`_bindDestroying`/
`_unbindDestroying`이 있고 **`Rerun`은 없다.**

**비어 있는 것**: 공개 메소드인지(`self:Rerun()`을 사용자 `fn`에 권하므로
공개), 시그니처, `_cleanup` 갱신 규칙(직전 cleanup 호출 → `nil` → `fn`
실행 → 반환값 저장 — 이 순서가 맞는지), **재진입** — `fn` 본문이
`self:Rerun()`을 부르면 `_cleanup`이 아직 저장 전이라 cleanup 없이 `fn`이
재귀 호출된다(무한 재귀는 UB로 둘 수 있지만 "첫 실행 중 호출"은 실수로
흔하다), `canExecute` 확인을 `Rerun` 안에서 하는지 호출부에서 하는지(지금
`Ref` 콜백은 호출부, Observer 경로는 전파 루프 — 사용자 직접 호출은
어디서도 안 봄).

## 🟡 `H-61` — 인자 없는 `state:Observer()`의 "no-op 콜백"은 재계산을 강제하지 못한다

**어디**: `base/source-state-plan.md` "`state:Observer(fn)`" 절 마지막
항목 — *"`fn`을 생략하면 내부적으로 no-op 콜백을 쓰는 것으로 취급해 …
그냥 이 State가 계속 재계산되게만 강제하고 싶을 때 씀"*, 그리고 그 용도의
출처인 "`previous`" 절의 캐비엇(*"능동적 관측 경로가 안 남아있으면
mutate 로직이 조용히 멈춘다"*).

**무엇이 어긋나나**: 전파는 push-invalidate/pull-recompute다. emit을 받는
Observer가 `:Get()`을 안 부르면 재계산은 일어나지 않는다(같은 절이 바로
위에서 *"값을 안 실어줌 — 반드시 `Get()`을 다시 해야 함"*이라 못박음).
no-op 콜백은 `:Get()`을 안 부르므로 이 유틸은 **아무것도 강제하지 않는다** —
`previous` 패턴의 State에 걸어도 mutate 로직은 그대로 멈춘다.

**필요한 것**: 내부 콜백을 `function(self) self:Get() end`로 명시(그러면
"항상 관측" 이름과 맞음), 또는 이 유틸의 용도 서술을 고침. `Epoch` 모델과
무관하고 옛 모델에서도 같았다 — 2026-08-07 서술이 처음부터 이랬다.

## 🟡 `H-62` — 구독 엣지의 등록 시점이 두 절에서 반대다

**어디**: `base/source-state-plan.md` "왜 State 체인을 Modifier처럼
플래튼하지 않는가"(*"살아있는 노드-대-노드 구독 엣지가 필요한 건 실제로
관측되는(`Get()`되는) State뿐 — 중간에 만들어놓고 아무도 안 보는 State는
구독 등록 자체가 안 일어남"*) vs 같은 문서 ":With도 새 State 노드로 확정"
(*"호출마다 self+주어진 인자들을 구독하는 새 State 노드를 만든다 … 상위
노드의 구독자 목록에 등록됨"*), `base/state-epoch-plan.md` §4 시딩(생성
시점에 `valueEpochMap`을 채움), `base/blocker-plan.md`(*"`state:Block(blocker)`
… 호출되는 즉시 onunblock 핸들을 등록"*).

**무엇이 어긋나나**: 앞의 절은 lazy(첫 `Get()` 때 엣지), 뒤의 셋은 eager
(생성 즉시 엣지)다. lazy면 —

```
B = A:With(x)                 -- 엣지 없음(아무도 B:Get() 안 함)
O = B:Observer(function() print("changed") end)   -- Get() 안 하는 Observer(허용된 사용법)
                              -- 등록 즉시 1회: "changed" (Get 안 함 → 여전히 엣지 없음)
A:Set(1)                      -- A의 구독자 집합에 B가 없음 → O 영구 침묵
```

"`Get()`을 안 하는 Observer는 매 변경마다 정확히 한 번 운다"(같은 문서,
`H-23` 위 항목)와 양립하지 않는다. `Epoch` 시딩도 생성 시점 엣지를 전제한다.
아마 2026-08-06 서술이 stale한 것이고 eager가 의도일 텐데, 그 절은
**"관리 부담이 작다"는 논거의 일부**로 lazy를 쓰고 있어서 그냥 지우면
논거가 약해진다 — 어느 쪽인지 명시가 필요하다. (eager라면 "중간 State
GC" 미해결이 더 절실해진다 — 상위가 하위를 weak로만 들면 엣지가 있어도
노드가 사라진다. 그 판단은 그 미해결 몫.)

## 🟡 `H-63` — `Blocker`의 onunblock "weak 배열"이 세 가지를 안 정한다

**어디**: `base/blocker-plan.md` "메커니즘"(*"onunblock 핸들을 blocker의 weak
배열에 등록"*, `Off()`: *"등록된 onunblock 핸들 전부 실행(순서 무관)"*),
`base/gate-plan.md` 5번(`blocker:Policy(emit)`이 값을 반환), `H-49` 결정문
(*"`Policy(emit)`을 부르는 시점에 onunblock 핸들이 등록"*).

1. **값-weak 배열은 순회가 깨진다.** `__mode = "v"` 배열에서 항목이 수거되면
   구멍이 생기고 `ipairs`는 첫 구멍에서 멈춘다(`#`도 border 미정) — 뒤의
   살아있는 게이트가 `Off()`를 못 받는다. `H-7`이 `Ref.Callbacks`를 배열에서
   해시맵 셋으로 바꾼 이유와 같은 문제인데 이쪽은 안 바뀌었다.
2. **누가 그 핸들을 강하게 드는가.** `state:Block(b)`가 노드 안 배선이던
   때는 gated state가 자기 필드로 들면 됐다. 지금은 `Policy(emit)`이
   `onUpstreamEmit`만 돌려주고, onunblock 핸들은 Blocker의 weak 배열에만
   들어간다. `Debounce`의 `setup`을 문서 그대로 짜면 —
   ```lua
   local b = Blocker(); local pass = b:Policy(emit)   -- onunblock 핸들: weak 배열에만 존재
   return function() …; pass() end                    -- pass는 그 핸들을 참조하지 않음
   ```
   다음 GC에서 핸들이 사라지고 `b:Off()`(창 끝)는 **조용히 아무것도 안
   한다** → 디바운스가 영영 안 나간다. "정책이 `pass` 클로저 안에 onunblock
   핸들을 upvalue로 잡아둔다"가 계약이어야 하는데 어디에도 없다.
3. **`Off()` 순회 중 새 등록.** `Off()` → 핸들 → flush → 하류 Observer가
   `state:Block(b)`를 새로 만들면(`Policy` 호출) 같은 테이블에 새 키가 들어간다
   — `H-23`이 실측한 미정의 순회. 스냅샷 규칙이 여기도 필요하다.

전부 "구현 시 정하면" 되는 것이지만, (2)는 안 정하면 실패가 **GC 타이밍에
따라 간헐적**이라 나중에 잡기 제일 어려운 종류다.

## 🟡 `H-64` — 포탈 언마운트 구간의 dep 변경 캐치업이 dep 종류에 따라 갈린다 (미확정)

**어디**: `base/effect-plan.md` `H-11` 절 2번(*"bind/unbind가 대칭이라
포탈이 자연히 성립한다 — 언마운트가 콜백을 떼고 재마운트의 `bindLifetime`이
다시 건다"*), `H-7` 절(`canExecute(handle)` 게이팅).

**손 트레이스**: `E = Effect(fn, s, r)`(State `s`, Ref `r`)가 포탈로 옮겨질 때.

```
unmountSlotTree → unbindLifetime(E) → Ref 콜백 해제, 내부 Observer unbind
언마운트 구간:
  s:Set(…)  → s의 전파 루프: canExecute(observer) 거짓 → skip
              E._epochs는 옛 리비전 그대로
  r:Set(…)  → 콜백 없음 → 아무 일 없음
재마운트  → bindLifetime(target2, E)
  → _bindDestroying: r:Callback(cb) 즉시 호출 → Rerun   ← r의 변경은 캐치업됨(H-58의 부작용)
  → s의 변경은 다음 s:Set까지 fn에 반영 안 됨            ← 캐치업 없음
```

`fn` 하나가 두 dep을 읽으므로 "r 때문에 Rerun된 fn"이 `s:Get()`도 같이
읽어 결과적으로 최신이 되긴 한다 — 단 **`Ref` dep이 하나라도 있을 때만**.
`Effect(fn, s)`만이면 재마운트 후 첫 `s:Set`까지 옛 부작용이 남는다. 포탈이
"파괴가 아니다"라면 언마운트 구간의 변경을 어떻게 볼지 — (a) 재마운트 시
무조건 1회 `Rerun`(`_epochs`도 그때 `Refresh`), (b) `_epochs:Refresh()`가
`true`일 때만, (c) 안 한다(계약으로 명시) — 중 하나를 정해야 하고, `H-58`의
갈래와 같이 정해야 한다(즉시 호출을 없애면 (a)/(b)가 필요해진다).

## 🟡 `H-65` — 죽은 바인딩 재사용 + mount-only `Effect(fn)`은 inert가 된다 (미확정)

**어디**: `base/lifecycle-pattern.md` (3) 부수 효과(*"바인딩이 죽은 뒤의
재사용은 허용 — `inst`가 Destroy됐거나 `unbindLifetime`된 `value`는 `canBound`가
참"*), `base/effect-plan.md` `_bindDestroying`의 Destroying 클로저
(`self._cleanup = nil` 소진).

```
E = Effect(fn)            → fn 1회, _cleanup 저장
Frame1 { E }; Frame1:Destroy() → Destroying → cleanup(), _cleanup = nil
Frame2 { E }              → canBound(E) 참 → bindLifetime OK → _bindDestroying
                          → fn은 다시 안 돌고 _cleanup도 없음 → Frame2가 죽어도 아무 일 없음
```

`Ref`의 재사용 허용은 값이 상태를 안 가져서 무해하지만, `Effect`는 "설치"
상태가 있다. 재바인드가 재설치인지(= `fn` 재실행), 금지인지(`isEffect`면
`_cleanup` 소진 뒤 `canBound` 거짓), 그냥 inert인지 — 명시가 없다.
`slot._detachCleanup`은 파괴 뒤 `nil`로 지우므로 이 경로를 안 탄다; 사용자
`Effect`만 해당.

## 🟢 `H-66` — `typing-limits.md` 영향 범위 표의 `state:Observer(fn)` 행

`| state:Observer(fn) | — | 해당 없음(로컬 제네릭 없음) | 해당 없음(EffectHandle 반환) |`
— `Observer`를 반환한다. 바로 윗줄 `Effect`와 복붙으로 섞인 것. 표만 고치면 됨.

## 🟢 `H-67` — `gate-plan.md` 4번의 `OffWithoutEmit` 근거가 잘못된 용례를 든다

*"안 그러면 `Dispatch.drive`의 배치 게이팅이 매 프레임 `On()` → … →
`OffWithoutEmit()`을 도는 동안 집합이 단조 증가하고"* — `base/blocker-plan.md`
"두 번째 용례"가 확정한 대로 `Dispatch.drive`/`setLength`의 게이팅은
`state:Block()`을 **안 부르고** `blocker:IsOn()`만 본다. gated 노드도
`withheld`도 없으니 그 경로에선 집합이 늘 수 없다. 결론("버리는 경로는
집합을 비운다")은 `state:Block` 사용자와 `Trailing = false` 때문에 여전히
유효하다 — `H-55`가 그 결론을 실제로 이행할 수 있는지를 묻는 것이고, 이
항목은 근거 문장만.

## 🟢 `H-68` — `Source:Set(v)`가 현재값과 같을 때의 동작이 어디에도 없다

`source-state-plan.md`/`state-epoch-plan.md`/`store-plan.md` 어디에도 `Set`이
`v == 현재값`이면 리비전을 안 올리는지(Fusion/Vide 관례) 무조건 올리는지가
없다. 어느 쪽이든 되지만 결정이 `:Emit()`의 존재 이유 서술과 얽힌다 —
동일성 스킵을 넣으면 `:Set(sameTable)`이 조용히 무시되므로 in-place mutate엔
`:Emit()`이 **필수**가 되고(지금 문서는 "편의"에 가깝게 적음), 안 넣으면
`:Set(sameTable)`도 전파되어 `:Emit()`이 사실상 `:Set(self:Get())`의 별칭이
된다. `Tween`처럼 매 프레임 `Set`하는 소스는 스킵 유무로 전파 비용이
달라진다. 구현 시 정하되 문서에 적을 것.

## 🟢 `H-69` — 통과 모드 게이트가 emit마다 weak 테이블을 할당한다

`gate-plan.md` 4번: 상류 emit이 오면 **무조건** `withheld`에 넣고 → 정책 →
`emit()` → flush 진입 시 `self._withheld = newWithheld()`(`setmetatable({},
{__mode="k"})`) 스왑. `Blocker`가 꺼져 있는 평상시엔 emit 하나당 테이블 하나 +
`setmetatable` 하나가 든다. `state:Block(b)`를 매 프레임 `Set`되는 Tween
소스 아래에 두면 프레임당 게이트 수만큼 할당이다. 정확성 문제는 아니다 —
"집합이 비어 있으면(= 방금 넣은 하나뿐이면) 스왑 대신 그 항목만 지운다"
같은 최적화는 `H-9`의 weak 유지 규칙과 충돌하지 않는다. 실측 후 정하면 됨.

## 🟢 `H-70` — `Effect(fn, ...deps)`의 deps 처리 세부가 비어 있다

- `Effect(fn, a, nil, b)`처럼 `nil`이 끼면 `{...}` + `ipairs`로 `_observers`/
  `_refDeps`를 만들 때 `b`가 조용히 빠진다(`select("#", ...)` 순회 필요).
  `nil` dep이 실수인지(에러) 허용인지(스킵) 미정.
- State/Source도 `Ref`도 아닌 값(Slot, 숫자, `None`)이 dep 자리에 오면 —
  무시인지 error인지 미정. `isInst`류 화이트리스트 결정(`H-40`)과 같은
  성격의 판단.
- 같은 `Ref`가 두 번 오면 `_refCallbacks[ref] = cb`가 덮어써져 먼저 건
  클로저는 `Ref.Callbacks`에 남는다(`:Uncallback`이 하나만 뗌). dedup을
  `Ref.Callbacks` 셋이 해주는 건 *같은 클로저*일 때뿐이다.

---

## 회신 방법

6라운드와 같다 — 항목 번호로 결정만 적어주면 `-followup.md`를 만들고
`base/`에 반영한다. 🔴 다섯 중 `H-55`/`H-58`/`H-59`는 같은 자리(정책·핸들이
"손에 쥔 것"만으로 계약을 이행할 수 있는가)에서 나온 것이라 같이 결정하는
편이 낫고, `H-57`/`H-64`/`H-65`는 "`unbindLifetime`이 cleanup을 안 부른다"
결정의 호출부별 예외 목록이라 한 번에 보는 게 낫다. `H-56`/`H-62`는 전파
루프 의사코드를 한 블록으로 쓰면 둘 다 닫힌다.
