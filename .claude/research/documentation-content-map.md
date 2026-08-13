# 문서 콘텐츠 분류 맵 (초심자/api/심화/skip)

**상태**: research — `documentation-plan.md` 0번 항목(3축 구조: 초심자/api/심화
+ 백엔드별 트랙 분리)이 확정된 뒤, 실제로 각 축에 뭘 채울지 `.claude/base/*.md`
전체 + 관련 `research/*.md`(tween-plan, ui-shorthand-plan)를 2026-08-06 세션에
6개 에이전트로 병렬 서베이해 분류함. **아직 문서를 쓰라는 뜻 아님** — 착수
시점은 여전히 구현 우선(`CLAUDE.md` "지금 할 일" 1번). 나중에 실제 문서화를
시작할 때 이 맵을 목차/우선순위표로 쓰면 됨.

**api↔심화 연결 원칙(사용자 확정)**: api 문서는 항목마다 설명을 간략하게
유지하고, 근거·내부 동작까지 파고드는 내용은 심화 섹션으로 링크("더 알아보기
→ 심화")하는 방식으로 연결. 아래 [api] 항목 중 "→심화"가 붙은 것들이 이
패턴 대상.

**분류 기준**: [초심자] core loop에 필수(백엔드 구체적, quad-roblox 기준) /
[api] 레퍼런스, 빠른 룩업용 짧은 설명 / [심화] 왜 이렇게 설계했는지, 최적화·
대규모 코드베이스 관리 관심자용 / [skip] 내부 설계 과정 기록, 최종 사용자
문서엔 안 들어감(세션 날짜, 정정 이력, 조사 원자료 등).

---

## 1. 초심자(getting-started) core loop — 취합된 목차 초안

전체 서베이에서 나온 [초심자] 항목을 실제 학습 순서로 재배열한 것. 이대로
목차를 잡으면 좋아 보임(그대로 확정은 아니고 초안):

1. **초기화** — `RobloxFactory(QuadBase)`로 base+backend 조립 (`module-lifecycle-plan.md`, `bind-system-plan.md`)
2. **Instance 만들기** — DOMless 즉시 생성 모델, 제네릭 `new<Class>` + 자주 쓰는 ~25개 클래스 정적 필드(`Frame`, `TextButton` 등) (`architecture.md`, `bind-system-plan.md`)
3. **속성 채우기** — `[Attribute "Name"]`, ~~`[Tag ""] = true`~~ **[2026-08-13 정정] 구모델(폐기, `archive/tag-hash-key-model-reversed.md`) — 실제로는 `Tag(...)` array-part 값 객체** 특수 바인드 키 (`architecture.md`)
4. **반응형 기초** — `Source`/`Store` 생성, `store.key`(dot-access)로 Source 읽기(Source는 State를 만족), `store.key:Set(value)`로 쓰기, State는 항상 읽기 전용 (`bind-system-plan.md`, `store-semantics.md`; 2026-08-06 후속 세션에서 dot-access가 Source를 직접 반환하고 쓰기가 `:Set()`으로 바뀜)
5. **스타일링** — Modifier 기본 체이닝(`:FontSize(14)`), 배열/인라인 merge 우선순위 규칙 (`modifier-plan.md`)
6. **자식 전달** — Slot 기본 개념(children 배열, add/remove/clear), 마운트된 slot 재마운트 시 throw (`slot-plan.md`)
7. **컴포넌트 작성** — 컴포넌트 = 순수 함수, 리프 프로퍼티엔 State만 바인딩, 전역 store 직접 참조 금지(이식성) (`component-composition-plan.md`, `purity-and-effects-plan.md`)
8. **컴포넌트 경계 넘기기** — `props.Modifier`/`props.Ref` named parameter 패턴 (`component-composition-plan.md`)
9. **이벤트** — self(Instance) 안 받음, 문자열 키(`Frame { MouseButton1Click = fn }`) (`bind-system-plan.md`)
10. **생명주기** — GC 위임(수동 정리 불필요), Destroy 이후 대상 재사용 금지 (`lifecycle-pattern.md`)
11. **Ref 기초** — 외부 관리 Instance 참조/마이그레이션용, `Ref(default):Callback(fn)`을 children 배열 숫자 슬롯에 직접 놓기 + 배열 위치로 자식 전/후 표현, "프로퍼티보다도 먼저" 필요할 때만 `PreRef`(2026-08-07 세 번째 세션, `phase` 옵션 폐기) (`architecture.md`, `bind-system-plan.md`)
12. **파생값 최소 예시** — `:With(...)` + `:Compute(fn)` 기본형 (`bind-system-plan.md`, `store-semantics.md`)
13. **Tween 기초** — ~~`[Tween(key, ...)] = storeValue`~~ **[2026-08-13 정정] 구모델(폐기, `archive/tween-special-bind-key-reversed.md`) — 실제로는 `Tween(opts) -> Tween<T>` 값-레벨 래퍼**, 취소 시 현재 보간값에서 자연스럽게 이어짐 (`base/tween-plan.md`)
14. **UI 숏핸드(quad-roblox 한정)** — `UICorner`/`UIPadding`/`UIPaddingOffset`/`UIScale` 인라인 키 (`base/ui-shorthand-plan.md`)

---

## 2. 파일별 상세 분류

### architecture.md
- 초심자: DOMless 즉시 Instance 생성 모델 / 특수 바인드 키 / Ref 기본 개념 / modifier 기본 사용법(스타일링) / Store·State·Source 온톨로지 핵심 동작 / quad-base·quad-roblox 패키지 구조 존재 사실
- api: Class 함수형+`:` 체이닝 예외 규칙 / store 바인드=전체 교체 의미론 / Tag/retract(CollectionService 기반) / modifier 병합 우선순위 규칙(→심화: CSS cascade 회피 근거) / PropertyChangedSignal이 pluggable 핸들러로 구현 / Source·State·Store 타입 정의
- 심화: Class가 OOP 아닌 함수형인 이유 / metatable 체이닝 폐기 이유(v1 clone 문제) / id 기반 전역 조회 폐지 이유 / Style(Default) 시스템 폐기→modifier 대체 근거 / 멀티 백엔드(GTK 등) 지향 이유 / push-invalidate·pull-recompute 전파 모델 상세, 다이아몬드 의존성 해결 근거
- skip: Tracker 미구현, lang 모듈 분리, Signal 클래스 미구현 판단 과정, 소스 트리·모노레포 구조, 테스트 전략(mock 설계)

### comparison-fusion-vide.md — 대부분 skip(내부 리서치 스냅샷)
- **quadnomicon**으로 재작성 가치 있는 것 두 개(2026-08-06 재분류 — 원래
  심화 후보였다가, 독자층이 "quad 사용자"가 아니라 "프레임워크 설계 자체에
  관심 있는 엔지니어"라 quadnomicon으로 이동): **Slot 단일 마운트 소유권**이
  Fusion/Vide 둘 다에 없는 quad만의 차별점(Fusion/Vide 경험자 대상 "왜 이중
  mount를 막는가" 비교 소재) / **`:With`+`:Compute` 명시적 파생값**이 Vide의
  암묵적 ambient stack 대신 채택된 이유(Vide 경험자 대상 비교 설명, 원문
  재작성 필요) — 단, "왜 Slot은 단일 마운트를 강제하는가" 자체(다른 프레임워크
  비교 없이 quad 논리만으로 설명 가능한 부분)는 여전히 심화에 남음(아래 4번
  9번 항목).
- 나머지(Fusion 반응 그래프 BFS 분석, Scope 정리 모델, Vide 디스패치 분석, 비교표 전체)는 전부 내부 설계 근거 수집용, skip — `.claude/` 내부 설계사로만 남고 publish 대상 아님

### quad-v1-architecture.md — 전체 skip
v1 폐기 API/버그/구조 결함 전부 v2 설계를 정당화하는 내부 회고. 단, **v1에서
넘어오는 기존 사용자용 마이그레이션 가이드**가 나중에 별도 문서로 계획된다면
그때만 재사용 가치 있음 — 지금 3축 어디에도 해당 없음.

### bind-system-plan.md (943줄, 최대 문서)
- 초심자: Source/Store/State 기본 정의+생성자, State 읽기 전용 규칙 / dot-access가 값 읽기 1급 경로 / `:With`+`:Compute` 최소 사용법 / Ref 기본 개념(children 배열에 직접 놓기, 별도 `CreatedRef` 없음) / 이벤트 self 미채택 기본 규칙+문자열 키 / 인스턴스 생성(제네릭+정적 필드) / 라이브러리 초기화 3줄(`RobloxFactory(QuadBase)`)
- api: `state:Observer(fn)` 사용법(→심화: weak-table 내부 인덱싱) / `:Subscribe()`/`:Unsubscribe()` 시그니처(→심화: 강참조 레지스트리 구조) / Ref 일반화 표면 API(→심화: "왜 값이 아니라 콜백인가") / 이벤트 store-bind 존재+권장 안 함 가이드(→심화: 엔지니어링 비용 근거) / 핸들러 3종 계약(`isHandlable`/`priority`/`process` — `process`가 자기 retract 클로저를 반환, 2026-08-13 다섯 번째 세션에 4종에서 축소) / `AttributeKey<T>` 특수 키(2026-08-11 아홉 번째 세션에 `Attribute<T>`에서 개명, 그룹 값 `Attribute(...)`와 구분 — 확정됨)
- 심화: push-invalidate/pull-recompute 전파 모델+"관측해야 실체화된다" 원칙+`previous` 캐비엇 / **왜 State를 Modifier처럼 플래튼하지 않는가**(이미 문서화 완료, 아래 3번 참고) / Store가 Store를 못 담는 이유 / 이벤트 self 미채택 4가지 근거 / store-bind 재귀 래핑 내부 메커니즘, retract가 Destroy 시 호출 안 되는 이유 / 같은 팩토리 재호출 no-op·다른 팩토리 충돌 에러 내부 안전장치
- skip: quad2-try 리서치 결과 섹션 전체(OOP 상속/커스텀 파서/Slot 스텁/`Pipe` 폐기 이력) / PA님 코드 교차검증 절(역사적 검증 기록) / "남은 열린 질문"/"확정된 것" 메타 요약

### component-composition-plan.md / module-lifecycle-plan.md
- 초심자: 컴포넌트=순수 함수 / 리프 프로퍼티 바인딩(**[정정, 2026-08-09 열한 번째 세션] "State만"이 아님 — 단순 원본 토글(`Frame{Visible=source}`)은 Source 직접 바인딩이 정상 경로, 여러 값에서 파생된 계산 결과일 때만 자연히 State가 됨, `component-composition-plan.md` 5번 절 참고**) / `props.Modifier`/`props.Ref` named parameter 경계 전달(**`props.Modifier or None`/`props.Ref or None` 필수 관용구 — 안 쓰면 nil-hole 버그, 2026-08-07 열 번째 세션 확정**) / `InitRoblox(Module)` 팩토리 초기화
- api: State(파생, 읽기전용) vs Source(원본, 쓰기가능) 경계 요약(→심화) / Slot 반환 컴포넌트는 Modifier/Ref 파라미터 미선언 / `Modifier.Overridden(mod1, mod2, ...)` 유틸(구 `Merge`, `props.Modifier` 단일 슬롯용 특수 상황으로 한정 소개 — 아래 modifier-plan.md 절 참고) / Bind는 유일 슬롯(재호출 no-op, 충돌 에러, →심화) / `:With`/`:Compute`로 파생 State 생성 시그니처 / 모듈 싱글톤 스코프
- 심화: v1 `Extend` 자동 store 소유 폐지 이유(React 벤치마킹) / Source가 State를 구조적으로 만족하는 서브타입 설계(2026-08-06 후속 세션 — `StoreSource` 프록시 중간안은 폐기되고 이걸로 대체됨, `store-semantics.md` 참고) / named-parameter 경계 방식 채택 이유(Compose/Fusion/Vide/v1 선례 수렴) / 다중 루트 반환 개념 제거 근거 / 팩토리 초기화 패턴 채택 이유(RBVM `InitNamespace` 반례) / Store 책임 분리(base가 `LifetimeHandle` 소유) / v1 named 체이닝 연산 폐기
- skip: Compose/Fusion/Vide/v1 프레임워크 비교 원자료 / provider/processor 네이밍 미정 등 열린 질문 메모

### lifecycle-pattern.md / purity-and-effects-plan.md
- 초심자: 수동 정리 불필요(GC 위임) / Destroy 이후 재사용 금지 / 컴포넌트는 파라미터로 받은 store만 사용(전역 store 직접 참조 금지)
- api: `Connected`/canExecute 인터페이스(→심화) / 생명 바인드 유틸 시그니처(→심화) / 이식성 규칙이 린트 강제가 아니라 컨벤션이라는 사실
- 심화: `Connected`가 계산된 속성인 이유(rbvm 근거) / `Instance.Destroying` 훅 단일화 이유 / weak-table GC-native 원칙+eager 정리 예외 / Signal 클래스 미채택 이유 / "quad는 생명주기 중간 계층이 아니다" 소유권 모델 / `retract` 네이밍 배경 / "순수함수 아니라 이식성 문제"로 재정의된 배경(vdom 없음 전제)
- skip: rbvm 조사 세션 메타, EventDrivenProgramming 교차검증 일화(결론만 심화에 남음)

### modifier-plan.md / slot-plan.md
- **Slot 프레이밍 확정(2026-08-11)**: Slot을 "동적 렌더링을 가능하게 하는
  도구"로 소개 — Slot의 요지 자체가 "요소가 자유롭게 생기고 사라짐"이라
  이 프레이밍이 본질과 일치함(children 배열이라는 정적 구조 서술보다 이
  동적 능력을 앞세움). 아직 미착수인 `Slot():Single(...)`(890행 백로그)도
  같은 프레이밍의 특수 케이스로 소개 — "1개 아니면 0개"의 동적 렌더일 뿐,
  별도 개념 아님.
- 초심자: Modifier 기본 체이닝+merge 우선순위 규칙 실제 예시 / Slot 기본 개념(children 배열)+클래스가 슬롯 받는 방법(Named Slot 없음) / 마운트된 slot 재마운트 시 즉시 throw
- api: Setter가 리터럴/변환 함수 둘 다 받음(→심화: getter 없는 이유) / 필드가 State일 수 있는 4가지 조합 표(→심화: 반응성 유지/끊김 이유) / `mod:UICorner(8)` dot-access 생성자 관습 / Slot은 인스턴스당 여럿 가능 / 중첩 인스턴스 자식 처리 / ~~retract 시 slot 내용 폐기(→심화: portal 없는 이유)~~ **[2026-08-13 정정] 2026-08-13 여섯 번째 세션에 역전 — `State<Slot>` 교체는 이제 파괴가 아니라 언마운트, portal은 그 자연스러운 귀결(`base/slot-plan.md`)** / `:Apply(factory)` 기본 체이닝 관용구(→심화: 언제 `Apply` vs `Overridden`인지 성능 기준) / `:Peek<<T>>(key)` + `isState`(→심화: `Get`과 이름을 다르게 한 이유)
- 심화: 정적 merge vs 런타임 pluggable 기각 이유(CSS cascade) / immutable+clone 체이닝 이유(형제 오염 방지) / getter 미채택 이유 / `__index` 런타임 구현 통찰 / Modifier가 핸들러 계층을 모르는 이유 / base/roblox 패키지 경계(Dispatch/Slot vs Handlers/Slot) / Slot 단일 마운트 소유권이 v1/Fusion/Vide 대비 개선인 이유 / ~~retract=폐기 확정 히스토리(portal 검토 후 기각)~~ **[2026-08-13 정정] 위와 같은 이유로 역전 — 이 항목은 "왜 한때 destroy+no-portal로 결정했었는가"라는 히스토리 소재로만 유효, 현재 결론 아님** / **왜 `Apply`가 기본이고 `Overridden`는 최적화 특수 케이스인가**(계산 의존성 있는 조합 vs 독립적 재사용 가능 조각의 병합 — 2026-08-07 다섯 번째 세션, `modifier-plan.md` 9번) / 왜 `Apply`가 clone 대신 mutate하지 않는가(형제 오염 방지가 개별 clone 비용 절감보다 우선)
- 열린 질문(문서화 보류): ~~여러 Slot이 형제로 섞일 때 순서 보장~~ **[해소됨,
  2026-08-09 여섯 번째 세션]** Length/Offset 누적합으로 확정, 심화 목록에
  추가 필요(`base/dispatch-core-plan.md` "Length/Offset" 절).
  **[2026-08-09 추가]** `Slot:List`의 `prev`/`userdata` 재사용 최적화를
  getting-started에서 "항상 파괴 후 재생성" 단순 버전만 가르치고 나중에
  최적화 단계에서 별도로 알려줄지, 아니면 Slot이 학습 순서상 core loop
  후반부라 어차피 Source/State를 다 아는 시점이니 처음부터 완전한 형태로
  한 번에 가르칠지 — 사용자가 직접 제기, 미결. 제 의견은 후자(후반부
  배치라 단계적으로 나눌 이득이 적어 보임)로 기울지만 확정 아님, 실제
  콘텐츠 작성 시점에 결정.
- skip: 세션 날짜/확정 이력, 문서 승격/정정 안내

### store-semantics.md / tween-plan.md / ui-shorthand-plan.md
- 초심자: Store 생성+`myStore.key:Set(value)` 문법 / `store.key`로 State 얻기 개념 / Tween 기본 바인드 키+취소 기본 동작 / UI 숏핸드 인라인 키 기본 예시(`Frame { UIPaddingOffset = 50 }`)
- api: `:With`+`:Compute` 시그니처(→심화) / `source:Emit()` 존재+"Get() 결과 캐시 금지" 캐비엇(버그 유발 포인트라 api에도 명시 가치 있음, →심화; 2026-08-06 후속 세션에서 `Store:Emit(key)`→`source:Emit()`로 호출부 변경, `store-semantics.md` 참고) / ~~Tween 핸들러가 Instance 직접 받음(Ref 불필요)~~ **[2026-08-13 정정] 구모델(폐기) — 실제로는 `Tween(opts)` 값-레벨 래퍼가 Property 자리에 놓이고 `PropertyHandler`가 `isTween`으로 분기** / retract는 Destroy 시 호출 안 됨(→심화) / UI 숏핸드 키 목록 레퍼런스 표 / Modifier와 순수 인라인 키 동등성
- 심화: Source·Store·State·Observer 온톨로지(독립 프리미티브 vs 파생 데이터 원칙, 생성자 모양 근거) / `Emit`이 Source 전용인 이유(디버깅 그래프 무결성) / `Store<T>`의 T가 Modifier 불가인 이유 / ~~Tween을 반응 그래프 밖 특수 bind key로 둔 이유(Fusion 반면교사)~~ **[2026-08-13 정정] 이 근거 자체가 폐기된 구모델 서술 — 현재는 Tween이 반응 그래프 "밖"이 아니라 Property 값 타입 치환(`T|Tween<T>`)으로 자연스럽게 들어와 있음, `base/tween-plan.md` 참고** / RoundSize 포팅 불필요 vs UICorner/UIPadding/UIScale 필요 이유 / "작고 opt-in 아닌 편의 기능은 코어 포함" 원칙
- 열린 질문(문서화 보류): tween-plan.md의 오버라이드/삭제후재시작/끝점이동 옵션 키 이름 미정 / ui-shorthand의 RoundSize 완전 드롭 여부
- skip: 세션 정정 이력, v1 소스 조사 경위

---

## 3. 이미 작성 완료된 심화 콘텐츠

- **왜 State 체인을 Modifier처럼 플래튼하지 않는가** — `base/bind-system-plan.md` 해당 절에 결정문 있음(2026-08-06 세션에서 이 대화 중 확정).

## 4. 심화 전용 신설 콘텐츠 후보 (반복 테마 정리, 에세이 단위)

위 표에서 반복 등장하는 "왜" 주제들을 에세이 단위로 묶으면:

1. 왜 함수형 컴포넌트인가(OOP 상속 대신) — `architecture.md`, `component-composition-plan.md`
2. 왜 Modifier는 런타임 pluggable이 아니라 정적 flatten인가 — `modifier-plan.md`
3. 왜 push-invalidate/pull-recompute인가(Fusion eager 노드 미채택) — `bind-system-plan.md`
4. 왜 State는 플래튼하지 않는가 — 작성 완료(위 3번)
5. 왜 GC-native 생명주기인가(Signal 클래스 없음) — `lifecycle-pattern.md`
6. 왜 이벤트 핸들러는 self를 안 받는가 — `bind-system-plan.md`, `research/documentation-plan.md` 3번과 통합 가능
7. 왜 컴포넌트 경계는 named parameter인가(Compose/Fusion/Vide/v1 수렴) — `component-composition-plan.md`
8. 왜 "다중 루트 반환" 개념을 없앴는가 — `component-composition-plan.md`
9. 왜 Slot은 단일 마운트 소유권을 강제하는가(v1/Fusion/Vide 대비) — `slot-plan.md`, `comparison-fusion-vide.md`
10. ~~왜 Tween은 반응 그래프 밖에 있는가~~ **[2026-08-13 정정] 위 §2 심화 항목과 같은 stale 표현 — 실제로는 Property 값 타입 치환(`T|Tween<T>`)으로 그래프 안에 자연스럽게 있음** — `base/tween-plan.md`
11. 왜 `:Emit()`은 Source 전용이고 파생 State엔 없는가(호출부는 `source:Emit()`, 2026-08-06 후속 세션에서 `Store:Emit(key)`→이 형태로 정리) — `store-semantics.md`
12. 독립 프리미티브 vs 파생 데이터 — 생성자 모양을 결정하는 원칙 — `store-semantics.md`
14. 왜 컴포넌트는 전역 store를 직접 참조하면 안 되는가(이식성) — `purity-and-effects-plan.md`
15. 왜 Source가 State를 구조적으로 만족하는가(Svelte Writable/Readable과 같은 서브타입 모양, `RefSource`/`StoreSource` 중간안이 왜 기각됐는가) — `store-semantics.md`, `component-composition-plan.md`
16. **State 파생 체인 동작 원리** — emit이 아래로 전파되고, `Get()` 요청이
    위로 거슬러 올라가 재계산된 뒤 다시 아래로 내려오는 흐름을 명확히
    설명(Blocker/Effect 둘 다 이 흐름 위에서 동작하므로 선행 이해로 필요)
    — `research/additional-primitives-plan.md` "문서화 백로그" 절
    (2026-08-06~07 신설)
17. **`:Compute` 함수 안에서 `if` 등으로 일부 의존값만 조건부로 사용하는
    유연한 구조** — 명시적 의존성 선언(`:With`) 위에서도 실제 계산은
    조건부로 일부만 쓸 수 있다는 팁 — `research/additional-primitives-plan.md`
    "문서화 백로그" 절
18. **Blocker 사용 가이드** — 파이프라인 최종 연산 지점(무거운 계산이
    실제 일어나는 derived state)에 배치하는 게 원칙이라는 것, **네스팅
    금지를 최우선으로 강조**(겹치는 배치는 각자 새 `Blocker`를 만들 것 —
    안 지키면 조용히 잘못된 시점에 조기 해제되는 원인 추적 어려운 버그로
    이어짐) — `base/blocker-plan.md`
19. 여러 Source를 한꺼번에 바꿀 때 Blocker 없이도 중복 재계산/재대입을
    피하는 파이프라인/업데이트 순서 팁(Blocker를 안 쓰는 단순 케이스용
    보조 팁) — `research/additional-primitives-plan.md` "문서화 백로그" 절

(13번이었던 "Fusion/Vide 경험자용 비교 섹션"은 2026-08-06 재분류로 아래 6번
`quadnomicon`으로 이동)

## 6. `quadnomicon` — 4번째 축, 프레임워크 설계자용 (2026-08-06 신설)

**독자층이 다름**: 심화(1~5번)는 "quad를 깊게 이해해 최적화하거나 왜
이런지 이해하고 싶은 quad 사용자"용. `quadnomicon`은 "비슷한 반응형 UI
프레임워크를 직접 설계/포크하려는 엔지니어"용 — quad를 그냥 쓰기만
한다면 평생 안 읽어도 무방한 콘텐츠. Rustonomicon 패러디로 이름 확정
(사용자 선택).

**현재 후보(둘 다 `comparison-fusion-vide.md`에서 재작성 필요, 원문
그대로 쓰면 안 됨 — 지금은 우리 내부 리서치 원자료 톤)**:
1. Slot 단일 마운트 소유권이 Fusion/Vide 둘 다에 없는 quad만의 차별점 —
   "왜 이중 mount를 막는가"를 Fusion/Vide 내부 동작과 나란히 비교
2. `:With`+`:Compute` 명시적 파생값이 Vide의 암묵적 ambient stack 대신
   채택된 이유 — Vide 경험자 대상 비교

**2026-08-06~07 후속 세션에서 추가된 후보(전부 `research/
additional-primitives-plan.md`의 "문서화 백로그" 절이 원자료)**:
3. **왜 lexical Batch를 기각하고 대신 값 기반 Blocker를 택했는가** —
   Solid `batch()`/MobX `runInAction()`류 lexical transaction이 Roblox의
   협조적 스케줄링(코루틴 yield) 환경에서 왜 근본적으로 위험한지(전역/
   코루틴 스코프 플래그가 새 코루틴 스폰·영구 yield에 어떻게 깨지는지
   구체 시나리오) **+** 그 대안으로 `Blocker`(콜스택/코루틴이 아니라
   값으로 지연 구간을 표현, 네스팅 의도적 미지원)가 어떻게 같은 문제를
   구조적으로 우회하는지 나란히 비교 — Fusion/Vide 비교는 아니고 "설계
   원리"형 에세이라 Rustonomicon 패러디 취지(비슷한 프레임워크 설계자용)와
   잘 맞음. (2026-08-06 세션엔 "왜 Batch가 없는가"로만 다뤘다가, Blocker
   채택 후 2026-08-07 세션에서 비교 에세이로 재구성됨 — Batch(lexical)
   기각과 Blocker 채택은 별개 결정이니 혼동하지 말 것.)
4. 왜 Context가 없는가 — 얕은 버전(코루틴 키 weak table push-pop)조차
   quad가 정상 패턴으로 확정한 Slot 비동기 추가에서 조용히 깨지는 이유,
   완전 자동 버전이 Roblox Luau의 플랫폼 한계(thread-local 없음)로 불가한
   이유, 명시적 타입 강제 Store 전달이 Context보다 안전한 이유(레이어드
   Store 대안도 왜 함께 기각됐는지 포함)
5. 왜 push-invalidate/pull-recompute 설계가 laziness와 재계산 방지를
   최우선 목표로 뒀는가 — 위 `심화` 3번(`왜 push-invalidate/pull-recompute
   인가`)을 더 깊게 확장, `Blocker` 같은 파생 프리미티브가 이 목표 위에서
   왜 자연스럽게 나왔는지까지 포함하는 설계 철학 에세이
6. **왜 배열/해시 두 패스 순서를 안 뒤집는가, `PreRef`는 왜 그 예외로
   따로 필요한가** (2026-08-07 세 번째 세션 원자료, `bind-system-plan.md`
   "`phase` 옵션 폐기" 절 마지막 항목이 이 자리를 지목해뒀던 것 — 지금까지
   여기 안 옮겨져 있었음) — "프로퍼티/이벤트가 항상 children/Ref보다
   나중"이라는 순서를 고치는 대신 `PreRef`라는 별도 타입으로 예외를
   빼낸 선택 자체가 에세이 소재. **여기 곁들일 후보 프레이밍(사용자 제시,
   2026-08-07, 정확한 정의는 미확정 — 아래 5번 목록 참고)**: `Ref`는
   `(v=Ref)` 매치 핸들러로 처리돼 다른 핸들러들과
   같은 우선순위 스캔에 참여한다는 의미에서 "hook"(순서 등록 가능, 다른
   값으로 교체되면 `retract`로 취소됨)에 가깝고, `PreRef`는 그 스캔 밖의
   고정 pre-pass라는 의미에서 "pre-hook"(항상 최우선 고정, 순서/취소
   개념 자체가 다름)에 가깝다는 구분 — quadnomicon 에세이로 쓸 때 이
   "hook"/"pre-hook" 용어 자체를 채택할지만 아직 열려있음(복수 `PreRef`
   간 순서는 2026-08-07 아홉 번째 세션에서 해소됨 — 배열 index 순서
   그대로, 별도 규칙 없음, `ref-plan.md` "PreRef" 절 참고).
   **[해소됨, 2026-08-12 여섯 번째 세션]** 취소 가능 여부 — PreRef는
   구조적으로 `retract` 체인에 아예 안 올라가므로 취소 개념 자체가 없고,
   대신 이미 fire된 PreRef를 재사용하면(두 번째 construction에 다시
   놓으면) 즉시 `error` — "1회용, 재할당 불가"로 확정. `bind-system-plan.md`
   "동적 경로로 도착한 PreRef는 런타임에도 명시적으로 에러" 절 바로 아래
   "PreRef는 '취소'라는 개념이 없다" 항목 참고.

7. **왜 `Compute(fn, ...)`는 여러 의존성을 편하게 받고 `Effect`/`Observer`는
   안 받는가** (2026-08-11 세션 원자료, `bind-system-plan.md` "`:Compute(fn,
   ...)` — 추가 의존성을 trailing args로 직접 받는 sugar" 절) — 겉보기엔
   비일관적인 API 표면(하나는 React `useMemo`식 trailing deps sugar를 받고,
   다른 둘은 명시적 `:With` 호출을 강제)이 실은 "sugar가 새 노드 생성 비용을
   감추는가"라는 단일 원칙에서 갈라져 나온다는 게 소재 — `Compute`는 어차피
   자기 결과를 담을 노드를 만들어야 해서 추가 구독을 얹는 게 공짜지만,
   `Effect`/`Observer`는 자기 자신이 State 노드가 아니라 다중 의존성 병합에
   진짜 새 노드가 필요해서 그 비용을 코드에 그대로 드러내는 쪽(`:With`
   명시)을 택했다는 비교.

**publish 안 하는 것과의 경계**: 세션별 정정 이력, 조사 원자료(Fusion
반응 그래프 BFS 분석, quad2-try 죽은 코드 조사 등)는 quadnomicon에도
안 들어감 — 그건 새 티어가 필요한 게 아니라 애초에 `.claude/` 내부
설계사로만 남고 절대 publish 안 하는 것(RFC 논의 저장소 같은 성격,
위 각 파일 섹션의 skip 참고). quadnomicon은 잘 다듬은 소수의 큐레이션된
에세이 공간이지, 내부 연구 기록을 그대로 옮기는 곳이 아님.

**배경지식 자체가 깊은 주제(예: GC) 처리 방침**: 새 티어를 만들지 않음.
"quad가 GC를 어떻게 활용하는가"(quad 고유)는 심화에 그대로 두되, "GC란
무엇인가" 자체를 가르치는 자체 튜토리얼은 안 쓰고 외부 좋은 자료로
링크 처리 — 안 그러면 문서 프로젝트가 일반 프로그래밍 교육 쪽으로
스코프 크리프될 위험이 있음(사용자 판단).

## 5. 문서화 아직 보류(미확정 설계라 쓰면 안 됨)

**[정정, 2026-08-09 열한 번째 세션] 아래 목록 중 상당수가 이미 해소돼
있었음 — 이 절이 오래 안 갱신되며 stale해진 것, 실제 열린 것만 남기고
해소된 건 표시만 남김(중복 조사 방지 목적, 지웠다가 나중에 또 조사하게
되는 걸 막기 위해 흔적만 유지).**

- **[해소됨]** Slot 형제 순서 보장 — `Dispatch.setLength`/
  `setOffsetSource`(Length/Offset)로 2026-08-09 여섯 번째 세션에 확정,
  `dispatch-core-plan.md` "Length/Offset" 절 참고.
- **[해소됨, 2026-08-13 정정]** Tween 오버라이드/옵션 값 모양 —
  2026-08-12 첫 번째 세션에 `Info: TweenInfo?`+편의 필드 폴백,
  override 정책은 `Tween.Cancel`(기본)/`Tween.Finish` 2값으로 확정,
  `tween-plan.md` 자체가 `research/`에서 `base/`로 승격됨(이 줄이 그
  갱신을 놓치고 있었음). **다만 아래 §1/§2의 Tween 예시(`[Tween(key,
  ...)] = storeValue` 특수 바인드 키, "Tween 핸들러가 Instance
  직접 받음", "반응 그래프 밖 특수 bind key로 둔 이유")는 전부
  2026-08-10 두 번째 세션에 폐기된 구모델
  (`archive/tween-special-bind-key-reversed.md`) 서술 — 이 문서를
  실제로 쓸 때 `Tween(opts) -> Tween<T>` 값-레벨 래퍼 모델로 다시
  써야 함.**
- **[해소됨]** `Attribute<T>` 제네릭 vs 타입별 정적 생성자 — 2026-08-09
  열한 번째 세션에 "둘 다 채택"으로 확정, `base/attribute-plan.md` 참고.
- provider/processor 네이밍 — **[해소됨]** `Handler`로 이미 오래전 확정
  (`base/module-lifecycle-plan.md`), 이 줄이 그 갱신을 놓치고 있었음.
- **[해소됨]** 키 기반 동적 컬렉션 재조정 최종 이름/시그니처, `Slot:Extract`
  세부 시맨틱 — `Slot:List(data, updateFn, keyFn?)`로 2026-08-09 세 번째
  세션에 전부 확정·통합(`base/slot-plan.md`), `Extract`도 CRUD 표에서
  완전히 확정(2026-08-09 열한 번째 세션엔 `Extract(index, newElement?)`로
  더 확장). `research/additional-primitives-plan.md`는 더 이상 열린
  항목 없음, 배경 자료로만 유지.
- **"hook"/"pre-hook" 용어 채택 여부** (2026-08-07, 위 심화 후보 6번 참고)
  — `bind-system-plan.md`는 `PreRef`가 위치 무관 호이스팅이라는 것과 일반
  `Ref`가 우선순위 스캔에 참여한다는 것까지는 확정해뒀고(복수 `PreRef`
  간 순서=배열 index 순서, 동적 경로로 도착한 PreRef는 전용 Handler가
  즉시 error — 둘 다 아홉 번째 세션에서 추가 확정), **`PreRef`의 취소
  가능성은 2026-08-12 여섯 번째 세션에 "취소 개념 없음, 재사용은 error"로
  해소됨**(위 심화 후보 6번, `bind-system-plan.md` 참고) — "hook 대
  pre-hook"이라는 용어 자체를 문서화 시 채택할지만 아직 미정.

`PreRef` 취소 가능성 항목은 실제로는 `.claude/question.md`에 별도로
잡혀있던 적이 없었음(이전 서술이 부정확했음, 이번에 확인·수정) — 순수
용어 선택인 "hook"/"pre-hook" 채택 여부만 여기서 계속 추적.

## 다음 단계

이 맵 자체를 지금 실행할 필요는 없음(구현 착수가 여전히 최우선,
`documentation-plan.md` "다음 단계" 참고). 나중에 실제로 문서 사이트
작업을 시작할 때: (1) 위 1번 목차 초안으로 초심자 트랙 스캐폴딩, (2) 파일별
[api] 항목으로 레퍼런스 페이지 스캐폴딩, (3) 4번 리스트를 심화 섹션
에세이 백로그로 사용.
