---
title: Blocker
description: 값 기반 전파 유보 — On/Off/OffWithoutEmit/Policy와 state:Apply(blocker)
---
# Blocker

`Blocker`는 **전파를 잠시 붙잡아 두는 스위치**입니다. 여러 값을 한 번에 바꿀 때 중간 상태가 하류로 새는 걸 막고, 다 바꾼 뒤 **한 번만** 통지하고 싶을 때 씁니다.

`Blocker` 자체는 새 메커니즘이 아니라 [`state:Gate(setup)`](../core/03-state.md#stategatesetup) 위에 얹힌 **정책**입니다 — 게이트 계약(무엇이 유보되고 `emit`이 무엇을 하는지)은 그쪽이 정본이고, 이 페이지는 그 위의 스위치만 다룹니다.

이 페이지의 심볼: [`q.Blocker()`](#qblocker) · [`blocker.IsBlocked`](#blockerisblocked) · [`blocker:IsOn()`](#blockerison) · [`blocker:On()`](#blockeron) · [`blocker:Off()`](#blockeroff) · [`blocker:OffWithoutEmit()`](#blockeroffwithoutemit) · [`blocker:Policy(emit)`](#blockerpolicyemit) · [`state:Apply(blocker)`](#stateapplyblocker)

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
```

---

## `q.Blocker()`

**시그니처**

```luau
Blocker: () -> Blocker

export type Blocker = {
	IsBlocked: boolean,
	IsOn: (self: Blocker) -> boolean,
	On: (self: Blocker) -> Blocker,
	Off: (self: Blocker) -> Blocker,
	OffWithoutEmit: (self: Blocker) -> Blocker,
	Policy: (self: Blocker, emit: GateEmit) -> () -> (),
	__apply: (self: any, state: any) -> any,
}
```

**반환** — 꺼진 상태(`IsBlocked = false`)의 새 `Blocker`.

**동작**

- 하나의 `Blocker`를 **여러 노드에 붙일 수 있습니다**. `:Off()` 한 번이 붙어 있는 게이트 전부를 풉니다.
- 게이트 쪽 등록은 약하게 잡습니다 — 게이트 노드가 사라지면 그 등록도 같이 사라집니다. `Blocker`가 게이트를(그리고 그 상류 사슬을) 붙잡아 두지 않습니다.
- `print(blocker)`는 `Blocker(on)` / `Blocker(off)`로 찍힙니다.

**예제**

```luau
local hp = q.Source(100)
local mp = q.Source(50)
local blocker = q.Blocker()

local shownHp: q.State<number> = hp:Apply(blocker)
local shownMp: q.State<number> = mp:Apply(blocker)

blocker:On()
hp:Set(80)
mp:Set(40) -- 아직 아무도 통지받지 않았다
blocker:Off() -- 두 게이트가 각각 한 번씩 통지
```

**관련** — [03-state](../core/03-state.md#stategatesetup) · [05-observer-effect](../core/05-observer-effect.md)

---

## `blocker.IsBlocked`

`boolean` 필드 — 지금 막고 있는지. **평범한 불리언이지 카운터가 아닙니다.**

그래서 **같은 `Blocker`를 겹쳐 잠그는 것은 지원하지 않습니다** — 안쪽 구간이 `:Off()`를 부르면 바깥 구간이 아직 끝나지 않았어도 풀립니다. 겹치는 구간이 필요하면 구간마다 별도의 `Blocker`를 만드세요.

"유보된 게 있는가"를 알려주는 필드는 없습니다. 그 정보는 게이트의 `emit(commit)` 반환값이 유일한 통로입니다([03-state](../core/03-state.md#stategatesetup)).

---

## `blocker:IsOn()`

**시그니처** — `IsOn: (self: Blocker) -> boolean`

`IsBlocked`를 그대로 읽는 얇은 접근자입니다.

---

## `blocker:On()`

**시그니처** — `On: (self: Blocker) -> Blocker` (self 반환)

**동작** — 플래그를 올립니다. 그게 전부입니다 — 이 시점 이후 붙어 있는 게이트들에 도착하는 emit이 각자의 흡수 집합에 쌓입니다. **값은 막지 않습니다**: 유보 중에도 하류의 `:Get()`은 최신 값을 봅니다.

---

## `blocker:Off()`

**시그니처** — `Off: (self: Blocker) -> Blocker` (self 반환)

**동작**

1. 먼저 플래그를 내립니다(푸는 도중 재진입한 흐름이 열린 상태를 보도록).
2. 등록된 핸들 목록의 **스냅샷**을 뜬 뒤 순회하며 각 게이트를 flush합니다 — 게이트마다 쌓인 배치가 **한 번의 통지**로 나갑니다. 쌓인 게 없는 게이트에서는 아무 일도 없습니다.
3. 순회 도중 누군가(방금 flush로 깨어난 하류가) 이 `Blocker`를 **다시 잠그면 거기서 멈춥니다**. 남은 게이트들은 유보분을 그대로 들고 다음 `:Off()`를 기다립니다.

---

## `blocker:OffWithoutEmit()`

**시그니처** — `OffWithoutEmit: (self: Blocker) -> Blocker` (self 반환)

**동작** — `:Off()`와 같은 경로를 돌되 **쌓인 배치를 버립니다**. 통지도, 기록도 없습니다.

버린 뒤에도 그래프는 망가지지 않습니다 — 하류의 값은 어차피 `:Get()` 시점에 최신으로 맞춰지고, 그 다음에 오는 진짜 emit은 정상적으로 흐릅니다.

**예제**

```luau
local hp = q.Source(100)
local blocker = q.Blocker()
local shown: q.State<number> = hp:Apply(blocker)

blocker:On()
hp:Set(80)
blocker:OffWithoutEmit() -- 80이라는 통지는 나가지 않는다
print(shown:Get()) --> 80 (값은 언제나 최신)
```

---

## `blocker:Policy(emit)`

**시그니처**

```luau
Policy: (self: Blocker, emit: GateEmit) -> () -> ()
export type GateEmit = (commit: boolean?) -> boolean
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `emit` | `GateEmit` | 게이트가 `setup`에 넘겨준 flush 함수. |

**반환** — 게이트의 `onUpstreamEmit`(상류 emit마다 불릴 클로저).

**동작**

- 이 `Blocker`의 정책을 **값으로** 꺼내 직접 게이트에 배선할 때 씁니다. `state:Apply(blocker)`가 내부에서 하는 일이 바로 이것이라, 특별한 사정이 없다면 `Apply` 쪽을 쓰면 됩니다.
- **부르는 그 자리에서** 이 `Blocker`에 해제 핸들을 등록합니다(약한 등록). 그 핸들의 강한 주인은 반환된 클로저이므로, 게이트가 살아 있는 동안만 핸들도 삽니다.
- `emit`이 함수가 아니면 그 자리에서 거절합니다:
  `Blocker: Policy emit must be a function (got {typeof(emit)})`

**예제**

```luau
local hp = q.Source(100)
local blocker = q.Blocker()

-- state:Apply(blocker)와 동등한 수동 배선
local gated: q.State<number> = hp:Gate(function(emit)
	return blocker:Policy(emit)
end)
```

---

## `state:Apply(blocker)`

`Blocker`는 `__apply`를 가진 애플리커티브 팩토리이므로 [`state:Apply`](../core/03-state.md#stateapplyfactory)의 객체 팔로 붙습니다. 정확히 다음과 같습니다:

```luau
state:Apply(blocker)
-- ≡
state:Gate(function(emit)
	return blocker:Policy(emit)
end)
```

**반환** — 같은 `T`의 게이트된 `State<T>`. 객체 팔의 반환 타입이 `any`이므로 **결과 타입은 호출부에서 명시**하세요:

```luau
local gated: q.State<number> = hp:Apply(blocker)
```

붙이지 않은 `Blocker`는 아무 일도 하지 않습니다 — `:On()`/`:Off()`는 **붙어 있는 게이트**를 통해서만 효과를 냅니다.

**관련** — [03-state](../core/03-state.md) · [05-observer-effect](../core/05-observer-effect.md) · [How-To 03 가상 스크롤](../../how-to/03-virtualized-infinite-scroll.md)
