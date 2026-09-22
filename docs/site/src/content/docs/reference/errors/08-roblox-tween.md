---
title: "에러 코드 — Roblox: Tween·Animate"
description: "Tween/Animate가 던지는 에러"
---
각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](/reference/errors/00-index/).


### Quad0214

`Animate: expected an options table (Animate{ Time = ... })` — `quad-roblox/src/Animate.luau`

- **언제**: `q.Animate(info)`의 `info`가 테이블이 아닐 때. 리터럴 옵션은 `Animate(info)` 호출 시점에 즉시 검증되고, `State`로 준 옵션은 실행할 때마다 풀려서 그때 검증됩니다.
- **고치려면**: `q.Animate{ Time = ... }` 모양으로 테이블을 넘기세요.
- **참고**: [`q.Animate(info)`](/reference/roblox/06-tween-animate/#qanimateinfo)

### Quad0227

`Tween:Mapped: fn must be a function (got {typeof(fn)})` — `quad-roblox/src/Tween.luau`

- **언제**: `tween:Mapped(fn)`의 `fn`이 함수가 아닐 때.
- **고치려면**: 목표 값을 받아 새 목표 값을 돌려주는 함수를 넘기세요.
- **참고**: [`tween:Mapped(fn)`](/reference/roblox/06-tween-animate/#tweenmappedfn)

### Quad0243

`Tween: {name} must be a number` — `quad-roblox/src/Tween.luau`

- **언제**: `Time`/`RepeatCount`/`DelayTime` 중 하나가 숫자가 아닌 값으로 주어졌을 때. `{name}`은 실제 필드 이름입니다.
- **고치려면**: 숫자를 넘기세요.
- **참고**: [`q.Tween(opts)`](/reference/roblox/06-tween-animate/#qtweenopts)

### Quad0244

`Tween: Reverses must be a boolean` — `quad-roblox/src/Tween.luau`

- **언제**: `Reverses`가 불린이 아닌 값으로 주어졌을 때.
- **고치려면**: `true`/`false`만 넘기세요.
- **참고**: [`q.Tween(opts)`](/reference/roblox/06-tween-animate/#qtweenopts)

### Quad0245

`Tween: Dedup must be a boolean` — `quad-roblox/src/Tween.luau`

- **언제**: `Dedup`이 불린이 아닌 값으로 주어졌을 때.
- **고치려면**: `true`/`false`만 넘기세요.
- **참고**: [`q.Tween(opts)`](/reference/roblox/06-tween-animate/#qtweenopts)

### Quad0246

`Tween: {name} must be a function` — `quad-roblox/src/Tween.luau`

- **언제**: `Started`/`Completed`/`Cancelled` 중 하나가 함수가 아닌 값으로 주어졌을 때. `{name}`은 실제 필드 이름입니다.
- **고치려면**: 인자 없는 함수를 넘기세요.
- **참고**: [`q.Tween(opts)`](/reference/roblox/06-tween-animate/#qtweenopts)

### Quad0247

`Tween: Override must be "Cancel" or "Finish"` — `quad-roblox/src/Tween.luau`

- **언제**: `Override`가 `"Cancel"`/`"Finish"` 둘 중 하나가 아닌 값으로 주어졌을 때.
- **고치려면**: 그 두 문자열 중 하나만 넘기세요(생략하면 기본 `"Cancel"`).
- **참고**: [`q.Tween(opts)`](/reference/roblox/06-tween-animate/#qtweenopts)

### Quad0248

`Tween: expected an options table (Tween{ Value = ... })` — `quad-roblox/src/Tween.luau`

- **언제**: `q.Tween(opts)`의 `opts`가 테이블이 아닐 때.
- **고치려면**: `q.Tween{ Value = ... }` 모양으로 테이블을 넘기세요.
- **참고**: [`q.Tween(opts)`](/reference/roblox/06-tween-animate/#qtweenopts)

### Quad0249

`Tween: Value is required` — `quad-roblox/src/Tween.luau`

- **언제**: `opts.Value`가 `nil`일 때 — `Tween`은 목표 값 없이 존재할 수 없습니다.
- **고치려면**: `Value` 필드를 채우세요.
- **참고**: [`q.Tween(opts)`](/reference/roblox/06-tween-animate/#qtweenopts)

### Quad0250

`Tween: Value must be a plain value, not a State (animate the State instead — state:Apply(Animate{...}) or state:Compute(function() return Tween{...} end))` — `quad-roblox/src/Tween.luau`

- **언제**: `opts.Value`로 `State`를 그대로 넘겼을 때 — `Tween`의 모든 필드는 평범한 값이어야 한다는 불변식(Q16 (b))을 어깁니다.
- **고치려면**: `State` 쪽을 감싸세요 — `state:Apply(q.Animate{...})`, 또는 `Compute` 안에서 `Tween{...}`을 만드세요.
- **참고**: [`q.Tween(opts)`](/reference/roblox/06-tween-animate/#qtweenopts)

### Quad0251

`Tween: Value must be a plain value, not None or another Tween (emit None itself to release the property)` — `quad-roblox/src/Tween.luau`

- **언제**: `opts.Value`로 `q.None`이나 다른 `Tween`을 넘겼을 때 — 이 역시 "모든 필드는 평범한 값" 불변식 위반입니다(`H-463`).
- **고치려면**: 프로퍼티를 풀고 싶으면 `Tween`으로 감싸지 말고 `None` 자체를 그 자리에 방출하세요.
- **참고**: [`q.Tween(opts)`](/reference/roblox/06-tween-animate/#qtweenopts)
