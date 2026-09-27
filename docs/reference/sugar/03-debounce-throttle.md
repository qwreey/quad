---
title: "Debounce / Throttle"
description: "시간 기반 전파 게이트의 옵션·제어 핸들·브로드캐스트와 주입 시간 op 의존"
---
# Debounce / Throttle

상류의 신호를 시간으로 걸러 하류 통지를 미루는 **게이트 팩토리**입니다. `Blocker`+`state:Gate`와 백엔드가 주입한 시간 op 위의 순수 슈거로, 새 코어 메커니즘을 만들지 않습니다.

이 페이지의 심볼: [`q.Debounce{...}`](#qdebounce) · [`q.Throttle{...}`](#qthrottle) · [`factory:Flush()`](#factoryflush) · [`factory:Cancel()`](#factorycancel) · [`handle:Flush()`](#handleflush) · [`handle:Cancel()`](#handlecancel)

:::note
둘 다 `quad-base`에 있지만 **동작하려면 백엔드가 필요합니다** — 순수 Luau엔 스케줄러가 없어 base가 시간 op를 기본 구현할 수 없습니다. 백엔드 없이 게이트가 타이머를 걸려는 순간(첫 상류 신호) 이렇게 죽습니다.

```
Quad0108 quad: setTimeout is not available — no backend has installed the lifetime primitives / engine ops (install a provider with quad:UseProvider — a bare Quad.New() has none; headless tests install their own provider the same way)
```

`quad-roblox`는 `task.delay`/`task.cancel`로 이 둘을 채웁니다.
:::

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local QuadTypes = require("@game/ReplicatedStorage/roblox_packages/quad_types") -- 설정 모듈이 다시 내보내지 않는 타입(`QuadTypes.GateHandle` 등)
type State<T> = q.State<T>
```

---

## 공통 계약

`Debounce{...}` / `Throttle{...}`는 **팩토리**(`TimedGate`)를 돌려주고, `state:Apply(factory)`로 붙입니다. **`:Apply` 한 번이 게이트 노드 하나**를 만듭니다 — 자기 Blocker, 자기 타이머를 가집니다. 그래서 한 팩토리를 여러 State에 붙이면 게이트도 그만큼 생깁니다.

- **`Debounce`**: 상류 신호가 올 때마다 창을 다시 엽니다 — 신호가 멎은 뒤에 통과.
- **`Throttle`**: 창 길이가 고정입니다 — 신호가 창을 리셋하지 못합니다.
- 구현은 하나이고 이 리셋 비트 하나만 다릅니다.

**게이트는 통지만 유보합니다.** 창이 열려 있는 동안에도 `:Get()`은 언제나 상류의 최신 값을 돌려줍니다 — 값을 가리는 게 아니라 하류 알림을 미루는 것입니다.

`tostring`은 이름과 창 길이를 보여줍니다 — `Debounce(Time=0.3)`.

**수명** — 게이트 노드는 상류를 약하게 구독하고 대기 타이머가 자기를 붙듭니다. 하류(호스트 인스턴스)가 파괴되면 **마지막 상류 신호 뒤 최대 2×`Time`** 안에 수거됩니다 — 단 상류가 `Time`보다 촘촘하게 **계속** 발화하면 창이 계속 다시 열려 그동안은 살아서 창 처리를 되풀이합니다([2026-09-27 mock 실측] — 상류를 멈추면 3초 안에 0). 모듈 수명의 상류(`RunService` 같은 것을 담은 `Source`)에 게이트를 걸었다면 호스트를 버릴 때 핸들 `:Cancel()`을 부르세요(예: `OnDestroyed`에서).

---

:::caution
**타이머가 통과시키는 순간 하류가 던지면 leading edge 하나가 사라집니다.** 창 끝(또는 `MaxTime`)의 통과는 창을 닫은 뒤 하류로 보내므로, 그 통지를 받은 Observer가 던지면 게이트는 "창 없음·상류 차단 중" 상태로 다음 신호까지 남습니다. 다음 신호는 `Leading = true`여도 즉시 통과하지 못하고 보류돼 `Time` 뒤에 trailing으로 나갑니다 — 그 한 번뿐이고 이후는 정상입니다(`Leading = false`면 겉으로 차이가 없습니다). quad는 던진 사용자 콜백을 복구하지 않습니다([공통 계약](#공통-계약)).
:::

## `q.Debounce{...}`

**시그니처**

```luau
Debounce: (opts: DebounceOptions) -> TimedGate

export type DebounceOptions = {
    read Time: number | StateMarker<number>,
    read Leading: boolean?, -- 기본 false
    read Trailing: boolean?, -- 기본 true
    read MaxTime: (number | StateMarker<number>)?,
    read Handle: Ref<GateHandle?>?,
}
```

**반환** — `TimedGate` 팩토리. `state:Apply(factory)`의 결과 타입은 상류와 같은 `State<T>`이고 호출부가 명시합니다.

## `q.Throttle{...}`

**시그니처**

```luau
Throttle: (opts: ThrottleOptions) -> TimedGate

export type ThrottleOptions = {
    read Time: number | StateMarker<number>,
    read Leading: boolean?, -- 기본 true
    read Trailing: boolean?, -- 기본 true
    read Handle: Ref<GateHandle?>?,
}
```

`MaxTime`이 없다는 것만 `DebounceOptions`와 다릅니다.

---

## 옵션

모르는 키는 조용히 무시됩니다. `q.debug = true`면 모르는 옵션 키(오타·옛 이름)를 한 줄로 알려 줍니다 — 정본은 [`q.debug`](../core/01-quad-module.md#qdebug).

| 옵션 | 타입 | Debounce 기본값 | Throttle 기본값 | 설명 |
|---|---|---|---|---|
| `Time` | `number \| State<number>` | **필수** | **필수** | 창 길이(초). 음수·NaN 거부. `0`은 허용되지만 "즉시"가 아니라 백엔드 타이머의 다음 재개점(Roblox `task.delay(0)`은 다음 프레임 근방)으로 미뤄질 수 있습니다 — mock 백엔드에선 같은 `advanceTime(0)` 안에서 발화합니다 |
| `Leading` | `boolean?` | `false` | `true` | 창이 열릴 때 첫 신호를 즉시 통과시킬지 |
| `Trailing` | `boolean?` | `true` | `true` | 창이 닫힐 때 보류분을 통과시킬지 |
| `MaxTime` | `(number \| State<number>)?` | `nil` | **없는 옵션** | 신호가 안 끊겨도, 보류가 시작된 뒤 최대 이만큼 안에 강제 통과. 강제 통과는 창을 다시 열지 않으므로 `MaxTime < Time`이면 통과 간격이 `Time`보다 짧아지고(`Time` 1·`MaxTime` 0.5·0.25초 간격 신호 → 0.5초마다), `MaxTime` 0이면 신호마다 다음 타이머 틱에 통과합니다([2026-09-27 mock 실측]). 걸린 캡은 원래 지연을 유지하고 다음 캡부터 새 `State` 값을 씁니다 |
| `Handle` | `Ref<GateHandle?>?` | `nil` | `nil` | 수동 제어 핸들을 받을 Ref |

- 기본값을 적용한 결과 `Leading`과 `Trailing`이 **둘 다 `false`가 되면 에러**입니다 — 아무것도 통과하지 못하므로. `Debounce`는 `Leading`의 기본값이 `false`라서 `Trailing = false` 하나만 줘도 여기에 해당합니다 — 그때는 `Leading = true`를 같이 주세요.
- `MaxTime`은 **`Debounce` 전용**입니다. `Throttle`은 이미 `Time`마다 통과시키므로 옵션 자체가 거부됩니다.
- `MaxTime` 타이머는 **뭔가 보류됐고 `Trailing`이 그걸 통과시킬 수 있을 때만** 걸립니다. `Trailing = false`인 Debounce에 `MaxTime`을 줘도 아무 일도 하지 않습니다 — 읽지도 않으므로 그 자리의 `State`는 검증되지도, 계산되지도 않습니다. 그리고 그 타이머는 통과 시점이 아니라 **그다음 보류되는 신호**부터 잽니다 — 신호가 쉬지 않고 들어올 때 실제 통과 간격은 `MaxTime`에 "통과 뒤 다음 신호까지의 틈"이 더해집니다(0.1초마다 신호에 `MaxTime = 1`이면 1.0~1.1초).
- `Time`/`MaxTime`에 `State`를 줘도 **구독하지 않습니다** — 상류 신호가 들어올 때 한 번 읽습니다. 이미 걸린 타이머는 자기 지연을 유지하고, 창이 닫힌 뒤 다시 여는 창(trailing 통과 뒤·`Flush` 뒤)은 **마지막 신호 때 읽은 값**을 씁니다. 신호 없이 값만 바꾸면 다음 신호부터 반영됩니다.

:::caution
옵셔널 자리의 `Handle: Ref<GateHandle?>?`는 [2026-09-26 기준] 신 솔버가 타입 인자를 검사하지 않습니다 — 다른 `T`의 `Ref`(예: `q.Ref<<Frame?>>(nil)`)도 타입 검사를 통과합니다. Luau 쪽 한계이고, 런타임 가드(위 `Quad0047`)는 그대로 동작합니다.
<!-- .claude/base/typing-limits.md 8.26 -->
:::

**옵션 게이트(팩토리를 부르는 줄에서 던집니다).** 이름 자리(`Debounce`/`Throttle`)는 부른 쪽에 따라 바뀝니다.

```
Quad0045 Debounce: options table expected (got nil)
Quad0040 Debounce: Time is required (a number of seconds or a State<number>)
Quad0041 Debounce: Time must be a non-negative number or a State<number> (got number)
Quad0042 Debounce: Leading must be a boolean (got number)
Quad0047 Debounce: Handle must be a Ref (got table)
Quad0048 Debounce: Leading and Trailing both false would pass nothing through
Quad0046 Throttle: MaxTime is Debounce-only (a throttle already passes every Time)
```

`Time`/`MaxTime`에 State를 준 경우엔 값이 실제로 읽히는 **신호가 들어오는 시점**에 한 번 더 검사합니다(`:Set` 줄에서 던집니다 — 타이머 콜백 안에서는 읽지 않습니다. 던진 신호의 출처는 이미 보류 집합에 들어가 있어 버려지지 않고 다음 통과(다음 신호의 leading·창 끝·`Flush`)에 실려 나가며, 던진 자리가 상류 `:Set`의 전파 파동 안이라 같은 원천의 다른 구독자 중 뒤에 오는 것은 그 신호를 받지 못합니다 — [State](../core/03-state.md)의 "던진 콜백은 감싸지 않는다" 규칙 그대로). 이때의 메시지는 조금 다릅니다(그 자리엔 `State<number>` 갈래가 없으므로).

```
Quad0039 Debounce: Time must be a non-negative number (got string)
```

`:Apply` 대상이 State가 아니면 그 `:Apply` 줄에서 막습니다.

```
Quad0043 Debounce: Apply target must be a State (got table)
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
Quad0044 Debounce: Handle is already filled — one Handle Ref per :Apply (make a new Ref, or drop Handle and use the factory's :Flush()/:Cancel() broadcast; a Ref with a non-nil default is rejected the same way)
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

- [Ref](../core/07-ref.md) — `Handle`이 받는 `Ref`, 그리고 [`ref:Unwrap()`](../core/07-ref.md#refunwrap)
- [네트워크·입력 브리지](../../how-to/04-network-and-input-bridge.md) — 바깥 이벤트를 반응형 그래프로 들여올 때
- [v1에서 옮겨오기](../../how-to/08-migrating-from-v1.md)
