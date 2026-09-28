---
title: "에러 코드 — Roblox: Tween·Animate"
description: "Tween/Animate가 던지는 에러"
---
# [레퍼런스] 에러 코드 — Roblox: Tween·Animate

각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](./00-index.md).


### Quad0214

`Animate: options must be a table, e.g. Animate{ Time = ... } (got {typeof(info)})` — `quad-roblox/src/Animate.luau`

- **언제**: `q.Animate(info)`의 `info`가 테이블이 아닐 때. 리터럴 옵션은 `Animate(info)` 호출 시점에 즉시 검증되고, `State`로 준 옵션은 실행할 때마다 풀려서 그때 검증됩니다.
- **고치려면**: `q.Animate{ Time = ... }` 모양으로 테이블을 넘기세요.
- **참고**: [`q.Animate(info)`](../roblox/06-tween-animate.md#qanimateinfo)

### Quad0227

`Tween:Mapped: fn must be a function (got {typeof(fn)})` — `quad-roblox/src/Tween.luau`

- **언제**: `tween:Mapped(fn)`의 `fn`이 함수가 아닐 때.
- **고치려면**: 목표 값을 받아 새 목표 값을 돌려주는 함수를 넘기세요.
- **참고**: [`tween:Mapped(fn)`](../roblox/06-tween-animate.md#tweenmappedfn)

### Quad0256

`Tween:{method}: wrap must be a function (got {typeof(wrap)})` — `quad-roblox/src/Tween.luau`

- **언제**: `tween:Mapped(fn, wrap)`의 둘째 인자나 `tween:Wrapped(wrap)`의 `wrap`이 함수가 아닐 때. `{method}`는 `Mapped` 또는 `Wrapped`입니다.
- **고치려면**: 콜백 핸들 `cb`를 받아 새 콜백 셋 `{ Started = …, Completed = …, Cancelled = … }`을 돌려주는 함수를 넘기세요. 콜백을 바꿀 필요가 없으면 `Mapped`의 둘째 인자를 빼세요.
- **참고**: [`tween:Wrapped(wrap)`](../roblox/06-tween-animate.md#tweenwrappedwrap) · [`tween:Mapped(fn)`](../roblox/06-tween-animate.md#tweenmappedfn)

### Quad0257

`Tween:{method}: wrap must return a callback set table (got {typeof(set)})` — `quad-roblox/src/Tween.luau`

- **언제**: `wrap(cb)`가 테이블이 아닌 값을 돌려줬을 때(흔히 `return`을 빠뜨려 `nil`).
- **고치려면**: 새 콜백 셋 테이블을 돌려주세요 — `return cb:Map(function(f) return … end)`나 `return { Completed = … }`. 셋에 없는 필드는 "콜백 없음"입니다.
- **참고**: [`tween:Wrapped(wrap)`](../roblox/06-tween-animate.md#tweenwrappedwrap) · [`tween:Mapped(fn)`](../roblox/06-tween-animate.md#tweenmappedfn)

### Quad0258

`Tween callbacks:Map: g must be a function (got {typeof(g)})` — `quad-roblox/src/Tween.luau`

- **언제**: `wrap` 안에서 콜백 핸들의 `cb:Map(g)`에 함수가 아닌 값을 넘겼을 때.
- **고치려면**: 원래 콜백 `f`를 받아 새 콜백(또는 `nil`)을 돌려주는 함수를 넘기세요.
- **참고**: [`tween:Wrapped(wrap)`](../roblox/06-tween-animate.md#tweenwrappedwrap) · [`tween:Mapped(fn)`](../roblox/06-tween-animate.md#tweenmappedfn)

### Quad0243

`Tween: {name} must be a number (got {typeof(v)})` — `quad-roblox/src/Tween.luau`

- **언제**: `Time`/`RepeatCount`/`DelayTime` 중 하나가 숫자가 아닌 값으로 주어졌을 때. `{name}`은 실제 필드 이름입니다.
- **고치려면**: 숫자를 넘기세요.
- **참고**: [`q.Tween(opts)`](../roblox/06-tween-animate.md#qtweenopts)

### Quad0244

`Tween: Reverses must be a boolean (got {typeof(opts.Reverses)})` — `quad-roblox/src/Tween.luau`

- **언제**: `Reverses`가 불린이 아닌 값으로 주어졌을 때.
- **고치려면**: `true`/`false`만 넘기세요.
- **참고**: [`q.Tween(opts)`](../roblox/06-tween-animate.md#qtweenopts)

### Quad0245

`Tween: Dedup must be a boolean (got {typeof(opts.Dedup)})` — `quad-roblox/src/Tween.luau`

- **언제**: `Dedup`이 불린이 아닌 값으로 주어졌을 때.
- **고치려면**: `true`/`false`만 넘기세요.
- **참고**: [`q.Tween(opts)`](../roblox/06-tween-animate.md#qtweenopts)

### Quad0246

`Tween: {name} must be a function (got {typeof(v)})` — `quad-roblox/src/Tween.luau`

- **언제**: `Started`/`Completed`/`Cancelled` 중 하나가 함수가 아닌 값으로 주어졌을 때. `{name}`은 실제 필드 이름입니다. `q.Animate{ … }`의 콜백 옵션에 `State`를 넣어도 이 에러입니다(콜백은 State 불가 — `Animate` 호출 줄에서 납니다).
- **고치려면**: 함수를 넘기세요 — `(inst, prop, value)`를 받거나 인자를 무시하는 함수 둘 다 됩니다. `tween:Mapped(fn, wrap)`/`tween:Wrapped(wrap)`의 `wrap`이 돌려준 셋의 값도 같은 검사를 받습니다.
- **참고**: [`q.Tween(opts)`](../roblox/06-tween-animate.md#qtweenopts)

### Quad0247

`Tween: Override must be "Cancel" or "Finish"` — `quad-roblox/src/Tween.luau`

- **언제**: `Override`가 `"Cancel"`/`"Finish"` 둘 중 하나가 아닌 값으로 주어졌을 때.
- **고치려면**: 그 두 문자열 중 하나만 넘기세요(생략하면 기본 `"Cancel"`).
- **참고**: [`q.Tween(opts)`](../roblox/06-tween-animate.md#qtweenopts)

### Quad0248

`Tween: options must be a table, e.g. Tween{ Value = ... } (got {typeof(opts)})` — `quad-roblox/src/Tween.luau`

- **언제**: `q.Tween(opts)`의 `opts`가 테이블이 아닐 때.
- **고치려면**: `q.Tween{ Value = ... }` 모양으로 테이블을 넘기세요.
- **참고**: [`q.Tween(opts)`](../roblox/06-tween-animate.md#qtweenopts)

### Quad0249

`Tween: Value is required` — `quad-roblox/src/Tween.luau`

- **언제**: `opts.Value`가 `nil`일 때 — `Tween`은 목표 값 없이 존재할 수 없습니다.
- **고치려면**: `Value` 필드를 채우세요.
- **참고**: [`q.Tween(opts)`](../roblox/06-tween-animate.md#qtweenopts)

### Quad0250

`Tween: Value must be a plain value, not a State (animate the State instead - state:Apply(Animate{...}) or state:Compute(function() return Tween{...} end))` — `quad-roblox/src/Tween.luau`

- **언제**: `opts.Value`로 `State`를 그대로 넘겼을 때 — `Tween`의 모든 필드는 평범한 값이어야 한다는 불변식을 어깁니다.
- **고치려면**: `State` 쪽을 감싸세요 — `state:Apply(q.Animate{...})`, 또는 `Compute` 안에서 `Tween{...}`을 만드세요.
- **참고**: [`q.Tween(opts)`](../roblox/06-tween-animate.md#qtweenopts)

### Quad0251

`Tween: Value must be a plain value, not None or another Tween (emit None itself to release the property)` — `quad-roblox/src/Tween.luau`

- **언제**: `opts.Value`로 `q.None`이나 다른 `Tween`을 넘겼을 때 — 이 역시 "모든 필드는 평범한 값" 불변식 위반입니다.
- **고치려면**: 프로퍼티를 풀고 싶으면 `Tween`으로 감싸지 말고 `None` 자체를 그 자리에 방출하세요.
- **참고**: [`q.Tween(opts)`](../roblox/06-tween-animate.md#qtweenopts)

### Quad0252

`Animate: Apply target must be a State (got {…}) - put the Animate on the State that feeds the field: state:Apply(q.Animate{ ... })` — `quad-roblox/src/Animate.luau`

- **언제**: `q.Animate{ … }`가 돌려준 팩토리를 `State`가 아닌 것에 붙였을 때 — `mod:Apply(q.Animate{…})`·`tag:Apply(q.Animate{…})`·Modifier setter의 변환 함수 자리(`mod:BackgroundTransparency(q.Animate{…})` — 그 필드가 비었거나 평범한 값일 때; 필드가 이미 State면 거부되지 않고 State 안의 State가 되는 정의되지 않은 동작). 괄호 안은 `Modifier`·`Tag`나 받은 값(setter 자리면 필드의 옛 값)의 타입입니다.
- **고치려면**: 그 필드에 흘리는 `State` 쪽에 붙이세요 — `mod:BackgroundTransparency(alpha:Apply(q.Animate{ Time = 0.2 }))`. setter 변환 함수 자리에서 난 경우 blame 줄은 여러분의 줄이 아니라 `Animate.luau`를 가리킬 수 있습니다(그 자리는 태그 없는 클로저를 거칩니다) — 스택 트레이스에서 여러분의 setter 호출을 찾으세요.
- **참고**: [`q.Animate(info)`](../roblox/06-tween-animate.md#qanimateinfo)

### Quad0253

`Animate: CanAnimate must be a boolean or a State<boolean> (got {typeof(v)})` — `quad-roblox/src/Animate.luau`

- **언제**: `CanAnimate`에 불리언도 `State`도 아닌 값(`"no"`·`0`·함수·`q.None` 등)을 줬을 때 — `Animate(info)` 호출 줄에서 납니다. `State`로 준 경우는 [`Quad0254`](#quad0254). `nil`은 생략과 같아 항상 애니메이션합니다.
- **고치려면**: `true`/`false`나 `State<boolean>`을 넘기세요. 함수로 조건을 계산하려면 `reduceMotion:Compute(function(s) return not s:Get() end)`처럼 State로 만드세요.
- **참고**: [`q.Animate(info)`](../roblox/06-tween-animate.md#qanimateinfo)

### Quad0254

`Animate: CanAnimate State must hold a boolean or nil (got {typeof(v)})` — `quad-roblox/src/Animate.luau`

- **언제**: `CanAnimate`로 준 `State`가 불리언도 `nil`도 아닌 값을 쥔 채 `Animate`가 실행될 때 — 애니메이션되는 값을 `Set`하거나 마운트하는 줄에서 납니다. 옵션 State만 바뀌면 재실행하지 않으므로, 나쁜 값은 다음 값 변경 때 드러납니다.
- **고치려면**: 그 State가 `true`/`false`(또는 `nil` — 생략과 같음)만 쥐게 하세요.
- **참고**: [`q.Animate(info)`](../roblox/06-tween-animate.md#qanimateinfo)
