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

## ⭐ 최우선 — 설계 결정은 **없음**, 다만 순서 문제 하나 (2026-08-22 갱신)

> **[2026-08-22] 아래 2번(M2/M3 마일스톤 경계)이 M2 착수를 막습니다.**
> 그건 "무엇을 확정할까"가 아니라 "어떤 순서로 짤까"라 성격이 달라서
> 이 절이 아니라 2번에 뒀습니다 — **설계 결정 대기는 여전히 0건**입니다.

> **M0 착수를 막던 항목이 전부 해소됐습니다.** `0-Y`(`:Compute(fn)`의
> lazy 핸들 계약)는 열세 번째 세션에, `0-Z`(Attribute 이름 소유권)와
> `0-A`(재디스패치 하강 diff)는 열네 번째 세션에, **`0-W`(`Ref` 이중
> 배치 방지)는 2026-08-14 열한 번째 세션에 확정·`base/` 반영 완료** —
> 그래서 이 문서엔 이제 "결정 대기" 절 자체가 없음(비어서 헤딩째로
> 삭제). 해소 전 원문과 결론은
> `archive/question-resolved.md`, 뒤집힌 옛 재디스패치 모델은
> `archive/dispatch-hintvalue-model-reversed.md`.
>
> **M0 착수 전 읽을 것**: `base/typing-limits.md`(0-Y가 남긴 구현 규약),
> `base/dispatch-core-plan.md`(0-A/0-Z가 반영된 디스패치 코어 — 열네 번째
> 세션에 `bind-system-plan.md`에서 분리 신설).

## 1. 용어 정리 — 아직 안 정해진 것만 (사용자 요청, 진행 중)

사용자 원 메모: "quad는 register라던가 좀 부정확하거나 느낌이 바로 와닿지
않던 용어들이 많음 — 전체적 용어를 보고 생각해볼래? 제안을 줘, 나도 같이
볼게." **이미 확정된 이름**(`State`/`Relate`/`List`/`canBound`/`Ref`/
`PreRef`/`Peek`/`isState`/`None`/`NoneHandler`/`Handler`)의 근거는
`archive/question-resolved.md`. (`canBound`는 2026-08-14 다섯 번째 세션에
폐기돼 `canExecute`로 통합됐다가 **같은 날 열한 번째 세션에 별도 진입점으로
재도입**되어 여전히 이 목록에 있음 — 이중 바인딩 가드 전용이고 `canExecute`
(emit 게이팅 전용)와는 판정 로직만 공유. 아래 3번 `canExecute` 항목과
`base/lifecycle-pattern.md`의 "`canBound` vs `canExecute`" 절,
`archive/canexecute-inst-arg-reversed.md` 하단 addendum 참고.)

- **`Slot`(2순위)**: Vue의 "slot"(콘텐츠 주입 지점)과 이름은 같지만 의미가
  다름(quad의 Slot은 자식 배열 재조정 프리미티브) — Vue 배경 있는 사람이
  헷갈릴 수 있음.
- **`Owned`(3순위, 2026-08-21 신설)**: `:List`/`:Single`의 설치 시점
  플래그(기본 `true`, `false`면 어떤 경로로도 파괴 안 함).
  `elementOwner`/`claimOwner`/`releaseOwner`와 같은 뿌리라 골랐지만
  **잠정 이름**이다 — 형용사라 옵션 테이블 키로는 자연스러운데, 실제로
  묻는 건 "이 Slot이 요소의 수명을 책임지는가"라서 `OwnsElements`처럼
  주어를 드러내는 쪽이 나을 수도 있음. `base/slot-plan.md`의
  "소유권은 설치 시점에 정해진다" 절.
- **`canExecute`(3순위, 사소함)**: 실제로 "이 값이 아직 살아있나" 확인인데
  이름이 범용 권한 체크처럼 들림 — `isAlive` 쪽이 더 직접적이라는 제안이
  있었으나, **(2026-08-08 재검토)** `isAlive`는 top-level `isX` 계열
  (`isState`/`isRef`/`isPreRef`/`isModifier`/`isObserver`류 — 전부 타입
  판별자)과 접두어가 겹쳐 "이것도 타입 체크인가" 오해를 유발할 수 있다는
  점이 지적됨. `canExecute`는 타입이 아니라 liveness(생존 여부)를 묻는
  질문이라 `is`보다 `can` 계열 접두를 유지하는 쪽이 낫다는 방향으로 사용자가
  기욺 — 여전히 미확정, 다음에 `can`으로 시작하는 구체 대안(예: `canRun`)을
  같이 검토할 것. **[2026-08-14 다섯 번째 세션] 시그니처는
  `canExecute(value): boolean` 1-인자로 확정**(옛 `(inst, value)` 2-인자는
  폐기, `base/lifecycle-pattern.md`, `archive/canexecute-inst-arg-reversed.md`).
  **[2026-08-14 열한 번째 세션 정정]** 당시엔 `canBound`가 폐기돼
  `canExecute` 하나가 두 역할을 겸했으나, 이후 `canBound`가 별도
  진입점으로 재도입되며 다시 갈라짐(같은 문서의 "`canBound` vs
  `canExecute`" 절) — 이 이름 정리 항목은 이제 `canExecute`(emit 게이팅
  전용)에만 적용되고, `canBound`(이중 바인딩 가드 전용)는 별개 이름으로
  유지됨. 둘 다 판정 로직은 비공개 헬퍼 하나를 공유.
- **클로저 인자 이름 `hintValue`(3순위, 사소함, 2026-08-13 열네 번째
  세션 신설)**: 하강 diff 재디스패치에서 이 인자는 더 이상 "힌트"가
  아니라 **`nil`이거나 같은 핸들러가 곧 처리할 새 값**임이 계약으로
  보장됨(`base/dispatch-core-plan.md`) — 이름이 옛 모델의 잔재라
  `nextValue`류가 더 정확함. 코퍼스에 이미 널리 쓰인 이름이라 이번엔
  안 바꾸고 대기열에만 올림(의사코드는 새로 쓰는 자리부터 `nextValue`를
  쓰기 시작했음).
- **`Brand`(3순위, 사소함, 2026-08-07 여덟 번째 세션 추가)**: 런타임
  nominal 타입 판별 통합 메커니즘 — `base/brand-plan.md`에서 동작/구현
  방식은 확정, 이름만 열린 질문(사용자가 직접 제기). `Tag`는 이미
  quad-roblox의 `CollectionService` 래퍼로 쓰여서 이름 충돌, 후보로
  "type namespace"류를 사용자가 검토했으나 미확정. **(2026-08-08 재확인)**
  사용자가 다시 짚었지만 여전히 미정.
  - **[2026-08-21 갱신] 표면이 바뀌어서 "OOP 인스턴스의 클래스명을 얻는
    느낌"이라는 원래 요구는 이제 안 맞는다** — 인스턴스 브랜드로 재작성되며
    역조회(`Brand.get`)가 없어졌고, 지금 하는 일은 **집합 멤버십**
    (`SomeBrand:is(x)`)이다. 이름 후보도 그 방향으로 다시 볼 것.
  - **메소드 케이싱도 같이 볼 것** — `:register`/`:is`가 소문자인데 quad
    공개 표면 관례는 PascalCase다(`:Get`/`:Set`). base 내부 유틸이라 지금은
    기존 `Brand.set`/`Brand.get` 관례를 이었지만, 이름을 정할 때 같이 정리.
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

## 2. M2/M3 마일스톤 경계 — **M2 착수 전에 답이 필요** (2026-08-22 신설)

**M2(디스패치 엔진)와 M3(Store/State/Source)의 의존이 양방향이라,
`ROADMAP.md` 순서대로면 M2를 끝까지 짤 수 없습니다.**

- **M2 → M3 (본체 의존)**: `Dispatch.setLength`가
  `len: number | State<number>`를, `Dispatch.setOffsetSource`가
  `Source<number>`를 받고, `recompute`가 `offset:Set()`을 부릅니다
  (`base/dispatch-core-plan.md`의 "Length/Offset" 절). 2026-08-22에 M2로
  옮긴 `GateNode`/`Blocker`도 State 위에 얹힙니다. 즉 **M2는
  `Source.luau`/`State.luau` 없이는 구현이 안 됩니다.**
- **M3 → M2 (얕은 의존)**: `state:Observer`/`Effect`의 동적 경로 가드가
  `Dispatch.addHandler` + `Handler.luau` 계약을 씁니다 — 이건 레지스트리
  등록 표면만 있으면 되므로 M2 **전체**를 요구하지 않습니다.
  **⚠️ 다만 "M2 앞머리 두 항목(`Dispatch/init.luau` + `Handler.luau`)이면
  된다"고는 말할 수 없습니다** — `Dispatch/init.luau`에는 `Dispatch.drive`가
  들어 있고, `dispatch-core-plan.md`가 *"적용 지점 — `Dispatch.drive`와
  `attachSlot`, 각각 자기 owner 키로 별도 Blocker"*라고 확정해 `drive`도
  게이팅을 씁니다. 즉 그 첫 항목 자체가 State-free가 아닙니다. 선택지 (b)로
  쪼갠다면 `drive`를 어느 쪽에 두느냐가 경계선이 됩니다.

**선택지**:
- **(a) M2와 M3의 순서를 바꾼다** — 반응형(Source/State/EpochMap/Gate/
  Blocker)을 먼저 짜고 그 위에 디스패치를 올림. 얕은 쪽(가드 Handler)만
  뒤로 미루면 됨. 지금까지의 결정 흐름("게이팅 먼저")과 방향이 같음.
- **(b) M2를 둘로 쪼갠다** — `Dispatch.getHandler`/`process`/`retractFrom`/
  `Handler`/`Brand`/`Relate`/`chains`까지가 M2a, State가 필요한
  Length/Offset·게이팅은 M3 뒤의 M2b로.
- **(c) 지금 구조를 두고 구현 시 알아서 오간다** — 로드맵은 "순서"가
  아니라 "묶음"으로만 읽음.

**[2026-08-22 기준] 이 항목이 M2 착수를 막습니다** — `.claude/todos.md`
0번이 "M2 착수를 막는 설계 항목은 없다"고 하는 것은 **설계** 얘기이고,
이건 설계가 아니라 **순서** 문제라 별개입니다.

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
  업계에 흔하지만 `Blocker`와는 다른 시간 기반 메커니즘이라 이 카탈로그
  밖 별개 질문으로 분리됐었음 — **[2026-08-19 해소]** 그 별개 질문은
  `base/debounce-throttle-plan.md`로 전부 해소·승격 완료, 더 이상 판단
  대기 아님. **[2026-08-13 세션 신설]** `Alternative`(nil 대체값, coalesce/`??`/
  엘비스 연산자류) 후보 추가 — Haskell 비교 리서치 중 나옴, 카탈로그 확정
  규칙에 그대로 맞아 포함 근거는 있음. 상세는 `research/operator-sugar-plan.md`.
  구현 자체는 맨 마지막 우선순위(순수 슈가, 없어도 무방) — 여전함.
- **중첩 State 평탄화 `State<State<T>>` → `State<T>`(2026-08-13 여섯 번째
  세션 신설, 백로그)** — **[근거 축소, 열네 번째 세션]** 원래 이 항목의
  주 근거는 "깊은 체인에선 힌트가 `nil`로 전달돼 깜빡임 방지가 꺼진다"는
  실제 기능 손실이었는데, **하강 diff 재디스패치로 각 레벨이 자기 값을
  받게 되면서 그 손실 자체가 없어졌음**(`base/dispatch-core-plan.md`).
  남은 근거는 편의성과 Slot offset이 밀리고 당겨지는 케이스뿐이라
  우선순위가 더 내려감 — `state:Flatten()`류 콤비네이터 아이디어는
  그대로 백로그. 상세는 `research/operator-sugar-plan.md` 마지막 절.
- **[신설, 2026-08-18 커밋 전 `/code-review high`] `store:GetDynamic`을
  콜론 메소드로 둘지, 탑레벨 함수로 둘지** — 콜론 메소드로 두면 Store의
  lazy `__index`(없는 키를 인덱싱하면 그 자리에서 `Source`를 만들어 저장)와
  부딪혀서, `__index`가 고정 메소드 테이블을 먼저 확인해야 하고 그 결과
  **`GetDynamic`이 모든 Store의 예약 키 이름**이 된다(그 이름의 Source는
  dot-access로 못 만듦). Store 키는 사용자 도메인 데이터 이름이라 충돌
  확률이 `Modifier`의 예약 이름들보다 높다. 대안은 탑레벨
  `getDynamic(store, name)` — "특정 프리미티브에 안 묶인 범용 유틸은 소문자
  탑레벨"이라는 기존 네이밍 규칙에는 오히려 더 맞는다. **M3/M4 착수 전
  필요**, `base/store-plan.md`의 "타입 추론 문제" 절.
- **[신설, 2026-08-18 구현 전 QA] 중간 State GC 미검증** — `State → State →
  State → Observer` 체인에서 중간 노드를 강하게 붙잡는 주체가 문서 어디에도
  없어 전파가 조용히 끊길 수 있음. 방향(상류 strong / 하류 weak)은 사용자가
  지목했고, **명문화 여부 결정 + `luau-test` 실측이 M3 착수 전에 필요** —
  `base/source-state-plan.md`의 "미해결 — 중간 State가 살아남는가" 절.
- **[신설, 2026-08-14 리뷰] `AttributeGroupHandler.process`의 부분 실패
  롤백** — 이름 순회 도중 소유권 충돌 error가 나면 그 전에 등록된 이름들이
  이 사이클엔 회수되지 않음(클로저가 안 만들어짐). 피해는 그 인스턴스
  수명으로 한정되고 재현도 시끄럽게 반복돼서 **지금은 별도 장치 없이
  문서화만** 했는데(`base/attribute-plan.md` "메커니즘" 절), 원자적
  롤백(그룹 `process`에만 국소적인 unwind)을 넣을지는 열어둠. 지금 결정
  불필요 — M10 구현 시점에 판단.
- **`quad-debug` 세부 API 이름** — `research/debug-tooling-plan.md` 참고.
  채널 실현 가능성(BindableEvent/Function이 플러그인↔Play 중 게임 경계를
  넘는지)까지 사용자가 Studio에서 직접 실측 검증 완료 — 기술적 불확실성은
  다 해소됨, 남은 건 세부 API 이름뿐("이벤트 함수가 self로 instance를
  읽는 게 quad 관습"이라는 언급은 2026-08-06 후속 세션에서 해소 —
  채택 안 함으로 확정, `base/event-plan.md` "이벤트 핸들러는
  self(Instance)를 받지 않는다" 절 참고). 사용자가 "quad 개발 완료 전엔
  착수 못 함"으로 직접 후순위 지정한 건 여전함 — base 설계(M2 Dispatch/
  M3 Source/M5 `D` 생성자) 시점에 훅 확장 지점만 고려해두면 됨.
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
전체 순서/우선순위는 `.claude/todos.md`가 최종 소스. 확정된 것들의 문서
색인은 `.claude/README.md`의 `base/` 표(예전에 이 문서 맨 아래에 있던
요약표는 그것과 중복이라 archive로 옮김).
