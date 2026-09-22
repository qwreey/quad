---
title: "에러 코드 — Ref·Observer·Effect·훅"
description: "Ref/PreRef/PostRef/Observer/Effect/생명주기 훅/bindLifetime이 던지는 에러"
---
각 절은 `### QuadNNNN` — 메시지 원문(자리표시자는 `{…}`), 언제 나는가, 어떻게 고치는가. 번호로 찾으려면 [색인](/reference/errors/00-index/).


### Quad0086

`Effect: fn must return a cleanup function or nothing (got {typeof(cleanup)})` — `quad-base/src/Effect.luau`

- **언제**: `q.Effect(fn, ...)`의 `fn`이 함수도 `nil`도 아닌 값(숫자, 연결 객체 등)을 돌려줬을 때 — cleanup 자리는 함수 하나뿐입니다.
- **고치려면**: 정리할 게 있으면 함수로 감싸 돌려주세요 — 연결 객체는 `return function() conn:Disconnect() end`처럼 감싸세요. 여럿이면 한 클로저로 묶으세요.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0087

`Effect: cannot bind an Effect from inside its own fn or cleanup` — `quad-base/src/Effect.luau`

- **언제**: `fn`이나 cleanup 안에서 새로 만든 `Effect`를 그 자리(props의 숫자 키)에 놓아 바인딩하려 할 때.
- **고치려면**: 새 핸들은 다음 렌더/실행에서 놓으세요 — `fn`/cleanup 실행 중에는 자기 자신도, 새로 만든 핸들도 그 자리에서 바인딩할 수 없습니다.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0088

`Effect: cannot change subscription from inside fn or cleanup` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakSubscribe()`를 그 `Effect` 자신의 `fn`이나 cleanup 실행 중에 부를 때.
- **고치려면**: 구독/재구독은 `fn`·cleanup 밖에서 하세요. 해제(`:Unsubscribe()`/`:WeakUnsubscribe()`)는 그 안에서도 됩니다.
- **참고**: [`effect:WeakSubscribe()`](/reference/core/05-observer-effect/#effectweaksubscribe)

### Quad0089

`Effect: already subscribed` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakSubscribe()`를 부를 때 이미 강하게(`:Subscribe()`) 구독돼 있어서 약한 구독으로 바꿀 수 없을 때.
- **고치려면**: 이미 구독 중인 핸들은 그대로 두거나, 새 `Effect`를 만드세요.
- **참고**: [`effect:WeakSubscribe()`](/reference/core/05-observer-effect/#effectweaksubscribe)

### Quad0230

`Effect: already bound to an Instance` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakSubscribe()`를 부를 때 이미 어떤 인스턴스의 props 자리에 묶여 있어서(전역 구독과 자리 바인딩은 겹칠 수 없음) 전역 구독으로 바꿀 수 없을 때.
- **고치려면**: 자리에 묶인 핸들은 그대로 두거나, 전역 구독이 필요하면 새 `Effect`를 만들어 처음부터 `:Subscribe()`/`:WeakSubscribe()`로 쓰세요.
- **참고**: [`effect:WeakSubscribe()`](/reference/core/05-observer-effect/#effectweaksubscribe)

### Quad0090

`Effect: cannot change subscription from inside fn or cleanup` — `quad-base/src/Effect.luau`

- **언제**: `effect:Subscribe()`를 그 `Effect` 자신의 `fn`이나 cleanup 실행 중에 부를 때.
- **고치려면**: 구독/재구독은 `fn`·cleanup 밖에서 하세요. 해제는 그 안에서도 됩니다.
- **참고**: [`effect:Subscribe()`](/reference/core/05-observer-effect/#effectsubscribe)

### Quad0091

`Effect: already subscribed` — `quad-base/src/Effect.luau`

- **언제**: `effect:Subscribe()`를 부를 때 이미 강하게 구독돼 있을 때(중복 `:Subscribe()`).
- **고치려면**: 이미 구독 중이면 다시 부르지 마세요.
- **참고**: [`effect:Subscribe()`](/reference/core/05-observer-effect/#effectsubscribe)

### Quad0231

`Effect: already bound to an Instance` — `quad-base/src/Effect.luau`

- **언제**: `effect:Subscribe()`를 부를 때 이미 어떤 인스턴스의 props 자리에 묶여 있을 때.
- **고치려면**: 자리에 묶인 핸들은 그대로 두거나, 전역 구독이 필요하면 새 `Effect`를 만드세요.
- **참고**: [`effect:Subscribe()`](/reference/core/05-observer-effect/#effectsubscribe)

### Quad0092

`Effect: subscribed strongly; use :Unsubscribe()` — `quad-base/src/Effect.luau`

- **언제**: `effect:WeakUnsubscribe()`를 부를 때 그 핸들이 강한 구독(`:Subscribe()`)으로 살아 있을 때.
- **고치려면**: 강한 구독을 풀려면 `:Unsubscribe()`를 쓰세요.
- **참고**: [`effect:WeakUnsubscribe()`](/reference/core/05-observer-effect/#effectweakunsubscribe)

### Quad0093

`Effect: not subscribed strongly; use :WeakUnsubscribe()` — `quad-base/src/Effect.luau`

- **언제**: `effect:Unsubscribe()`를 부를 때 그 핸들이 강하게 구독된 적이 없을 때(약한 구독뿐이거나, 자리에만 묶여 있거나, 이미 `:Unsubscribe()`로 한 번 풀린 뒤 다시 부른 경우).
- **고치려면**: 약한 구독을 풀려면 `:WeakUnsubscribe()`를 쓰세요. 강한 구독을 이미 한 번 풀었다면 다시 부르지 마세요.
- **참고**: [`effect:Unsubscribe()`](/reference/core/05-observer-effect/#effectunsubscribe)

### Quad0094

`Effect: fn must be a function` — `quad-base/src/Effect.luau`

- **언제**: `q.Effect(fn, ...)`의 `fn`이 함수가 아닐 때.
- **고치려면**: 함수를 넘기세요.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0095

`Effect: dep #{i} is nil` — `quad-base/src/Effect.luau`

- **언제**: `q.Effect(fn, ...deps)`의 의존성 목록 중 `i`번째가 `nil`일 때.
- **고치려면**: 모든 의존성 자리를 실제 값(`State`/`Source`/`Ref`)으로 채우세요.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0096

`Effect: dep #{i} is not a State/Source/Ref` — `quad-base/src/Effect.luau`

- **언제**: 의존성 목록의 `i`번째가 `State`/`Source`/`Ref` 중 어느 것도 아닐 때.
- **고치려면**: 의존성은 `State`/`Source`/`Ref`만 쓸 수 있습니다.
- **참고**: [`q.Effect(fn, ...deps)`](/reference/core/05-observer-effect/#qeffectfn-deps)

### Quad0097

`Effect: must be an array item, not the value of a {typeof(k)} key` — `quad-base/src/Effect.luau`

- **언제**: `Effect`를 props의 문자 키 값 자리에 두거나, `State`/`Store`에 담아 그 자리에 닿게 했을 때.
- **고치려면**: `Effect`는 props의 숫자 키(배열부) 리터럴 자리에만 놓으세요.
- **참고**: [숫자 키 자리에 넣기](/reference/core/05-observer-effect/#숫자-키-자리에-넣기)

### Quad0098

`Effect: Effect.Init(module) has not run for this quad instance` — `quad-base/src/Effect.luau`

- **언제**: `Effect.implFor(module)`이 그 quad 모듈 인스턴스에서 아직 `Effect.Init`이 돌지 않았는데 불렸을 때 — 정상 경로(`module:RunInit`)로는 나지 않는 내부 조립 순서 불변식입니다.
- **고치려면**: (문서 미정) — 사용자 코드가 직접 부딪히는 자리가 아닙니다. quad 모듈 조립(`New()`) 경로를 우회해 내부 함수를 직접 부르지 않았는지 확인하세요.
- **참고**: [Observer / Effect](/reference/core/05-observer-effect/)
