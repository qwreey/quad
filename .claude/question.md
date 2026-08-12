# 확인/결정 필요 목록

**2026-08-04 세션 말미에 전체 재정리함.** 예전엔 라운드(1차~6차)별로 문서가
계속 쌓이면서 순서가 시간순도 우선순위순도 아니게 됐고, 이미 해소된 라운드
기록이 새로 열린 질문보다 위에 있는 등 혼동을 유발했음(문서 감사에서 발견).
그 상세 히스토리는 지우지 않았음 — git log로 이 파일의 이전 버전을 보거나,
각 `base/`/`research/` 문서 안의 라운드 표시("2026-08-04 3차 라운드" 등)를
따라가면 그대로 남아있음. 이 문서는 이제 **"지금 열려있는 것" 우선으로만**
구성.

## 지금 열려있는 것 (우선순위순)

### 0. 추가 프리미티브 필요성 — 사용자 요청, 대부분 수렴(2026-08-06~07)

사용자 질문: "다른 독립 프리미티브나 종속 파생 데이터는 뭐가 더 필요할 것
같나요. 이것만으로 이 프로젝트는 충분하다 생각해요?" — 여러 서브에이전트
조사 + 사용자와 라이브 논의로 계속 수렴 중. **2026-08-07 문서 정리에서
확정/기각된 항목은 `research/additional-primitives-plan.md`에서
분리됨**: Blocker → `base/blocker-plan.md`, Effect → `base/effect-plan.md`, Batch →
`archive/batch-rejected.md`, Context(+레이어드 Store) → `archive/
context-rejected.md`. 아래는 그중 **아직 실제로 열려있는 것만** 남김.

- **[해소됨, 2026-08-09 세 번째 세션]** 키 기반 동적 컬렉션 재조정 —
  `Slot:List(data, updateFn, keyFn?) -> Slot` 콜론 메소드로 완전히 확정
  (자유 함수/새 타입 둘 다 기각, "Slot이 이미 가진 것 위에 새 공개
  메소드를 안 얹으니 별도 타입일 이유가 없다"는 게 근거). Slot의
  `Extract`/`Add(index)` CRUD와 같이 확정됨, 상세는 `base/slot-plan.md`
  "`Slot:List(...)`" 절.
- **[해소됨, 2026-08-07 여섯 번째 세션]** Effect/Observer 관계 — Effect는
  자유 함수로 확정(`state` 인자를 받으면 내부적으로 `state:Observer(...)`를
  조합해 재실행+자동 cleanup 배선, React `useEffect`와 동형). `state:Observer(fn)`도
  등록 즉시 1회 실행되는 것으로 확정. 상세는 `base/effect-plan.md`의
  "해결됨" 절과 `base/bind-system-plan.md`의 Observer 절.
- Untrack/Suspense/Error Boundary/Readonly는 조사 결과 새 프리미티브 없이
  기존 설계·Lua 자체 기능으로 이미 충분한 것으로 판단(`research/
  additional-primitives-plan.md` "빈 자리 아닌 것" 절).
- **[해소됨, 2026-08-11 세션]** `Slot:Single(state, updateFn)` — `:List`를
  0/1개짜리 배열로 감싸는 순수 sugar로 확정(`index` 없이 `offset`/
  `prev`/`userdata`만 전달, 고정 key로 `prev` 재사용 보장). `base/
  slot-plan.md`의 "`Slot:Single(...)`" 절. 같은 세션에 **Slot-in-Slot
  중첩도 확정**(요소 타입 제약에서 `Slot` 배제 해제, `Dispatch.setLength`/
  `setOffsetSource`를 Slot 자신을 owner 키로 재사용하는 재귀 `attachSlot`) —
  `base/slot-plan.md`의 "Slot-in-Slot 중첩" 절. **[해소됨, 2026-08-11
  일곱 번째 세션]** `Slot:Add`가 `State<T>`/`Source<T>`도 요소로 받음 —
  새 메커니즘 아니라 내부적으로 `Slot():Single(element)`(updateFn 생략
  시 identity)를 대신 삽입하는 순수 sugar로 확정(`updateFn`도 이때
  `Slot:Single(state, updateFn?)`로 선택 인자화). `base/slot-plan.md`의
  "반응형 raw 요소" 절.

### 1. 용어 정리 (사용자 요청, 진행 중)

사용자 원 메모: "quad는 register라던가 좀 부정확하거나 느낌이 바로 와닿지
않던 용어들이 많음 — 전체적 용어를 보고 생각해볼래? 제안을 줘, 나도 같이
볼게." 1차 제안 완료, 아래는 우선순위순 요약 — 최종 판단은 사용자와 계속
논의 필요:

- **`State`(1순위, 위험도 높음)**: 지금 정의는 "읽기 전용, 파생/캐시 뷰"인데
  React/Vue 등 업계 전반에서 "state"는 거의 항상 "쓸 수 있는 로컬 슬롯"을
  뜻함 — 처음 보는 사람이 정반대로 오해할 위험이 큼. `Computed`/`Derived`
  (Vue `computed()`, Svelte 5 `$derived`가 정확히 같은 의미로 씀)가 실제
  의미에 더 맞아 보임. 단, v1의 "register"를 이미 한 번 "State"로 리네임한
  지 얼마 안 됐다는 점 고려 필요.
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
- **[해소됨, 2026-08-08 세션]** `PerInstanceState` — 이름 문제 자체가 없어짐.
  `State`와 이름이 겹쳐 혼동 유발하던 그 유틸은 `Relate`로 대체·정식
  승격됨(`base/relate-plan.md`) — 이름도 이미 사용자 확정("Relate 괜찮아요"),
  `State`와 안 겹침.
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
- **[해소됨, 2026-08-09 세 번째 세션]** 키 기반 동적 컬렉션 재조정 이름 —
  `List`로 확정(`Slot:List(...)` 메소드, `Render`/`Draw`는 기각). 상세는
  `base/slot-plan.md` "`Slot:List(...)`" 절.
- **[해소됨, 2026-08-09 세션]** `Bound` — **`canBound(handle): boolean`
  탑레벨 함수로 확정**, `canExecute`와 같은 결(raw 필드를 직접 노출하는
  대신 predicate 함수로 감쌈). `base/bind-system-plan.md` "이중 바인딩
  금지" 절 참고.
- **`Brand`(3순위, 사소함, 2026-08-07 여덟 번째 세션 추가)**: 런타임
  nominal 타입 판별 통합 메커니즘(`Brand.set`/`Brand.get`, `isState`를
  10종 branded 타입 전부로 일반화) — `bind-system-plan.md`의 `Brand`
  절에서 동작/구현 방식은 확정, "OOP 인스턴스의 클래스명을 얻는 느낌"을
  전달할 더 나은 이름이 있는지가 열린 질문(사용자가 직접 제기) — `Tag`는
  이미 quad-roblox의 `CollectionService` 래퍼로 쓰여서 이름 충돌, 후보로
  "type namespace"류를 사용자가 검토했으나 미확정. **(2026-08-08 재확인)**
  사용자가 다시 짚었지만 여전히 미정.
- **[해소됨, 2026-08-08 세션]** `Ref`/`PreRef`/`Peek`/`isState`(구
  `Override`는 이미 `Overridden`으로 별도 확정) — 전부 현재 이름 그대로
  유지로 확정. `Ref`는 "지연 없는 확정된 값 박스"라는 정의를 재확인(leaf
  노드를 담는 용도로도, leaf 노드에 바인딩하는 용도로도 쓰임 — 넓어진
  정의에도 여전히 맞음), `PreRef`는 더 나은 대안이 안 보여 그대로,
  `Peek`/`isState`는 이미 잘 맞는다고 재확인.
- **[해소됨, 2026-08-08 세션]** `None`/`NoneHandler` — `Undefined`/`Null`/
  `Nothing`도 검토했으나 기각(`Null`은 보통 "포인터가 비어있음"을 뜻해
  "값이 없음"이라는 의도와 안 맞는다는 게 이유), `None`/`NoneHandler`
  그대로 확정.
- **[해소됨, 2026-08-08 세션]** "프로바이더" → **`Handler`로 확정** —
  `base/module-lifecycle-plan.md`가 이미 [해소됨]으로 표시해뒀던 걸
  이 목록에 반영 안 하고 있던 stale 항목. `Processor`는 계약 메소드 이름
  자체가 `process`라 "그 안에 또 process가 있어" 눈에 걸리고, `Provider`는
  `canProvide`처럼 "뭔가를 공급한다"는 늬앙스라 실제로는 값을 처리/반응하는
  Handler의 동작과 안 맞으며 React `Context.Provider`류 맥락 패턴과도 헷갈릴
  수 있고, `Plug`는 "꽂힌다"는 늬앙스는 맞지만 "값을 처리한다"는 의미가
  없어 기각 — `Handler`가 계약(`isHandlable`/`process`/`retract`) 전체를
  가장 정확히 담는다는 사용자 재확인. 근거를 `base/module-lifecycle-plan.md`
  "프로바이더" 절에 보강 완료.
- **이미 지나간 사례로 참고**: `register`(v1) → `State`(v2) 리네임은
  "모호함"은 풀었지만 "다른 뜻으로 이미 쓰이는 단어"라는 새 문제를 만든
  셈 — 이번 정리에서 같은 패턴을 조심할 것.
- `Store`/`Source`/`Modifier`/`Ref`/`PreRef`/`Peek`/`isState`/`Handler`/
  `None`/`NoneHandler`/`process`/`retract`/`isHandlable`은 업계 선례와
  잘 맞거나 이미 신중하게 결정된 이름들이라 특별한 문제 없음.
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

### 2. 구현 착수 직전 감사 결과 (2026-08-06 신설, M0 착수 전 확인 권장)

`research/pre-implementation-audit.md` — `base/` 전체를 M0 착수 직전
시점에서 모호성/지연결정리스크/단순화후보 세 렌즈로 재감사한 결과. 총
11개 우선순위1(구현 중 바로 부딪힐 가능성 높음) + 11개 우선순위2(지금
정해두면 싼 지연리스크) + 2개 단순화후보. 전체는 그 문서 참고, 특히
사용자 판단이 필요한 것 위주로 요약:

- **[해소됨, 2026-08-10 세션]** Tween.luau가 "범용 store-bind 캐치올
  핸들러"의 유일한 예시로 서술됨 — Tween을 독립 Dispatch 핸들러에서
  값-레벨 래퍼(`Tween<T>`, PropertyHandler가 소비)로 재설계해 해소.
  범용 State/Source 언랩은 `Dispatch/StoreBind.luau` 하나뿐, Tween 여부
  판단은 완전히 별개(`research/tween-plan.md` 전면 재작성, 우선순위1-1
  해소).
- **[해소됨, 2026-08-09 세션]** `State<Modifier>`와 Ref/Slot이 Modifier
  필드에 들어가는 것 — 이제 둘 다 `isX` predicate 기반 명시적 `error`로
  통일(`base/modifier-plan.md` 4번/7번 절, `base/store-semantics.md`
  "따름정리" 절). Luau 타입 차단은 "되면 좋은 보너스"로 격하되어 더
  이상 필수 검증 항목 아님 — 문서모순 절 + 우선순위2-2도 갱신 완료.
- ~~`props.Modifier`/`props.Ref` forwarding 관례가 Lua 배열 리터럴
  nil-hole 함정에 그대로 노출됨~~ — **반영 완료(2026-08-07 열 번째
  세션)**. `props.Modifier or None`/`props.Ref or None` 관용구를 필수로
  확정(`base/component-composition-plan.md` "필수 관용구" 절) — M0에선
  이 관용구 자체가 타입/런타임 양쪽에서 문제없이 동작하는지만 검증.
- **~~`canExecute`/`Connected`의 실제 구현 방식이 미확정~~ — 반영 완료
  (2026-08-08 세션)** — 우선순위1-6 해소. `bindLifetime(inst,value)`/
  `canExecute(inst,value)` 탑레벨 함수로 확정(네임스페이스 안 씀,
  `LifetimeHandle.luau`는 이 둘의 인터페이스만 갖고 quad-roblox가 구현
  주입), 시그니처는 `(handle)`이 아니라 `(inst, value)` 2-인자로 재정정
  (Observer 자신의 `Subscribed` 상태를 먼저 보고, 그 다음 `inst`의 공유
  gcconn을 봄 — 두 조건이 독립적이라 하나로 못 뭉침). gchold 저장소는
  새 프리미티브 `Relate`(`base/relate-plan.md`) 위에 구현 — `base/
  lifecycle-pattern.md`의 "`bindLifetime`/`canExecute` — 확정" 절 참고.
- **~~`LifetimeHandle` 인터페이스가 M8에 배치돼 있지만 M4/M6이 이미 그걸
  필요로 함(로드맵 순서 역전)~~ — 반영 완료(2026-08-07 세 번째 세션)**:
  `LifetimeHandle`/`Relate` 인터페이스(타입만)를 `ROADMAP.md`
  M2로 옮기고, quad-roblox 실 구현만 M8에 남김 — 우선순위1-9 해소.
- **[해소됨]** retract 시 "이전 핸들러" 추적 책임 소재 — Dispatch 체인
  (`chains`)+`Dispatch.retractUnder`로 2026-08-08 세 번째 세션에 이미
  해소(`pre-implementation-audit.md` 1-2, `bind-system-plan.md` "Dispatch
  체인" 절). **[해소됨, 2026-08-09 세션]** `:Compute`의 `previous` 인자
  오버엔지니어링 의심도 기각(`bind-system-plan.md` "previous" 절,
  `pre-implementation-audit.md` 3-1). **[해소됨]** UI shorthand의 기존
  UICorner 매칭 기준도 `base/ui-shorthand-plan.md`에 이미 확정 반영돼
  있던 것을 이번에 `pre-implementation-audit.md` 2-11에도 해소 표시로
  동기화. **[해소됨, 2026-08-09 세 번째 세션]** Slot CRUD 의미론
  (`add`/`remove`/`clear`) 미정의(1-7)/`isMounted` 이중 추적 혼용(1-8) —
  `base/slot-plan.md` 참고. **아직 실제로 열려있는 건 하나** — 우선순위
  스캔 동률/매치실패 처리(1-3) — `pre-implementation-audit.md` 본문 참고.
- **[해소됨, 2026-08-08 두 번째 세션]** `Frame { ref }`/`Frame { observer }`처럼
  children 배열 숫자 슬롯에 직접 놓는 leaf 값을 매칭·바인드하는 Handler
  (`(i:number, v=Ref/Observer/PreRef)`)의 패키지 배치 — 원래 제안대로
  `quad-base`, `Dispatch/Leaf.luau`(이미 있던 `Dispatch/StoreBind.luau`와
  같은 층위)로 확정. Dispatch 자체가 프리미티브가 아니라 탑레벨 싱글톤이고
  base 기본 핸들러와 quad-roblox 백엔드 핸들러가 같은 `Dispatch.addHandler`
  레지스트리를 공유한다는 결론과 함께 나온 것 — `base/bind-system-plan.md`
  "Dispatch는 프리미티브가 아니다" 절, `base/architecture.md` 소스트리 참고.

### 3. 낮은 우선순위

- **`Operator` 콤비네이터 슈가 네임스페이스 이름(2026-08-12 신설)** —
  `Sum`/`Product`/`Not`/비트연산 등 `:Compute`/`:Apply`용 슈가 함수 모음의
  이름. 흔한 단어라 top-level 노출은 위험, 후보는 `Operator`/`Op`/`Ops`
  (`Combinator`는 코퍼스 전반에서 이미 일반명사로 쓰여서 제외) — 아직
  미정. `research/operator-sugar-plan.md` 참고. 구현 자체는 맨 마지막
  우선순위(순수 슈가, 없어도 무방).
- `research/existing-instance-bind-plan.md` — 스코프 논의만 필요, 구현
  착수를 막지 않음.
- **v1 `objectListClass.__newIndex` 오타 기능의 재현 테스트 필요** —
  `reference/quad-v1-architecture.md`에 남겨진 v1 내부 동작 확인 사항, 마이그레이션
  가이드 작성 시점에 필요. 지금은 그냥 백로그로만 기록.
- **[해소됨, 2026-08-09 여섯 번째 세션]** 여러 Slot이 형제로 섞일 때
  순서 보장 — `Dispatch.setLength`/`Dispatch.setOffsetSource` + 형제별
  개수 누적합을 `LayoutOrder`에 리액티브 바인딩하는 메커니즘으로 확정,
  DOM류 물리 순서 백엔드에도 같은 base 로직이 재사용됨(backend Handler의
  "offset 변경 시 할 일"만 no-op으로 갈림). 상세는 `base/
  bind-system-plan.md` "Length/Offset" 절, `base/slot-plan.md` "여러
  Slot이 섞일 때 순서 보장" 절. **같은 구현 시점에 같이 확인할 것
  (2026-08-06 추가, 아직 안 풀림)**: Slot이 quad 밖(v1 compat 등)에서
  만들어진 임의 Instance를 동적 배열 원소로 받을 수 있는지, retract 시
  foreign Instance를 어떻게 다루는지 — `research/v1-compat-plan.md` 7-3
  참고.
- **`quad-debug` 세부 API 이름** — `research/debug-tooling-plan.md` 참고.
  채널 실현 가능성(BindableEvent/Function이 플러그인↔Play 중 게임 경계를
  넘는지)까지 사용자가 Studio에서 직접 실측 검증 완료 — 기술적 불확실성은
  다 해소됨, 남은 건 세부 API 이름뿐("이벤트 함수가 self로 instance를
  읽는 게 quad 관습"이라는 언급은 2026-08-06 후속 세션에서 해소 —
  채택 안 함으로 확정, `base/bind-system-plan.md` "이벤트 핸들러는
  self(Instance)를 받지 않는다" 절 참고). 사용자가 "quad 개발 완료 전엔
  착수 못 함"으로 직접 후순위 지정한 건 여전함 — base 설계(M2 Dispatch/
  M3 Source/M5 DI 생성자) 시점에 훅 확장 지점만 고려해두면 됨.
- **문서화 전략(UI 네이밍 컨벤션, Store 부작용을 게임 시스템에서 쓰는
  패턴)** — `research/documentation-plan.md`(뼈대만). 정식 백로그 항목으로
  올릴지, 착수 시점을 언제로 볼지 사용자 판단 필요.
- **[해소됨, 2026-08-09 열한 번째 세션]** Attribute 특수 키 타입
  파라미터화 — `[AttributeKey<<boolean>> "name"]`(구 `Attribute<<boolean>>`,
  2026-08-11 아홉 번째 세션에 그룹 `Attribute(...)`와의 이름 충돌 방지로
  리네임) 제네릭 스타일과 `[BooleanAttribute "name"]` 타입별 정적 생성자
  패밀리 **둘 다 채택으로 확정**(내부 구현 동일, 호출부 표기만 다름).
  `base/attribute-plan.md` 참고 — 제네릭 파라미터가 `=` 뒤 값 타입까지
  좁혀주는지는 M0/M10에서 실측 필요(안 돼도 런타임엔 영향 없음).
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
- **`framework-comparison-findings.md`의 두 남은 개선 후보 반영 여부** —
  `research/framework-comparison-findings.md` "다음 단계" 절. use-after-destroy
  검증 안전망 부재, `:With`의 정적 의존성(동적 With 미지원) 두 가지를 실제
  설계에 반영할지, 반영한다면 M0 스파이크 때 같이 검증할지 나중 최적화
  패스로 미룰지 — 아직 사용자 판단 전.

## 참고: 지금까지 확정된 것 (요약)

전부 `base/`에 문서화되어 더 이상 열려있지 않음 — 상세 근거/논의 과정이
필요하면 아래 문서를 열어볼 것(라운드별 세부 히스토리는 각 문서 안에
"2026-08-04 O차 라운드" 식으로 표시돼 있음):

| 주제 | 문서 |
|---|---|
| 전체 아키텍처 결정(디스패치 모델, DOMless, 태그/Ref, Signal 미채택 등) | `base/architecture.md` |
| Store/State/Source 온톨로지, 인스턴스 생성/이벤트 인체공학, Ref, 남은 API 이름 | `base/bind-system-plan.md` |
| Store 부작용 허용, `:With`+`:Compute`, dot-access 문법 | `base/store-semantics.md` |
| 프로바이더 패턴, bind/store 구현 책임 분리 | `base/module-lifecycle-plan.md` |
| Slot 재조정, 재마운트 시 throw, retract=폐기 | `base/slot-plan.md` |
| `Connected`+GC 라이프사이클 패턴 | `base/lifecycle-pattern.md` |
| Modifier(정적 merge, immutable 체이닝, State 필드 지원, `Apply`/`Overridden`/`Peek`/`isState`) | `base/modifier-plan.md` |
| 컴포넌트화(플레인 함수, State/Source 경계, 컴포넌트 경계 modifier/Ref는 named parameter로 전달, multi-root 개념 폐기, `Modifier.Overridden`) | `base/component-composition-plan.md` |
| 컴포넌트 이식성(전역 store 참조 시 재사용성 문제) | `base/purity-and-effects-plan.md` |
| Blocker(값 기반 emit 지연/합치기) | `base/blocker-plan.md` |
| Effect(설치+확정 정리, `state` 있으면 Observer 조합해 재실행도 지원 — 확정) | `base/effect-plan.md` |
| `Relate`(inst-weak 릴레이션 프리미티브, `SetWeak`/`GetWeak`/`SetStrong`/`GetStrong`), `bindLifetime`/`canExecute`(inst,value) 탑레벨 함수 | `base/relate-plan.md`, `base/lifecycle-pattern.md` |
| `retract` 필드 생략 불가(no-op 허용, 누락 시 핸들러 교체 순간 크래시), store-bind 재실행은 `state:Observer(fn):Subscribe()` 재사용 | `base/bind-system-plan.md` |
| UICorner/UIPadding/UIScale 인라인 편의 키 — 이름·메커니즘·store-bind 가능성까지 확정 | `base/ui-shorthand-plan.md` |
| Batch(lexical) 기각, Context(+레이어드 Store) 기각 | `archive/batch-rejected.md`, `archive/context-rejected.md` |
| Fusion/Vide 비교 리서치(주의: 일부 서술은 이후 라운드에서 뒤집힘, 문서 내 정정 표시 참고) | `reference/comparison-fusion-vide.md` |
| v1 내부 동작 스냅샷 | `reference/quad-v1-architecture.md` |
| 트윈 — 값-레벨 `Tween<T>` 래퍼(2026-08-10)+옵션 값 모양·override 정책·`Animate` 콤비네이터(2026-08-12) 전부 확정, 자연완료 북키핑 하나만 남음 | `research/tween-plan.md` |
| quad2-try(폐기된 이전 시도) 리서치 — OOP 상속/커스텀 파서/Slot 스텁/`Pipe` COW 전부 죽은 접근으로 확인, 반복 조사 금지 | `base/bind-system-plan.md` |

---
전체 순서/우선순위는 루트 `CLAUDE.md`가 최종 소스 — 위 표는 힌트일 뿐 그쪽이
바뀌면 이 문서도 갱신할 것.
