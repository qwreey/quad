# 구현 전 손 트레이싱 **7라운드** — M2(반응형 코어) 범위 + M2→M3 경계

**구성**: **패스 3개, 발견 30건(`H-55`~`H-84`).** 1차 패스는 문서 대 문서
손 트레이싱(`H-55`~`H-70`), **2차 패스는 문서가 "확인했다"고 적은 주장을
실제로 `luau`/`luau-analyze`에 걸어본 실측**(`H-71`~`H-76`, 2026-08-25 추가),
**3차 패스는 (a) 실제로 커밋된 M1 코드·툴체인을 이 저장소에서 그대로 돌려본
것과 (b) 1·2차가 범위에서 뺐던 "M2를 *소비하는* 문서"**(`H-77`~`H-84`,
2026-08-25 추가). 발견 번호는 패스를 가로질러 이어서 매긴다(6라운드와 같은
방식).

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

**1차 패스에 쓴 각도(6라운드와 다른 것)**:
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

**1차 패스의 범위**: `base/source-state-plan.md` / `state-epoch-plan.md` / `store-plan.md` /
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

**읽는 순서**: 🔴은 그대로 구현하면(또는 지금 상태 그대로 두면) 동작이
어긋나는 것, 🟡은 정의가
비어 있거나 두 서술이 갈려 M2 구현자가 임의로 정하게 되는 것, 🟢은 문서
정합·구현 시 정하면 되는 것. "미확정" 표시는 트레이싱으로 확신까지 못 간
의심이다. **2차 패스 표의 마지막 열은 그 항목을 실제로 돌려본 결과**라,
거기 ✅가 붙은 것은 의심이 아니라 재현된 사실이다.

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

**⭐ [2026-08-25] 2차 패스 — 실측 (`H-71`~`H-76`).** 1차가 안 쓴 각도로
같은 라운드를 이어서 돌렸다. 상세는 아래 "2차 패스" 절.

| 번호 | 심각도 | 한 줄 | 주 대상 | 실측 |
|---|---|---|---|---|
| `H-71` | 🔴 | **단일 `Relate` 안의 자기참조(값 → 키)는 GC 안전하지 않다** — `relate-plan.md`가 안전하다고 단언한 바로 그 모양이 100% 샌다. `RefLeafHandler`가 정확히 그 모양 | `relate-plan.md`, `ref-plan.md`, `source-state-plan.md` leaf dedup | ✅ 커밋된 `Relate.luau`로 50/50 누수 |
| `H-72` | 🟡 | `GateNode`가 `state-epoch-plan.md` §4 규칙 1~3을 돌려면 `emitEpochMap`을 **갱신하지 않고 비교**해야 하는데, `EpochMap` 표면에 그 연산이 없다 | `state-epoch-plan.md` §3·§4, `gate-plan.md` 4번 | 표면 대조(코드 없음) |
| `H-73` | 🟡 | `store:GetDynamic<<T>>(name): Source<T>`는 **콜론이든 탑레벨이든 `T`를 바인딩할 방법이 없다** — Luau엔 호출부 명시 타입 인자가 없고 기대 타입 추론도 안 된다. 콜론 쪽은 합성 타입에 키 자체가 없어 타입에러 | `store-plan.md`, `question.md` 최우선 | ✅ `T`가 `unknown`으로 떨어짐 |
| `H-74` | 🟡 | eager `defaults` 경로는 `__index`를 **통째로 우회**하므로 "고정 메소드 테이블을 먼저 확인"이라는 예약 키 방어가 성립하지 않는다 | `store-plan.md` | ✅ `attempt to call a table value` |
| `H-75` | 🔴 | `WrapStore`가 스파이크 `16`의 **평평한** 모양이면 `store.key:Compute(무주석 콜백)`이 깨진다 — `typing-limits.md` ②쪼개기를 `type function` 안에서도 해야 한다 | `store-plan.md`, `typing-limits.md` §5, `luau-test/done/16` | ✅ 평평=실패 / 쪼개기=통과 |
| `H-76` | 🔴 | `type function`은 **바깥 타입 별칭을 참조 못 한다** → `Source<T>` 전 표면을 구조적으로 중복 작성해야 하고, 메소드 self 파라미터가 **불변**이라 필드 하나만 어긋나도 `store.key`가 `State<T>` 파라미터 자리에 **안 들어간다**. 스파이크 `16`은 그 대입을 안 해봤다 | `store-plan.md`, `typing-limits.md` §5·§6 | ✅ 별칭 참조 실패 / `Revision` 누락만으로 대입 실패 |

**⭐ [2026-08-25] 3차 패스 — 커밋된 코드·툴체인 실측 + M2 소비자 문서 (`H-77`~`H-84`).**
상세는 아래 "3차 패스" 절.

| 번호 | 심각도 | 한 줄 | 주 대상 | 실측 |
|---|---|---|---|---|
| `H-77` | 🔴 | **`Relate`의 *내부 키*가 `inst`를 되참조하면 `SetStrong`/`SetWeak` 둘 다 샌다** — 규칙에 이 슬롯 자체가 없고, `H-71`의 해법 (b)(“`SetWeak`으로 낮춘다”)가 여기선 **전혀 안 듣는다**. 커밋된 `RunInit`이 실제로 물린다 | `relate-plan.md`, `module-lifecycle-plan.md`, 커밋된 `quad-base/src/init.luau` | ✅ 커밋된 코드로 30/30 누수 |
| `H-78` | 🔴 | **커밋된 M1 스모크 2개와 `done/`의 타입 스파이크 `23`이 지금 저장소 상태에서 안 돈다** — 게다가 실패 모드가 `luau-analyze` "진단 0건"이라 **통과로 오독된다**. `ROADMAP.md` M1은 날짜도 전제조건도 없이 "전부 PASS" | `ROADMAP.md` M1, `project-setup-plan.md`, `luau-test/STATUS.md` | ✅ 워크어라운드 전/후 대조 |
| `H-79` | 🟡 | **`Store`에 열거 표면이 없는데** 그룹 `Attribute(...)`/`:NameMap()`이 그걸 요구한다 — lazy `__index` 때문에 키 집합이 **접근 이력에 좌우**되고, `defaults` 없이 만든 Store에선 빈 맵이 된다 | `store-plan.md`, `attribute-plan.md` | ✅ 0개 / 1개 / 2개로 갈림 |
| `H-80` | 🟡 | M2가 `quad-types`의 `Quad`에 추가할 목록이 `Source`/`State`/`Store`뿐 — **`State`는 런타임 값이 아예 없고**, M2가 실제로 얹는 나머지 탑레벨 값(`Effect`·`is*` 전량·`bindLifetime` 4종…)이 전부 빠져 있다. 그 전부가 `H-25`가 만든 바로 그 벽에 부딪힌다 | `ROADMAP.md` M2, `quad-types-plan.md`, `source-state-plan.md` | 표면 대조 |
| `H-81` | 🟡 | `isModifier` 런타임 가드는 **전부 M2 코드**(`Source:Set`/Store 생성/`:Compute` 캐싱)에 들어가는데 체크박스는 **M7에만** 있고 M2 체크리스트엔 한 줄도 없다. 게다가 적용 지점 목록이 두 문서에서 다르다 | `ROADMAP.md` M7, `modifier-plan.md` 7번, `source-state-plan.md` | 표면 대조 |
| `H-82` | 🟢 | `:With`를 실노드로 확정한 **근거 2번이 pass-through 노드엔 성립하지 않는다** — 2026-08-14 재작성이 "근거가 더 강해졌다"면서 실제론 정확도를 낮췄다. 결론은 안 바뀜(근거 1·3이 유효) | `source-state-plan.md` | 문서 정합 |
| `H-83` | 🟢 | 확정된 Store 구현 스케치를 그대로 쓰면 **무인자 `Store()`가 `table.clone(nil)`로 크래시**한다 — 같은 문서가 `defaults`는 선택이라고 확정해뒀다 | `store-plan.md` | ✅ `table expected, got nil` |
| `H-84` | 🟢 | `:With(...)`/`state:Block(b)`/`Source:Emit()`이 M2 체크리스트에 개별 항목으로 없다 — `:Compute`/`:Apply`/`:Observer`는 각각 있는데 | `ROADMAP.md` M2 | 표면 대조 |

---

# 1차 패스 — 문서 대 문서 손 트레이싱

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

# 2차 패스 — 문서가 "확인했다"고 적은 것을 실제로 돌려봤다 (2026-08-25)

**왜 이 패스가 있는가**: 사용자 요청 — *"저기에 포함되지 않은 문제점을
더 찾아봐. 찾은 다음에 진짜 있는 문제인지 재검증까지 다 해줘."*

**1차 패스와 다른 각도**: 1차는 **문서 대 문서**의 손 트레이싱이었다.
이번엔 **문서가 "확인했다"고 적어둔 런타임/타입 주장을 실제로
`luau`/`luau-analyze`에 걸어봤다.** 그래서 아래 여섯 중 다섯은 추측이
아니라 **실행 결과**이고, 각 항목에 재현 코드가 그대로 들어 있다.
같이 확인된 것 — **"확인 완료"라고 적힌 스파이크들이 정작 위험한 모양을
안 테스트한 경우가 반복적으로 나왔다**(`07`은 되참조 없는 payload만,
`16`은 대입을 아예 안 해봄).

**실측 환경**: `luau` / `luau-analyze`
(`~/.local/share/mise/installs/luau/latest`, 2026-08-25 실행).

**이 패스의 범위**: `base/relate-plan.md` / `lifecycle-pattern.md` (0)(1) /
`store-plan.md` 전체 / `state-epoch-plan.md` §2~§5 / `gate-plan.md` 4번 /
`blocker-plan.md` / `typing-limits.md` §1②·§5·§6·영향 범위 표 /
`source-state-plan.md`의 leaf dedup·`:Compute` trailing deps /
`ref-plan.md`의 `RefLeafHandler` / `brand-plan.md` / 커밋된
`quad-base/src/Relate.luau`·`init.luau` / `luau-test/done/07`·`16`·`21` /
`ROADMAP.md` M2. **1차 패스(`H-55`~`H-70`)와 겹치는 항목은 없다** —
겹칠 뻔한 자리는 항목 안에 "이건 `H-xx`와 별개다"로 적었다.

---

## 🔴 `H-71` — 단일 `Relate` 안의 자기참조는 GC 안전하지 않다 (실측)

**어디**: `base/relate-plan.md`의 "위험한 패턴 — 서로 다른 두 `Relate`의
상호 강참조 순환" 절.

**문서가 뭐라고 하나**: 그 절은 자기참조(값이 자기 키를 되참조)를 세 개
예로 들고 — `Dispatch.setLength`의 observer 클로저가 `inst`를 캡처,
`Ref.Value = inst`, `slot._mountedInst = physicalTarget` — **"단일 `Relate`
안에서 일어나는 한 안전함"** 이라고 단언한다. 근거로 든 문장은
*"그 `Relate`의 키(`inst`)가 테이블 바깥에서 독립적으로 reachable한지만
판별하면 되기 때문"*이다.

**무엇이 어긋나나**: 그 판별이 정확히 **ephemeron 테이블의 의미론**이고,
같은 문서가 바로 아래 문단에서 **Luau엔 ephemeron이 없다**고(출처까지 달아)
확정해뒀다. ephemeron이 없는 weak-key 테이블은 **값을 무조건 마킹**하므로,
값에서 키로 가는 강한 경로가 하나라도 있으면 그 엔트리는 영원히 안 걷힌다.
두 `Relate`가 필요한 게 아니라 **하나면 충분하다.** 즉 이 절은 자기 근거로
자기 결론을 반증하고 있다.

**실측** — 커밋된 `quad-base/src/Relate.luau`를 **그대로 require**해서 돌렸다:

```lua
local Relate = require("./Relate")  -- quad-base/src/Relate.luau 원본
local function gc() for _ = 1, 10 do collectgarbage() end end
local function countAlive(c) local n = 0 for _ in c do n += 1 end return n end

-- 대조군: payload가 inst를 되참조하지 않음 (스파이크 07이 실제로 테스트한 모양)
do
    local r, canary = Relate(), setmetatable({}, {__mode = "v"})
    do for i = 1, 50 do
        local inst = {}
        local payload = {tag = "p" .. i}
        r:SetStrong(inst, "k", payload); canary[i] = payload
    end end
    gc(); print("[대조군]", countAlive(canary))
end

-- 케이스1: RefLeafHandler 모양 — relate:SetStrong(inst,k,v) + v:Set(inst)
do
    local r, canary = Relate(), setmetatable({}, {__mode = "v"})
    do for i = 1, 50 do
        local inst = {}
        local ref = {Value = inst}
        r:SetStrong(inst, 1, ref); canary[i] = ref
    end end
    gc(); print("[케이스1]", countAlive(canary))
end

-- 케이스2: setLength observer 모양 — StrongMap 값이 inst를 캡처한 클로저
do
    local r, canary = Relate(), setmetatable({}, {__mode = "v"})
    do for i = 1, 50 do
        local inst = {}
        local observer = {emit = function() return inst end}
        r:SetStrong(inst, "observer", observer); canary[i] = observer
    end end
    gc(); print("[케이스2]", countAlive(canary))
end

-- 케이스3: 같은 모양이지만 SetWeak (2026-08-18에 정정된 gchold/gcconn 저장 방식)
do
    local r, canary = Relate(), setmetatable({}, {__mode = "v"})
    do for i = 1, 50 do
        local inst = {}
        local held = {back = inst}
        r:SetWeak(inst, "gchold", held); canary[i] = held
    end end
    gc(); print("[케이스3]", countAlive(canary))
end
```

```
[대조군]  0   ← 정상
[케이스1] 50  ← 하나도 안 걷힘
[케이스2] 50  ← 하나도 안 걷힘
[케이스3] 0   ← SetWeak은 정상
```

**즉 `SetStrong` + 값→키 되참조는 100% 샌다.** `SetWeak`은 안전하다 —
2026-08-18에 `lifecycle-pattern.md`의 gchold/gcconn 저장을 `SetStrong`에서
`SetWeak`으로 정정한 판단은 **결과적으로 맞았고**, 다만 그때 적은 근거
("두-`Relate` 상호 순환에 걸린다")는 실제보다 좁았다 — 단일 `Relate`로도
걸린다.

**왜 지금까지 안 잡혔나 — 스파이크 `07`이 위험한 모양을 안 테스트했다.**
`luau-test/done/07-relate-weak-table-gc.luau`는 스스로 *"`relate-plan.md`
전체가 기대고 있는 바로 그 주장"* 을 검증한다고 적고 4번 절에서
연쇄 GC를 확인하는데, 거기 쓰는 payload가
`local payload = { tag = "payload" .. i }` — **`inst`를 되참조하지 않는
모양**이다(위 대조군과 동일). 그래서 통과했다.

**실제로 어디가 물리나**:
- **`RefLeafHandler.process`**(`base/ref-plan.md`) — `relate:SetStrong(inst, k, v)`
  하고 `v:Set(inst)`로 `v.Value = inst`를 세운다. **케이스1 그대로다.**
  게다가 그 relate 엔트리를 지우는 코드는 retractor의 `nextValue ~= v`
  분기 안에만 있어서, **평범한 `Destroy`(정리를 GC에 위임하는 정상 경로)
  에서는 한 번도 안 지워진다.** 결과: `Frame { Ref(myRef) }` 하나마다
  Instance userdata + `Ref` + 버킷이 프로세스 수명 동안 남는다.
- **`ObserverEffectLeafHandler.process`**(`base/source-state-plan.md`의
  "Observer/Effect Leaf dedup" 절) — 같은 모양(`relate:SetStrong(inst,k,v)`).
  `v`가 `inst`를 되참조하는지는 사용자 `fn`이 뭘 캡처하느냐와
  `EffectHandle._destroyConn`(그 `inst`의 `Destroying` 연결)에 달려 있어
  케이스1만큼 확정적이진 않지만, **되참조하면 똑같이 샌다.**
- `relate-plan.md`가 든 나머지 두 예(`setLength` observer, `slot._mountedInst`)는
  각각 저장 방식이 `SetStrong`이냐 `SetWeak`이냐에 따라 갈린다 — **결론이
  아니라 판정 기준 자체가 문서에 잘못 적혀 있으므로 전수 재확인이 필요하다.**

**이건 `H-63`(Blocker의 weak 배열)과 별개다** — 그쪽은 값-weak 배열의
순회/구멍 문제이고, 이건 키-weak 테이블의 마킹 의미론이다.

**갈래(결정 전 목록)**:
(a) **`relate-plan.md`의 그 절을 뒤집는다** — "자기참조는 `SetWeak`일 때만
안전하고, `SetStrong` + 되참조는 금지"를 규칙으로 못박고, `SetStrong`을
쓰는 자리(`ref-plan.md`, `source-state-plan.md` leaf dedup,
`attribute-plan.md`의 `nameClaims`/`groupClaimKeys`, `tag-plan.md`의
`tagNameMap`, `module-lifecycle-plan.md`의 `runInitRelate`)를 전수 훑어
값이 키를 되참조하는지 확인한다. (참고: `runInitRelate`는 값이 `true`,
`nameClaims`/`groupClaimKeys`/`tagNameMap`은 값이 부기 테이블이라 일단
안전해 보이고, 확정적으로 물리는 건 `RefLeafHandler` 하나다.)
(b) **dedup 기록을 `SetStrong` → `SetWeak`으로 낮춘다** — dedup은 순수
성능 최적화라(그 절이 스스로 *"correctness 문제는 아님"* 이라고 못박음)
weak로 낮춰 엔트리가 조기 소실돼도 "dedup을 한 번 놓친다"까지가 최대
손해다. `relate-plan.md`의 **"다른 곳에서 안전하게 유지되는 것은 항상
`SetWeak`"** 규칙에도 그대로 맞는다(`v`는 gchold가 이미 강하게 잡는다).
(c) `unbindLifetime` 경로에서 relate 엔트리를 항상 지운다 — 정상 `Destroy`
경로엔 `unbindLifetime` 호출이 없으므로 **이것만으로는 안 닫힌다.**
(b)가 제일 싸 보이고 기존 규칙과도 일관된다.

**같이 해야 할 것**: `luau-test/done/07`에 되참조 케이스를 **음성 대조군으로**
추가할 것 — 지금 그 파일은 "GC-native 아키텍처의 핵심 전제를 검증했다"고
여러 문서에 인용되고 있는데, 실제로는 안전한 모양만 봤다.

## 🟡 `H-72` — `GateNode`가 규칙 1~3을 돌 수 있는 연산이 `EpochMap`에 없다

**어디**: `base/state-epoch-plan.md` §4의 "⚠️ [2026-08-22 신설] `GateNode`는
이 의사코드를 그대로 쓰지 않는다" 항목, §3의 `EpochMap` 표면,
`base/gate-plan.md` 4번의 "게이트의 `emitEpochMap`은 수신 때가 아니라 실제로
전파할 때" 항목.

**무엇이 어긋나나**: §4의 수신 규칙은 두 boolean으로 세 갈래를 가른다.

```lua
local valueChanged = self.valueEpochMap:Update(from)
local emitChanged  = self.emitEpochMap:Update(from)
```

게이트 예외는 **"판정(규칙 1~3)은 똑같이 먼저 돈다"** 면서 동시에
**"`emitEpochMap:Update`를 수신 시점에 부르지 않는다"** 고 한다. 그런데
`emitChanged`를 얻는 유일한 통로가 `:Update`이고, `:Update`는 정의상
**읽고 나서 덮어쓴다**(§3: *"저장된 리비전과 `epoch.Revision`을 비교하고,
다르면 새 값으로 덮는다"*). `EpochMap`의 나머지 표면도 전부 쓰기를 한다 —
`:Refresh`는 자기 키를 다시 읽어 **갱신**하고, `:Sync`는 **쓰기 전용**,
`:TrackFrom`은 키를 넘겨받아 **채운다**. **"갱신하지 않고 비교만 하는"
연산이 하나도 없다.**

즉 게이트 구현자는 셋 중 하나를 임의로 고르게 된다 — (1) `emitChanged`를
포기하고 `valueChanged`만으로 판정한다(규칙 2·3이 사라진다), (2)
`emitEpochMap:Update`를 그냥 부른다(§4 예외와 `gate-plan.md` 4번이 확정한
"유보 중엔 아직 안 던졌다"는 맵의 뜻이 깨진다), (3) `EpochMap` 내부
테이블에 게이트가 직접 손을 넣는다(컴포지션이 깨진다).

**이건 `H-55`와 별개다** — `H-55`는 *정책이* 흡수 집합을 버릴 수 없다는
것이고, 이건 *노드가* 자기 판정을 표현할 연산이 없다는 것이다. 다만 둘 다
"`Epoch` 일반화 때 게이트 쪽 요구가 표면에 반영이 덜 됐다"는 같은 뿌리에서
나오므로 같이 보는 게 낫다.

**갈래**: (a) `EpochMap:Peek(Epoch | EpochSet) -> boolean`(읽기 전용 비교)을
추가한다 — `Update`가 이미 `{읽기, 비교, 쓰기}`라 `Peek`은 그 앞 두 개만
쓰는 것이고 코드 공유가 쉽다. (b) `Update(from, write: boolean?)`처럼
플래그를 단다(표면이 하나 안 늘지만 호출부에서 의도가 덜 보인다).
(c) 게이트는 `valueChanged`만 본다 — 그러면 §4의 규칙 2("값은 최신인데
통지는 아직")가 게이트에서 사라지므로, 게이트가 붙들고 있는 동안 하류가
`Get()`으로 앞당겨 읽은 뒤 게이트가 풀릴 때 **통지가 통째로 사라지는**
경로가 생기는지 따로 따져야 한다.

## 🟡 `H-73` — `GetDynamic<<T>>`는 어느 표면으로 둬도 `T`를 바인딩할 수 없다 (실측)

**어디**: `base/store-plan.md`의 "타입 추론 문제" 절
(`store:GetDynamic<<T>>(name): Source<T>`), `ROADMAP.md` M2의 그 체크박스,
`.claude/question.md` 최우선 절(콜론 메소드냐 탑레벨 함수냐).

**무엇이 어긋나나**: 열려 있는 질문은 *"콜론이면 예약 키가 된다"* 는
**런타임** 충돌 하나였는데, 실측해보니 **타입 쪽이 먼저 막힌다.**

**실측 1 — 콜론 메소드는 합성 타입에 키 자체가 없다.** 스파이크 `16`의
`WrapStore`/`ProcessStoreType`을 그대로 쓰고 마지막 줄만 바꿨다:

```lua
type Processed = ProcessStoreType<{ ty: string, count: number }>
local processed: Processed = nil :: any
local dyn = processed:GetDynamic("runtimeName")
```
```
TypeError: Key 'GetDynamic' not found in table 'Processed'
```

`ProcessStoreType`은 `ty:properties()`를 돌며 **`T`의 필드만** 심으므로
고정 메소드는 결과 타입에 존재하지 않는다. 이건 스파이크 `21`이 확인한
"미선언 키는 타입 에러"라는 **방어선이 그대로 자기 메소드에도 걸린 것**이다.
콜론 메소드를 유지하려면 `ProcessStoreType`이 `GetDynamic`을 **명시적으로
주입**해야 한다(그리고 그 순간 `H-74`의 eager 충돌이 같이 따라온다).

**실측 2 — 주입해도 `T`가 안 묶인다.** `types.generic("T")`로 제네릭
`GetDynamic`을 주입하면 키는 생기지만:

```
TypeError: Expected this to be 'Source<number>' but got
  't1 where t1 = { Get: (t1) -> unknown, Set: (t1, unknown) -> () }'
```

`T`가 `unknown`으로 떨어진다.

**실측 3 — 탑레벨 함수로 옮겨도 같다.** `type function`과 무관하게, 순수
Luau에서:

```lua
local function getDynamic<T>(store: Store, name: string): Source<T>
    return (nil :: any) :: Source<T>
end
local a: Source<number> = getDynamic(store, "x")   -- ❌ Source<unknown>
local b = getDynamic(store, "y") :: Source<string> -- ✅ 캐스트는 통과
```

`T`를 실을 자리가 어디에도 없다 — Luau엔 **호출부 명시 타입 인자 문법이
없고**(`ident<number>(1)`은 비교 연산자로 오파싱된다, 실측 확인), **기대
타입으로부터의 제네릭 인스턴스화도 안 된다**(위 `a`). 인자에도 `T`가 안
나타나므로 추론할 근거가 0이다.

**따라서 `<<T>>` 표기 자체가 이 자리에선 성립하지 않는다** —
`base/quad-types-plan.md`가 확정한 이중 꺾쇠 관례는 **타입 자리의 명시적
인스턴스화**(`Foo<<A, B>>`)에 대한 것이고, `store:GetDynamic<<T>>(name)`은
**값 호출부**라 그 관례가 적용될 자리가 아니다.

**남는 선택지**: `GetDynamic`을 **비제네릭**으로 두고 `Source<any>`(또는
`any`)를 돌려준 뒤 호출부가 `:: Source<number>`로 캐스팅하게 하는 것뿐이다.
그러면 사용자 판정의 취지(*"여기서 타입 보장을 포기했다가 호출부에
드러난다"*)는 오히려 더 정직하게 드러난다 — 캐스트가 코드에 남으니까.
그리고 그 모양이면 **탑레벨 함수 쪽이 명확히 유리하다**: `type function`을
전혀 안 고쳐도 되고(실측 1이 사라짐), 예약 키도 안 생기고(`H-74`가
사라짐), `isState`/`bindLifetime`과 같은 "소문자 탑레벨 유틸" 관례에도
맞는다. **이건 `question.md` 최우선 항목에 대한 실측 근거이지 결정이 아니다 —
판단은 사용자 몫.**

## 🟡 `H-74` — eager `defaults` 경로는 `__index`를 통째로 우회한다 (실측)

**어디**: `base/store-plan.md`의 "Store = Source들의 이름 붙은 모음"
절(eager 생성 스케치)과 "타입 추론 문제" 절의 ⚠️ 구현 주의
(*"`__index`가 고정 메소드 테이블을 먼저 확인하고, 없을 때만 lazy `Source`
생성으로 폴백해야 하며, 그 결과 `GetDynamic`은 Store의 예약 키 이름이
된다"*).

**무엇이 어긋나나**: `__index`는 **raw 키가 없을 때만** 불린다. 그런데 eager
생성은 확정된 스케치대로 `table.clone(defaults)` 결과에 `Source`를 **직접
써넣는다** — 그 키들은 raw로 존재하므로 `__index`가 아예 안 돈다. 따라서
`defaults`에 `GetDynamic`이라는 도메인 키가 있으면 **고정 메소드가 조용히
가려진다.** 문서가 확정한 *"그 이름의 Source는 dot-access로 못 만듦"* 은
lazy 경로에만 참이고, eager 경로로는 **만들 수 있다.**

**실측** — 확정 스케치를 그대로 옮긴 최소 모델:

```lua
local METHODS = {}
function METHODS.GetDynamic(self, name) return "..." end

local function Store(defaults)
    local sources = table.clone(defaults or {})
    for k, v in sources do sources[k] = Source(v) end
    return setmetatable(sources, { __index = function(t, k)
        local m = METHODS[k]; if m ~= nil then return m end   -- 고정 메소드 먼저
        local s = Source(nil); rawset(t, k, s); return s      -- 없으면 lazy
    end })
end

Store({ hp = 10 }):GetDynamic("x")                -- OK
Store({ hp = 10, GetDynamic = 3 }):GetDynamic("x") -- ?
```
```
(1) GetDynamic 타입: function   → 호출 OK
(2) GetDynamic 타입: table      → attempt to call a table value
```

**타입 층도 못 잡는다** — `ProcessStoreType<{GetDynamic: number}>`는
그 키를 그냥 `Source<number>`로 합성하므로, 타입상으로도 "메소드가 아니라
Source"가 되어 일관되게 틀린다.

**`Modifier`와 "정확히 같은 구조"가 아니다.** `base/modifier-plan.md`의
"구현 시 주의"가 다루는 `__index`는 **필드 setter를 즉석에서 합성**하는
것이라 미리 채워지는 raw 키가 없다 — 그래서 거기선 "고정 메소드를 먼저
확인"이 실제로 방어가 된다. Store만 eager 경로를 갖는다.

**갈래**: (a) `Store` 생성 시 `defaults`의 키를 예약 이름과 대조해
**즉시 error**(가장 싸고, "런타임이 아니라 타입에 방어선을 둔다"는 확정과
충돌하지 않는다 — 이건 타입이 못 잡는 자리라서), (b) eager 생성 결과를
store 테이블이 아니라 **내부 백킹 테이블**에 넣고 `__index`가 항상 돌게
한다(그러면 `store-plan.md`가 그림자 실값 저장소를 불필요하다고 적은
서술을 손봐야 한다),
(c) `H-73`대로 `GetDynamic`을 **탑레벨 함수로 옮겨** 예약 키를 아예 안
만든다 — 그러면 이 항목이 통째로 사라진다.

## 🔴 `H-75` — 평평한 `WrapStore`면 `store.key:Compute(무주석 콜백)`이 깨진다 (실측)

**어디**: `base/store-plan.md`의 `WrapStore`/`ProcessStoreType` 스케치,
`luau-test/done/16-type-store-key-typefunction.luau`,
`base/typing-limits.md` §5(*"✅ 검증 완료"*)와 §1의 ②쪼개기.

**무엇이 어긋나나**: 확정된 `WrapStore`는 `Get`/`Set`만 있는 **평평한**
테이블 하나를 만든다. 거기에 `Compute`(로컬 제네릭 `U` + 자기 타입을
self로 받는 메소드)를 그대로 얹으면, `typing-limits.md` §1이 확정한 바로
그 실패 모드에 걸린다 — **콜백 파라미터 무주석 추론이 깨진다.**
그런데 `store.key1:With(store.key2):Compute(fn)`은 `store-plan.md`가 직접
드는 대표 관용구다.

**실측 A — 평평한 모양(스파이크 16 형태 + `Compute`)**:

```lua
type function WrapSource(ty: type): type
    local src = types.newtable()
    src:setproperty(types.singleton("Get"), types.newfunction({head={src}}, {head={ty}}))
    local U = types.generic("U")
    src:setproperty(types.singleton("Compute"), types.newfunction(
        {head={src, types.newfunction({head={src}}, {head={U}})}}, {head={U}}, {U}))
    return src
end
...
local b = store.ty:Compute(function(s) return #s:Get() end)
```
```
TypeError: Expected this to be '(tp2) -> number where t1 = { Compute: ..., Get: ... }'
but got '<T>(t1) -> len<T> where t1 = { read Get: (t1) -> (T, ...unknown) }'
```

**실측 B — 손으로 쓴 대조군도 똑같이 실패**(즉 `type function` 탓이
아니라 §1의 알려진 문제):

```lua
type SourceS = { Get: (self: SourceS) -> string, Compute: <U>(self: SourceS, fn: (SourceS) -> U) -> U }
local b = s:Compute(function(x) return #x:Get() end)   -- ❌ 같은 에러
```

**실측 C — ②쪼개기를 손으로 쓰면 통과**:

```lua
type SourceDataS = { Get: (self: SourceDataS) -> string }
type SourceS = SourceDataS & { Compute: <U>(self: SourceDataS, fn: (self: SourceDataS) -> U) -> U }
local b = s:Compute(function(x) return #x:Get() end)   -- ✅ 진단 0건
```

**실측 D — ②쪼개기를 `type function` 안에서도 할 수 있다(통과)**: `data`
핸들과 `full` 핸들을 각각 `types.newtable()`로 만들고, `full`의 메소드
self/콜백 파라미터가 전부 `data`를 가리키게 하면 무주석 콜백이 통과하고
음성 대조군(`local bad: string = store.ty:Compute(... number ...)`)만
정확히 에러난다.

**그래서 무엇이 필요한가**: `WrapStore`는 **평평한 테이블 하나가 아니라
데이터부/메소드부 두 핸들**로 지어야 한다. 지금 `store-plan.md` 스케치와
스파이크 `16`은 평평한 모양이고, `typing-limits.md` §5는 그 평평한 모양을
근거로 "✅ 검증 완료"라고 적는다 — **검증된 건 `Get`/`Set` 두 개뿐이고,
콜백을 받는 메소드는 한 번도 안 걸어봤다.** §8 체크리스트에 "`type function`
으로 타입을 합성할 때도 ②쪼개기를 적용할 것"이 빠져 있다.

## 🔴 `H-76` — 합성 타입은 `Source<T>` 자리에 **안 들어갈 수 있다**, 그리고 그 사실이 검증된 적이 없다 (실측)

**어디**: `base/store-plan.md`의 *"Luau는 이름이 아니라 '만족하는가'로
구조적 일치를 검사하므로 문제없이 `Source<string>` 자리에 대입 가능"*,
`base/typing-limits.md` §5·§6, `luau-test/done/16`.

**세 가지가 겹친다.**

**(1) `type function`은 바깥 타입 별칭을 참조할 수 없다(실측).**

```lua
export type Source<T> = { Get: (self: Source<T>) -> T, ... }
type function WrapA(ty: type): type
    return Source
end
type R = WrapA<string>
```
```
TypeError: 'WrapA' type function: returned a non-type value
```

즉 `WrapStore`는 `Source<T>` 정본을 **가리킬 수가 없고 통째로 다시 지어야
한다.** 이건 `quad-types-plan.md`가 이미 기록한 함정(*"`type function`은
같은 파일의 바깥 스코프 로컬 함수를 아예 참조 못 한다"* → `matchesPattern`과
`CheckVersion` 로직이 물리적으로 중복)의 **타입 별칭 판**이고, 지금
`store-plan.md`엔 그 서술이 없다. 결과적으로 **`Source<T>`/`State<T>`의 전
표면(`Get`/`Set`/`Emit`/`Revision`/`Compute`/`With`/`Observer`/`Apply`/
`Gate`/`Block`…)이 두 곳에 손으로 중복 유지되며, 둘이 어긋나도 컴파일러가
말해주지 않는다.**

**(2) 메소드 self 파라미터는 불변(invariant)이라 조금만 어긋나도 대입이
막힌다(실측).** ②쪼개기 모양으로 짓되 `Revision` **하나만** 빠뜨렸더니:

```
TypeError: Expected this to be 'SourceData<number> & { Compute: ..., Set: ... }'
but got '{ Compute: ..., Get: (t1) -> number, Set: ... } where t1 = { Get: (t1) -> number }'
  * Expected the 1st parameter of property `Compute` to be exactly `SourceData<number>`,
    but got `t1 where t1 = { Get: (t1) -> number }`
```

`t1`과 `SourceData<number>`는 `Revision` 하나 차이인데, self 파라미터가
**"exactly"** 를 요구하므로 그 하나 때문에 `store.key`가 `Source<number>`
자리에 **안 들어간다.** `state:With(store.key)`, `Effect(fn, store.key)`,
`Modifier` 필드 등 base가 `State<T>`를 받는 **모든 자리**가 여기 걸린다.

**(3) 그 대입은 검증된 적이 없다.** 스파이크 `16`은
`processed.ty:Get()`을 호출해보고 음성 대조군 4건을 확인할 뿐,
**`processed.ty`를 `Source<string>` 타입 자리에 넣어보지 않는다.**
평평한 2메소드 모양에 한해서는 실제로 통과하지만(확인함), 그건 실제
`Source<T>`가 아니라 장난감 타입이다.

**해답은 있다(실측으로 확인)** — 정본 `Source<T>`를 ②쪼개기 모양으로
선언하고, `WrapStore`가 그걸 **충실히**(`Revision`까지) 같은 모양으로
재현하면 `store.key:Compute(무주석 콜백)`과 `Source<number>` 대입이
**둘 다 통과**한다. 그리고 드리프트를 잡으려면 타입 테스트에 **정합성 단언**
한 줄을 상주시키면 된다:

```lua
-- WrapStore가 정본에서 어긋나는 순간 여기서 컴파일 에러가 난다
local _probe = (nil :: any) :: ProcessStoreType<{ k: number }>
local _conformance: Source<number> = _probe.k
```
(`::`를 한 식 안에서 두 번 체이닝하면 파싱이 깨지므로 두 줄로 나눠야
한다 — 이 형태로 진단 0건 확인.)

**그래서 결정이 필요한 것**: (a) 정본 `Source<T>`/`State<T>` 선언을 처음부터
②쪼개기(`SourceData<T>` + 메소드부)로 확정할 것인가(`typing-limits.md` ②는
이미 그 모양을 권하지만 `source-state-plan.md`/`store-plan.md`의 표면
서술은 그 형태로 안 적혀 있다), (b) `WrapStore` 중복을 규약으로 못박고
정합성 단언을 `luau-test`에 상주시킬 것인가, (c) 스파이크 `16`에 대입
케이스와 `Compute` 케이스를 추가할 것인가. 셋 다 M2를 짜기 전에 정해야
한다 — 나중에 발견하면 `Source`/`State`의 **타입 선언 모양 자체**를 바꾸는
일이 된다.

---

## 부록 — 열려 있던 실측 항목 하나는 **성립**한다

`base/source-state-plan.md`의 "trailing deps를 `fn`에 lazy positional
인자로도 노출" 절과 `ROADMAP.md` M2가 남겨둔 미검증 항목 (B) —
**"이형(heterogeneous) 타입 dep 여러 개를 제네릭 팩 하나로 정확히 좁혀
받을 수 있는가"**(스파이크 `15`, 지금 `rewrite-required/`) — 를 같이
재봤다. **된다.**

```lua
type StateData<T> = { Get: (self: StateData<T>) -> T }
export type State<T> = StateData<T> & {
    ComputeN: <U, D...>(self: StateData<T>, fn: (self: StateData<T>, prev: U?, D...) -> U, D...) -> U,
}
local s: State<string> = nil :: any
local a: StateData<number> = nil :: any
local b: StateData<boolean> = nil :: any

local r = s:ComputeN(function(self, prev, d1: StateData<number>, d2: StateData<boolean>)
    return if d2:Get() then d1:Get() else 0
end, a, b)
local rn: number = r      -- ✅ U == number 로 정확히 추론
```

- **양성**: 이형 2개(`number`/`boolean`)가 팩 하나로 정확히 좁혀진다.
- **음성 대조군**: 콜백 파라미터 순서를 바꿔 넘기면 두 자리 모두 잡힌다
  (`Expected 'StateData<boolean>' but got 'StateData<number>'` × 2).
- **무주석 콜백도 타입 검사가 살아 있다** — 콜백 안에서 없는 메소드를
  부르거나 `Get()` 결과를 틀린 타입으로 받으면 호출부에서 잡힌다.
- 확정된 순서(`previous?`가 팩 **앞**)가 그대로 성립한다.
- **다만 `previous?`를 안 쓸 때 자리를 비워야 하는 불편은 그대로다** —
  `function(self, _, d1, d2)`.

**부수 관찰(위 `H-75`와 같은 결)**: dep을 **팩이 아니라 고정 인자**로
선언하면(`<U, D1>(..., dep1: StateData<D1>)`) 무주석 콜백 추론이 깨진다 —
로컬 제네릭 `D1`이 콜백 파라미터에 나타나기 때문. quad가 확정한 모양은
팩(`...deps`)이라 지금은 안 물리지만, "dep 1개짜리 특수 오버로드"를
나중에 만들고 싶어지면 여기부터 볼 것.

---

# 3차 패스 — 커밋된 코드·툴체인을 실제로 돌려봤다 + M2 소비자 문서 (2026-08-25)

**왜 이 패스가 있는가**: 사용자 요청 — *"저기에 포함되지 않은 문제점을
더 찾아봐. 찾은 다음에 진짜 있는 문제인지 재검증까지 다 해줘. 찾은걸
이어붙이면 돼"*.

**1·2차와 다른 각도 둘**:

1. **2차는 문서가 주장하는 Luau 동작을 *새로 짠 최소 재현*으로 걸었다.
   3차는 저장소에 이미 있는 것을 그대로 돌린다** — `quad-base/test/smoke.*.luau`,
   `luau-test/done/`의 스파이크 전량, `python3 .claude/tools/doc-check.py`,
   그리고 커밋된 `quad-base/src/*.luau`에 대한 `luau-analyze`. 즉 "설계가
   맞나"가 아니라 **"지금 이 저장소가 문서가 말하는 상태인가"**를 본다.
2. **1차 패스가 범위에서 명시적으로 뺐던 문서들** — `tween-plan.md` /
   `modifier-plan.md` / `attribute-plan.md` / `onchange-plan.md` /
   `bind-system-plan.md` / `quad-types-plan.md` / `architecture.md` /
   `project-setup-plan.md` / `module-lifecycle-plan.md`. 이들은 M2를 만드는
   문서가 아니라 **M2가 만든 것을 쓰는** 문서라, "소비자가 요구하는데 M2
   설계엔 없는 것"이 여기서만 보인다.

**실측 환경**: `luau` / `luau-analyze`
(`~/.local/share/mise/installs/luau/latest`), `python3`, 2026-08-25 실행,
작업 트리는 이 패스 시작 시점 상태 그대로(커밋되지 않은 변경 없음).
**아래에서 `pesde` 링크를 실제 디렉토리로 치환한 구간이 있으나 검증 후
전부 원상복구했고**(심볼릭 링크 20개, `git status` 클린), 그 폴더들은
전부 `.gitignore` 대상이라 저장소 파일은 손대지 않았다.

**이 패스의 범위**: 커밋된 `quad-base/src/`(`init.luau`/`Relate.luau`/
`Debug/init.luau`) · `quad-types/src/` · `type-version-check/src/` ·
`quad-base/test/` 3개 · 루트 `pesde.toml`/`.luaurc`/`default.project.json`/
`mise.toml` · `.claude/luau-test/`(`STATUS.md` + `done/` 전량) ·
`base/store-plan.md` 런타임 절 · `base/attribute-plan.md` 그룹 절 ·
`base/modifier-plan.md` 7번 · `base/source-state-plan.md`의 온톨로지·전파
모델·`:With` 절 · `base/state-epoch-plan.md` §2 · `base/quad-types-plan.md` ·
`base/project-setup-plan.md` · `base/relate-plan.md` · `ROADMAP.md` M1/M2/M7.
**1·2차 패스(`H-55`~`H-76`)와 겹치는 항목은 없다** — 겹칠 뻔한 자리는
항목 안에 "이건 `H-xx`와 별개다"로 적었다.

---

## 🔴 `H-77` — `Relate`의 *내부 키*가 `inst`를 되참조하면 `SetStrong`/`SetWeak` **둘 다** 샌다 (실측)

**어디**: `base/relate-plan.md`의 "위험한 패턴 — 서로 다른 두" 절,
`base/module-lifecycle-plan.md`의 "New()의 내부 구성 — InitXxx 팩토리 체이닝" 절,
그리고 **실제로 커밋된 `quad-base/src/init.luau`**.

**`H-71`과 무엇이 다른가**: `H-71`은 `SetStrong(inst, key, **value**)`의
**값**이 `inst`를 되참조하는 경우였고, 결론은 *"`SetWeak`은 안전하다"*
(케이스3이 0/50)였다. 이 항목은 **가운데 인자(`key`)** 다. `Relate`의
실제 구조상 —

```lua
-- quad-base/src/Relate.luau, 커밋된 그대로
buckets[inst] = bucket          -- buckets는 __mode = "k"
bucket.StrongMap[key] = value   -- 평범한 테이블 → 키·값 모두 강함
bucket.WeakMap  = setmetatable({}, { __mode = "v" })   -- **값만** weak
```

`WeakMap`이 `__mode = "v"`이므로 **`SetWeak`도 키는 강하게 잡는다.**
그래서 키가 `inst`를 잡으면 `buckets`의 weak 키가 자기 자신의 버킷을
통해 살아남는다 — `SetStrong`이든 `SetWeak`이든 똑같이.

**실측 1 — 커밋된 `Relate.luau`를 그대로 require**:

```lua
local Relate = require("./Relate")
-- 대조군: 내부 키가 inst를 캡처하지 않음
local keyFn = function() return i end        -- → 50개 중 0개 생존
-- 케이스: 내부 키가 inst를 캡처
local initFn = function() return inst end    -- → 50개 중 50개 생존
-- 같은 모양을 SetWeak으로                    -- → 50개 중 50개 생존
```

```
[대조군 — 키가 inst 미참조]  0
[케이스 — 키가 inst 캡처]   50
[SetWeak — 키가 inst 캡처]  50   ← H-71의 해법 (b)가 여기선 안 듣는다
```

**실측 2 — 커밋된 `quad-base/src/init.luau`의 `RunInit`이 실제로 물린다.**
그 파일은 `runInitRelate:SetStrong(self, initFn, true)`로 **함수 자신을
내부 키**로 쓰고, 바로 위에 이렇게 적어뒀다:

> `New()가 몇 번 불려도 module마다 weak-키잉되므로 별도 정리 불필요(module이 GC되면 이 기록도 같이 사라짐).`

`initFn`이 module을 캡처하는 순간 이 주석이 거짓이 된다:

```lua
local Quad = require("../src")
-- A: initFn이 module을 캡처하지 않는 정상형
local function initFn(m) m.tagA = true end
for i = 1, 30 do local q = Quad.New(); q:RunInit(initFn); canaryA[i] = q end
-- B: initFn이 바깥 module 변수를 캡처
for i = 1, 30 do local q = Quad.New(); q:RunInit(function() q.tagB = true end); canaryB[i] = q end
```

```
[A] initFn이 module 미캡처 — 살아남은 module 수: 0
[B] initFn이 module 캡처   — 살아남은 module 수: 30
```

`runInitRelate`는 **모듈 레벨 상수**라 프로세스 수명 내내 산다. 즉 B
모양으로 `RunInit`을 쓰면 그 `New()` 인스턴스는 **영원히 안 죽는다.**
`q:RunInit(function() ... q ... end)`는 특별히 이상한 코드가 아니다 —
`initFn(self)`가 `self`를 주긴 하지만, 바깥 변수를 그냥 쓰는 게 더 짧아서
자연히 나온다.

**어느 서술이 틀렸나**: `relate-plan.md`의 규칙 문단은 위험을 전부
**"값"** 기준으로만 서술한다 — *"어떤 값(`inst` 아닌 임의 객체 …)을 다른
`Relate`의 바깥 키로 쓰고 싶어지면 … 그 값 자체가 `inst`로 되돌아가는 강한
back-reference를 갖고 있는지 먼저 확인할 것"*. **`Relate` 자신의 두 번째
인자(내부 키)는 이 문서 어디에도 등장하지 않는다.** `H-71`이 이미 그
절 전체를 다시 쓰기로 만들어놨으니, 다시 쓸 때 **슬롯을 셋으로 나눠**
적어야 한다:

| 슬롯 | `SetStrong` | `SetWeak` |
|---|---|---|
| 바깥 키(`inst`) | weak(설계) | weak(설계) |
| 내부 키(`key`) | **강함** | **강함** ← 여기 규칙이 없었다 |
| 값(`value`) | 강함(`H-71`이 다룸) | weak |

**갈래(결정 전 목록)**:
(a) **규칙만 넓힌다** — "`Relate`의 내부 키로 쓰는 객체는 `inst`를 되참조하면
안 된다(문자열/숫자/`inst`와 무관한 값 객체만)"를 못박고, 지금 내부 키가
객체인 자리를 전수 확인한다. 실제로 객체를 내부 키로 쓰는 건
`runInitRelate`(함수)와 `groupClaimKeys`(그룹 `Attribute` 값 객체) 둘뿐이고,
뒤는 값 객체가 `inst`를 안 잡으므로 안전하다 — **확정적으로 물리는 건
`RunInit` 하나다.**
(b) **`RunInit`의 키를 바꾼다** — 함수 자신 대신 호출부가 주는 이름/토큰을
키로 쓴다. 다만 `module-lifecycle-plan.md`가 "함수 자체를 릴레이션 키로 쓴다"를
**센티널을 없애는 근거**로 확정해뒀으므로(위 절 참고) 이걸 되짚는 셈이 된다.
(c) **`Relate`에 내부 키까지 weak인 저장 모드를 추가한다** — `__mode = "kv"`
서브맵. 표면이 하나 늘고, ephemeron이 없으므로 이번엔 **키가 값을 잡는**
반대 방향 문제가 생긴다(값이 `true`인 `runInitRelate`엔 무해).
(a)가 제일 싸고 `H-71`의 규칙 재작성과 한 번에 끝난다. 어느 쪽이든
**`quad-base/src/init.luau`의 그 주석은 지금 거짓이므로 같이 고쳐야 한다.**

**이건 `H-71`과 별개다** — 같은 파일의 같은 절을 고치게 되지만, `H-71`의
해법 (b)(`SetStrong` → `SetWeak`)가 **이 경우엔 아무 효과가 없다**는 게
실측으로 확인됐으므로 따로 결정해야 한다.

## 🔴 `H-78` — 커밋된 M1 스모크 2개와 타입 스파이크 `23`이 지금 저장소 상태에서 안 돈다 (실측)

**어디**: `ROADMAP.md` M1의 *"`quad-base/test/mock.luau` + `smoke.*.luau`, 전부 PASS"* /
*"`RunInit`/`AddPlugin`으로 구현·smoke 테스트 검증 완료"*,
`base/project-setup-plan.md`의 "워크스페이스 의존성은 심볼릭 링크로 연결된다" 절,
`.claude/luau-test/STATUS.md`(스파이크 `23`이 `done/`).

**실측 — 이 패스 시작 시점의 저장소 상태 그대로**:

```
$ luau quad-base/test/smoke.init.luau
error while running module: ./quad-base/src/init.luau:17: error while running
module: error requiring module "./.pesde/qwreey+quad_types/0.0.0/quad_types/src":
could not resolve child component "src"

$ luau quad-base/test/smoke.plugin.luau      → 같은 에러
$ luau quad-base/test/smoke.mock.luau        → ALL PASS  (src를 require 안 함)
```

**원인은 심볼릭 링크다 — 격리해서 확인했다.** 이 `luau` CLI는 require
경로에 심볼릭 링크가 끼면 디렉토리든 파일이든 해소하지 않는다:

```lua
require("./real/src")   -- 실제 디렉토리 → ok
require("./linked")     -- 같은 곳을 가리키는 심볼릭 링크 → could not resolve child component
```

`pesde`의 워크스페이스 링크가 전부 심볼릭 링크이므로(`find -type l` → 20개),
`quad-base/src/init.luau`가 `quad_types`를 require하는 순간 걸린다.

**⭐ 더 나쁜 쪽은 타입 검사다 — 실패가 "진단 0건"처럼 보인다.**

```
$ luau-analyze quad-base/src/init.luau quad-base/src/Relate.luau ... 
quad-base/roblox_packages/quad_types.luau(1,16): TypeError: Unknown require: unsupported path
quad-base/roblox_packages/quad_types.luau(2,21): TypeError: Unknown type 'module.Quad'
./quad-base/src/init.luau(37,3): TypeError: Cannot call a value of type *error-type* ...
```

즉 **`Quad` 타입 계약이 quad-base 쪽에서 아예 안 보인다.** 그리고
`done/`에 들어 있는 `23-type-quadtypes-checkversion-addplugin.luau`는
이 상태에서 **자기 음성 대조군이 한 건도 안 뜬다**:

```
$ luau-analyze .claude/luau-test/done/23-type-quadtypes-checkversion-addplugin.luau
quad-types/luau_packages/type_version_check.luau(1,16): TypeError: Unknown require: unsupported path
quad-types/luau_packages/type_version_check.luau(2,45): TypeError: Unknown type 'module.CheckVersion'
```

그 파일이 검증하려는 것(버전 불일치 시 진단)은 **한 줄도 안 나온다.**
`base/project-setup-plan.md`가 이미 경고해둔 실패 모드 그대로다 —
*"`luau-analyze`가 진단 0건이어도 타입이 제대로 해소됐다는 뜻이"* 아니다.

**대조 — 문서가 적어둔 워크어라운드를 적용하면 전부 정상이다.**
심볼릭 링크 20개를 실제 디렉토리 복사본으로 치환하고 다시 돌리면:

```
smoke.init.luau    → === ALL PASS ===
smoke.plugin.luau  → === ALL PASS ===
luau-analyze quad-base/src/... quad-types/src/... type-version-check/src/...  → 진단 0건
스파이크 23        → TypeError: type-version-check: version "9.9.9" does not match pattern "0.0.0"
                     (정확히 의도한 음성 대조군 1건, 그 외 0건)
```

**즉 설계도 코드도 멀쩡하다 — 빠진 건 "이 저장소를 돌릴 수 있게 만드는
단계"가 어디에도 절차로 없다는 것이다.** `project-setup-plan.md`는 그
치환을 **과거에 한 번 손으로 했다는 기록**으로만 적어두고 스스로
*"아직 반복 가능한 스크립트/mise task로 정식화하진 않음"*이라고 밝힌다.
그 사이에 —

- `ROADMAP.md` M1의 "전부 PASS"에는 **날짜도 전제조건도 없다** —
  `conventions.md`의 시한부 주장 규약(날짜를 붙일 것)에 걸리는 자리인데
  `doc-check.py`는 이 문장 모양을 안 잡는다(실제로 지금 ERROR 0이다).
- `luau-test/STATUS.md`는 `23`을 `done/`에 두고 실행법을
  `luau-analyze <파일>`이라고만 적는다 — 그대로 따라 하면 위 상태가 된다.
- **작업 트리가 이 패스 시작 시점에 이미 실패 상태였다.** 즉 그 사이의
  어떤 세션이 `luau-analyze`를 돌렸다면 **거짓 클린**을 받았다.

**왜 지금 이게 M2 문제인가**: M2는 **`quad-types`의 `Quad`에 필드를 추가하는
첫 마일스톤**이고(`ROADMAP.md` M2의 `H-25` 파생 항목, 아래 `H-80`), 그
추가가 실제로 먹었는지 확인하는 유일한 수단이 정확히 지금 조용히 망가져
있는 그 경로다.

**갈래**: (a) 치환을 `mise` task(또는 `.claude/tools/`의 스크립트)로
정식화하고 `project-setup-plan.md`/`STATUS.md`/`ROADMAP.md`가 그걸
가리키게 한다 — 문서가 이미 *"이 시점에 정식 스크립트화를 고려할 것"*이라
예고해둔 선택지다. (b) 그 스크립트가 없으면 진단이 무의미하다는 걸
`luau-test/README.md`/`STATUS.md`의 실행법 줄에 명시한다(최소 조치).
(c) `ROADMAP.md` M1의 "전부 PASS"에 **날짜와 전제조건**을 붙인다.
셋 다 서로 배타적이지 않다.

**이건 `H-25`(닫힌 `Quad` 레코드)와 별개다** — 그쪽은 타입이 **좁아서**
에러가 나는 것이고, 이쪽은 타입이 **아예 안 보여서** 에러가 안 나는 것이다.

## 🟡 `H-79` — `Store`에 열거 표면이 없는데 그룹 `Attribute`가 그걸 요구한다 (실측)

**어디**: `base/attribute-plan.md`의 "그룹 `Attribute(...)` — 여러 Store를 한 번에 attribute로" 절
(`attr:NameMap(): {[string]: Source<any>}`, 그리고 *"각 Store에서 이름 붙은
`Source` 슬롯을 그대로 가져와 자기 자신의 key→Source 맵에 넣는 것"*),
같은 문서의 "메커니즘 — 그룹 전용 키로 단일 키 경로에 위임" 절
(`for name, source in pairs(v:NameMap()) do`),
`base/store-plan.md`의 "Store = Source들의 이름 붙은 모음" 절.

**무엇이 어긋나나**: `Attribute(store)`는 Store를 **이름 집합으로 평탄화**해야
하는데, `store-plan.md`는 열거 표면을 하나도 정의하지 않는다. 남는 건
`pairs(store)`뿐이고, 그건 **raw 키만** 준다 — 그런데 같은 문서가 확정한
Store 모델은 **eager + lazy**다:

> `Store<<SomeType>>()`처럼 `defaults` 없이 만든 뒤 `.Key:Set(v)`를 부르는 경우

이 형태의 Store는 **생성 직후 raw 키가 하나도 없다.**

**실측** — 확정 스케치를 그대로 옮긴 최소 모델(eager `table.clone` +
lazy `__index` + `rawset`):

```lua
local s1 = Store({hp = 10, mp = 5})
local n = 0; for k in s1 do n += 1 end          --> 2

local s2 = Store()          -- Store<{hp:number, mp:number}>() 상당
local n2 = 0; for k in s2 do n2 += 1 end        --> 0   ← Attribute가 볼 이름이 없다
local _ = s2.hp             -- 어딘가에서 한 번 읽히면
local n3 = 0; for k in s2 do n3 += 1 end        --> 1   ← 이제 1개
```

```
eager store 열거 개수: 2
lazy-only store 열거 개수(Attribute가 볼 이름 수): 0
hp 한 번 접근 후: 1
```

즉 `Attribute(store)`가 잡는 이름 집합이 **"그 시점까지 누가 어떤 키를
읽었는가"에 좌우된다.** 렌더 순서가 조금만 바뀌어도 attribute가 붙었다
안 붙었다 하는, 재현이 어려운 종류의 버그다.

**여기서 갈라지는 부수 질문 하나** — `:NameMap()`이 **생성 시점 스냅샷**인지
**호출 시점 라이브 조회**인지도 안 정해져 있다. `attribute-plan.md`의
`Attribute.Merged` 서술은 *"자기 자신의 key→Source 맵에 넣는 것"*이라
스냅샷처럼 읽히는데, 의사코드는 `process`마다 `v:NameMap()`을 다시 부른다.
스냅샷이면 위 타이밍 의존이 그대로 굳고, 라이브면 **같은 그룹 값이
디스패치마다 다른 키 집합을 내놓을 수 있어** 그 절이 확정한 "자기가
등록했던 키 전부를 걷어내는" 클로저 계약과 부딪힌다(클로저는 `keys`를
캡처하므로 실제론 안전하지만, 그러면 "라이브"인 의미가 없다).

**필요한 것**: 셋 중 하나를 M2에서 정해야 한다 —
(a) **Store가 선언된 키 집합을 런타임에도 안다** — `Store<T>(defaults)`가
`defaults` 없이도 이름 목록을 받을 수 있게 하거나, 타입 쪽 선언에서
런타임 목록을 만들 방법을 둔다(지금은 없다 — `store-plan.md`가 확정한
방어선이 *"런타임이 아니라 타입"*이라 런타임엔 선언 정보가 0이다).
(b) **`Attribute(store)`는 그 시점 materialize된 키만 본다고 계약으로
못박는다** — 그러면 `defaults`를 주는 게 사실상 필수가 되고, 그 사실을
`store-plan.md`/`attribute-plan.md` 양쪽에 적어야 한다.
(c) **Store에 명시적 열거 표면을 하나 둔다**(`store:Names()` 류) —
`Tag:Names()`/`attr:NameMap()`과 같은 계열이고, `H-73`/`H-74`가 이미
제기한 "예약 키냐 탑레벨 함수냐" 문제를 같이 받는다.

**이건 `H-74`(eager 경로가 `__index`를 우회한다)와 별개다** — 그쪽은
예약 키가 가려지는 문제이고, 이쪽은 **키가 아직 존재하지 않는** 문제다.
다만 둘 다 "eager와 lazy가 서로 다른 것을 보고 있다"는 같은 뿌리라
같이 보는 게 낫다.

## 🟡 `H-80` — M2가 `Quad`에 추가할 목록이 `Source`/`State`/`Store`뿐이다

**어디**: `ROADMAP.md` M2의 `H-25` 파생 체크박스(*"`quad-types`의 `Quad`에
`Source`/`State`/`Store` 필드 추가"*), `base/quad-types-plan.md`의
"`Quad` 타입 — 확정된 표면" 절과 "`AddPlugin<Self, P>` — 실측 검증된 플러그인 체이닝" 절,
`base/source-state-plan.md`의 "핵심 온톨로지" 절.

**두 가지가 어긋난다.**

**(1) `State`는 런타임 값이 아예 없다.** 코퍼스 어디에도 `State(...)`
생성자가 없다 — State는 `:With`/`:Compute`/`:Gate`로만 생기고, 같은
문서가 *"State는 쓰기 대상이 아님"*으로 확정해뒀다. 그래서 `Quad`에
넣을 수 있는 건 **타입 재수출**(`export type State<T>`)뿐인데, 체크박스는
`Source`/`Store`와 나란히 **"필드"**라고 적는다. 구현자가 그대로 읽으면
`Quad`에 `State: ???`를 만들려다 막힌다.

> **부수 — `state(state)`라는 옛 표기가 아직 살아 있다.**
> `source-state-plan.md`의 "핵심 온톨로지" 절이 State의 합성 모델을
> *"`state(state)`로 기존 state의 결과를 받아 새 state를 만들어 분기 가능"*
> 이라고 적고, `base/architecture.md`의 소스 트리 주석(`State.luau`)도
> *"state(state) 분기"*를 그대로 복사해뒀다. 이건 2026-08-04 시점 표기이고
> 실제 확정 표면은 `:With`/`:Compute`다 — **호출 가능한 `State(x)`가 있는
> 것처럼 읽히므로** (1)과 같이 정리하는 게 좋다.

**(2) M2가 얹는 나머지 탑레벨 값이 전부 빠져 있다.** 같은 마일스톤의
다른 체크박스들이 이미 요구하는 것만 모아도 —

| M2가 만드는 탑레벨 값 | 어느 체크박스가 요구하나 |
|---|---|
| `Effect(fn, ...deps)` | M2 "`Effect(fn, ...deps)`" 항목 |
| `is*` 전량(`isState`/`isSource`/`isObserver`/`isEffect`/`isEpoch`/`isStore`/…) | M2 `Brand.luau` 항목 |
| `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute` | M2 `LifetimeHandle.luau` 항목(*"네임스페이스 없이 탑레벨 함수로 export"*) |
| `Relate()` | M2 `Relate.luau` 항목 |
| `Blocker()` | M2 `Blocker.luau` 항목 |

`H-25`가 실측으로 확인한 벽은 *"`New(): Quad`가 닫힌 레코드이고 `RunInit`은
반환값이 없어 타입을 못 넓힌다"*였다. 그 벽은 `Dispatch` 하나에만 있는 게
아니라 **위 전부에 똑같이 있다** — `quad.isState(v)`도 `quad.Effect(fn)`도
지금 `Quad`엔 없으므로 `luau-analyze`에서 그대로 `Key not found`다.

**갈래**: (a) M2 체크박스의 목록을 위 표까지 확장하고, `State`는
"타입 재수출만"으로 명시한다(가장 싸다). (b) 규칙 자체를 *"그
마일스톤이 `quad-base`의 `init.luau`에 심는 모든 표면"*으로 다시 쓰고
마일스톤마다 목록을 안 세게 한다 — `quad-types-plan.md`의 그 절이 규칙의
정본이므로 거기서 한 번만 정하면 된다. 어느 쪽이든 `ROADMAP.md` M3의
같은 항목(`Dispatch` 기준)도 같이 봐야 한다.

## 🟡 `H-81` — `isModifier` 런타임 가드는 전부 M2 코드인데 체크박스는 M7에만 있다

**어디**: `base/modifier-plan.md`의 "7. State/Source가 Modifier를 값으로 담는 것" 절,
`base/source-state-plan.md`의 "따름정리 — `Store<T>`/`Source<T>`의 `T`는 Modifier가 될 수 없음" 절,
`ROADMAP.md` M7의 *"`State<Modifier>` 조합에 `isModifier` 기반 명시적 error 적용"* 체크박스.

**(1) 마일스톤이 어긋난다.** `modifier-plan.md` 7번이 확정한 적용 지점은
셋인데 **전부 M2가 쓰는 파일**이다:

- `Source:Set(value)` → `Source.luau`(M2)
- `Store({defaults})` 생성 시 각 키를 `Source(v)`로 만드는 시점 → `Store.luau`(M2)
- State의 `:Compute(fn)` 결과를 캐시로 저장하기 직전 → `State.luau`(M2)

판별자 `isModifier` 자체는 M2 앞머리 `Brand.luau` 항목에 이미 들어 있으므로
**M2 시점에 쓸 수 있다.** 그런데 체크박스는 M7에만 있고 **M2 체크리스트엔
한 줄도 없다.** 그대로 가면 (a) M2 구현자가 이 훅 자리를 모른 채 세 파일을
짜고, (b) M7이 M2 코드를 다시 열어야 하며, (c) 그 사이 **M4(첫 end-to-end
반응형 업데이트)가 가드 없이 돈다.**

**(2) 적용 지점 목록이 두 문서에서 다르다.** `source-state-plan.md`의
"따름정리" 절은 *"`Source<Modifier>`(Store를 거치지 않는 독립
`Source(someModifier)`)에도 동일하게 적용됨"*이라고 **독립 생성자**를
명시하는데, `modifier-plan.md` 7번의 적용 지점 열거엔 그 자리가 없다
(`Source:Set` / Store defaults / `:Compute` 캐싱 셋뿐). 구현자가
`modifier-plan.md`만 보면 `Source(someModifier)`가 그냥 통과한다.

**필요한 것**: (a) `ROADMAP.md` M2에 "위 세 자리(+ `Source(v)` 생성자)에
`isModifier` 게이트를 같이 심는다"를 항목으로 넣고 M7 항목은 그걸
가리키게 한다, (b) `modifier-plan.md` 7번의 적용 지점 목록에 독립
생성자를 추가해 두 문서를 맞춘다. 둘 다 순수 문서 작업이고 설계는 안
바뀐다.

## 🟢 `H-82` — `:With`를 실노드로 확정한 근거 2번이 pass-through 노드엔 성립하지 않는다

**어디**: `base/source-state-plan.md`의 "`:With`도 새 State 노드로 확정, 가변인자로 체인 남발 방지" 절의
근거 2번(*"공유 캐시를 못 타고 중복 계산이 생김. [2026-08-14 근거 재작성]"*).

**무엇이 어긋나나**: 그 근거는 `w = key1:With(key2)`에서 갈라지는
`c1 = w:Compute(g1)` / `c2 = w:Compute(g2)`를 들며 *"빌더면 `w`라는 노드가
아예 없어서 c1/c2가 key1/key2에 각자 직접 구독을 걸고 각자 계산하므로,
공유 지점이 사라짐"*이라고 한다. 그런데 **같은 절이 바로 아래에서
`:With` 노드를 "계산 함수는 없고 값은 `self`를 그대로 통과(pass-through)"**
로 확정한다.

계산이 없으므로 **공유될 계산이 없다.** `c1`은 `g1`을, `c2`는 `g2`를
돌리고, 그 둘이 읽는 `key1`/`key2`의 캐시는 **빌더든 노드든 어느 쪽이든
key1/key2 자신이 들고 있다.** 실노드 `w`가 실제로 아끼는 건 계산이
아니라 **엣지 수와 에포크 부기**다(`key1 → w` 하나 대 `key1 → c1`,
`key1 → c2` 둘 — `state-epoch-plan.md` §7의 맵 크기가 그만큼 덜 는다).

**왜 이게 눈에 띌 만한가**: 그 근거는 2026-08-14에 *"원래 이 항목은
`invalid` 플래그로 다이아몬드 중복 워크 방지 장치를 근거로 들었으나 그
장치는 폐기됨"*이라며 **일부러 다시 쓴 것**이고, 그러면서
*"근거의 강도는 이 재작성으로 오히려 올라감: 예전 근거는 순회 비용
최적화였지만, 지금 근거는 실제 중복 **계산**임"*이라고 스스로 평가한다.
실제로는 **정확한 서술(순회 비용)에서 부정확한 서술(중복 계산)으로
내려간 것**이다. 바로 위 "왜 State 체인을 Modifier처럼 플래튼하지 않는가" 절의
같은 논증은 `b = a:Compute(f)`(계산이 **있는** 노드)를 예로 들어서 맞는데,
그 논증을 계산이 없는 노드에 그대로 복사하면서 어긋났다.

**결론은 안 바뀐다** — 근거 1(디버그 그래프 1:1 대응)과 근거 3(clone이
Compute 노드의 캐시 슬롯까지 복사해 실제로 깨짐)이 그대로 유효하다.
근거 2를 "엣지/부기 공유"로 고쳐 적기만 하면 된다.

## 🟢 `H-83` — 확정된 Store 구현 스케치를 그대로 쓰면 무인자 `Store()`가 크래시한다 (실측)

**어디**: `base/store-plan.md`의 "Store = Source들의 이름 붙은 모음" 절 —
*"`defaults`는 선택(안 줘도 됨, 순수 편의용 초기값 템플릿)"*과, 같은 절의
확정된 구현 스케치 *"`local sources = table.clone(defaults); for k, v in
sources do sources[k] = Source(v) end`"*.

```
$ luau -e 'print(pcall(function() return table.clone(nil) end))'
false   invalid argument #1 to 'clone' (table expected, got nil)
```

`defaults`가 선택인데 스케치엔 `or {}`가 없다. **`table.clone(defaults or {})`**
한 곳만 고치면 된다 — 구현 시 자연히 걸릴 수도 있지만, 그 스케치는
*"성능 근거"*까지 붙여 확정된 문장이라 그대로 옮겨 적힐 가능성이 높다.
같은 자리에서 `Source()`(무인자 = `Source(nil)`)는 이미 확정돼 있으므로
추가 결정은 없다.

## 🟢 `H-84` — `:With`/`state:Block`/`Source:Emit`이 M2 체크리스트에 개별 항목으로 없다

**어디**: `ROADMAP.md` M2의 "반응형 본체" 절.

`:Compute(fn, ...)`·`state:Apply(factory)`·`state:Observer(fn)`·
`state:Gate(setup)`는 각각 체크박스를 갖는데, 다음 셋은 `Source.luau`/
`State.luau`/`Store.luau`라는 한 줄짜리 포괄 항목 안에만 있다:

- **`:With(...)`** — 새 노드를 만드는 프리미티브이고, `source-state-plan.md`가
  *"`:With`가 만드는 pass-through 노드는 계산 함수가 없어서"* 우연한 캡처가
  없다며 **미해결 항목(중간 State GC)의 핵심 사례로 지목**한 바로 그 자리다.
  그 미해결이 `question.md` 최우선 절에 있으므로, 체크박스가 없으면
  "결론이 어디에 반영돼야 하는가"가 로드맵에서 안 보인다.
- **`state:Block(b)`** — `Blocker.luau` 항목은 `:On()`/`:IsOn()`/
  `:OffWithoutEmit()`만 나열한다. **State 쪽 진입점**은 안 적혀 있는데,
  `blocker-plan.md`가 확정한 공개 API이고 `H-55`의 결정이 정확히 이
  진입점의 계약을 바꾼다.
- **`Source:Emit()`** — `state-epoch-plan.md` §8이 *"`Revision`만 갱신하면
  그대로 동작한다"*로 확정해둔 자리이고, `H-68`(같은 값 `Set`의 동작)의
  결정이 이것의 존재 이유를 바꾼다.

순수 로드맵 정합이라 🟢이지만, **`H-55`/`H-68`과 "중간 State GC"의 결론이
각각 어디로 가야 하는지가 지금 로드맵에 자리가 없다**는 뜻이라 그 셋을
결정할 때 같이 처리하는 게 낫다.

---

## 부록 — 3차 패스에서 돌려봤는데 **문제가 없던 것**

같은 각도로 훑었지만 실측 결과 문서와 일치했던 것들. 다음 라운드가
같은 곳을 다시 파지 않도록 남긴다.

- **`bit32.bnot(-rev)` 리비전 갱신** — `base/state-epoch-plan.md` §2의
  실측 표(`0 → 4294967295`, `1 → 0`, `2 → 1`, `4294967295 → 4294967294`)가
  **정확하다**. `0`에서 10회 돌려도 `4294967295`부터 1씩 내려가며 중복이
  없다. `-0` 입력(`rev == 0`)도 문서 서술대로 동작한다.
- **`python3 .claude/tools/doc-check.py`** — **ERROR 0건**, WARN 37건
  (전부 판단이 필요한 종류: `-followup.md`류 상대 표기, 날짜 없는 완결
  주장). 회귀 없음.
- **`luau-test/done/`의 런타임 스파이크 8개**(`02`/`03`/`06`/`07`/`11`/
  `17`/`18`/`20`) — **전원 재통과**, FAIL 문자열 0건.
- **`luau-test/STATUS.md`의 개수 표** — 실제 폴더와 일치
  (`done/` 16, `rewrite-required/` 7, `not-run/` 0+헬퍼 1).
- **타입 스파이크의 진단 개수** — 워크어라운드 적용 후 `08`/`09`/`12`/
  `13`/`14`/`16`/`21`/`23` 전부 각자 의도한 음성 대조군 수만큼만 뜬다
  (`08`의 `Recursive type being used with different parameters`는
  `base/typing-limits.md`가 확정한 **의도된** 결과다).
- **커밋된 `quad-base/src/*.luau`의 타입** — 워크어라운드 적용 시
  `luau-analyze` **진단 0건**. `H-78`의 에러는 전부 링크 해소 실패에서
  파생된 것이고 소스 자체의 타입 문제가 아니다.
- **`Relate.luau`의 `WeakMap` 공유 메타테이블/버킷 lazy 생성** —
  `base/relate-plan.md`의 "실제 구조" 절 서술과 커밋된 코드가 일치한다
  (문제는 코드가 아니라 `H-77`의 **규칙 쪽 공백**이다).


---

## 회신 방법

6라운드와 같다 — 항목 번호로 결정만 적어주면 `-followup.md`를 만들고
`base/`에 반영한다.

**1차 패스**: 🔴 다섯 중 `H-55`/`H-58`/`H-59`는 같은 자리(정책·핸들이
"손에 쥔 것"만으로 계약을 이행할 수 있는가)에서 나온 것이라 같이 결정하는
편이 낫고, `H-57`/`H-64`/`H-65`는 "`unbindLifetime`이 cleanup을 안 부른다"
결정의 호출부별 예외 목록이라 한 번에 보는 게 낫다. `H-56`/`H-62`는 전파
루프 의사코드를 한 블록으로 쓰면 둘 다 닫힌다.

**2차 패스**: `H-73`/`H-74`/`H-75`/`H-76`은 전부 **Store의 타입 합성 하나**
에서 갈라져 나온 것이라 같이 보는 게 낫고, 특히 `H-73`은 `question.md`
최우선 항목(콜론 메소드냐 탑레벨 함수냐)에 대한 **실측 근거**다 — 탑레벨
쪽을 고르면 `H-74`도 같이 사라진다. `H-71`은 다른 것과 독립이고 **가장
급하다**: 판정 기준 자체가 문서에 잘못 적혀 있어서, 고치지 않으면 앞으로
`SetStrong`을 쓰는 모든 자리가 같은 실수를 반복한다. `H-72`는 `H-55`와
같은 뿌리(`Epoch` 일반화 때 게이트 쪽 요구가 표면에 덜 반영됨)라 그것과
같이 결정하는 게 낫다.

**3차 패스**: `H-77`은 **`H-71`과 반드시 같이** 볼 것 — 같은 절을 고치게
되지만 `H-71`의 해법 (b)가 여기선 안 듣는다는 게 실측으로 확인됐다.
`H-78`은 설계 결정이 아니라 **작업 환경 결정**이라 다른 것들과 독립이고,
지금 상태로 두면 M2 내내 타입 검사가 조용히 무의미해지므로 **착수 전에
닫는 게 낫다**. `H-79`/`H-83`은 Store 런타임 하나에서 갈라져 나온 것이라
`H-73`/`H-74`와 같이 보면 되고, `H-80`/`H-81`/`H-84`는 전부 **로드맵
체크리스트가 실제 작업을 다 안 담고 있다**는 한 가지 문제의 세 얼굴이라
한 번에 고치면 된다. `H-82`는 순수 문서 정정이고 결론을 안 바꾼다.
