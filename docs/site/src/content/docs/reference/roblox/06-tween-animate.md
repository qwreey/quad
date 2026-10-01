---
title: "Tween과 Animate"
description: "값-레벨 트윈 래퍼, 프로퍼티에서의 3-상태 동작(첫 세팅 스냅·Dedup·Override), :Apply 콤비네이터 Animate"
---
`Tween{…}`은 "이 값으로 애니메이션하라"를 **값 하나**로 만든 래퍼입니다. 프로퍼티 자리에 평범한
값 대신 놓으면 프로퍼티 핸들러가 엔진 트윈으로 바꿔 재생합니다. `Animate{…}`는 State 하나를
통째로 트윈으로 감싸는 [`:Apply`](/reference/core/03-state/) 콤비네이터입니다.

이 페이지의 심볼: [`q.Tween(opts)`](#qtweenopts) · [`tween:Mapped(fn)`](#tweenmappedfn) · [`tween:Wrapped(wrap)`](#tweenwrappedwrap) ·
[`q.isTween(x)`](#qistweenx) · [`q.Animate(info)`](#qanimateinfo) ·
[프로퍼티에서의 동작](#프로퍼티에서의-동작)

:::note
`Tween`/`isTween`/`Animate`는 `quad-roblox` 백엔드 전용입니다 — 옵션 어휘가 Roblox `TweenInfo`의
것이기 때문입니다.
:::

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local RobloxModule = require("@game/ReplicatedStorage/roblox_packages/quad_roblox") -- `Tween<T>` 타입
local D = q.Declaration
```

---

## `q.Tween(opts)`

`opts`의 모르는 키는 조용히 무시됩니다(`q.Animate`도 같음). `q.debug = true`면 모르는 옵션 키(오타·옛 이름)를 한 줄로 알려 줍니다 — 정본은 [`q.debug`](/reference/core/01-quad-module/#qdebug).

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
	read Started: TweenCallback<T>?,     -- 콜백 셋 — 뜻은 아래 "프로퍼티에서의 동작"
	read Completed: TweenCallback<T>?,
	read Cancelled: TweenCallback<T>?,
}

export type TweenCallback<T> = (inst: Instance, prop: string, value: T) -> ()
```

**반환** — frozen `Tween<T>`. 넘긴 옵션 테이블은 **복제**되므로 호출자의 테이블을 나중에 고쳐도
만들어진 값은 그대로입니다.

**예제**

```luau
local open = q.Source(false)

local size: q.State<RobloxModule.Tween<UDim2>> = open:Compute(function(self: q.StateData<boolean>): RobloxModule.Tween<UDim2>
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
- **`Started`/`Completed`/`Cancelled`는 `(inst, prop, value)`를 받는 함수**입니다 — 인자가 필요 없으면 `function() … end`로 적어도 됩니다. 언제 불리는지는 [프로퍼티에서의 동작](#프로퍼티에서의-동작)에서. `:Mapped(fn)`로 만든 값에도 그대로 실리고(그때 `value`는 매핑된 값), 콜백만 바꾼 사본은 [`tween:Wrapped`](#tweenwrappedwrap)로 만듭니다.
- **`Info` 없이 `Time = 0`이고 `DelayTime`/`RepeatCount`/`Reverses`도 없으면(또는 0·거짓) 엔진 트윈을 만들지 않고 값을 그 자리에서 씁니다** — 첫 세팅과 같은 스냅이라 콜백도 스냅 규칙을 따릅니다. 그 셋 중 하나라도 있으면 평소대로 엔진 트윈입니다.

**동작 — 모든 필드는 평범한 값입니다**

`Value`에 [`State`](/reference/core/03-state/)를 넣을 수 없습니다. State를 애니메이션하고 싶으면 State
쪽을 감싸세요([`state:Apply(q.Animate{…})`](/reference/core/03-state/)) 또는 `Compute` 안에서 `Tween{…}`을
만드세요(위 예제).

**검증과 에러**

| 상황 | 문구 |
|---|---|
| 옵션이 테이블이 아님 | `Quad0248 Tween: options must be a table, e.g. Tween{ Value = ... } (got {typeof(opts)})` |
| `Value` 없음 | `Quad0249 Tween: Value is required` |
| `Time`/`RepeatCount`/`DelayTime`이 숫자가 아님 | `Quad0243 Tween: {name} must be a number (got {typeof(v)})` |
| `Reverses`가 불린이 아님 | `Quad0244 Tween: Reverses must be a boolean (got {typeof(opts.Reverses)})` |
| `Dedup`이 불린이 아님 | `Quad0245 Tween: Dedup must be a boolean (got {typeof(opts.Dedup)})` |
| `Override`가 두 값이 아님 | `Quad0247 Tween: Override must be "Cancel" or "Finish"` |
| `Started`/`Completed`/`Cancelled`가 함수가 아님 | `Quad0246 Tween: {name} must be a function (got {typeof(v)})` |
| `Value`가 State | `Quad0250 Tween: Value must be a plain value, not a State (animate the State instead - state:Apply(Animate{...}) or state:Compute(function() return Tween{...} end))` |
| `Value`가 `None`이거나 다른 `Tween` | `Quad0251 Tween: Value must be a plain value, not None or another Tween (emit None itself to release the property)` |

`Info`/`Style`/`Direction`은 **생성 시점에 검사하지 않습니다** — 타입이 이미 정밀하고, 타입을 우회한
값은 엔진이 자기 에러를 냅니다(`inst[k] = 잘못된값`과 같은 부류).

`tostring(tween)`은 `Tween(10, 0.3s)`처럼 목표 값과(편의 필드로 준 경우) `Time`을 보여줍니다.

---

## `tween:Mapped(fn)`

**시그니처**

```luau
Mapped: <T, U>(self: TweenData<T>, fn: (T) -> U, wrap: ((cb: TweenCallbackHandle) -> TweenCallbacks)?) -> Tween<U>
```

옵션은 그대로 두고 **`Value`만 `fn(Value)`로 바꾼** 새 Tween을 돌려줍니다. 원본은 그대로입니다. 콜백은 그대로 복사됩니다. 둘째 인자 `wrap`을 주면 콜백 셋도 같은 사본에서 바꿉니다 — 뜻은 [`tween:Wrapped`](#tweenwrappedwrap)와 같고, 값과 콜백을 한 번에 바꾸는 빠른 경로입니다(사본 하나).
결과는 다시 검증되므로 `fn`이 `nil`을 돌려주면 `Quad0249 Tween: Value is required`가 납니다.

옵션 프리셋을 상수로 두고 값만 갈아 끼우는 데 쓰면 좋습니다.

```luau
local FADE = q.Tween({ Value = 0, Time = 0.15 })

local a = FADE:Mapped(function(v: number): number return 1 end)  -- Time = 0.15 유지
local b = FADE:Mapped(function(v: number): number return 0.5 end)
```

`fn`이 함수가 아니면 `Quad0227 Tween:Mapped: fn must be a function (got {typeof(fn)})`.

---

## `tween:Wrapped(wrap)`

**시그니처**

```luau
Wrapped: <T>(self: TweenData<T>, wrap: (cb: TweenCallbackHandle) -> TweenCallbacks) -> Tween<T>

export type TweenCallbacks = {
	read Started: TweenCallback<any>?,
	read Completed: TweenCallback<any>?,
	read Cancelled: TweenCallback<any>?,
}
export type TweenCallbackHandle = TweenCallbacks & {
	Map: (self: TweenCallbacks, g: (f: TweenCallback<any>) -> TweenCallback<any>?) -> TweenCallbacks,
}
```

값은 그대로 두고 **콜백 셋만 `wrap`이 돌려준 것으로 바꾼** 새 Tween을 돌려줍니다. `wrap`은 한 번 불리고, 원본의 콜백 셋을 보는 핸들 `cb`를 받습니다 — `cb.Started`/`cb.Completed`/`cb.Cancelled`는 원본 함수(없으면 `nil`)이고, `cb:Map(g)`는 있는 콜백마다 `g(f)`를 적용한 새 셋입니다. **돌려준 셋이 사본의 콜백 셋 전체**입니다 — 빠뜨린 필드는 콜백이 없고, 원본에 없던 콜백을 새로 붙일 수도 있습니다. 돌려준 셋이 원본과 같은 함수 셋이면 사본을 만들지 않고 원본을 돌려줍니다(Tween은 값이라 신원에 기대는 곳이 없습니다).

같은 Tween을 여러 자리에 걸면 콜백도 자리마다 불립니다. 한 번만 반응하려면 `prop`으로 거르세요.

```luau
local fade = q.Tween({
	Value = 0,
	Time = 0.2,
	Completed = function(_inst, _prop, _value) onFaded() end,
})
-- BackgroundTransparency와 TextTransparency 둘에 걸되, 완료는 BackgroundTransparency에서만 알린다
local once = fade:Wrapped(function(cb)
	return cb:Map(function(f)
		return function(inst, prop, value)
			if prop == "BackgroundTransparency" then f(inst, prop, value) end
		end
	end)
end)
```

`wrap`이 함수가 아니면 `Quad0256`, 테이블이 아닌 것을 돌려주면 `Quad0257`, `cb:Map`의 `g`가 함수가 아니면 `Quad0258`입니다. 돌려준 셋의 값은 `q.Tween`의 콜백과 같은 규칙으로 검사합니다(`Quad0246`).

---

## `q.isTween(x)`

**시그니처**

```luau
isTween: (x: any) -> boolean
```

그 값이 `Tween`인지 판정합니다([브랜드 검사](/reference/core/11-predicates/) — 같은 모양의 평범한 테이블은
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
	read Started: TweenCallback<any>?,   -- Tween에 그대로 실린다(State 불가)
	read Completed: TweenCallback<any>?,
	read Cancelled: TweenCallback<any>?,
}
```

**반환** — `:Apply`에 넘기는 팩토리. `state:Apply(q.Animate{…})`가 **State를 돌려주고**, 그 State의
값은 원래 값을 감싼 `Tween`입니다.

**예제**

```luau
local alpha = q.Source(0)
local animated: q.State<RobloxModule.Tween<number>> = alpha:Apply(q.Animate({ Time = 0.3, Style = Enum.EasingStyle.Quad }))

local reduceMotion = q.Source(false)
local guarded = alpha:Apply(q.Animate({
	Time = 0.3,
	CanAnimate = reduceMotion:Compute(function(self: q.StateData<boolean>): boolean
		return not self:Get()
	end),
}))

local box = D.Frame({ BackgroundTransparency = animated })
```

**동작**

- **옵션 State는 의존성이 아닙니다.** 다시 계산되는 것은 **원래 State의 값이 바뀔 때**뿐입니다.
  옵션 State가 바뀌었다고 애니메이션을 다시 돌리지 않고, **다음 값 변경 때** 최신 옵션이 반영됩니다.
- **`CanAnimate`가 거짓이면** 감싸지 않고 원래 값을 그대로 내보냅니다 — 프로퍼티 핸들러가 즉시
  씁니다(모션 축소 옵션 같은 우회로). 생략하면 항상 애니메이션합니다. 단 **콜백이 하나라도 있으면**
  `Time = 0`인 `Tween`으로 내보냅니다 — 프로퍼티 핸들러가 엔진 트윈 없이 값을 찍고 `Started`·`Completed`를
  그 자리에서 부르므로, 모션을 껐어도 "끝났을 때"의 처리는 그대로 돕니다. 이때 `DelayTime` 같은 다른 옵션은
  싣지 않습니다(모션이 꺼진 것이니 즉시).
- **`nil`/[`None`](/reference/core/10-lifetime-sentinels/#qnone)은 그대로 통과합니다.** 감싸지 않으므로
  프로퍼티 핸들러가 `nil`을 씁니다 — 보간 가능한 타입은 전부 엔진이 `nil`을 거부하므로 실제로 쓰이는 자리는 드물고, `nil` 발행에는 `CanAnimate = false`의 `Started`/`Completed` 콜백도 불리지 않습니다(돌던 트윈의 `Cancelled`는 옵니다 — [2026-09-27 mock 관측]).
- 실행마다 **새 `Tween` 값**이 만들어집니다. 같은 목표로의 재발행을 접는 것은 소비자(프로퍼티 핸들러)의
  일입니다 — 아래 `Dedup`.
- **리터럴 옵션은 `Animate(info)` 시점에 즉시 검증**됩니다(여러분의 호출 줄을 blame). State로 준
  옵션은 실행할 때마다 풀려서 그때 검증됩니다.
- 옵션이 테이블이 아니면 `Quad0214 Animate: options must be a table, e.g. Animate{ Time = ... } (got {typeof(info)})`.
- **콜백 셋(`Started`/`Completed`/`Cancelled`)은 State로 줄 수 없습니다** — `Animate(info)` 줄에서 `Quad0246`으로 거부됩니다(애니메이션 여부와 무관하게 같은 규칙).
- `CanAnimate`가 불리언도 State도 아니면(`"no"`·`0`·함수 등) `Quad0253 Animate: CanAnimate must be a boolean or a State<boolean> (got {typeof(v)})`로 거부됩니다 — State가 불리언이 아닌 값을 쥐면 그 값으로 실행할 때 `Quad0254`입니다(`nil`은 생략과 같아 항상 애니메이션).
- `Animate`는 **State의 `:Apply` 전용**입니다. Modifier·Tag의 `:Apply`에 넣으면 `Quad0252 Animate: Apply target must be a State (got Modifier)`로 거부됩니다. Modifier setter의 변환 함수 자리에 넣어도 그 필드가 비었거나 평범한 값이면 같은 에러(괄호는 그 옛 값의 타입)지만, 필드가 이미 State를 쥐고 있으면 setter가 그 State의 `:Compute`로 변환을 부르므로 거부되지 않고 State 안에 State가 든 모양이 조용히 만들어집니다 — 정의되지 않은 동작입니다. 어느 쪽이든 그 필드에 흘리는 State 쪽에 `:Apply(q.Animate{ … })`를 붙이세요.

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
- **비교 대상은 기록된 목표이지, 프로퍼티의 실제 값이 아닙니다.** 그래서 기록된 뒤 프로퍼티가 quad 밖에서 바뀌었으면(사용자 드래그·스크롤 같은 엔진 쓰기, 코드의 직접 대입) 같은 목표를 다시 보내도 건너뛰어 그 값으로 돌아가지 않습니다. `Reverses = true` 트윈도 같습니다 — 끝나면 프로퍼티는 시작값에 서 있지만 기록은 목표라, 같은 목표로 다시 재생하려는 두 번째부터 건너뜁니다. 이런 자리에서 같은 목표로 다시 재생하려면 `Dedup = false`를 주세요([드래그 뒤 제자리로 돌아가는 관용구](/how-to/04-network-and-input-bridge/#끌어다-놓으면-제자리로-돌아가는-카드)). [2026-10-01 mock 실측]
- 평범한 값이 쓰인 자리에는 기록된 목표가 없으므로, 거기 도착한 `Tween`은 언제나 재생됩니다.
- 건너뛴 `Tween`의 콜백은 버려집니다 — 끝까지 가는 콜백은 **그 트윈을 실제로 시작시킨 값**의 것입니다.

**교체 순서와 `Override`**

돌고 있는 엔진 트윈은 **새 값이 쓰이기 전에 취소**됩니다(엔진이 비동기로 계속 쓰기 때문).
그다음 **들어오는 쪽의 `Override`**를 봅니다.

| `Override` | 뜻 |
|---|---|
| `"Cancel"`(기본) | 지금 보간된 값에서 이어서 새 트윈을 시작한다 |
| `"Finish"` | 이전 트윈의 목표 값으로 **먼저 스냅**한 뒤 새 트윈을 시작한다 |

평범한 값이 들어오면 취소만 하고 그 값을 씁니다.

**자리가 철거될 때는 진행 중인 트윈만 취소합니다 — 기록은 남습니다**

트윈이 흐르던 자리 자체가 철거되면(숏핸드 `UICorner = …`를 `nil`로 내려 관리 자식이 파괴될 때, `q.Dispatch.retractFrom`) 돌고 있던 엔진 트윈을 **취소**합니다 — 파괴된 인스턴스를 향해 트윈이 계속 돌지 않습니다. 이때는 들어오는 값이 없으므로 `Override`는 보지 않습니다(값이 그 자리에서 멈춥니다). "첫 세팅은 스냅"의 기준은 **quad가 그 인스턴스의 그 프로퍼티를 처음 쓰는가**라서, 철거해도 "쓴 적 있음"은 남고 나중에 같은 자리에 오는 `Tween`은 애니메이션합니다. 취소 순간 프로퍼티가 목표값에 못 미쳤으면 그 목표만 잊어(같은 목표를 다시 선언해도 재생됨), 이미 목표값을 쥐고 있었으면(트윈이 끝난 뒤) 그 기록은 그대로라 같은 목표는 무동작입니다.

**시작·완료·취소를 알립니다 — `Started` / `Completed` / `Cancelled`**

세 콜백은 `(inst, prop, value)` — 그 트윈이 도는 인스턴스, 프로퍼티 이름, 그 Tween의 목표 값 — 를 받고, 부르는 쪽은 프로퍼티 핸들러입니다. **모든 콜백은 그 자리의 기록을 마친 뒤에 불립니다** — 그래서 콜백 안에서 같은 자리를 다시 써도 순서가 흐트러지지 않습니다(아래). 인스턴스의 프로퍼티 값 자체는 별개입니다 — 엔진 트윈이 막 시작된 `Started` 안이라면 아직 움직이기 전 값입니다.

| 콜백 | 불리는 때 |
|---|---|
| `Started` | 엔진 트윈을 재생한 **직후, 동기로**. 스냅(첫 세팅, 또는 `Info` 없는 `Time = 0`)에서는 값을 찍은 뒤 `Completed` 바로 앞에 |
| `Completed` | 트윈이 **자연히 끝났을 때만**(엔진 `Completed` 시그널의 `PlaybackState.Completed`) — 엔진이 그 시그널을 미루는 만큼 뒤에 옵니다. 스냅에서는 동기로. 도는 사이 인스턴스가 **파괴됐으면 불리지 않습니다**(아래) |
| `Cancelled` | quad가 **돌고 있던** 트윈을 끊는 그 자리에서 **동기로** — 새 값이 들어와 교체될 때와 자리가 철거될 때. 교체 때 이미 끝난 트윈에는 불리지 않습니다(엔진이 목표에 닿았지만 통지가 아직 안 온 사이에 교체가 오면 `Completed`가 그 자리에서 불립니다). **철거 때는 목표에 닿고 통지만 남은 트윈도 `Cancelled`입니다** — 사라지는 자리의 트윈이 막 끝났는지는 가리지 않습니다(이미 `Completed`를 받은 트윈은 철거 때 아무것도 받지 않습니다) |

그래서 교체 순서는 항상 **이전 `Cancelled`(통지 대기 중이었으면 이전 `Completed`) → 새 `Started` → (나중에) 새 `Completed`**입니다. 엔진의 취소 통지는 미뤄져서(다음 yield) 동기 교체에서는 새 트윈이 시작된 **뒤에** 도착하고, 이미 끝난 트윈에 `Cancel`을 해도 한 번 더 납니다 — quad는 그 통지를 쓰지 않고 자기 `Cancel` 호출 자리에서 직접 부르며, `Completed` 연결은 한 번 불린 뒤 스스로 끊습니다. 같은 목표라 건너뛴 `Tween`(`Dedup`)은 아무것도 부르지 않습니다.

**인스턴스가 먼저 파괴되면** — 파괴는 자리별 되돌리기를 거치지 않으므로([20장](/getting-started/20-handlers/)) 돌던 트윈은 끊기지 않고 파괴된 인스턴스 위에서 끝까지 돕니다. `Cancelled`는 오지 않고, 그 뒤 엔진이 보내는 완료 통지는 인스턴스가 더는 quad의 것이 아니므로 **무시됩니다** — `Completed`도 불리지 않습니다. 파괴된 인스턴스의 자리를 직접 되돌려도(`q.Dispatch.retractFrom`) 콜백은 불리지 않습니다(트윈은 끊깁니다). 새 값으로 교체하거나 자리를 철거할 때만 `Cancelled`입니다. 콜백과 그 클로저가 잡은 값은 트윈이 끝나거나 끊기는 순간 놓입니다 — 다만 **끝나지 않는 트윈**(`RepeatCount = -1`)은 파괴로는 끊기지 않으니, 파괴 전에 값을 바꾸거나 자리를 철거해 끊으세요.

**콜백 안에서 같은 프로퍼티를 다시 써도 됩니다** — 다음 트윈을 잇는 흔한 자리는 `Completed`이지만, 기록을 마친 뒤에 불리므로 `Started`·`Cancelled`에서 같은 자리에 묶인 State를 `:Set`해도 그 쓰기가 마지막으로 남고 끊기지 않는 트윈도 남지 않습니다. 앞선 콜백이 같은 자리를 새 값으로 바꾸면, 바뀌어 버린 값은 `Started` 없이 `Cancelled`만 받거나(엔진 트윈) 아무것도 받지 않습니다(스냅). 예외 하나 — 마운트 중 첫 세팅(스냅)의 `Started` 안에서 같은 State를 `:Set`하면 화면이 따라가지 않을 수 있습니다(정의되지 않은 동작).

**콜백이 던지면** — 에러는 그 콜백을 부른 줄(값을 바꾼 `:Set` 등)로 나옵니다. 그 뒤 그 자리의 상태는 정해져 있지 않습니다 — quad는 던진 콜백을 복구하지 않습니다(정의되지 않은 동작). 관측(계약 아님): 같은 전이에서 던진 콜백 뒤에 올 콜백(새 값의 `Started` 등)은 불리지 않았고, 다음 값보다 철거가 먼저 오면 그 트윈이 끊기지 않고 끝까지 돌 수 있었습니다. 다음 값이 오면 이어지는 것처럼 보이는 경우가 많지만, 던지기 전과 같은 목표를 다시 보내면 중간값에 머무는 경우도 관측돼 기대어서는 안 됩니다.

**숏핸드([02장](/reference/roblox/02-d/#숏핸드-키-넷))에 건 Tween의 콜백은 값 하나에 한 번**, `(숏핸드를 건 인스턴스, "UICorner"·"UIPadding" 같은 숏핸드 키, 여러분이 준 값)`으로 불립니다 — 네 숏핸드 모두 같고, 관리 자식의 프로퍼티 넷에 같은 Tween을 거는 `UIPadding`/`UIPaddingOffset`은 마지막 프로퍼티(`PaddingBottom`)가 보고할 때 부릅니다. 반면 **같은 Tween/State를 프로퍼티 둘 이상에 직접 걸면 자리마다 한 번씩**, 각자의 `prop`으로 불립니다 — 한 번만 반응하려면 `prop`으로 거르거나 [`tween:Wrapped`](#tweenwrappedwrap)로 감싸세요.

**인자는 부르는 순간 읽습니다** — 엔진 트윈의 연결은 인스턴스를 클로저로 잡지 않고, 발화 때 트윈이 원래 쥔 인스턴스를 읽어 넘깁니다. 그래서 인자를 받는다고 인스턴스 수명이 늘지 않습니다(연결은 기록이 트윈을 쥐는 동안 살아 있고, Luau의 약한 키 테이블은 ephemeron이 아니라서 포획이었다면 인스턴스가 수거되지 않았을 것입니다). 받은 `inst`를 오래 쥐는 것은 여러분 클로저의 일입니다 — 오래 필요한 값은 [원천을 거쳐 프로퍼티로 흘리는 모양](/getting-started/17-animation/#끝났을-때-알기--startedcompletedcancelled)을 권합니다.

---

**관련**

- [D — 문자 키](/reference/roblox/02-d/#문자-키--프로퍼티와-이벤트) — Tween 팔이 있는 프로퍼티
- [17. 움직이게 하기 — `Tween`과 `Animate`](/getting-started/17-animation/)
- [05. 디자인 토큰과 테마 전환](/how-to/05-theme-and-dynamic-styling/)
