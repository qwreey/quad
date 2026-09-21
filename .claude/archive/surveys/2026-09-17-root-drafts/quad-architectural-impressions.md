# Quad v2 아키텍처 탐색 및 심층 분석 보고서: 설계의 정밀함과 문서 확장 제언

> **문서 목적**: Quad 프레임워크 전반(코어 코드베이스, The Quadnomicon 11권 전권, Getting Started 및 How-To 문서군)을 깊이 있게 탐색한 뒤, 아키텍처적 인상, 타 생태계(웹 및 Roblox 타 라이브러리)와의 비교, 그리고 향후 문서화 및 기술 브랜딩 관점에서 확장 가능한 아이디어를 정리합니다.
> **작성 일자**: 2026-09-17
> **대상 저장소**: [quad](file:///code/Projects/quad/README.md) (`qwreey/quad_base`, `qwreey/quad_roblox`, `qwreey/quad_types`, `qwreey/quad_error`)

---

## 1. 아키텍처 총평: "단단한 실용주의(Hardened Pragmatism)"

Quad v2 코드베이스와 기술 문서를 탐색하면서 가장 강하게 다가오는 인상은 **"타협 없는 엔지니어링 엄격함과 지독할 정도로 정직한 실용주의"**입니다.

많은 프레임워크가 개발 편의성이라는 명목으로 "마법(Magic)"을 도입합니다. 전역 스택을 통한 암묵적 의존성 추적, 가상 DOM을 통한 무지성 렌더링, 블랙박스 가비지 컬렉션 의존 등이 대표적입니다. 하지만 Luau와 Roblox 엔진이라는 특수한 런타임(코루틴 yield, C++ userdata 신원 변동, 네이티브 계층과의 비동기 상호작용, Ephemeron 테이블 부재) 위에서는 이러한 마법들이 고스란히 런타임 글리치, 메모리 누수, 그리고 원인 불명의 크래시로 돌아옵니다.

Quad는 마법을 부리는 대신:
- **모든 의존성을 코드 표면에 정적으로 드러내고**,
- **인스턴스 신원과 메모리 수명을 결정론적 엔진 시그널로 붙잡으며**,
- **32-bit 비트 연산 기반의 경량 랩어라운드 리비전으로 다이아몬드 글리치를 완벽히 접어내는**

선택을 내렸습니다. 설계 선택마다 **"산 것(What we bought)"과 "치른 대가(Paid cost)"를 명시적으로 대조 문서화**하고 있는 태도는 오픈소스 라이브러리 중에서도 보기 드문 수준의 완성도와 설계 정직성을 보여줍니다.

---

## 2. The Quadnomicon(11권)으로 본 핵심 아키텍처 혁신 심층 분석

Quad의 기술 명세서인 **The Quadnomicon**은 각 권마다 독립적인 컴퓨터 과학적 문제와 Luau/Roblox의 런타임 한계를 정면으로 돌파한 기록을 담고 있습니다.

### ① 32-bit Wrapping Revision과 EpochMap (Vol. 1)
* **문제 배경**: 반응형 그래프에서 가장 고전적인 문제는 다이아몬드 의존성(`A -> B, C -> D`)입니다. Vide처럼 순수 Eager Push를 쓰면 `D`가 중복 실행되고 일시적 불일치(Glitch)가 발생하며, Fusion처럼 eager 집합을 생성순으로 정렬하면 애니메이션이나 외부 클럭이 반응 그래프를 복잡하게 오염시킵니다.
* **Quad의 해법**: 
  - 리비전을 `self.Revision = bit32.bnot(-self.Revision)`으로 갱신합니다. Luau의 FASTCALL 빌트인 비트 부정/반전 단 한 번으로 랩어라운드 감산 카운터를 돌립니다 (`2^53` float 포화 방지 및 극도의 속도).
  - Push 단계는 **신호 전파(Push-Invalidate)**만 수행하여 유저 함수를 단 하나도 실행하지 않고 `_valueEpochMap`만 갱신합니다.
  - Pull 단계는 소비자가 `:Get()`을 부르는 시점에 노드 캐시와 `cacheCurrCount == cacheTargetCount`를 비교하여 단 한 번만 재계산합니다.
* **최신 업계 표준과의 일치**: 2024~2026년 JavaScript 표준화 기구의 **TC39 Signals Proposal**(`Signal.State`, `Signal.Computed`), **Vue 3.4**의 Dep/Link 버전 카운터 시스템, **Angular Signals**가 채택한 표준 알고리즘과 정확히 동일한 Push-Pull 버저닝 아키텍처입니다.

### ② DOMless 환경에서의 복수 형제 반환: 부분합 가상 슬롯 트리 (Vol. 9 & Vol. 2)
* **문제 배경**: React나 웹 프레임워크는 가상 DOM이 존재하므로 `<Fragment>`나 `<>`를 통해 래퍼 DOM 노드(`<div>`) 없이도 컴포넌트가 여러 형제 노드를 반환할 수 있습니다. 하지만 Roblox에는 VDOM이 없으며 오직 C++ 물리 계층의 `Instance.Parent` 트리만 존재합니다. 따라서 전통적으로 컴포넌트가 형제 여럿을 반환하려면 반드시 더미 래퍼 `Frame`을 두어야 했고, 이는 `UIListLayout` 등의 레이아웃 시스템을 완전히 파괴하는 주범이었습니다.
* **Quad의 해법**:
  - `Slot`([`Slot/init.luau`](file:///code/Projects/quad/quad-base/src/Slot/init.luau))을 Roblox 데이터 모델에 존재하지 않는 **순수 부기(Bookkeeping) 노드**로 정의했습니다.
  - 물리적으로는 자식들이 부모 `Frame`의 직접 자식으로 붙되, 논리적으로는 `Slot`이 자식들의 길이(Length)와 상대 오프셋(Offset)을 부분합(Prefix-sum) 트리([`Slot/Tree.luau`](file:///code/Projects/quad/quad-base/src/Slot/Tree.luau))로 관리합니다.
  - CRUD가 일어날 때마다 상류 슬롯으로 변경분을 전파하며, `ctx.Index`와 `ctx.Offset`을 반응형 State로 쥐어주어 레이아웃 순서를 제어합니다.
* **관전 포인트**: DOMless UI 렌더러가 가상 DOM의 최대 장점 중 하나인 "Fragment"를 엔진 객체 오염 없이 순수 수학적 부기만으로 달성한 독창적인 돌파구입니다.

### ③ Luau 메모리 토폴로지와 Ephemeron 부재의 극복: 앵커 섬과 수명 위임 (Vol. 3 & Vol. 7)
* **문제 배경**:
  - Luau는 Lua 5.2+의 **에페메론 테이블(Ephemeron Tables)을 지원하지 않습니다.** 약참조 키 테이블(`{ __mode = "k" }`)에서 값 `V`가 키 `K`를 업밸류로 캡처하고 있으면 순환 강참조가 되어 영구 메모리 누수가 발생합니다.
  - 게다가 Roblox의 `Instance`는 C++ 엔진 객체를 가리키는 Lua userdata 포인터라, Lua 측 참조가 끊기면 엔진 객체는 살아있어도 userdata가 GC되어 추후 다시 가져올 때 **서로 다른 userdata 포인터**가 생깁니다. 이 경우 `inst`를 키로 쓰는 weak table 바인딩 장부가 조용히 미아가 됩니다.
* **Quad의 해법**:
  - `nativeClaim(inst)`([`LifetimeHandle.luau`](file:///code/Projects/quad/quad-roblox/src/LifetimeHandle.luau))에서 절대 발화하지 않는 `inst:GetPropertyChangedSignal("ClassName")` 시그널 콜백을 통해 클로저가 `gchold`와 `inst`를 상호 캡처하도록 하여 **userdata 신원을 영구 고정**하고 **앵커 섬(Anchor Island)**을 형성합니다.
  - 디스패치 체인 리스트 등 내부 부기는 전부 약참조(`chains = Relate()`)로 두고, 실제 강참조는 `bindLifetime(inst, list)`를 통해 인스턴스의 `gchold` 섬 하나에만 겁니다.
  - 유저에게 수동 `Scope` 배열을 들고 다니게 하지 않고, 인스턴스의 엔진 커넥션 `.Connected`로 생존을 판정하며, 회수는 `inst:Destroy()`라는 단 하나의 명확한 절단면과 Luau GC에 맡깁니다.
  - **Teardown 철학**: 파괴 시 모든 바인딩의 `retractor`를 순회 실행하지 않습니다. Destroy로 `gchold` 섬이 무너지면 하위 객체는 도달 불가능해지며, 이는 "철거가 아니라 메모리 해제"입니다.

### ④ 불변성 우회와 공변 마커: Luau New Solver 길들이기 (Vol. 4)
* **문제 배경**: Luau의 차세대 타입 솔버(Solver V2)에서 `State<T>`는 `Get(): T`(출력)와 `Set(T)`(입력)을 모두 가지므로 타입 매개변수 `T`에 대해 **불변(Invariant)**으로 판정됩니다. 이로 인해 `State<number>`가 `State<number | UDim>` 자리에 대입되지 못하고, 31개 GUI 클래스의 Declaration 유니언 타입이 기하급수적으로 폭발하여 `Code is too complex to typecheck` 에러와 함께 `LuauTarjanChildLimit` 한도를 초과했습니다.
* **Quad의 해법**:
  - 입력 자리가 요구하는 것은 런타임 메소드가 아니라 "이 노드가 어떤 T를 방출하는가에 대한 공변 정보"뿐이라는 점에 착안했습니다.
  - `quad-types`에 **공변 마커**(`export type StateMarker<T> = { read __quadState: true, read __quadStateValue: T }`)를 신설했습니다.
  - `read` 키워드로 읽기 전용 필드를 선언하여 솔버가 `T`를 **공변(Covariant)**으로 평가하게 만들고, 폭 서브타이핑(Width Subtyping)을 통해 메소드가 다 붙은 전체형 `State<T>`가 캐스트 없이 마커 자리에 그대로 통과되도록 했습니다. 런타임에서는 `__quadStateValue`가 순수 팬텀 타입이라 메모리 오버헤드가 제로입니다.

### ⑤ 비파괴 언마운트와 소유권 공리: 포탈이 프리미티브 없이 나오는 이유 (Vol. 5)
* **문제 배경**: 일반적인 선언형 프레임워크에서는 컴포넌트가 트리에서 언마운트되면 해당 서브트리의 상태와 DOM/인스턴스가 즉시 파괴됩니다. 따라서 서브트리를 유지한 채 다른 곳으로 옮기려면 React의 `<Portal>` 같은 별도의 특수 프리미티브가 필요했습니다.
* **Quad의 해법**:
  - **소유권 공리**: "자원을 만든 쪽이 그 수명을 정한다. 마운트 자리는 가시성만 정한다."
  - 자식 숫자 키의 슬롯 교체 시 파괴(`destroy`)가 아닌 언마운트(`rawUnmount`)를 수행하여 인스턴스 트리와 이벤트 연결을 살려둡니다.
  - 따라서 `a:Set(nil)`로 가방 창에서 떼어내고 `b:Set(itemView)`로 핫바 창에 붙이면, 인스턴스 재생성이나 상태 유실 없이 **드래그 앤 드롭 형태의 포탈이 추가 프리미티브 전혀 없이 공짜로 성립**합니다.

### ⑥ 단일 인자 생존 게이트와 물리 수명-반응성 분리 (Vol. 6)
* **문제 배경**: UI 인스턴스는 Lua 메모리 수명(GC)과 Roblox 엔진 수명(`Destroy()`)이라는 두 가지 수명을 갖습니다. 파괴된 인스턴스를 반응형 노드가 계속 참조하여 사후 발화가 죽은 객체를 건드리는 것을 막아야 합니다.
* **Quad의 해법**:
  - 옛 설계의 `canExecute(inst, value)` 두 인자 시그니처가 State 전파 루프(여기엔 `inst`가 없음)에서 호출 불가능하다는 구조적 결함을 발견하고, `bindLifetime` 시점에 `inst`의 엔진 커넥션(`gcconn`) 참조를 `value` 쪽 릴레이션에 복사하여 **`canExecute(value)` 단일 인자 게이트**로 일원화했습니다.
  - Roblox 엔진의 `.Connected` 속성 전환은 `Destroy`와 **동기(Synchronous)**이므로, 파괴 직후 지연 배달될 수 있는 시그널과 무관하게 모든 사후 발화가 즉시 차단됩니다.

### ⑦ 개방형 디스패치 엔진과 대칭적 Retractor (Vol. 8)
* **문제 배경**: 대다수 UI 라이브러리는 `if type(k) == "number" ... elseif isState(v) ...` 식의 모놀리식 중앙 디스패처를 둡니다. 이 경우 라이브러리 코어를 수정하지 않고서는 새 값 타입(Spring, Tween, Custom State)이나 커스텀 키를 확장할 수 없습니다.
* **Quad의 해법**:
  - 모든 props 바인딩을 `isHandlable`, `priority`, `process`를 가진 `Handler` 레코드로 추상화했습니다 ([`Dispatch/Handler.luau`](file:///code/Projects/quad/quad-base/src/Dispatch/Handler.luau)).
  - `process`는 반드시 해당 바인딩을 원상 복구하는 **대칭적 retractor 클로저**를 반환해야 하며, 이를 통해 값 스왑과 컴포넌트 철거가 동일한 역순 파이프라인으로 안전하게 롤백됩니다.
  - `Property`, `Event`, `Slot`, `Modifier`, 심지어 반응형 상태 바인딩인 `StoreBind`조차도 이 동일한 우선순위 레지스트리에 등록된 핸들러일 뿐입니다. 마이크로커널형 구조로 코어를 수정하지 않고 서드파티가 임의의 우선순위로 끼어들 수 있습니다.

### ⑧ 다중 백엔드 추상 기계 (Vol. 10)
* **문제 배경**: 선언형 UI 코어에 특정 엔진 API(`game`, `Instance`, `task`)가 얽혀 있으면 vanilla Luau CLI 환경에서 헤드리스 테스트를 돌리거나 타 플랫폼으로 확장하는 것이 불가능해집니다.
* **Quad의 해법**:
  - `quad-base`는 엔진 전역을 단 하나도 참조하지 않는 순수 추상 기계(Abstract Machine)입니다.
  - 물리 트리 조작(`nativeInsert`, `nativeExtract` 등), 생명주기 판정, Attr/Tag 조작, 시간 op를 런타임에 주입받으며, `Quad:UseProvider(QuadRoblox)` 한 줄로 백엔드가 부착됩니다. 공식 Roblox 백엔드조차도 이 공개 진입점을 통해 들어온 첫 번째 손님일 뿐입니다.

### ⑨ 포맷 헬퍼 없는 정적 Grep 가능 에러와 Surface Blame (Vol. 11)
* **문제 배경**: 프레임워크 내부에서 `formatError(subject, reason)` 같은 헬퍼를 사용하면, 프로덕션 환경이나 유저 로그에 찍힌 에러 문자열이 여러 조각으로 파편화되어 소스 코드에서 해당 지점을 `grep`으로 바로 찾을 수 없게 됩니다. 또한 깊은 추상화 계층 때문에 에러 스택트레이스가 유저 코드가 아닌 라이브러리 내부 파일만을 지목합니다.
* **Quad의 해법**:
  - 에러 메시지 리터럴을 던지는 코드 라인에 문자열 템플릿 형태로 온전히 보존하여 `grep` 가능한 고정 접두사를 유지합니다.
  - 공개 표면 함수들에 `setFuncLevel(SURFACE, fn)`로 계층 태그를 부여하고, 에러 발생 시 런타임 스택을 검사하여 라이브러리 내부 프레임을 건너뛰고 **실제 유저의 호출 라인(Surface)**을 지목(Blame)합니다.

---

## 3. 타 프레임워크 생태계와의 다각도 비교 매트릭스

| 분류 축 | React / react-lua | Vide (Roblox) | Fusion (Roblox) | SolidJS / TC39 Signals | **Quad v2** |
|---|---|---|---|---|---|
| **반응성 패러다임** | Coarse-grained (컴포넌트 리렌더) | Fine-grained (시그널 기반) | Reactive Graph (State/Computed) | Fine-grained (시그널 기반) | **Fine-grained (Push-Pull 정밀 반응형)** |
| **의존성 선언** | Hook 의존성 배열 (`useMemo`) | 암묵적 (전역 스코프 스택) | 명시적 (`use(state)`) | 암묵적 (전역 스코프 스택) | **명시적 (`:Compute(fn, ...deps)`)** |
| **전파 알고리즘** | 상태 변경 -> 트리 스케줄링 | 순수 Eager Push (동기 깊이우선) | Invalidate + Eager 정렬 실행 | Push-Pull 버전 카운터 하이브리드 | **Push-Invalidate, Pull-Recompute (32-bit Revision & EpochMap)** |
| **다이아몬드 글리치** | VDOM 배치 렌더로 회피 | 미해결 (중복 계산 발생) | 생성순 정렬로 글리치 방어 | 토폴로지 플래그로 방어 | **구조적 원천 차단 (읽을 때 1회 계산)** |
| **정상 상태 GC 할당** | 렌더마다 VDOM 객체 할당 | 재실행마다 링크 노드 재할당 | 재계산 시 그래프 재연결 | 재실행마다 추적 엣지 재할당 | **Zero-Allocation (정적 엣지 고정, 할당 없음)** |
| **렌더링 타깃** | 가상 DOM -> Reconciliation | Roblox Instance 직접 생성 | Roblox Instance 직접 생성 | 브라우저 DOM 직접 생성 | **부착식 추상 기계 (Roblox, Mock 등 교체 가능)** |
| **복수 형제 반환** | `<Fragment>` (VDOM diff) | 래퍼 Frame 또는 단일 루트 | 래퍼 Frame 또는 단일 루트 | `<></>` (DOM Fragment) | **`Slot` 가상 부기 부분합 트리 (No wrapper Frame)** |
| **정리(Teardown) 모델** | Effect 클린업 함수 | 수동 소유권 트리 (`destroy`) | `Scope` 테이블 명시적 전달 | `createRoot` / `onCleanup` | **엔진 커넥션 `.Connected` + Luau GC** |
| **포탈 (서브트리 이동)** | `<Portal>` 전용 프리미티브 | 재조정 시 파괴/재생성 | 재조정 시 파괴/재생성 | 포탈 컴포넌트 필요 | **비파괴 언마운트로 공짜 성립 (소유권 공리)** |
| **키/속성 확장성** | 컴파일러/고정 props 어휘 | `action()` (값 타입 확장 불가) | `SpecialKey` (4단계 고정) | Directives / JSX 커스텀 속성 | **열린 우선순위 핸들러 레지스트리 (`Dispatch`)** |

---

## 4. 문서화(Documentation) 관찰 및 확장 제안

현재 `docs/`의 완성도는 일반적인 오픈소스의 수준을 훌쩍 뛰어넘습니다. 체계적인 20단계의 Getting Started, 9개의 How-To, 그리고 11권에 달하는 The Quadnomicon은 대단히 훌륭한 자산입니다. 

여기서 외부 사용자(특히 웹 프론트엔드 출신 엔지니어나 기존 Fusion/Vide 유저)의 적응을 돕고 라이브러리의 매력을 극대화하기 위해 다음과 같은 문서적 확장을 고려해볼 수 있습니다.

---

### 제안 1. "Mental Model Shift (사고방식의 전환)" 시각화 가이드 추가
* **배경**: React나 일반적인 UI 프레임워크에 익숙한 개발자는 머릿속에 `State -> Component(props) -> VDOM -> DOM/Instance`라는 멘탈 모델을 가지고 있습니다.
* **제언**: Quad의 멘탈 모델인 **"파이프 & 프로퍼티 직결"**을 대조 다이어그램으로 명확히 보여주는 짧은 인트로 섹션을 `docs/overview/` 또는 `docs/getting-started/02-first-screen.md` 앞단에 배치하는 것을 추천합니다.
* **개념 다이어그램 예시**:
  ```
  [전통적 VDOM 렌더러]
  상태 변경 ──> 컴포넌트 전체 재실행 ──> VDOM 트리 생성 ──> Diffing ──> 인스턴스 갱신
  
  [Quad DOMless 정밀 렌더러]
  상태 변경 ──> [무효화 신호] ──> 대상 프로퍼티 바인더(StoreBind) ──> 인스턴스 단일 속성 즉시 대입
  (컴포넌트는 이미 태어나서 사라진 1회용 셋업 함수)
  ```

---

### 제안 2. 다른 언어/프레임워크 출신을 위한 로제타 스톤 (Rosetta Stone)
* **배경**: 현재 `docs/overview/01-why-quad.md`는 Fusion, Vide, react-lua를 깊이 있게 비교하고 있습니다. 하지만 최근 Roblox 개발 생태계에는 React, Svelte, SolidJS 등 웹 프론트엔드 배경을 가진 개발자들의 유입이 많습니다.
* **제언**: 용어와 관례를 1:1로 매핑해주는 **"빠른 치트시트(Rosetta Stone)"** 단독 문서(예: `docs/overview/rosetta-stone.md` 또는 how-to)를 제공하면 온보딩 속도가 극대화될 수 있습니다:

| 개념 / 목적 | React / Web | SolidJS | Fusion | **Quad v2** |
|---|---|---|---|---|
| **기본 상태** | `useState(0)` | `createSignal(0)` | `Value(0)` | `q.Source(0)` |
| **파생 계산** | `useMemo(() => ...)` | `createMemo(() => ...)` | `Computed(() => ...)` | `state:Compute(fn, ...deps)` |
| **부수 효과** | `useEffect(() => ...)` | `createEffect(() => ...)` | `Observer(state):onChange(...)` | `q.Effect(fn)` / `state:Observer(fn)` |
| **복수 형제 렌더링** | `<> <A/> <B/> </>` | `<> <A/> <B/> </>` | 없음 (Frame 필수) | `q.Slot { A, B }` |
| **서브트리 이동/포탈** | `createPortal(...)` | `Portal` | 없음 | `slotState:Set(...)` (비파괴 언마운트) |
| **재사용 스타일** | CSS Classes / Tailwind | Class / Style object | 없음 | `D.Modifier.ClassName { ... }` |
| **정리 / 클린업** | `useEffect(() => cleanup)` | `onCleanup(() => ...)` | `Scope:doCleanup()` | 인스턴스 `Destroy()` 시 자동 해제 |

---

### 제안 3. "왜 명시적 의존성인가?"에 대한 기술적 변호 챕터 보강
* **배경**: SolidJS나 Svelte 5 등 현대 웹 생태계에서는 암묵적 의존성 추적(시그널 함수를 호출만 하면 자동으로 잡히는 것)이 "트렌드"로 여겨집니다. 따라서 웹에서 온 개발자나 Vide 사용자는 `:Compute(fn, ...deps)`처럼 의존성을 뒤에 적어야 하는 것을 처음 볼 때 "왜 번거롭게 뒤에 또 적어야 하지?"라는 의문을 품기 쉽습니다.
* **제언**: 
  - `docs/overview/01-why-quad.md`와 `docs/getting-started/03-flowing-values.md`에 이미 훌륭한 설명이 있지만, **"Luau 코루틴(Yield) 환경에서 전역 스코프 스택이 겪는 치명적 붕괴"**와 **"재평가마다 링크 객체를 만들지 않는 Zero-Allocation Steady State의 게임 엔진 최적화 이점"**을 강조하는 콜아웃을 더 전면에 배치하면, 이것이 "타협이 아니라 고도의 엔지니어링 선택"임을 유저가 즉시 납득할 수 있습니다.

---

### 제안 4. 디스패치 핸들러 확장 쇼케이스 (How-To 레시피)
* **배경**: Quad의 가장 독보적인 장점 중 하나는 `quad.Dispatch.addHandler`를 통해 코어를 전혀 건드리지 않고도 서드파티가 새로운 값 타입이나 특수 키를 정의할 수 있다는 점입니다.
* **제언**: `docs/how-to/`에 다음과 같은 실전 커스텀 확장 레시피를 1~2개 추가하면 프레임워크의 확장 가능성이 생생하게 체감될 것입니다:
  1. **Spring 애니메이션 값 타입 만들기**: 물리 스프링 시뮬레이터를 래핑하여 `D.Frame { Position = MySpring(targetPos) }`처럼 프로퍼티 자리에 바로 꽂을 수 있는 핸들러 구현.
  2. **유한 상태 머신(FSM) / 제스처 핸들러 만들기**: 버튼 드래그, 롱프레스 등을 감지하는 커스텀 이벤트 핸들러 구현.

---

## 5. 결론: 완성도 높은 아키텍처에 대한 감상

Quad는 단순한 "Roblox UI 라이브러리 하나 더"가 아닙니다. 
- 가상 DOM의 오버헤드를 거부하면서도 가상 트리의 최대 이점인 Fragment(`Slot`)를 수학적 부분합으로 재현했고,
- 암묵적 추적의 함정을 피하면서도 현대 반응형 이론의 정점인 Push-Pull 글리치 프리 전파(TC39 Signals와 동일 계보)를 달성했으며,
- 프레임워크 코어를 엔진과 완전히 분리된 순수 추상 기계로 완성해냈습니다.

이 프로젝트는 Fine-grained reactivity의 본질을 가장 타협 없이 구현한 사례 중 하나이며, 적절한 문서적 브릿지만 더해진다면 Luau 생태계를 넘어 선언형 렌더러 아키텍처 연구에 있어서도 훌륭한 레퍼런스가 될 자격을 갖추고 있습니다.
