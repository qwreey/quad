# 8라운드 손 트레이싱 발견 — **사용자 결정과 반영 결과**

**무엇인가**: `.claude/qa-request/pre-implementation-handtrace-round8.md`의
발견 17건(`H-107`~`H-123`, 3개 패스)을 사용자와 대화형으로 처리한 결과.
**결정의 소스는 이 문서**이고, 발견 원문·실측 전사·"이상 없다고 확인한 것"
목록은 그 파일이 소스다(여기서 다시 서술하지 않음).

**진행 방식**: 그 문서 §4가 배치 회신용으로 묶어둔 **결정 문항 Q1~Q10**
순서를 따랐다. 물어보기 전에 🔴 다섯의 핵심 주장(`Ref:Set` 블록에 `Revision`
갱신·Weak 순회 없음 / 전파 루프가 `sub.fn(sub, from)` / `CheckReserved`가 `T`를
통째로 받음)을 `base/`에서 직접 재확인했고 **전부 그대로였다.**

**[2026-08-26] 결정·반영 전부 완료.** 처분 요약:

| 처분 | 번호 |
|---|---|
| 확정 — `base/` 반영 | `H-107`~`H-113`, `H-117`~`H-123` |
| **문항이 틀렸음 — 심각도 강등** | `H-118`(🟡→🟢, 설계 결정이 아니라 문서 정합) |
| 정정만(판단 불필요) | `H-114`, `H-115`, `H-121`, `H-123` |
| 문서화 대상으로 등록(지금 결정 아님) | `H-116` |

**⭐ 사용자가 전제를 정정한 것 둘** — 이번 라운드의 실질적 소득이다:

1. **`Ref` 콜백과 Observer 콜백을 통합하려던 시각 자체가 틀렸다**(Q2-후속).
   *"observer 에는 epoch 란게 존재하지 않음. emit 으로 온 epoch 를 넘겨줄 뿐,
   그러나 ref 는 그 자체로 epoch임."* 그래서 `Effect`는 dep 종류별로 클로저를
   따로 단다 — `effect-plan.md`의 *"클로저는 하나로 통일한다"* 주석은 근거가
   없었고 삭제됐다.
2. **`H-118`은 "정책과 Blocker 중 누가 `emit`을 쥐는가"라는 소유권 문제가
   아니었다**(Q7). `setup(emit)`이 계약이라 `emit`은 정의상 정책 손에 있고,
   Blocker에 위임되는 것은 **"emit된 적 있던가"의 부기**뿐이다 — *"그 구현을
   나눠 쓰지 않기 위함일 뿐 아녔음?"*. 설계는 안 바뀌고 `gate-plan.md` 5번의
   **문장만** 틀렸다.

**새 표면·이름**: `Ref` 콜백 2번째 인자(`fn(value, ref)`) · Observer `fn`의
3-자리(`fn(targetState, self, emitFrom)`) · `observer._state` ·
`Ref.WeakCallbacks`(이름 신설) · `CheckReservedKeys<keyof<T>>` +
`__reservedCheck` 팬텀 필드 · Store 생성자의 `defaults` `isSource` 검증
**폐기**: `CheckReserved<T>`(`T`를 통째로 받는 배선) · `rawInvalid` 잔재 표기 ·
`_observers` 잔재 표기 · *"`Debounce`/`Throttle`은 `emit`을 아예 안 쥔다"*
**역전 없음** — 7라운드 확정 중 뒤집힌 것은 하나도 없다. 이번 라운드가 고친
건 전부 **7라운드 확정이 `base/`에 내려앉을 때 생긴 누락·충돌**이다.

---

## 🅐 `Effect`의 dep 발화 배선 — `H-107` · `H-108` (Q1, Q2-후속)

### `H-107` — `Ref` 콜백을 `k(value, self)`로 확장 **(확정)**

**결정: (a).** `Ref`의 일반 콜백은 이제 두 번째 인자로 **그 `Ref` 자신**을
받는다. `Ref`는 그 자체가 `Epoch`이므로 이게 곧 `Effect`가 필요로 하던
`from` 통로다.

- **왜 필요했나**: `Effect(fn, someRef)`에서 `ref:Set(v)` → `onDepFire`가
  `(_ = v, from = nil)`을 받는다. `EpochMap:Update`의 인자 계약은
  `Epoch | EpochSet`이라 `nil`이 올 자리가 없어 **`nil` 순회 크래시**,
  가드를 넣으면 **`Rerun`이 영영 안 돈다**(8라운드가 확정 의사코드 3개를
  그대로 전사해 실행, 크래시 재현).
- **비용은 `k(value)` → `k(value, self)` 한 자리**다. 기존 사용자 콜백
  (`function(inst) ... end`)은 두 번째 인자를 무시하면 그대로다.
- **기각**: (b) `Effect`가 `Ref` dep에만 래퍼 클로저 — 아래 Q2-후속으로
  "클로저 통일" 자체가 목표가 아니게 되면서 근거가 약해졌다. (c) `from == nil`을
  `Ref` 발화로 해석 — 설치 발화(등록 즉시 1회)도 `from == nil`이라 구분 불가.

**반영**: `base/ref-plan.md`(콜백 시그니처 항목 신설 + `:Set` 의사코드).

### `H-108` — `Ref:Set` 의사코드가 자기 반영을 못 받았던 것 **(확정, 갈래 없음)**

`H-53` 블록(2026-08-24 작성)이 하루 뒤 확정된 두 가지를 소급으로 못 받고
있었다. 갈래가 없어 문항으로 안 물었고 권고안을 그대로 반영했다:

1. **`Revision` 갱신 줄이 없었다** — 이 블록만 보고 짜면 `Effect`의 캐치업
   (`_epochs:Refresh()`)과 `Update(ref)` 판정이 전부 죽는다.
2. **Weak 콜백 테이블 순회가 없었다** — `.Callbacks`(강한 셋)만 돌아서,
   `Effect`가 건 `:WeakCallback`은 **한 번도 발화하지 않는다.**
3. **갱신 순서가 계약에 없었다** — 확정된 순서는 **값 → 리비전 → 콜백**.
   리비전이 콜백보다 뒤면 콜백 안의 `Update(ref)`가 옛 리비전을 읽어
   `false` → 그 `Set`의 `Rerun`이 접히고 다음 `Refresh()` 때에야 뒤늦게
   돈다(간헐 지연).

**부수로 이름 하나를 정했다** — 약한 콜백 테이블은 그때까지 *"`.Callbacks`와
별도 테이블"*로만 불렸는데, 의사코드가 순회해야 해서 **`.WeakCallbacks`**로
명명했다(`base/ref-plan.md`의 `:WeakCallback` 항목).

### Q2-후속 — 두 콜백은 **합치지 않는다** (확정)

Q1(a)로 `Ref` 콜백의 `from`이 2번째, Q2로 Observer의 `emitFrom`이 3번째가
되면서 "같은 `onDepFire` 하나"가 성립하지 않게 됐다. 정렬 방법을 물었더니
**사용자가 전제를 정정**했다 — 애초에 둘을 합치려던 게 아니다:

> *"Ref 의 callback 과 observer 의 콜백이 아주 헤테로지니어스한 개념이라,
> 둘을 전혀 합치고자 한 적 없고, 원 아이디어는 달랐음. 아주 중요한 부분이
> 있는데, observer 에는 epoch 란게 존재하지 않음. emit 으로 온 epoch 를
> 넘겨줄 뿐, 그러나 ref 는 그 자체로 epoch임. 처음부터 둘 처리를 묶어보는
> 시각 자체가 잘못되었는것."*

확정된 모양 — `Effect` 생성자가 dep 종류별로 클로저를 따로 단다:

```lua
local function fire(from) ... end                       -- 공통 본문
local function onRefFire(_, ref) fire(ref) end          -- Ref: 2번째가 출처
local function onStateFire(_, _, from) fire(from) end   -- Observer: 3번째가 출처
```

- **dedup은 클로저 identity가 하는 게 아니다** — `_deps`(중복 dep 무시)와
  `_epochs`(다이아몬드 판정)가 한다. 그래서 클로저를 나눠도 *"공통 상류를
  공유해도 한 파동에 `fn`은 한 번만"*이 그대로 성립한다.
- `effect-plan.md`의 *"⭐ 클로저는 **하나**로 통일한다"* 주석은 **삭제**했다.

**반영**: `base/effect-plan.md`(생성자 의사코드 + 주석 교체).

---

## 🅑 전파 루프의 self — `H-109` · `H-110` (Q2)

### `H-109` + `H-110` — Observer `fn`은 **세 자리**, 리시버는 강참조 **(확정)**

**결정: (a)의 사용자 수정판.** 문항의 (a)는 `sub.fn(sub._state, from)`
2-인자였는데, 사용자가 자리 하나를 더 요구했다:

> *"Ref 의 콜백과 같게 실 값이 앞에 놓이도록.
> `fn(targetState: state, self: observer, emitFrom: epoch|{epoch})` 구조가
> 되는게 좋아보임."*

확정된 자리 배치:

| 자리 | 무엇 | 왜 |
|---|---|---|
| 1 | `targetState` — 이 Observer가 붙은 State의 lazy 핸들 | 기존 계약 그대로. `:Compute`의 `fn(self, ...)`와 같은 모양 |
| 2 | `self` — Observer 값 자신 | 핸들 조작 |
| 3 | `emitFrom: Epoch \| EpochSet` | `EpochMap:Update(from)`에 그대로 |

전파 루프는 `sub.fn(sub._state, sub, from)`이 된다.

- **무엇이 깨져 있었나**: 루프 의사코드가 `sub.fn(sub, from)`으로 **Observer
  자신**을 self로 넘기는데 계약은 *"self는 리시버 State의 lazy 핸들"*이었다.
  그대로 짜면 `H-61`이 확정한 무인자 `state:Observer()`의 내부 콜백
  (`function(self) self:Get() end`)이 **"attempt to call missing method Get"**
  으로 즉사한다(Observer엔 `:Get()`이 없다). `Effect`의 `onDepFire`가 첫
  인자를 `_`로 버려서 7라운드 트레이싱이 이 충돌을 못 봤다.
- **`H-110`이 같은 결정으로 닫힌다** — 루프가 `sub._state`를 읽으므로
  Observer는 리시버를 **강하게 들어야** 하고, 그게 곧 Observer의 `_hold`
  상당이다. 그 전엔 `fn` 클로저의 **우연한 캡처** 말고 근거가 없었고,
  캡처가 없는 확정 사례가 이미 둘이었다(`H-61`의 내부 콜백, `Effect`의 dep
  콜백) — `:Subscribe()`의 공개 계약(*"GC되지 않고 영원히 계속 실행됨"*)이
  거기서 다시 열려 있었다.
- **기각**: (b) self=Observer를 정본으로 하고 `Observer:Get()` 델리게이션
  신설 — 표면이 늘고 Observer가 "State처럼 보이는" 새 혼동을 만든다.

**반영**: `base/source-state-plan.md`(전파 루프 절 · `state:Observer(fn)`
계약 절 · `H-61` 항목의 파라미터 이름 · `_hold` 불변식에 말단 핸들 추가).

---

## 🅒 `WeakSubscribe`와 `canExecute` — `H-111` (Q3)

**결정: (a) — `WeakSubscribe`도 `.Subscribed = true`를 세운다.** 강·약이
갈라지는 지점은 **레지스트리를 강하게 잡느냐뿐**이고 `.Subscribed`는 구독
경로 공용 플래그다.

- **무엇이 미정의였나**: `Effect`의 내부 Observer는 `WeakSubscribe`로만
  등록되는데, 전파 루프의 `canExecute(sub)`를 통과하려면 `isBoundAlive`가
  참이어야 한다 — gcconn 경로는 핸들에만 있으니 남는 판정 근거가
  `.Subscribed`뿐이다. **안 세운다고 읽으면 `Effect`의 State dep 전량이
  조용히 침묵한다.** 두 해석이 각각 다른 확정 문장에 뿌리를 두고 있어
  구현자가 어느 쪽을 골라도 "문서대로 했다"고 말할 수 있었다.
- 사용자 원문 *"구현이 한 벌"*과 (a)가 정합한다.
- **기각**: (b) 판정을 필드 대신 weak 레지스트리 멤버십으로 — 동작은 같지만
  해제가 양쪽 테이블을 지워야 하는 대칭 요구가 새로 생긴다.

**반영**: `base/source-state-plan.md`(`:WeakSubscribe()` 절) ·
`base/lifecycle-pattern.md`(`isBoundAlive` (b) 주석 + `Subscribe`/
`WeakSubscribe` 분해 의사코드 신설 + *"오직 전역 `:Subscribe()` 경로 전용
필드"* 문장 정정).

---

## 🅓 `CheckReserved`가 실사용 `T`에서 안 돈다 — `H-112` · `H-115` · `H-117` (Q4)

### `H-112` — 인자를 `keyof<T>`로 좁힌다 **(확정)**

**결정: (a).** 타입 함수는 `T`가 아니라 **키 싱글톤 유니온 `keyof<T>`**를
받고, 팬텀 필드 `__reservedCheck`로 격리한다.

- **무엇이 깨져 있었나**(실측 재현): 최종 Store의 `T`는 정의상
  `{hp: Source<number>, …}`이고, 확정 선언 스타일(§1②)에서 `Source<T>`는
  `Compute`의 `-> State<U>` 재귀 반환 누수 때문에 **내부에 `*error-type*`을
  품는다.** Luau 타입 함수는 그런 타입을 받는 순간 실패하므로,
  `CheckReserved<T>`를 어디에 배선하든 **예약 키가 없는 완전히 유효한 Store
  사용 지점 전부**에 `TypeError: Type functions do not currently support types
  of the form '*error-type*'`가 뜬다. 접근 경로 배선이면 거기 더해
  `does not have key 'hp'`로 필드 접근까지 전멸한다.
- **7라운드가 못 본 이유**: 그때 스파이크의 `T`가 **철회된 재설계의 스칼라
  필드**(`{hp: number}`)였다. 최종형에선 필드가 `Source<T>`다.
- **`keyof<T>`면 통과한다**(실측): `Source` 타입이 인자에 아예 안 실려
  직렬화 문제가 원천 소멸. 예약 키 진단이 **캐스트 지점과 생성자 호출 지점
  양쪽에서** 강제 평가 없이 뜨고, `store.hp:Get()` 양성 통과/음성 대조군
  정확히 걸림, **무주석 `:Compute` 콜백 추론 생존**.
- `base/typing-limits.md` §0(*타입 함수는 진단까지만*)의 허용 범위 안이다 —
  결과가 접근 타입에 안 섞인다(팬텀 필드 값은 `types.singleton(true)`).
  내장 `index<>`/`keyof<>`가 형제 필드의 `*error-type*`에 오염되지 않는다는
  것도 별도 실측(`CheckedQuad`)으로 재확인됐다.
- **기각**: (b) `CheckReserved` 포기(예약 키 충돌의 "조용히 꺼짐"을 감수),
  (c) 선언 스타일을 §1③(`typeof`)으로 전환(무주석 콜백 추론 포기 — 최종형
  실측 표의 약속과 어긋난다). **"콜백 추론 + 예약 키 진단" 동시 성립 배선은
  `T`를 통째로 넘기는 한 존재하지 않는다.**

**반영**: `base/store-plan.md`(타입 선언 + 통과 배선 + 기각 기록,
"예약 키는 `Of`/`Names` 둘뿐" 절의 옛 문구 정정) · `ROADMAP.md` M2 체크박스.

### `H-115` — 실측 표의 출처가 재현 불가 **(정정만)**

`store-plan.md`의 최종형 실측 표가 `audit/type-store-index-keyof/`를 출처로
인용하는데 **그 폴더에 최종형 결합을 도는 파일이 없다**(대부분 철회된
재설계 대상). 표의 측정값 자체는 8라운드 스파이크로 대체 재확인됐으므로
캐비엇을 달았고, **`STATUS.md`의 `16`/`21` 재작성 때 최종형 +
`CheckReservedKeys` 배선을 같이 넣으면 닫힌다**고 그쪽에도 적었다. 그
폴더의 `02`/`06`은 최종형에서도 유효한 측정이니 재작성 때 버리지 말 것.

### `H-117` — `store:Of("k")` 무인스턴스화는 틀린 주석도 통과시킨다 **(정정만)**

`Source<unknown>`은 아무 구체 타입 주석과도 충돌하지 않는다 — 실측에서
`local d: Source<boolean> = s:Of("dyn")`이 진단 0건으로 통과했다. *"`Of`는
타입 보장을 포기했다가 호출부에 드러나는 자리"*라는 확정 서술은 `<<T>>`를
실제로 적었을 때 얘기고, 빠뜨리면 조용히 unsound하다. 한 줄 보강.

---

## 🅔 `recompute`의 두 경계 — `H-113` · `H-119` (Q5, Q6)

둘 다 M3라 M2 착수를 막지 않지만, 같은 함수의 계약이라 같이 답했다.

### `H-113` — splice의 무효화는 `j`가 아니라 **`j - 1`** **(확정)**

**결정: (a).** 재개 지점은 `invalidAfter` 그대로 두고, 무효화만 되돌린다.

- **무엇이 깨져 있었나**: 루프가 매 반복 `bk.invalidAfter = i`를 쓰므로,
  `offset:Set(abs)` 도중 사용자 코드가 **커서 자리 i에서** splice하면
  `math.min(invalidAfter, i) = i` — **아무 일도 없던 것과 같은 값**이 된다.
  되감기 조건 `invalidAfter < i`가 거짓이라 재방문이 없고, 밀려 들어온
  요소의 offset `Source`는 이번 패스에서 `Set`을 못 받는다. 루프 끝의
  `bk.invalidAfter = bk.N`이 캐시를 "유효"로 마감하므로 다음 계기까지
  **그 요소만 옆으로 어긋난 레이아웃**이 남는다(`H-3`의 *"위로는 맞고
  옆으로만 틀린다"*와 같은 부류). `sum`은 안 낡는다 — 낡는 건 offset 하나다.
- **`j - 1`이면 닫힌다**: `j == i`면 `i-1`부터 되감고 `i`를 재방문한다(그
  자리 offset 쓰기는 `~=` 가드로 no-op). `j < i`도 한 자리 여분 재방문만.
  `prefix[j-1]`은 `1..j-2`의 합이라 splice와 무관하게 유효하다.
- `/code-review`가 한때 `j`로 바꾼 동기(재개 `+1` 폐기에 맞춘 쌍)는 재개가
  `invalidAfter`로 남는 한 `j-1`로도 안 깨진다.
- **기각**: (b) 되감기 신호를 별도 필드로 분리 — `H-101`의 *"새 필드를 안
  만든다"* 확정을 되짚는 쪽이라 비용이 더 크다.

**반영**: `base/dispatch-core-plan.md`(무효화 표의 splice 행 + 되감기 절).

### `H-119` — 명시 `recompute` 호출도 재진입 게이트를 탄다 **(확정)**

**결정: (a).** `raw*` 삭제 3형제와 `_baseObserver`의 직접 호출을 전부
`blocker:IsOn() or bk.recomputeBlocker:IsOn()`이면 건너뛰도록 통일한다.

- **무엇이 깨져 있었나**: `H-101`의 재진입 차단은 실체가 `gatedRecompute`
  안의 두 검사인데 **명시 호출 경로는 그걸 안 거친다**(`recompute` 자신은
  머리에서 `recomputeBlocker:On()`만 하고 재진입을 검사하지 않는다). 그래서
  대칭이 깨져 있었다 — **`Add`는 안전한데 `Remove`는 깨진다**:
  중첩 `recompute`가 완주하며 (1) `bk.invalidAfter = bk.N`으로 **바깥의
  되감기 신호를 지우고**, (2) `OffWithoutEmit()`으로 **바깥이 도는 중에
  차단기를 꺼버리고**, (3) 바깥이 자기 옛 `sum`으로 `Length:Set` — 중첩이
  이미 써둔 올바른 `Length`를 낡은 합으로 덮는다. `H-19`(명시 호출 예외,
  08-24)와 `H-101`(재진입 차단, 08-25)이 하루 차로 확정되며 서로를 못 봤다.
- **건너뛴 몫은 손실이 아니다** — `spliceArraysDown`/`invalidAfter = 0`이
  이미 당겨둔 신호로 바깥 루프의 되감기가 복구한다(`H-101` 설계 그대로,
  새 메커니즘 없음).
- **부수로 `_baseObserver` 콜백에 두 줄을 채웠다** — 배치 Blocker만 보던
  게이트에 `recomputeBlocker`를 더했고, `H-3`의 3번이 요구하는데 의사코드에
  없던 `bk.invalidAfter = 0`도 넣었다.
- **기각**: (b) `recompute` 머리에서 조기 반환 — *"명시 호출은 반드시
  돈다"*는 `H-19`의 표면 의미가 바뀌고, 되감기 신호 유지 요구는 어차피 같다.

**반영**: `base/dispatch-core-plan.md`(계약 신설) ·
`base/slot-plan.md`(`rawRemove`/`rawDetach`/`rawUnmount` 계열 3곳 +
`materializeSlotTree`의 `_baseObserver` 콜백).

---

## 🅕 `Debounce`/`Throttle` 정책 — `H-118` (Q7) — **문항이 틀렸다**

**결정: gate-plan 5번의 문장만 고친다. 설계는 안 바뀐다.**

문항은 *"정책과 Blocker 중 누가 `emit`을 쥐는가"*를 갈래로 세웠는데, 사용자가
그 프레이밍 자체를 되물었다:

> *"둘다 쥔다는 의미를 모르겠음. epoch|{epoch} 를 모아두는 부분은 gate 쪽이긴
> 한데(각각 본인껀 본인이 모아야하니까), emit 을 blocker 가 쥔다는건
> 정확하게는, 'emit 된 적 있던가?' 를 저장하기 위함 아님? 그 구현을 나눠 쓰지
> 않기 위함일 뿐 아녔음?"*

원문을 다시 읽으니 그대로다 — `setup(emit)`이 곧 계약이므로 **`emit`은
정의상 정책 손에 있고**, 정책은 그걸 `b:Policy(emit)`에 넘겨야 배선이
성립한다. 위임되는 건 `emit`이 아니라 **보류 부기(`HasBlockedEmit`)**이고,
`blocker:Policy` 표면의 존재 이유는 그 구현을 나눠 쓰지 않는 것이다.
따라서 `H-55`/`H-86`이 확정한 **타이머 경로의 `emit()`/`emit(false)` 직접
호출**과 5번의 위임 구조는 **충돌하지 않는다** — 경로가 둘이고 각자 몫이 있다:

| 경로 | 무엇을 부르나 |
|---|---|
| 상류 emit 도착(동기) | `pass()` — 보류 여부는 Blocker가 판정 |
| 타이머/제어 핸들(flush·버리기·조회) | `emit()` / `emit(false)`, 반환값도 씀 |

두 경로가 같은 파동에 겹쳐도 **빈 배치 얼리리턴**이 흡수한다.
그래서 `H-118`은 **🟡 계약 결정 → 🟢 문서 정합**으로 강등된다.

**반영**: `base/gate-plan.md` 5번(*"`emit`을 아예 안 쥔다"* 머리 문장을
*"보류 판정·`pending` 부기를 직접 구현하지 않는다"*로 교체 + 정정 배너 +
경로 표).

---

## 🅖 `Ref` 콜백의 즉시-nil 호출 — `H-120` (Q8)

**결정: (a) — 슈가/관용구에 nil 가드 래퍼.** `Ref` 계약은 안 건드린다.

- **무엇이 깨져 있었나**: `Ref` 콜백은 *"등록 즉시 1회 호출, nil/미설정이어도
  그대로"*가 계약인데, 코퍼스가 `Ref():Callback(fn)`을 children 배열
  관용구로, `OnCreated(fn) = PreRef():Callback(fn)`을 슈가로 배포한다.
  `fn`의 선언 타입은 non-nil `Instance`다 — 그래서
  `OnCreated(function(inst) inst.Name = "x" end)`은 **pre-pass에 도달하기도
  전에** "attempt to index nil"로 죽는다. `source-state-plan.md`가 이 조합을
  이미 *"사용자 실수"*로 분류해뒀는데, 정작 코퍼스가 자기 슈가로 그 실수를
  확정 패턴으로 배포하고 있었다.
- 훅 셋이 백로그(M8/순수 슈가)라 비용은 문서 정정 수준이다.
- **기각**: (b) 즉시 1회 호출을 "한 번이라도 `Set`된 뒤"로 좁힘(`Ref` 계약
  자체를 되짚어야 하고, "미설정 상태를 알고 싶어 콜백을 거는" 용례의 파급
  확인이 필요), (c) 문서 경고만(훅 슈가의 인체공학 약속과 어긋난다).

**반영**: `base/lifecycle-hooks-plan.md`(`guard` 래퍼를 확정 스케치에 +
children 배열 관용구 캐비엇) · `base/ref-plan.md`(콜백 계약 항목에 캐비엇).

---

## 🅗 `isModifier` 가드 자리와 Store defaults 검증 — `H-122` (Q9)

**결정: (a) — 가드를 `Source` 생성자로 옮기고, Store 생성자엔 `isSource`
화이트리스트 검증을 신설한다.**

- **무엇이 stale였나**: 세 문서(`modifier-plan.md` 7번 ·
  `source-state-plan.md` 따름정리 절 · `ROADMAP.md`의 `H-81` 체크박스)가
  가드 적용 지점으로 *"Store 생성 시 각 `defaults` 키를 `Source(v)`로 만드는
  시점"*을 지목하는데, **명시적 초기화 확정(2026-08-25) 이후 그 지점이 코드상
  존재하지 않는다** — Store는 `Source`를 만들지 않고 생성자는 `table.clone`뿐.
- **가드를 `Source` 생성자에 두면 defaults 경로가 자동 커버된다** — 독립
  `Source(someModifier)`와 한 자리로 수렴해 **목록이 오히려 짧아진다.**
- **defaults 런타임 검증은 새로 생긴다**: 타입은 `Source<T>` 필드를
  요구하지만 `--!nocheck`/동적 코드가 `{hp = 100}`(raw 값)을 넘기면 지금
  스케치는 조용히 받고 첫 `store.hp:Get()`에서 엉뚱한 에러로 죽는다.
  `H-40`이 `:List` 요소 검증을 화이트리스트로 뒤집은 것과 같은 성격이라
  여기도 화이트리스트를 둔다 — `isSource`가 거짓이면 `error(..., 2)`
  (사용자 입력 검증이므로 `level 2`, 메시지는 영어). 생성 시 1회라 hot path
  아님.
- **기각**: (b) 문구만 정정하고 타입 방어만 신뢰.

**반영**: `base/modifier-plan.md` 7번 · `base/source-state-plan.md` 따름정리
절 · `base/store-plan.md`(생성자 검증 항목 신설) · `ROADMAP.md`(`H-81`
체크박스 정정 + 검증 체크박스 신설) · `luau-test/STATUS.md`
(`done/11-modifier-illegal-value-error`가 eager `Source(v)` 모델을 박제한 채
"통과"로 앉아 있는 것을 `rewrite-required/` 대상으로 명시).

---

## 🅘 문서 정합 — 판단 불필요 (`H-114` · `H-121` · `H-123`)

### `H-114` — "하루 차 미반영" 둘

1. **`effect-plan.md`의 `H-11` 확정 목록 2번**이 `H-58` 이전 모델을 유지하고
   있었다(*"`Ref` 콜백도 같이 해제"* / *"언마운트가 콜백을 떼고 재마운트가
   다시 건다"*). `H-58`은 정반대로 확정했다 — **아무것도 안 뗀다.** 목록에
   정정 배너를 달고 뒤집힌 문장은 취소선 처리했다. 같은 파일의
   `_observers` 잔재 표기 세 곳도 같이 지웠다(`H-58` 이후 `Effect`엔
   `_observers`가 없고 `_deps` 하나다).
2. **`state-epoch-plan.md` §4 상단**의 구조체 선언과 수신 규칙이 폐기된
   `rawInvalid: boolean`으로 쓰여 있었다. `H-85` 절의 안내 문장이 *"아래 두
   절"*만 가리켰는데 **구조체는 그 절보다 위**라 위에서부터 읽으면 폐기된
   필드로 먼저 확정하게 된다. 구조체를 카운터 쌍으로 바꾸고 배너를 달았다.

### `H-121` — `slot-plan`의 대표 `updateFn` 예시가 크래시한다

`layoutOrder:With(offset):Compute(function(i, o) return i:Get() + o:Get() end)` —
확정 계약은 `fn(self, previous?, ...trailingDeps)`이고 **`:With`로 모은 값은
포지셔널로 안 넘어온다**(*"with한 값을 포지셔널 인자로 받지 않고 클로저로
직접 읽는다"*). 두 번째 자리에 실제로 오는 건 `previous`라 첫 사이클엔
`nil`(`o:Get()` 즉사), 이후엔 직전 결과 숫자(`number:Get()`으로 또 죽음).
클로저 읽기 형태로 교정했다. 이 예시는 `userdata`/`LayoutOrder` 관용구의
**정본 본보기**라 그대로 옮겨질 위험이 컸다.

**같은 배치로 `audit/type-recursion-issue/spikes/`의 `23`/`24`에 배너를
달았다** — 그 폴더는 "직접 다시 돌려 판정을 재현"하라고 남겨둔 것이라,
`slot-plan`만 고치면 나중 재실행이 옛 콜백 계약을 "재확인"하는 모양이 된다.
스파이크의 **측정값(타입 추론)은 그대로 유효**하므로 모델링은 안 건드리고
"이 호출 모양을 확정 관용구로 재인용하지 말 것"만 못박았다.

### `H-123` — 3차 문서 정합 묶음

1. **`project-setup-plan.md`의 리링크 서술이 `H-78` 이전이었다** —
   *"아직 반복 가능한 스크립트로 정식화하진 않음, 매번 수동 치환"*이라고
   안내하는데 `scripts/relink.sh` + `scripts/test.sh`가 이미 커밋돼 있다.
   "테스트는 `./scripts/test.sh`로 돌린다"로 교체했다.
2. **`pesde.lock`** → 아래 Q10.
3. **`:Single`의 2-인자 표기** — 절 제목과 본문 한 곳이 `(state, updateFn?)`
   인데 `H-22` 확정 의사코드는 `opts`(= `Owned`) 3번째 인자를 받는다. 둘 다
   `(state, updateFn?, opts?)`로 고쳤다.

### `H-116` — quad 두 벌 공존 (지금 결정할 일 아님)

패키지 매니저 생태계에서 두 라이브러리가 서로 다른 quad 버전을 끌어오는 건
예정된 미래인데, 그때 `Brand` 레지스트리·`None` 센티널·`Subscribed` 전역
테이블이 **모듈 사본마다 분리**된다 — 한 사본이 만든 값을 다른 사본에 넘기면
`isState`/`isObserver`가 거짓이 되어 요소 화이트리스트 검증(`H-40`)이
**정상 값을 이물로 판정**한다. 설계로 막을 일이 아니라 **문서화할 사실**이라
`research/documentation-content-map.md` §4에 항목 20번으로 등록했다.

---

## Q10 — `pesde.lock`은 커밋한다 (확정)

`project-setup-plan.md`가 *"미확정, 사용자 판단 필요"*로 열어두고
*"`todos.md`에 확인 필요 항목으로 반영"*이라 주장했는데 **그 반영이 실제로는
어디에도 없었다**(`question.md`/`todos.md`/`HUMAN_TODO.md` grep 0건). 실태는
lockfile이 이미 전부 커밋돼 있어 잠정 권고와 일치했고, 사용자가 현 실태대로
확정했다. 절 제목을 "커밋한다"로 바꾸고 "아직 확인 안 된 것" 목록에서 뺐다.

---

## 남은 것 / 안 한 것

- **8라운드 §6의 "남은 의심" 셋 중 둘은 이 라운드 결정으로 닫혔다** —
  `H-119`의 도달 조건 폭은 Q6 (a)가 게이트를 통일하므로 무관해졌고,
  §1③ 선언과 최종 Store 형태의 결합은 Q4 (a)로 당장 안 필요하다. 남은 것은
  **게이트 `emit(false)` 직후 다이아몬드 두 번째 경로 도착** 하나인데, 8라운드
  스스로 *"정책이 파동 도중 동기적으로 `emit(false)`를 부르는 경우가 실재하는지
  판단이 안 서서 발견으로 안 올렸다"*고 적은 항목이라 **여기서도 열지 않는다.**
- **8라운드 §6의 "못 본 것"은 그대로 유효하다** — 특히 **M5+ 구간(그룹
  `Attribute` 위임 체인, `D` 생성자, 숏핸드→`PropertyHandler` 위임,
  `:List` reconcile의 실제 값 대입)은 문서 정독 수준**이고 값 단위 트레이싱을
  안 했다. 다음 라운드가 있다면 거기가 최우선이다.
- **실측 스파이크**는 여전히 `luau-test/STATUS.md`가 소스다 — 이 라운드가
  거기에 항목 셋을 더했다(`11` 재작성, `16`/`21` 재작성 시 최종형 배선,
  `CheckedQuad` M2 후 재실측).

---

## 반영 후 검증 — 감사 11라운드 + `/code-review high` (2026-08-26)

**감사 루프**: `quad-doc-auditor` 11라운드(한 턴에 하나씩, 라운드마다 각도
변경), 발견 44건, **마지막 라운드 0건으로 수렴**. 상세와 교훈은
`session/2026-08-26-01-handtrace-round8-resolution.md`의 "감사 루프" 절.

**`/code-review high`**: 사용자가 직접 호출, **7건 전부 유효**했다. 감사자와
보는 축이 다르다는 게 다시 확인됐다 — 감사자는 코퍼스 정합성을, code-review는
**새로 쓴 서술 안의 결함**을 본다. 이번에 잡힌 것 중 셋은 감사 11라운드
어디에서도 안 나온 종류다:

| # | 심각도 | 무엇 | 처분 |
|---|---|---|---|
| 1 | **HIGH** | `recompute` 되감기가 `i = 0`으로 떨어져 크래시 | `math.max(bk.invalidAfter, 1)` 클램프 |
| 2 | MEDIUM | `H-113`의 `-1`이 splice에만 가고 `rawMove`/`rawSwap`류(`H-29` 규약 3번)엔 안 감 | 같은 처방으로 통일 |
| 3 | MEDIUM | `WeakUnsubscribe`가 강하게 구독된 값을 반쪽 해제 | **사용자 확정: error** |
| 4 | MEDIUM | *"Subscribe/Unsubscribe 둘 다 idempotent"*가 확정 의사코드의 `error`와 충돌 | **사용자 확정: error가 정본** |
| 5 | MEDIUM | `bk.recomputeBlocker`가 `getBookkeeping` 초기화 열거에 없음 | 열거에 추가 |
| 6 | LOW/MED | `keyof<{}>`(빈 Store) 미실측 | `STATUS.md`의 `16`/`21` 재작성 지침에 대조군 추가 |
| 7 | LOW | ROADMAP 배너가 바뀐 체크박스 개수를 소스 밖에 적음 | 개수 제거, 체크박스가 소스 |

**⭐ 1번은 이 라운드의 반영이 *만든* 결함이다** — `H-113`(splice 무효화를
`index - 1`로)과 `H-119`(`_baseObserver`에 `bk.invalidAfter = 0`)가 각각
독립적으로는 옳은데, **둘이 겹치면서 `invalidAfter`가 0이 될 수 있는 경로가
둘 생겼고** 되감기 블록은 클램프가 없었다. 결과는 `sum = prefix[0]`(nil) →
다음 반복에서 `sourceList[0]`이 nil → **부기가 멀쩡한데 "부기가 깨졌음"이라는
error로 죽는다.** 8라운드가 정확히 이런 "결정들이 겹칠 때" 결함을 찾는
라운드였는데, 그 라운드의 *처방*들이 겹쳐 같은 종류를 하나 더 만든 셈이다.

**3·4번은 계약 결정이라 사용자에게 물었다.** 둘 다 fail-fast 쪽으로 확정 —
`Subscribe`는 idempotent가 아니고(이미 구독/바인드된 값이면 error),
`WeakUnsubscribe`는 강한 킵이 남아 있으면 error다. **`Unsubscribe`만
idempotent이고 이 비대칭은 의도된 것**이라는 것도 같이 명문화했다.

### `/code-review high` **2차** — 7건 더, 전부 유효

1차 7건을 반영한 **직후** 사용자가 한 번 더 돌렸고 또 7건이 나왔다. **그중
넷이 1차 수정이 만든 것**이다 — 이 문서의 "고치는 과정이 새 결함을 만든다"가
다시 확인됐다.

| # | 심각도 | 무엇 | 처분 |
|---|---|---|---|
| 1 | **MED-HIGH** | `H-114`가 `_observers` → `_deps`로 **이름만** 고치는 바람에, `H-58`이 폐기한 *"`bindLifetime`이 내부 Observer로 cascade한다"* 동작 주장이 **갓 정비된 것처럼** 보이게 됨 | 배너로 거짓 명시 + 결론의 근거를 `isEffect` 훅으로 교체 |
| 2 | MEDIUM | 무효화 절의 머리 문장이 *"전부 같은 모양 — `math.min(inv, i)`"*인데 바로 아래 표는 `H-113` 이후 **세 가지 인덱스**를 규정 | 머리 문장 재작성, "표가 소스" 명시 |
| 3 | MED-LOW | `rawMove`/`rawSwap`류 무효화 규칙이 `slot-plan`에만 있고 `dispatch-core`의 표엔 행이 없음(그런데 `slot-plan`이 그 표를 "세 규칙"의 소스로 인용) | 표에 행 신설, 개수 서술 제거 |
| 4 | MED-LOW | 전파 루프 주석이 `-- Observer / Effect`인데 `_state`는 **Observer에만** 있음 | 주석 교정 + `Effect`가 내부 Observer를 통해 온다는 것 명문화 |
| 5 | MED-LOW | *"예약 키는 `Of`/`Names` 둘뿐"*이 같은 파일의 셋(+`__reservedCheck`)과 불일치(`ROADMAP`도) | 양쪽 셋으로 |
| 6 | LOW | `luau-test/README.md`의 `16` 재작성 지침이 아직 옛 `CheckReserved` | 이름·배선 갱신 + 빈 Store 대조군 |
| 7 | LOW | **⛔ 폐기 배너 아래 죽은 문단에 내가 `H-111` 날짜 마커를 찍어** 살아 있는 것처럼 보이게 함 | 마커 제거 |

**⭐ 1번과 7번이 이 라운드의 교훈이다** — 폐기된 서술을 만질 때
**이름만 고치거나 날짜 마커를 찍으면 오히려 해롭다.** 죽은 텍스트가 갓
정비된 것처럼 보여서, 위에서부터 읽는 구현자가 더 믿게 된다. 1번은 실제로
`H-58`이 막은 버그(바인드마다 `Rerun`)를 되살릴 수 있는 자리였다.
**폐기 블록은 배너만 달고 본문은 건드리지 않는 게 낫다.**

### `/code-review high` **3차** — 7건 더 (+minor 1), 전부 유효

2차 반영 직후 또 돌렸고 또 7건. **이번에도 대부분이 앞 두 차례 수정의 산물**이다.

| # | 심각도 | 무엇 | 처분 |
|---|---|---|---|
| 1 | MEDIUM | `typing-limits.md` §0이 이름은 `CheckReservedKeys`로 고쳐놓고 바로 뒤 문장은 *"둘 다 `T`를 검증만 하고 그대로 통과시키고"* — **양쪽 다 거짓**(인자도 반환도) | 재정정. §0이 "무엇이 합법적 타입 함수인가"의 소스라 그대로 읽으면 `H-112`가 실측한 실패 배선을 다시 도출 |
| 2 | MEDIUM | 무효화 표에 4번째 행(`rawMove`/`rawSwap`)만 넣고 **헤딩·산문·배치 목록은 "셋"** — 새 규칙이 *"표는 산문뿐이고 코드 경로가 없다"*(`H-3`)는 원래 상태로 되돌아감 | 헤딩·산문 정정 + 배치 목록에 4번 신설 |
| 3 | MEDIUM | `ROADMAP.md` M3 체크리스트도 같은 결함(**구현자가 실제로 보는 자리**) | 같은 처방 |
| 4 | MEDIUM | `Ref:Set`의 교차 dedup 근거를 *"thread를 두 번 resume"*이라 적었는데, 그러면 소진이 `.Callbacks`만 비우므로 **죽은 코루틴을 영원히 조용히 `resume`**하게 된다(`resume`은 죽은 스레드에 `false`를 돌려줌) | 실제 불변식(**대기자는 `.Callbacks`에만 산다** — `WeakWait`는 없다) 명문화, dedup은 **함수 키 전용** |
| 5 | LOW | `STATUS.md`가 `CheckedQuad` 재실측을 `rewrite-required/23`에 매달았는데 **거기 `23`이 없다**(`done/`에 통과 상태) — 안 일어날 재작성에 매달려 고아가 될 뻔 | 포인터 정정 |
| 6 | LOW | *"Store는 `Source`를 만들지 않는다"* 전제가 **거짓** — 동적 키 창구 `store:Of(name)`은 만든다. 세 곳에서 그게 옛 가드 자리를 지운 **이유**로 쓰임 | "`defaults` 경로에선"으로 정밀화(결론은 그대로 — `Source` 생성자 가드가 `Of`까지 커버) |
| 7 | LOW | `H-119`가 *"명시 호출부 **전부**"*라 했는데 `:List` 활성화 꼬리와 `mountSlotTree` 꼬리 **둘이 빠짐** | 같은 게이트 추가 |

*(minor: `H-119` 산문의 "`rawSplice`류"가 가리키는 함수가 없음 — 제거.)*

**⭐ 이 세 차례 code-review의 총평.** 21건이 나왔고 **절반 이상이 직전
수정의 산물**이었다. 반복된 실패 모드는 하나다 — **한 자리를 고치면서 그
자리를 요약·인용·정당화하는 이웃 문장을 같이 안 고침.** 표에 행만 넣고
헤딩의 개수를 안 고치거나(2·3번), 이름만 바꾸고 그 이름이 서술하던 동작을
그대로 두거나(2차 1번), 새 dedup의 *근거*를 잘못 적어 그 근거가 다른
불변식을 함의하게 만들거나(4번). **감사자는 이걸 못 잡는다** — 코퍼스
정합성이 아니라 **방금 쓴 문장 안의 논리**라서다.

### `/code-review high` **4차** — 6건, 그중 하나가 **`H-101` 역전**을 불렀다

| # | 심각도 | 무엇 | 처분 |
|---|---|---|---|
| 1 | **HIGH** | `getOffsetAt`의 꼬리가 `bk.invalidAfter`를 **올려서** splice가 낮춰둔 되감기 신호를 지운다 | **부기 필드를 둘로 분리**(아래) |
| 2 | LOW | `ROADMAP`의 전파 루프 사본 주석이 아직 `-- Observer / Effect` | 교정 |
| 3 | LOW | `lifecycle-hooks-plan` 본문 6곳이 아직 `Callback(fn)`(가드 없음) | 전부 `guard(fn)` |
| 4 | — | *(materialize 꼬리 게이트가 사후조건을 깬다)* — **기각.** `bk`는 그 Slot **자신의** 부기이고 `recomputeBlocker`는 같은 Slot의 `recompute` 중에만 켜지므로, 게이트가 발화하는 상황이면 **그 바깥 루프가 끝내 `Length`를 확정한다.** 리뷰가 든 *"`mountSlotTree`의 `acc`"* 근거도 어긋난 인용 — `slot.Offset`은 **부모의** `recompute`가 정한다 | 변경 없음 |
| 5 | MEDIUM | 다만 `Dispatch.drive` 꼬리와 일반 배치 계약은 **게이트가 아예 없다** — `raw*`와 같은 `H-119` 구멍 | Q6 결정대로 게이트 |
| 6 | LOW | `:Uncallback`이 *"`Callbacks[fn] = nil` 한 줄"* — 같은 파일이 두 테이블을 본다고 확정 | 두 테이블로 |

#### ⭐⭐⭐ `H-101`의 "새 필드를 안 만든다"가 역전됐다 — 부기 필드가 둘로

**사용자 진단**: *"캐시와 컴퓨팅 위치를 같이 둔 것이 폭탄이였는듯 … 지금의 큰
문제는, **Set을 해줬느냐**와 **캐시가 유효하지 않느냐**라는 다른 목적의 값을
같은 값이 쥐고 있음. 그것 자체가 문제였는듯."*

`H-101`은 *"두 뜻('캐시가 여기까지 유효'와 '여기 다음부터 다시 해야 함')이
**실제로 같은 것**이기 때문"* 새 필드를 안 만들기로 확정했었다. **그 전제가
틀렸다.**

| 필드 | 뜻 | 올리는 쪽 | 내리는 쪽 |
|---|---|---|---|
| `bk.offsetCacheValidUpTo` | `offsetCache`가 여기까지 정확 | `getOffsetAt` (**어디서 불리든**) | 무효화 사이트 전부 |
| `bk.offsetSetUpTo` | offset `Source`에 여기까지 `:Set` 완료 | **`recompute`만** | 무효화 사이트 전부 |

- **옛 이름 `invalidAfter`는 완전히 없앴다** — 그 이름이 두 뜻을 겸했던 게
  원인이라 남겨두면 읽는 쪽이 옛 의미를 그대로 가져온다. 이름은 **사용자
  확정**(`offsetCacheValidUpTo` + `offsetSetUpTo` — 어미를 맞춰 둘 다
  "여기까지 유효/완료"로 읽히게).
- **`getOffsetAt`이 캐시 마커를 올리는 건 어디서 불려도 안전하다** — 그 함수가
  실제로 캐시를 그 지점까지 정확히 채우고 나서 올리기 때문. 문제였던 건
  **Set 마커**가 `recompute` 밖에서 올라가는 것이었고, 이제 그건 불가능하다.
- **무효화는 둘 다 내린다** — 구조가 바뀌면 캐시도 낡고 `Set`도 다시 해야 한다.

**왜 여섯 라운드의 감사와 세 번의 code-review를 통과했나** — **한 프리미티브
*안*에서는 원래 안전했다.** `rawRemove`는 `getOffsetAt`을 `spliceArraysDown`
**앞**에서 부른다. 깨지려면 **한 콜백에서 CRUD를 두 번**(`Remove` 뒤 `Add`)
해야 하고, 두 번째의 `setOffsetSource`가 `getOffsetAt`을 부르며 신호를
되올린다. 사용자가 *"getOffsetAt 자체가 recompute를 내지 못해서 올리는 게
문제가 안 되는 것 아니냐"*고 되물어 재트레이싱한 끝에 이 2-연산 경로가 나왔다.

### `/code-review high` **5차** — 6건 (필드 분리 직후)

부기 필드 분리(40곳 넘는 치환)를 아무도 안 본 상태라 바로 돌렸다.

| # | 심각도 | 무엇 | 처분 |
|---|---|---|---|
| 1 | MEDIUM | 훅의 `guard(fn)`가 **1-인자** — 같은 라운드에 `Ref` 콜백이 2-인자가 됐는데 두 번째를 조용히 삼킨다. children 배열 관용구가 "위와 같은 가드"를 쓰라 하므로 `Epoch`를 쓰는 소비자가 `nil`을 받는다 | `function(v, r) … fn(v, r)` |
| 2 | MEDIUM | `_baseObserver`는 `bk`를 무가드로 쓰는데 형제 두 자리는 `if bk and …` — 같은 커밋 안에서 규약이 갈림 | **`getBookkeeping`은 lazy 생성이라 절대 nil이 아님**을 명문화하고 흔적 가드 제거 |
| 3 | MEDIUM | 새 무효화 행이 `H-29` 규약을 짝으로 지목했는데, 그 규약의 2번(*"`bk.N`은 안 변한다"*)이 **`rawSplice`/`rawClear`엔 거짓** — 그대로 짜면 `rawClear` 뒤 `recompute`가 끝을 넘어가 "부기가 깨졌음" error | 규약에 예외 명시 + 표 행의 범위 축소 |
| 4 | LOW/MED | `__reservedCheck`는 **런타임 대응물이 없다**(타입은 `true`, 런타임은 `nil`). `store:Names()`에도 안 들어가 `store:Of("__reservedCheck")`가 런타임엔 통과 | 캐비엇 둘 명문화 |
| 5 | LOW | `WeakUnsubscribe`만 fail-fast고 **반대 방향이 안 막힘** — 약하게만 구독된 값에 `Unsubscribe`가 조용히 성공해 `Effect`의 dep을 죽인다 | **사용자 확정: 대칭으로 막는다** — "해제는 건 경로로 푼다" |
| 6 | LOW | `bk.offsetSetUpTo = bk.N` 꼬리의 **근거**가 아직 *"캐시가 낡은 채로 유효 표시"* — 분리 뒤 이 꼬리는 캐시를 안 만진다 | 근거 재작성 |

**⭐ 6번이 이 세션에서 세 번째 같은 실수다** — **이름만 바꾸고 그 이름이
서술하던 근거는 그대로 둠**(`H-114`가 지적한 바로 그 실패 모드). 1차에선
`_observers` → `_deps`, 3차에선 `CheckReservedKeys`, 이번엔 `invalidAfter` →
`offsetSetUpTo`. **대규모 치환을 할 때는 치환된 토큰이 든 *문장 전체*를 다시
읽어야 한다** — 토큰만 맞추면 그 문장이 설명하던 불변식이 바뀐 걸 못 본다.

### `/code-review high` **6차** — 8건 (HIGH 3), **전부 5차 수정이 만든 것**

| # | 심각도 | 무엇 | 처분 |
|---|---|---|---|
| 1·2 | **HIGH** | 5차에 `Unsubscribe`에 대칭 가드를 넣어놓고, **같은 파일 몇 줄 아래의 *"`:Unsubscribe()`는 idempotent다 … 비대칭이 의도된 것"*을 안 지웠다**(두 문서 다). 산문대로 짜면 가드 없는 `Unsubscribe`가 나와 그 가드가 막으려던 침묵 살해가 그대로 | 두 곳 재정정 — 계약은 **"해제는 건 경로로 푼다"** 하나 |
| 3 | **HIGH** | 5차의 예외 목록이 `rawSplice`/`rawClear`만 빼고 **`rawExtract`를 빠뜨렸다** — `Extract(index)`는 `newElement` 생략 시 **자리 수가 준다**(CRUD 표). 규약대로 짜면 `bk.N`이 옛 개수로 남아 다음 `recompute`가 끝을 넘어가 "부기가 깨졌음" error | 조건부임을 명시(교체 형태는 그대로, 제거 형태는 splice 취급) |
| 4 | MEDIUM | `ROADMAP`의 `guard` 스케치가 아직 **1-인자** | 2-인자로 |
| 5 | MEDIUM | `guard`가 `fn(v, r)`로 부르는데 훅의 `fn`은 **1-인자로 선언** → `--!strict`에서 arity 에러 | 선언 타입을 2-인자로(Luau 함수 타입은 파라미터에 반변이라 사용자의 1-인자 람다는 그대로 통과) |
| 6·7 | MEDIUM | **대규모 치환이 *역사 인용문*까지 바꿨다** — `H-101`의 원문 인용이 `bk.offsetSetUpTo`(= 새 필드)로 바뀌어 *"새 필드를 안 만든다"*와 **자기모순**이 됐고, 같은 파일 절 참조도 제목과 어긋났다 | 인용·참조를 옛 이름으로 되돌림 |
| 8 | LOW | *"`if bk` 가드를 두지 말 것"* 규칙을 새로 세워놓고 **두 자리를 안 고쳐** 그 규칙이 지적한 불일치를 그대로 남김 | 제거 |

**⭐⭐ 이 라운드가 가장 선명한 교훈을 준다 — 나는 같은 실수를 네 번 했다.**
1차 `_observers` → `_deps`, 3차 `CheckReservedKeys`, 5차 `invalidAfter` →
`offsetSetUpTo`, 그리고 6차의 6·7번. **전부 "토큰을 바꾸고 그 토큰이 든 문장은
안 읽음"**이다. 6·7번은 한 걸음 더 나아가 **역사 기록까지 오염**시켰다 —
*"옛 이름을 완전히 없앴다"*는 내 선언이 정정 배너 안의 **인용문**에까지
적용돼, 폐기를 서술하는 문장이 자기가 폐기한 것의 새 이름을 쓰게 됐다.

**규칙으로 남긴다**: **전역 치환은 인용문·절 제목·정정 배너를 건드리면 안 된다.**
그 셋은 *과거에 무엇이라고 적혀 있었는가*를 보존하는 게 목적이라, 새 이름으로
바꾸는 순간 그 목적이 무너진다. 치환 전에 그 세 형태를 먼저 제외 목록에 넣을 것.

### `/code-review high` **7차** — 5건, **HIGH 0**

| # | 심각도 | 무엇 | 처분 |
|---|---|---|---|
| 1 | MEDIUM | `EffectHandle:Unsubscribe()`의 *"idempotent"* — **세 번째 사본**. 6차가 두 문서에서 지웠는데 이건 놓쳤다 | 정정(살아 있는 요구는 "cleanup 중복 호출 금지"뿐) |
| 2 | MEDIUM | `ROADMAP`의 M2 `state:Observer(fn)` 체크박스가 **`H-109`/`H-110` 미반영** — 3-슬롯 시그니처도 `observer._state`도 없다. 그 체크박스로 짜면 `sub._state`가 `nil`이라 **`H-109`가 고치려던 크래시가 그대로** | 시그니처·`_state`·`H-61` 파라미터 이름 반영 |
| 3 | LOW/MED | `for d in seen do` — **유효한 Luau가 아니다**(테이블을 호출하려 든다). `H-107`로 본문을 다시 쓴 바로 그 루프 | `pairs(seen)` |
| 4 | LOW | 요약 다이어그램이 **강한 셋 `Ref.Callbacks`를 약한 엣지로** 표기 — 그대로 읽으면 `Ref`가 `Effect`를 영원히 붙들어 `H-58`의 약한 설계가 죽는다 | `.WeakCallbacks`로 |
| 5 | LOW | 3차가 이미 거짓으로 판정한 *"Store는 `Source`를 만들지 않는다"*를 **새로 쓴 두 블록에 다시 넣었다** | "`defaults` 경로에선"으로 |

**추이**: HIGH 1 → MED-HIGH 1 → HIGH 0 → **HIGH 1(설계 역전)** → HIGH 0 →
**HIGH 3** → **HIGH 0**. 6차가 정점이었고(전부 5차 수정의 산물), 그 실패
모드를 명문화한 뒤의 7차는 HIGH가 없다.

**5번이 남은 패턴을 보여준다** — 한 곳에서 고친 사실이 **나중에 새로 쓰는
글에서 되살아난다.** 3차에 `modifier-plan`/`source-state-plan`/`ROADMAP`
세 곳을 고쳤는데, 5차에 `luau-test` 블록을 새로 쓰면서 그 거짓 전제를 다시
적었다. 고친 것을 기억하는 것과 **새로 쓸 때 그 기억을 적용하는 것**은 다른
일이다.

