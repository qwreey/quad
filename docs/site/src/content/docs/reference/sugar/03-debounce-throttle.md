---
title: "Debounce / Throttle"
description: "시간 기반 전파 게이트의 옵션·제어 핸들·브로드캐스트와 주입 시간 op 의존"
---
상류의 신호를 시간으로 걸러 하류 통지를 미루는 **게이트 팩토리**입니다. `Blocker`+`state:Gate`와 백엔드가 주입한 시간 op 위의 순수 슈거로, 새 코어 메커니즘을 만들지 않습니다.

이 페이지의 심볼: [`q.Debounce{...}`](#qdebounce) · [`q.Throttle{...}`](#qthrottle) · [`factory:Flush()`](#factoryflush) · [`factory:Cancel()`](#factorycancel) · [`handle:Flush()`](#handleflush) · [`handle:Cancel()`](#handlecancel)

:::note
둘 다 `quad-base`에 있지만 **동작하려면 백엔드가 필요합니다** — 순수 Luau엔 스케줄러가 없어 base가 시간 op를 기본 구현할 수 없습니다. 백엔드 없이 게이트가 타이머를 걸려는 순간(첫 상류 신호) 이렇게 죽습니다.

```
quad: setTimeout is not available — no backend has installed the lifetime primitives / engine ops (install a provider with quad:UseProvider — a bare Quad.New() has none; tests use mock.installLifetime)
```

`quad-roblox`는 `task.delay`/`task.cancel`로 이 둘을 채웁니다.
:::

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadTypes = require(<quad-types 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
type State<T> = QuadTypes.State<T>
```

---

## 공통 계약

`Debounce{...}` / `Throttle{...}`는 **팩토리**(`TimedGate`)를 돌려주고, `state:Apply(factory)`로 붙입니다. **`:Apply` 한 번이 게이트 노드 하나**를 만듭니다 — 자기 Blocker, 자기 타이머를 가집니다. 그래서 한 팩토리를 여러 State에 붙이면 게이트도 그만큼 생깁니다.

- **`Debounce`**: 상류 신호가 올 때마다 창을 다시 엽니다 — 신호가 멎은 뒤에 통과.
- **`Throttle`**: 창 길이가 고정입니다 — 신호가 창을 리셋하지 못합니다.
- 구현은 하나이고 이 리셋 비트 하나만 다릅니다.

**게이트는 통지만 유보합니다.** 창이 열려 있는 동안에도 `:Get()`은 언제나 상류의 최신 값을 돌려줍니다 — 값을 가리는 게 아니라 하류 알림을 미루는 것입니다.

`tostring`은 이름과 창 길이를 보여줍니다 — `Debounce(Time=0.3)`.

---

## `q.Debounce{...}`

**시그니처**

```luau
Debounce: (opts: DebounceOptions) -> TimedGate

export type DebounceOptions = {
    Time: number | State<number>,
    Leading: boolean?, -- 기본 false
    Trailing: boolean?, -- 기본 true
    MaxTime: (number | State<number>)?,
    Handle: Ref<GateHandle?>?,
}
```

**반환** — `TimedGate` 팩토리. `state:Apply(factory)`의 결과 타입은 상류와 같은 `State<T>`이고 호출부가 명시합니다.

## `q.Throttle{...}`

**시그니처**

```luau
Throttle: (opts: ThrottleOptions) -> TimedGate

export type ThrottleOptions = {
    Time: number | State<number>,
    Leading: boolean?, -- 기본 true
    Trailing: boolean?, -- 기본 true
    Handle: Ref<GateHandle?>?,
}
```

`MaxTime`이 없다는 것만 `DebounceOptions`와 다릅니다.

---

## 옵션

| 옵션 | 타입 | Debounce 기본값 | Throttle 기본값 | 설명 |
|---|---|---|---|---|
| `Time` | `number \| State<number>` | **필수** | **필수** | 창 길이(초). 음수·NaN 거부 |
| `Leading` | `boolean?` | `false` | `true` | 창이 열릴 때 첫 신호를 즉시 통과시킬지 |
| `Trailing` | `boolean?` | `true` | `true` | 창이 닫힐 때 보류분을 통과시킬지 |
| `MaxTime` | `(number \| State<number>)?` | `nil` | **없는 옵션** | 신호가 안 끊겨도 최대 이 간격마다 강제 통과 |
| `Handle` | `Ref<GateHandle?>?` | `nil` | `nil` | 수동 제어 핸들을 받을 Ref |

- `Leading`과 `Trailing`을 **둘 다 `false`로 주면 에러**입니다 — 아무것도 통과하지 못하므로.
- `MaxTime`은 **`Debounce` 전용**입니다. `Throttle`은 이미 `Time`마다 통과시키므로 옵션 자체가 거부됩니다.
- `MaxTime` 타이머는 **뭔가 보류됐고 `Trailing`이 그걸 통과시킬 수 있을 때만** 걸립니다. `Trailing = false`인 Debounce에 `MaxTime`을 줘도 아무 일도 하지 않습니다.
- `Time`/`MaxTime`에 `State`를 줘도 **구독하지 않습니다** — 타이머를 거는 시점에만 한 번 읽습니다. 이미 걸린 타이머는 자기 지연을 유지합니다.

**옵션 게이트(팩토리를 부르는 줄에서 던집니다).** 이름 자리(`Debounce`/`Throttle`)는 부른 쪽에 따라 바뀝니다.

```
Debounce: options table expected (got nil)
Debounce: Time is required (a number of seconds or a State<number>)
Debounce: Time must be a non-negative number or a State<number> (got number)
Debounce: Leading must be a boolean (got number)
Debounce: Handle must be a Ref (got table)
Debounce: Leading and Trailing both false would pass nothing through
Throttle: MaxTime is Debounce-only (a throttle already passes every Time)
```

`Time`/`MaxTime`에 State를 준 경우엔 값이 실제로 읽히는 **타이머를 거는 시점**에 한 번 더 검사합니다. 이때의 메시지는 조금 다릅니다(그 자리엔 `State<number>` 갈래가 없으므로).

```
Debounce: Time must be a non-negative number (got string)
```

`:Apply` 대상이 State가 아니면 그 `:Apply` 줄에서 막습니다.

```
Debounce: Apply target must be a State (got table)
```

---

## 제어 핸들 (`GateHandle`)

`Handle`에 `q.Ref<<QuadTypes.GateHandle?>>(nil)`를 넘기면 **`:Apply` 시점에** 그 Ref가 제어 핸들로 채워집니다(마운트 시점이 아닙니다).

```luau
export type GateHandle = {
    Flush: (self: GateHandle) -> (),
    Cancel: (self: GateHandle) -> (),
}
```

**Ref 하나는 `:Apply` 하나를 가리킵니다.** 이미 채워진 Ref를 다시 넘기면 — 팩토리를 재사용하며 같은 Handle을 쓰는 경우가 전형적입니다 — 그 `:Apply` 자리에서 에러가 납니다. 기본값이 `nil`이 아닌 Ref도 같은 이유로 거부됩니다.

```
Debounce: Handle is already filled — one Handle Ref per :Apply (make a new Ref, or drop Handle and use the factory's :Flush()/:Cancel() broadcast; a Ref with a non-nil default is rejected the same way)
```

여러 게이트를 한꺼번에 제어하려면 Handle 대신 팩토리 브로드캐스트를 쓰십시오.

### `handle:Flush()`

**시그니처** — `Flush: (self: GateHandle) -> ()`

보류분이 있으면 **지금 통과시키고** 창을 다시 엽니다. 보류분이 없으면 진짜 no-op입니다 — 돌고 있는 창을 건드리지 않습니다.

### `handle:Cancel()`

**시그니처** — `Cancel: (self: GateHandle) -> ()`

보류분을 **버리고** idle로 돌아갑니다. 전파가 일어나지 않습니다. 상류의 값 자체는 그대로이므로 `:Get()`은 여전히 최신 값입니다 — 버려지는 것은 통지입니다.

---

## 팩토리 브로드캐스트 (`TimedGate`)

```luau
export type TimedGate = {
    Flush: (self: TimedGate) -> (),
    Cancel: (self: TimedGate) -> (),
    __apply: (self: any, state: any) -> any,
}
```

### `factory:Flush()`

그 팩토리가 만든 **모든 게이트**에 `Flush`를 전파합니다. 팩토리는 자기가 만든 게이트를 약한 키로만 붙들고 있으므로, 이 목록이 게이트를 살려두지는 않습니다.

### `factory:Cancel()`

같은 방식으로 모든 게이트에 `Cancel`을 전파합니다.

---

## 예제

```luau
-- 검색창 디바운스(0.3초, 1초마다는 강제 통과) + 수동 제어 핸들
local searchInput = q.Source("")
local handle = q.Ref<<QuadTypes.GateHandle?>>(nil)
local debounced: State<string> = searchInput:Apply(q.Debounce {
    Time = 0.3,
    MaxTime = 1.0,
    Handle = handle,
})

-- Observer 콜백은 값이 아니라 대상 State 핸들을 받는다 — 값은 :Get()으로 읽는다.
-- 구독을 유지하려면 :Subscribe()(또는 숫자 키 자리에 넣어 인스턴스에 바인딩)해야 한다.
debounced:Observer(function(target)
    print("API 검색 실행:", target:Get())
end):Subscribe()

searchInput:Set("a")
searchInput:Set("ab") -- 창 안이라 통지 없음. 다만 debounced:Get()은 이미 "ab"
-- 0.3초 뒤 "ab"가 통지된다

handle:Unwrap():Flush() -- 기다리지 않고 지금 내보낸다(보류분이 없으면 no-op)
handle:Unwrap():Cancel() -- 보류분을 버린다(통지 없음)
```

```luau
-- 스크롤 위치 스로틀(0.1초 고정 창) — 팩토리 브로드캐스트로 한꺼번에 제어
local scrollGate = q.Throttle { Time = 0.1 }
local scrollRaw = q.Source(0)
local scrollPos: State<number> = scrollRaw:Apply(scrollGate)

scrollGate:Flush() -- 이 팩토리가 만든 게이트 전부
scrollGate:Cancel()
```

---

## 관련

- [Ref](/reference/core/07-ref/) — `Handle`이 받는 `Ref`, 그리고 [`ref:Unwrap()`](/reference/core/07-ref/#refunwrap)
- [네트워크·입력 브리지](/how-to/04-network-and-input-bridge/) — 바깥 이벤트를 반응형 그래프로 들여올 때
- [v1에서 옮겨오기](/how-to/08-migrating-from-v1/)
