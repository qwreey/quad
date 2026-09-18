---
title: Observer / Effect
description: leaf 구독 핸들 둘 — state:Observer(fn)과 q.Effect(fn, ...deps), 구독 네 진입점과 cleanup
---
반응형 그래프의 **말단**에 붙어 바깥세상에 부수효과를 내는 핸들 둘입니다.

- **`Observer`** — 노드 **하나**를 관측합니다. 값을 실어주지 않고, cleanup 개념도 없습니다.
- **`Effect`** — 의존성 **여럿**(`State`/`Source`/`Ref`)을 걸고, 함수가 돌려준 cleanup을 생명주기에 맞춰 소진합니다.

둘은 이름이 같은 네 진입점(`:Subscribe` / `:WeakSubscribe` / `:Unsubscribe` / `:WeakUnsubscribe`)과 `.Subscribed` 플래그를 공유하지만, **본문은 각자의 것**입니다 — 아래 각 절이 그 차이를 적습니다.

이 페이지의 심볼: [`state:Observer(fn)`](#stateobserverfn) · [`observer.Subscribed`](#observersubscribed) · [`observer:Subscribe()`](#observersubscribe) · [`observer:WeakSubscribe()`](#observerweaksubscribe) · [`observer:Unsubscribe()`](#observerunsubscribe) · [`observer:WeakUnsubscribe()`](#observerweakunsubscribe) · [`q.Effect(fn, ...deps)`](#qeffectfn-deps) · [`effect:Rerun()`](#effectrerun) · [`effect:Subscribe()`](#effectsubscribe) · [`effect:WeakSubscribe()`](#effectweaksubscribe) · [`effect:Unsubscribe()`](#effectunsubscribe) · [`effect:WeakUnsubscribe()`](#effectweakunsubscribe)

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local D = q.Declaration
```

:::note
**생존 판정은 백엔드가 심습니다.** 이 페이지의 구독·바인딩은 전부 백엔드가 설치하는 생명주기 op 위에서 돕니다. 프로바이더를 설치하지 않은 맨 `Quad.New()`에서 `:Subscribe()`를 부르면 `quad: {name} is not available — no backend has installed {what}` 로 시작하는 에러(뒤에 프로바이더를 설치하라는 안내가 붙습니다)가 납니다. 판정 자체의 설계는 [Quadnomicon Vol. 6](/quadnomicon/06-liveness-gate-and-isolation/).
:::

---

## 핸들은 두 가지로 살아난다

만들어진 직후의 핸들은 **아직 실행 자격이 없습니다**(`.Subscribed`는 `false`). 자격을 얻는 경로는 둘이고, 둘 중 하나만 골라야 합니다.

1. **props의 숫자 키 자리에 핸들을 넣어 인스턴스에 매다는 것** — 그 인스턴스가 사는 동안만 실행 자격을 유지합니다. 인스턴스가 파괴되면 `Observer`는 **관측을 멈추고**(그 뒤로는 값이 바뀌어도 콜백이 불리지 않습니다), `Effect`은 **cleanup이 한 번 돈 뒤** 멈춥니다. UI에 딸린 부수효과는 대개 이쪽입니다.
2. **전역 구독** — `:Subscribe()`(강한 유지) 또는 `:WeakSubscribe()`(약한 유지). 인스턴스와 무관하게 사는 구독입니다.

**둘을 겹칠 수는 없습니다.** 이미 한쪽으로 살아 있는 핸들을 다른 쪽으로 다시 살리려 하면 거절합니다 — `Observer: already subscribed` 또는 `Observer: already bound to an Instance`(`Effect`도 주어만 바뀐 같은 문구).

### 숫자 키 자리에 넣기

```luau
local hp = q.Source(100)

local label = D.TextLabel {
	Text = hp:Compute(function(self: q.StateData<number>)
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

문자 키 자리에 넣으면 타입 우회 실수로 보고 거절합니다:

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

**동작**

- **등록 즉시 한 번 발화합니다**(`emitFrom = nil`). 초기값 반영을 따로 적을 필요가 없습니다.
- 그 첫 발화 **뒤에** 상류의 구독자 집합에 합류합니다 — 첫 발화 안에서 대상 노드를 `:Set`해도 자기 자신이 그걸 다시 받지 않습니다.
- 아직 살아나지 않은(구독도 바인딩도 안 된) 핸들에도 emit은 **도착합니다**. 다만 실행 자격이 없어 **보류**되고, 그 사이 몇 번이 왔든 살아나는 시점에 **정확히 한 번**, `emitFrom = nil`로 재생됩니다.
- 콜백은 **자기 자신을 구독하거나 묶을 수 없습니다**. 콜백 안에서 `:Subscribe()`/`:WeakSubscribe()`를 부르면
  `Observer: cannot change subscription from inside its own fn`
  (콜백 안에서 만든 핸들을 숫자 키 자리에 놓는 경우는 `Observer: cannot bind an Observer from inside its own fn`). 해제(`:Unsubscribe()`/`:WeakUnsubscribe()`)는 콜백 안에서도 됩니다 — 해제는 콜백을 다시 부르지 않습니다.
- 콜백이 예외를 던지면 그 핸들은 **굳습니다** — 이후 (재)구독과 다른 인스턴스에 묶기는 위 문구로 거부됩니다. 발화 자체는 막히지 않아 상류가 바뀌면 콜백은 계속 돕니다(quad는 예외를 잡지 않으므로 "던졌다"는 사실을 따로 기억하지 못합니다). 정리하려면 `:Unsubscribe()`(강한 구독) 또는 묶인 인스턴스의 파괴로 놓아주세요.
- 인자 검증: `State: Observer fn must be a function (or nil for the always-observe utility)`
- 같은 원천을 구독한 Observer·Effect끼리의 **발화 순서는 정해져 있지 않습니다** — 등록 순서도 아닙니다. 순서가 필요하면 한 콜백 안에서 차례대로 부르세요.
- 콜백 안에서 **yield하지 마세요**(Roblox의 `task.wait` 등) — 정의되지 않은 동작입니다. 파동이 그 자리에서 멈추거나 같은 콜백이 겹쳐 돌 수 있고, 겹치면 나중 값의 콜백이 먼저 끝나 **마지막으로 처리한 값이 낡은 값**이 됩니다. 기다릴 일은 따로 띄운 코루틴으로 떼어 내세요.
- 숫자 키 자리에 놓여 **묶이는 순간** 보류돼 있던 통지가 한 번 재생되는데, 그 콜백이 던지면 `Declaration`은 에러로 끝나지만 그 핸들은 실패한 인스턴스에 묶인 채 남습니다(정의되지 않은 동작 — `Effect`도 같습니다). 같은 핸들로 다시 놓으면 원인 대신 `bindLifetime: value is already bound to another Instance`가 납니다. 재시도는 새 핸들로 하세요 — `Declaration` 안에서 인라인으로 만드는 보통 코드는 자연히 그렇게 됩니다.

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

`Effect`도 같은 이름의 플래그를 같은 뜻으로 갖습니다.

**strict 캐비엇** — 한 함수 안에서 `.Subscribed`를 비교한 뒤 `:Subscribe()`/`:Unsubscribe()`를 부르고 같은 필드를 다시 비교하면, 타입 검사기가 앞 비교로 좁힌 값을 그대로 들고 있어 두 번째 비교를 모순으로 봅니다(런타임 값은 정상). 다시 읽어야 하면 함수를 거쳐 읽으세요 — `local function subscribed(h) return h.Subscribed end`.

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
콜백 안에서, 그리고 콜백이 던져 굳은 뒤에도 됩니다 — 해제는 콜백을 부르지 않습니다.

---

## `observer:WeakUnsubscribe()`

**시그니처** — `WeakUnsubscribe: (self: Observer) -> Observer`

**동작** — 약한 구독을 해제합니다. **관대합니다** — 구독한 적이 없거나 이미 풀린 핸들에 불러도 조용히 통과합니다. 단, 강한 유지가 남아 있으면 반쯤 풀린 핸들이 되므로 거절합니다:
`Observer: subscribed strongly; use :Unsubscribe()`

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
| `...deps` | `State` / `Source` / `Ref` | 이것들이 움직일 때마다 `fn`이 다시 돕니다. |

**반환** — `Effect`. **아직 구독되지 않은 상태**입니다.

**동작**

- **생성하는 그 자리에서 `fn`이 한 번 돕니다.** 구독·바인딩보다 먼저이며, 이 첫 실행은 미룰 수 없습니다.
- 의존성은 생성자에서 한 번 검증합니다. 같은 것을 여러 번 넘기면 조용히 하나로 합쳐집니다.
  - `Effect: fn must be a function`
  - `Effect: dep #{i} is nil`
  - `Effect: dep #{i} is not a State/Source/Ref` (번호는 `...deps`에서의 자리입니다)
- **cleanup은 함수 하나입니다.** 타입의 가변 반환 표기는 "아무것도 안 돌려줘도 된다"를 위한 것이고, 런타임이 소진하는 것은 **첫 번째 반환 하나**뿐입니다. 정리할 게 여럿이면 한 클로저로 묶으세요 — `return function() a() b() end`. 함수도 `nil`도 아닌 값(숫자, 연결 객체 등)을 돌려주면 그 자리에서 던지고, `fn`이 던진 것과 같이 그 `Effect`는 죽습니다 — 연결은 `return function() conn:Disconnect() end`처럼 감싸세요.
  - `Effect: fn must return a cleanup function or nothing (got {typeof(cleanup)})`
- cleanup 안에서 의존성을 `:Set`해도 됩니다 — 바로 뒤에 도는 `fn`이 그 새 값을 읽고, 그것으로 한 사이클입니다(같은 입력으로 한 번 더 돌지 않습니다). `fn` 안에서 의존성을 `:Set`하면 한 번 더 돕니다.
- cleanup이 도는 자리는 넷입니다 — 다음 `fn` 실행 직전, [`:Unsubscribe()`](#effectunsubscribe), 매달린 인스턴스가 파괴될 때, 그리고 인스턴스는 살아 있는데 **그 숫자 키 자리가 다른 값으로 재구동될 때**(자리를 `State<Effect?>`로 잡아 두고 갈아 끼우는 경우 — 그 자리를 떠나는 `Effect`의 cleanup이 한 번 돕니다). cleanup은 인자 하나 `dying`을 받습니다 — 셋째 자리(**인스턴스가 죽어서**)에서만 `true`이고 나머지 셋에서는 `false`입니다. 죽을 때만 해야 할 정리와 자리를 떠날 때마다 할 정리를 이걸로 가릅니다. 인자를 안 받는 `function() … end`도 그대로 됩니다.
- 살아나기 전의 의존성 변경은 `Observer`와 같이 **보류**됐다가 살아나는 시점에 한 번 재생됩니다.
- `fn`이나 cleanup 안에서 자기를 (재)구독할 수 없습니다:
  `Effect: cannot change subscription from inside fn or cleanup`
  (콜백 안에서 만든 핸들을 숫자 키 자리에 놓는 경우는 `Effect: cannot bind an Effect from inside its own fn or cleanup`). 해제(`:Unsubscribe()`/`:WeakUnsubscribe()`)는 `fn` 안에서도 됩니다 — `fn`을 다시 부르지 않고, `fn`이 그 뒤 돌려준 cleanup은 저장되지 않고 즉시 소진됩니다(핸들이 더는 실행 자격이 없으므로).
- `fn` 안에서 의존성을 `:Set`하면 그 실행이 끝난 뒤 한 번 더 도는 **지연 재실행**이 됩니다.
- `fn`이 예외를 던지면 그 `Effect`는 **죽습니다** — 이후 재실행과 (재)구독이 막힙니다. 남는 일은 `:Unsubscribe()`(강한 구독을 풀어 핸들과 상류를 놓아줌 — 그때 소진할 cleanup은 없습니다, 던진 `fn`은 돌려준 게 없으니까) 또는 `:WeakUnsubscribe()`뿐입니다. 죽은 핸들을 강한 구독에 둔 채 버리면 모듈 수명 동안 남습니다.
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

**관련** — [How-To 04 네트워크·입력 브리지](/how-to/04-network-and-input-bridge/) · [Quadnomicon Vol. 6](/quadnomicon/06-liveness-gate-and-isolation/)

---

## `effect:Rerun()`

**시그니처** — `Rerun: (self: Effect) -> Effect` (인자 없음, self 반환)

**동작** — `fn`을 지금 다시 돌립니다(직전 cleanup을 먼저 소진하고). 실행 자격이 없으면(구독·바인딩 전, 파괴 파동 안, cleanup 실행 중) **돌지 않고 요청을 보류**했다가 살아나는 시점에 한 번 재생합니다. 이미 `fn`이 도는 중이면 그 실행이 끝난 뒤로 미뤄집니다.

---

## `effect:Subscribe()`

**시그니처** — `Subscribe: (self: Effect) -> Effect`

**동작** — **강한 구독**. 레지스트리가 핸들을 강하게 잡습니다. `.Subscribed`를 올린 뒤, 보류된 변경이 있으면 한 번 재생합니다.

**에러** — `Effect: already subscribed` / `Effect: already bound to an Instance` / `Effect: cannot change subscription from inside fn or cleanup`

---

## `effect:WeakSubscribe()`

**시그니처** — `WeakSubscribe: (self: Effect) -> Effect`

**동작** — **약한 구독**. 나머지는 `:Subscribe()`와 같지만 레지스트리가 핸들을 잡아주지 않습니다 — 참조를 놓으면 수거됩니다. 이때 `Effect`가 강하게 쥐고 있던 의존성 등록(`Ref` 콜백, 내부 Observer)도 함께 사라집니다.

---

## `effect:Unsubscribe()`

**시그니처** — `Unsubscribe: (self: Effect) -> Effect`

**동작** — 강한 구독을 해제하고 **마지막 cleanup을 정확히 한 번 소진합니다**. 엄격합니다:
`Effect: not subscribed strongly; use :WeakUnsubscribe()`
(이 문에서 거절당하면 cleanup은 건드려지지 않습니다.) `fn` 안에서도, `fn`이 던져 죽은 뒤에도 됩니다 — `fn`을 부르지 않습니다.

---

## `effect:WeakUnsubscribe()`

**시그니처** — `WeakUnsubscribe: (self: Effect) -> Effect`

**동작** — 약한 구독을 해제합니다. **관대하며**(구독한 적 없어도 통과) **cleanup을 건드리지 않습니다**. 강한 유지가 남아 있으면 거절합니다:
`Effect: subscribed strongly; use :Unsubscribe()`

**관련** — [03-state](/reference/core/03-state/) · [sugar/06-blocker](/reference/sugar/06-blocker/) · [Quadnomicon Vol. 3 — 메모리 토폴로지](/quadnomicon/03-luau-memory-topology/)
