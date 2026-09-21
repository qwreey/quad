---
title: "웹에서 오셨다면 — 개념 대응표와 반응성 한눈에"
description: "React·Vue·Solid·Svelte 같은 웹 프레임워크의 개념을 quad의 대응 개념에 빗대어 빠르게 잡고, 정확히 무엇이 다른지 짧게 정리합니다"
---
> **대상 독자**: React·Vue·Solid·Svelte 등 웹 프론트엔드 프레임워크를 써봤고, quad의 개념을 그 경험에 빗대어 빠르게 잡고 싶은 엔지니어.
> **하는 일**: 웹 개념 → quad 대응 한 줄 대응표, quad의 반응성이 정확히 어떤 갈래인지, 없는 것과 다른 관례를 짧게 정리하고 각각 더 깊은 문서로 보냅니다.
> **안 하는 일**: 내부 구현 설명이 아닙니다 — 메커니즘 자체는 [The Quadnomicon](/quadnomicon/01-revision-and-epochmap/)이 다룹니다. 사용법 튜토리얼도 아닙니다 — 손으로 먼저 만들어 보실 분은 [시작하기](/getting-started/00-installation/)로 가시면 됩니다. 이 문서는 랜딩 페이지의 "React를 쓰다 오셨다면" 문답 둘을 중복하지 않고 그 옆에 놓이는 더 넓은 지도입니다.

---

## 1. 한눈에 — 웹 개념과 quad 대응

| 웹에서 | quad에서 | 더 보기 |
|---|---|---|
| Signals(`useState`, `ref()`, `createSignal`) | `q.Source` — 값을 담는 원자 | [시작하기 03](/getting-started/03-flowing-values/) · [레퍼런스 Source](/reference/core/02-source/) |
| `createMemo`/`useMemo`(다이아몬드에서도 한 번만 계산) | `:Compute(fn, ...deps)` — 읽을 때(pull) 계산되는 파생 값, 의존성은 인자로 명시 | [시작하기 03](/getting-started/03-flowing-values/) · [레퍼런스 State](/reference/core/03-state/) |
| `createEffect`/`useEffect` | `q.Effect(fn, ...deps)`(+ 단일 State엔 `state:Observer(fn)`) | [시작하기 08](/getting-started/08-observer-effect/) · [레퍼런스 Observer·Effect](/reference/core/05-observer-effect/) |
| JSX가 VNode를 만들고 나중에 실제 DOM과 diff | `D.Frame { … }`을 부르는 그 자리에서 진짜 `Instance`가 만들어짐 — 비교할 이전 트리도, diff 단계도 없음 | [왜 Quad인가](/overview/01-why-quad/) · [시작하기 02](/getting-started/02-first-screen/) |
| key 붙은 리스트 재조정(`.map(item => <Card key=… />)`) | `slot:List(data, updateFn, keyFn)` — 키가 같은 항목은 재사용, 사라진 키만 파괴 | [시작하기 14](/getting-started/14-lists/) · [레퍼런스 Slot](/reference/core/06-slot/) |
| `ref`/`useRef`/콜백 ref | `Ref`/`PreRef`/`PostRef` — 발화 시점이 셋으로 갈림(자식·프로퍼티 처리 전/그 순서대로/전부 끝난 뒤) | [시작하기 07](/getting-started/07-ref/) · [레퍼런스 Ref](/reference/core/07-ref/) |
| Context API(`createContext`/`useContext`, 트리를 거슬러 조회) | `q.Context`/`Provider` — 명시적으로 아래로 넘기는 가방, 위로 조회하지 않음 | [시작하기 15](/getting-started/15-context/) · [레퍼런스 Context](/reference/sugar/01-context/) |
| 양방향 바인딩(`v-model`, 제어 컴포넌트) | `Text = src`(in 한 줄) + `q.Out("Text", src)`(out 한 줄) — 각각 따로 적는 명시적 두 줄 | [시작하기 06](/getting-started/06-flowing-back/) · [레퍼런스 OnChange](/reference/roblox/05-onchange/) |
| `onChange` 핸들러 | `q.OnChange(name, fn)` | [레퍼런스 OnChange](/reference/roblox/05-onchange/) |
| 에러 바운더리(`<ErrorBoundary>`, `error.tsx`) | `q.Fallback(base, onError)` / `q.Traceback(base, onError)` | [레퍼런스 Fallback·Traceback](/reference/sugar/05-fallback-traceback/) |
| debounce/throttle 훅 | `state:Apply(q.Debounce{ Time = … })` / `q.Throttle{ Time = … }` | [레퍼런스 Debounce·Throttle](/reference/sugar/03-debounce-throttle/) |
| 배치/트랜잭션(`batch()`, `unstable_batchedUpdates`) | `q.Blocker` — 여러 값을 바꾸는 동안 통지를 모았다가 한 번에 | [시작하기 18](/getting-started/18-blocker/) · [레퍼런스 Blocker](/reference/sugar/06-blocker/) |
| 포탈(`createPortal`) | 별도 프리미티브 없음 — 비파괴 언마운트 덕에 `Slot`이 들고 있던 원소를 다른 자리로 그냥 옮기면 됨 | [Quadnomicon Vol. 5](/quadnomicon/05-non-destructive-portal-and-ownership/) |
| Suspense/`Resource`(비동기 로딩 경계) | 없음 | 아래 3절 |
| Exit animation(`AnimatePresence`류 — 사라지는 애니메이션이 끝날 때까지 언마운트를 미룸) | 없음(백로그 아이디어) | 아래 3절 |

숫자 키와 문자 키가 나뉘는 이유까지 포함해 위 표의 각 줄이 실제로 어떻게 생겼는지는 [왜 Quad인가](/overview/01-why-quad/)의 예제 하나로 충분합니다.

---

## 2. 반응성은 "fine-grained"입니다

quad는 SolidJS나 TC39 Signals 제안과 같은 계열입니다 — 컴포넌트 함수가 다시 실행되는 일이 없고, `Source`/`State`/`Observer`는 컴포넌트 단위가 아니라 각자 독립된 노드로 존재하며, 값이 바뀌면 그 값을 구독한 프로퍼티 바인딩 하나에만 도달합니다. 가상 DOM을 만들고 이전 트리와 비교하는 단계 자체가 없습니다.

전파는 두 갈래입니다. `:Compute` 파이프로는 `Set`이 **무효화 신호만** 내려보내고, 실제 계산은 누군가 `:Get()`을 부르는 시점에 일어납니다 — 프로퍼티에 물린 파이프라면 통지를 받은 바인딩이 그 자리에서 읽으므로, 결과적으로 화면에 값이 쓰이는 순간입니다. `Observer`와 `Effect`는 반대로 **push**입니다 — `Set`과 같은 콜스택 안에서 동기적으로 돕니다. `A`가 `B`와 `C` 양쪽 경로로 `D`에 영향을 주는 다이아몬드 모양에서도 `D`는 딱 한 번만 계산됩니다 — 신호는 두 번 와도 계산은 읽을 때 한 번이기 때문입니다. 메커니즘 자체는 [Quadnomicon Vol. 1](/quadnomicon/01-revision-and-epochmap/)이 다룹니다.

다만 웹의 Signals와 한 군데는 갈립니다 — **의존성을 암묵적으로 추적하지 않습니다.** 콜백 안에서 어떤 State를 그냥 읽는 것만으로는 의존성이 되지 않고, `:Compute(fn, ...deps)`나 `:Depend(...)`에 명시적으로 적은 것만 구독됩니다. Roblox/Luau 환경은 코루틴과 태스크 스케줄러가 흔해서, 계산 도중 yield가 일어나면 "지금 뭘 추적 중인가"를 기억하는 전역 상태가 오염되기 쉽습니다 — quad는 그 전역 상태 자체를 두지 않는 쪽을 택했고, 대신 의존성을 호출부 한 줄에서 정적으로 읽을 수 있게 됩니다.

그리고 **누가 읽지 않으면 계산도 일어나지 않습니다.** `:Compute`로 만든 파생 값을 아무도 `:Get()`하지 않으면(직접적으로든, 프로퍼티에 물려서든) 그 함수는 한 번도 실행되지 않습니다 — 이 pull 트리거 지점(정확히 언제 값을 "읽는가")이 프레임워크마다 조금씩 다른데, quad는 화면 프로퍼티에 실제로 값이 쓰이는 순간이 그 자리입니다. 자세한 내용은 [19. 값은 언제 흐르나](/getting-started/19-laziness/)에 정리돼 있습니다.

---

## 3. 없는 것과 다른 것

**없는 것**

- **컴포넌트 재실행 모델이 없습니다.** 컴포넌트는 한 번만 실행되는 셋업 함수라 "이번 렌더에서 뭐가 바뀌었나"를 따질 일 자체가 없습니다.
- **Hook 규칙이 없습니다.** 같은 이유로 최상단·조건문 밖·같은 순서 같은 제약이 없습니다 — [시작하기 13](/getting-started/13-functions/).
- **가상 DOM diffing이 없습니다.** 1절 표대로 실제 Instance가 그 자리에서 만들어집니다.
- **자동 양방향 바인딩이 없습니다.** `v-model` 같은 마법은 일부러 두지 않았습니다 — `Text = src` + `q.Out(...)` 두 줄을 항상 명시적으로 적습니다.
- **Suspense/`Resource`류가 없습니다.** 비동기 로딩을 선언적으로 막아주는 경계가 없고, 로딩 상태는 직접 `Source<boolean>`으로 다룹니다.
- **Exit animation(사라지는 애니메이션이 끝날 때까지 언마운트를 미루는 것)이 없습니다.** 검토된 백로그 아이디어일 뿐 지금은 없습니다 — 지금은 실제로 지울 때 애니메이션이 끝나길 기다려 주지 않습니다.

**다른 것**

- **props 안에서 숫자 키와 문자 키가 다른 뜻입니다.** 문자 키는 프로퍼티·이벤트(`Text = …`, `Activated = fn`)이고, 숫자 키(배열 자리)는 `Modifier`·자식·`Ref`·`Slot`·`Tag`/`Attr`·`q.OnChange`/`q.Out`·생명주기 훅이 놓이는 자리입니다. JSX의 속성과 자식이 한 문법으로 섞이는 것과 달리, quad는 이 둘을 문법 층위에서 갈라 둡니다 — [왜 Quad인가](/overview/01-why-quad/)의 예제가 그 모양을 보여줍니다.

---

## 4. 어디로 갈까

- **손으로 먼저 만들어 보고 싶다면**: [시작하기 00. 설치](/getting-started/00-installation/)부터 22편을 순서대로.
- **폼/입력 패턴이 궁금하다면**: [How-To 02. 폼 유효성 검사와 제출 버튼 제어](/how-to/02-form-validation-pattern/).
- **반응성·Slot·GC·디스패치의 내부 원리가 궁금하다면**: [Quadnomicon Vol. 1](/quadnomicon/01-revision-and-epochmap/)(Revision·EpochMap), [Vol. 2](/quadnomicon/02-slot-prefix-sum-tree/)(Slot 부분합 트리), [Vol. 7](/quadnomicon/07-instance-identity-and-gc-philosophy/)(인스턴스 신원·GC), [Vol. 8](/quadnomicon/08-extensible-dispatch-engine/)(디스패치 엔진), [Vol. 9](/quadnomicon/09-fragment-breakthrough-and-domless-slot/)(Slot으로 형제 여럿 반환하기).
- **심볼을 바로 찾고 싶다면**: [API 레퍼런스 색인](/reference/00-index/).
- **v1을 쓰던 분이라면**: [quad v1에서 오는 분께](/overview/02-from-v1/).
