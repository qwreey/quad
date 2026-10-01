---
title: State
description: 읽기 전용 파생 반응형 노드 — Get/Compute/Depend/Apply/Observer/Gate
---
`State`는 **파생 노드**입니다. 값을 직접 쓸 수 없고, 상류(`Source`나 다른 `State`)에서 계산돼 나옵니다. **런타임 생성자가 없습니다** — `State` 값은 `:Compute` / `:Depend` / `:Gate`(그리고 그 위에 얹힌 `:Apply` 팩토리들)의 결과로만 생깁니다. 쓰기가 필요하면 [`Source`](/reference/core/02-source/)입니다.

이 페이지의 심볼: [`state:Get()`](#stateget) · [`state:Compute(fn, ...deps)`](#statecomputefn-deps) · [`state:Depend(...)`](#statedepend) · [`state:Apply(factory)`](#stateapplyfactory) · [`state:Observer(fn)`](#stateobserverfn) · [`state:Gate(setup)`](#stategatesetup)

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
```

**타입 표기** — 타입의 출처는 `quad-types` 패키지이고, [01장의 설정 모듈](/getting-started/01-setup/)이 자주 쓰는 아홉을 다시 내보내므로 이 문서는 `q.State<T>`처럼 적습니다. `quad-base`를 직접 require한 모듈에는 `State`라는 값도, `State<T>`라는 타입도 없습니다 — 설정 모듈을 안 거친다면 `QuadTypes.State<T>`로 적으세요.

```luau
export type StateData<T> = { read __quadState: true, read __quadStateValue: T, Get: (self: StateData<T>) -> T }

export type State<T> = StateData<T> & {
	Compute: <U>(self: StateData<T>, fn: (self: StateData<T>, previous: U?, ...any) -> U, ...any) -> State<U>,
	Depend: (self: StateData<T>, ...any) -> State<T>,
	Apply: (<U>(self: StateData<T>, factory: (State<T>) -> U) -> U) & ((self: StateData<T>, factory: { __apply: (self: any, state: any) -> any }) -> any),
	Observer: (self: StateData<T>, fn: ObserverFn<T>?) -> Observer,
	Gate: (self: StateData<T>, setup: GateSetup) -> State<T>,
}
```

`StateData<T>`는 "값을 읽을 수 있는 부분"만 떼어낸 것이고, 콜백 파라미터 자리에 오는 lazy 핸들이 이 타입입니다. `__quadStateValue`는 타입에만 있는 팬텀 필드입니다 — 런타임 값에는 없으니 읽지 마세요. `State<T>`는 주석 자리에서 **불변**입니다(`State<number>`는 `State<number | UDim>` 자리에 들어가지 않습니다). 값을 넘겨받는 자리들은 그래서 공변 마커 타입을 요구합니다 — [Quadnomicon Vol. 4](/quadnomicon/04-covariant-markers/).

`print(state)`는 캐시가 유효할 때 `State(<값>)`, 아직 계산 전이거나 무효화된 상태면 `State(?)`로 찍힙니다. 출력을 위해 계산을 돌리지 않기 때문입니다. `:Gate`가 끼운 게이트 노드는 같은 모양을 이름만 바꿔 씁니다 — `Gate(2)`, 캐시가 무효면 `Gate(?)`.

---

## `state:Get()`

**시그니처**

```luau
Get: (self: StateData<T>) -> T
```

**반환** — 이 노드의 현재 값.

**동작**

- **lazy입니다.** 아무도 `:Get()`을 부르지 않으면 `:Compute`의 함수는 돌지 않습니다. 반대로 값이 이미 최신이면 `:Get()`을 여러 번 불러도 재계산은 없습니다.
- 재계산이 필요하면 **수렴할 때까지 다시 계산합니다**. 계산 함수가 도는 도중에 상류가 움직였다면(닫힌 게이트 뒤에 있어 통지가 못 온 변경 등) 그걸 반영해 다시 계산합니다 — 그래서 `:Get()`은 언제나 "가장 최신 입력으로 계산된 값"을 돌려줍니다.
- 이 되감기는 **값만** 앞당깁니다. 통지(구독자 발화)는 진짜 emit이 올 때까지 기다립니다.
- ⚠️ 계산 함수가 매 회차마다 자기 상류를 다시 `:Set`한다면 이 루프는 수렴하지 않습니다. **정의되지 않은 동작**입니다(계산 함수 안의 `:Set` 자체가 그렇습니다 — 아래 [`state:Compute`](#statecomputefn-deps)).

---

## `state:Compute(fn, ...deps)`

**시그니처**

```luau
Compute: <U>(self: StateData<T>, fn: (self: StateData<T>, previous: U?, ...any) -> U, ...any) -> State<U>
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `fn` | `(self, previous?, ...deps) -> U` | 계산 함수. 함수가 아니면 에러. |
| `...deps` | `State`/`Source` | 후행 의존성. 리시버 외에 더 구독할 노드들. `nil`은 에러. |

**반환** — `State<U>` 노드 하나. 의존성이 여럿이어도 노드는 하나입니다(합치는 중간 노드를 만들지 않습니다).

**동작**

**반응형 콜백은 파동 도중 yield하지 않고, 꼬인 파동을 풀어 줄 도구가 없는 곳에서 자기 입력을 되먹이지 않습니다.** 계산 함수는 어떤 `State`도 `:Set`하지 않습니다 — 읽어서 조합해 돌려줄 뿐입니다. 계산 함수 안(그 함수가 부른 것 안 포함)의 `:Set`/`:Emit`과 yield는 **정의되지 않은 동작**입니다. 예외는 하나 — [`Effect`](/reference/core/05-observer-effect/#qeffectfn-deps)가 자기 의존성을 `:Set`하면 끝난 뒤 한 번 더 도는데, 지연 재실행이 그 꼬임을 푸는 정의된 동작입니다. 이 밖은 정의되지 않습니다. [`q.debug`](/reference/core/01-quad-module/#qdebug)를 켜면 계산 함수 도중의 `:Set`/`:Emit`과, 멈춘 계산 위에 새 계산이 시작되는 것(yield)이 경고 한 줄로 드러납니다(동작은 그대로).

- 콜백이 받는 것은 **값이 아니라 lazy 핸들**입니다. 첫 인자 `self`는 **리시버**(`:Compute`를 부른 그 노드)의 핸들이고, 세 번째 인자부터는 `...deps`가 넘긴 순서 그대로의 핸들입니다. 전부 `:Get()`으로 읽습니다.
- 예외는 두 번째 인자 `previous`입니다 — 이건 핸들이 아니라 **이 노드가 직전에 계산해 둔 결과값 자체**이고, 아직 한 번도 계산하지 않았으면 `nil`입니다. 노드마다 독립적으로 기억됩니다.
  - **`previous`는 값의 연속성(누적·직전 값과의 비교)을 위한 것이지 자원 소유·정리를 위한 것이 아닙니다.** 계산 함수가 `previous`로 받은 Instance나 연결을 `Destroy`/`q.dispose`하고 새로 만드는 모양은 쓰지 마세요 — 계산 함수는 순수해야 하고(언제 몇 번 돌지는 읽는 쪽이 정합니다 — [시작하기 19장](/getting-started/19-laziness/)), 실행이 겹치면(yield·재진입) 각 실행이 시작할 때 같은 `previous`를 읽으므로 같은 값을 두 번 정리하게 되거나, 어떤 결과는 `previous`로 넘어오지 못하고 버려져 정리되지 않습니다(정의되지 않은 동작). 만들고 치워야 하는 자원은 [`Effect`](/reference/core/05-observer-effect/#qeffectfn-deps)의 cleanup으로 다루세요.
- 조건에 따라 `self:Get()`을 건너뛰는 계산도 그대로 허용됩니다 — 읽지 않으면 그 회차엔 상류를 계산하지 않습니다.
- 계산 함수는 **값 한 세대에 한 번만 돕니다.** 계산 함수가 자기 노드의 값을 읽으면(직접, 또는 하류 State를 거쳐 — 의존성 순환) 그 `:Get()` 줄에서 아래 문구로 에러가 납니다 — 순환은 만든 쪽의 실수라 그 자리에서 잡힙니다. 계산 함수가 **던지면** 그 세대의 재읽기도 같은 문구로 에러이고, 상류가 바뀌어 새 세대가 되면 다시 돕니다 — 잘못된 값을 고쳐 `:Set`하면 회복됩니다(그 상류가 `Blocker`·`Debounce` 뒤에서 유보 중이어도 같습니다 — 게이트는 통지만 붙들지 값을 가리지 않습니다). 회복되는 것은 **그 노드**입니다 — 던지는 순간 그 값을 읽던 소비자는 자기 자리의 계약대로 남습니다(읽던 `Effect`는 죽고(`Quad0088`류), 같은 세대에 그 값을 읽은 `:List` 원소가 있으면 그 Slot의 `Length` 발행이 멈춥니다; 어느 소비자가 예외를 받는지는 구독 순회 순서라 정해져 있지 않습니다 — [2026-09-27 mock 실측]). 잡히지 않는 순환 하나: 계산 함수가 자기 의존성을 `:Set`한 **뒤** 자기 값을 읽으면 그 `:Set`이 새 세대를 만들어 재진입으로 보이지 않고 스택 오버플로가 납니다(계산 함수 안에서 자기 의존성을 쓰는 것 자체가 정의되지 않은 동작).
  `Quad0184 State: Compute fn is already running for this value - a dependency cycle (the fn reads its own value, directly or through a downstream State), a yield inside the fn, or an earlier read that threw (it runs again once an upstream changes)`
- **계산 함수 안의 yield는 정의되지 않은 동작입니다** — 계산은 읽는 쪽의 `:Get()` 안에서 동기로 돕니다. UB에서의 현재 관측(계약 아님): 멈춘 사이 다른 코루틴이 같은 세대를 읽으면 위 문구로 에러가 나고, 상류가 바뀌어 다른 코루틴이 새 세대를 계산하면 그쪽은 돌고 에러는 yield했다 돌아온 쪽의 읽기가 받습니다.
- **여러 `State` 중 하나를 고르는 계산은 고를 `State`들을 `...deps`로 넣고 `:Get()`한 값을 돌려주는 것이 정식입니다.** 그러면 한 원천의 변경이 선택과 값을 함께 바꿔도 이 노드가 한 파동을 접어 한 번만 내보냅니다. `State` 자체를 돌려주는 계산(`State<State<T>>`)도 지원되지만 의미가 다릅니다 — 바깥 노드는 안쪽 `State`를 읽지(pull) 않으므로 안쪽이 지금 파동을 받았는지 모르고, 그래서 관여하지 않는 것이 이 구조의 의도된 동작입니다. 같은 원천에서 한 번에 선택과 안쪽 값이 함께 바뀌면, 소비하는 자리에는 빠진 가지의 (그 자체로는 옳은) 새 값이 한 번 쓰였다가 새 선택으로 바뀔 수 있습니다 — 숫자 키 자리에서 그 값이 이미 다른 곳에 마운트된 Instance면 `Quad0160`, Slot 원소 자리면 `Quad0156`으로 드러납니다. 고르는 계산은 대부분 값으로 접는 쪽이 낫습니다.
- 계산 결과로 **Modifier를 돌려줄 수 없습니다**:
  `Quad0185 State: a Compute function returned a Modifier - State/Source cannot hold Modifiers`
- 인자 검증: `Quad0187 State: Compute fn must be a function (got {typeof(fn)})` / `Quad0186 State: dep #{i + 1} is nil` / `Quad0183 State: dep #{i} is not a State/Source`. 번호는 **리시버가 1번**이라, 후행 의존성의 첫 자리가 `#2`입니다. 검사는 `nil`을 먼저 전부 보고 그다음 타입을 보므로 `a:Depend(5, nil)`은 `#2`가 아니라 `dep #3 is nil`을 냅니다(`Effect`는 자리 순서대로 한 번에 봅니다 — `q.Effect(fn, nil, 5)`는 `Quad0095 Effect: dep #1 is nil`, `q.Effect(fn, 5, nil)`은 `Quad0096 Effect: dep #1 is not a State/Source/Ref` — [2026-09-27 mock 실측]).

**strict 캐비엇** — 반환이 `State<U>`로 온전히 추론되지 않는 자리가 있어, **파생 노드를 만드는 줄에는 결과 타입을 주석**하는 것이 이 코퍼스의 관례입니다. 또 `...deps`가 `...any`이므로 콜백 안에서 의존성 파라미터에 타입 주석을 다세요.

**예제**

```luau
local width = q.Source(2)
local height = q.Source(10)

local area: q.State<number> = width:Compute(function(self, previous, other: q.StateData<number>)
	return self:Get() * other:Get()
end, height)

print(area:Get()) --> 20
height:Set(20)
print(area:Get()) --> 40
```

**관련** — [How-To 02 폼 검증](/how-to/02-form-validation-pattern/) · [Quadnomicon Vol. 1](/quadnomicon/01-revision-and-epochmap/)

---

## `state:Depend(...)`

**시그니처**

```luau
Depend: (self: StateData<T>, ...any) -> State<T>
```

**인자** — 넘긴 가변 인자는 **전부 추가 의존성**입니다(`:Compute`와 같은 검증을 받습니다).

**반환** — `State<T>`. 값은 리시버의 것을 그대로 통과시키는 노드입니다.

**동작**

- 값은 그대로 두고 **구독 범위만 넓히는** 노드를 하나 만듭니다. "A의 값을 쓰되, B가 움직여도 다시 발행되어야 한다"가 필요할 때 씁니다.
- `:Compute`처럼 계산 함수를 받지 않으므로 `previous` 같은 개념도 없습니다.
- 넘긴 의존성의 **값을 읽어 오지 않습니다.** 이름이 `:Compute(fn, ...deps)`·`q.Effect(fn, ...deps)`의 `deps`와 같은 낱말인 이유입니다 — 그 deps만 따로 거는 연산입니다. 값이 필요하면 뒤에 붙인 `:Compute` 안에서 직접 `:Get()`하세요.
- `:Observer(fn)`와 헷갈리지 마세요 — `:Observer`는 **fn이 이 State를 관측**하는 구독 핸들이고, `:Depend`는 **State가 다른 State의 변경을 따라가는** 새 노드입니다(콜백이 없습니다).

**예제**

```luau
local text = q.Source("hello")
local locale = q.Source("ko")

-- text의 값 그대로, 다만 locale이 바뀌어도 다시 흐른다
local shown: q.State<string> = text:Depend(locale)
print(shown:Get()) --> hello
```

---

## `state:Apply(factory)`

**시그니처**

```luau
Apply: (<U>(self: StateData<T>, factory: (State<T>) -> U) -> U)
     & ((self: StateData<T>, factory: { __apply: (self: any, state: any) -> any }) -> any)
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `factory` | 함수 또는 `__apply`를 가진 객체 | 이 노드를 받아 무언가를 돌려주는 애플리커티브 팩토리. |

**반환** — 함수 팔은 팩토리가 돌려주는 것 그대로, 객체 팔은 `any`입니다.

**동작**

- 함수를 넘기면 `factory(self)`를 그대로 부릅니다.
- 객체를 넘기면 메소드 형태로 `factory:__apply(self)`를 부릅니다 — 이 자리의 `self`는 팩토리 객체입니다. [`Blocker`](/reference/sugar/06-blocker/)와 `Debounce`/`Throttle`이 이 팔로 붙습니다(`q.Animate { … }`는 함수를 돌려주는 팩토리라 함수 팔입니다).
- 둘 중 어느 쪽도 아니면
  `Quad0191 State: Apply factory must be a function or an object with an __apply method (got {typeof(factory)})`

**strict 캐비엇** — 두 팔은 유니온이 아니라 **교집합 오버로드**입니다(객체가 너비 서브타이핑으로 들어가야 하기 때문). 객체 팔의 반환이 `any`이므로 결과 타입은 호출부에서 명시하세요:

```luau
local raw = q.Source(0)
local blocker = q.Blocker()
local gated: q.State<number> = raw:Apply(blocker)
```

**관련** — [sugar/06-blocker](/reference/sugar/06-blocker/) · [How-To 05 테마와 동적 스타일](/how-to/05-theme-and-dynamic-styling/)

---

## `state:Observer(fn)`

**시그니처**

```luau
Observer: (self: StateData<T>, fn: ObserverFn<T>?) -> Observer
export type ObserverFn<T> = (targetState: StateData<T>, self: Observer, emitFrom: (Epoch | EpochSet)?) -> ()
```

값을 실어주지 않는 leaf 구독 핸들을 만듭니다. 콜백은 **값이 아니라 관측 대상 핸들·자기 자신·출처**를 받고, 등록 시점에 즉시 한 번 발화합니다. 전체 계약(구독 네 진입점, 보류와 캐치업)은 **[05-observer-effect](/reference/core/05-observer-effect/#stateobserverfn)** 가 정본입니다.

인자 검증: `Quad0190 State: Observer fn must be a function or nil (got {typeof(fn)}) - nil makes the always-observe utility`

---

## `state:Gate(setup)`

**시그니처**

```luau
Gate: (self: StateData<T>, setup: GateSetup) -> State<T>
export type GateEmit = (commit: boolean?) -> boolean
export type GateSetup = (emit: GateEmit) -> () -> ()
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `setup` | `(emit) -> onUpstreamEmit` | 게이트 정책. **생성 시 딱 한 번** 불리고, 상류 emit마다 불릴 클로저를 돌려줘야 합니다. |

**반환** — 같은 `T`의 `State<T>`. 전파 경로에 게이트 노드 하나가 끼어든 것뿐입니다.

**동작**

- **값은 절대 가리지 않습니다.** 게이트가 막는 것은 통지뿐이라, 유보 중에도 `:Get()`은 최신 값을 돌려줍니다.
- 상류에서 emit이 오면 게이트는 그 **출처를 흡수 집합에 모아 두고** `setup`이 돌려준 클로저를 부릅니다. 그 클로저가 `emit`을 어떻게 쓸지가 정책의 전부입니다.
- `emit()` 또는 `emit(true)` — 모아둔 배치를 지금 한 번에 내려보냅니다. `emit(false)` — 모아둔 배치를 **버립니다**(전파도, 기록도 없음). 반환값은 "모아둔 게 있었는가"이며, 배치가 비어 있으면 아무 일도 하지 않고 `false`입니다.
- 유보 중에 여러 번 온 변경은 **한 번의 통지로 합쳐집니다**. 내려가는 출처는 원래 `Source`가 아니라 게이트가 만든 배치(집합)입니다. 게이트가 여럿이면 하류가 받는 횟수는 그래프·순회 순서에 따라 달라질 수 있습니다([Blocker](/reference/sugar/06-blocker/)의 `:Off()` 절) — 횟수가 아니라 값에 기대세요.
- 유보 중에 새로 만든 하류 `Observer`·`Effect`는 첫 실행에서 최신 값을 읽지만 유보된 통지는 받은 적이 없으므로, 게이트가 배치를 내려보낼 때 **같은 값으로 한 번 더** 돕니다(둘이 같습니다 — [2026-09-30 mock 실측]).
- 게이트 위에 게이트를 얹을 수 있습니다. 위쪽 게이트가 내려보낸 배치는 참조로 들고 있지 않고 풀어서 자기 집합에 합칩니다.
- 인자 검증: `Quad0188 State: Gate setup must be a function (emit) -> onUpstreamEmit (got {typeof(setup)})` / `Quad0189 State: Gate setup must return the onUpstreamEmit function`

**예제**

```luau
local raw = q.Source(0)
local release: ((commit: boolean?) -> boolean)?

-- 상류 변경을 무조건 붙잡아 두고, release()를 부를 때만 흘려보내는 정책
local held: q.State<number> = raw:Gate(function(emit)
	release = emit
	return function() end -- 상류 emit이 와도 아무것도 하지 않는다 = 유보
end)

local seen = {}
held:Observer(function(target)
	table.insert(seen, target:Get())
end):Subscribe()

raw:Set(1)
raw:Set(2)
print(#seen, held:Get()) --> 1  2   (통지는 설치 발화 한 번뿐, 값은 이미 최신)
print((release :: any)()) --> true (모아둔 배치를 흘려보냄 → 구독자 1회 발화)
```

**관련** — [sugar/06-blocker](/reference/sugar/06-blocker/)(`Blocker`는 이 위의 정책입니다) · [05-observer-effect](/reference/core/05-observer-effect/)
