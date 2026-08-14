# 추가 프리미티브 필요성 조사 — 다른 프레임워크 대비 갭 분석

**상태**: research — 사용자와 라이브 논의로 대부분 수렴(2026-08-06~07),
**2026-08-07 문서 정리에서 확정/기각된 항목을 분리**: Effect/Blocker →
`base/blocker-plan.md`/`base/effect-plan.md`, Batch(lexical) → `archive/
batch-rejected.md`, Context(+레이어드 Store 대안) → `archive/
context-rejected.md`. **[2026-08-09 세 번째 세션]** 마지막으로 남아있던
키 기반 동적 컬렉션 재조정도 `Slot:List(...)` 메소드로 완전히 확정되어
`base/slot-plan.md`로 승격됨(아래 절은 요약+포인터만 남기고 상세는 그쪽
참고) — **[2026-08-09 세 번째 세션 기준] 이 문서에 새로 열려있는 설계
질문은 없었음**, 아래 표/"빈 자리 아닌 것"/"문서화 백로그"/"참고 소스"
절은 배경 리서치 기록으로만 유지. **단 이후 세션에 열린 질문 2개가
새로 추가됨** — "Attribute 그룹 명시적 unset 유틸"(2026-08-12),
"중첩 State 평탄화 `State<State<T>>`"(2026-08-13 여섯 번째 세션, 이후
`question.md` 백로그로 근거 축소) — 아래 해당 절 참고.

## 배경

사용자 질문: "다른 독립 프리미티브나 종속 파생 데이터는 뭐가 더 필요할 것
같나요. 이것만으로 이 프로젝트는 충분하다 생각해요?" — 지금까지 확정된
독립 프리미티브(`Source`/`Store`/`Ref`/`Modifier`/`Slot`/`DI`)+파생 데이터
(`State`/`Observer`)만으로 충분한지, 웹 프레임워크나 실제 Roblox 개발 관점에서 솔직하게
재검토해달라는 요청.

## 조사 방법

서브에이전트 여러 개를 병렬/순차로 띄워 조사(웹 프레임워크 서베이, Fusion/
Vide/v1/artworks 소스 근거 조사, Context 구현 난이도 판정) + 그 결과를
사용자와 라이브로 검증/반박/재조정. `research/framework-comparison-findings.md`
(quad vs Fusion/Vide/react-lua 강점/약점 비교)와는 다른 질문 — 그 문서는
"같은 개념을 quad가 얼마나 잘 구현했는가", 이 문서는 "개념 자체가 통째로
없는 게 있는가/필요한가".

## 결론 요약

| 후보 | 판정 | 현재 위치 |
|---|---|---|
| 키 기반 동적 컬렉션 재조정 | **채택, 확정** — `Slot:List(...)` 메소드로 통합 | `base/slot-plan.md`(2026-08-09 세 번째 세션) |
| Effect(leaf 죽음에 확정 정리 + `state` 있으면 재실행) | **채택, 확정** — Observer와의 관계도 해소 | `base/effect-plan.md` |
| Blocker(값 기반 emit 지연/합치기) | **채택** — Batch의 대안 | `base/blocker-plan.md` |
| Batch(함수/코루틴 스코프 lexical block) | **기각** | `archive/batch-rejected.md` |
| Context(트리 하위 암묵 전파) + 레이어드 Store | **기각** | `archive/context-rejected.md` |
| Observer에 cleanup 반환 계약 추가 | **기각** — 클로저 업밸류로 이미 충분 | `base/effect-plan.md`(근거만 인용) |
| Untrack/Peek | 빈 자리 아님 | 아래 "빈 자리 아닌 것" 절 |
| Suspense/비동기 경계 | 빈 자리 아님(문서화 문제로 재분류) | 아래 "빈 자리 아닌 것" 절 |
| Error Boundary | 빈 자리 아님 | 아래 "빈 자리 아닌 것" 절 |
| Readonly wrapper | 빈 자리 아님 | 아래 "빈 자리 아닌 것" 절 |

## 키 기반 동적 컬렉션 재조정 — 확정, `base/slot-plan.md`로 승격 (2026-08-09 세 번째 세션)

React `key` prop, Vue `v-for :key`, Solid `<For>`, Fusion `ForPairs`/
`ForKeys`/`ForValues`, Vide `indexes()`/`values()`에 대응하는 프리미티브 —
데이터 배열을 정체성(key) 기준으로 diff해서 변경분만 생성/갱신/언마운트한다
(**[정정, 2026-08-13 4차 감사]** 원래 "파괴"였으나 2026-08-13 여섯 번째
세션의 언마운트 전환 반영 — 최신 소스는 `base/slot-plan.md`).
**최종 확정 형태는 자유 함수도 새 타입도 아니라 `Slot`의 콜론 메소드**
(`Slot():List(data, updateFn, keyFn?) -> Slot`) — 상세 시그니처/구현
의사코드/왜 자유 함수·새 타입이 아닌지/`Move` 기반 리오더/`userdata` 기반
`Source` 관리 위임은 전부 `base/slot-plan.md`의 "`Slot:List(...)`" 절
참고, 여기서 반복 안 함.

이 아래 있던 "왜 매핑 함수 직관이 안 통하는가"/"메커니즘 스케치"/
"이름 후보"/"남은 열린 질문" 절은 전부 그 문서로 흡수·확정되어 제거함 —
State 메소드로 두려던 초기 폼팩터가 기각된 경위만 여전히
`archive/keyed-collection-state-method-rejected.md`에 별도 보존.

## 빈 자리 아닌 것으로 확인된 것들

- **Untrack/Peek**(Solid `untrack()`, Vue `toRaw`): quad는 Vide식 암묵
  추적을 기각하고 `:With(...)` 명시적 의존성 선언을 택함 — "읽었지만
  추적 안 하고 싶다"는 필요 자체가 안 생김(`:With`에 안 넣으면 그게 곧
  untracked read). Vide `untrack()`은 암묵 추적 전용 문제라 quad엔 애초에
  적용 안 됨.
- **Suspense/비동기 경계**: `Ref:Wait()`(coroutine 대기) + 처음엔 nil인
  Source로 부분 커버되지만, **quad 컴포넌트가 한 번만 실행된다**는 전제와
  부딪히는 함정이 있음 — 렌더 함수 최상단의 `if loading then return
  Spinner end`류는 마운트 시점 단 한 번만 평가되고 데이터 도착 후
  재평가 안 됨. Slot + Observer 조합으로 실제 구현은 가능하나 1급 패턴이
  아니라서, 새 코어 프리미티브보다는 **"render-once 함정" 문서화
  우선순위 문제**로 재분류(`research/documentation-plan.md`의 권장 패턴
  문서 부류에 속함, React 습관 개발자가 특히 잘 빠질 실수).
- **Error Boundary**: quad 컴포넌트는 평범한 Lua 함수 호출이라, 리스트
  개별 아이템 생성 주변에 `pcall(MyComp, props)`를 감싸는 것만으로 React
  Error Boundary와 같은 격리 효과를 프레임워크 지원 없이 얻음.
- **Readonly wrapper**: `component-composition-plan.md`가 이미 "Source
  직접 전달은 좁은 케이스에 한정, 일반적으론 State + callback이 기본"으로
  못박아둬서 캡슐화 깨짐 문제 자체가 대부분 상황에서 안 생김.
- **Fusion `Observer`/`Attribute`**: quad `state:Observer(fn)` +
  `base/attribute-plan.md`의 Attribute 논의로 이미 커버 중, 신규 아님.
- **디바운스/스로틀**: ~~Fusion/Vide/v1 어디에도 공개 프리미티브로 없음 —
  세 레포 모두 없다는 것 자체가 "quad도 굳이 안 만들어도 된다"는 정황.~~
  **[2026-08-14 뒤집힘]** 사용자가 직접 "`Blocker`와 유사하게 만들어야
  한다"고 지정 — 위 "빈 자리 아님" 판정은 더 이상 유효하지 않음.
  설계 초안은 `research/debounce-throttle-plan.md`. (원 판정의 근거였던
  "세 레포에 없다"는 관찰 자체는 사실이지만, 2026-08-12 열아홉 번째 세션의
  외부 리서치에서 RxJS/VueUse 등 Roblox 밖에선 가장 흔한 콤비네이터
  카테고리 중 하나로 확인돼 근거로서의 무게가 이미 약해져 있었음.)

## 문서화 백로그 (2026-08-06~07, `documentation-content-map.md`에도 반영)

- **quadnomicon 에세이**:
  - "왜 lexical Batch를 기각하고 대신 값 기반 Blocker를 택했는가" —
    `archive/batch-rejected.md`와 `base/blocker-plan.md`의
    Blocker 절을 나란히 비교.
  - "왜 Context가 없는가" — `archive/context-rejected.md` 참고.
  - "왜 push-invalidate/pull-recompute 설계가 laziness와 재계산 방지를
    최우선 목표로 뒀는가" — Blocker 같은 파생 프리미티브가 이 목표 위에서
    자연스럽게 나온 이유까지 포함해 기존 심화 콘텐츠 후보 3번(`왜
    push-invalidate/pull-recompute인가`)을 더 깊게 확장.
- **심화 문서**:
  - "State 파생 체인 동작 원리" — emit이 아래로 전파되고, `Get()` 요청이
    위로 거슬러 올라가 재계산된 뒤 다시 아래로 내려오는 흐름을 명확히
    설명(Blocker/Effect 둘 다 이 흐름 위에서 동작하므로 선행 이해로 필요).
  - "`:Compute` 함수 안에서 `if` 등으로 일부 의존값만 조건부로 사용하는
    유연한 구조" — 명시적 의존성 선언(`:With`) 위에서도 실제 계산은
    조건부로 일부만 쓸 수 있다는 팁.
  - "Blocker 사용 가이드" — 파이프라인 최종 연산 지점에 배치, **네스팅
    금지를 강하게 명시**(`base/blocker-plan.md`의 "재진입" 절
    참고, 문서화 시 최우선 강조 항목).
  - "여러 Source를 한꺼번에 바꿀 때 Blocker 없이도 중복 재계산을 피하는
    파이프라인/업데이트 순서 팁"(Blocker를 안 쓰는 단순 케이스용 보조 팁,
    기존 "심화 최적화 팁" 항목을 Blocker 존재를 전제로 재조정).

## 참고: 조사에 사용한 소스 근거

- Fusion: `State/ForPairs.luau`, `State/ForKeys.luau`,
  `Utility/Contextual.luau`, `Graph/Observer.luau`, `Instances/Attribute.luau`,
  `Memory/doCleanup.luau`
- Vide: `indexes.luau`, `values.luau`, `context.luau`, `batch.luau`,
  `action.luau`, `untrack.luau`, `cleanup.luau`
- quad v1: `store.lua`, `tracker.lua`, `class.lua`(diff/reconcile/keyed
  계열 헬퍼 없음, grep 확인)
- artworks: `EventDrivenProgramming/Observable.luau`, `Utility/Array.luau`,
  `GlobalDataStorage/request.luau`, `DeclarativeProgramming/DeclarativeInstance.luau`

경로는 모두 `.claude/initreq/<repo>/...` 기준(읽기 전용 참고 레포).
