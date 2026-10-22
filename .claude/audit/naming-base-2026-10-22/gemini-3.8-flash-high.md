# Naming Review: quad 모듈 객체 신규 메서드 2종 및 메타데이터 선언

본 문서는 컴포넌트 킷(Component Kit) 및 게임 개발자(소비자) 관점에서 Luau/Roblox 반응형 UI 라이브러리인 **quad**의 모듈 객체(`q`)에 추가될 신규 API 명칭을 검토한 결과 보고서입니다.

> **안내**: 본 보고서의 모든 추천 사항은 **제안**이며, 최종 채택 및 결정 권한은 사용자에게 있습니다.

---

## 1. Per-q 결과 캐시 (`q:X`)

### 1.1 제안 명칭 및 시그니처 형태 (Pick)
- **추천 명칭**: `GetOrCreate`
- **추천 시그니처 형태**: `q:GetOrCreate(build, [key])` (단일/선택 인자 형태 제안)

### 1.2 Ranked Shortlist
1. **`GetOrCreate`** (1위)
2. **`GetOrBuild`** (자체 추가 제안 후보, 2위)
3. **`Shared`** (3위)
4. **`Cached`** (4위)

---

### 1.3 선정 이유
1. **동작의 본질(조회 후 부재 시 생성 및 보관)을 왜곡 없이 100% 명확히 표현**:
   - `GetOrCreate`는 키로 기존 결과를 조회하고, 없을 때만 `build(q)`를 호출해 캐시한 뒤 반환하는 메커니즘을 가장 정확하게 드러냅니다.
   - 이미 소프트웨어 엔지니어링 전반(Map, Cache, DI 컨테이너)에서 확립된 관례적인 패턴명이므로 러닝 커브가 사실상 0에 수렴합니다.
2. **반응형 라이브러리 특유의 개념 혼동 원천 차단**:
   - quad는 반응형 라이브러리이며 이미 `q.State`, `q.Source`, `q.Effect` 등을 제공합니다.
   - `Memo`나 `Lazy`와 같은 명칭은 반응형 계산값(computed value)이나 지연 평가 객체로 오해될 위험이 매우 큽니다. `GetOrCreate`는 이러한 오해를 완벽히 배제합니다.
3. **자체 추가 후보 `GetOrBuild`의 강점**:
   - 두 번째 인자(또는 빌더 함수)의 매개변수명이 `build`이므로, `q:GetOrBuild(build)` 또는 `q:GetOrBuild(build, key)`는 인자명과 어휘적 정합성이 가장 높습니다.

---

### 1.4 시그니처 형태 (Shape) 검토 및 제안: `q:X(build, [key])`
- **제안 이유**:
  - **킷 서브모듈의 주 사용 패턴 간결화**: 킷 내부 모듈(버튼, 인풋, 패널 등 수십~수백 개)의 90% 이상은 자신의 `build` 함수 식별자 자체를 키로 사용합니다.
    - `q:X(build, [key])` 형태: `return function(q) return q:GetOrCreate(build) end`로 극도로 간결합니다.
    - `q:X(key, build)` 형태 강제 시: `return function(q) return q:GetOrCreate(build, build) end`처럼 동일한 식별자를 중복 전달해야 하는 보일러플레이트가 발생합니다.
  - **문자열 키 지원**: 킷 루트나 패키지 간 공유가 필요할 때만 선택적 두 번째 인자로 넘깁니다(`q:GetOrCreate(build, "quad_kit_roblox_devui_7")`). 킷 모듈은 보통 파일 최상단에 `local function build(q) ... end`로 함수를 분리 선언하므로, 키가 뒤에 와도 가독성을 해치지 않습니다.
- *(대안 제안)*: 만약 인라인 익명 함수 `q:X("key", function(q) ... end)` 작성을 선호한다면, 런타임에서 첫 번째 인자의 타입에 따라 디스패치(`if type(first) == "function" and second == nil then ...`)하는 오버로딩 지원도 검토할 수 있습니다.

---

### 1.5 오해를 부르는 이름 경고 (Flagged Names)
- ⚠️ **`Memo` (강력 비추천 / 오해 위험 높음)**:
  - React의 `useMemo(fn, deps)`나 반응형 시스템(Solid/MobX/Vue)의 `memo`/`computed`를 강하게 연상시킵니다.
  - 개발자가 이를 보고 "의존성 반응형 State가 바뀌면 재계산되는 반응형 캐시인가?"라고 심각하게 오해할 수 있습니다. 실제로는 반응형 추적이나 무효화(invalidation)가 전혀 없는 1회성 per-q 캐시입니다.
- ⚠️ **`Once` (비추천 / 오해 위험)**:
  - Roblox 엔진의 `RBXScriptSignal:Once(fn)`처럼 "단 1회만 이벤트를 수신하는 리스너"로 각인되어 있습니다.
  - 또한 quad 내부에 이미 1회성 실행(반환값 없음)을 수행하는 `q:RunInit`이 존재하므로([quad-base/src/init.luau:155-166](file:///code/Projects/quad-agy/naming-base-1022/quad-base/src/init.luau#L155-L166), 실측), "결과값을 보관하고 반환한다"는 본질적 차이가 이름에서 전혀 드러나지 않습니다.
- ⚠️ **`Lazy` (비추천 / 오해 위험)**:
  - 함수형 프로그래밍이나 Luau에서 `Lazy`는 일반적으로 지연 평가 래퍼 객체(Thunk 또는 `.Value`로 접근하는 지연 컨테이너)를 반환하는 것을 기대하게 만듭니다. 본 메서드는 즉시 빌드를 평가하여 테이블을 반환하므로 불일치합니다.
- ⚠️ **`Singleton` (비추천 / 오해 위험)**:
  - 프로세스/게임 전역(Global) 싱글톤으로 오해하기 쉽습니다. quad는 `Quad.NewModule()`을 통해 격리된 여러 개의 `q` 인스턴스를 만들 수 있으므로([quad-base/src/init.luau:77](file:///code/Projects/quad-agy/naming-base-1022/quad-base/src/init.luau#L77), 실측), 이 캐시는 전역이 아니라 해당 `q` 수명에 묶인 per-q 캐시입니다.

---

## 2. 백엔드 설치 검증 (`q:Y(name, versionPattern)`)

### 2.1 제안 명칭 (Pick)
- **추천 명칭**: `AssertProvider`

### 2.2 Ranked Shortlist
1. **`AssertProvider`** (1위)
2. **`AssertBackend`** (2위)
3. **`AssertProviderVersion`** (3위)
4. **`AssertBackendVersion`** (자체 추가 제안 후보, 4위)

---

### 2.3 선정 이유
1. **설치 API와의 완벽한 대칭성(Symmetry) 및 인지 일관성**:
   - 게임의 셋업 모듈이 백엔드를 설치할 때 호출하는 메서드는 `q:UseProvider(...)`입니다([quad-base/src/init.luau:225](file:///code/Projects/quad-agy/naming-base-1022/quad-base/src/init.luau#L225), 실측).
   - 검증 실패 시 사용자에게 보여줄 에러 메시지 또한 `"call UseProvider in the game's setup module first"`입니다.
   - 따라서 설치 주체와 검증 주체가 모두 `Provider`라는 동일한 용어를 사용하는 `AssertProvider`가 개발자의 멘탈 모델에 가장 자연스럽게 맞닿아 있습니다.
2. **역할의 포괄성 (존재 검증 + 버전 검증)**:
   - 이 메서드는 프로바이더가 아예 설치되지 않았을 때(nil)와 특정 버전 조건을 만족하지 못했을 때 모두 에러를 발생시킵니다.
   - `AssertProviderVersion`처럼 "버전"에만 한정 짓지 않고, `AssertProvider`로 명명하는 것이 "필요한 프로바이더의 충족 여부를 단언(assert)한다"는 전체 동작을 깔끔하게 포괄합니다.
3. **라이브러리 내부 관례(`_assert...`) 계승**:
   - quad 내부에서도 전제조건 위반 시 즉시 에러를 던지는 훅에 `_assertBindable` 등의 명칭을 사용하고 있습니다([quad-base/src/LifetimeHandle.luau:28](file:///code/Projects/quad-agy/naming-base-1022/quad-base/src/LifetimeHandle.luau#L28), 실측).

---

### 2.4 오해를 부르는 이름 경고 (Flagged Names)
- ⚠️ **`AssertProvided` (강력 비추천 / 심각한 오해 위험)**:
  - 수동태 과거분사로 문법적 어색함이 있을 뿐만 아니라, quad가 이미 별도로 가지고 있는 `q.Context` 및 `Context.Provider`([quad-base/src/init.luau:151](file:///code/Projects/quad-agy/naming-base-1022/quad-base/src/init.luau#L151), 실측)와 심각한 용어 충돌을 일으킵니다.
  - 사용자는 `q:AssertProvided(...)`를 보고 "특정 Context의 Provider가 상위에 존재하는지 검사하는 메서드인가?"라고 오해할 소지가 매우 큽니다.
- ⚠️ **`AssertUsing` (비추천 / 모호함)**:
  - 대상(무엇을 using 중인지)이 생략되어 플러그인(`AddPlugin`)인지, 백엔드인지 전혀 구별할 수 없습니다. C#/Luau의 using 키워드나 리소스 관리 문법으로 오인될 수 있습니다.
- ⚠️ **`AssertBackend` (주의 / 용어 분열)**:
  - 개념적으로는 "백엔드"가 맞으나, quad의 실제 공개 API가 `UseBackend`가 아닌 `UseProvider`로 되어 있어, 사용자에게 "Provider와 Backend가 서로 다른 별개의 개념인가?"라는 불필요한 혼선을 유발합니다.

---

## 3. 프로바이더 이름 및 버전 선언 방식

### 3.1 제안 형태 (Pick)
- **추천 형태**: `Provider = { Name = "...", Version = "..." }`

### 3.2 Ranked Shortlist
1. **`Provider = { Name = "...", Version = "..." }`** (1위)
2. **`ProviderName = "..."` / `ProviderVersion = "..."`** (2위)
3. **`Name = "..."` / `Version = "..."`** (3위, ⚠️ 충돌 위험으로 채택 불가)

---

### 3.3 선정 이유 및 충돌 위험 분석
1. **`q.Version` 필드 파괴(Clobbering) 원천 방지 (실측 근거)**:
   - `quad-base`는 생성 시점에 이미 자체 코어 버전인 `Version = "3.4.0"`을 모듈 루트에 선언하고 있습니다([quad-base/src/init.luau:85](file:///code/Projects/quad-agy/naming-base-1022/quad-base/src/init.luau#L85), 실측: `Version = "3.4.0"`).
   - `q:UseProvider`는 인자로 전달된 프로바이더 함수가 반환한 `extension` 테이블의 모든 키를 `q`에 반복문으로 직접 병합합니다([quad-base/src/init.luau:177-179, 248](file:///code/Projects/quad-agy/naming-base-1022/quad-base/src/init.luau#L177-L179), 실측: `for k, v in extension do self[k] = v end`).
   - 만약 프로바이더가 최상위 필드로 `Version = "..."`을 반환하면, **`quad-base`의 코어 버전(`q.Version`)을 덮어써 파괴**하게 됩니다.
   - 또한 최상위 `Name`은 로블록스의 `Instance.Name`이나 일반 변수명과 충돌할 소지가 너무 큽니다.
2. **네임스페이스 격리 및 메타데이터 응집도(Cohesion)**:
   - `q.Provider = { Name = "quad-roblox", Version = "3.4.0" }` 형태로 묶음 제공 시, `q.Version`(base 버전)과 `q.Provider.Version`(프로바이더 버전)이 명확히 공존할 수 있습니다.
   - `AssertProvider` 구현 시에도 다음과 같이 안전하고 직관적인 검사가 가능합니다 (추정 제안):
     ```luau
     local info = self.Provider
     if type(info) ~= "table" or info.Name ~= expectedName ... then
         -- 에러 발생
     end
     ```
3. **미래 확장성**:
   - 향후 프로바이더에 엔진 종류, 렌더링 백엔드 기능 플래그, 빌드 메타데이터 등이 추가되더라도 `Provider` 네임스페이스 하위에 안전하게 추가할 수 있습니다.

---

## 4. 제안 요약 테이블

| 검토 항목 | 제안 픽 (Pick) | 권장 시그니처 / 형태 | 배제/경고 명칭 (Flagged) | 핵심 채택 사유 |
| :--- | :--- | :--- | :--- | :--- |
| **1. Per-q 결과 캐시** | **`GetOrCreate`** (또는 `GetOrBuild`) | `q:GetOrCreate(build, [key])` | `Memo`, `Once`, `Lazy`, `Singleton` | 반응형 State/이벤트 리스너와의 오해 차단, 조회+빌드+캐시 본질 직관적 표현 |
| **2. 백엔드 설치 검증** | **`AssertProvider`** | `q:AssertProvider(name, versionPattern)` | `AssertProvided`, `AssertUsing` | 기존 `UseProvider`와의 완벽한 대칭성, `Context.Provider` 혼동 방지 |
| **3. 메타데이터 선언** | **`Provider = { Name, Version }`** | `{ Provider = { Name = "...", Version = "..." } }` | 최상위 `Name` / `Version` | `q.Version` 덮어쓰기 파괴 방지, 네임스페이스 격리 및 확장성 |

---

## 5. 실측 및 검증 기록 (Worktree 내부)

- **전체 테스트 스위트 실행 결과 (실측)**:
  - 실행 명령: `( ulimit -v 4000000; timeout 600 ./scripts/test.sh )`
  - 판정: Exit Code `0` (ALL PASS)
  - 검증 항목: `luau-analyze`, `luau-lsp analyze`, `doc-coverage` (212/212), `type-surface-check`, `error-codes` (272 ids, 0 errors), `check-version` (3.4.0).
- **관련 파일 및 라인 실측**:
  - `quad-base/src/init.luau:85`: `Version = "3.4.0"` 선언 확인.
  - `quad-base/src/init.luau:177-179`: `mergeExtension`의 `self[k] = v` 복사 루프 확인 (최상위 필드 충돌 위험 실측).
  - `quad-base/src/init.luau:225-251`: `UseProvider`의 fn identity 락 및 `mergeExtension` 호출 확인.
  - `quad-base/src/init.luau:155-166`: `RunInit`의 1회 실행(no return) 계약 확인.
  - `quad-roblox/src/init.luau:73-98`: `QuadRoblox`가 `RobloxFactory(q)` 확장 테이블을 반환하는 구조 확인.
  - `quad-roblox-devui/src/Quad.luau:17`: 기존 킷이 `Quad:UseProvider(...)`를 직접 호출하여 결합되어 있던 구조 확인.
