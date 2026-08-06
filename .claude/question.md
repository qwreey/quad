# 확인/결정 필요 목록

**2026-08-04 세션 말미에 전체 재정리함.** 예전엔 라운드(1차~6차)별로 문서가
계속 쌓이면서 순서가 시간순도 우선순위순도 아니게 됐고, 이미 해소된 라운드
기록이 새로 열린 질문보다 위에 있는 등 혼동을 유발했음(문서 감사에서 발견).
그 상세 히스토리는 지우지 않았음 — git log로 이 파일의 이전 버전을 보거나,
각 `base/`/`research/` 문서 안의 라운드 표시("2026-08-04 3차 라운드" 등)를
따라가면 그대로 남아있음. 이 문서는 이제 **"지금 열려있는 것" 우선으로만**
구성.

## 지금 열려있는 것 (우선순위순)

### 0. 추가 프리미티브 필요성 — 사용자 요청, 조사 완료(2026-08-06)

사용자 질문: "다른 독립 프리미티브나 종속 파생 데이터는 뭐가 더 필요할 것
같나요. 이것만으로 이 프로젝트는 충분하다 생각해요?" — 웹 프레임워크/
Fusion/Vide/quad v1 소스를 서브에이전트 2개로 병렬 조사 완료, 상세는
`research/additional-primitives-plan.md`. 요지:

- **키 기반 동적 컬렉션 재조정(가장 시급)**: Fusion `ForPairs`/`ForKeys`/
  `ForValues`, Vide `indexes()`/`values()`, React `key` prop에 대응하는
  프리미티브가 quad엔 전혀 없음 확인 — `Slot`은 CRUD 껍데기일 뿐 diff
  엔진이 아님. 인벤토리/리더보드/채팅로그 같은 실전 리스트 UI에 직결.
  Slot 확장으로 갈지 별도 프리미티브(가칭 `Keyed`/`ForEach`)로 갈지부터
  전혀 정해진 게 없음 — 사용자 판단 필요.
- Effect/Watch(자동 cleanup 공개 API), Batch/Transaction(이벤트 store-bind
  churn 문제 직결), Context(트리 전파, 단 `purity-and-effects-plan.md`
  이식성 원칙과 상충)는 부차적 후보로 확인, 착수 여부 미정.
- Untrack/Suspense/Error Boundary/Readonly는 조사 결과 새 프리미티브 없이
  기존 설계·Lua 자체 기능으로 이미 충분한 것으로 판단.

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
  때 이 연쇄까지 같이 고려할 것.
- **`PerInstanceState`(2순위)**: 핵심 프리미티브 `State`와 이름이 겹쳐서
  실제로는 완전히 무관한 유틸(인스턴스별 weak-keyed 저장소)인데 혼동
  유발 가능 — `PerInstanceStorage`/`InstanceData` 등 대안.
- **`Slot`(2순위)**: Vue의 "slot"(콘텐츠 주입 지점)과 이름은 같지만 의미가
  다름(quad의 Slot은 자식 배열 재조정 프리미티브) — Vue 배경 있는 사람이
  헷갈릴 수 있음.
- **`CreatedRef`/`canExecute`(3순위, 사소함)**: `CreatedRef`는 과거분사형이라
  생성자처럼 안 읽힘. `canExecute`는 실제로 "이 핸들이 아직 살아있나"
  확인인데 이름이 범용 권한 체크처럼 들림 — `isAlive` 쪽이 더 직접적.
- **`Ref`(3순위, 2026-08-06 추가)**: 정의가 "quad가 만든 instance를 얻는
  통로"에서 "아무 사용자 값이나 담는 범용 값 박스"로 넓어져서(`base/
  bind-system-plan.md` "Ref 일반화" 절), 이름이 여전히 넓어진 의미에
  맞는지 재검토 대상.
- **"프로바이더"(3순위, 사소함)**: `base/module-lifecycle-plan.md`가
  "provider"라고 불러온, `isHandlable`로 참여 여부를 결정하고 우선순위대로
  스캔되는 pluggable 참가자 개념 — 정확한 이름을 "provider"/"processor"/
  그냥 "plug" 중 뭘로 할지 아직 안 정함(개념 자체는 확정). 이 문서가 자체적으로
  "question.md에도 취합"이라고 표시해뒀던 항목이 누락돼 있어 이번에 추가.
- **이미 지나간 사례로 참고**: `register`(v1) → `State`(v2) 리네임은
  "모호함"은 풀었지만 "다른 뜻으로 이미 쓰이는 단어"라는 새 문제를 만든
  셈 — 이번 정리에서 같은 패턴을 조심할 것.
- `Store`/`Source`/`Modifier`/`Ref`/`process`/`retract`/`isHandlable`은
  업계 선례와 잘 맞거나 이미 신중하게 결정된 이름들이라 특별한 문제 없음.

### 2. 구현 착수 직전 감사 결과 (2026-08-06 신설, M0 착수 전 확인 권장)

`research/pre-implementation-audit.md` — `base/` 전체를 M0 착수 직전
시점에서 모호성/지연결정리스크/단순화후보 세 렌즈로 재감사한 결과. 총
11개 우선순위1(구현 중 바로 부딪힐 가능성 높음) + 11개 우선순위2(지금
정해두면 싼 지연리스크) + 2개 단순화후보. 전체는 그 문서 참고, 특히
사용자 판단이 필요한 것 위주로 요약:

- **Tween.luau가 "범용 store-bind 캐치올 핸들러"의 유일한 예시로 서술됨** —
  일반 반응형 프로퍼티 바인딩(`BackgroundColor3 = store.color`, 애니메이션
  없음)이 결국 이름은 "Tween"인 파일을 거쳐가는 건지, 아니면 별도 범용
  `Handlers/StoreBind.luau`가 있어야 하는 건지 확정 필요 — 우선순위1-1.
- **`State<Modifier>` 타입 차단(엔지니어링 비용 감수)과 Ref/Slot이 Modifier
  필드에 들어가는 건 UB 방치 — 같은 문서 안에서 정반대 원칙이 근거 설명
  없이 나란히 적용됨.** 왜 이 경우만 예외로 방어하는지 명문화 필요, 또는
  Luau에서 실제 타입 차단이 가능한지부터 확인(안 되면 그냥 UB로 격하) —
  문서모순 절 + 우선순위2-2.
- **`props.Modifier`/`props.Ref` forwarding 관례가 Lua 배열 리터럴
  nil-hole 함정에 그대로 노출됨** — caller가 Modifier/Ref를 안 넘기면
  `{nil, ref, child}`에서 뒤 항목까지 통째로 무시될 수 있는 버그 클래스.
  M0 스파이크에 이 케이스(안 넘기는 경우)를 반드시 포함시킬 것 — 우선순위1-5.
- **`canExecute`/`Connected`의 실제 구현 방식(Parent==nil vs Connection.
  Connected vs Destroying 플래그)이 미확정인데 이미 Slot/Observer/store-bind
  retract 전역에 재사용 확정됨** — M2/M3 착수 전 실측 필요 — 우선순위1-6.
- **`LifetimeHandle` 인터페이스가 M8에 배치돼 있지만 M4/M6이 이미 그걸
  필요로 함(로드맵 순서 역전)** — quad-base 인터페이스 정의를 M2/M3로
  옮기는 게 자연스러워 보임, `ROADMAP.md` 수정 필요 — 우선순위1-9.
- 그 외(Slot CRUD 의미론 미정의, retract 시 "이전 핸들러" 추적 책임 소재,
  우선순위 스캔 동률/매치실패 처리, `:Compute`의 `previous` 인자가
  오버엔지니어링일 수 있음, UI shorthand의 기존 UICorner 매칭 기준 등)는
  `pre-implementation-audit.md` 본문 참고.

### 3. 낮은 우선순위

- `research/existing-instance-bind-plan.md` — 스코프 논의만 필요, 구현
  착수를 막지 않음.
- **v1 `objectListClass.__newIndex` 오타 기능의 재현 테스트 필요** —
  `base/quad-v1-architecture.md`에 남겨진 v1 내부 동작 확인 사항, 마이그레이션
  가이드 작성 시점에 필요. 지금은 그냥 백로그로만 기록.
- **여러 Slot이 형제로 섞일 때 순서 보장** — `base/slot-plan.md`의 "여러
  Slot이 섞일 때 순서 보장" 절 참고. Roblox 단일 백엔드로는 급하지 않음
  (LayoutOrder/ZIndex로 대부분 해결), 다른 백엔드(웹 DOM 등) 재사용성과
  직결되는 문제라 Slot 코어 로직 구현 시점에 재검토.
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
- **Attribute 특수 키 타입 파라미터화** — `base/bind-system-plan.md`
  "Attribute 특수 키" 절(2026-08-06 신규). `[Attribute<<boolean>> "name"]`
  제네릭 스타일 vs `[BooleanAttribute "name"]` 타입별 정적 생성자 패밀리
  중 뭘로 갈지 — 소견은 DI 인스턴스 생성 패턴처럼 "제네릭 하나 + 자주
  쓰는 타입만 정적 지름길" 절충이지만 확정 아님, M10(Handlers/Attribute)
  착수 전 아무 때나 확인해도 됨.
- **UICorner/UIPadding/UIScale 인라인 편의 키 세부** — `research/
  ui-shorthand-plan.md`. 기능 필요 여부(여전히 필요로 재확정)·메커니즘
  (Handler)·패키지 배치(quad-roblox 코어)는 확정, 남은 건 이름 재검토
  (용어 정리 합류)와 `RoundSize`(이미지 라운드) 대체 방식뿐.

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
| Modifier(정적 merge, immutable 체이닝, State 필드 지원) | `base/modifier-plan.md` |
| 컴포넌트화(플레인 함수, State/Source 경계, 컴포넌트 경계 modifier/Ref는 named parameter로 전달, multi-root 개념 폐기, `Modifier.Merge`) | `base/component-composition-plan.md` |
| 컴포넌트 이식성(전역 store 참조 시 재사용성 문제) | `base/purity-and-effects-plan.md` |
| Fusion/Vide 비교 리서치(주의: 일부 서술은 이후 라운드에서 뒤집힘, 문서 내 정정 표시 참고) | `base/comparison-fusion-vide.md` |
| v1 내부 동작 스냅샷 | `base/quad-v1-architecture.md` |
| 트윈 오버라이드(기본값 Cancel), 세부 옵션만 남음 | `research/tween-plan.md` |
| quad2-try(폐기된 이전 시도) 리서치 — OOP 상속/커스텀 파서/Slot 스텁/`Pipe` COW 전부 죽은 접근으로 확인, 반복 조사 금지 | `base/bind-system-plan.md` |

---
전체 순서/우선순위는 루트 `CLAUDE.md`가 최종 소스 — 위 표는 힌트일 뿐 그쪽이
바뀌면 이 문서도 갱신할 것.
