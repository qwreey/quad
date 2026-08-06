# 확인/결정 필요 목록

**2026-08-04 세션 말미에 전체 재정리함.** 예전엔 라운드(1차~6차)별로 문서가
계속 쌓이면서 순서가 시간순도 우선순위순도 아니게 됐고, 이미 해소된 라운드
기록이 새로 열린 질문보다 위에 있는 등 혼동을 유발했음(문서 감사에서 발견).
그 상세 히스토리는 지우지 않았음 — git log로 이 파일의 이전 버전을 보거나,
각 `base/`/`research/` 문서 안의 라운드 표시("2026-08-04 3차 라운드" 등)를
따라가면 그대로 남아있음. 이 문서는 이제 **"지금 열려있는 것" 우선으로만**
구성.

## 지금 열려있는 것 (우선순위순)

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

### 2. 낮은 우선순위

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
- **v1 하위호환(compat) 레이어 방향** — `research/v1-compat-plan.md`(신규,
  2026-08-06, 같은 날 후속 논의로 수렴). v1 런타임을 v2 위에 재구현하는
  건(문법 흉내) 컴포넌트 정체성 모델 충돌로 얇게 안 되지만, **v1을 그대로
  두고 v2와 병행 실행 + 경계에서만 `state:Observer()`(lazy 포기, 항상
  관측)로 값을 리졸브해 v1 프로퍼티에 재대입하는 브리지**는 유력 방향으로
  수렴(사용자 제안, 기존 base 원시들만으로 조립 가능함을 확인). 남은 결정:
  이 브리지가 양방향(v1→v2도) 필요한지, 브리지 글루 코드를 별도 패키지로
  뺄지.

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
