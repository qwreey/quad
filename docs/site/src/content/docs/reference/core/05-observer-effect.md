---
title: Observer / Effect
description: leaf 구독 핸들 둘 — state:Observer(fn)과 q.Effect(fn, ...deps), 구독 네 진입점과 cleanup
---
반응형 그래프의 **말단**에 붙어 바깥세상에 부수효과를 내는 핸들 둘입니다.

- **`Observer`** — 노드 **하나**를 관측합니다. 값을 실어주지 않고, cleanup 개념도 없습니다.
- **`EffectHandle`** — 의존성 **여럿**(`State`/`Source`/`Ref`)을 걸고, 함수가 돌려준 cleanup을 생명주기에 맞춰 소진합니다.

둘은 이름이 같은 네 진입점(`:Subscribe` / `:WeakSubscribe` / `:Unsubscribe` / `:WeakUnsubscribe`)과 `.Subscribed` 플래그를 공유하지만, **본문은 각자의 것**입니다 — 아래 각 절이 그 차이를 적습니다.

이 페이지의 심볼: [`state:Observer(fn)`](#stateobserverfn) · [`observer.Subscribed`](#observersubscribed) · [`observer:Subscribe()`](#observersubscribe) · [`observer:WeakSubscribe()`](#observerweaksubscribe) · [`observer:Unsubscribe()`](#observerunsubscribe) · [`observer:WeakUnsubscribe()`](#observerweakunsubscribe) · [`q.Effect(fn, ...deps)`](#qeffectfn-deps) · [`effect:Rerun()`](#effectrerun) · [`effect:Subscribe()`](#effectsubscribe) · [`effect:WeakSubscribe()`](#effectweaksubscribe) · [`effect:Unsubscribe()`](#effectunsubscribe) · [`effect:WeakUnsubscribe()`](#effectweakunsubscribe)

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local QuadTypes = require(<quad-types 모듈 경로>) -- 타입 주석용(`QuadTypes.StateData<T>` 등)
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

:::note
**생존 판정은 백엔드가 심습니다.** 이 페이지의 구독·바인딩은 전부 백엔드가 설치하는 생명주기 op 위에서 돕니다. 프로바이더를 설치하지 않은 맨 `Quad.New()`에서 `:Subscribe()`를 부르면 `quad: {name} is not available — no backend has installed {what}` 로 시작하는 에러(뒤에 프로바이더를 설치하라는 안내가 붙습니다)가 납니다. 판정 자체의 설계는 [Quadnomicon Vol. 6](/quadnomicon/06-liveness-gate-and-isolation/).
:::

---

## 핸들은 두 가지로 살아난다

만들어진 직후의 핸들은 **아직 실행 자격이 없습니다**(`.Subscribed`는 `false`). 자격을 얻는 경로는 둘이고, 둘 중 하나만 골라야 합니다.

1. **요소 배열에 넣어 인스턴스에 매다는 것** — props의 **숫자 키** 자리에 핸들을 넣으면, 그 인스턴스가 사는 동안만 실행 자격을 유지합니다. 인스턴스가 파괴되면 `Observer`는 **관측을 멈추고**(그 뒤로는 값이 바뀌어도 콜백이 불리지 않습니다), `EffectHandle`은 **cleanup이 한 번 돈 뒤** 멈춥니다. UI에 딸린 부수효과는 대개 이쪽입니다.
2. **전역 구독** — `:Subscribe()`(강한 유지) 또는 `:WeakSubscribe()`(약한 유지). 인스턴스와 무관하게 사는 구독입니다.

**둘을 겹칠 수는 없습니다.** 이미 한쪽으로 살아 있는 핸들을 다른 쪽으로 다시 살리려 하면 거절합니다 — `Observer: already subscribed` 또는 `Observer: already bound to an Instance`(`Effect`도 주어만 바뀐 같은 문구).

### 숫자 키 자리에 넣기

```luau
local hp = q.Source(100)

local label = D.TextLabel {
	Text = hp:Compute(function(self: QuadTypes.StateData<number>)
		return `HP {self:Get()}`
	end),

	-- 숫자 키 자리: 이 인스턴스의 수명에 매달린다
	hp:Observer(function(target)
		print("hp is now", target:Get())
	end),
	q.Effect(function()
		print("effect sees", hp:Get())
	end, hp),
}
```

해시 키 자리에 넣으면 타입 우회 실수로 보고 거절합니다:

- `Observer: must be an array item, not the value of a {typeof(k)} key`
- `Effect: must be an array item, not the value of a {typeof(k)} key`

---

## `state:Observer(fn)`

**시그니처**

```luau
Observer: (self: StateData<T>, fn: ObserverFn<T>?) -> Observer

export type ObserverFn<T> = (targetState: StateData<T>, self: Observer, emitFrom: (Epoch | EpochSet)?) -> ()
export type Observer = {
	read __quadObserver: true,
	Subscribed: boolean,
	Subscribe: (self: Observer) -> Observer,
	WeakSubscribe: (self: Observer) -> Observer,
	Unsubscribe: (self: Observer) -> Observer,
	WeakUnsubscribe: (self: Observer) -> Observer,
}
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `fn` | `ObserverFn<T>?` | 관측 콜백. 생략하면 "언제나 관측만 하는" 유틸이 됩니다(내부적으로 대상의 값을 읽기만 합니다). |

콜백이 받는 셋:

| 자리 | 타입 | 설명 |
|---|---|---|
| `targetState` | `StateData<T>` | **관측 대상 노드의 핸들**. 값은 `:Get()`으로 읽습니다 — 값이 인자로 오지 않습니다. |
| `self` | `Observer` | 이 핸들 자신. |
| `emitFrom` | `(Epoch \| EpochSet)?` | 이 발화의 출처. 설치 발화와 보류분 재생 때는 **`nil`**이고, 게이트를 지나온 발화에서는 하나가 아니라 집합입니다. |

**반환** — `Observer` 핸들. **아직 구독되지 않은 상태**입니다.

**동작**

- **등록 즉시 한 번 발화합니다**(`emitFrom = nil`). 초기값 반영을 따로 적을 필요가 없습니다.
- 그 첫 발화 **뒤에** 상류의 구독자 집합에 합류합니다 — 첫 발화 안에서 대상 노드를 `:Set`해도 자기 자신이 그걸 다시 받지 않습니다.
- 아직 살아나지 않은(구독도 바인딩도 안 된) 핸들에도 emit은 **도착합니다**. 다만 실행 자격이 없어 **보류**되고, 그 사이 몇 번이 왔든 살아나는 시점에 **정확히 한 번**, `emitFrom = nil`로 재생됩니다.
- 콜백은 **자기 자신의 생명주기를 바꿀 수 없습니다**. 콜백 안에서 구독을 건드리면
  `Observer: cannot change subscription from inside its own fn`
- 인자 검증: `State: Observer fn must be a function (or nil for the always-observe utility)`

**예제**

```luau
local hp = q.Source(100)
local log = {}

local observer = hp:Observer(function(target, self, emitFrom)
	table.insert(log, target:Get())
end)
print(#log) --> 1 (등록 즉시 1회)

hp:Set(80)
print(#log) --> 1 (아직 살아나지 않았다 — 보류)

observer:Subscribe()
print(#log) --> 2 (보류분 1회 재생, 최신값 80)

hp:Set(60)
print(#log) --> 3
```

**관련** — [03-state](/reference/core/03-state/) · [Quadnomicon Vol. 6](/quadnomicon/06-liveness-gate-and-isolation/)

---

## `observer.Subscribed`

`boolean` 필드. **강한 구독뿐 아니라 약한 구독에서도 `true`가 됩니다** — "지금 살아 있는가"를 나타내는 플래그이지 "강하게 잡혀 있는가"가 아닙니다. 강·약 구분은 해제할 때 어느 문을 써야 하는지로 드러납니다(아래 두 쌍).

`EffectHandle`도 같은 이름의 플래그를 같은 뜻으로 갖습니다.

---

## `observer:Subscribe()`

**시그니처** — `Subscribe: (self: Observer) -> Observer` (self 반환)

**동작** — **강한 구독**. 전역 레지스트리가 핸들을 강하게 잡으므로, 참조를 어디에도 남기지 않아도 수거되지 않습니다. `.Subscribed`를 올리고, 보류된 변경이 있으면 그 자리에서 한 번 재생합니다.

**에러** — 이미 살아 있으면 `Observer: already subscribed` / `Observer: already bound to an Instance`. 콜백 안에서 부르면 `Observer: cannot change subscription from inside its own fn`.

---

## `observer:WeakSubscribe()`

**시그니처** — `WeakSubscribe: (self: Observer) -> Observer`

**동작** — **약한 구독**. `.Subscribed`를 올리고 보류분을 재생하는 것은 `:Subscribe()`와 같지만, 레지스트리가 핸들을 잡아주지 않습니다 — **당신이 참조를 들고 있어야** 살아 있습니다. 놓으면 수거되고 발화도 멈춥니다.

**에러** — `:Subscribe()`와 같습니다.

---

## `observer:Unsubscribe()`

**시그니처** — `Unsubscribe: (self: Observer) -> Observer`

**동작** — 강한 구독을 해제합니다(강·약 등록을 둘 다 지우고 `.Subscribed`를 내립니다). **엄격합니다** — 강하게 구독한 적이 없으면 거절합니다:
`Observer: not subscribed strongly; use :WeakUnsubscribe()`

---

## `observer:WeakUnsubscribe()`

**시그니처** — `WeakUnsubscribe: (self: Observer) -> Observer`

**동작** — 약한 구독을 해제합니다. **관대합니다** — 구독한 적이 없거나 이미 풀린 핸들에 불러도 조용히 통과합니다. 단, 강한 유지가 남아 있으면 반쯤 풀린 핸들이 되므로 거절합니다:
`Observer: subscribed strongly; use :Unsubscribe()`

---

## `q.Effect(fn, ...deps)`

**시그니처**

```luau
Effect: (fn: EffectFn, ...any) -> EffectHandle

export type EffectFn = (self: EffectHandle) -> ...(() -> ())
export type EffectHandle = {
	read __quadEffect: true,
	Subscribed: boolean,
	Rerun: (self: EffectHandle) -> EffectHandle,
	Subscribe: (self: EffectHandle) -> EffectHandle,
	WeakSubscribe: (self: EffectHandle) -> EffectHandle,
	Unsubscribe: (self: EffectHandle) -> EffectHandle,
	WeakUnsubscribe: (self: EffectHandle) -> EffectHandle,
}
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `fn` | `EffectFn` | 부수효과 본문. 인자로 **핸들 자신**을 받습니다(의존성 값은 넘어오지 않습니다 — 클로저로 직접 읽으세요). cleanup 함수를 돌려줄 수 있습니다. |
| `...deps` | `State` / `Source` / `Ref` | 이것들이 움직일 때마다 `fn`이 다시 돕니다. |

**반환** — `EffectHandle`. **아직 구독되지 않은 상태**입니다.

**동작**

- **생성하는 그 자리에서 `fn`이 한 번 돕니다.** 구독·바인딩보다 먼저이며, 이 첫 실행은 미룰 수 없습니다.
- 의존성은 생성자에서 한 번 검증합니다. 같은 것을 여러 번 넘기면 조용히 하나로 합쳐집니다.
  - `Effect: fn must be a function`
  - `Effect: dep #{i} is nil`
  - `Effect: dep #{i} is not a State/Source/Ref` (번호는 `...deps`에서의 자리입니다)
- **cleanup은 함수 하나입니다.** 타입의 가변 반환 표기는 "아무것도 안 돌려줘도 된다"를 위한 것이고, 런타임이 소진하는 것은 **첫 번째 반환 하나**뿐입니다. 정리할 게 여럿이면 한 클로저로 묶으세요 — `return function() a() b() end`.
- cleanup이 도는 자리는 셋입니다 — 다음 `fn` 실행 직전, [`:Unsubscribe()`](#effectunsubscribe), 그리고 매달린 인스턴스가 파괴될 때.
- 살아나기 전의 의존성 변경은 `Observer`와 같이 **보류**됐다가 살아나는 시점에 한 번 재생됩니다.
- `fn`이나 cleanup 안에서 자기 구독을 바꿀 수 없습니다:
  `Effect: cannot change subscription from inside fn or cleanup`
- `fn` 안에서 의존성을 `:Set`하면 그 실행이 끝난 뒤 한 번 더 도는 **지연 재실행**이 됩니다.
- `fn`이 예외를 던지면 그 `Effect`는 **죽습니다** — 이후 재실행이 전부 막힙니다.

**예제**

```luau
local hp = q.Source(100)

local effect = q.Effect(function(self)
	local value = hp:Get()
	print("hp:", value)
	return function()
		print("정리:", value) -- 다음 실행 직전 / 해제 / 파괴 때 정확히 한 번
	end
end, hp)
-- 여기서 이미 한 번 돌았다

effect:Subscribe()
hp:Set(80) -- 정리 → 재실행
effect:Unsubscribe() -- 마지막 정리 1회
```

**관련** — [How-To 04 네트워크·입력 브리지](/how-to/04-network-and-input-bridge/) · [Quadnomicon Vol. 6](/quadnomicon/06-liveness-gate-and-isolation/)

---

## `effect:Rerun()`

**시그니처** — `Rerun: (self: EffectHandle) -> EffectHandle` (인자 없음, self 반환)

**동작** — `fn`을 지금 다시 돌립니다(직전 cleanup을 먼저 소진하고). 실행 자격이 없으면(구독·바인딩 전, 파괴 파동 안, cleanup 실행 중) **돌지 않고 요청을 보류**했다가 살아나는 시점에 한 번 재생합니다. 이미 `fn`이 도는 중이면 그 실행이 끝난 뒤로 미뤄집니다.

---

## `effect:Subscribe()`

**시그니처** — `Subscribe: (self: EffectHandle) -> EffectHandle`

**동작** — **강한 구독**. 레지스트리가 핸들을 강하게 잡습니다. `.Subscribed`를 올린 뒤, 보류된 변경이 있으면 한 번 재생합니다.

**에러** — `Effect: already subscribed` / `Effect: already bound to an Instance` / `Effect: cannot change subscription from inside fn or cleanup`

---

## `effect:WeakSubscribe()`

**시그니처** — `WeakSubscribe: (self: EffectHandle) -> EffectHandle`

**동작** — **약한 구독**. 나머지는 `:Subscribe()`와 같지만 레지스트리가 핸들을 잡아주지 않습니다 — 참조를 놓으면 수거됩니다. 이때 `Effect`가 강하게 쥐고 있던 의존성 등록(`Ref` 콜백, 내부 Observer)도 함께 사라집니다.

---

## `effect:Unsubscribe()`

**시그니처** — `Unsubscribe: (self: EffectHandle) -> EffectHandle`

**동작** — 강한 구독을 해제하고 **마지막 cleanup을 정확히 한 번 소진합니다**. 엄격합니다:
`Effect: not subscribed strongly; use :WeakUnsubscribe()`
(이 문에서 거절당하면 cleanup은 건드려지지 않습니다.)

---

## `effect:WeakUnsubscribe()`

**시그니처** — `WeakUnsubscribe: (self: EffectHandle) -> EffectHandle`

**동작** — 약한 구독을 해제합니다. **관대하며**(구독한 적 없어도 통과) **cleanup을 건드리지 않습니다**. 강한 유지가 남아 있으면 거절합니다:
`Effect: subscribed strongly; use :Unsubscribe()`

**관련** — [03-state](/reference/core/03-state/) · [06-blocker-gate](/reference/core/06-blocker-gate/) · [Quadnomicon Vol. 3 — 메모리 토폴로지](/quadnomicon/03-luau-memory-topology/)
