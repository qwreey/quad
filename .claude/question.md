# 확인/결정 필요 목록

**이 문서는 사용자가 답해야 할 것만 담습니다.** 이미 결정이 끝난 항목은
2026-08-13 아홉 번째 세션에 `archive/question-resolved.md`로 옮겼음 —
"해결된 게 너무 많아 필요한 부분만 읽기 어렵다"는 사용자 지적에 따른 것.
결정 내용은 안 바뀌었고 읽는 자리만 옮겼으니, 어떤 항목이 왜 그렇게
정해졌는지 되짚고 싶으면 그 문서를 볼 것(지금 유효한 설계 자체는 항상
`base/`가 소스).

**항목을 해소하면**: 여기서 지우고 `archive/question-resolved.md`에
근거와 함께 옮길 것 — 다시 쌓이면 같은 문제가 반복됨.

---

## ⭐ 최우선 — M0 착수를 막고 있음 (1건)

이 항목은 사용자가 **직접 스케치하며 판단하겠다고 명시 이관**한 것이라
에이전트가 기본값으로 밀고 갈 수 없음. 루트 `HUMAN_TODO.md` 4번에도 있음.

> **[2026-08-13 열세 번째 세션] 여기 같이 있던 `0-Y`(`:Compute(fn)`의
> lazy 핸들 계약)는 해소됨** — 실측 결론은 "계약은 그대로 두고, 파생
> State를 만드는 자리마다 결과 타입을 명시 주석으로 바인딩한다. 그 외는
> Luau의 현 한계라 지금 우리가 할 수 있는 바 없다". 지금 유효한 규약은
> **`base/typing-limits.md`**, 실측 근거 전문은
> `audit/type-recursion-issue/`, 해소 전 원문은
> `archive/question-resolved.md`의 0-Y 절.

### 0-Z. ⭐ **최우선 — Attribute 이름 소유권을 무엇으로 판정할 것인가** (2026-08-13 여섯 번째 세션, 사용자가 다음 세션 심층 분석으로 이관)

**이게 지금 유일하게 `base/` 반영을 막고 있는 결정.** 아래 0-A의
재디스패치 모델은 나머지가 전부 확정됐고, 이 항목 하나만 정해지면
⚠️ 배너를 단 **7개 문서**(`bind-system-plan.md`/`tag-plan.md`/
`slot-plan.md`/`attribute-plan.md`/`ref-plan.md`/`architecture.md`/
`ROADMAP.md` — `ref-plan.md`는 9차 세션 분할 때 배너가 같이 안 옮겨간
걸 10차 세션 감사에서 발견해 추가)를 한 번에 옮기면 됨.

**문제**: 새 모델(핸들러 선비교)에서는 그룹 A가 잡아둔
`AttributeKey("foo")` 인덱스 1에 그룹 B가 들어와도 **양쪽 다 `StoreBind`에
매치되므로 "같은 핸들러"로 판정돼 조용히 갈아탐.** 그리고 나중에 A의
클로저가 자기 이름들을 `retractFrom`할 때 B의 바인딩을 대신 철거함
(교차 오염). 예전 "조용한 last-write-wins"가 그대로 돌아옴 — 이번 감사에서
고쳤던 바로 그 증상. 즉 **Dispatch의 점유 체크가 대신 잡아주던 걸 이제
Attribute가 직접 해야 함.**

**사용자 방향(2026-08-13, 심층 분석은 다음 세션)**:
> "Attribute 소유권은 아마 이전 결정을 다시 가져오는게 맞아보이긴 하네요.
> 막 깊게 Key -> Group 필요한것 같지는 않고, 본인 retract 처리를 수행할 때
> 무언가 하면 될듯 한데. 이 부분은 나중에 제가 물리적으로 스케치 해보며
> 심층 분석해보겠습니다."

- **"이전 결정을 다시 가져온다"** = 2026-08-13 네 번째 세션의 이름별
  claimant `Relate`(당시 이름 `owners`). **당시 기각 사유는 새 모델에서
  구조적으로 소멸함** — 그때 버그는 "소유권 반납이 `process`의 `v==nil`
  분기에만 있어서, 그룹이 이름을 통째로 놓는 경로가 그 분기를 안 타
  옛 소유권이 안 지워짐"이었는데, 지금은 **클로저가 항상 불리므로 거기서
  반납**하면 그 구멍이 안 생김. 사용자의 "본인 retract 처리를 수행할 때
  무언가 하면 될듯"이 정확히 이 지점.
- **"막 깊게 Key → Group 필요한 것 같지는 않다"** — 키에서 그룹으로
  거슬러 올라가는 양방향 레지스트리까지는 필요 없고, 이름 → 현재
  claimant 단방향이면 충분할 것이라는 방향.
- 원문 맥락과 기각된 두 중간안(`rawNew` 전용 키, `AttributeGroupKeyHandler`
  체크포인트)은 `archive/checkpoint-handler-pattern-reversed.md`,
  분석은 `research/dispatch-redispatch-diff-plan.md` 5절.

**대안 후보(정리해둠)**: (a) 이름별 claimant `Relate`를 Attribute에
국소적으로 — 권고, (b) UB로 두고 문서로만 금지 — 증상이 "조용한 오작동 +
교차 오염"이라 다른 UB들(즉시 스택오버플로/즉시 error)보다 나빠서 비권장,
(c) `Dispatch`에 claimant 개념 일반화 — 이번에 걷어낸 방향이라 반대.

## 결정 대기 — M0는 안 막음

### 0-W. 같은 `Ref` 객체가 두 자리에 놓이는 걸 막을 것인가 (2026-08-13 열세 번째 세션 신설, 0-Z 확인 중 발견)

**0-Z(Attribute)를 보다가 "Ref에도 같은 문제가 있냐"는 사용자 질문에서
나온 것 — 있고, 막는 장치가 전혀 없음.** 단 메커니즘은 0-Z와 **반대
방향**이라 별개 항목으로 분리: Attribute는 *두 소유자 → 한 자리*(이름별
메모이즈된 키라 수렴), Ref는 *한 객체 → 두 자리*(발산).

**손 트레이싱**(`base/ref-plan.md`의 `RefLeafHandler` 의사코드에 대입,
`Frame1 { Ref = r }` / `Frame2 { Ref = r }`):

1. `process(inst1,"Ref",r)` → `relate[inst1]["Ref"]`가 nil → `r:Set(inst1)`
2. `process(inst2,"Ref",r)` → `relate[inst2]["Ref"]`도 nil(**다른 키**) →
   `r:Set(inst2)` — inst1 바인딩이 **조용히 유실, 에러 없음**
3. inst1 자리가 retract → `hintValue(nil) ~= v(r)` → **`r:Set(nil)`** —
   inst2가 정당하게 들고 있던 값을 지움(교차 오염)

`relate`가 `(inst,k)`별로만 있어 "이 Ref가 이미 다른 자리에 있다"를
원천적으로 못 봄.

**형제 프리미티브 대조 — Ref만 비어 있음**:

| | 공유 자원 | 방어 | 상태 |
|---|---|---|---|
| `Slot` | element | `claimOwner`/`claimOwnerAt` → 즉시 error(`Slot{a,a}`/`Frame{slot,slot}`) | 막힘 |
| `PreRef` | 자기 자신 | `_fired` → 재사용 시 error | 막힘 |
| `Tag` | 태그 이름 | 위치별 참조 카운트 — 겹침이 **의도된 동작**(합집합) | 설계상 정상 |
| `Attribute` | 이름 | 없음 | **0-Z** |
| **`Ref`** | 자기 자신 | **없음** | **이 항목** |

특히 걸리는 두 가지:
- **`PreRef`는 정확히 이 재사용을 error로 막고**, 문서가 "`Slot:List`의
  `updateFn`처럼 반복 호출되는 자리에선 매번 새 `PreRef()`를 만들라"는
  관용구까지 명시해뒀음 — **일반 `Ref`는 같은 자리에서 같은 실수를 해도
  아무도 안 막음**(비대칭).
- 스파이크 `19`가 Tag/Attribute/Slot 소유권은 음성 대조군까지 넣어
  검증하는데 **`Ref`만 커버가 없음**.

**0-Z와의 관계 — 독립**: 이건 하강 diff 모델이 만든 회귀가 **아니라
원래부터 있던 갭**(점유 체크는 같은 `(inst,k,index)`만 봤지, 서로 다른
자리를 가로지르는 건 원래 안 봤음). 0-Z를 어떻게 정하든 별도 결정이고,
0-Z와 달리 **M0를 막지 않음** — 다만 사용자가 소유권 설계를 스케치할 때
같이 보는 게 자연스러움.

**선택지**: (a) `Slot`/`PreRef`와 같이 즉시 error(일관성 높음, `Relate`
하나로 Ref→현재 자리 추적), (b) UB로 두고 문서화만(현상 유지 —
단 증상이 "조용한 값 소실"이라 다른 UB보다 나쁨), (c) 마지막 쓰기 승리를
정식 동작으로 인정(비권장, `Ref`의 "확정된 값 박스" 의미와 충돌).

### 0-A. `hintValue` 폐기 → process 하강 중 핸들러 비교 (2026-08-13 여섯 번째 세션, **Attribute 건 외 확정**)

**검토 결과 사용자 지적이 맞음 — 현행 `hintValue`엔 실제 결함이 있음.**
힌트가 "그 자리에 곧 디스패치될 raw 값"이라 `None` 센티널이나 `State`/
`Tween` 같은 래퍼가 그대로 넘어갈 수 있고, 그러면 말단 핸들러의
`isTag(hint)` 가드가 거짓이 되어 **깜빡임/재생성 방지가 조용히 꺼짐**
(정확성은 유지돼서 지금까지 안 드러났음). 상세 재현·분석·제안은
`research/dispatch-redispatch-diff-plan.md`.

**후속 라운드에서 모델은 거의 확정됨** — 래핑 핸들러가 `retractFrom`을
선행 호출하는 걸 폐기하고, `Dispatch.process` 안에서 **핸들러를 먼저
비교**해 (같으면 그 자리 클로저에 새 값을 넘기고 자기 `process` 재호출,
다르면 그 자리부터 아래를 전량 철거). 이걸로 (a) 힌트의 타입이
구조적으로 보장되고(같은 핸들러일 때만 값이 넘어가므로), (b) 깊은 체인의
힌트 유실도 사라지며(각 레벨이 자기 재프로세스에서 자기 힌트를 받음),
(c) `oldValue`를 따로 넘기자던 보완안은 불필요해짐(사용자 지적:
"클로저라 이미 본인이 알지 않아요?" — 맞음, `chains`에 추가로 저장할 건
비교용 `handler` 하나뿐), (d) `HandlerChanged` 마커도 불필요(핸들러가
바뀌었다는 건 retractor가 `nil` 힌트로 불린다는 사실로 이미 표현됨).

**남은 열린 항목은 Attribute 이름 소유권 하나뿐 — 위 0-Z로 분리해
최우선 배치**(사용자가 다음 세션에 직접 스케치하며 심층 분석하기로).
그 하나 외에는 이 항목에 결정할 게 없음.

**실행 규모**: `base/`의 `bind-system-plan.md`/`tag-plan.md`/`slot-plan.md`/
`attribute-plan.md`/`ref-plan.md` 의사코드 재작성 + `architecture.md`
소스트리 서술과 `ROADMAP.md` M2/M4/M6/M10 체크리스트 — 0-Z 하나만 정해지면
한 번에 옮기면 됨(어디를 어떻게 고칠지는
`research/dispatch-redispatch-diff-plan.md` 6절에 파일별로 적어둠 — 뒤
셋은 2026-08-13 7차/10차 감사에서 그 목록에 빠져 있던 걸 발견해 추가).
**그때까지 `base/`의 현행 `hintValue` 서술이 유효** — 아직 안 옮겼다는 걸
잊고 base만 읽으면 옛 모델로 구현하게 되니 주의.
### 0-B. `dispose(any)` — 시그니처/범위 (2026-08-13 여섯 번째 세션 신설, 사용자 제안)

`State<Slot>` 교체를 파괴가 아니라 **언마운트**로 확정하면서(`state<Frame>`와
동일, `base/slot-plan.md`), 명시적 파괴 수단으로 base 탑레벨 `dispose(value)`를
제공하기로 방향 확정. "이 값이 지금 어디 마운트돼 있는가"는 이미
`elementOwner`가 들고 있어(다중 마운트 error 판정용) 새 부기가 필요 없음.

**[확정, 사용자] 시맨틱은 "거부"** — 대상이 아직 어느 트리에 의해
살아있길 요구되고 있으면 **파괴를 거부하고 즉시 error**. 떼어내주지
않음(떼어내는 건 `Set`=언마운트의 몫, `dispose`는 그 뒤). 근거: 엔진은
`Destroy`/`Clear`에 에러를 안 내지만 quad의 `_elements`/`lengthList`/
`sourceList`/`elementOwner`는 그 순간 어긋나므로, **quad가 관리 중인 값을
안전하게 지우는 유일한 경로**가 이것이고 "지금 지우면 안 되는 상태"를
잡아주는 게 존재 이유. 이걸로 "`Set` 전에 직접 `Destroy()`"가 UB에서
명확한 에러로 바뀜.

**미확정**: 시그니처(`dispose(any)`가 맞는지, 타입을 어떻게 좁힐지),
대상 범위(Slot 외에 Instance/Observer/Effect까지 커버하는지),
`unbindLifetime`과의 역할 분담.

## 1. 용어 정리 — 아직 안 정해진 것만 (사용자 요청, 진행 중)

사용자 원 메모: "quad는 register라던가 좀 부정확하거나 느낌이 바로 와닿지
않던 용어들이 많음 — 전체적 용어를 보고 생각해볼래? 제안을 줘, 나도 같이
볼게." **이미 확정된 이름**(`State`/`Relate`/`List`/`canBound`/`Ref`/
`PreRef`/`Peek`/`isState`/`None`/`NoneHandler`/`Handler`)의 근거는
`archive/question-resolved.md`.

- **`DI`(Declarative Instance, 1순위)**: "Dependency Injection"의 업계
  표준 축약어와 완전히 겹침 — 4차 라운드에서 이미 한 번 실제로 오해가
  있었던 전례(`base/bind-system-plan.md`의 "인스턴스 생성" 절 참고).
  **파급 효과(2026-08-06 추가)**: `DI`가 리네임되면 `DI.FrameModifier`류
  Modifier 클래스별 타입 프리픽스도 같이 바뀌어야 함 — `DI` 리네임 논의
  때 이 연쇄까지 같이 고려할 것. **(2026-08-08 추가)** 사용자가 `D`(Declarative
  만 남김)로 축약하는 안을 제안 — 근거: (1) "Instance" 전용 개념이 아니라
  quad-* 전반의 declare 요소로 확장해도 되는 이름, (2) 엔진 종속 없이 다른
  백엔드에서도 재사용 가능, (3) 어차피 `D.FrameModifier`류 타입 프리픽스가
  길면 못 쓰므로 짧아야 한다는 실용적 제약. 아직 최종 확정 아님 — 다음
  세션에서 마저 논의(한 글자 식별자의 검색성/자기설명력 트레이드오프를
  문서에서 어떻게 보완할지도 같이).
- **`Slot`(2순위)**: Vue의 "slot"(콘텐츠 주입 지점)과 이름은 같지만 의미가
  다름(quad의 Slot은 자식 배열 재조정 프리미티브) — Vue 배경 있는 사람이
  헷갈릴 수 있음.
- **`canExecute`(3순위, 사소함)**: 실제로 "이 핸들이 아직 살아있나" 확인인데
  이름이 범용 권한 체크처럼 들림 — `isAlive` 쪽이 더 직접적이라는 제안이
  있었으나, **(2026-08-08 재검토)** `isAlive`는 top-level `isX` 계열
  (`isState`/`isRef`/`isPreRef`/`isModifier`/`isObserver`류 — 전부 타입
  판별자)과 접두어가 겹쳐 "이것도 타입 체크인가" 오해를 유발할 수 있다는
  점이 지적됨. `canExecute`는 타입이 아니라 liveness(생존 여부)를 묻는
  질문이라 `is`보다 `can` 계열 접두를 유지하는 쪽이 낫다는 방향으로 사용자가
  기욺 — 여전히 미확정, 다음에 `can`으로 시작하는 구체 대안(예: `canRun`)을
  같이 검토할 것.
- **`Brand`(3순위, 사소함, 2026-08-07 여덟 번째 세션 추가)**: 런타임
  nominal 타입 판별 통합 메커니즘(`Brand.set`/`Brand.get`, `isState`를
  10종 branded 타입 전부로 일반화) — `brand-plan.md`의 `Brand`
  절에서 동작/구현 방식은 확정, "OOP 인스턴스의 클래스명을 얻는 느낌"을
  전달할 더 나은 이름이 있는지가 열린 질문(사용자가 직접 제기) — `Tag`는
  이미 quad-roblox의 `CollectionService` 래퍼로 쓰여서 이름 충돌, 후보로
  "type namespace"류를 사용자가 검토했으나 미확정. **(2026-08-08 재확인)**
  사용자가 다시 짚었지만 여전히 미정.
- **`Tag`/`Added`/`Removed`/`Merged`(3순위, 사소함, 2026-08-08 세 번째
  세션 array-part 값 객체 재설계 때 확정된 API 표면)**: `base/tag-plan.md`가
  "열린 질문 없음, 값 모양/메커니즘/retract/패키지 배치 전부 확정, 이름
  자체만 용어 정리 대상"이라고 명시해뒀으나 이 목록에 반영이 안 돼 있던
  누락 — 이번에 추가. `Tag`는 Roblox `CollectionService`가 쓰는 용어와
  1:1 대응이라 그 자체로는 무난해 보이지만, 위 `Brand` 항목(97-99행)에서
  "`Tag`가 이미 이 뜻으로 쓰이고 있어서 충돌"이라는 이유로 `Brand`의
  대안 이름 후보에서 제외됐다는 점은 참고할 것 — 두 이름이 같은 코퍼스
  안에서 공존 가능한지도 같이 검토 대상.
- **`Attribute`/`AttributeKey`(3순위, 사소함, 2026-08-11 아홉 번째 세션
  추가)**: 여러 Store를 한 번에 attribute로 묶는 그룹 프리미티브
  (`Attribute(store1, store2, ...)`, `Tag`와 동형)가 신설되면서, 기존
  단일 키 생성자 `Attribute<<T>>("name")`를 이름 충돌 방지를 위해
  `AttributeKey<<T>>`로 잠정 리네임함(`OnChange`/`OnChangeKey`처럼 함수
  이름과 반환 타입 이름이 분리된 기존 전례와 대칭) — 해석 모호성 자체는
  이미 없앴으니 급하지 않지만, 최종 이름은 여전히 이 목록의 다른
  가칭들과 함께 검토 대상. `base/attribute-plan.md` "그룹 `Attribute(...)`"
  절 참고.
- **참고 — 이미 지나간 사례**: `register`(v1) → `State`(v2) 리네임은
  "모호함"은 풀었지만 "다른 뜻으로 이미 쓰이는 단어"라는 새 문제를 만든
  셈 — 이번 정리에서 같은 패턴을 조심할 것.
- `Store`/`Source`/`Modifier`/`process`/`retract`/`isHandlable`은 업계
  선례와 잘 맞거나 이미 신중하게 결정된 이름들이라 특별한 문제 없음.

## 3. 낮은 우선순위 — 열려 있지만 급하지 않음

- **`Operator` 콤비네이터 슈가 네임스페이스 이름+포함 범위(2026-08-12 신설,
  같은 날 후속으로 외부 리서치 완료)** — `Sum`/`Product`/`Not`/비트연산 등
  `:Compute`/`:Apply`용 슈가 함수 모음의 이름. 흔한 단어라 top-level
  노출은 위험, 후보는 `Operator`/`Op`/`Ops`(`Combinator`는 코퍼스 전반에서
  이미 일반명사로 쓰여서 제외) — **서브 에이전트 외부 리서치 결과 `Operator`가
  가장 선례가 강함**(Python `operator` 모듈)이나 최종 확정은 여전히 사용자
  몫. 같은 리서치에서 포함 범위도 새로 갈렸음 — 비트/비교 연산자 그룹과
  `Sub`/`Div`는 리액티브 콤비네이터로서 선례가 전혀 없어 드랍 후보로,
  `Clamp`/`Min`/`Max`는 선례가 강해 추가 후보로, Debounce/Throttle은
  업계에 흔하지만 `Blocker`와는 다른 시간 기반 메커니즘이라 이 카탈로그가
  아니라 quad-roblox 쪽 별도 프리미티브로 다룰지 판단이 필요한 별개 질문으로
  분리됨. **[2026-08-13 세션 신설]** `Alternative`(nil 대체값, coalesce/`??`/
  엘비스 연산자류) 후보 추가 — Haskell 비교 리서치 중 나옴, 카탈로그 확정
  규칙에 그대로 맞아 포함 근거는 있음. 상세는 `research/operator-sugar-plan.md`.
  구현 자체는 맨 마지막 우선순위(순수 슈가, 없어도 무방) — 여전함.
- **중첩 State 평탄화 `State<State<T>>` → `State<T>`(2026-08-13 여섯 번째
  세션 신설, 백로그)** — 인덱스 기반 `Dispatch` 재설계로 `State<State<T>>`는
  UB에서 정상 지원 대상이 됐지만, 깊이가 늘수록 `retractFrom`의 힌트가
  더 깊은 인덱스엔 `nil`로 전달돼 `Tag`/`Ref`/`Slot` 등의 힌트 기반
  최적화(깜빡임 방지)가 무력화되는 실제 기능 손실이 있음 — 값 층에서
  평탄화하는 `state:Flatten()`류 콤비네이터 아이디어는 나왔으나 착수 안
  함. 상세는 `research/operator-sugar-plan.md` 마지막 절.
- `research/existing-instance-bind-plan.md` — 스코프 논의만 필요, 구현
  착수를 막지 않음.
- **`quad-debug` 세부 API 이름** — `research/debug-tooling-plan.md` 참고.
  채널 실현 가능성(BindableEvent/Function이 플러그인↔Play 중 게임 경계를
  넘는지)까지 사용자가 Studio에서 직접 실측 검증 완료 — 기술적 불확실성은
  다 해소됨, 남은 건 세부 API 이름뿐("이벤트 함수가 self로 instance를
  읽는 게 quad 관습"이라는 언급은 2026-08-06 후속 세션에서 해소 —
  채택 안 함으로 확정, `base/event-plan.md` "이벤트 핸들러는
  self(Instance)를 받지 않는다" 절 참고). 사용자가 "quad 개발 완료 전엔
  착수 못 함"으로 직접 후순위 지정한 건 여전함 — base 설계(M2 Dispatch/
  M3 Source/M5 DI 생성자) 시점에 훅 확장 지점만 고려해두면 됨.
- **문서화 전략(UI 네이밍 컨벤션, Store 부작용을 게임 시스템에서 쓰는
  패턴)** — `research/documentation-plan.md`(뼈대만). 정식 백로그 항목으로
  올릴지, 착수 시점을 언제로 볼지 사용자 판단 필요.
- **v1 하위호환(compat) 레이어 — `quad-roblox-v1-compat`** —
  `research/v1-compat-plan.md`(신규, 2026-08-06, 두 차례 후속 논의로 수렴).
  방향 확정: v1을 그대로 병행 실행 + 경계에서만 `state:Observer()`(lazy
  포기)로 값을 리졸브해 v1 프로퍼티에 재대입하는 브리지, v2→v1 단방향만
  (양방향 불필요로 확정), 패키지명 `quad-roblox-v1-compat`으로 확정(소스
  트리에 세 번째 패키지로 추가될 예정). v2-in-v1/v1-in-v2 두 임베딩 방향
  모두 기술적 근거와 안전 규칙까지 정리됐으나(문서 7번), **Slot이 foreign
  Instance를 어떻게 다루는지만 Slot 코어 구현 시점까지 결정 불가로 남음**
  (위 "여러 Slot이 형제로 섞일 때 순서 보장" 항목과 같은 시점에 확인).
  그 외 §8의 세부 항목(v1 자기 루트의 `Destroying` 자기청소 여부,
  `registerClass` 체이닝 기능 브릿징 필요성)은 문서 자체가 "지금 결정
  불필요"로 표시해둠 — 위 Slot 항목과 별도로, 실제 compat 레이어 구현
  시점에 `research/v1-compat-plan.md` §8을 다시 열어 확인.
- **Slot이 quad 밖에서 만들어진 임의 Instance를 받을 수 있는가**
  (2026-08-06 추가, 아직 안 풀림) — v1 compat 등에서 넘어온 foreign
  Instance를 동적 배열 원소로 받을 수 있는지, retract 시 어떻게 다루는지.
  **Slot 코어 구현(M6) 시점에 확인** — `research/v1-compat-plan.md` 7-3.

> **없어진 번호에 대해**: 예전 "0번(추가 프리미티브)"과 "2번(구현 착수
> 직전 감사 결과)"은 전원 해소되어 통째로 `archive/question-resolved.md`로
> 갔음. 우선순위1 11개의 개별 상태가 궁금하면
> `research/pre-implementation-audit.md`가 원본이자 최신.

---
전체 순서/우선순위는 루트 `CLAUDE.md`가 최종 소스. 확정된 것들의 문서
색인은 `.claude/README.md`의 `base/` 표(예전에 이 문서 맨 아래에 있던
요약표는 그것과 중복이라 archive로 옮김).
