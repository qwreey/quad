# 확인/결정 필요 목록

**2026-08-04 세션 말미에 전체 재정리함.** 예전엔 라운드(1차~6차)별로 문서가
계속 쌓이면서 순서가 시간순도 우선순위순도 아니게 됐고, 이미 해소된 라운드
기록이 새로 열린 질문보다 위에 있는 등 혼동을 유발했음(문서 감사에서 발견).
그 상세 히스토리는 지우지 않았음 — git log로 이 파일의 이전 버전을 보거나,
각 `base/`/`research/` 문서 안의 라운드 표시("2026-08-04 3차 라운드" 등)를
따라가면 그대로 남아있음. 이 문서는 이제 **"지금 열려있는 것" 우선으로만**
구성.

## 지금 열려있는 것 (우선순위순)

### 1. [최우선] 컴포넌트 경계에서 modifier/Ref가 어떻게 전달되는가

사용자가 "지금 quad에서 가장 문제되는 부분"으로 직접 지목. 컴포넌트가
플레인 함수이고 반환하는 루트가 여러 개(혹은 Slot으로 갈라지는 구조)일 때,
호출부가 넘긴 modifier/Ref가 "어느 루트로 가야 하는지" 모호해지는 케이스가
있음. Jetpack Compose는 언어 강제가 아니라 "컴포저블은 `modifier` 파라미터를
받아 루트에 적용해야 한다"는 순수 관례(+린트)로 풂 — quad도 비슷한 관례
기반으로 갈 수 있어 보이나 다중 루트 케이스는 미정.

**주의**: modifier "값 자체"가 어떻게 동작하는지(정적 merge, immutable+clone
체이닝, State 필드 지원)는 이미 완전히 확정됨(`base/modifier-plan.md`) — 이
질문은 그것과 별개로 "경계를 어떻게 통과하느냐"만 다룸, 혼동하지 말 것.

→ 상세/배경: `research/component-composition-plan.md`.

### 2. 용어 정리 (사용자 요청, 진행 중)

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
- **`PerInstanceState`(2순위)**: 핵심 프리미티브 `State`와 이름이 겹쳐서
  실제로는 완전히 무관한 유틸(인스턴스별 weak-keyed 저장소)인데 혼동
  유발 가능 — `PerInstanceStorage`/`InstanceData` 등 대안.
- **`Slot`(2순위)**: Vue의 "slot"(콘텐츠 주입 지점)과 이름은 같지만 의미가
  다름(quad의 Slot은 자식 배열 재조정 프리미티브) — Vue 배경 있는 사람이
  헷갈릴 수 있음.
- **`CreatedRef`/`canExecute`(3순위, 사소함)**: `CreatedRef`는 과거분사형이라
  생성자처럼 안 읽힘. `canExecute`는 실제로 "이 핸들이 아직 살아있나"
  확인인데 이름이 범용 권한 체크처럼 들림 — `isAlive` 쪽이 더 직접적.
- **이미 지나간 사례로 참고**: `register`(v1) → `State`(v2) 리네임은
  "모호함"은 풀었지만 "다른 뜻으로 이미 쓰이는 단어"라는 새 문제를 만든
  셈 — 이번 정리에서 같은 패턴을 조심할 것.
- `Store`/`Source`/`Modifier`/`Ref`/`process`/`retract`/`isHandlable`은
  업계 선례와 잘 맞거나 이미 신중하게 결정된 이름들이라 특별한 문제 없음.

### 3. 낮은 우선순위

- `research/existing-instance-bind-plan.md` — 스코프 논의만 필요, 구현
  착수를 막지 않음.
- **v1 `objectListClass.__newIndex` 오타 기능의 재현 테스트 필요** —
  `base/quad-v1-architecture.md`에 남겨진 v1 내부 동작 확인 사항, 마이그레이션
  가이드 작성 시점에 필요. 지금은 그냥 백로그로만 기록.

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
| 컴포넌트 이식성(전역 store 참조 시 재사용성 문제) | `base/purity-and-effects-plan.md` |
| Fusion/Vide 비교 리서치(주의: 일부 서술은 이후 라운드에서 뒤집힘, 문서 내 정정 표시 참고) | `base/comparison-fusion-vide.md` |
| v1 내부 동작 스냅샷 | `base/quad-v1-architecture.md` |
| 트윈 오버라이드(기본값 Cancel), 세부 옵션만 남음 | `research/tween-plan.md` |
| quad2-try(폐기된 이전 시도) 리서치 — OOP 상속/커스텀 파서/Slot 스텁/`Pipe` COW 전부 죽은 접근으로 확인, 반복 조사 금지 | `base/bind-system-plan.md` |

---
전체 순서/우선순위는 루트 `CLAUDE.md`가 최종 소스 — 위 표는 힌트일 뿐 그쪽이
바뀌면 이 문서도 갱신할 것.
