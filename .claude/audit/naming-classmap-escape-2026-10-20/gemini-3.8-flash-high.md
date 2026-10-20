# quad 커스텀 클래스 맵 탈출구(Class-Map Escape) 명칭 검토 보고서

본 보고서는 Luau 신규 타입 솔버(LuauSolverV2) 환경에서 UI 및 3D 계층을 작성하는 Roblox 개발자(라이브러리 사용자)의 관점에서 quad의 커스텀 클래스 맵 탈출구 API 명칭(`q.???`)을 검토한 결과입니다.
프로젝트의 모든 최종 결정 권한은 사용자에게 있으며, 본 문서에 제시된 판정 및 대안은 사용자의 판단을 돕기 위한 **제안**입니다.

---

## 1. `With`에 대한 판정 (Verdict)
- **판정**: **change (변경 권고)** [제안]
- **판정 근거**:
  1. **자기서술성(Self-descriptiveness) 결여**: quad 명명 원칙 2("자기서술적일 것 — 이름만으로 무엇이 들어가는지 읽혀야 한다")에 정면으로 위배됩니다 [실측: [`.claude/research/declaration-naming-table.md:14`](file:///code/Projects/quad-agy/naming-classmap-escape/.claude/research/declaration-naming-table.md#L14)]. `q.With`만으로는 플러그인(`WithPlugin`), 옵션/설정(`WithOptions`), 테마, 백엔드 중 무엇을 'With'하는지 전혀 유추할 수 없습니다 [추정].
  2. **런타임 인자 기대와 빈 호출 `()`의 인지 부조화**: `With`는 전치사 특성상 런타임에 주입할 값 인자(`q.With(options)`)를 강하게 기대하게 만듭니다. 그러나 이 탈출구는 런타임 인자가 없는 순수 타입 바인딩(`q.With<<Map>>()`)이므로 호출 형태가 어색합니다 [추정].
  3. **과거 명칭 충돌 및 철회 이력**: quad는 이미 `State:With(...)`가 "무엇을 With하는가?"라는 모호성 때문에 `State:Depend(...)`로 개명된 전력이 있습니다 [실측: [`quad-types/src/init.luau:205`](file:///code/Projects/quad-agy/naming-classmap-escape/quad-types/src/init.luau#L205)]. 최상위 API에서 다시 모호한 `With`를 채택하는 것은 일관성에 역행합니다 [추정].

---

## 2. 최선의 이름 및 대안 (Best Name & Alternatives)

### Best Name: `ForClasses` [제안]
- **한 줄 근거**: "이 클래스 집합을 위한 quad 표면"이라는 의미를 직관적으로 전달하며, 반환값이 클래스 목록이 아닌 선언 표면(`W.Elem`, `W.Modifier` 등)임을 명확히 유지함 [제안].
- **호출 형태 예시**:
  ```luau
  -- 로컬 선언
  local W = q.ForClasses<<{ Part: Part, Beam: Beam, BasePart: BasePart }>>()
  local Part = W.Elem "Part"
  local s = W.Spread "BasePart" { Anchored = true }

  -- 공용 모듈 (shared module)
  return q.ForClasses<<World>>()
  ```
- **Confusion Risk**: **Low**
  - **Roblox 충돌**: 없음. Roblox의 핵심 객체 모델 용어인 "Class"(`ClassName`, `:IsA`)와 정확히 일치하면서도, 엔진의 단수 명사 프로퍼티와 충돌하지 않음 [실측/추정].
  - **Luau 충돌**: 없음. Luau RFC의 `class` 키워드(단수)와 시각적/구문적으로 명확히 분리됨 [추정].
  - **라이브러리 내부**: `q.Raw`, `q.Backend`, `q.NewModule()` 등 기존 최상위 API와 겹치지 않고 목적이 분명함 [실측: `q` 표면 구조]. 또한 `Extend`처럼 기존 내장 GUI 맵과 자동 병합(merge)된다는 헛된 기대를 주지 않고 독립 바인딩임을 암시함 [추정].

---

### Alternative 1: `Classes` [제안]
- **한 줄 근거**: 단일 단어로 가장 간결하며, 타입 인자로 주어지는 대상(`{ Part: Part }`)이 클래스 목록임을 직관적으로 가리킴 [제안].
- **호출 형태 예시**:
  ```luau
  local W = q.Classes<<World>>()
  local Part = W.Elem "Part"
  ```
- **Confusion Risk**: **Medium**
  - 복수 명사 `Classes`는 클래스 객체들의 딕셔너리(`{ Part = ... }`)를 반환할 것으로 기대하기 쉬우나, 실제 반환값은 `Elem`/`Modifier`를 담은 선언 표면이므로 `W.Part`로 접근하려는 직관적 오류를 유발할 수 있음 [추정].
  - 단수 `Class`는 이미 사용자가 Luau `class` RFC와의 혼동을 이유로 기각한 바 있어 [실측: [`.claude/research/declaration-naming-table.md:45`](file:///code/Projects/quad-agy/naming-classmap-escape/.claude/research/declaration-naming-table.md#L45)], 복수형도 유사한 어감 부담이 일부 잔존함 [추정].

---

### Alternative 2: `For` [제안]
- **한 줄 근거**: 영문 독해(`q For <<World>>()`)가 가장 간결하고 매끄러우며, 특정 타입 도메인 전용 표면을 얻는 뉘앙스를 자연스럽게 살림 [제안].
- **호출 형태 예시**:
  ```luau
  local W = q.For<<World>>()
  local Part = W.Elem "Part"
  ```
- **Confusion Risk**: **Medium**
  - 대문자 `For`는 식별자로서 유효하지만, Luau의 핵심 제어문 예약어 `for`와 대소문자만 달라 시각적 인지 부하 및 코드 스캔 시의 이질감이 있음 [추정].
  - "무엇을 위한 것인지"가 생략되어 있어 백엔드 플랫폼(`q.For<Roblox>`)이나 렌더 타겟 등으로 오해될 여지가 있음 [추정].

---

### Alternative 3: `Surface` [제안]
- **한 줄 근거**: 라이브러리 내부의 개념적 실체인 "선언 표면(typed surface)"을 정확히 지칭하여 반환 객체의 정체성을 표현함 [제안].
- **호출 형태 예시**:
  ```luau
  local W = q.Surface<<World>>()
  local Part = W.Elem "Part"
  ```
- **Confusion Risk**: **High**
  - Roblox 환경에서 `Surface`는 `SurfaceGui`, `SurfaceAppearance`, `SurfaceType` 등 3D 서피스 렌더링 도메인 용어로 강력하게 점유되어 있음 [실측].
  - 3D/World 객체를 위한 탈출구에서 `q.Surface`를 보았을 때 `SurfaceGui` 관련 헬퍼나 3D 캔버스 빌더로 오인할 확률이 매우 높음 [추정].

---

### 기타 기각 후보군 검토 메모
- **`Extend` (Risk: High)**: 기존 내장 30개 GUI 맵에 신규 클래스가 "확장/추가(merge)"된다는 인상을 강하게 줌. 하지만 실제로는 솔버 부하("Code is too complex") 방지를 위해 **기존 맵과 합쳐지지 않는 독립 바인딩**이므로, 사용자가 `W.Elem "Frame"`을 함께 쓰려다 겪는 오류 위험이 극도로 큼 [실측: [`.claude/research/declaration-surface-plan.md:119`](file:///code/Projects/quad-agy/naming-classmap-escape/.claude/research/declaration-surface-plan.md#L119) / 추정].
- **`Bind` (Risk: High)**: quad의 핵심 반응형 도메인(`StoreBind`, 프로퍼티 바인딩)과 용어가 겹쳐 극심한 개념 혼선 유발 [실측: `bind-system-plan.md`].
- **`Using` (Risk: Medium)**: C# `using`이나 React hooks(`use...`)와 혼동되어 런타임 스코프/리소스 관리자로 오독됨 [추정].
- **`ClassMap` (Risk: Medium)**: 입력값 형태의 명칭이라 반환되는 빌더 표면(`Elem`, `Modifier`)과의 범주 불일치가 발생함 [추정].

---

## 3. 메커니즘 자체에 대해 이름/문서가 경고해야 할 점 (종합 3줄)
1. **독립 치환(No Merge)**: 내장 GUI 맵(30개)과 자동 합병되지 않고 전달받은 타입 맵만으로 제한되므로, GUI와 3D를 혼용하려면 사용자가 해당 맵 타입에 양쪽을 모두 선언해야 함 [추정].
2. **런타임 무검증(Zero Runtime Guard)**: 런타임에는 아무런 인자도 받지 않고 검증도 수행하지 않으므로, `{ Part: Frame }`이나 오타처럼 잘못된 매핑 타입을 넘겨도 타입 시스템과 런타임이 이를 감지하지 못함 [추정].
3. **솔버 복잡도 한계(Solver Complexity)**: 탈출구라 하더라도 수백 개의 클래스를 한 맵에 대량 등록하면 quad가 내장 맵을 30개로 축소했던 원인인 Luau의 "Code is too complex" 오류가 사용자 코드에서 재발함 [실측: [`.claude/research/declaration-surface-plan.md:119`](file:///code/Projects/quad-agy/naming-classmap-escape/.claude/research/declaration-surface-plan.md#L119) / 추정].
