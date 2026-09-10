---
title: "Tween과 Animate"
description: "값-레벨 트윈 래퍼, 프로퍼티에서의 3-상태 동작(첫 세팅 스냅·Dedup·Override), :Apply 콤비네이터 Animate"
---
`Tween{…}`은 "이 값으로 애니메이션하라"를 **값 하나**로 만든 래퍼입니다. 프로퍼티 자리에 평범한
값 대신 놓으면 프로퍼티 핸들러가 엔진 트윈으로 바꿔 재생합니다. `Animate{…}`는 State 하나를
통째로 트윈으로 감싸는 [`:Apply`](/reference/core/03-state/) 콤비네이터입니다.

이 페이지의 심볼: [`q.Tween(opts)`](#qtweenopts) · [`tween:Mapped(fn)`](#tweenmappedfn) ·
[`q.isTween(x)`](#qistweenx) · [`q.Animate(info)`](#qanimateinfo) ·
[프로퍼티에서의 동작](#프로퍼티에서의-동작)

:::note
`Tween`/`isTween`/`Animate`는 `quad-roblox` 백엔드 전용입니다 — 옵션 어휘가 Roblox `TweenInfo`의
것이기 때문입니다.
:::

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadTypes = require(<quad-types 모듈 경로>)
local RobloxModule = require(<quad-roblox 모듈 경로>)
local q = Quad:UseProvider(RobloxModule.QuadRoblox)
local D = q.D
```

---

## `q.Tween(opts)`

**시그니처**

```luau
export type TweenConstructor = <T>(opts: TweenOptions<T>) -> Tween<T>

export type TweenOverride = "Cancel" | "Finish"
export type TweenOptions<T> = {
	read Value: T,                       -- 필수. 평범한 값이어야 한다
	read Info: TweenInfo?,               -- 있으면 아래 편의 필드를 전부 무시한다
	read Time: number?,
	read Style: Enum.EasingStyle?,
	read Direction: Enum.EasingDirection?,
	read RepeatCount: number?,
	read Reverses: boolean?,
	read DelayTime: number?,
	read Override: TweenOverride?,       -- 기본 "Cancel"
	read Dedup: boolean?,                -- 기본 true
}
```

**반환** — frozen `Tween<T>`. 넘긴 옵션 테이블은 **복제**되므로 호출자의 테이블을 나중에 고쳐도
만들어진 값은 그대로입니다.

**예제**

```luau
local open = q.Source(false)

local size = open:Compute(function(self: QuadTypes.StateData<boolean>): RobloxModule.Tween<UDim2>
	return q.Tween({
		Value = if self:Get() then UDim2.fromOffset(320, 200) else UDim2.fromOffset(320, 0),
		Time = 0.25,
		Style = Enum.EasingStyle.Quart,
		Direction = Enum.EasingDirection.Out,
		Override = "Finish",
	})
end)

local panel = D.Frame({ Size = size })
```

**옵션**

- **`Info`가 이깁니다.** `Info`를 주면 편의 필드(`Time`/`Style`/`Direction`/`RepeatCount`/`Reverses`/
  `DelayTime`)는 무시됩니다. 없으면 그 필드들이 `TweenInfo.new`로 조립되고, 빠진 자리에는 엔진 자신의
  기본값이 채워집니다.
- **`Override`는 문자열**입니다 — `"Cancel"`(기본) 또는 `"Finish"`. 뜻은 [프로퍼티에서의 동작](#프로퍼티에서의-동작)에서.
- **`Dedup`은 기본 켜짐**입니다(필드를 생략하면 `nil`이고 소비자가 참으로 취급). 끄려면 `Dedup = false`.

**동작 — 모든 필드는 평범한 값입니다**

`Value`에 [`State`](/reference/core/03-state/)를 넣을 수 없습니다. State를 애니메이션하고 싶으면 State
쪽을 감싸세요([`state:Apply(q.Animate{…})`](/reference/core/03-state/)) 또는 `Compute` 안에서 `Tween{…}`을
만드세요(위 예제).

**검증과 에러**

| 상황 | 문구 |
|---|---|
| 옵션이 테이블이 아님 | `Tween: expected an options table (Tween{ Value = ... })` |
| `Value` 없음 | `Tween: Value is required` |
| `Time`/`RepeatCount`/`DelayTime`이 숫자가 아님 | `Tween: {name} must be a number` |
| `Reverses`가 불린이 아님 | `Tween: Reverses must be a boolean` |
| `Dedup`이 불린이 아님 | `Tween: Dedup must be a boolean` |
| `Override`가 두 값이 아님 | `Tween: Override must be "Cancel" or "Finish"` |
| `Value`가 State | `Tween: Value must be a plain value, not a State (animate the State instead — state:Apply(Animate{...}) or state:Compute(function() return Tween{...} end))` |
| `Value`가 `None`이거나 다른 `Tween` | `Tween: Value must be a plain value, not None or another Tween (emit None itself to release the property)` |

`Info`/`Style`/`Direction`은 **생성 시점에 검사하지 않습니다** — 타입이 이미 정밀하고, 타입을 우회한
값은 엔진이 자기 에러를 냅니다(`inst[k] = 잘못된값`과 같은 부류).

`tostring(tween)`은 `Tween(10, 0.3s)`처럼 목표 값과(편의 필드로 준 경우) `Time`을 보여줍니다.

---

## `tween:Mapped(fn)`

**시그니처**

```luau
Mapped: <T, U>(self: TweenData<T>, fn: (T) -> U) -> Tween<U>
```

옵션은 그대로 두고 **`Value`만 `fn(Value)`로 바꾼** 새 Tween을 돌려줍니다. 원본은 그대로입니다.
결과는 다시 검증되므로 `fn`이 `nil`을 돌려주면 `Tween: Value is required`가 납니다.

옵션 프리셋을 상수로 두고 값만 갈아 끼우는 데 쓰면 좋습니다.

```luau
local FADE = q.Tween({ Value = 0, Time = 0.15 })

local a = FADE:Mapped(function(v: number): number return 1 end)  -- Time = 0.15 유지
local b = FADE:Mapped(function(v: number): number return 0.5 end)
```

`fn`이 함수가 아니면 `Tween:Mapped: fn must be a function (got {typeof(fn)})`.

---

## `q.isTween(x)`

**시그니처**

```luau
isTween: (x: any) -> boolean
```

그 값이 `Tween`인지 판정합니다([브랜드 검사](/reference/core/12-predicates/) — 같은 모양의 평범한 테이블은
`false`).
`State`가 실어 나르는 값을 직접 읽어 분기해야 하는 드문 자리에서 씁니다.

---

## `q.Animate(info)`

**시그니처**

```luau
export type AnimateFn = (info: AnimateInfo) -> (self: any) -> State<Tween<any>>

export type AnimateInfo = {
	-- Tween의 옵션들과 같되(Value 제외), 각 자리에 State도 올 수 있다
	read Info: (TweenInfo | StateMarker<TweenInfo>)?,
	read Time: (number | StateMarker<number>)?,
	read Style: (Enum.EasingStyle | StateMarker<Enum.EasingStyle>)?,
	read Direction: (Enum.EasingDirection | StateMarker<Enum.EasingDirection>)?,
	read RepeatCount: (number | StateMarker<number>)?,
	read Reverses: (boolean | StateMarker<boolean>)?,
	read DelayTime: (number | StateMarker<number>)?,
	read Override: (TweenOverride | StateMarker<TweenOverride>)?,
	read CanAnimate: (boolean | StateMarker<boolean>)?, -- 기본 true
	read Dedup: (boolean | StateMarker<boolean>)?,
}
```

**반환** — `:Apply`에 넘기는 팩토리. `state:Apply(q.Animate{…})`가 **State를 돌려주고**, 그 State의
값은 원래 값을 감싼 `Tween`입니다.

**예제**

```luau
local alpha = q.Source(0)
local animated = alpha:Apply(q.Animate({ Time = 0.3, Style = Enum.EasingStyle.Quad }))

local reduceMotion = q.Source(false)
local guarded = alpha:Apply(q.Animate({
	Time = 0.3,
	CanAnimate = reduceMotion:Compute(function(self: QuadTypes.StateData<boolean>): boolean
		return not self:Get()
	end),
}))

local box = D.Frame({ BackgroundTransparency = animated })
```

**동작**

- **옵션 State는 의존성이 아닙니다.** 다시 계산되는 것은 **원래 State의 값이 바뀔 때**뿐입니다.
  옵션 State가 바뀌었다고 애니메이션을 다시 돌리지 않고, **다음 값 변경 때** 최신 옵션이 반영됩니다.
- **`CanAnimate`가 거짓이면** 감싸지 않고 원래 값을 그대로 내보냅니다 — 프로퍼티 핸들러가 즉시
  씁니다(모션 축소 옵션 같은 우회로). 생략하면 항상 애니메이션합니다.
- **`nil`/[`None`](/reference/core/11-lifetime-sentinels/#qnone)은 그대로 통과합니다.** 감싸지 않으므로
  프로퍼티 핸들러가 `nil`을 씁니다(객체 참조를 놓는 경로).
- 실행마다 **새 `Tween` 값**이 만들어집니다. 같은 목표로의 재발행을 접는 것은 소비자(프로퍼티 핸들러)의
  일입니다 — 아래 `Dedup`.
- **리터럴 옵션은 `Animate(info)` 시점에 즉시 검증**됩니다(여러분의 호출 줄을 blame). State로 준
  옵션은 실행할 때마다 풀려서 그때 검증됩니다.
- 옵션이 테이블이 아니면 `Animate: expected an options table (Animate{ Time = ... })`.

---

## 프로퍼티에서의 동작

`Tween`은 디스패치에 참여하지 않는 **값**입니다. 실제 애니메이션은 프로퍼티 핸들러가 (Instance,
프로퍼티) 한 자리마다 들고 있는 상태를 보고 결정합니다.

**첫 세팅은 스냅합니다**

그 자리에 아직 아무것도 쓴 적이 없으면, 값이 `Tween`이어도 **엔진 트윈 없이 `Value`를 즉시**
씁니다. 화면에 처음 나타나는 순간에 진입 애니메이션이 도는 것을 막기 위함입니다.

```luau
-- 첫 값은 즉시 10, 그다음 Set부터 애니메이션
local size = q.Source(q.Tween({ Value = 10, Time = 0.3 }))
local box = D.Frame({ BackgroundTransparency = size })
```

**같은 목표는 다시 재생하지 않습니다 — `Dedup`**

들어온 `Tween`의 **`Value`가 그 자리에 기록된 목표와 같으면** 아무 일도 하지 않습니다. 돌고 있는
트윈은 계속 돌고, 끝난 트윈을 다시 트리거하지도 않습니다.

- 비교 대상은 **`Value`뿐**입니다 — `Time`/`Style` 같은 옵션은 비교하지 않습니다.
- 비교는 **값 동등**입니다(엔진의 `==`). `UDim.new(0, 8)` 두 개는 같은 값입니다.
- `Tween{ Dedup = false }`로 끄면 같은 목표라도 매번 다시 시작합니다.
- 평범한 값이 쓰인 자리에는 기록된 목표가 없으므로, 거기 도착한 `Tween`은 언제나 재생됩니다.

**교체 순서와 `Override`**

돌고 있는 엔진 트윈은 **새 값이 쓰이기 전에 취소**됩니다(엔진이 비동기로 계속 쓰기 때문).
그다음 **들어오는 쪽의 `Override`**를 봅니다.

| `Override` | 뜻 |
|---|---|
| `"Cancel"`(기본) | 지금 보간된 값에서 이어서 새 트윈을 시작한다 |
| `"Finish"` | 이전 트윈의 목표 값으로 **먼저 스냅**한 뒤 새 트윈을 시작한다 |

평범한 값이 들어오면 취소만 하고 그 값을 씁니다.

---

**관련**

- [D — 해시 부분](/reference/roblox/02-d/#해시-부분--프로퍼티와-이벤트) — Tween 팔이 있는 프로퍼티
- [11. 움직이게 하기 — `Tween`과 `Animate`](/getting-started/11-animation/)
- [05. 테마와 동적 스타일링](/how-to/05-theme-and-dynamic-styling/)
