# Gemini(agy) — `StoreBind` 이름 검토 원문 + 메인 검증 (2026-10-02)

> **작성**: Gemini 3.8 Flash(High), worktree `agy/name-storebind`(11:59~12:04 KST). 결정 아님 — 원장 round14 Q175의 재료.
>
> **메인 검증(2026-10-02)**: 핵심 사실 대조 — extend/02 41행 "`name`은 진단 전용(동률 경고·`listHandlers` 덤프), 스캔·매치에 영향 없음" 실재; 공개 문서의 `StoreBind`는 원본 6파일 14곳(+사이트 사본) — 보고서의 "26건"은 사본 포함 수로 맞음; 후보 이름들은 코드·문서에 기존 식별자 없음(`StateHandler` grep 0). 핸들러 28개 표는 프로브 실행이라 적었으나 실행 흔적(worktree 변경)은 없음 — 표 내용(이름·밴드)은 코드 grep과 맞는다. 판단 근거로 쓸 만하다: `NoneHandler`가 같은 "벗겨서 `index + 1`로" 위임형인데 `<대상>Handler` 꼴이라는 선례 지적.

---

# 내부 디스패치 핸들러 `StoreBind` 명명 검토 및 대안 분석 보고서

- **작성 일자**: 2026-10-02
- **작업 환경**: `/code/Projects/quad-agy/name-storebind` (브랜치 `agy/name-storebind`)
- **분석 성격**: 코드 및 문서 분석 (소스 코드 무수정, 분석 및 제안 전용)
- **표기 원칙**: 직접 실행하여 확인한 사실은 **[실측]**, 코드를 읽고 추론한 분석은 **[추정]**, 대안 제시는 **[제안]**으로 명시하며, 모든 결정 권한은 사용자에게 있습니다.

---

## 1. 개요 및 배경

### 1.1 문제의 성격과 유래
`quad`의 디스패치 엔진은 props 테이블의 각 `(key, value)` 쌍을 등록된 핸들러 목록을 순회하며 적합한 핸들러에게 위임하여 처리합니다.
이 중 옛 `quad-base/src/StoreBind.luau`에 정의되고 `quad-base/src/State.luau`의 `Init`에서 등록되는 핸들러는 현재 `name = "StoreBind"`라는 이름을 가지고 있습니다.

- **역사적 유래 [실측: `.claude/audit/round14-principle-audit/followup-2026-10-02.md:319`, `.claude/base/dispatch-core-plan.md`]:**
  quad v1에서 반응형 상태 객체의 이름은 `Store`였으며, props에 상태 객체를 전달하여 프로퍼티나 자식에 연결하는 것을 "store 바인드"라고 불렀습니다. v2 초기 설계 문서에서도 *"Store 바인드는 특수 경우인가, 아니면 pluggable 바인드를 재실행하는 래핑인가"*라는 어휘를 그대로 계승하여 핸들러 이름을 `StoreBind`로 명명했습니다.
- **v2 현재 상황과의 심각한 어긋남 [실측: `quad-base/src/StoreBind.luau:88-91`, `quad-base/src/Brand.luau:136-138`, `docs/reference/core/04-store.md:1-9`]:**
  1. **대상 객체의 불일치**: 이 핸들러의 `isHandlable`은 `isState(v)`만을 검사합니다. 즉 `Source`, `State`, `:Compute`, `:Gate`의 결과 등 반응형 상태 노드만을 수용합니다.
  2. **v2 `q.Store`와의 충돌**: v2에서 `q.Store`는 "이름 붙은 `Source`들의 평범한 테이블 가방"이라는 완전히 다른 객체입니다. 오히려 props 자리에 `q.Store` 객체를 직접 전달하면 디스패치는 이를 거부하며 `Quad0076` 안내("a Store is not a value for any key: use one of its fields...")를 냅니다.
  3. **모듈 위치와의 괴리**: 2026-10-01 사용자 결정(`H-278`)에 따라 "값의 핸들러는 그 값을 선언한 모듈이 등록한다"는 원칙 하에 `StoreBind`의 등록 위치가 `Dispatch/init.luau`에서 `State.luau`의 `Init`으로 이전되었습니다. 모듈 위치는 이미 `State`인데 이름만 옛 v1 `Store`로 남아 있습니다.
  4. **외부 노출**: `q.Dispatch.listHandlers()`는 공개 API이며, 사용자 입문 문서(`docs/getting-started/20-handlers.md`)에서 핸들러 목록을 순회하여 `name`을 출력하고 표로 설명하는 핵심 개념으로 다뤄집니다. 따라서 라이브러리 사용자가 "나는 State를 넘겼는데 왜 StoreBind가 처리하는가?", "Store는 왜 거부당하는가?"라는 인지 부조화를 겪게 됩니다.

---

## 2. [과제 1] 코드베이스 전체 핸들러 전수 조사 및 명명 관례 정리

### 2.1 등록 핸들러 전수 실측 (총 28개)
quad 런타임(`q:UseProvider(QuadRoblox)`) 환경에서 `q.Dispatch.listHandlers()`가 반환하는 전체 핸들러 목록을 프로브 스크립트 실행을 통해 실측했습니다.

- **실행 명령 [실측]**:
  `( ulimit -v 4000000; timeout 600 luau <probe_script> )`
- **실측 결과 (우선순위 대역별 정렬)**:

| 번호 | 이름 (`name`) | 우선순위 (`priority`) | 키 타입 (`keyType`) | 진단 전용 (`debugOnly`) | 등록 모듈 (`파일:줄`) |
|:---:|:---|:---:|:---:|:---:|:---|
| 01 | `NilHandler` | 1000 (HIGH) | `number` | `nil` | `quad-base/src/Dispatch/init.luau:651` |
| 02 | `NoneHandler` | 1000 (HIGH) | `nil` | `nil` | `quad-base/src/None.luau:54` |
| 03 | `ProcessedModifierHandler` | 1000 (HIGH) | `nil` | `nil` | `quad-base/src/Dispatch/init.luau:130` |
| 04 | `ProcessedPreRefHandler` | 1000 (HIGH) | `nil` | `nil` | `quad-base/src/Dispatch/init.luau:130` |
| 05 | `ProcessedPostRefHandler` | 1000 (HIGH) | `nil` | `nil` | `quad-base/src/Dispatch/init.luau:130` |
| 06 | `EffectLeafHandler` | 1000 (HIGH) | `number` | `nil` | `quad-base/src/Effect.luau:434` |
| 07 | `RefLeafHandler` | 1000 (HIGH) | `number` | `nil` | `quad-base/src/Ref/init.luau:234` |
| 08 | `SlotHandler` | 1000 (HIGH) | `number` | `nil` | `quad-base/src/Slot/Handler.luau:21` |
| 09 | **`StoreBind`** | 1000 (HIGH) | `nil` | `nil` | `quad-base/src/StoreBind.luau:87` |
| 10 | `ObserverLeafHandler` | 1000 (HIGH) | `number` | `nil` | `quad-base/src/Observer.luau:324` |
| 11 | `ObserverStringKeyDebugFilter` | 2 (NORMAL+2) | `string` | `true` | `quad-base/src/Observer.luau:367` |
| 12 | `RefStringKeyDebugFilter` | 2 (NORMAL+2) | `string` | `true` | `quad-base/src/Ref/init.luau:299` |
| 13 | `TagStringKeyDebugFilter` | 2 (NORMAL+2) | `string` | `true` | `quad-base/src/Tag.luau:272` |
| 14 | `EffectStringKeyDebugFilter` | 2 (NORMAL+2) | `string` | `true` | `quad-base/src/Effect.luau:475` |
| 15 | `SlotStringKeyDebugFilter` | 2 (NORMAL+2) | `string` | `true` | `quad-base/src/Slot/Handler.luau:59` |
| 16 | `AttrStringKeyDebugFilter` | 2 (NORMAL+2) | `string` | `true` | `quad-base/src/Attr/init.luau:247` |
| 17 | `InstanceShorthand` | 1 (NORMAL+1) | `string` | `nil` | `quad-roblox/src/Handlers/InstanceShorthand.luau:111` |
| 18 | `InstanceChild` | 0 (NORMAL) | `number` | `nil` | `quad-roblox/src/Handlers/InstanceChild.luau:67` |
| 19 | `Property` | 0 (NORMAL) | `string` | `nil` | `quad-roblox/src/Handlers/Property.luau:274` |
| 20 | `Event` | -1 (NORMAL-1) | `string` | `nil` | `quad-roblox/src/Handlers/Event.luau:63` |
| 21 | `OnChange` | -1 (NORMAL-1) | `number` | `nil` | `quad-roblox/src/Handlers/OnChange.luau:112` |
| 22 | `ObserverDynamicPathGuard` | -1000000 (FALLBACK) | `nil` | `nil` | `quad-base/src/Observer.luau:357` |
| 23 | `EffectDynamicPathGuard` | -1000000 (FALLBACK) | `nil` | `nil` | `quad-base/src/Effect.luau:465` |
| 24 | `PreRefDynamicPathGuard` | -1000000 (FALLBACK) | `nil` | `nil` | `quad-base/src/Ref/init.luau:290` |
| 25 | `PostRefDynamicPathGuard` | -1000000 (FALLBACK) | `nil` | `nil` | `quad-base/src/Ref/init.luau:291` |
| 26 | `TagFallbackHandler` | -1000000 (FALLBACK) | `number` | `nil` | `quad-base/src/Tag.luau:277` |
| 27 | `AttrGroupFallbackHandler` | -1000000 (FALLBACK) | `number` | `nil` | `quad-base/src/Attr/init.luau:261` |
| 28 | `AttrKeyFallbackHandler` | -1000000 (FALLBACK) | `nil` | `nil` | `quad-base/src/Attr/Key.luau:99` |

### 2.2 명명 관례 및 패턴 분석

코드베이스의 28개 핸들러는 소속 모듈과 역할에 따라 매우 엄격하고 일관된 규칙을 따르고 있습니다 [추정]:

1. **소속 계층별 명명 스타일의 분리**:
   - **`quad-roblox` (백엔드 도메인 계층)**:
     - 접미사 `-Handler`를 붙이지 않고 Roblox 엔진의 대상 개념을 고유 명사로 직접 명명합니다 (`Property`, `Event`, `OnChange`, `InstanceChild`, `InstanceShorthand`).
   - **`quad-base` (코어/엔진 계층)**:
     - 23개 핸들러 중 `StoreBind`를 제외한 22개 핸들러가 모두 **명확한 역할 접미사(`-Handler`, `-Guard`, `-Filter`)**를 가집니다.
2. **`quad-base` 접미사 체계 분석**:
   - **`*Handler` (10개)**: 해당 값을 일반적/기본적으로 처리하는 핸들러.
     - 기본 처리기: `NoneHandler`, `NilHandler`, `SlotHandler`
     - 전처리 센티널 처리기: `ProcessedModifierHandler`, `ProcessedPreRefHandler`, `ProcessedPostRefHandler`
     - 잎(Leaf) 종단 바인딩: `ObserverLeafHandler`, `EffectLeafHandler`, `RefLeafHandler` (인스턴스에 종속된 관측/참조 연결)
     - 폴백 기본 구현: `TagFallbackHandler`, `AttrGroupFallbackHandler`, `AttrKeyFallbackHandler` (백엔드가 오버라이드하지 않았을 때의 base 폴백)
   - **`*Guard` (4개)**: FALLBACK 밴드에서 비정상적인 동적 유입(예: State 언랩 후 잘못 도달한 배열 전용 값)을 감지하여 즉시 구체적 진단 에러(`QuadNNNN`)를 내뿜고 차단하는 방어 핸들러 (`*DynamicPathGuard`).
   - **`*Filter` (6개)**: `debugOnly = true`로 동작하며, 배열 전용 객체가 문자열 프로퍼티 키에 실수로 놓였을 때 경고 출력 후 디스패치를 그대로 흘려보내는 진단 필터 (`*StringKeyDebugFilter`).
3. **대상 명명 규칙 (Noun-First)**:
   - 모든 `quad-base` 핸들러는 처리하는 **대상 객체/타입 이름**을 접두어로 사용합니다:
     - `None` → `NoneHandler`
     - `Nil` → `NilHandler`
     - `Slot` → `SlotHandler`
     - `Ref` → `RefLeafHandler`, `RefStringKeyDebugFilter`
     - `Observer` → `ObserverLeafHandler`, `ObserverDynamicPathGuard`, `ObserverStringKeyDebugFilter`
4. **유일한 이탈자: `StoreBind`**:
   - 대상 객체는 `State`인데 이름은 `Store`입니다.
   - 접미사 관례(`Handler`/`Guard`/`Filter`)를 따르지 않고 유일하게 동사적 결합(`Bind`) 형태를 띱니다.
   - `NoneHandler`와 구조적으로 동일하게 "값을 한 겹 벗겨 `index + 1`로 재디스패치"하는 역할을 수행함에도, `None`은 `NoneHandler`인 반면 `State`는 `StoreBind`로 명명되어 불일치가 발생합니다.

---

## 3. [과제 2] v2 공개 어휘 및 "Bind" 단어의 용법 분석

### 3.1 v2의 공식 심볼 및 개념 체계 [실측: `docs/reference/00-index.md`]
- **`Source`**: 값을 직접 변경(`:Set`)할 수 있는 원천 노드.
- **`State`**: `Source`를 포함하여 계산 노드(`:Compute`), 의존성 노드(`:Depend`), 게이트 노드(`:Gate`)를 모두 포괄하는 반응형 노드의 대표 상위 개념. (`isState`는 `isSource`와 `StateBrand`를 포괄).
- **`Store`**: 이름 붙은 `Source`들을 담는 테이블 가방(`q.Store`). 점 접근(`store.hp`) 제공이 목적이며 자체적인 반응형 노드가 아님.
- **`Observer` / `Effect`**: 반응형 그래프 말단에서 변화를 구독하고 실행하는 핸들러.
- **`Slot`**: 동적 자식 인스턴스 장부 및 컬렉션 관리자.
- **`Ref` / `PreRef` / `PostRef`**: 인스턴스 참조 캡처 객체.
- **`Tag` / `Attr` / `Modifier` / `Context` / `Blocker`**: 선언적 메타데이터 및 제어 프리미티브.

### 3.2 v2 공개 문서에서 "Bind"라는 단어의 실제 의미 [실측: `git grep -i "bind" docs/`]
공개 문서 및 API에서 "bind"라는 단어는 오직 두 가지 명확한 맥락에서만 사용됩니다:

1. **생명주기 묶기 (Lifetime Binding)**:
   - `q.Backend.bindLifetime(inst, value)` / `unbindLifetime(value)`
   - 값(Observer, Effect, retractor 등)의 메모리 수명을 호스트 Instance의 수명에 종속시키는 핵심 메커니즘.
   - 사용자에게 노출되는 주요 에러 문구:
     - `Quad0104 bindLifetime: value is already bound to this Instance`
     - `Quad0226 bindLifetime: this Instance is not claimed by quad`
     - `Quad0233 bindLifetime: value is already bound to another Instance`
   - 따라서 사용자에게 quad에서 "Bind"란 **"인스턴스 수명에 리소스를 결속하는 행위"**로 강하게 각인되어 있습니다.
2. **기존 UI 인스턴스 바인딩 (Studio UI / Prefab Binding via `q.Claim`)**:
   - `docs/how-to/07-studio-ui-binding-and-claim/`, `docs/skills/quad-ui-dev/SKILL.md`:
   - Studio에서 이미 제작된 인스턴스 트리에 quad의 반응형 로직을 붙이는 행위를 "Prefab Binding", "Studio UI Binding"으로 설명합니다.

### 3.3 용어 충돌 및 혼선 지점 [추정]
- `StoreBind`의 실제 동작은 "수명 결속(bindLifetime)"도 아니고 "기존 인스턴스 바인딩(Claim)"도 아닙니다.
- 실제 동작은 **"자리에 놓인 State를 구독하여 풀린 실제 값을 다음 우선순위 핸들러(`index + 1`)로 재전달하는 디스패치 위임"**입니다.
- 따라서 `StoreBind`라는 이름은:
  1. 대상이 `Store`가 아니므로 1차 혼선 (오히려 Store를 거부함),
  2. 행위가 `bindLifetime`이나 `Claim`이 아니므로 2차 혼선을 초래합니다.

---

## 4. [과제 3] 핸들러 이름 후보군(6종) 상세 평가

기존 코드베이스 식별자와의 충돌 여부를 먼저 전수 검사했습니다.
- **실행 명령 [실측]**:
  `git grep -E "(StateHandler|StateUnwrapHandler|StateReDispatchHandler|StateDispatchHandler|StateObserverHandler|StateBind|ReactiveHandler)"`
- **실측 결과**: 전 파일에서 **0건 매치** (모든 후보가 기존 식별자와 충돌 없음 확인).

다음은 최소 6개 이상의 후보에 대한 외부자/내부자 시선 비교 평가입니다 [제안 및 분석]:

---

### 후보 1: `StateHandler` [강력 추천]
- **명명 구조**: 대상(`State`) + 접미사(`Handler`)
- **(외부자 시선)**:
  - `q.Dispatch.listHandlers()`를 출력했을 때 직관성이 가장 뛰어납니다. 사용자는 "props 자리에 `State`(또는 `Source`)를 넣으면 `StateHandler`가 받아서 처리하는구나"라고 단번에 이해할 수 있습니다.
  - `Slot`을 넣으면 `SlotHandler`, `None`을 넣으면 `NoneHandler`, `State`를 넣으면 `StateHandler`라는 규칙이 자연스럽게 성립합니다.
- **(내부자 시선)**:
  - `quad-base`의 대표 명명 규칙(`<Target>Handler`)과 100% 일치합니다.
  - `NoneHandler` 역시 `q.None`을 `nil`로 변환하여 `index + 1`로 재디스패치하는 위임 핸들러이지만 `NoneUnwrapHandler`가 아닌 `NoneHandler`로 불립니다. `StateHandler`는 이 선례와 완벽히 동일한 패턴입니다.
  - 등록 모듈이 `quad-base/src/State.luau`이므로 모듈 이름과의 일관성이 극대화됩니다.
- **파일/헬퍼 변경**:
  - quad-base/src/StateHandler.luau(가상 경로)
  - `StateHandler.register`, `StateHandler.assertAcyclicChain`

---

### 후보 2: `StateUnwrapHandler` [차선 추천]
- **명명 구조**: 대상(`State`) + 동작(`Unwrap`) + 접미사(`Handler`)
- **(외부자 시선)**:
  - 핸들러 목록을 볼 때 "State를 한 겹 벗겨서(unwrap) 아래 핸들러로 넘긴다"는 동작의 본질이 이름에 직접 드러납니다.
  - 입문 문서 `docs/getting-started/20-handlers.md` 2절 제목인 *"State가 오면 벗겨서(unwrap) 한 칸 아래로"*의 핵심 키워드와 완벽히 일치하여 문서 학습 효과가 뛰어납니다.
- **(내부자 시선)**:
  - 코드베이스 주석 전반에서 `StoreBind unwraps State`라는 표현이 수십 번 사용되고 있어 내부 어휘와 매우 잘 통합니다.
  - 다만 `NoneHandler`나 `SlotHandler`에 비해 이름에 동작 동사(`Unwrap`)가 포함되어 약간의 비대칭(descriptive)이 존재합니다.
- **파일/헬퍼 변경**:
  - quad-base/src/StateUnwrapHandler.luau(가상 경로)
  - `StateUnwrapHandler.assertAcyclicChain`

---

### 후보 3: `StateBind`
- **명명 구조**: 대상(`State`) + 접미사(`Bind`)
- **(외부자 시선)**:
  - `Store`가 `State`로 바뀌어 대상의 오류는 바로잡혔으나, "State를 어디에 바인드한다는 뜻인가? `bindLifetime`인가?"라는 의문이 여전히 남을 수 있습니다.
- **(내부자 시선)**:
  - 기존 `StoreBind`에서 단어 하나만 바꾼 최소 변경안으로, 기존 설계 문서나 기억과의 괴리감이 가장 적습니다.
  - 그러나 `quad-base`의 모든 핸들러가 `-Handler`, `-Guard`, `-Filter` 접미사를 갖는 관례에서 여전히 혼자 예외(`-Bind`)로 남게 됩니다.
- **파일/헬퍼 변경**:
  - quad-base/src/StateBind.luau(가상 경로)
  - `StateBind.assertAcyclicChain`

---

### 후보 4: `StateReDispatchHandler` (또는 `StateDispatchHandler`)
- **명명 구조**: 대상(`State`) + 내부 메커니즘(`ReDispatch`) + 접미사(`Handler`)
- **(외부자 시선)**:
  - "Re-dispatch가 무슨 뜻이지?" 디스패치 엔진 내부의 `index + 1` 재귀 호출 메커니즘을 모르는 일반 라이브러리 사용자에게는 기술적으로 지나치게 복잡하고 낯선 이름입니다.
- **(내부자 시선)**:
  - `.claude/base/dispatch-core-plan.md`의 ‘recursive re-execution handler’, "re-dispatch at index + 1"이라는 내부 아키텍처 관점에서는 가장 정밀한 표현입니다.
  - 그러나 이름이 다소 길고 외부자 친화적이지 못합니다.
- **파일/헬퍼 변경**:
  - quad-base/src/StateReDispatchHandler.luau(가상 경로)

---

### 후보 5: `StateObserverHandler`
- **명명 구조**: 대상(`State`) + 구현 수단(`Observer`) + 접미사(`Handler`)
- **(외부자 시선)**:
  - `ObserverLeafHandler`와 이름이 매우 비슷하여, "Observer를 처리하는 핸들러인가, State를 처리하는 핸들러인가?"라는 혼란을 일으킵니다.
- **(내부자 시선)**:
  - 핸들러 내부 구현이 `state:Observer(fn)`를 생성하고 `bindLifetime(inst, observer)`를 수행하므로 구현 메커니즘을 정확히 설명합니다.
  - 그러나 핸들러의 명명 원칙(자신이 처리할 입력 값 기준)에 비추어 볼 때 대상(`State`)과 구현(`Observer`)이 혼재되어 적절하지 않습니다.
- **파일/헬퍼 변경**:
  - quad-base/src/StateObserverHandler.luau(가상 경로)

---

### 후보 6: `ReactiveHandler`
- **명명 구조**: 대상 개념(`Reactive`) + 접미사(`Handler`)
- **(외부자 시선)**:
  - "반응형 값을 처리하는 핸들러"로 의미 전달은 무난합니다.
  - 하지만 quad의 공식 공개 심볼 어휘는 `Reactive`가 아니라 `Source`와 `State`입니다.
- **(내부자 시선)**:
  - 코드베이스의 브랜드 검사 함수는 `Brand.isState`이며, quad에는 `isReactive`라는 브랜드나 타입이 존재하지 않습니다. 어휘 불일치가 발생합니다.
- **파일/헬퍼 변경**:
  - quad-base/src/ReactiveHandler.luau(가상 경로)

---

### 후보 7 (보너스): `StateDelegateHandler`
- **명명 구조**: 대상(`State`) + 위임 동작(`Delegate`) + 접미사(`Handler`)
- **(외부자 시선)**:
  - "State의 처리를 위임한다"는 의미이나, "Delegate"라는 단어는 quad 공개 문서 어디에도 등장하지 않는 비표준 어휘입니다.
- **(내부자 시선)**:
  - 주석의 "redelegates with index + 1"과 호응하지만, `quad-base`의 단순 명료한 명명 규칙에 부합하지 않습니다.

---

### 4.1 파일명 및 공개 헬퍼 `assertAcyclicChain` 검토 [추정 및 코드 관측]
현재 `StoreBind.luau`는 핸들러 등록 외에 한 가지 중요한 공개 헬퍼 함수를 외부로 내보냅니다:
- `StoreBind.assertAcyclicChain(first, seed, raise)` (`quad-base/src/StoreBind.luau:63`)
- **사용처 [실측]**:
  - `quad-base/src/StoreBind.luau:100` (자기 자신)
  - `quad-base/src/Slot/Elements.luau:80` (`wrapElement` 내부에서 Slot 원소 순환 방어)
  - `quad-base/src/Slot/List.luau:164` (`reconcile` 내부에서 List 원소 순환 방어)

**내부자 관점의 통찰 [추정]**:
`assertAcyclicChain`은 State 사슬의 순환(`s:Set(s)`, `a:Set(b); b:Set(a)`)을 검사하여 `Quad0070` 에러를 발생시키는 함수로, 에러 제목도 이미 `State:`입니다 (`Subject State: everywhere (round13 Q90)`).
이 함수는 본질적으로 **State의 구조적 특성을 검증하는 유틸리티**입니다.
따라서 만약 파일명이 `StateHandler.luau`로 변경된다면 `StateHandler.assertAcyclicChain`이 되어 현재의 `StoreBind.assertAcyclicChain`보다 훨씬 자연스러워집니다. (장기적으로는 `State.luau`나 전용 유틸 모듈로 이동하는 방안도 검토 가능하나, 현재 상태에서는 `StateHandler`에 위치해도 이름의 어색함이 완전히 해소됩니다.)

---

## 5. [과제 4] "바꾸지 않는다" 선택지 평가 (비용 및 편익 분석)

"바꾸지 않는다" 역시 엔지니어링 관점에서 매우 정당하고 진지하게 검토되어야 할 선택지입니다.

### 5.1 변경 시 소요 비용 실측 분석

이름을 변경(`StoreBind` → `StateHandler` 등)할 경우 수정해야 하는 대상의 규모를 `git grep`으로 실측했습니다:

- **공개 문서 (`docs/`) [실측: 총 26건, 10개 파일]**:
  - `docs/getting-started/20-handlers.md` (4건): 사용자가 직접 보는 핸들러 목록 표 및 본문 설명
  - `docs/quadnomicon/08-extensible-dispatch-engine.md` (6건): 디스패치 체인 및 밴드 구조 심층 설명
  - `docs/how-to/10-debugging-and-troubleshooting.md` (1건): blame 설명
  - `docs/getting-started/11-slot.md` (1건): mock 주석
  - `docs/reference/errors/02-dispatch-bookkeeping.md` (1건): `Quad0070` 소스 파일 위치 표기
  - `docs/skills/quad-ui-dev/SKILL.md` (1건): 스킬 레퍼런스
  - `docs/site/src/content/docs/` 내 위 4개 문서 미러 (12건)
- **설계 및 내부 문서 (`.claude/base/`) [실측: 총 89건, 15개 파일]**:
  - `dispatch-core-plan.md` (43건)
  - `attribute-plan.md` (10건)
  - `slot-plan.md` (7건), `tween-plan.md` (7건), `architecture.md` (5건) 등
  - *주의사항*: `.claude/base/`의 문서들은 과거 설계 결정 및 히스토리를 담고 있으며, 절 제목("Store 바인드는 특수 경우인가...")을 함부로 고치면 다른 문서의 절 링크 참조(`doc-check.py`)가 깨질 위험이 있습니다.
- **소스 코드 및 테스트 (`src/`, `test/`) [실측: 약 60건]**:
  - 소스: `State.luau`, `StoreBind.luau`(파일명 변경), `Slot/Elements.luau`, `Slot/List.luau`, `Dispatch/init.luau` 등
  - 테스트: `spec.storebind.luau`(파일명 변경), `spec.dispatch.luau:966` 문자열 비교 등
- **호환성 영향 (Breaking Change 여부) [실측: `docs/reference/extend/02-dispatch-handler-contract.md:41`]**:
  - 핸들러의 `name` 필드는 공식 계약상 **"진단 전용(동률 경고와 listHandlers 덤프에 쓰임)"**으로 명시되어 있어 디스패치 매칭이나 런타임 로직에 영향을 주지 않습니다.
  - 다만 사용자가 `listHandlers()`의 `name` 문자열을 하드코딩으로 비교하는 단위 테스트나 디버깅 도구를 작성했다면 영향을 받을 수 있습니다.

### 5.2 바꾸지 않고 유지할 때의 비용 (부채) [추정]
1. **사용자 인지 부조화 영속화**:
   - `docs/getting-started/20-handlers.md`를 읽는 모든 신규 사용자가 "State를 넣었는데 왜 이름이 StoreBind인가?", "Store는 왜 에러가 나는가?"라는 의문을 마주하게 되며, 이에 대한 추가 해명이나 주석이 문서에 필요해집니다.
2. **어휘 충돌의 방치**:
   - v2의 공식 `Store` 개념과 디스패치의 `StoreBind` 개념이 영원히 상충된 채 남게 됩니다.
   - 최근 사용자 피드백(*"storebind 라는 이름도 뭔가 애매하네. 실질적으로 state 에 대한걸 다루니까 ... 이것도 문제가 보여"*)에서 지적된 부채가 그대로 유지됩니다.

### 5.3 소결
- 변경 비용은 공개 문서 약 26곳과 소스/테스트 수십 곳의 치환 작업으로, 위험도가 높은 로직 변경이 아니라 **텍스트 리네이밍 작업**에 가깝습니다.
- 반면 얻는 이익은 **v2 코어 어휘(`State`)와 디스패치 엔진 명명의 완전한 일치, 사용자 학습 비용 절감, 용어 혼선 종결**입니다.
- 따라서 작업 비용 대비 얻는 개념적 무결성의 가치가 훨씬 크다고 평가됩니다 [추정].

---

## 6. [과제 5] 결론: 추천안 및 차선안 (제안)

> **안내**: 아래 추천안과 차선안은 분석 결과를 바탕으로 한 **제안**이며, 최종 채택 여부와 명칭 결정은 사용자가 합니다.

### 6.1 추천 (1순위): `StateHandler` (파일명: `StateHandler.luau`)

- **선정 이유**:
  1. **완벽한 대칭성과 관례 준수**:
     `quad-base`의 모든 값 핸들러(`NoneHandler`, `NilHandler`, `SlotHandler`)와 정확히 동일한 `<Target>Handler` 규칙을 따릅니다.
  2. **선례와의 일치 (`NoneHandler`)**:
     `NoneHandler` 역시 값을 언랩하여 `index + 1`로 재디스패치하는 위임형 핸들러이지만 `NoneUnwrapHandler`가 아닌 `NoneHandler`라는 이름을 씁니다. `StateHandler`는 이 선례와 정확히 일치합니다.
  3. **가장 명쾌한 사용자 멘탈 모델**:
     `q.Dispatch.listHandlers()`를 호출했을 때,
     - 배열에 자식을 놓으면 → `SlotHandler`, `InstanceChild`
     - 프로퍼티에 값을 놓으면 → `Property`
     - 반응형 값을 놓으면 → **`StateHandler`**
     - 비우기를 놓으면 → `NoneHandler`, `NilHandler`
     사용자가 라이브러리의 동작 구조를 한눈에 파악할 수 있는 가장 단순하고 강력한 어휘입니다.
  4. **등록 모듈(`State.luau`) 및 브랜드(`isState`)와의 완전한 일치**:
     `H-278` 원칙에 따라 핸들러를 소유하고 등록하는 모듈이 `State.luau`이므로, 모듈과 핸들러 이름의 연결성이 자연스럽습니다.

### 6.2 차선 (2순위): `StateUnwrapHandler` (파일명: `StateUnwrapHandler.luau`)

- **선정 이유**:
  1. **동작 특수성의 명시**:
     일반적인 종단(terminal) 핸들러와 달리, "State를 한 겹 벗겨서(unwrap) 아래 칸으로 넘긴다"는 재귀 위임의 본질을 이름 자체에 드러내고 싶을 때 가장 적합합니다.
  2. **입문 문서와의 호응**:
     `docs/getting-started/20-handlers.md` 2절의 핵심 설명("State가 오면 벗겨서(unwrap) 한 칸 아래로")과 용어가 완벽히 일치하여 교육적 전달력이 높습니다.
  3. **차선으로 둔 이유**:
     `NoneHandler`와의 명명 대칭성이 다소 깨지고, 이름이 4음절로 길어지며, "핸들러 이름은 처리 대상을 나타낸다"는 원칙에 동작 서술어가 추가되기 때문입니다.

---

## 7. 향후 작업 진행 시 참고 체크리스트 (사용자 승인 시)

만약 사용자가 이름 변경(`StateHandler` 등)을 결정할 경우의 작업 범위는 다음과 같습니다 [추정]:

1. **파일 변경**:
   - 옛 `quad-base/src/StoreBind.luau` → quad-base/src/StateHandler.luau(가상 경로) (git mv)
   - `quad-base/test/spec.storebind.luau` → quad-base/test/spec.statehandler.luau(가상 경로) (git mv)
2. **소스 코드 치환**:
   - `quad-base/src/State.luau`: require 경로 및 `StateHandler.register` 호출
   - quad-base/src/StateHandler.luau(가상 경로): 내부 테이블명, `name = "StateHandler"`, 함수명
   - `quad-base/src/Slot/Elements.luau`, `Slot/List.luau`: `StateHandler.assertAcyclicChain` require
   - `quad-base/test/spec.dispatch.luau:966`: `"StoreBind"` → `"StateHandler"`
3. **문서 동기화**:
   - `docs/getting-started/20-handlers.md` (및 미러): `StoreBind` → `StateHandler`
   - `docs/quadnomicon/08-extensible-dispatch-engine.md` (및 미러)
   - `docs/reference/errors/02-dispatch-bookkeeping.md`: Quad0070 출처 경로 갱신
   - `docs/skills/quad-ui-dev/SKILL.md`
4. **검증**:
   - `./scripts/test.sh` 실행 및 exit code 0 확인.
