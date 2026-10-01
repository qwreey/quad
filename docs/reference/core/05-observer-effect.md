---
title: Observer / Effect
description: leaf 구독 핸들 둘 — state:Observer(fn)과 q.Effect(fn, ...deps), 구독 네 진입점과 cleanup
---
# Observer / Effect

반응형 그래프의 **말단**에 붙어 바깥세상에 부수효과를 내는 핸들 둘입니다.

- **`Observer`** — 노드 **하나**를 관측합니다. 값을 실어주지 않고, cleanup 개념도 없습니다.
- **`Effect`** — 의존성 **여럿**(`State`/`Source`/`Ref`)을 걸고, 함수가 돌려준 cleanup을 생명주기에 맞춰 소진합니다.

둘은 이름이 같은 네 진입점(`:Subscribe` / `:WeakSubscribe` / `:Unsubscribe` / `:WeakUnsubscribe`)과 `.Subscribed` 플래그를 공유하지만, **본문은 각자의 것**입니다 — 아래 각 절이 그 차이를 적습니다.

**반응형 콜백은 파동 도중 yield하지 않고, 꼬인 파동을 풀어 줄 도구가 없는 곳에서 자기 입력을 되먹이지 않습니다.** [`:Compute`](./03-state.md#statecomputefn-deps) 계산 함수는 어떤 `State`도 `:Set`하지 않습니다 — 읽어서 조합해 돌려줄 뿐입니다. `Effect`가 자기 의존성을 `:Set`하면 끝난 뒤 한 번 더 도는데, 이것은 지연 재실행이 그 꼬임을 푸는 정의된 예외입니다. 이 밖은 정의되지 않습니다. 다른 대상을 `:Set`하는 것은 두 핸들의 본업입니다.

이 페이지의 심볼: [`state:Observer(fn)`](#stateobserverfn) · [`observer.Subscribed`](#observersubscribed) · [`observer:Subscribe()`](#observersubscribe) · [`observer:WeakSubscribe()`](#observerweaksubscribe) · [`observer:Unsubscribe()`](#observerunsubscribe) · [`observer:WeakUnsubscribe()`](#observerweakunsubscribe) · [`q.Effect(fn, ...deps)`](#qeffectfn-deps) · [`effect:Rerun()`](#effectrerun) · [`effect:Subscribe()`](#effectsubscribe) · [`effect:WeakSubscribe()`](#effectweaksubscribe) · [`effect:Unsubscribe()`](#effectunsubscribe) · [`effect:WeakUnsubscribe()`](#effectweakunsubscribe)

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.Declaration
```

:::note
**생존 판정의 인스턴스 쪽 절반은 백엔드가 심습니다.** 판정 자체(`canBound`/`canExecute`)와 바인딩(`bindLifetime`)은 quad-base 것이고, 그 아래 "이 값이 살아 있는 인스턴스에 묶여 있는가"만 백엔드의 hold op(`isHeld` 등)에 묻습니다. 프로바이더를 설치하지 않은 맨 `Quad.New()`에서 `:Subscribe()`를 부르면 `quad: {name} is not available - no backend has installed {what}` 로 시작하는 에러(뒤에 프로바이더를 설치하라는 안내가 붙습니다)가 납니다. 판정 자체의 설계는 [Quadnomicon Vol. 6](../../quadnomicon/06-liveness-gate-and-isolation.md).
:::

---

## 핸들은 두 가지로 살아난다

만들어진 직후의 핸들은 **아직 실행 자격이 없습니다**(`.Subscribed`는 `false`). 자격을 얻는 경로는 둘이고, 둘 중 하나만 골라야 합니다.

1. **props의 숫자 키 자리에 핸들을 넣어 인스턴스에 매다는 것** — 그 인스턴스가 사는 동안만 실행 자격을 유지합니다. 인스턴스가 파괴되면 `Observer`는 **관측을 멈추고**(그 뒤로는 값이 바뀌어도 콜백이 불리지 않습니다 — 기본 Deferred 시그널 설정에선 파괴 즉시; Immediate 설정에선 파괴 파동 안에서 죽는 쪽의 cleanup·`OnDestroyed`가 부른 `Set`은 같은 호스트의 핸들을 한 번 더 돌릴 수 있습니다), `Effect`은 **cleanup이 한 번 돈 뒤** 멈춥니다. UI에 딸린 부수효과는 대개 이쪽입니다.
2. **전역 구독** — `:Subscribe()`(강한 유지) 또는 `:WeakSubscribe()`(약한 유지). 인스턴스와 무관하게 사는 구독입니다.

**둘을 겹칠 수는 없습니다.** 이미 한쪽으로 살아 있는 핸들을 다른 쪽으로 다시 살리려 하면 거절합니다 — 묶인 핸들에 `:Subscribe()`/`:WeakSubscribe()`를 부르면 `Observer: already bound to an Instance`(`Effect`도 주어만 바뀐 같은 문구), 반대로 구독된 핸들을 숫자 키 자리(`D.Frame { h }`)에 놓으면 `Quad0104 bindLifetime: value is already subscribed`([2026-09-27 mock 실측] — 강한·약한 구독 둘 다).

### 숫자 키 자리에 넣기

```luau
local hp = q.Source(100)

local label = D.TextLabel {
	Text = hp:Compute(function(self: q.StateData<number>)
		return `HP {self:Get()}`
	end),

	-- 숫자 키 자리: 이 인스턴스의 수명에 매달린다
	-- (strict: 이 자리의 무주석 콜백은 target의 타입을 잃습니다 — 값을 쓰려면 `target: q.StateData<number>`처럼 주석을 달 것)
	hp:Observer(function(target)
		print("hp is now", target:Get())
	end),
	q.Effect(function()
		print("effect sees", hp:Get())
	end, hp),
}
```

문자 키 자리에 넣으면 타입 우회 실수로 보고 거절합니다:

- `Quad0116 Observer: must be an array item, not the value of a {typeof(k)} key`
- `Quad0097 Effect: must be an array item, not the value of a {typeof(k)} key`

단 그 문자 키가 그 클래스의 반영 프로퍼티 이름이면 프로퍼티 핸들러가 먼저 받아 이 거절에 닿지 않습니다(생성된 props 타입이 strict에서 그 자리를 막는 것이 첫 방어입니다). [`q.debug`](./01-quad-module.md#qdebug)를 켜면 그런 자리마다 경고 한 줄이 나옵니다(같은 요소·키는 한 번, 동작은 그대로).

---

## `state:Observer(fn)`

**시그니처**

```luau
Observer: (self: StateData<T>, fn: ObserverFn<T>?) -> Observer

export type ObserverFn<T> = (targetState: StateData<T>, self: Observer, emitFrom: (Epoch | EpochSet)?) -> ()
export type Observer = {
	read __quadObserver: true,
	read Subscribed: boolean,
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

**Observer는 최종 소비자입니다.** 관측한 값을 화면·로그·바깥 세계로 내보내는 끝자리이지, 값을 만들어 그래프에 다시 공급하는 자리가 아닙니다. 콜백이 **다른** 대상을 `:Set`하는 것은 정상입니다. 콜백이 **자기 상류**(관측 대상이나 그 원천)를 직접, 또는 다른 핸들을 거쳐 다시 `:Set`하는 것은 **정의되지 않은 동작**입니다 — `Compute` 안에서 `:Set`하는 것과 같은 종류이고, 그 공급 때문에 이 핸들과 같은 상류를 보는 핸들들이 **몇 번, 어떤 순서로, 어떤 값으로** 도는지 quad는 정하지 않습니다(같은 값으로 중복해 도는 것도 포함). 예를 들어 같은 `Compute`를 보는 형제 Observer 둘이 각자 그 원천을 되쓰면, 어느 쪽이 몇 번 어떤 값으로 도는지 정해져 있지 않습니다. 값을 이어 만들려면 `Compute`로 파생하세요 — 필요한 State를 `...deps`로 선언하고 계산 함수 안에서 `:Get()`으로 읽습니다([03-state](./03-state.md#statecomputefn-deps)). 자기 입력을 되써서 바로잡아야 하면 [`Effect`](#qeffectfn-deps)로 옮기세요 — 지연 재실행이 그 꼬임을 푸는 정의된 경로입니다. 범위를 강제하려면 값을 받는 자리(입력 핸들러)에서 깎아 `:Set`하거나 `src:Compute(...)`로 깎은 값을 따로 두세요. **Slot의 [`Offset`/`Length`](./06-slot.md)를 보는 콜백이 Slot을 CRUD해 그 값이 다시 바뀌는 고리도 여기 해당하지 않습니다** — 그 고리는 State가 아니라 Slot의 자리 계산을 거치고, Slot이 스스로 다시 계산해 맞춥니다(정의된 경로 — 예: 옆 Slot의 길이에 따라 헤딩·그리드 칸을 넣고 빼기; 넣고 빼기를 값마다 뒤집는 콜백은 `Effect`의 무한 재실행처럼 끝나지 않습니다). **바깥세상을 한 바퀴 도는 왕복도 여기 해당하지 않습니다** — Observer가 쓴 프로퍼티를 엔진이 [`q.Out`](../roblox/05-onchange.md#qoutname-src)·`OnChange`로 다시 올려 보내는 경로는 정상입니다(엔진은 같은 값을 다시 넣으면 신호를 내지 않고, `q.Out`은 같은 값을 거르므로 한 바퀴에서 멈춥니다). [`q.debug`](./01-quad-module.md#qdebug)를 켜면 콜백이 도는 도중 같은 핸들에 실행할 변경이 다시 도착하는 것 — 자기 상류를 되먹였다는 신호 — 이 핸들마다 경고 한 줄로 드러납니다(던지지 않고, 동작은 그대로; 위 Slot 자리 계산을 거친 고리는 알리지 않습니다).

**동작**

- **등록 즉시 한 번 발화합니다**(`emitFrom = nil`). 초기값 반영을 따로 적을 필요가 없습니다.
- 핸들은 **먼저** 상류의 구독자 집합에 합류하고, 그다음 첫 발화를 합니다. 첫 발화 도중 대상 노드가 바뀌면 그 변경은 버려지지 않고 **보류**됩니다 — 첫 발화 안에서 콜백을 다시 돌리지 않고, 핸들이 묶이거나 구독될 때 **한 번** `emitFrom = nil`로 반영됩니다(아직 살아나지 않은 핸들에 온 변경과 같은 규칙 — 아래 항목). 첫 발화 도중 변경이 오는 길은 콜백 자신(이나 콜백이 깨운 다른 코드)이 자기 상류를 되먹이는 것뿐이고, 그건 위 단락대로 정의되지 않은 동작입니다.
- 첫 발화의 콜백이 던지면 예외는 `:Observer(...)` 호출 밖으로 나가고 핸들은 돌려받지 못합니다. 그 핸들은 상류의 구독자 집합(약한 참조)에 남아 있다가 수거되고, 그동안 변경이 와도 콜백은 돌지 않습니다.
- 아직 살아나지 않은(구독도 바인딩도 안 된) 핸들에도 emit은 **도착합니다**. 다만 실행 자격이 없어 **보류**되고, 그 사이 몇 번이 왔든 살아나는 시점에 **정확히 한 번**, `emitFrom = nil`로 재생됩니다.
- `Source`를 직접 관측하는 핸들은 **이미 돈 리비전으로 다시 돌지 않습니다.** 파동 도중 다른 콜백이 이 핸들을 살려(구독·바인딩) 재생이 먼저 돌았거나, 다른 콜백이 같은 `Source`를 다시 `:Set`해 안쪽 파동이 먼저 이 핸들에 닿았다면, 뒤늦게 도착하는 같은 리비전의 통지는 건너뜁니다. 이 보장은 `Source`를 직접 관측할 때뿐입니다 — 파생 State(`:Compute` 등)를 관측하는 핸들은 같은 두 경우에 같은 값으로 한 번 더 돌 수 있습니다([2026-09-30 mock 실측]; 몇 번째로 닿는지는 발화 순서처럼 정해져 있지 않습니다).
- 콜백은 **자기 자신을 구독하거나 묶을 수 없습니다**. 콜백 안에서 `:Subscribe()`/`:WeakSubscribe()`를 부르면
  `Observer: cannot change subscription from inside its own fn`
  (콜백 안에서 만든 핸들을 숫자 키 자리에 놓는 경우는 `Quad0109 Observer: cannot bind an Observer from inside its own fn`). 해제(`:Unsubscribe()`/`:WeakUnsubscribe()`)는 콜백 안에서도 됩니다 — 해제는 콜백을 다시 부르지 않습니다.
- 살아난 뒤의 콜백이 자기 관측 대상을 `:Set`하는 것도 자기 상류 되먹임이라 정의되지 않은 동작입니다. 관측(계약 아님): 지금은 새 파동이 콜백 안에서 곧바로 이 핸들을 다시 부르고(`Effect`처럼 끝난 뒤로 미루지 않습니다), 바깥 실행의 나머지는 되쓰기 전에 읽은 옛 값을 들고 이어집니다. 조건 없이 되쓰는 콜백은 `Source`가 같은 값도 전파하므로 스택이 자라 넘칩니다. 대상을 되써 수렴시켜야 하면 `Effect`로 옮기세요.
- 콜백이 예외를 던지면 그 핸들은 **굳습니다** — 이후 (재)구독과 다른 인스턴스에 묶기는 위 문구로 거부됩니다. 발화 자체는 막히지 않아 상류가 바뀌면 콜백은 계속 돕니다(quad는 예외를 잡지 않으므로 "던졌다"는 사실을 따로 기억하지 못합니다). 정리하려면 `:Unsubscribe()`(강한 구독) 또는 묶인 인스턴스의 파괴로 놓아주세요.
- 인자 검증: `Quad0190 State: Observer fn must be a function or nil (got {typeof(fn)}) - nil makes the always-observe utility`
- 같은 원천을 구독한 Observer·Effect끼리의 **발화 순서는 정해져 있지 않습니다** — 등록 순서도 아닙니다. 순서가 필요하면 한 콜백 안에서 차례대로 부르세요.
- 콜백 안에서 **yield하지 마세요**(Roblox의 `task.wait` 등) — 정의되지 않은 동작입니다. 파동이 그 자리에서 멈추거나 같은 콜백이 겹쳐 돌 수 있고, 겹치면 나중 값의 콜백이 먼저 끝나 **마지막으로 처리한 값이 낡은 값**이 됩니다. 기다릴 일은 따로 띄운 코루틴으로 떼어 내세요.
- 숫자 키 자리에 놓여 **묶이는 순간** 보류돼 있던 통지가 한 번 재생되는데, 그 콜백이 던지면 `Declaration`은 에러로 끝나지만 그 핸들은 실패한 인스턴스에 묶인 채 남습니다(정의되지 않은 동작 — `Effect`도 같습니다). 같은 핸들로 다시 놓으면 원인 대신 `Quad0233 bindLifetime: value is already bound to another Instance`가 납니다. 재시도는 새 핸들로 하세요 — `Declaration` 안에서 인라인으로 만드는 보통 코드는 자연히 그렇게 됩니다.

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

**관련** — [03-state](./03-state.md) · [Quadnomicon Vol. 6](../../quadnomicon/06-liveness-gate-and-isolation.md)

---

## `observer.Subscribed`

`boolean` 필드. **강한 구독뿐 아니라 약한 구독에서도 `true`가 됩니다** — "전역 구독(`:Subscribe`/`:WeakSubscribe`)이 붙어 있는가"를 나타내는 플래그이지 "강하게 잡혀 있는가"가 아닙니다. 숫자 키 자리에 묶여 살아 있는 핸들은 이 필드가 `false`입니다(그 경로는 인스턴스 수명이 자격을 주므로) — "지금 실행 자격이 있는가"를 묻는 것이 아닙니다. 강·약 구분은 해제할 때 어느 문을 써야 하는지로 드러납니다(아래 두 쌍).

`Effect`도 같은 이름의 플래그를 같은 뜻으로 갖습니다.

**strict 캐비엇** — 한 함수 안에서 `.Subscribed`를 비교한 뒤 `:Subscribe()`/`:Unsubscribe()`를 부르고 같은 필드를 다시 비교하면, 타입 검사기가 앞 비교로 좁힌 값을 그대로 들고 있어 두 번째 비교를 모순으로 봅니다(런타임 값은 정상). 다시 읽어야 하면 함수를 거쳐 읽으세요 — `local function subscribed(h) return h.Subscribed end`.

---

## `observer:Subscribe()`

**시그니처** — `Subscribe: (self: Observer) -> Observer` (self 반환)

**동작** — **강한 구독**. 전역 레지스트리가 핸들을 강하게 잡으므로, 참조를 어디에도 남기지 않아도 수거되지 않습니다. `.Subscribed`를 올리고, 보류된 변경이 있으면 그 자리에서 한 번 재생합니다.

**에러** — 이미 살아 있으면 `Quad0114 Observer: already subscribed` / `Quad0235 Observer: already bound to an Instance`. 콜백 안에서 부르면 `Quad0113 Observer: cannot change subscription from inside its own fn`.

---

## `observer:WeakSubscribe()`

**시그니처** — `WeakSubscribe: (self: Observer) -> Observer`

**동작** — **약한 구독**. `.Subscribed`를 올리고 보류분을 재생하는 것은 `:Subscribe()`와 같지만, 레지스트리가 핸들을 잡아주지 않습니다 — **당신이 참조를 들고 있어야** 살아 있습니다. 놓으면 수거되고 발화도 멈춥니다.

**에러** — `:Subscribe()`와 같습니다.

---

## `observer:Unsubscribe()`

**시그니처** — `Unsubscribe: (self: Observer) -> Observer`

**동작** — 강한 구독을 해제합니다(강·약 등록을 둘 다 지우고 `.Subscribed`를 내립니다). **엄격합니다** — 강하게 구독한 적이 없으면 거절합니다:
`Quad0115 Observer: only a strongly subscribed Observer can be released with :Unsubscribe() - a weakly subscribed one must be released with :WeakUnsubscribe(), and one held only by a seat must be released by clearing that seat`
콜백 안에서, 그리고 콜백이 던져 굳은 뒤에도 됩니다 — 해제는 콜백을 부르지 않습니다.

---

## `observer:WeakUnsubscribe()`

**시그니처** — `WeakUnsubscribe: (self: Observer) -> Observer`

**동작** — 약한 구독을 해제합니다. **관대합니다** — 구독한 적이 없거나 이미 풀린 핸들에 불러도 조용히 통과합니다. 단, 강한 유지가 남아 있으면 반쯤 풀린 핸들이 되므로 거절합니다:
`Quad0112 Observer: subscribed strongly; use :Unsubscribe()`

---

## `q.Effect(fn, ...deps)`

**시그니처**

```luau
Effect: (fn: EffectFn, ...any) -> Effect

export type EffectFn = (self: Effect) -> ...((dying: boolean) -> ())
export type Effect = {
	read __quadEffect: true,
	read Subscribed: boolean,
	Rerun: (self: Effect) -> Effect,
	Subscribe: (self: Effect) -> Effect,
	WeakSubscribe: (self: Effect) -> Effect,
	Unsubscribe: (self: Effect) -> Effect,
	WeakUnsubscribe: (self: Effect) -> Effect,
}
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `fn` | `EffectFn` | 부수효과 본문. 인자로 **핸들 자신**을 받습니다(의존성 값은 넘어오지 않습니다 — 클로저로 직접 읽으세요). cleanup 함수를 돌려줄 수 있습니다. |
| `...deps` | `State` / `Source` / `Ref` | 이것들이 움직일 때마다 `fn`이 다시 돕니다 — 한 `Set`이 서로 다른 여러 dep을 거쳐 와도 **1회**이고(다이아몬드 흡수), 게이트를 거친 사본이 나중에 풀려도 이미 통지로 받은 리비전이면 0회입니다([2026-09-27 mock 실측]). 게이트가 막고 있는 동안 만든 `Effect`는 첫 실행에서 값을 읽었더라도 그 통지는 받은 적이 없으므로, 게이트가 풀리면 한 번 더 돕니다([2026-09-30 mock 실측]). |

**반환** — `Effect`. **아직 구독되지 않은 상태**입니다.

**동작**

- **생성하는 그 자리에서 `fn`이 한 번 돕니다.** 구독·바인딩보다 먼저이며, 이 첫 실행은 미룰 수 없습니다.
- 의존성은 생성자에서 한 번 검증합니다. 같은 것을 여러 번 넘기면 조용히 하나로 합쳐집니다.
  - `Quad0094 Effect: fn must be a function (got {typeof(fn)})`
  - `Quad0095 Effect: dep #{i} is nil`
  - `Quad0096 Effect: dep #{i} is not a State/Source/Ref` (번호는 `...deps`에서의 자리입니다)
- **cleanup은 함수 하나입니다.** 타입의 가변 반환 표기는 "아무것도 안 돌려줘도 된다"를 위한 것이고(단 strict에서 한 갈래는 cleanup을, 다른 갈래는 `return nil`을 하는 `fn`은 타입이 거부합니다 — `return nil :: any` 또는 빈 `return function() end`로 우회, [2026-09-27 실측]), 런타임이 소진하는 것은 **첫 번째 반환 하나**뿐입니다. 정리할 게 여럿이면 한 클로저로 묶으세요 — `return function() a() b() end`. 함수도 `nil`도 아닌 값(숫자, 연결 객체 등)을 돌려주면 그 자리에서 던지고, `fn`이 던진 것과 같이 그 `Effect`는 죽습니다 — 연결은 `return function() conn:Disconnect() end`처럼 감싸세요.
  - `Quad0086 Effect: fn must return a cleanup function or nothing (got {typeof(cleanup)})`
- cleanup 안에서 의존성을 `:Set`해도 됩니다 — 바로 뒤에 도는 `fn`이 그 새 값을 읽고, 그것으로 한 사이클입니다(같은 입력으로 한 번 더 돌지 않습니다). `fn` 안에서 의존성을 `:Set`하면 한 번 더 돕니다.
- cleanup이 도는 자리는 넷입니다 — 다음 `fn` 실행 직전, [`:Unsubscribe()`](#effectunsubscribe), 매달린 인스턴스가 파괴될 때, 그리고 인스턴스는 살아 있는데 **그 숫자 키 자리가 다른 값으로 재구동될 때**(자리를 `State<Effect?>`로 잡아 두고 갈아 끼우는 경우 — 그 자리를 떠나는 `Effect`의 cleanup이 한 번 돕니다). cleanup은 인자 하나 `dying`을 받습니다 — 셋째 자리(**인스턴스가 죽어서**)에서만 `true`이고 나머지 셋에서는 `false`입니다. 죽을 때만 해야 할 정리와 자리를 떠날 때마다 할 정리를 이걸로 가릅니다. 인자를 안 받는 `function() … end`도 그대로 됩니다.
  - **Immediate 시그널 설정에서 파괴 파동 도중 그 자리를 갈아 끼우는 것은 정의되지 않은 동작입니다.** 같은 파괴 파동 안에서 다른 파괴 처리(형제의 cleanup이나 `OnDestroyed`)가 죽어 가는 인스턴스의 `State<Effect?>` 자리를 **다른** 값으로 `Set`하면, 떠나는 옛 값의 cleanup은 "자리를 떠남"으로 처리돼 `dying = false`를 받고, 새 값은 이미 죽어 가는 인스턴스에 막 묶여 그 파괴 통지를 놓치므로 cleanup(과 `OnDestroyed`)이 **한 번도 돌지 않습니다**([2026-09-27 mock 실측]). 기본 Deferred 설정(Roblox 기본값)에서는 파괴 처리가 돌기 전에 자리의 구독이 먼저 끊겨 이 창이 없습니다.
- 살아나기 전의 의존성 변경은 `Observer`와 같이 **보류**됐다가 살아나는 시점에 한 번 재생됩니다. `Source`·`Ref` 의존성은 `fn`이 돌 때마다 그 리비전을 본 것으로 기록하므로, 파동 도중 되살아나 재생이 먼저 돌았다면 같은 파동의 뒤늦은 통지로 다시 돌지 않습니다 — `Observer`의 같은 항목과 같은 뜻이고, 파생 State 의존성은 이 경우 같은 값으로 한 번 더 돌 수 있다는 한계도 같습니다([2026-09-30 mock 실측]).
- `fn`이나 cleanup 안에서 자기를 (재)구독할 수 없습니다:
  `Effect: cannot change subscription from inside fn or cleanup, or after this Effect's fn or cleanup has thrown - a thrown Effect stays dead; create a new one`
  (콜백 안에서 만든 핸들을 숫자 키 자리에 놓는 경우는 `Quad0087 Effect: cannot bind an Effect from inside its own fn or cleanup`). 해제(`:Unsubscribe()`/`:WeakUnsubscribe()`)는 `fn` 안에서도 됩니다 — `fn`을 다시 부르지 않고, `fn`이 그 뒤 돌려준 cleanup은 저장되지 않고 즉시 소진됩니다(핸들이 더는 실행 자격이 없으므로).
- `fn` 안에서 의존성을 `:Set`하면 그 실행이 끝난 뒤 한 번 더 도는 **지연 재실행**이 됩니다. 재실행이 다시 `:Set`하면 또 돌고, 그렇게 이어지는 재실행은 정의된 동작입니다. 다만 한 번의 반복이 **1만 회를 넘게 다시 돌면 `Quad0263`으로 멈추고 던집니다**(늘 켜진 한도 — [`q.debug`](./01-quad-module.md#qdebug)와 무관합니다; 그 `Effect`는 `fn`이 던진 것과 같이 죽습니다). 첫 실행이든 이후 실행이든 의존성을 계속 바꿔 수렴하지 않는 `fn`이 여기 걸리고, **`Source`는 같은 값을 다시 넣어도 전파하므로** 조건 없이 같은 값을 되쓰는 `fn`도 여기 해당합니다. 되쓰기는 값이 실제로 다를 때만 하세요. **[2026-10-01 기준]** 게시된 3.2.0은 이 한도 없이 끝나지 않고 돌았고, 한도는 다음 릴리즈부터입니다([변경 이력](../../../CHANGELOG.md) `[Unreleased]`).
  - `Quad0263 Effect: fn re-ran 10000 times in one loop - the fn keeps setting one of its own deps (a Source propagates even an equal value; set only when the value differs)`
- `fn`이 예외를 던지면 그 `Effect`는 **죽습니다** — 이후 재실행과 (재)구독이 막힙니다. **cleanup이 던져도 같습니다** — 재실행·`:Unsubscribe`·호스트 파괴·`:WeakUnsubscribe` 어느 자리에서 던졌든 그 뒤 재실행은 보류되고 (재)구독은 "cannot change subscription from inside fn or cleanup"으로 거부됩니다(던진 자리에 따라 강한 구독이 남거나, 호스트 파괴 자리였다면 재바인드도 막힙니다). 남는 일은 `:Unsubscribe()`(강한 구독을 풀어 핸들과 상류를 놓아줌 — 그때 소진할 cleanup은 없습니다, 던진 `fn`은 돌려준 게 없으니까) 또는 `:WeakUnsubscribe()`뿐입니다. 죽은 핸들을 강한 구독에 둔 채 버리면 모듈 수명 동안 남습니다.
- `fn`과 cleanup 안에서 **yield하지 마세요** — 정의되지 않은 동작입니다. 증상은 `Observer`와 다릅니다: `Effect`는 겹친 요청을 `fn`이 돌아온 뒤 한 번 더 도는 것으로 흡수하지만, yield하는 사이 묶인 인스턴스가 죽거나 자리에서 내려가면 죽음의 cleanup은 이미 지나간 뒤입니다. 그래도 `fn`이 돌아오며 돌려준 cleanup은 버려지지 않습니다 — 핸들이 더는 실행 자격이 없으므로 그 자리에서 **즉시 소진**됩니다(인스턴스가 죽어서면 `dying = true`, 자리에서 내려가서면 `false`). 그 사이에 `fn`이 잡은 자원은 그렇게 정리되지만, 순서와 타이밍은 보장하지 않습니다. 네트워크 왕복은 `fn` 밖(따로 띄운 코루틴)에서 하고 결과를 `State`로 넣으세요.

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

**관련** — [How-To 04 네트워크·입력 브리지](../../how-to/04-network-and-input-bridge.md) · [Quadnomicon Vol. 6](../../quadnomicon/06-liveness-gate-and-isolation.md)

---

## `effect:Rerun()`

**시그니처** — `Rerun: (self: Effect) -> Effect` (인자 없음, self 반환)

**동작** — `fn`을 지금 다시 돌립니다(직전 cleanup을 먼저 소진하고). 실행 자격이 없으면(구독·바인딩 전, 파괴 파동 안, cleanup 실행 중) **돌지 않고 요청을 보류**했다가 살아나는 시점에 한 번 재생합니다. 이미 `fn`이 도는 중이면 그 실행이 끝난 뒤로 미뤄집니다 — 생성 직후의 첫 실행도 마찬가지라, 첫 실행의 `fn` 안에서 부른 `Rerun()`(또는 의존성 `:Set`)은 아직 구독·바인딩 전이어도 보류되지 않고 그 실행이 끝난 자리에서 한 번 더 돕니다. 실행 자격은 "의존성 변경으로 다시 돌 수 있는가"를 가르는 조건이지, 명시적으로 요청한 재실행을 미루는 장치가 아닙니다.

---

## `effect:Subscribe()`

**시그니처** — `Subscribe: (self: Effect) -> Effect`

**동작** — **강한 구독**. 레지스트리가 핸들을 강하게 잡습니다. `.Subscribed`를 올린 뒤, 보류된 변경이 있으면 한 번 재생합니다.

**에러** — `Quad0091 Effect: already subscribed` / `Quad0231 Effect: already bound to an Instance` / `Quad0090 Effect: cannot change subscription from inside fn or cleanup, or after this Effect's fn or cleanup has thrown - a thrown Effect stays dead; create a new one`

---

## `effect:WeakSubscribe()`

**시그니처** — `WeakSubscribe: (self: Effect) -> Effect`

**동작** — **약한 구독**. 나머지는 `:Subscribe()`와 같지만 레지스트리가 핸들을 잡아주지 않습니다 — 참조를 놓으면 수거됩니다. 이때 의존성 쪽에 걸려 있던 등록(`Ref` 콜백, State·Source의 구독자 집합 항목 — 둘 다 약한 참조이고 그 등록을 살려 두는 것은 `Effect`입니다)도 함께 사라집니다.

**에러** — `Quad0089 Effect: already subscribed` / `Quad0230 Effect: already bound to an Instance` / `Quad0088 Effect: cannot change subscription from inside fn or cleanup, or after this Effect's fn or cleanup has thrown - a thrown Effect stays dead; create a new one`

---

## `effect:Unsubscribe()`

**시그니처** — `Unsubscribe: (self: Effect) -> Effect`

**동작** — 강한 구독을 해제하고 **마지막 cleanup을 정확히 한 번 소진합니다**. 엄격합니다:
`Quad0093 Effect: only a strongly subscribed Effect can be released with :Unsubscribe() - a weakly subscribed one must be released with :WeakUnsubscribe(), and one held only by a seat must be released by clearing that seat`
(이 문에서 거절당하면 cleanup은 건드려지지 않습니다.) `fn` 안에서도, `fn`이 던져 죽은 뒤에도 됩니다 — `fn`을 부르지 않습니다. cleanup 안에서 자기를 해제하는 것은 그 cleanup이 다음 `fn` 직전·인스턴스 파괴·자리 교체로 소진될 때만 뜻이 있습니다 — **이 메소드가 소진한 cleanup 안에서 다시 `:Unsubscribe()`를 부르면** 강한 구독은 이미 풀린 뒤라 위 문구로 던집니다(이중 해제).

---

## `effect:WeakUnsubscribe()`

**시그니처** — `WeakUnsubscribe: (self: Effect) -> Effect`

**동작** — 약한 구독을 해제합니다. **관대하며**(구독한 적 없어도 통과) **cleanup을 건드리지 않습니다**. 강한 유지가 남아 있으면 거절합니다:
`Quad0092 Effect: subscribed strongly; use :Unsubscribe()`

**관련** — [03-state](./03-state.md) · [sugar/06-blocker](../sugar/06-blocker.md) · [Quadnomicon Vol. 3 — 메모리 토폴로지](../../quadnomicon/03-luau-memory-topology.md)
